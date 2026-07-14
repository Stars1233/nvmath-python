# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/04_Symmetric_Eigenvalues/heev_batched_block.cu
#

import sys
import warnings
from pathlib import Path

import numpy as np
import scipy.linalg
from numba_cuda_mlir import cuda

from nvmath.device import Solver

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import prepare_random_matrix, verify_relative_error  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_strided, store_from_shared_strided  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-3,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-8

BLOCKS = 128


def main():
    solver = Solver(
        function="heev",
        size=(16, 16, 1),
        precision=np.float32,
        data_type="complex",
        fill_mode="upper",
        arrangement=("row_major", "row_major"),
        job="overwrite_vectors",
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    m = solver.m
    lda = solver.lda
    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_a = m * lda * bpb
    n_lambda = m * bpb
    a_strides = (m * lda, lda, 1)
    a_shape_t = (bpb, m, m)

    n_workspace = solver.workspace_size

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(a, lam, info):
        smem_a = cuda.shared.array(n_a, dtype=solver.value_type)
        smem_lambda = cuda.shared.array(n_lambda, dtype=solver.precision)
        smem_workspace = cuda.shared.array(n_workspace, dtype=solver.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(a[base_sample_idx:], smem_a, a_shape_t, a_strides)
        cuda.syncthreads()

        solver.execute(smem_a, smem_lambda, smem_workspace, info[base_sample_idx:])
        cuda.syncthreads()

        store_from_shared_strided(smem_a, a[base_sample_idx:], a_shape_t, a_strides)
        store_from_shared_strided(smem_lambda, lam[base_sample_idx:], (bpb, m), (m, 1))

    a = prepare_random_matrix(
        (batch_count, m, m),
        dtype=solver.precision,
        is_complex=True,
        is_hermitian=True,
    )
    a_input = a.copy()

    a_d = cuda.to_device(a)
    lambda_d = cuda.device_array((batch_count, m), dtype=solver.precision)
    info_d = cuda.device_array(batch_count, dtype=solver.info_type)

    kernel[BLOCKS, solver.block_dim](a_d, lambda_d, info_d)
    cuda.synchronize()

    v_result = a_d.copy_to_host()
    lambda_result = lambda_d.copy_to_host()
    info_result = info_d.copy_to_host()

    for sample_idx in range(batch_count):
        if info_result[sample_idx] != 0:
            raise RuntimeError(f"{info_result[sample_idx]}-th parameter is wrong for sample idx={sample_idx}")

    rel_tol = _PREC_TABLE[solver.precision]
    error_sum_lambda = 0.0
    error_sum_residual = 0.0
    for sample_idx in range(batch_count):
        # 1. Compare eigenvalues with scipy reference
        lambda_ref = np.sort(scipy.linalg.eigvalsh(a_input[sample_idx]))
        lambda_dx = np.sort(lambda_result[sample_idx])
        error_sum_lambda += verify_relative_error(lambda_dx, lambda_ref, rel_tol, _ABS_ERR, solver)

        # 2. Verify eigenvector property: A @ V = V @ diag(lambda)
        v_b = v_result[sample_idx]
        a_v = a_input[sample_idx] @ v_b
        v_lam = v_b * lambda_result[sample_idx]
        error_sum_residual += verify_relative_error(a_v, v_lam, rel_tol, _ABS_ERR, solver)

    print("HEEV: relative error of eigenvalues vs scipy: ", error_sum_lambda)
    print("HEEV: relative error of A @ V - V @ diag(lambda): ", error_sum_residual)
    print("Successfully validated batched HEEV against scipy reference.")


if __name__ == "__main__":
    main()
