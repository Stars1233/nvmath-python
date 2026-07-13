# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import numpy as np
import pytest

import nvmath
from nvmath_tests.helpers import print_aligned_table, time_cupy

cupy = pytest.importorskip("cupy")


def run_test(data, n, nrhs, precision, *, batch_count=None, ncycles=10, seed=23):
    rng = cupy.random.default_rng(seed)
    A_shape = (n, n) if batch_count is None else (batch_count, n, n)
    B_shape = (n, nrhs) if batch_count is None else (batch_count, n, nrhs)
    A = rng.random(A_shape).astype(precision) * 0.1 + cupy.eye(n, dtype=precision)
    B = rng.random(B_shape).astype(precision)

    stream = cupy.cuda.get_current_stream()

    with nvmath.linalg.generic.DirectSolver(A, B, stream=stream) as solver:
        solver.plan()

        def execute():
            solver.reset_operands(a=A, b=B, stream=stream)
            solver.factorize(stream=stream)
            solver.solve(stream=stream)

        time_nvmath = time_cupy(execute, ncycles)

    time_cp = time_cupy(lambda: cupy.linalg.solve(A, B), ncycles)

    data.append(
        {
            "precision": precision.__name__,
            "n": n,
            "nrhs": nrhs,
            "batch_count": batch_count,
            "nvmath-python [ms]": time_nvmath["time_ms"],
            "cupy [ms]": time_cp["time_ms"],
            "dataset_size [MiB]": (A.nbytes + B.nbytes) / (2**20),
            "speedup nvmath-python over cupy": time_cp["time_ms"] / time_nvmath["time_ms"],
        }
    )


def test_non_batched_solver_perf():
    batch_count = None
    seed = 23
    data = []
    for precision in [np.float32, np.float64, np.complex64, np.complex128]:
        for n in [2**i for i in range(5, 14)]:
            nrhs = max(n // 2, 1)
            run_test(data, n, nrhs, precision, batch_count=batch_count, seed=seed, ncycles=10)
    print("\n")
    cols = [
        "precision",
        "n",
        "nrhs",
        "dataset_size [MiB]",
        "nvmath-python [ms]",
        "cupy [ms]",
        "speedup nvmath-python over cupy",
    ]
    print_aligned_table(cols, data)


def test_batched_solver_perf():
    n = 512
    nrhs = n // 2
    seed = 23
    data = []
    for precision in [np.float32, np.float64]:
        for batch_count in (1, 4, 16, 64, 256):
            run_test(data, n, nrhs, precision, batch_count=batch_count, seed=seed, ncycles=10)
    print("\n")
    cols = [
        "precision",
        "n",
        "nrhs",
        "batch_count",
        "dataset_size [MiB]",
        "nvmath-python [ms]",
        "cupy [ms]",
        "speedup nvmath-python over cupy",
    ]
    print_aligned_table(cols, data)
