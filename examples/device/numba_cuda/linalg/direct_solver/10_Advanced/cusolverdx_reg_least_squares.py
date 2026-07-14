# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/10_Advanced/reg_least_squares.cu
#

# Solves min ||b - A x||^2 + lambda^2 ||x||^2 by reducing to an unregularized
# least-squares problem on the augmented (M+N) x N system [A; lambda*I] x = [b; 0].
# Note: like upstream, lambda goes on the diagonal directly (the effective
# regularization weight in objective space is lambda^2).

import sys
import warnings
from pathlib import Path

import numpy as np
from numba import cuda

from nvmath.device import LeastSquaresSolver

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import prepare_random_matrix, verify_relative_error  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-4,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-8

M = 100
N = 8
LAMBDA = 0.1
BLOCKS = 1024


def main():
    solver = LeastSquaresSolver(
        size=(M + N, N, 1),
        precision=np.float32,
        data_type="real",
        arrangement=("col_major", "col_major"),
        transpose_mode="non_transposed",
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_a = solver.a_size()
    n_bx = solver.bx_size()
    n_tau = solver.tau_size

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(a_top, b_top, x_out):
        smem_a = cuda.shared.array(n_a, dtype=solver.value_type)
        smem_bx = cuda.shared.array(n_bx, dtype=solver.value_type)
        smem_tau = cuda.shared.array(n_tau, dtype=solver.value_type)

        base = cuda.blockIdx.x * bpb
        tid = cuda.threadIdx.x
        bdim = cuda.blockDim.x * cuda.blockDim.y * cuda.blockDim.z

        # Build augmented As = [A; lambda*I] (col-major, lda = M+N) and bs = [b; 0]
        for s in range(bpb):
            for idx in range(tid, M * N, bdim):
                col = idx // M
                row = idx % M
                smem_a[s * (M + N) * N + col * (M + N) + row] = a_top[base + s, row, col]
            for idx in range(tid, N * N, bdim):
                col = idx // N
                row = idx % N
                val = solver.value_type(LAMBDA) if row == col else solver.value_type(0)
                smem_a[s * (M + N) * N + col * (M + N) + (M + row)] = val
            for idx in range(tid, M, bdim):
                smem_bx[s * (M + N) + idx] = b_top[base + s, idx]
            for idx in range(tid, N, bdim):
                smem_bx[s * (M + N) + (M + idx)] = solver.value_type(0)
        cuda.syncthreads()

        solver.solve(smem_a, smem_tau, smem_bx)
        cuda.syncthreads()

        # First N entries of bs hold x; copy out
        for s in range(bpb):
            for idx in range(tid, N, bdim):
                x_out[base + s, idx] = smem_bx[s * (M + N) + idx]

    a = prepare_random_matrix(
        (batch_count, M, N),
        dtype=solver.precision,
        is_complex=False,
    )
    b = prepare_random_matrix(
        (batch_count, M, 1),
        dtype=solver.precision,
        is_complex=False,
    )[:, :, 0]

    a_d = cuda.to_device(a)
    b_d = cuda.to_device(b)
    x_d = cuda.device_array((batch_count, N), dtype=solver.value_type)

    kernel[BLOCKS, solver.block_dim](a_d, b_d, x_d)
    cuda.synchronize()

    x_result = x_d.copy_to_host()

    # Closed-form reference: x* = (A^T A + lambda^2 I)^-1 A^T b
    eye_n = np.eye(N, dtype=solver.precision)
    error_sum = 0.0
    for sample_idx in range(batch_count):
        a_b = a[sample_idx]
        ata = a_b.T @ a_b + (LAMBDA * LAMBDA) * eye_n
        x_ref = np.linalg.solve(ata, a_b.T @ b[sample_idx])
        error_sum += verify_relative_error(x_result[sample_idx], x_ref, _PREC_TABLE[solver.precision], _ABS_ERR, solver)

    print(f"Successfully validated against numpy normal-equations reference, with accumulated error: {error_sum}")


if __name__ == "__main__":
    main()
