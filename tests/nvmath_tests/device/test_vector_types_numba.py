# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import inspect

import numpy as np
import pytest
from numba import cuda, types

from nvmath.device import (
    complex32,
    complex64,
    complex128,
    float16x2,
    float16x2_type,
    float16x4,
    float16x4_type,
    float32x2,
    float32x2_type,
    float32x4,
    float32x4_type,
    float64x2,
    float64x2_type,
    float64x4,
    float64x4_type,
    half2,
    half4,
    np_float16x2,
    np_float16x4,
    uint32x4,
    uint32x4_type,
)

from .utils.common_axes import Compiler, all_compiler_params, xfail_mlir_fp16


def _native_vec_for(compiler, dtype):
    if compiler == Compiler.numba_cuda:
        from nvmath.device import (
            float16x2 as nc_float16x2,
        )
        from nvmath.device import (
            float16x2_type as nc_float16x2_type,
        )
        from nvmath.device import (
            float16x4 as nc_float16x4,
        )
        from nvmath.device import (
            float16x4_type as nc_float16x4_type,
        )
        from nvmath.device import (
            float32x2 as nc_float32x2,
        )
        from nvmath.device import (
            float32x2_type as nc_float32x2_type,
        )
        from nvmath.device import (
            float64x2 as nc_float64x2,
        )
        from nvmath.device import (
            float64x2_type as nc_float64x2_type,
        )

        return {
            complex32: (nc_float16x2, nc_float16x2_type),
            complex64: (nc_float32x2, nc_float32x2_type),
            complex128: (nc_float64x2, nc_float64x2_type),
            half2: (nc_float16x2, nc_float16x2_type),
            half4: (nc_float16x4, nc_float16x4_type),
        }[dtype]
    if compiler == Compiler.numba_cuda_mlir:
        from numba_cuda_mlir.cuda.vector_types import (
            float16x2 as mlir_float16x2,
        )
        from numba_cuda_mlir.cuda.vector_types import (
            float16x4 as mlir_float16x4,
        )
        from numba_cuda_mlir.cuda.vector_types import (
            float32x2 as mlir_float32x2,
        )
        from numba_cuda_mlir.cuda.vector_types import (
            float64x2 as mlir_float64x2,
        )

        return {
            complex32: (mlir_float16x2, mlir_float16x2),
            complex64: (mlir_float32x2, mlir_float32x2),
            complex128: (mlir_float64x2, mlir_float64x2),
            half2: (mlir_float16x2, mlir_float16x2),
            half4: (mlir_float16x4, mlir_float16x4),
        }[dtype]
    raise ValueError(f"Unknown compiler: {compiler}")


# Tests we can use the types to build arrays and read to/from global arrays
# built with Numba basic complex dtypes
@pytest.mark.parametrize(
    "numpy_type,numba_type,numba_fe_type",
    [
        (np.complex128, float64x2_type, float64x2),
        (np.complex128, float32x2_type, float32x2),
        (np.complex64, float64x2_type, float64x2),
        (np.complex64, float32x2_type, float32x2),
    ],
)
def test_complex_numpy_numba_interop(numpy_type, numba_type, numba_fe_type):
    print(f"Test for {numpy_type} <-> {numba_type}")

    @cuda.jit
    def f(input, output1, output2):
        lmem = cuda.local.array(shape=(4,), dtype=numba_type)
        smem = cuda.shared.array(shape=(4,), dtype=numba_type)

        for i in range(4):
            lmem[i] = input[i]
            smem[i] = lmem[i]
            output1[i] = smem[i]
            output2[i] = numba_fe_type(smem[i].x, smem[i].y)

    input = np.array([3.14 + 2.71j, -3.71 - 2.71j, 3.71 - 9.84j, -45.58 - 987j], dtype=numpy_type)
    output1 = np.zeros_like(input)
    output2 = np.zeros_like(input)

    f[1, 1](input, output1, output2)
    cuda.synchronize()

    assert np.allclose(input, output1)
    assert np.allclose(input, output2)


np_float32x2 = np.dtype([("x", np.float32), ("y", np.float32)], align=True)
np_float32x4 = np.dtype([("x", np.float32), ("y", np.float32), ("z", np.float32), ("w", np.float32)], align=True)
np_float64x2 = np.dtype([("x", np.float64), ("y", np.float64)], align=True)
np_float64x4 = np.dtype([("x", np.float64), ("y", np.float64), ("z", np.float64), ("w", np.float64)], align=True)
np_uint32x4 = np.dtype([("x", np.uint32), ("y", np.uint32), ("z", np.uint32), ("w", np.uint32)], align=True)

FLOAT64X2_INPUT = np.array(
    [(3.14, 2.71), (2.71, 42), (1.0, -100), (-1.0, 1.0)],
    dtype=np_float64x2,
)
FLOAT64X4_INPUT = np.array(
    [
        (3.14, 2.71, -0.1, 0.1),
        (2.71, 42, 3.0, 4.0),
        (1.0, -100, 1000, -10000),
        (-1.0, 1.0, 0, 0),
    ],
    dtype=np_float64x4,
)
UINT32X4_INPUT = np.array(
    [(0, 1, 2, 3), (4, 5, 6, 7), (2**32 - 1, 42, 100, 999), (1234, 5678, 9012, 3456)],
    dtype=np_uint32x4,
)


# Test we can build types from numpy dtypes
@pytest.mark.parametrize(
    "size,input,numba_type,numba_fe_type",
    [
        (2, FLOAT64X2_INPUT.astype(np_float16x2), float16x2_type, float16x2),
        (4, FLOAT64X4_INPUT.astype(np_float16x4), float16x4_type, float16x4),
        (2, FLOAT64X2_INPUT.astype(np_float32x2), float32x2_type, float32x2),
        (4, FLOAT64X4_INPUT.astype(np_float32x4), float32x4_type, float32x4),
        (2, FLOAT64X2_INPUT, float64x2_type, float64x2),
        (4, FLOAT64X4_INPUT, float64x4_type, float64x4),
        (4, UINT32X4_INPUT, uint32x4_type, uint32x4),
    ],
)
def test_dtypes_numpy_numba_interop(size, input, numba_type, numba_fe_type):
    print(f"Test for {input.dtype} <-> {numba_type}")

    @cuda.jit
    def f(input, output):
        for i in range(4):
            v = input[i]
            if size == 2:
                w = numba_fe_type(v.x, v.y)
                output[i].x = w.x
                output[i].y = w.y
            elif size == 4:
                w = numba_fe_type(v.x, v.y, v.z, v.w)
                output[i].x = w.x
                output[i].y = w.y
                output[i].z = w.z
                output[i].w = w.w

    output = np.zeros_like(input)

    f[1, 1](input, output)
    cuda.synchronize()

    assert np.array_equal(input, output)


@pytest.mark.parametrize(
    "numba_type,count,bitwidth,numba_basic_type",
    [
        (float16x2_type, 2, 2 * 16, types.float16),
        (float16x4_type, 4, 4 * 16, types.float16),
        (float32x2_type, 2, 2 * 32, types.float32),
        (float32x4_type, 4, 4 * 32, types.float32),
        (float64x2_type, 2, 2 * 64, types.float64),
        (float64x4_type, 4, 4 * 64, types.float64),
        (uint32x4_type, 4, 4 * 32, types.uint32),
    ],
)
def test_vector_types(numba_type, count, bitwidth, numba_basic_type):
    print(f"Test for {numba_type}")
    assert numba_type.bitwidth == bitwidth
    assert numba_type.count == count
    assert numba_type.dtype == numba_basic_type


def test_views():
    @cuda.jit
    def f(input, output):
        v0 = input.view(np.float16)
        v1 = cuda.local.array(shape=(4 * 7,), dtype=np.float16)
        v2 = v1.view(float16x2_type)
        v3 = v2.view(float16x4_type)
        v4 = output.view(float16x4_type)

        for j in range(7):
            for i in range(4):
                v1[4 * j + i] = v0[4 * j + i]

            for i in range(2):
                v2[2 * j + i] = float16x2(v1[4 * j + 2 * i], v1[4 * j + 2 * i + 1])

            v3[j] = float16x4(v2[2 * j].x, v2[2 * j].y, v2[2 * j + 1].x, v2[2 * j + 1].y)
            v4[j] = v3[j]

    input = np.linspace(0.0, 3.14, 4 * 7, dtype=np.float16)
    output = np.zeros_like(input)
    f[1, 1](input, output)
    cuda.synchronize()

    assert np.allclose(input, output)


def test_views_vector_load_store():
    input = np.linspace(0.0, 3.14, 4, dtype=np.float16)
    output = np.zeros_like(input)

    # Ensure that we get the right vectorized version with float16x4 types
    @cuda.jit
    def f_vectorized(input, output):
        input4 = input.view(float16x4_type)
        output4 = output.view(float16x4_type)
        output4[0] = input4[0]

    f_vectorized[1, 1](input, output)
    cuda.synchronize()
    assert np.allclose(input, output)

    ptx = [v for k, v in f_vectorized.inspect_asm().items()]
    assert len(ptx) == 1
    ptx = ptx[0]

    assert "ld.global.u64" in ptx or "ld.global.b64" in ptx
    assert "st.global.u64" in ptx or "st.global.b64" in ptx

    assert "ld.global.u16" not in ptx or "ld.global.b16" not in ptx
    assert "ld.global.u16" not in ptx or "st.global.b16" not in ptx

    # Ensure that we *don't* get the right vectorized version without
    @cuda.jit
    def f_non_vectorized(input, output):
        for i in range(4):
            output[i] = input[i]

    f_non_vectorized[1, 1](input, output)
    cuda.synchronize()
    assert np.allclose(input, output)

    ptx = [v for k, v in f_non_vectorized.inspect_asm().items()]
    assert len(ptx) == 1
    ptx = ptx[0]

    assert "ld.global.u64" not in ptx or "ld.global.b64" not in ptx
    assert "st.global.u64" not in ptx or "st.global.b64" not in ptx

    assert "ld.global.u16" in ptx or "ld.global.b16" in ptx
    assert "st.global.u16" in ptx or "st.global.b16" in ptx


@pytest.mark.parametrize("compiler", all_compiler_params())
@pytest.mark.parametrize(
    "dtype, real_np_dtype, four_args",
    [
        (complex32, np.float16, False),
        (complex64, np.float32, False),
        (complex128, np.float64, False),
        (half2, np.float16, False),
        (half4, np.float16, True),
    ],
)
def test_underlying_abstraction_storage_interop(request, compiler, dtype, real_np_dtype, four_args):
    cuda = compiler.runtime
    xfail_mlir_fp16(request, compiler, dtype)
    native_ctor, native_dtype = _native_vec_for(compiler, dtype)

    @cuda.jit
    def kernel(out_a, out_b):
        # Direction: native -> abstraction
        native_slot_a = cuda.local.array(shape=(1,), dtype=native_dtype)
        if four_args:
            native_slot_a[0] = dtype(1.0, 2.0, 3.0, 4.0)
        else:
            native_slot_a[0] = dtype(1.0, 2.0)
        abstraction_slot_a = cuda.local.array(shape=(1,), dtype=dtype)
        abstraction_slot_a[0] = native_slot_a[0]
        out_a.view(dtype)[0] = abstraction_slot_a[0]

        # Direction: abstraction -> native
        abstraction_slot_b = cuda.local.array(shape=(1,), dtype=dtype)
        if four_args:
            abstraction_slot_b[0] = native_ctor(5.0, 6.0, 7.0, 8.0)
        else:
            abstraction_slot_b[0] = native_ctor(5.0, 6.0)
        native_slot_b = cuda.local.array(shape=(1,), dtype=native_dtype)
        native_slot_b[0] = abstraction_slot_b[0]
        out_b.view(dtype)[0] = native_slot_b[0]

    out_a = np.zeros(1, dtype=dtype)
    out_b = np.zeros(1, dtype=dtype)
    kernel[1, 1](out_a, out_b)
    cuda.synchronize()

    if np.issubdtype(out_a.dtype, np.complexfloating):
        assert out_a[0] == 1.0 + 2.0j
        assert out_b[0] == 5.0 + 6.0j
    elif four_args:
        assert np.allclose(out_a.view(np.float16), np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float16))
        assert np.allclose(out_b.view(np.float16), np.array([5.0, 6.0, 7.0, 8.0], dtype=np.float16))
    else:
        assert np.allclose(out_a.view(real_np_dtype), np.array([1.0, 2.0], dtype=real_np_dtype))
        assert np.allclose(out_b.view(real_np_dtype), np.array([5.0, 6.0], dtype=real_np_dtype))


@pytest.mark.parametrize("compiler", all_compiler_params())
@pytest.mark.parametrize(
    "dtype, expected_host_dtype",
    [
        (complex32, np_float16x2),
        (complex64, np.complex64),
        (complex128, np.complex128),
        (half2, np_float16x2),
        (half4, np_float16x4),
    ],
)
def test_numba_type(request, compiler, dtype, expected_host_dtype):
    cuda = compiler.runtime
    xfail_mlir_fp16(request, compiler, dtype)
    HOST_COMPLEX = inspect.isclass(expected_host_dtype) and issubclass(expected_host_dtype, np.complexfloating)
    FOUR_ARGS = expected_host_dtype == np_float16x4

    @cuda.jit
    def kernel(a):
        smem = cuda.shared.array(shape=(1,), dtype=dtype)
        if FOUR_ARGS:
            smem[0] = dtype(3.14, 2.71, -1.0, 1.0)
        else:
            smem[0] = dtype(3.14, 2.71)
        a.view(dtype)[0] = smem[0]

    a = np.zeros(1, dtype=dtype)
    assert a.dtype == expected_host_dtype

    kernel[1, 1](a)

    if HOST_COMPLEX:
        assert a[0] == 3.14 + 2.71j
    elif FOUR_ARGS:
        assert np.allclose(a.view(np.float16), np.array([3.14, 2.71, -1.0, 1.0], dtype=np.float16))
    else:
        assert np.allclose(a.view(np.float16), np.array([3.14, 2.71], dtype=np.float16))


@pytest.mark.parametrize(
    "dtype, expected_alignment",
    [
        (complex32, 4),
        (complex64, 8),
        (complex128, 16),
        (half2, 4),
        (half4, 8),
    ],
)
def test_numba_type_alignment(dtype, expected_alignment):
    @cuda.jit
    def copy(a, b):
        av = a.view(dtype)
        bv = b.view(dtype)
        bv[0] = av[0]

    a = np.zeros(1, dtype=dtype)
    b = np.zeros(1, dtype=dtype)

    copy[1, 1](a, b)

    ptx = [v for k, v in copy.inspect_asm().items()]
    assert len(ptx) == 1
    ptx = ptx[0]

    print(ptx)

    if expected_alignment < 16:
        expected_ld_st_inst = f"global.u{expected_alignment * 8}"
        expected_ld_st_inst_b = f"global.b{expected_alignment * 8}"
    else:
        expected_ld_st_inst = f"global.v2.u{expected_alignment * 4}"
        expected_ld_st_inst_b = f"global.v2.b{expected_alignment * 4}"

    assert "ld." + expected_ld_st_inst in ptx or "ld." + expected_ld_st_inst_b in ptx
    assert "st." + expected_ld_st_inst in ptx or "st." + expected_ld_st_inst_b in ptx


@pytest.mark.parametrize("compiler", all_compiler_params())
@pytest.mark.parametrize(
    "complex_dtype, np_complex_ctor",
    [
        (complex64, np.complex64),
        (complex128, np.complex128),
    ],
)
def test_np_complex_cast_from_native_vector(compiler, complex_dtype, np_complex_ctor):
    cuda = compiler.runtime
    native_ctor, _ = _native_vec_for(compiler, complex_dtype)

    @cuda.jit
    def kernel(out):
        v = native_ctor(1.0, 2.0)
        out[0] = np_complex_ctor(v) / 4.0

    out = np.zeros(2, dtype=np_complex_ctor)
    kernel[1, 1](out)
    cuda.synchronize()
    assert out[0] == np_complex_ctor(0.25 + 0.5j)


@pytest.mark.parametrize("compiler", all_compiler_params())
@pytest.mark.parametrize(
    "complex_dtype, np_complex_ctor",
    [
        (complex64, np.complex64),
        (complex128, np.complex128),
    ],
)
def test_np_complex_cast(compiler, complex_dtype, np_complex_ctor):
    cuda = compiler.runtime

    @cuda.jit
    def kernel(in_arr, out_arr):
        tmp = cuda.local.array(shape=(1,), dtype=complex_dtype)
        tmp[0] = in_arr[0]
        tmp[0] = np_complex_ctor(tmp[0]) / 4.0
        out_arr[0] = tmp[0]

    in_arr = np.array([1.0 + 2.0j], dtype=np_complex_ctor)
    out_arr = np.zeros(1, dtype=np_complex_ctor)
    kernel[1, 1](in_arr, out_arr)
    cuda.synchronize()
    assert out_arr[0] == np_complex_ctor(0.25 + 0.5j)
