# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/05_fft_Xd/fft_3d_box_single_block.cu
#

import functools

import numpy as np
from numba import cuda

from nvmath.device import FFT, Dim3


def main():
    fft_size_x = 16
    fft_size_y = 15
    fft_size_z = 14

    FFT_base = functools.partial(FFT, fft_type="c2c", direction="forward", precision=np.float32, execution="Thread")
    fft_x = FFT_base(size=fft_size_x)
    fft_y = FFT_base(size=fft_size_y)
    fft_z = FFT_base(size=fft_size_z)

    value_type = fft_x.value_type
    max_dim = max(fft_size_x, fft_size_y, fft_size_z)
    block_dim = Dim3(max_dim, max_dim, 1)
    shared_memory_size = (fft_size_x * fft_size_y * fft_size_z) * np.complex64(1.0).itemsize
    storage_size = max(fft_x.storage_size, fft_y.storage_size, fft_z.storage_size)
    grid_dim = Dim3(1, 1, 1)

    eptx = fft_x.elements_per_thread
    epty = fft_y.elements_per_thread  # codespell:ignore epty
    eptz = fft_z.elements_per_thread

    stride_x = fft_size_y * fft_size_z
    stride_y = fft_size_z
    stride_z = 1

    @cuda.jit
    def f(input, output):
        thread_data = cuda.local.array(shape=(storage_size,), dtype=value_type)
        shared_mem = cuda.shared.array(shape=(0,), dtype=value_type)

        tidx = cuda.threadIdx.x
        tidy = cuda.threadIdx.y

        # given thread --> X
        # threadIdx.y  --> Y
        # threadIdx.x  --> Z
        if tidy < fft_size_y and tidx < fft_size_z:
            for i in range(eptx):
                # fast_copy(input, i * stride_x + tidy * stride_y + tidx * stride_z, thread_data, i)  # noqa: W505
                thread_data[i] = input[i, tidy, tidx]

            fft_x.execute(thread_data)

            index = tidy * stride_y + tidx * stride_z
            for i in range(eptx):
                shared_mem[index] = thread_data[i]
                index += stride_x

        cuda.syncthreads()

        # threadIdx.y  --> X
        # given thread --> Y
        # threadIdx.x  --> Z
        if tidy < fft_size_x and tidx < fft_size_z:
            index = tidy * stride_x + tidx * stride_z
            for i in range(epty):  # codespell:ignore epty
                thread_data[i] = shared_mem[index]
                index += stride_y

            fft_y.execute(thread_data)

            index = tidy * stride_x + tidx
            for i in range(epty):  # codespell:ignore epty
                shared_mem[index] = thread_data[i]
                index += stride_y

        cuda.syncthreads()

        # threadIdx.y  --> X
        # threadIdx.x  --> Y
        # given thread --> Z
        if tidy < fft_size_x and tidx < fft_size_y:
            index = tidy * stride_x + tidx * stride_y
            # for i in range(0, eptz, 2): # eptz is even
            #     fast_copy_2x(shared_mem, index, thread_data, i)
            #     index += 2
            for i in range(eptz):
                thread_data[i] = shared_mem[index]
                index += stride_z

            fft_z.execute(thread_data)

            # Reshuffle in shared
            index = tidy * stride_x + tidx * stride_y
            # for i in range(0, eptz, 2): # eptz is even
            #     fast_copy_2x(thread_data, i, shared_mem, index)
            #     index += 2
            for i in range(eptz):
                shared_mem[index] = thread_data[i]
                index += stride_z

        cuda.syncthreads()

        # given thread --> X
        # threadIdx.y  --> Y
        # threadIdx.x  --> Z
        if tidy < fft_size_y and tidx < fft_size_z:
            index = tidy * stride_y + tidx * stride_z
            for i in range(eptx):
                thread_data[i] = shared_mem[index]
                index += stride_x

            for i in range(eptx):
                # fast_copy(thread_data, i, output, i * stride_x + tidy * stride_y + tidx * stride_z)  # noqa: W505
                output[i, tidy, tidx] = thread_data[i]

    input = (
        np.random.uniform(-1, 1, size=(fft_size_x, fft_size_y, fft_size_z))
        + 1j * np.random.uniform(-1, 1, size=(fft_size_x, fft_size_y, fft_size_z))
    ).astype(np.complex64)
    output = np.zeros((fft_size_x, fft_size_y, fft_size_z), dtype=np.complex64)
    input_d = cuda.to_device(input)
    output_d = cuda.to_device(output)

    f[grid_dim, block_dim, 0, shared_memory_size](input_d, output_d)
    cuda.synchronize()

    output_test = output_d.copy_to_host()

    output_ref = np.fft.fftn(input)
    error = np.linalg.norm(output_ref - output_test) / np.linalg.norm(output_ref)

    print(f"FFT: ({fft_size_x}, {fft_size_y}, {fft_size_z})")
    print("Correctness results:")
    print(f"L2 error: {error}")

    assert error < 1e-4

    print("Success")


if __name__ == "__main__":
    main()
