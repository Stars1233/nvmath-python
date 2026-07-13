# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/06_convolution/convolution_performance.cu
#

import functools
import sys
from pathlib import Path

import cupy
import cupy.fft
import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import FFT

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[3]))
sys.path.append(str(Path(__file__).resolve().parents[2]))

from common_cupy import time_cupy  # type: ignore[misc, import-not-found]
from common_numba import time_simt  # type: ignore[misc, import-not-found]


def main():
    fft_size = 512
    batch_size = (2**30) // fft_size // np.complex64(1.0).itemsize
    ncycles = 10

    FFT_base = functools.partial(
        FFT,
        fft_type="c2c",
        size=fft_size,
        precision=np.float32,
        ffts_per_block="suggested",
        execution="Block",
    )
    fft = FFT_base(direction="forward")
    ifft = FFT_base(direction="inverse")

    grid_dim = (batch_size + fft.ffts_per_block - 1) // fft.ffts_per_block

    @cuda.jit
    def f(input, output):
        thread_data = cuda.local.array(shape=(fft.storage_size,), dtype=fft.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fft.ffts_per_block + local_fft_id

        if fft_id >= batch_size:
            return

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < fft_size:
                thread_data[i] = input[fft_id, index]
                index += fft.stride

        fft.execute(thread_data, shared_mem)

        for i in range(fft.elements_per_thread):
            thread_data[i] = np.complex64(thread_data[i]) / fft.size

        ifft.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < fft_size:
                output[fft_id, index] = thread_data[i]
                index += fft.stride

    input = (
        np.random.uniform(-10, 10, (batch_size, fft_size)) + 1j * np.random.uniform(-10, 10, (batch_size, fft_size))
    ).astype(np.complex64)
    output = np.ones((batch_size, fft_size), dtype=np.complex64)
    input_d = cupy.array(input)
    output_d = cupy.array(output)

    cupy_ms = time_cupy(lambda input: cupy.fft.ifft(cupy.fft.fft(input, axis=-1), axis=-1), ncycles, input_d)

    simt_ms = time_simt(f, grid_dim, fft.block_dim, fft.shared_memory_size, ncycles, input_d, output_d)

    output_test = cupy.asnumpy(output_d)
    output_ref = np.fft.ifft(np.fft.fft(input, axis=-1), axis=-1)

    error = np.linalg.norm(output_test - output_ref) / np.linalg.norm(output_ref)
    assert error < 1e-5

    print(f"Time per convolution:\ncupy {cupy_ms} ms\ncuSIMT {simt_ms} ms")

    print("Success")


if __name__ == "__main__":
    main()
