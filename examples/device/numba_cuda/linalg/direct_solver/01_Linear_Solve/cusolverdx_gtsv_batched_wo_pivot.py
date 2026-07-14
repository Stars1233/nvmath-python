# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/01_Linear_Solve/gtsv_batched_wo_pivot_block.cu
#

import sys
import warnings
from pathlib import Path

import numpy as np
import scipy.linalg
from numba import cuda

from nvmath.device import Solver

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import random as random_arr  # type: ignore[misc, import-not-found]
from common import verify_relative_error  # type: ignore[misc, import-not-found]
from common_numba import load_to_shared_strided, store_from_shared_strided  # type: ignore[misc, import-not-found]

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

_PREC_TABLE = {
    np.float32: 1e-4,
    np.float64: 1e-6,
}
_ABS_ERR = 1e-8

BLOCKS = 512


def main():
    solver = Solver(
        function="gtsv_no_pivot",
        size=(18, 18, 4),
        precision=np.float32,
        data_type="complex",
        arrangement=("col_major", "row_major"),
        leading_dimensions=(5, 19),
        execution="Block",
        batches_per_block="suggested",
        block_dim="suggested",
    )

    m, _, k = solver.m, solver.n, solver.k
    ldb = solver.ldb
    bpb = solver.batches_per_block
    batch_count = BLOCKS * bpb

    n_dl = (m - 1) * bpb
    n_d = m * bpb
    n_du = (m - 1) * bpb
    n_b = m * ldb * bpb
    b_strides = (m * ldb, ldb, 1)
    b_shape_t = (bpb, m, k)

    dl_shape_t = (bpb, m - 1)
    d_shape_t = (bpb, m)
    dl_strides = (m - 1, 1)
    d_strides = (m, 1)

    print(f"solver.batches_per_block={bpb}")
    print(f"solver.block_dim={solver.block_dim}")
    print(f"batch_count={batch_count}")

    @cuda.jit
    def kernel(dl, d, du, b, info):
        smem_dl = cuda.shared.array(n_dl, dtype=solver.value_type)
        smem_d = cuda.shared.array(n_d, dtype=solver.value_type)
        smem_du = cuda.shared.array(n_du, dtype=solver.value_type)
        smem_b = cuda.shared.array(n_b, dtype=solver.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(dl[base_sample_idx:], smem_dl, dl_shape_t, dl_strides)
        load_to_shared_strided(d[base_sample_idx:], smem_d, d_shape_t, d_strides)
        load_to_shared_strided(du[base_sample_idx:], smem_du, dl_shape_t, dl_strides)
        load_to_shared_strided(b[base_sample_idx:], smem_b, b_shape_t, b_strides)
        cuda.syncthreads()

        solver.execute(smem_dl, smem_d, smem_du, smem_b, info[base_sample_idx:])
        cuda.syncthreads()

        store_from_shared_strided(smem_b, b[base_sample_idx:], b_shape_t, b_strides)

    d_host = random_arr((batch_count, m), solver.precision)
    dl_host = random_arr((batch_count, m - 1), solver.precision)
    du_host = random_arr((batch_count, m - 1), solver.precision)
    if solver.data_type == "complex":
        d_host = d_host.astype(np.complex64 if solver.precision == np.float32 else np.complex128)
        d_host = d_host + 1j * random_arr((batch_count, m), solver.precision)
        dl_host = dl_host.astype(d_host.dtype) + 1j * random_arr((batch_count, m - 1), solver.precision)
        du_host = du_host.astype(d_host.dtype) + 1j * random_arr((batch_count, m - 1), solver.precision)

    abs_lower = np.zeros_like(np.abs(d_host))
    abs_upper = np.zeros_like(np.abs(d_host))
    abs_lower[:, 1:] = np.abs(dl_host)
    abs_upper[:, :-1] = np.abs(du_host)
    d_host = (np.sign(d_host.real) + 1j * 0).astype(d_host.dtype) * (abs_lower + abs_upper + 5.0)

    b_host = random_arr((batch_count, m, k), solver.precision)
    if solver.data_type == "complex":
        b_host = b_host.astype(d_host.dtype) + 1j * random_arr((batch_count, m, k), solver.precision)

    dl_d = cuda.to_device(dl_host)
    d_d = cuda.to_device(d_host)
    du_d = cuda.to_device(du_host)
    b_d = cuda.to_device(b_host)
    info_d = cuda.device_array(batch_count, dtype=solver.info_type)

    kernel[BLOCKS, solver.block_dim](dl_d, d_d, du_d, b_d, info_d)
    cuda.synchronize()

    b_result = b_d.copy_to_host()
    info_result = info_d.copy_to_host()

    for sample_idx in range(batch_count):
        if info_result[sample_idx] != 0:
            raise RuntimeError(f"{info_result[sample_idx]}-th parameter is wrong for sample idx={sample_idx}")

    error_sum = 0.0
    for sample_idx in range(batch_count):
        banded = np.zeros((3, m), dtype=d_host.dtype)
        banded[0, 1:] = du_host[sample_idx]
        banded[1, :] = d_host[sample_idx]
        banded[2, :-1] = dl_host[sample_idx]
        x_scipy = scipy.linalg.solve_banded((1, 1), banded, b_host[sample_idx])
        error_sum += verify_relative_error(b_result[sample_idx], x_scipy, _PREC_TABLE[solver.precision], _ABS_ERR, solver)

    print(f"Successfully validated against scipy reference, with accumulated error: {error_sum}")


if __name__ == "__main__":
    main()
