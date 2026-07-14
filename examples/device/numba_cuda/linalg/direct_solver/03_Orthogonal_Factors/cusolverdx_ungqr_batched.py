# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/03_Orthogonal_Factors/ungqr_batched_block.cu
#

import sys
import warnings
from pathlib import Path

import numpy as np
from numba import cuda

from nvmath.device import Solver

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import prepare_random_matrix, verify_relative_error  # type: ignore[misc, import-not-found]
from common import random as random_arr  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_strided, store_from_shared_strided  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-4,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-8

BLOCKS = 64


def reconstruct_q(a: np.ndarray, tau: np.ndarray, m: int, k: int) -> np.ndarray:
    q = np.identity(m, dtype=a.dtype)
    for i in range(k):
        v = np.zeros((m, 1), dtype=a.dtype)
        v[i, 0] = 1.0
        v[i + 1 :, 0] = a[i + 1 :, i]
        q = q @ (np.identity(m, dtype=a.dtype) - tau[i] * (v @ v.T.conj()))
    return q


def main():
    solver = Solver(
        function="ungqr",
        size=(26, 25, 23),
        precision=np.float32,
        data_type="complex",
        arrangement=("row_major", "row_major"),
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    m, n, k = solver.m, solver.n, solver.k
    lda = solver.lda
    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_a = m * lda * bpb
    n_tau = k * bpb
    a_strides = (m * lda, lda, 1)
    a_shape_t = (bpb, m, n)
    tau_shape_t = (bpb, k)
    tau_strides = (k, 1)

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(a, tau):
        smem_a = cuda.shared.array(n_a, dtype=solver.value_type)
        smem_tau = cuda.shared.array(n_tau, dtype=solver.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(a[base_sample_idx:], smem_a, a_shape_t, a_strides)
        load_to_shared_strided(tau[base_sample_idx:], smem_tau, tau_shape_t, tau_strides)
        cuda.syncthreads()

        solver.execute(smem_a, smem_tau)
        cuda.syncthreads()

        store_from_shared_strided(smem_a, a[base_sample_idx:], a_shape_t, a_strides)

    a = prepare_random_matrix(
        (batch_count, m, n),
        dtype=solver.precision,
        is_complex=True,
    )
    a *= 0.1

    tau_dtype = np.complex64 if solver.precision == np.float32 else np.complex128
    tau = random_arr((batch_count, k), solver.precision).astype(tau_dtype) + 1j * random_arr((batch_count, k), solver.precision)
    tau *= 2.0

    a_d = cuda.to_device(a)
    tau_d = cuda.to_device(tau)

    kernel[BLOCKS, solver.block_dim](a_d, tau_d)
    cuda.synchronize()

    a_result = a_d.copy_to_host()

    error_sum = 0.0
    for sample_idx in range(batch_count):
        q_expected = reconstruct_q(a[sample_idx], tau[sample_idx], m, k)
        error_sum += verify_relative_error(
            a_result[sample_idx], q_expected[:, :n], _PREC_TABLE[solver.precision], _ABS_ERR, solver
        )

    print(f"Successfully validated against numpy reference, with accumulated error: {error_sum}")


if __name__ == "__main__":
    main()
