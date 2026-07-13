# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuBLASDx/01_gemm_introduction/introduction_example.cu
#
# This example demonstrates the basic shared memory API: the A, B and C matrices
# are staged in shared memory and ``MM.execute`` computes
# ``C = alpha * A * B + beta * C`` in place. It intentionally avoids the advanced
# tensor APIs (e.g. ``get_layout_*``).
#

import sys
from pathlib import Path

import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import Matmul

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import random_real  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_2d, store_from_shared_2d  # type: ignore[misc, import-not-found]


def main():
    m, n, k = 32, 32, 32
    block_size = 256

    MM = Matmul(
        size=(m, n, k),
        precision=np.float64,
        data_type="real",
        arrangement=("row_major", "col_major", "col_major"),
        execution="Block",
        block_size=block_size,
    )

    b_dim_rev, c_dim_rev = MM.b_dim[::-1], MM.c_dim[::-1]

    @cuda.jit
    def f(a, b, c, alpha, beta, output):
        smem_a = cuda.shared.array(shape=MM.a_dim, dtype=MM.a_value_type)
        # cuBLASDx requires column-major arrays but cuda.shared.array creates row-major
        # arrays (only) so we emulate a column-major array by flipping dimensions
        smem_b = cuda.shared.array(shape=b_dim_rev, dtype=MM.b_value_type)
        smem_c = cuda.shared.array(shape=c_dim_rev, dtype=MM.c_value_type)

        load_to_shared_2d(a, smem_a, MM.a_dim, row_major=True)
        load_to_shared_2d(b, smem_b, MM.b_dim)
        load_to_shared_2d(c, smem_c, MM.c_dim)

        cuda.syncthreads()

        MM.execute(alpha, smem_a, smem_b, beta, smem_c)

        cuda.syncthreads()

        store_from_shared_2d(smem_c, output, MM.c_dim)

    a = random_real(MM.a_dim, np.float64)
    b = random_real(MM.b_dim, np.float64)
    c = random_real(MM.c_dim, np.float64)
    o = np.zeros_like(c)

    a_d = cuda.to_device(a)
    b_d = cuda.to_device(b)
    c_d = cuda.to_device(c)
    o_d = cuda.to_device(o)

    alpha = 1.0
    beta = 1.0

    f[1, MM.block_dim](a_d, b_d, c_d, alpha, beta, o_d)
    cuda.synchronize()

    data_test = o_d.copy_to_host()
    data_ref = alpha * (a @ b) + beta * c
    error = np.linalg.norm(data_test - data_ref) / np.linalg.norm(data_ref)
    assert error < 1e-10


if __name__ == "__main__":
    main()
