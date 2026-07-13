# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/03_block_fft_performance/block_fft_performance.cu
#


import sys
from pathlib import Path

import numpy as np
from cuda.bindings import runtime as cudart
from numba_cuda_mlir import cuda

from nvmath.device import FFT

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[3]))
sys.path.append(str(Path(__file__).resolve().parents[2]))

from common import CHECK_CUDART, fft_perf_GFlops  # type: ignore[misc, import-not-found]
from common_numba import get_active_blocks_per_multiprocessor, time_simt  # type: ignore[misc, import-not-found]


def main():
    ncycles = 1
    repeat = 4000
    fft_size = 512
    ffts_per_block = 1
    err, out = cudart.cudaGetDeviceProperties(0)
    CHECK_CUDART(err)
    sms = out.multiProcessorCount
    elements_per_thread = 8

    fft = FFT(
        fft_type="c2c",
        size=fft_size,
        precision=np.float32,
        direction="forward",
        execution="Block",
        elements_per_thread=elements_per_thread,
        ffts_per_block=ffts_per_block,
    )

    @cuda.jit
    def f(data, repeat):
        thread_data = cuda.local.array(shape=(fft.storage_size,), dtype=fft.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * ffts_per_block + local_fft_id

        index = cuda.threadIdx.x
        for i in range(elements_per_thread):
            thread_data[i] = data[fft_id, index]
            index += fft.stride

        for _r in range(repeat):
            fft.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(elements_per_thread):
            data[fft_id, index] = thread_data[i]
            index += fft.stride

    dummy = cuda.to_device(np.ones((ffts_per_block, fft_size), dtype=np.complex64))
    blocks_per_sm = get_active_blocks_per_multiprocessor(f, fft.block_dim, fft.shared_memory_size, dummy, repeat)
    batch_size = sms * blocks_per_sm * ffts_per_block

    grid_dim = batch_size // ffts_per_block
    assert batch_size % ffts_per_block == 0

    data = np.random.uniform(-10, 10, (batch_size, fft_size)) + 1j * np.random.uniform(-10, 10, (batch_size, fft_size))
    data = data.astype(np.complex64)
    data_d = cuda.to_device(data)

    time_ms = time_simt(f, grid_dim, fft.block_dim, fft.shared_memory_size, ncycles, data_d, repeat)
    time_2x_ms = time_simt(f, grid_dim, fft.block_dim, fft.shared_memory_size, ncycles, data_d, 2 * repeat)
    time_fft_ms = (time_2x_ms - time_ms) / repeat
    perf = fft_perf_GFlops(fft_size, batch_size, time_fft_ms)

    print(
        f"FFT type: {fft.fft_type}\n"
        f"FFT size: {fft_size}\n"
        f"FFTs elements per thread: {elements_per_thread}\n"
        f"FFTs per block: {ffts_per_block}\n"
        f"CUDA blocks: {grid_dim}\n"
        f"Blocks per multiprocessor: {blocks_per_sm}\n"
        f"FFTs run: {batch_size}\n"
        f"Shared memory: {fft.shared_memory_size}\n"
        f"Avg Time [ms_n]: {time_fft_ms}\n"
        f"Time (all) [ms_n]: {time_fft_ms * repeat}\n"
        f"Performance [GFLOPS]: {perf}"
    )


if __name__ == "__main__":
    main()
