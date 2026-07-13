# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/01_simple_fft_thread/simple_fft_thread_fp16.cu
#


import sys
from pathlib import Path

import numpy as np
from numba import cuda

from nvmath.device import FFT, float16x4

# Add parent directory to sys.path to access common libraries
sys.path.append(str(Path(__file__).resolve().parents[3]))
sys.path.append(str(Path(__file__).resolve().parents[2]))

from common import complex64_to_fp16x2, fp16x2_to_complex64  # type: ignore[misc, import-not-found]


def main():
    threads_count = 3

    fft = FFT(fft_type="c2c", size=8, precision=np.float16, direction="forward", execution="Thread")

    assert fft.implicit_type_batching == 2

    @cuda.jit
    def f(data):
        thread_data = cuda.local.array(shape=(fft.storage_size,), dtype=fft.value_type)

        local_fft_id = cuda.threadIdx.x

        for i in range(fft.elements_per_thread):
            r0 = data[2 * local_fft_id, 2 * i + 0]
            i0 = data[2 * local_fft_id, 2 * i + 1]
            r1 = data[2 * local_fft_id + 1, 2 * i + 0]
            i1 = data[2 * local_fft_id + 1, 2 * i + 1]
            thread_data[i] = float16x4(r0, r1, i0, i1)

        fft.execute(thread_data)

        for i in range(fft.elements_per_thread):
            rrii = thread_data[i]
            r0, r1, i0, i1 = rrii.x, rrii.y, rrii.z, rrii.w
            data[2 * local_fft_id, 2 * i + 0] = r0
            data[2 * local_fft_id, 2 * i + 1] = i0
            data[2 * local_fft_id + 1, 2 * i + 0] = r1
            data[2 * local_fft_id + 1, 2 * i + 1] = i1

    # Numpy has no FP16 complex, so we create a 2xlarger arrays of FP16 reals
    # Each consecutive pair of reals form one logical FP16 complex number
    data = np.zeros((fft.implicit_type_batching * threads_count, fft.size), dtype=np.complex64)
    for i in range(fft.implicit_type_batching * threads_count):
        for j in range(fft.size):
            val = i * fft.size + j
            data[i, j] = val - 1j * val
    data_fp16 = complex64_to_fp16x2(data)
    data_d = cuda.to_device(data_fp16)

    print("input [1st FFT]:")
    for i in range(fft.size):
        print(f"{data[0, i].real} {data[0, i].imag}")

    f[1, threads_count](data_d)
    cuda.synchronize()

    data_test = fp16x2_to_complex64(data_d.copy_to_host())

    print("output [1st FFT]:")
    for i in range(fft.size):
        print(f"{data_test[0, i].real} {data_test[0, i].imag}")

    data_ref = np.fft.fft(data, axis=-1)
    error = np.linalg.norm(data_test - data_ref) / np.linalg.norm(data_ref)
    assert error < 1e-3
    print("Success")


if __name__ == "__main__":
    main()
