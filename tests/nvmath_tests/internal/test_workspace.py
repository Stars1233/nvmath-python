# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Unit tests for nvmath._internal.workspace.Workspace.

These tests run on host (no CUDA device required); `utils.device_ctx` is
stubbed and the allocator interfaces are exercised with `Fake*` doubles.
``allocate_perhaps`` is a context manager — every successful allocation lives
inside a ``with`` block, and failure-path coverage drives the exception branch
by raising inside the block.
"""

import contextlib
import logging

import pytest
from cuda.core import MemoryResource

from nvmath._internal.workspace import NumpyMemoryResource, Workspace
from nvmath.memory import MemoryPointer


class _Sentinel(Exception):
    """Marker exception raised inside `with` blocks to drive the __exit__
    exception branch deterministically."""


class _FakeBuffer:
    """Duck-typed stand-in for cuda.core.Buffer. Workspace touches `.handle`
    (via ``int()``) and `.close(stream)` — that's the entire surface area.

    cuda.core.Buffer is a Cython class with strict Stream type-validation in
    `close(stream)`, so we can't pass a FakeStream to a real Buffer. This fake
    bypasses that and records both the call and its stream argument."""

    def __init__(self, handle: int, size: int, mr: "_FakeResource"):
        self.handle = handle
        self.size = size
        self._mr = mr

    def close(self, stream=None) -> None:
        self._mr.deallocate(self.handle, self.size, stream=stream)


# ---------------------------------------------------------------------------
# Fakes
# ---------------------------------------------------------------------------


class FakeStream:
    """Minimal Stream stand-in that records `wait()` and `sync()` calls."""

    def __init__(self, name: str = "stream"):
        self.name = name
        self.waits: list = []
        self.syncs: int = 0

    def wait(self, event) -> None:
        self.waits.append(event)

    def sync(self) -> None:
        self.syncs += 1

    def __repr__(self) -> str:
        return f"FakeStream({self.name})"


class FakeStreamHolder:
    """Mimics StreamHolder for the fields Workspace touches."""

    def __init__(self, stream: FakeStream | None = None):
        self.obj = stream if stream is not None else FakeStream()
        self.ctx = contextlib.nullcontext()


class FakeAllocator:
    """Synchronous allocator (`memalloc` only). Records calls; the produced
    MemoryPointer carries a finalizer that records its address on free."""

    def __init__(self, device_id: int = 0, logger=None, base_addr: int = 0x1000):
        self.device_id = device_id
        self.logger = logger
        self.calls: list = []
        self._next_addr = base_addr
        self.freed: list[int] = []

    def memalloc(self, size: int) -> MemoryPointer:
        addr = self._next_addr
        self._next_addr += max(size, 1)
        self.calls.append(("memalloc", size))
        return MemoryPointer(addr, size, finalizer=lambda a=addr: self.freed.append(a))


class FakeAsyncAllocator:
    """Async allocator (`memalloc_async` only)."""

    def __init__(self, device_id: int = 0, logger=None, base_addr: int = 0x2000):
        self.device_id = device_id
        self.logger = logger
        self.calls: list = []
        self._next_addr = base_addr
        self.freed: list[int] = []

    def memalloc_async(self, size: int, stream) -> MemoryPointer:
        addr = self._next_addr
        self._next_addr += max(size, 1)
        self.calls.append(("memalloc_async", size, stream))
        return MemoryPointer(addr, size, finalizer=lambda a=addr: self.freed.append(a))


class BadAllocator:
    """Allocator that raises TypeError to exercise the protocol error path."""

    device_id = 0

    def memalloc(self, size: int):
        raise TypeError("wrong signature")


class RaisesOnSecondCallAllocator:
    """Sync allocator: succeeds on the first ``memalloc``, raises on subsequent
    calls. Used to simulate grow-OOM — the prior outer method's allocation
    worked, but the grow attempt fails."""

    def __init__(self, device_id: int = 0, logger=None, base_addr: int = 0x6000):
        self.device_id = device_id
        self.logger = logger
        self.calls: list = []
        self._next_addr = base_addr
        self.freed: list[int] = []

    def memalloc(self, size: int) -> MemoryPointer:
        if len(self.calls) >= 1:
            raise RuntimeError("alloc failed (simulated grow OOM)")
        addr = self._next_addr
        self._next_addr += max(size, 1)
        self.calls.append(("memalloc", size))
        return MemoryPointer(addr, size, finalizer=lambda a=addr: self.freed.append(a))


class _FakeResource(MemoryResource):
    """Shared base for the cuda.core.MemoryResource doubles. The ``host`` flag
    drives ``is_host_accessible``. ``deallocate_streams`` records the stream
    argument on each free — Workspace.release() passes ``self.stream`` to
    Buffer.close(), which threads through to the resource's deallocate()."""

    _host: bool

    def __init__(self, base_addr: int):
        self.calls: list = []
        self.freed: list[int] = []
        self.deallocate_streams: list = []
        self._next_addr = base_addr

    def allocate(self, size: int, *, stream=None) -> _FakeBuffer:
        addr = self._next_addr
        self._next_addr += max(size, 1)
        self.calls.append(("allocate", size, stream))
        return _FakeBuffer(handle=addr, size=size, mr=self)

    def deallocate(self, ptr, size, stream=None):
        self.freed.append(int(ptr))
        self.deallocate_streams.append(stream)

    @property
    def is_device_accessible(self) -> bool:
        return True

    @property
    def is_host_accessible(self) -> bool:
        return self._host

    @property
    def device_id(self) -> int:
        return -1 if self._host else 0


class FakePinnedResource(_FakeResource):
    """Host-accessible MemoryResource. Release goes through stream-ordered
    Buffer.close(stream) just like the device-only path — no host sync."""

    _host = True

    def __init__(self, base_addr: int = 0x4000):
        super().__init__(base_addr)


class FakeDeviceResource(_FakeResource):
    """Device-only MemoryResource. Release uses stream.wait(event) +
    stream-ordered Buffer.close(stream)."""

    _host = False

    def __init__(self, base_addr: int = 0x5000):
        super().__init__(base_addr)


class FailingResource(MemoryResource):
    """MemoryResource whose allocate() raises, used to exercise atomic rollback."""

    def allocate(self, size: int, *, stream=None):
        raise RuntimeError("allocate failed")

    def deallocate(self, ptr, size, stream=None):
        pass

    @property
    def is_device_accessible(self) -> bool:
        return True

    @property
    def is_host_accessible(self) -> bool:
        return False

    @property
    def device_id(self) -> int:
        return 0


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def stub_device_ctx(monkeypatch):
    """Replace `device_ctx` so tests don't need a real CUDA device."""

    @contextlib.contextmanager
    def _ctx(device_id):
        yield None

    monkeypatch.setattr("nvmath.internal.utils.device_ctx", _ctx)


@pytest.fixture
def logger():
    return logging.getLogger("nvmath.test.workspace")


@pytest.fixture
def make_workspace(logger, stub_device_ctx):
    def _make(*, async_: bool = False, on_allocated=None, label: str = "ws"):
        alloc = FakeAsyncAllocator() if async_ else FakeAllocator()
        ws = Workspace(alloc, logger=logger, label=label, on_allocated=on_allocated)
        return ws, alloc

    return _make


# ---------------------------------------------------------------------------
# Allocation (inside the `with` block)
# ---------------------------------------------------------------------------


def test_size_zero_bypasses_allocator(make_workspace):
    ws, alloc = make_workspace()
    ws.set_size(0)
    holder = FakeStreamHolder()
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        assert alloc.calls == []
        assert ws_ctx.ptr is not None
        assert ws_ctx.ptr.size == 0
        assert ws_ctx.allocated_size == 0
        # 0-byte sentinel claims ownership the same way a real allocation does — the
        # state machine is uniform across zero and non-zero sizes.
        assert ws_ctx.allocated_here is True
        assert ws_ctx.stream is holder.obj


def test_sync_allocator_path(make_workspace):
    ws, alloc = make_workspace(async_=False)
    ws.set_size(128)
    holder = FakeStreamHolder()
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        assert alloc.calls == [("memalloc", 128)]
        assert ws_ctx.ptr is not None
        assert ws_ctx.allocated_size == 128
        assert ws_ctx.allocated_here is True
        assert ws_ctx.stream is holder.obj


def test_async_allocator_path(make_workspace):
    ws, alloc = make_workspace(async_=True)
    ws.set_size(256)
    holder = FakeStreamHolder()
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        assert len(alloc.calls) == 1
        name, size, stream = alloc.calls[0]
        assert name == "memalloc_async"
        assert size == 256
        assert stream is holder.obj
        assert ws_ctx.allocated_here is True


def test_on_allocated_hook(make_workspace):
    seen: list[int] = []
    ws, _ = make_workspace(on_allocated=lambda raw: seen.append(raw))
    ws.set_size(64)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None) as ws_ctx:
        assert len(seen) == 1
        assert seen[0] == ws_ctx.raw_ptr


def test_on_allocated_not_called_for_size_zero(make_workspace):
    seen: list[int] = []
    ws, _ = make_workspace(on_allocated=lambda raw: seen.append(raw))
    ws.set_size(0)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
        # The 0-byte fast path bypasses the hook because there is no real
        # allocation to register with the underlying library.
        assert seen == []


def test_allocate_perhaps_reuse(make_workspace):
    """Two sequential `with` blocks (representing two outer methods) reuse the same
    buffer; the allocator is invoked exactly once."""
    ws, alloc = make_workspace()
    ws.set_size(512)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None):
        pass  # First outer method

    with ws.allocate_perhaps(holder, get_last_event=None):
        pass  # Second outer method — should reuse

    assert len(alloc.calls) == 1, "Allocator should only be invoked once when size is unchanged"


def test_allocate_perhaps_grow(make_workspace):
    """Growing across two outer methods (set_size between `with` blocks) triggers a
    fresh allocation."""
    ws, alloc = make_workspace()
    holder = FakeStreamHolder()

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    ws.set_size(256)
    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    assert [c[1] for c in alloc.calls] == [128, 256]
    assert ws.allocated_size == 256


def test_allocate_perhaps_shrink_no_realloc(make_workspace):
    """Shrinking the requested size between outer methods leaves the larger held
    buffer intact (no shrink rule)."""
    ws, alloc = make_workspace()
    holder = FakeStreamHolder()

    ws.set_size(1024)
    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    ws.set_size(64)
    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    assert len(alloc.calls) == 1
    assert ws.allocated_size == 1024  # Old, larger buffer is kept


def test_allocator_typeerror_wrapped(logger, stub_device_ctx):
    """Allocator misimplementing the protocol → wrapped TypeError on __enter__,
    body never runs, the inline rollback clears partial state."""
    ws = Workspace(BadAllocator(), logger=logger)
    ws.set_size(128)

    with pytest.raises(TypeError, match="must conform to the interface in the 'BaseCUDAMemoryManager' protocol"):  # noqa: SIM117
        with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
            pytest.fail("body must not run when __enter__ raises")

    assert ws.ptr is None
    assert ws.allocated_size == 0
    assert ws.allocated_here is False


# ---------------------------------------------------------------------------
# Release inside the `with` block
# ---------------------------------------------------------------------------


def test_release_with_event(make_workspace):
    """Explicit release inside a `with` block waits on the event and frees."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(event)
        assert holder.obj.waits == [event]
        assert ws_ctx.ptr is None

    assert addr in alloc.freed


def test_release_no_event(make_workspace):
    """release(None) inside a `with` block: no wait, just free."""
    ws, _ = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        ws_ctx.release(None)
        assert holder.obj.waits == []
        assert ws_ctx.ptr is None


# ---------------------------------------------------------------------------
# Failure paths driven by raising inside the `with` block
# ---------------------------------------------------------------------------


def test_exception_in_block_releases_when_allocated_here(make_workspace):
    """Raise inside a `with` block: the __exit__ exception branch sees
    allocated_here=True and frees the buffer (with a stream wait against the
    consumer's last_compute_event)."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()
    addr = None

    with pytest.raises(_Sentinel), ws.allocate_perhaps(holder, get_last_event=lambda: event) as ws_ctx:
        addr = ws_ctx.raw_ptr
        raise _Sentinel

    assert addr in alloc.freed
    assert ws.allocated_here is False
    assert holder.obj.waits == [event]


def test_exception_in_block_preserves_inherited_buffer(make_workspace):
    """A `with` block that *inherits* the buffer from a prior outer method (reuse
    short-circuit) must NOT free it on exception — the inherited buffer is still
    valid, freeing it would punish reuse."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()

    # Prior outer method allocates and exits cleanly.
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr

    # Second outer method reuses the buffer, then raises.
    assert ws.allocated_here is False  # Reset by prior exit
    with pytest.raises(_Sentinel), ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        # Reuse short-circuit means allocated_here stays False here
        assert ws_ctx.allocated_here is False
        assert ws_ctx.raw_ptr == addr
        raise _Sentinel

    assert ws.ptr is not None
    assert ws.raw_ptr == addr  # Buffer was preserved
    assert alloc.freed == []
    assert ws.allocated_here is False


# ---------------------------------------------------------------------------
# Pointer plumbing & misc
# ---------------------------------------------------------------------------


def test_raw_ptr_extracts_device_ptr(make_workspace):
    ws, _ = make_workspace()
    ws.set_size(128)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None) as ws_ctx:
        assert ws_ctx.raw_ptr == ws_ctx.ptr.device_ptr


def test_release_no_buffer_held(logger, stub_device_ctx):
    """release() when nothing has been allocated must not raise — the
    workspace's stream is None at that point, and there's nothing to free."""
    ws = Workspace(FakeAllocator(), logger=logger)
    assert ws.stream is None
    # Calling release() unconditionally on a cleanup path of a workspace
    # that was never allocated is a legitimate no-op.
    ws.release(object())
    assert ws.ptr is None


def test_release_idempotent(make_workspace):
    """A second release() after the buffer is gone is a no-op; the
    underlying allocator's finalizer runs exactly once."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(None)
    # __exit__ ran, but ptr was already None so nothing further happens.

    ws.release(None)  # External second release: also no-op
    assert ws.ptr is None
    assert len([a for a in alloc.freed if a == addr]) == 1


# ---------------------------------------------------------------------------
# cuda.core.MemoryResource path (e.g. PinnedMemoryResource for host pinned)
# ---------------------------------------------------------------------------


def test_memory_resource_allocator_path(logger, stub_device_ctx):
    """MemoryResource dispatch: __enter__ calls resource.allocate(size, stream)
    and stores the returned Buffer."""
    res = FakePinnedResource()
    ws = Workspace(res, logger=logger, label="pinned ws")
    ws.set_size(256)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        assert len(res.calls) == 1
        name, size, stream = res.calls[0]
        assert name == "allocate"
        assert size == 256
        assert stream is holder.obj
        assert isinstance(ws_ctx.ptr, _FakeBuffer)
        assert ws_ctx.allocated_size == 256
        assert ws_ctx.allocated_here is True
        assert ws_ctx.stream is holder.obj


def test_raw_ptr_extracts_buffer_handle(logger, stub_device_ctx):
    """raw_ptr returns int(buffer.handle) via the construction-time-selected
    Workspace._get_ptr_from_buffer extractor."""
    res = FakePinnedResource(base_addr=0xABCD000)
    ws = Workspace(res, logger=logger)
    ws.set_size(128)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None) as ws_ctx:
        assert ws_ctx.raw_ptr == 0xABCD000
        assert ws_ctx.raw_ptr == int(ws_ctx.ptr.handle)


def test_release_pinned_stream_orders_close(logger, stub_device_ctx):
    """Host-accessible MemoryResource: release() does stream.wait(event) +
    stream-ordered Buffer.close(stream) — no host sync. The event is honored
    for host-accessible workspaces just like device-only workspaces."""
    res = FakePinnedResource()
    ws = Workspace(res, logger=logger)
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(event)

    assert holder.obj.syncs == 0  # No host sync
    assert holder.obj.waits == [event]
    assert res.deallocate_streams == [holder.obj]  # close(stream) threaded through
    assert ws.ptr is None
    assert addr in res.freed


def test_release_pinned_idempotent_no_redundant_wait(logger, stub_device_ctx):
    """A second release() on an already-released host-accessible workspace must
    skip the stream.wait() — otherwise an unconditional cleanup-path release()
    would pay for a stream wait every time it runs after the first."""
    res = FakePinnedResource()
    ws = Workspace(res, logger=logger)
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        ws_ctx.release(event)
        assert holder.obj.waits == [event]

    ws.release(event)
    assert holder.obj.waits == [event]  # No additional wait — early return on ptr is None


def test_release_clears_allocated_here(make_workspace):
    """release() inside a `with` block clears allocated_here, so __exit__ on
    success becomes a no-op (it would otherwise try to call _reset on an already-
    cleared flag, which is fine but the invariant is testable)."""
    ws, _ = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        assert ws_ctx.allocated_here is True
        ws_ctx.release(None)
        assert ws_ctx.allocated_here is False

    # __exit__ ran; flag still False.
    assert ws.allocated_here is False


def test_release_device_resource_uses_stream_wait(logger, stub_device_ctx):
    """For a device-only MemoryResource, release() uses stream.wait(event) +
    stream-ordered Buffer.close(stream) — same ordering rule as the legacy
    device path, plus the stream-threaded close."""
    res = FakeDeviceResource()
    ws = Workspace(res, logger=logger)
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(event)

    assert holder.obj.waits == [event]
    assert holder.obj.syncs == 0
    assert res.deallocate_streams == [holder.obj]
    assert ws.ptr is None
    assert addr in res.freed


def test_memory_resource_reuse(logger, stub_device_ctx):
    """The reuse short-circuit applies uniformly across protocols: a second
    `with` block with the same size does not re-invoke allocate()."""
    res = FakePinnedResource()
    ws = Workspace(res, logger=logger)
    ws.set_size(512)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    with ws.allocate_perhaps(holder, get_last_event=None):
        pass

    assert len(res.calls) == 1


def test_memory_resource_atomic_rollback(logger, stub_device_ctx):
    """A MemoryResource.allocate() that raises in __enter__ triggers the
    inline rollback; the workspace's tracked state is cleared
    and the body never runs."""
    ws = Workspace(FailingResource(), logger=logger)
    ws.set_size(128)

    with pytest.raises(RuntimeError, match="allocate failed"), ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
        pytest.fail("body must not run when allocator raises in __enter__")

    assert ws.ptr is None
    assert ws.allocated_size == 0
    assert ws.allocated_here is False


# ---------------------------------------------------------------------------
# Context manager-specific behavior
# ---------------------------------------------------------------------------


def test_context_manager_resets_on_success(make_workspace):
    """The __exit__ success branch clears allocated_here — observable as
    allocated_here=False after the with block ends. ptr is preserved for reuse."""
    ws, _ = make_workspace()
    ws.set_size(128)
    with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None) as ws_ctx:
        assert ws_ctx.allocated_here is True
    assert ws.allocated_here is False
    # ptr is preserved for reuse on the next outer method.
    assert ws.ptr is not None


def test_context_manager_releases_on_exception(make_workspace):
    """The __exit__ exception branch frees a buffer this call allocated —
    observable as allocated_here=False, ptr=None, allocator's free was called."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()
    addr = None

    with pytest.raises(_Sentinel), ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        raise _Sentinel

    assert ws.allocated_here is False
    assert ws.ptr is None
    assert addr in alloc.freed


def test_context_manager_get_last_event_late_bound(make_workspace):
    """The get_last_event callable is read at __exit__ time, not __enter__ time —
    so a value the consumer assigns *inside* the block is what the exception
    path observes."""
    ws, _ = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()

    state = {"event": None}

    with pytest.raises(_Sentinel), ws.allocate_perhaps(holder, get_last_event=lambda: state["event"]):
        late_event = object()
        state["event"] = late_event  # Assigned mid-block
        raise _Sentinel

    # The mid-block-assigned event is what got waited on, not the None at __enter__.
    assert holder.obj.waits == [late_event]


def test_context_manager_case_a_reentrancy_check(logger, stub_device_ctx):
    """Manually setting allocated_here=True simulates a prior outer method leaking
    the flag. Entering a fresh `with` block must trip the case-A reentrancy
    check at __enter__, regardless of whether the body would have
    short-circuited or allocated fresh."""
    ws = Workspace(FakeAllocator(), logger=logger)
    ws.set_size(128)
    ws.allocated_here = True  # Simulate leak from prior outer method

    with pytest.raises(RuntimeError, match=r"allocated_here.*was True on entry"):  # noqa: SIM117
        with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
            pytest.fail("body must not run when __enter__ reentrancy check fires")


def test_nested_with_blocks_fire_case_a(make_workspace):
    """Nested `with` blocks on the same Workspace are a contract violation — the
    inner __enter__'s case-A reentrancy check catches them. The outer block
    remains valid; the RuntimeError propagates out via the inner __exit__'s
    exception branch (which frees the outer's buffer too — the outer block
    sees a workspace whose buffer was freed under it, but the error has
    already cancelled the program flow)."""
    ws, _ = make_workspace()
    ws.set_size(128)

    with pytest.raises(RuntimeError, match=r"allocated_here.*was True on entry"):  # noqa: SIM117
        with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
            with ws.allocate_perhaps(FakeStreamHolder(), get_last_event=None):
                pytest.fail("inner body must not run")


def test_release_within_with_block_clean_exit(make_workspace):
    """Calling release() mid-block clears allocated_here; the success-path
    __exit__'s allocated_here clear is then a redundant write."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()

    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(None)
        # Inside the block, post-release: ptr cleared, allocated_here cleared.
        assert ws_ctx.ptr is None
        assert ws_ctx.allocated_here is False

    # __exit__ saw allocated_here=False and did its no-op reset.
    assert ws.allocated_here is False
    assert addr in alloc.freed


def test_release_within_with_block_then_exception(make_workspace):
    """Release mid-block, then raise: __exit__ exception branch sees
    allocated_here=False (cleared by release) and skips redundant release;
    the buffer's free was already called by the explicit release."""
    ws, alloc = make_workspace()
    ws.set_size(128)
    holder = FakeStreamHolder()
    event = object()
    addr = None

    with pytest.raises(_Sentinel), ws.allocate_perhaps(holder, get_last_event=lambda: event) as ws_ctx:
        addr = ws_ctx.raw_ptr
        ws_ctx.release(event)
        assert holder.obj.waits == [event]  # Waited once, by the explicit release
        raise _Sentinel

    # Only the explicit release waited on the event; __exit__ saw allocated_here=False
    # and didn't issue another wait or free.
    assert holder.obj.waits == [event]
    assert addr in alloc.freed
    assert len([a for a in alloc.freed if a == addr]) == 1, "Buffer freed exactly once"
    assert ws.allocated_here is False


# ---------------------------------------------------------------------------
# Grow-path cleanup: the held buffer is released (with stream ordering) before
# the fresh allocation overwrites self.ptr. Without this, the old Buffer's
# __del__ would run unordered against any pending compute that was still
# reading it.
# ---------------------------------------------------------------------------


def test_grow_releases_old_buffer_with_event(make_workspace):
    """Grow path with a sync allocator: the old buffer's free was called before
    the second block's body runs, AND the consumer's event was waited on."""
    ws, alloc = make_workspace()
    holder = FakeStreamHolder()
    event = object()

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        small_addr = ws_ctx.raw_ptr

    ws.set_size(256)
    with ws.allocate_perhaps(holder, get_last_event=lambda: event) as ws_ctx:
        # Grow-cleanup release ran inside __enter__ before the fresh alloc.
        assert small_addr in alloc.freed
        assert holder.obj.waits == [event]
        assert ws_ctx.allocated_size == 256
        assert ws_ctx.raw_ptr != small_addr  # Fresh allocation


def test_grow_with_pinned_resource_stream_orders_close(logger, stub_device_ctx):
    """Host-accessible MemoryResource grow: release uses stream.wait(event) +
    stream-ordered Buffer.close(stream) — same path as device-only. The host is
    no longer blocked on a stream.sync() during pinned-buffer release. The
    consumer's get_last_event is honored, just like device-only."""
    res = FakePinnedResource()
    ws = Workspace(res, logger=logger)
    holder = FakeStreamHolder()
    event = object()

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        small_addr = ws_ctx.raw_ptr

    ws.set_size(256)
    with ws.allocate_perhaps(holder, get_last_event=lambda: event):
        # Grow-cleanup release ran inside __enter__ before the fresh alloc.
        assert holder.obj.syncs == 0  # No host sync
        assert holder.obj.waits == [event]
        assert small_addr in res.freed
        assert res.deallocate_streams == [holder.obj]  # close(stream) threaded


def test_grow_with_device_resource_uses_stream_wait(logger, stub_device_ctx):
    """Device-only MemoryResource grow: release uses stream.wait(event) +
    stream-ordered Buffer.close(stream). Verifies the get_last_event callable
    is what gets passed through to release on the device path."""
    res = FakeDeviceResource()
    ws = Workspace(res, logger=logger)
    holder = FakeStreamHolder()
    event = object()

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        small_addr = ws_ctx.raw_ptr

    ws.set_size(256)
    with ws.allocate_perhaps(holder, get_last_event=lambda: event):
        assert holder.obj.waits == [event]
        assert holder.obj.syncs == 0
        assert small_addr in res.freed
        assert res.deallocate_streams == [holder.obj]  # close(stream) threaded


def test_grow_failure_releases_old_buffer_then_lands_in_empty(logger, stub_device_ctx):
    """Grow failure: release-then-allocate ordering means the old buffer is
    cleanly freed BEFORE the new alloc is attempted. If the new alloc raises,
    the inline rollback clears state, and the workspace lands in Empty — but
    the old buffer was already cleaned up (no leak). Documents the
    release-then-allocate tradeoff: the consumer has lost the still-valid
    old buffer."""
    alloc = RaisesOnSecondCallAllocator()
    ws = Workspace(alloc, logger=logger)
    holder = FakeStreamHolder()
    event = object()

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=None) as ws_ctx:
        small_addr = ws_ctx.raw_ptr

    ws.set_size(256)
    with pytest.raises(RuntimeError, match="alloc failed"), ws.allocate_perhaps(holder, get_last_event=lambda: event):
        pytest.fail("body must not run when grow's fresh alloc raises")

    assert small_addr in alloc.freed  # Old buffer was released cleanly
    assert holder.obj.waits == [event]  # Stream wait happened during grow-cleanup
    assert ws.ptr is None  # inline rollback returned state to Empty
    assert ws.allocated_size == 0
    assert ws.allocated_here is False
    assert ws.stream is None


def test_grow_late_binds_event(make_workspace):
    """get_last_event is read at the next __enter__'s grow time, so a value
    updated *between* `with` blocks is what gets waited on. Proves the callable
    isn't captured at the prior block's exit time."""
    ws, alloc = make_workspace()
    holder = FakeStreamHolder()

    state = {"event": None}

    ws.set_size(128)
    with ws.allocate_perhaps(holder, get_last_event=lambda: state["event"]):
        small_addr = ws.raw_ptr
        state["event"] = object()  # Consumer records a compute event mid-block.
    first_event = state["event"]

    # Update the consumer's tracked event before the next outer method.
    state["event"] = object()
    second_event = state["event"]

    ws.set_size(256)
    with ws.allocate_perhaps(holder, get_last_event=lambda: state["event"]):
        assert small_addr in alloc.freed
        # Late binding: the *current* value of state["event"] is what got waited on.
        assert holder.obj.waits == [second_event]
        assert second_event is not first_event


# ---------------------------------------------------------------------------
# NumpyMemoryResource (host-only MemoryResource, no CUDA driver involvement)
# ---------------------------------------------------------------------------


class TestNumpyMemoryResource:
    """Unit tests for NumpyMemoryResource in isolation.

    These tests do not exercise Workspace; they verify the MR satisfies the
    cuda.core.MemoryResource contract on its own — same level of granularity
    as the existing _FakeResource / FakePinnedResource tests, but with real
    NumPy-backed allocations so we can also assert ctypes round-trip.
    """

    def test_accessibility_flags(self):
        mr = NumpyMemoryResource()
        assert mr.is_host_accessible is True
        assert mr.is_device_accessible is False
        assert mr.device_id == -1

    def test_allocate_returns_buffer_with_size_and_handle(self):
        mr = NumpyMemoryResource()
        buf = mr.allocate(64)
        assert buf.size == 64
        assert int(buf.handle) != 0  # numpy.empty(64) yields a real address

    def test_distinct_allocations_have_distinct_handles(self):
        mr = NumpyMemoryResource()
        a = mr.allocate(64)
        b = mr.allocate(64)
        assert int(a.handle) != int(b.handle)

    def test_deallocate_removes_strong_ref_from_held(self):
        mr = NumpyMemoryResource()
        buf = mr.allocate(32)
        ptr = int(buf.handle)
        assert ptr in mr._held  # white-box: held keyed by ptr
        mr.deallocate(ptr, 32)
        assert ptr not in mr._held

    def test_deallocate_unknown_ptr_is_noop(self):
        # We use dict.pop(..., None), so a stray deallocate must not raise.
        mr = NumpyMemoryResource()
        mr.deallocate(0xDEADBEEF, 16)  # never allocated through us

    def test_ctypes_roundtrip_writes_visible_in_held_array(self):
        """Bytes written through Buffer.handle land in the retained ndarray."""
        import ctypes

        import numpy as np

        mr = NumpyMemoryResource()
        buf = mr.allocate(32)
        ptr = int(buf.handle)
        c_view = (ctypes.c_char * 32).from_address(ptr)
        # Write a known pattern via the raw C buffer view.
        c_view[:8] = b"abcdefgh"
        retained = mr._held[ptr]
        # The retained ndarray (uint8) must reflect the same bytes.
        assert bytes(retained[:8].tobytes()) == b"abcdefgh"
        # And a NumPy view built from the address agrees.
        ndview = np.ndarray(shape=(32,), dtype=np.uint8, buffer=c_view)
        assert bytes(ndview[:8].tobytes()) == b"abcdefgh"

    def test_zero_byte_allocation_safe(self):
        """allocate(0) must not crash; deallocate(0-sized) must be balanced.

        numpy.empty(0) is well-defined and has a valid (if non-dereferenceable)
        ctypes.data; we just need the lifecycle to round-trip cleanly.
        """
        mr = NumpyMemoryResource()
        buf = mr.allocate(0)
        assert buf.size == 0
        ptr = int(buf.handle)
        # ptr may be zero or non-zero depending on platform/NumPy version; either
        # way the resource must allow deallocation without raising.
        mr.deallocate(ptr, 0)
        assert ptr not in mr._held

    def test_allocate_ignores_stream_argument(self):
        """Stream argument is documented as ignored on host-only MRs."""
        mr = NumpyMemoryResource()
        # Pass an arbitrary non-None object to confirm we don't try to use it.
        sentinel = object()
        buf = mr.allocate(8, stream=sentinel)
        assert buf.size == 8
        mr.deallocate(int(buf.handle), 8, stream=sentinel)


# ---------------------------------------------------------------------------
# Workspace in CUDA-less mode (allocator is_device_accessible=False)
# ---------------------------------------------------------------------------


@pytest.fixture
def trip_device_ctx(monkeypatch):
    """Replace ``utils.device_ctx`` with a function that fails if entered.

    Distinct from ``stub_device_ctx`` (which silently no-ops), this fixture
    *asserts* that the host-only ``Workspace`` path never enters the device
    context. If the implementation accidentally calls ``device_ctx`` for a
    host-only allocator, the test surfaces it as a clean failure.
    """

    def _ctx(device_id):
        raise AssertionError(f"device_ctx({device_id}) was entered in a path expected to be CUDA-free.")

    monkeypatch.setattr("nvmath.internal.utils.device_ctx", _ctx)


class TestCUDAlessWorkspace:
    """Workspace running with no CUDA driver involvement.

    Triggered when the allocator is a ``cuda.core.MemoryResource`` with
    ``is_device_accessible=False`` (e.g. ``NumpyMemoryResource``). These tests
    install a tripwire on ``utils.device_ctx`` to assert the host-only path
    really doesn't reach into the CUDA driver.
    """

    def test_numpy_mr_no_device_ctx_no_stream(self, logger, trip_device_ctx):
        """Allocate via NumpyMemoryResource without entering device_ctx or
        a stream context. raw_ptr is a usable host address (ctypes round-trip)."""
        import ctypes

        mr = NumpyMemoryResource()
        ws = Workspace(mr, logger=logger)
        ws.set_size(64)
        with ws.allocate_perhaps(None, get_last_event=None):
            addr = ws.raw_ptr
            assert addr != 0
            buf = (ctypes.c_char * 64).from_address(addr)
            buf[:8] = b"abcdefgh"
            # The retained ndarray reflects what we wrote through ctypes.
            assert bytes(mr._held[addr][:8].tobytes()) == b"abcdefgh"
            # No CUDA stream was retained on Workspace.
            assert ws.stream is None
        # On normal exit the buffer is kept for reuse, like every other path.
        assert ws.ptr is not None
        assert ws.allocated_size == 64

    def test_pinned_resource_uses_device_path(self, logger, stub_device_ctx):
        """PinnedMemoryResource is host-accessible AND device-accessible (mapped),
        so it needs the stream for ordered close. The host-only dispatch must
        NOT trigger for it."""
        res = FakePinnedResource()  # is_device_accessible=True (pinned/mapped)
        ws = Workspace(res, logger=logger)
        assert ws._is_device_accessible is True
        ws.set_size(128)
        holder = FakeStreamHolder()
        with ws.allocate_perhaps(holder, get_last_event=None):
            # Real stream threaded through the allocator and retained.
            assert ws.stream is holder.obj
            assert res.calls == [("allocate", 128, holder.obj)]

    def test_pinned_with_none_stream_holder_raises_type_error(self, logger, stub_device_ctx):
        """Defensive: a device-accessible MR with stream_holder=None is a
        programming error (the resource needs the stream for ordered close)."""
        res = FakePinnedResource()
        ws = Workspace(res, logger=logger)
        ws.set_size(32)
        with pytest.raises(TypeError, match="requires stream_holder"), ws.allocate_perhaps(None, get_last_event=None):
            pass

    def test_release_passes_none_stream_to_buffer_close(self, logger, trip_device_ctx):
        """release() in host-only mode (NumpyMemoryResource) must invoke
        Buffer.close(stream=None) — no stream wait, no device_ctx, but the
        dealloc must still fire."""
        mr = NumpyMemoryResource()  # is_device_accessible=False → host-only path
        ws = Workspace(mr, logger=logger)
        ws.set_size(64)
        with ws.allocate_perhaps(None, get_last_event=None) as ws_ctx:
            addr = ws_ctx.raw_ptr
            assert addr in mr._held
            ws_ctx.release(None)
            assert addr not in mr._held  # deallocate fired with stream=None
        assert ws.ptr is None

    def test_is_device_accessible_cache_per_allocator_kind(self, logger):
        """_is_device_accessible mirrors the allocator's cuda.core property and
        drives the device + stream context dispatch."""
        # Numpy MR (not device-accessible).
        assert Workspace(NumpyMemoryResource(), logger=logger)._is_device_accessible is False
        # Pinned MR (host-accessible AND device-accessible — pinned memory is mapped).
        assert Workspace(FakePinnedResource(), logger=logger)._is_device_accessible is True
        # Device-only MR.
        assert Workspace(FakeDeviceResource(), logger=logger)._is_device_accessible is True
        # Legacy allocators are not MemoryResource — device-accessible by default.
        assert Workspace(FakeAllocator(), logger=logger)._is_device_accessible is True

    def test_grow_path_works_without_cuda(self, logger, trip_device_ctx):
        """set_size(small) -> allocate -> set_size(big) -> allocate releases
        the old buffer and allocates a new one, all without CUDA."""
        mr = NumpyMemoryResource()
        ws = Workspace(mr, logger=logger)
        ws.set_size(32)
        with ws.allocate_perhaps(None, get_last_event=None):
            small_addr = ws.raw_ptr
        assert small_addr in mr._held
        ws.set_size(256)
        with ws.allocate_perhaps(None, get_last_event=None):
            big_addr = ws.raw_ptr
            assert big_addr != small_addr
            assert ws.allocated_size == 256
        # Old buffer was released on the grow path.
        assert small_addr not in mr._held

    def test_zero_byte_with_memory_resource_does_not_take_legacy_shortcut(self, logger, trip_device_ctx):
        """The 0-byte fast path that returns a MemoryPointer(0,0) sentinel only
        fires for legacy allocators. With a MemoryResource (NumpyMemoryResource
        here), allocate(0) is dispatched normally and yields a real Buffer."""
        mr = NumpyMemoryResource()
        ws = Workspace(mr, logger=logger)
        ws.set_size(0)
        with ws.allocate_perhaps(None, get_last_event=None):
            # Real Buffer of size 0, not a sentinel MemoryPointer.
            assert ws.ptr is not None
            assert ws.size == 0
            # raw_ptr returns whatever numpy.empty(0) yielded (well-defined int).
            _ = ws.raw_ptr  # must not raise

    def test_device_path_unchanged_with_real_stream_holder(self, logger, stub_device_ctx):
        """Regression guard: a device-accessible MR with a real stream_holder
        still enters device_ctx and threads the stream through allocator + release."""
        # Use stub_device_ctx (yields None) — the host-only branch must NOT
        # be selected here, but we still want to skip a real CUDA device.
        res = FakePinnedResource()
        ws = Workspace(res, logger=logger)
        ws.set_size(32)
        holder = FakeStreamHolder()
        with ws.allocate_perhaps(holder, get_last_event=None):
            assert ws.stream is holder.obj
            assert res.calls == [("allocate", 32, holder.obj)]

    def test_numpy_view_typed_roundtrip_via_ctypes(self, logger, trip_device_ctx):
        """End-to-end shape that the planned NumPyWorkspaceView wraps: build a
        typed numpy view over the workspace buffer, fill via numpy, read back.

        Until NumPyWorkspaceView lands (see internal/design/NUMPYVIEW.md), this
        validates the underlying contract: NumpyMemoryResource + Workspace +
        ctypes.from_address + np.ndarray(buffer=...) round-trip cleanly.
        """
        import ctypes

        import numpy as np

        mr = NumpyMemoryResource()
        ws = Workspace(mr, logger=logger)
        ws.set_size(64)  # 16 float32 elements
        with ws.allocate_perhaps(None, get_last_event=None):
            addr = ws.raw_ptr
            c_buf = (ctypes.c_char * 64).from_address(addr)
            view = np.ndarray(shape=(16,), dtype=np.float32, buffer=c_buf)
            view[:] = np.arange(16, dtype=np.float32)
            # Re-derive the view to confirm the writes are persisted in the
            # underlying buffer (not just an unrelated copy).
            view2 = np.ndarray(shape=(16,), dtype=np.float32, buffer=c_buf)
            np.testing.assert_array_equal(view2, np.arange(16, dtype=np.float32))

    def test_third_party_device_allocator_without_device_id_attr_requires_explicit_kwarg(self, logger):
        """Workspace pulls device_id from the allocator by default. A third-party
        legacy allocator that doesn't expose device_id (e.g. doesn't follow the
        in-tree convention) must either grow the attribute or pass device_id
        explicitly to Workspace; otherwise construction fails fast."""

        class ThirdPartyAlloc:
            """Conforms to BaseCUDAMemoryManager Protocol but lacks device_id."""

            def memalloc(self, size: int) -> MemoryPointer:
                return MemoryPointer(0xDEADBEEF, size, finalizer=None)

        # Default path: no device_id on allocator, none passed → TypeError.
        with pytest.raises(TypeError, match="could not infer device_id"):
            Workspace(ThirdPartyAlloc(), logger=logger)

        # Escape hatch: passing device_id explicitly succeeds.
        ws = Workspace(ThirdPartyAlloc(), logger=logger, device_id=0)
        assert ws._device_id == 0
        assert ws._is_device_accessible is True
