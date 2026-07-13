# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

#
# Mirrors https://github.com/NVIDIA/CUDALibrarySamples/blob/main/MathDx/cuFFTDx/05_fft_Xd/fft_3d.cu
#

import functools

import numpy as np
from numba_cuda_mlir import cuda

from nvmath.device import FFT, Dim3


def main():
    fft_size_z = 32
    fft_size_y = 1024
    fft_size_x = 1024

    ept_z = 16
    fpb_z = 4
    ept_y = 32
    fpb_y = 2
    ept_x = 32
    fpb_x = 2

    FFT_base = functools.partial(FFT, fft_type="c2c", direction="forward", precision=np.float32, execution="Block")
    fft_z = FFT_base(size=fft_size_z, elements_per_thread=ept_z, ffts_per_block=fpb_z)
    fft_y = FFT_base(size=fft_size_y, elements_per_thread=ept_y, ffts_per_block=fpb_y)
    fft_x = FFT_base(size=fft_size_x, elements_per_thread=ept_x, ffts_per_block=fpb_x)

    grid_dim_z = Dim3((fft_size_x * fft_size_y) // fpb_z, 1, 1)
    grid_dim_y = Dim3((fft_size_x * fft_size_z) // fpb_y, 1, 1)
    grid_dim_x = Dim3((fft_size_y * fft_size_z) // fpb_x, 1, 1)

    @cuda.jit
    def f_z(input, output):
        thread_data = cuda.local.array(shape=(fft_z.storage_size,), dtype=fft_z.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft_z.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fpb_z + local_fft_id

        # fft_id is the linear index of the 1D FFT in the X-Y plane
        id_x = fft_id // fft_size_y
        id_y = fft_id % fft_size_y

        index = cuda.threadIdx.x
        for i in range(ept_z):
            thread_data[i] = input[id_x, id_y, index]
            index += fft_z.stride

        fft_z.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(ept_z):
            output[id_x, id_y, index] = thread_data[i]
            index += fft_z.stride

    @cuda.jit
    def f_y(input, output):
        thread_data = cuda.local.array(shape=(fft_y.storage_size,), dtype=fft_y.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft_y.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fpb_y + local_fft_id

        # fft_id is the linear index of the 1D FFT in the X-Z plane
        id_x = fft_id // fft_size_z
        id_z = fft_id % fft_size_z

        index = cuda.threadIdx.x
        for i in range(ept_y):
            thread_data[i] = input[id_x, index, id_z]
            index += fft_y.stride

        fft_y.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(ept_y):
            output[id_x, index, id_z] = thread_data[i]
            index += fft_y.stride

    @cuda.jit
    def f_x(input, output):
        thread_data = cuda.local.array(shape=(fft_x.storage_size,), dtype=fft_x.value_type, alignment=32)
        shared_mem = cuda.shared.array(shape=(0,), dtype=fft_x.value_type, alignment=32)

        local_fft_id = cuda.threadIdx.y
        fft_id = cuda.blockIdx.x * fpb_x + local_fft_id

        # fft_id is the linear index of the 1D FFT in the Y-Z plane
        id_y = fft_id // fft_size_z
        id_z = fft_id % fft_size_z

        index = cuda.threadIdx.x
        for i in range(ept_x):
            thread_data[i] = input[index, id_y, id_z]
            index += fft_x.stride

        fft_x.execute(thread_data, shared_mem)

        index = cuda.threadIdx.x
        for i in range(ept_x):
            output[index, id_y, id_z] = thread_data[i]
            index += fft_x.stride

    input = (
        np.random.uniform(-1, 1, size=(fft_size_x, fft_size_y, fft_size_z))
        + 1j * np.random.uniform(-1, 1, size=(fft_size_x, fft_size_y, fft_size_z))
    ).astype(np.complex64)
    output = np.zeros((fft_size_x, fft_size_y, fft_size_z), dtype=np.complex64)
    input_d = cuda.to_device(input)
    output_d = cuda.to_device(output)

    f_z[grid_dim_z, fft_z.block_dim, 0, fft_z.shared_memory_size](input_d, output_d)
    f_y[grid_dim_y, fft_y.block_dim, 0, fft_y.shared_memory_size](output_d, output_d)
    f_x[grid_dim_x, fft_x.block_dim, 0, fft_x.shared_memory_size](output_d, output_d)
    cuda.synchronize()

    output_test = output_d.copy_to_host()

    output_ref = np.fft.fftn(input)
    error = np.linalg.norm(output_test - output_ref) / np.linalg.norm(output_ref)

    print(f"FFT: ({fft_size_x}, {fft_size_y}, {fft_size_z})")
    print("Correctness results:")
    print(f"L2 error: {error}")

    assert error < 1e-4

    print("Success")


if __name__ == "__main__":
    main()
