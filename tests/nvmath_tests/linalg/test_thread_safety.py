# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Thread-safety regression tests for the linalg cuBLAS / cuBLASLt handle cache
and the documented per-instance contract of the stateful Matmul classes.
"""

import threading

import numpy as np
import pytest
from cuda.core import Device

import nvmath
from nvmath.linalg._internal import utils as linalg_utils


@pytest.fixture(scope="module")
def device_id() -> int:
    return Device().device_id


# NOTE: cublaslt handles are non-unique per thread except for CTK 12.9
@pytest.mark.parametrize("binding", ["cublas"])
def test_handle_cache_per_thread(device_id, binding):
    """
    `get_handle()` must return a distinct handle for each calling thread,
    even when many threads request a handle for the same device
    simultaneously.
    """
    num_threads = 8
    barrier = threading.Barrier(num_threads)
    end_barrier = threading.Barrier(num_threads)
    handles: list[int | None] = [None] * num_threads
    errors: list[BaseException] = []

    def worker(i: int) -> None:
        try:
            barrier.wait()
            handles[i] = linalg_utils.get_handle(device_id, binding=binding)
            end_barrier.wait()
        except BaseException as e:
            errors.append(e)
            # Unblock any peers so the test fails fast
            # instead of deadlocking on `end_barrier`.
            end_barrier.abort()

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(num_threads)]
    for t in threads:
        t.start()

    for t in threads:
        t.join()

    assert not errors, f"workers raised: {errors}"
    assert all(h is not None for h in handles)
    assert len(set(handles)) == num_threads, (
        f"expected {num_threads} distinct handles, got {len(set(handles))} "
        f"({handles}); cache is not delivering per-thread isolation. "
        f"If got==1, the installed nvmath likely predates the thread-safe "
        f"handle cache -- see test_installed_nvmath_is_thread_safe_build."
    )


@pytest.mark.parametrize("api", ["advanced", "generic"])
def test_matmul_concurrent_distinct_instances(device_id, api):
    """
    Documented contract: distinct :class:`Matmul` instances on distinct
    streams are safe to use from distinct threads. This test exercises the
    contract end-to-end across 8 threads (with NumPy operands and per-thread
    cuda.core streams) for both the advanced (cuBLASLt) and generic (cuBLAS)
    Matmul APIs, and verifies all per-thread results agree with a
    single-threaded reference.
    """
    if api == "advanced":

        def make_matmul(a, b, stream):
            return nvmath.linalg.advanced.Matmul(a, b, stream=stream)
    else:
        execution = nvmath.linalg.ExecutionCUDA(device_id=device_id)

        def make_matmul(a, b, stream):
            return nvmath.linalg.Matmul(a, b, execution=execution, stream=stream)

    num_threads = 8
    m, n, k = 64, 64, 64

    rng = np.random.default_rng(0)
    a = rng.random((m, k), dtype=np.float32)
    b = rng.random((k, n), dtype=np.float32)
    reference = a @ b

    barrier = threading.Barrier(num_threads)
    results: list[np.ndarray | None] = [None] * num_threads
    errors: list[BaseException] = []

    def worker(i: int) -> None:
        try:
            device = Device(device_id)
            device.set_current()
            stream = device.create_stream()
            barrier.wait()
            with make_matmul(a, b, stream) as mm:
                mm.plan(stream=stream)
                out = mm.execute(stream=stream)
            results[i] = out
        except BaseException as e:
            errors.append(e)

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(num_threads)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert not errors, f"workers raised: {errors}"
    assert all(r is not None for r in results)
    for i, r in enumerate(results):
        np.testing.assert_allclose(r, reference, rtol=1e-4, atol=1e-4, err_msg=f"thread {i}")
