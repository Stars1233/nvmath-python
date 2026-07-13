# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/04_Symmetric_Eigenvalues/htev_batched_block.cu
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

from common import random as random_arr  # type: ignore[misc, import-not-found]
from common import verify_relative_error  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_strided, store_from_shared_strided  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-3,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-6

BLOCKS = 512


def main():
    solver = Solver(
        function="htev",
        size=(64, 64, 1),
        precision=np.float32,
        data_type="real",
        job="no_vectors",
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    m = solver.m
    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_d = m * bpb
    n_e = (m - 1) * bpb
    d_shape_t = (bpb, m)
    e_shape_t = (bpb, m - 1)
    d_strides = (m, 1)
    e_strides = (m - 1, 1)

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(d, e, info):
        smem_d = cuda.shared.array(n_d, dtype=solver.value_type)
        smem_e = cuda.shared.array(n_e, dtype=solver.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(d[base_sample_idx:], smem_d, d_shape_t, d_strides)
        load_to_shared_strided(e[base_sample_idx:], smem_e, e_shape_t, e_strides)
        cuda.syncthreads()

        solver.execute(smem_d, smem_e, info[base_sample_idx:])
        cuda.syncthreads()

        store_from_shared_strided(smem_d, d[base_sample_idx:], d_shape_t, d_strides)

    d_input = (random_arr((batch_count, m), solver.precision) + 1.0) * 2.0 + 2.0
    e_input = random_arr((batch_count, m - 1), solver.precision) * 12.5 + 7.5

    d_d = cuda.to_device(d_input.copy())
    e_d = cuda.to_device(e_input.copy())
    info_d = cuda.device_array(batch_count, dtype=solver.info_type)

    kernel[BLOCKS, solver.block_dim](d_d, e_d, info_d)
    cuda.synchronize()

    eigvals_result = d_d.copy_to_host()
    info_result = info_d.copy_to_host()

    for sample_idx in range(batch_count):
        if info_result[sample_idx] != 0:
            raise RuntimeError(f"{info_result[sample_idx]}-th parameter is wrong for sample idx={sample_idx}")

    error_sum = 0.0
    for sample_idx in range(batch_count):
        eigvals_ref = np.sort(scipy.linalg.eigvalsh_tridiagonal(d_input[sample_idx], e_input[sample_idx]))
        eigvals_dx = np.sort(eigvals_result[sample_idx])
        error_sum += verify_relative_error(eigvals_dx, eigvals_ref, _PREC_TABLE[solver.precision], _ABS_ERR, solver)

    print(f"Successfully validated eigenvalues against scipy reference, with accumulated error: {error_sum}")


if __name__ == "__main__":
    main()
