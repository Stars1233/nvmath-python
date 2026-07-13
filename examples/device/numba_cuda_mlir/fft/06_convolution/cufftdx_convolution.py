# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/06_convolution/convolution.cu
#

import functools

import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import FFT


def main():
    FFT_base = functools.partial(
        FFT,
        fft_type="c2c",
        size=128,
        precision=np.float32,
        ffts_per_block=2,
        elements_per_thread=8,
        execution="Block",
    )
    fft = FFT_base(direction="forward")
    ifft = FFT_base(direction="inverse")

    @cuda.jit
    def f(data):
        thread_data = cuda.local.array(shape=(fft.storage_size,), dtype=fft.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fft.ffts_per_block + local_fft_id

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            thread_data[i] = data[fft_id, index]
            index += fft.stride

        shared_mem = cuda.shared.array(shape=(0,), dtype=fft.value_type, alignment=32)
        fft.execute(thread_data, shared_mem)

        for i in range(fft.elements_per_thread):
            thread_data[i] = np.complex64(thread_data[i]) / fft.size

        ifft.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            data[fft_id, index] = thread_data[i]
            index += fft.stride

    data = np.empty((fft.ffts_per_block, fft.size), dtype=np.complex64)
    for i in range(fft.ffts_per_block * fft.size):
        data.flat[i] = i - 1j * i
    data_d = cuda.to_device(data)

    print("input [1st FFT]:")
    for i in range(fft.size):
        print(f"{data[0, i].real} {data[0, i].imag}")

    f[1, fft.block_dim, 0, fft.shared_memory_size](data_d)
    cuda.synchronize()

    data_test = data_d.copy_to_host()

    print("output [1st FFT]:")
    for i in range(fft.size):
        print(f"{data_test[0, i].real} {data_test[0, i].imag}")

    error = np.linalg.norm(data_test - data) / np.linalg.norm(data)
    assert error < 1e-5

    print("Success")


if __name__ == "__main__":
    main()
