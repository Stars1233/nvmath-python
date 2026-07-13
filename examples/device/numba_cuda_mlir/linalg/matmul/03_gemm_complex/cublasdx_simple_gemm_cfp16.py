# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuBLASDx/03_gemm_complex/simple_gemm_cfp16.cu
#
# NOTE: Run this with NUMBA_CUDA_MLIR_DISABLE_LTO_OPT=1. With the default LTO
# optimization level, a known numba-cuda-mlir LTO linking bug can erase
# float16/bfloat16 (and their vector type) stores, producing wrong results.
# BUG: https://github.com/NVIDIA/numba-cuda-mlir/pull/122
#

import sys
from pathlib import Path

import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import Matmul

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import random_complex  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared, store_from_shared  # type: ignore[misc, import-not-found]


def main():
    m, n, k = 64, 64, 64

    MM = Matmul(
        size=(m, n, k),
        precision=np.float16,
        data_type="complex",
        arrangement=("row_major", "col_major", "col_major"),
        execution="Block",
    )

    # BUG: https://github.com/NVIDIA/numba-cuda-mlir/issues/110
    lda, ldb, ldc = MM.leading_dimension

    @cuda.jit
    def f(a, b, c, alpha, beta, output):
        # all value types are the same
        smem = cuda.shared.array(shape=(0,), dtype=MM.a_value_type)
        smem_a = smem[0:]
        smem_b = smem[MM.a_size :]
        smem_c = smem[MM.a_size + MM.b_size :]

        load_to_shared(a, smem_a, MM.a_dim, lda, row_major=True)
        load_to_shared(b, smem_b, MM.b_dim, ldb)
        load_to_shared(c, smem_c, MM.c_dim, ldc)

        cuda.syncthreads()

        MM.execute(alpha, smem_a, smem_b, beta, smem_c)

        cuda.syncthreads()

        store_from_shared(smem_c, output, MM.c_dim, ldc)

    # Note: Numpy does not have a complex<half>
    # so those are really arrays of complex64.
    a = random_complex(MM.a_dim, np.float16)
    b = random_complex(MM.b_dim, np.float16)
    c = random_complex(MM.c_dim, np.float16)
    o = np.zeros_like(c)

    a_d = cuda.to_device(a)
    b_d = cuda.to_device(b)
    c_d = cuda.to_device(c)
    o_d = cuda.to_device(o)

    alpha = 1 + 1j
    beta = 2 + 2j

    # The numba-cuda-mlir launcher only opts in to the larger dynamic shared
    # memory limit when the requested size is strictly greater than 48 KiB. At
    # exactly 48 KiB the opt-in is skipped, and the kernel's few bytes of static
    # shared memory then push the block over the default limit, failing the
    # launch with CUDA_ERROR_INVALID_VALUE. Request one byte past the threshold
    # to force the opt-in; the extra byte is harmless.
    # BUG: https://github.com/NVIDIA/numba-cuda-mlir/issues/143
    smem = MM.get_shared_storage_size()
    launch_smem = max(smem, 48 * 1024 + 1)

    f[1, MM.block_dim, 0, launch_smem](a_d, b_d, c_d, alpha, beta, o_d)
    cuda.synchronize()

    data_test = o_d.copy_to_host()
    data_ref = alpha * (a @ b) + beta * c
    error = np.linalg.norm(data_test - data_ref) / np.linalg.norm(data_ref)
    assert error < 1e-2


if __name__ == "__main__":
    main()
