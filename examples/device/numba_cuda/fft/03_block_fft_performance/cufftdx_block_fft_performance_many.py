# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/03_block_fft_performance/block_fft_performance_many.cu
#

"""
Note:
    This example has been modified from the original C++ implementation to avoid using
    array sizes (e.g., 137, 251) that require a workspace. Currently, nvmath-python
    does not support cuFFTDx configurations that require a workspace.
    For more information on supported sizes, please see the cuFFTDx documentation:
    https://docs.nvidia.com/cuda/cufftdx/requirements_func.html#supported-functionality
"""

import sys
from pathlib import Path

import numpy as np
from cuda.bindings import runtime as cudart
from numba import cuda

from nvmath.device import FFT

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[3]))
sys.path.append(str(Path(__file__).resolve().parents[2]))

from common import CHECK_CUDART, fft_perf_GFlops  # type: ignore[misc, import-not-found]
from common_numba import get_active_blocks_per_multiprocessor, time_numba  # type: ignore[misc, import-not-found]


def run(fft_type, fft_size, direction=None):
    ncycles = 1
    repeat = 4000
    err, out = cudart.cudaGetDeviceProperties(0)
    sms = out.multiProcessorCount
    CHECK_CUDART(err)

    fft = FFT(
        fft_type=fft_type,
        size=fft_size,
        precision=np.float32,
        direction=direction,
        execution="Block",
        ffts_per_block="suggested",
    )

    complex_size = fft_size if fft_type == "c2c" else fft_size // 2 + 1

    @cuda.jit
    def f(data, repeat):
        thread_data = cuda.local.array(shape=(fft.storage_size,), dtype=fft.value_type)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft.value_type)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fft.ffts_per_block + local_fft_id

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < complex_size:
                thread_data[i] = data[fft_id, index]
                index += fft.stride

        for _r in range(repeat):
            fft.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < complex_size:
                data[fft_id, index] = thread_data[i]
                index += fft.stride

    dummy = cuda.to_device(np.ones((fft.ffts_per_block, complex_size), dtype=np.complex64))
    blocks_per_sm = get_active_blocks_per_multiprocessor(f, fft.block_dim, fft.shared_memory_size, dummy, repeat)
    batch_size = sms * blocks_per_sm * fft.ffts_per_block
    grid_dim = batch_size // fft.ffts_per_block
    assert batch_size % fft.ffts_per_block == 0

    data = np.random.uniform(-10, 10, (batch_size, complex_size)) + 1j * np.random.uniform(-10, 10, (batch_size, complex_size))
    data = data.astype(np.complex64)
    data_d = cuda.to_device(data)

    time_ms = time_numba(f, grid_dim, fft.block_dim, fft.shared_memory_size, ncycles, data_d, repeat)
    time_2x_ms = time_numba(f, grid_dim, fft.block_dim, fft.shared_memory_size, ncycles, data_d, 2 * repeat)
    time_fft_ms = (time_2x_ms - time_ms) / repeat
    perf = fft_perf_GFlops(fft_size, batch_size, time_fft_ms, coef=1.0 if fft_type == "c2c" else 0.5)

    print(f"{fft_type}, {fft_size}, {perf}, {time_fft_ms}, ")


def main():
    run("c2c", 512, direction="forward")
    run("c2c", 1024, direction="forward")
    run("c2c", 2048, direction="forward")
    run("c2c", 4096, direction="forward")
    run("c2c", 512, direction="inverse")
    run("c2c", 1024, direction="inverse")
    run("c2c", 2048, direction="inverse")
    run("c2c", 4096, direction="inverse")
    run("r2c", 512)
    run("r2c", 1024)
    run("r2c", 2048)
    run("r2c", 4096)
    run("c2r", 512)
    run("c2r", 1024)
    run("c2r", 2048)
    run("c2r", 4096)


if __name__ == "__main__":
    main()
