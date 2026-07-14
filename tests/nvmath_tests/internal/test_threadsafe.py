# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import gc
import itertools
import threading

from nvmath._internal import threadsafe


def _counting_create():
    """Return a ``create`` callable that hands out a fresh unique int per call,
    plus the list recording every key it was called with."""
    calls: list = []
    # `next` on an itertools.count is a single atomic C call, so handles stay
    # unique even when threads create concurrently (unlike `len(calls)`, which
    # would race against the separate `append`).
    counter = itertools.count(1)

    def create(key) -> int:
        calls.append(key)
        # Distinct, nonzero handle per call so identity comparisons are meaningful.
        return next(counter)

    return create, calls


def test_handle_destroyed_on_thread_exit():
    """
    A handle cached by a worker thread must be destroyed once the worker's
    ``Thread`` object becomes unreachable, not held until process exit.
    """
    create, _ = _counting_create()
    destroyed: list[int] = []
    cache = threadsafe.HandleCache[int](create=create, destroy=destroyed.append)

    captured: list[int] = []

    def worker() -> None:
        captured.append(cache.get(0))

    t = threading.Thread(target=worker)
    t.start()
    t.join()
    del t

    # The destroy chain -- Thread object collected -> threading.local cleanup
    # drops the worker's `_tls.cache` -> `_CachedHandle` refcount -> 0 ->
    # `weakref.finalize` fires `destroy` -- usually completes on the first GC
    # pass under CPython, but frames pinned by pytest-cov, tracemalloc, or
    # PYTHONDEVMODE can require another. Loop until observed, capped to keep
    # failures bounded.
    handle = captured[0] if captured else None
    for _ in range(10):
        gc.collect()
        if handle in destroyed:
            break

    assert captured, "worker did not record a handle"
    assert captured[0] in destroyed, (
        f"expected handle {captured[0]} to be destroyed after the worker thread exited; saw destroys: {destroyed}"
    )


def test_get_caches_per_thread():
    """Repeated ``get`` for the same key on one thread returns the same handle
    and only creates it once."""
    create, calls = _counting_create()
    cache = threadsafe.HandleCache[int](create=create, destroy=lambda h: None)

    first = cache.get(7)
    again = cache.get(7)

    assert first == again
    assert calls == [7], f"expected a single create for key 7, got {calls}"


def test_distinct_threads_get_distinct_handles():
    """Each thread owns its own cache, so concurrent ``get`` calls for the same
    key return a distinct handle per thread (pure-unit analog of the GPU
    ``test_handle_cache_per_thread``)."""
    create, _ = _counting_create()
    cache = threadsafe.HandleCache[int](create=create, destroy=lambda h: None)

    num_threads = 8
    barrier = threading.Barrier(num_threads)
    handles: list[int | None] = [None] * num_threads
    errors: list[BaseException] = []

    def worker(i: int) -> None:
        try:
            barrier.wait()
            handles[i] = cache.get(0)
        except BaseException as e:
            errors.append(e)
            barrier.abort()

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(num_threads)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert not errors, f"workers raised: {errors}"
    assert all(h is not None for h in handles)
    assert len(set(handles)) == num_threads, (
        f"expected {num_threads} distinct per-thread handles, got {len(set(handles))} ({handles})"
    )
