# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuSolverDx/09_Performance/geqrf_batched_performance.cu
#

import sys
import warnings
from pathlib import Path

import numpy as np
from numba import cuda

from nvmath.device import QRFactorize

sys.path.append(str(Path(__file__).resolve().parents[4]))
sys.path.append(str(Path(__file__).resolve().parents[3]))

from common import prepare_random_matrix  # type: ignore[misc, import-not-found]
from common_numba import (  # type: ignore[misc, import-not-found]
    load_to_shared_strided,
    store_from_shared_strided,
    time_numba_prep_args,
)

warnings.filterwarnings("ignore", module="numba")

np.random.seed(43)

BATCHES = 10000
WARMUP_REPEATS = 1
KERNEL_REPEATS = 5


def get_flops_geqrf(m: int, n: int, is_complex: bool) -> float:
    if m >= n:
        flops = 2.0 * n * n * (m - n / 3.0)
    else:
        flops = 2.0 * m * m * (n - m / 3.0)
    return 4.0 * flops if is_complex else flops


def main():
    factorizer = QRFactorize(
        size=(128, 32),
        precision=np.float32,
        data_type="real",
        arrangement="col_major",
        execution="Block",
        batches_per_block="suggested",
        # "suggested" block_dim (512) overflows the registers for mlir
        # pin a smaller block instead.
        block_dim=(128, 1, 1),
    )

    bpb = factorizer.batches_per_block
    grid_dim = (BATCHES + bpb - 1) // bpb
    padded_batches = grid_dim * bpb

    n_a = factorizer.a_size()
    n_tau = factorizer.tau_size

    print(f"factorizer.batches_per_block={bpb}")
    print(f"factorizer.block_dim={factorizer.block_dim}")
    print(f"grid_dim={grid_dim}, padded_batches={padded_batches}")

    @cuda.jit
    def kernel(a, a_out, tau):
        smem_a = cuda.shared.array(n_a, dtype=factorizer.value_type)
        smem_tau = cuda.shared.array(n_tau, dtype=factorizer.value_type)

        base_sample_idx = cuda.blockIdx.x * bpb

        load_to_shared_strided(a[base_sample_idx:], smem_a, factorizer.a_shape, factorizer.a_strides())
        cuda.syncthreads()

        factorizer.factorize(smem_a, smem_tau)
        cuda.syncthreads()

        store_from_shared_strided(smem_a, a_out[base_sample_idx:], factorizer.a_shape, factorizer.a_strides())
        store_from_shared_strided(smem_tau, tau[base_sample_idx:], factorizer.tau_shape, factorizer.tau_strides)

    a_host = prepare_random_matrix(
        (padded_batches, factorizer.m, factorizer.n),
        dtype=factorizer.precision,
        is_complex=False,
    )

    def prep_args():
        a_d = cuda.to_device(a_host)
        a_out_d = cuda.device_array_like(a_d)
        tau_d = cuda.device_array((padded_batches, factorizer.tau_shape[1]), dtype=factorizer.value_type)
        return [a_d, a_out_d, tau_d]

    ms = time_numba_prep_args(kernel, grid_dim, factorizer.block_dim, 0, KERNEL_REPEATS, prep_args)

    is_complex = factorizer.value_type != factorizer.precision
    seconds_per_giga_batch = ms / 1e3 / BATCHES * 1e9
    bytes_per_elem = np.dtype(factorizer.value_type).itemsize
    input_size = factorizer.m * factorizer.n
    gb_s = input_size * bytes_per_elem * 2 / seconds_per_giga_batch
    gflops = get_flops_geqrf(factorizer.m, factorizer.n, is_complex) / seconds_per_giga_batch

    print(
        f"{'cuSolverDx-GEQRF':<30} {BATCHES:>10} {factorizer.m:>5} {factorizer.n:>5}  "
        f"{gflops:>7.2f} GFLOP/s, {gb_s:>7.2f} GB/s, {ms:>7.2f} ms, {factorizer.block_dim[0]} blockDim"
    )


if __name__ == "__main__":
    main()
