# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Reusable per-thread data structures."""

import sys
import threading
import typing
import weakref

__all__ = ["HandleCache"]

Key = typing.TypeVar("Key")


class _CachedHandle(typing.Generic[Key]):
    # A raw integer handle cannot be the referent of `weakref.finalize`, so we wrap it in
    # this object and attach the finalizer to the wrapper. The finalizer fires when the
    # wrapper is garbage-collected — i.e. when the owning thread's `threading.local` storage
    # is dropped, or at interpreter shutdown.

    __slots__ = ("handle", "__weakref__")

    handle: typing.Final[int]

    def __init__(self, key: Key, create: typing.Callable[[Key], int], destroy: typing.Callable[[int], None]):
        self.handle = create(key)

        def finalize(handle: int) -> None:
            # `destroy` is the binding-agnostic callable injected by the consumer. It is
            # expected to be safe to run on any thread regardless of the current device:
            # e.g. `cublasDestroy` / `cublasLtDestroy` each internally call
            # `cudaDeviceSynchronize()` on the handle's own device. That matters because the
            # finalizer may run on whichever thread garbage-collects the cached handle, not
            # necessarily the one that created it.
            try:
                destroy(handle)
            except Exception:
                # Tolerate destroy failures only at interpreter shutdown, where the bindings
                # module may already be partially torn down. Outside shutdown a destroy
                # failure is a real bug; re-raising surfaces it as the standard "Exception
                # ignored in:" message from the finalizer rather than silently leaking the
                # handle.
                if not sys.is_finalizing():
                    raise

        weakref.finalize(self, finalize, self.handle)


class HandleCache(typing.Generic[Key]):
    """Per-thread cache of integer library handles, keyed by an opaque key.

    The key is any hashable the caller chooses: a bare ``device_id``, or a tuple such as
    ``(device_id, ...)`` for libraries that need to distinguish handles by more than device.
    The cache never interprets the key — only the injected ``create`` callable does. Because
    the caching behavior is per-thread, keys only have to be unique per-thread.

    Args:

        create: ``create(key) -> int`` makes a new handle for ``key``. The
            callable must perform any device-context handling it needs.

        destroy: ``destroy(handle) -> None`` destroys a handle. It is invoked
            from ``weakref.finalize`` when the owning thread or the interpreter exits, so
            must be able to run on a different thread than the one that created the handle.

    Examples:

    .. code-block:: python

        from nvmath._internal import threadsafe


        def create_handle(device_id: int) -> int:
            with utils.device_ctx(device_id):
                return cublas.create()


        threadsafe.HandleCache[int](
            create=create_handle,
            destroy=cublas.destroy,
        )

    """

    __slots__ = ("_create", "_destroy", "_tls")

    def __init__(self, create: typing.Callable[[Key], int], destroy: typing.Callable[[int], None]):
        self._create = create
        self._destroy = destroy
        # Per-thread storage; each thread mutates only its own `cache` dict, so
        # no lock is required.
        self._tls = threading.local()

    def get(self, key: Key) -> int:
        """Return the cached handle for ``key`` on the current thread."""
        try:
            cache = self._tls.cache
        except AttributeError:
            cache = self._tls.cache = {}
        item = cache.get(key)
        if item is None:
            item = _CachedHandle(key, self._create, self._destroy)
            cache[key] = item
        return item.handle
