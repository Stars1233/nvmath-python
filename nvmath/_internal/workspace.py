# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Reusable workspace buffer manager for stateful nvmath APIs.

A *workspace* is a non-operand scratch buffer the underlying library (cuBLASLt,
cuFFT, cuSparse, ...) requires for its ``execute`` step. ``Workspace`` manages the
lifecycle — allocation, reuse across calls, stream-ordered release, and exception
cleanup — so each stateful API doesn't have to.

The required size is recorded during ``plan()`` (via :meth:`Workspace.set_size`); the
buffer is allocated lazily on first use and reused on subsequent calls.

The allocator is pluggable. Choose one based on what kind of memory you need:

- :class:`BaseCUDAMemoryManager` — sync device pool (e.g. cupy, torch caching)
- :class:`BaseCUDAMemoryManagerAsync` — stream-aware device pool (e.g. CUDA async)
- :class:`cuda.core.MemoryResource` — covers both device and host memory
  (e.g. ``cuda.core.DeviceMemoryResource``, ``cuda.core.PinnedMemoryResource``,
   or ``NumpyMemoryResource``)

:meth:`Workspace.allocate_perhaps` is a context manager: the ``with`` block defines
the lifetime of the consumer's use of the buffer. On normal exit the buffer is kept
for reuse on the next call. On exception, any buffer this call allocated fresh is
released. The consumer never has to write an exception handler for the workspace.

Typical use::

    class Matmul:
        def __init__(self, ..., allocator, logger):
            self.workspace = Workspace(allocator, logger, label="matmul workspace")
            self.last_compute_event = None

        def plan(self, ...):
            ...
            self.workspace.set_size(required_bytes)

        def execute(self, *, release_workspace=False, stream_holder, ...):
            with self.workspace.allocate_perhaps(
                stream_holder, get_last_event=lambda: self.last_compute_event
            ) as ws:
                cublaslt.matmul(..., ws.raw_ptr, ws.size, ...)
                self.last_compute_event = stream_holder.obj.record()
                if release_workspace:
                    ws.release(self.last_compute_event)
                    # If the event is not managing the lifetime of other objects,
                    # null it to prevent a duplicate wait in self.free().
                    self.last_compute_event = None

        def free(self, ...):
            self.workspace.release(self.last_compute_event)
            self.last_compute_event = None
"""

__all__ = ["Workspace", "NumpyMemoryResource", "get_pinned_memory_resource"]

import contextlib
from collections.abc import Callable
from contextlib import nullcontext

import numpy as np
from cuda.core import Buffer, Event, MemoryResource, Stream

from nvmath._internal.utils import LoggerLike
from nvmath.internal import formatters, utils
from nvmath.internal.memory import get_legacy_pinned_memory_resource, get_pinned_async_memory_resource
from nvmath.internal.package_ifc import StreamHolder
from nvmath.memory import (
    BaseCUDAMemoryManager,
    BaseCUDAMemoryManagerAsync,
    MemoryPointer,
)

_PROTOCOL_TYPE_ERROR_MESSAGE = (
    "The method 'memalloc' in the allocator object must conform to the interface in the 'BaseCUDAMemoryManager' protocol."
)


class Workspace:
    """Manages a CUDA scratch buffer with reuse, stream-ordered release, and
    exception cleanup.

    Args:
        allocator: A :class:`BaseCUDAMemoryManager`, :class:`BaseCUDAMemoryManagerAsync`,
            or :class:`cuda.core.MemoryResource`. Use a ``MemoryResource``
            (e.g. ``PinnedMemoryResource``) when you need a host buffer or any backing
            the legacy protocols can't express.
        logger: Logger for debug-level allocation/release messages.
        device_id: The CUDA device the workspace lives on. Optional — if omitted,
            it is read from ``allocator.device_id``. ``cuda.core.MemoryResource``
            declares this attribute in its protocol; the legacy
            ``BaseCUDAMemoryManager(Async)`` protocols don't, but every in-tree
            implementation exposes it as a convention. Pass this explicitly when
            the allocator can't supply it: a third-party legacy allocator that
            doesn't expose ``device_id``, or a pinned-only resource (e.g.
            ``LegacyPinnedMemoryResource``) whose ``device_id`` deliberately
            raises because pinned memory isn't bound to a specific GPU.
        label: Short noun for log messages (e.g. ``"matmul workspace"``).
        on_allocated: Optional callback invoked with the raw pointer right after a
            successful allocation, inside the device + stream context. Used by cuFFT
            to register the buffer with its handle via ``cufft.set_work_area``.
    """

    __slots__ = (
        # Public state (also annotated below for type checkers / docs).
        "ptr",
        "size",
        "allocated_size",
        "allocated_here",
        "stream",
        # Configuration cached from __init__.
        "_allocator",
        "_logger",
        "_label",
        "_on_allocated",
        "_get_ptr",
        "_close_on_release",
        "_is_device_accessible",
        "_device_id",
        # Transient per-call state set by allocate_perhaps, read by __enter__ /
        # __exit__, cleared back to None on __exit__.
        "_stream_holder",
        "_get_last_event",
    )

    ptr: MemoryPointer | Buffer | None
    """The owning buffer wrapper, or ``None`` when no buffer is held. Use
    :attr:`raw_ptr` to get the integer pointer for C bindings."""

    size: int
    """Bytes required by the current plan. Set via :meth:`set_size`."""

    allocated_size: int
    """Bytes currently held by ``ptr``. May exceed ``size`` after a smaller plan
    (the held buffer is never shrunk)."""

    allocated_here: bool
    """``True`` iff the current ``allocate_perhaps`` ``with`` block allocated this
    buffer (rather than inheriting one from a previous call). Managed structurally by
    the context manager — consumers don't need to set or reset it themselves. Exposed
    for introspection."""

    stream: Stream | None
    """The stream the buffer was allocated on. Used by :meth:`release` to order
    freeing against the consumer's last compute event."""

    def __init__(
        self,
        allocator: BaseCUDAMemoryManager | BaseCUDAMemoryManagerAsync | MemoryResource,
        logger: LoggerLike,
        *,
        device_id: int | None = None,
        label: str = "workspace",
        on_allocated: Callable[[int], None] | None = None,
    ) -> None:
        self._allocator = allocator
        self._logger = logger
        self._label = label
        self._on_allocated = on_allocated

        # MemoryResource returns a Buffer (which needs explicit, stream-ordered
        # close()); legacy allocators return a MemoryPointer (whose finalizer
        # fires on reference-drop). Cache both decisions at construction for the
        # release hot path.
        if isinstance(allocator, MemoryResource):
            self._get_ptr: Callable[..., int] = self._get_ptr_from_buffer
            self._close_on_release = True
        else:
            self._get_ptr = utils.get_ptr_from_memory_pointer
            self._close_on_release = False

        # Mirrors the allocator's cuda.core.MemoryResource.is_device_accessible
        # property; legacy BaseCUDAMemoryManager(Async) allocators have no such
        # flag and are device-accessible by definition. Drives whether allocate /
        # release enter the device + stream context.
        self._is_device_accessible = not isinstance(allocator, MemoryResource) or allocator.is_device_accessible

        # AttributeError covers third-party allocators that simply don't expose
        # device_id; RuntimeError covers cuda.core's LegacyPinnedMemoryResource,
        # whose property raises by design (pinned memory isn't bound to a GPU).
        if device_id is None:
            try:
                device_id = allocator.device_id  # type: ignore[union-attr]
            except (AttributeError, RuntimeError):
                device_id = None
        if self._is_device_accessible and device_id is None:
            raise TypeError(
                f"Workspace could not infer device_id from {type(allocator).__name__}: "
                "the allocator is device-accessible but has no usable 'device_id' attribute. "
                "Pass device_id=<int> to Workspace explicitly."
            )
        self._device_id: int | None = device_id

        self.ptr = None
        self.size = 0
        self.allocated_size = 0
        self.allocated_here = False
        self.stream = None
        # Transient per-call state set by allocate_perhaps and read by
        # __enter__ / __exit__. None outside an active `with` block.
        self._stream_holder: StreamHolder | None = None
        self._get_last_event: Callable[[], Event | None] | None = None

    @staticmethod
    def _get_ptr_from_buffer(buffer: Buffer) -> int:
        """Pointer extractor for ``MemoryResource``-backed buffers. The ``int()``
        cast unwraps cuda.core's ``CUdeviceptr`` (a typed alias of int)."""
        return int(buffer.handle)

    # ------------------------------------------------------------------ plan
    def set_size(self, size: int) -> None:
        """Record the size required by the current plan."""
        if size < 0:
            raise ValueError(f"Internal Error: Cannot allocate {self._label} of size {size} < 0.")
        self.size = size

    # ------------------------------------------------------------ allocation
    def allocate_perhaps(
        self,
        stream_holder: StreamHolder | None,
        *,
        get_last_event: Callable[[], Event | None] | None,
    ) -> "Workspace":
        """Acquire the workspace buffer for the duration of a ``with`` block.

        On entry, the buffer is either reused (if it's already at least ``size`` bytes) or
        freshly allocated. If the held buffer is too small, it is released first — with a
        stream wait against ``get_last_event()`` to order the free against any pending
        compute on the prior buffer — and then a fresh buffer is allocated. Inside the
        block, read ``ws.raw_ptr`` and ``ws.size`` to plumb into a C binding, and optionally
        call ``ws.release(...)`` to free the buffer mid-scope.

        On normal exit the buffer is kept for reuse on the next call. On exception, if this
        call allocated a fresh buffer it is released — again with a stream wait against
        ``get_last_event()``. The consumer doesn't write an exception handler.

        Host-only mode (no CUDA driver required): when the allocator is a
        :class:`cuda.core.MemoryResource` with ``is_device_accessible=False`` (e.g.
        :class:`NumpyMemoryResource`), Workspace skips the device + stream context
        entirely. ``stream_holder`` is ignored in this mode and may be ``None``;
        the allocator is invoked with ``stream=None`` and :meth:`release` will pass
        ``None`` to ``Buffer.close``. Pinned memory (``PinnedMemoryResource``) is
        *device-accessible* — it needs the stream for ordered close and goes through
        the device path even though its ``device_id`` is ``-1``.

        Args:
            stream_holder: The stream the workspace is allocated on. May be ``None``
                only when the allocator is a host-only ``MemoryResource``.
            get_last_event: A callable returning the consumer's current
                ``last_compute_event``. Called at ``__enter__`` time on the grow path
                (when a held buffer is too small) and at ``__exit__`` time on the
                exception path. Late-binding via callable lets the consumer assign a
                fresh event inside the block and have the next ``__enter__`` see it.
                Required whenever the held buffer may have pending compute (both
                device-only and host-accessible workspaces): the released buffer is
                stream-waited against this event before its (stream-ordered) close.
                May be ``None`` for workspaces guaranteed to be quiescent at the
                relevant call sites.

        Returns:
            self: A reference to this Workspace. The Workspace is its own context
                manager — the ``with`` statement calls ``__enter__`` to perform
                allocation and ``__exit__`` to handle cleanup. Inside the block,
                read ``self.raw_ptr`` / ``self.size``; optionally call
                ``self.release(...)``.
        """
        # NOTE: get_last_event is required so that human developers must think about
        # using this parameter.
        # Stash transient per-call params for __enter__ / __exit__ to read.
        # Workspace is its own context manager (rather than returning a separate
        # scope object) to avoid the per-call Python object alloc on the hot path.
        # Safe because allocate_perhaps is documented as not reentrant — the
        # __enter__ check on allocated_here would catch any nested misuse.
        self._stream_holder = stream_holder
        self._get_last_event = get_last_event
        return self

    def __enter__(self) -> "Workspace":
        if self.allocated_here:
            raise RuntimeError(
                "Workspace.allocate_perhaps is reusable but not reentrant: allocated_here was "
                "True on entry, meaning a prior `with` block didn't exit through __exit__ "
                "(consumer bypassed the `with` statement or caught and suppressed the exit-path)."
            )

        gle = self._get_last_event

        # Grow-path cleanup: a held buffer that's too small must be released before the
        # fresh allocation overwrites self.ptr — otherwise the old Buffer's __del__ runs
        # unordered against any pending compute that was still reading it. release()
        # handles the stream wait, the stream-ordered close(), and clears all
        # post-release state, leaving the fresh-alloc dispatch with a clean slate.
        if self.ptr is not None and self.allocated_size < self.size:
            self.release(gle() if gle is not None else None)

        # Allocation with rollback: drop any partial state if _allocate_perhaps raises.
        try:
            self._allocate_perhaps(self._stream_holder)
        except BaseException:
            self.ptr = None
            self.allocated_size = 0
            self.allocated_here = False
            self.stream = None
            raise

        return self

    def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
        if exc_type is not None and self.allocated_here:
            gle = self._get_last_event
            self.release(gle() if gle is not None else None)
        self.allocated_here = False
        # Drop transient per-call refs — they don't outlive the with-block.
        self._stream_holder = None
        self._get_last_event = None

    def _allocate_perhaps(self, stream_holder: StreamHolder | None) -> None:
        """Internal — perform the allocation (or reuse short-circuit). Called from
        the :meth:`allocate_perhaps` context manager's ``__enter__``.

        Implementation notes:

        - The legacy ``BaseCUDAMemoryManager(Async)`` 0-byte fast path produces a
          ``MemoryPointer(0, 0, ...)`` sentinel rather than calling ``memalloc(0)``,
          since concrete implementations don't uniformly support zero-byte
          allocations. ``MemoryResource.allocate(0)`` is well-defined and used
          directly.
        - Dispatch order is ``MemoryResource``, then ``BaseCUDAMemoryManagerAsync``,
          then ``BaseCUDAMemoryManager`` (most-specific first).
        - The ``on_allocated`` hook fires from inside the device+stream context so
          it sees the right active context — and only on real allocations, never on
          reuse or the 0-byte fast path.
        """
        if self.ptr is not None and self.allocated_size >= self.size:
            return

        # Host-only allocators (NumpyMemoryResource and similar) skip the device
        # + stream context to keep Workspace usable without a CUDA driver/device;
        # stream_holder is ignored in that mode.
        device_cm: contextlib.AbstractContextManager[object]
        stream_cm: contextlib.AbstractContextManager[object]
        stream_obj: Stream | None
        if self._is_device_accessible:
            if stream_holder is None:
                raise TypeError(
                    "Workspace.allocate_perhaps requires stream_holder for device-accessible allocators (got None)."
                )
            # __init__ validates this invariant; assertion narrows int | None for mypy.
            assert self._device_id is not None
            device_cm = utils.device_ctx(self._device_id)
            stream_cm = stream_holder.ctx
            stream_obj = stream_holder.obj
        else:
            device_cm = nullcontext()
            stream_cm = nullcontext()
            stream_obj = None

        self._logger.debug("Allocating %s...", self._label)
        if self.size == 0 and not isinstance(self._allocator, MemoryResource):
            self.ptr = MemoryPointer(0, 0, finalizer=None)
            self.allocated_here = True
        else:
            with device_cm, stream_cm:
                try:
                    if isinstance(self._allocator, MemoryResource):
                        self.ptr = self._allocator.allocate(self.size, stream=stream_obj)
                    elif isinstance(self._allocator, BaseCUDAMemoryManagerAsync):
                        self.ptr = self._allocator.memalloc_async(self.size, stream_obj)
                    else:
                        self.ptr = self._allocator.memalloc(self.size)
                    self.allocated_here = True
                except TypeError as e:
                    raise TypeError(_PROTOCOL_TYPE_ERROR_MESSAGE) from e
                if self._on_allocated is not None:
                    self._on_allocated(self._get_ptr(self.ptr))

        self.allocated_size = self.size
        self.stream = stream_obj
        # %-formatting defers MemoryStr(...) __str__ until the logger emits.
        self._logger.debug(
            "Finished allocating %s of size %s in the context of stream %s.",
            self._label,
            formatters.MemoryStr(self.size),
            self.stream,
        )

    # ------------------------------------------------------------- free path
    def release(self, last_compute_event: Event | None) -> None:
        """Wait for pending compute and free the buffer.

        Call this explicitly inside an :meth:`allocate_perhaps` ``with`` block
        (e.g. when ``release_workspace=True``) to free the buffer mid-scope. On the
        exception path the context manager calls this internally if the buffer is
        still held; consumers don't need to.

        Safe to call when no buffer is held — it's a no-op, so a redundant second
        release doesn't pay for a stream wait. After a successful release, null
        your ``last_compute_event`` slot so a subsequent release doesn't re-wait
        on a stale event.

        .. important:: This is a buffer-release operation, not a standalone event-sync
            primitive. If no buffer is held, the method returns immediately and
            ``last_compute_event`` is not waited on. For a standalone event sync, call
            ``stream.wait(event)`` directly.
        """
        # NOTE: last_compute_event is required so that human developers must think about
        # using this parameter.
        if self.ptr is None:
            return
        if self.stream is not None and last_compute_event is not None:
            self.stream.wait(last_compute_event)
        if self._close_on_release:
            # Pass the stream so the dealloc is stream-ordered — pinned-buffer free
            # is deferred until pending stream work completes, no host stall.
            self.ptr.close(self.stream)  # type: ignore[union-attr]
        self.ptr = None
        self.allocated_size = 0
        self.allocated_here = False
        self.stream = None
        self._logger.debug("[release] %s released.", self._label)

    # ------------------------------------------------------- pointer plumbing
    @property
    def raw_ptr(self) -> int:
        """Raw integer pointer for plumbing into C bindings.

        Raises :class:`AttributeError` if no buffer is held (called outside a ``with``
        block, or after :meth:`release`). For the legacy 0-byte fast path returns
        ``0`` — if a null device pointer is unsuitable downstream, also branch on
        ``self.size == 0``.
        """
        return self._get_ptr(self.ptr)


class NumpyMemoryResource(MemoryResource):
    """Host :class:`cuda.core.MemoryResource` backed by :func:`numpy.empty`.

    Allocates plain (non-pinned) host memory via NumPy. Unlike
    :class:`PinnedMemoryResource` / :class:`LegacyPinnedMemoryResource`, this
    resource does not call into the CUDA driver, so it is safe to use in
    environments where no CUDA driver/device is available (CPU-only test runs,
    pure-host scratch space for parameter struct staging, etc.).

    Pair with ``Workspace(NumpyMemoryResource(), logger)`` and pass
    ``stream_holder=None`` to ``allocate_perhaps`` for a fully CUDA-free path
    (``device_id`` is read from the resource and is ``-1``).

    Not suitable as the host half of a :class:`MirroredWorkspace`: ``cudaMemcpyAsync``
    requires page-locked memory for asynchronous correctness.
    """

    def __init__(self) -> None:
        # Strong refs keyed by ptr — Buffer carries only the int pointer.
        self._held: dict[int, np.ndarray] = {}

    def allocate(self, size: int, *, stream: Stream | None = None) -> Buffer:
        arr = np.empty(size, dtype=np.uint8)
        ptr = int(arr.ctypes.data)
        self._held[ptr] = arr
        return Buffer.from_handle(ptr=ptr, size=size, mr=self)

    def deallocate(self, ptr: int, size: int, stream: Stream | None = None) -> None:
        # `stream` must NOT be keyword-only: cuda.core < 1 calls deallocate with all
        # arguments positionally (Buffer.close -> mr.deallocate(ptr, size, stream)).
        self._held.pop(int(ptr), None)

    @property
    def is_host_accessible(self) -> bool:
        return True

    @property
    def is_device_accessible(self) -> bool:
        return False

    @property
    def device_id(self) -> int:
        return -1


def get_pinned_memory_resource(device_id: int) -> MemoryResource:
    """
    Use host pinned cuda asynchronous memory pool (via cuda.core.PinnedMemoryResource)
    if available, otherwise use legacy pinned memory resource
    (via cuda.core.LegacyPinnedMemoryResource).
    """
    mr = get_pinned_async_memory_resource(device_id)
    if mr is None:
        mr = get_legacy_pinned_memory_resource(device_id)
    return mr
