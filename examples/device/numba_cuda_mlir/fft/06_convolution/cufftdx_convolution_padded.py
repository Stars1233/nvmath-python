# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Note:
    This example has been modified from the original C++ implementation to avoid using
    array sizes (e.g., 3668) that require a workspace. Currently, nvmath-python
    does not support cuFFTDx configurations that require a workspace.
    For more information on supported sizes, please see the cuFFTDx documentation:
    https://docs.nvidia.com/cuda/cufftdx/requirements_func.html#supported-functionality
"""

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/06_convolution/convolution_padded.cu
#

import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import FFT


def main():
    ffts_per_block = 2
    signal_length = 100
    fft_size = 128

    kwargs = {
        "size": fft_size,
        "precision": np.float32,
        "elements_per_thread": 2,
        "ffts_per_block": ffts_per_block,
        "execution": "Block",
    }
    fft = FFT(**kwargs, fft_type="r2c")
    ifft = FFT(**kwargs, fft_type="c2r")

    storage_size = max(fft.storage_size, ifft.storage_size)
    shared_memory_size = max(fft.shared_memory_size, ifft.shared_memory_size)
    assert ifft.stride == fft.stride
    assert ifft.block_dim == fft.block_dim
    assert ifft.elements_per_thread == fft.elements_per_thread

    @cuda.jit
    def f(data):
        thread_data = cuda.local.array(shape=(storage_size,), dtype=fft.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft.value_type, alignment=32)
        thread_data_real = thread_data.view(np.float32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * ffts_per_block + local_fft_id

        # Data being loaded is real, for we load fft_size real elements per batch
        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < signal_length:
                thread_data_real[i] = data[fft_id, index]
            elif index < fft_size:
                thread_data_real[i] = 0.0
            index += fft.stride

        fft.execute(thread_data, shared_mem)

        # After the first transform, the data is complex, so we have fft_size//2+1 complex
        # elements per batch
        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < (fft_size // 2 + 1):
                thread_data[i] = np.complex64(thread_data[i]) / fft_size
            index += fft.stride

        ifft.execute(thread_data, shared_mem)

        # After the second transform, the data is real again, so we store fft_size real
        # elements per batch
        index = cuda.threadIdx.x
        for i in range(fft.elements_per_thread):
            if index < signal_length:
                data[fft_id, index] = thread_data_real[i]
            index += fft.stride

    data = np.empty((ffts_per_block, signal_length), dtype=np.float32)
    for i in range(ffts_per_block * signal_length):
        data.flat[i] = float(i)
    data_d = cuda.to_device(data)

    print("input [1st FFT]:")
    for i in range(signal_length):
        print(f"{data[0, i]}")

    f[1, fft.block_dim, 0, shared_memory_size](data_d)
    cuda.synchronize()

    data_test = data_d.copy_to_host()

    print("output [1st FFT]:")
    for i in range(signal_length):
        print(f"{data_test[0, i]}")

    error = np.linalg.norm(data_test - data) / np.linalg.norm(data)
    assert error < 1e-5

    print("Success")


if __name__ == "__main__":
    main()
