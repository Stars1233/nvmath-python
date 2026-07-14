# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/00_Introduction/posv_batched_block.cu
#

import sys
import warnings
from pathlib import Path

import numpy as np
import scipy.linalg
from numba import cuda

from nvmath.device import CholeskySolver

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import prepare_random_matrix, verify_relative_error  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_strided, store_from_shared_strided  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-4,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-8

BLOCKS = 256


def main():
    solver = CholeskySolver(
        size=(32, 32, 1),
        precision=np.float64,
        data_type="complex",
        fill_mode="lower",
        arrangement=("col_major", "col_major"),
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_a = solver.a_size()
    n_b = solver.b_size()

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(a, b, info):
        smem_a = cuda.shared.array(n_a, dtype=solver.value_type)
        smem_b = cuda.shared.array(n_b, dtype=solver.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(a[base_sample_idx:], smem_a, solver.a_shape, solver.a_strides())
        load_to_shared_strided(b[base_sample_idx:], smem_b, solver.b_shape, solver.b_strides())
        cuda.syncthreads()

        solver.factorize(smem_a, info[base_sample_idx:])
        cuda.syncthreads()

        solver.solve(smem_a, smem_b)
        cuda.syncthreads()

        store_from_shared_strided(smem_a, a[base_sample_idx:], solver.a_shape, solver.a_strides())
        store_from_shared_strided(smem_b, b[base_sample_idx:], solver.b_shape, solver.b_strides())

    a = prepare_random_matrix(
        (batch_count, *solver.a_shape[1:]),
        dtype=solver.precision,
        is_complex=True,
        is_positive_definite=True,
    )
    b = prepare_random_matrix(
        (batch_count, *solver.b_shape[1:]),
        dtype=solver.precision,
        is_complex=True,
    )

    a_d = cuda.to_device(a)
    b_d = cuda.to_device(b)
    info_d = cuda.device_array(batch_count, dtype=solver.info_type)

    kernel[BLOCKS, solver.block_dim](a_d, b_d, info_d)
    cuda.synchronize()

    b_result = b_d.copy_to_host()
    info_result = info_d.copy_to_host()

    for sample_idx in range(batch_count):
        if info_result[sample_idx] != 0:
            raise RuntimeError(f"{info_result[sample_idx]}-th parameter is wrong for sample idx={sample_idx}")

    error_sum = 0.0
    for sample_idx in range(batch_count):
        x_scipy = scipy.linalg.solve(a[sample_idx], b[sample_idx], assume_a="pos")
        error_sum += verify_relative_error(b_result[sample_idx], x_scipy, _PREC_TABLE[solver.precision], _ABS_ERR, solver)

    print(f"Successfully validated against scipy reference, with accumulated error: {error_sum}")


if __name__ == "__main__":
    main()
