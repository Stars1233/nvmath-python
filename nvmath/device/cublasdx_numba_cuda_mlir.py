# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from numba_cuda_mlir import types
from numba_cuda_mlir.compiler import declare_device
from numba_cuda_mlir.extending import (
    overload,
    overload_method,
    typing_registry,
)
from numba_cuda_mlir.lowering_utilities.type_conversions import to_numba_type
from numba_cuda_mlir.numba_cuda.cudadrv.linkable_code import LTOIR
from numba_cuda_mlir.numba_cuda.extending import typeof_impl

from nvmath.device.common import (
    axpby,
    clear,
    copy,
    copy_fragment,
    copy_wait,
    make_fragment_like,
    make_tensor,
)
from nvmath.device.common_cuda import get_default_code_type
from nvmath.device.common_numba_cuda_mlir import (
    HostDescriptorBase,
    get_array_pointer,
    get_value_ptr,
    int_to_uint32_ptr,
    register_dummy_type,
)
from nvmath.device.cublasdx import (
    DevicePipeline,
    Matmul,
    TilePipeline,
    _BlasMatmulLayout,
    _BlasMatmulLikeLayout,
    compile_blas_execute,
)

from .cublasdx_backend import (
    _BLAS_COMPILED_ARGS,
    _BLAS_DEFINITION_ARGS,
)

# ==============================================
# Helpers
# ==============================================


def _check_array_value_types(MM: Matmul, a: types.Array, b: types.Array, c: types.Array) -> bool:
    expected = tuple(to_numba_type(vt) for vt in MM._traits.value_types)
    return (a.dtype, b.dtype, c.dtype) == expected


_NOT_SUPPORTED = (
    "Advanced matmul and opaque tensor APIs are not yet supported by the numba-cuda-mlir backend."
    " Only Matmul.execute with array operands is available."
)


def _unsupported(*args, **kwargs):
    raise NotImplementedError(_NOT_SUPPORTED)


# ==============================================
# Matmul Type
# ==============================================


class BlasType(HostDescriptorBase):
    """
    Type class associated with the `cublasdx.Matmul`.
    """

    def __init__(self, blas: Matmul) -> None:
        assert isinstance(blas, Matmul)
        super().__init__(blas, _BLAS_DEFINITION_ARGS, "BlasNumba")


register_dummy_type(BlasType, Matmul, _BLAS_DEFINITION_ARGS + _BLAS_COMPILED_ARGS)


# ==============================================
# Matmul executes
# ==============================================


@overload_method(BlasType, "execute", strict=False, typing_registry=typing_registry)
def ol_blas_execute(blas_numba: BlasType, _arg1, _arg2, _arg3, _arg4=None, _arg5=None, _arg6=None, _arg7=None, _arg8=None):
    if not isinstance(blas_numba, BlasType):
        return

    none_set = {None, types.Omitted(None)}
    MM = blas_numba.host_descriptor

    if {_arg4, _arg5, _arg6, _arg7, _arg8} <= none_set:
        _unsupported()

    if {_arg6, _arg7, _arg8} <= none_set:
        if not all(isinstance(x, types.Array) for x in (_arg2, _arg3, _arg5)):
            _unsupported()
        return _build_basic_impl(MM, _arg1, _arg2, _arg3, _arg4, _arg5)

    if not all(isinstance(x, types.Array) for x in (_arg2, _arg4, _arg7)):
        _unsupported()
    return _build_ldabc_impl(MM, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7, _arg8)


def _build_basic_impl(MM: Matmul, alpha, a, b, beta, c):
    if (
        not all(isinstance(x, types.Number) for x in (alpha, beta))
        or not all(isinstance(x, types.Array) for x in (a, b, c))
        or not _check_array_value_types(MM, a, b, c)
    ):
        return None

    code, symbol = compile_blas_execute(
        MM,
        code_type=get_default_code_type(),
        execute_api="static_leading_dimensions",
    )

    c_value_type = MM.c_value_type
    c_ptr = types.CPointer(c.dtype)
    sig = types.void(c_ptr, types.CPointer(a.dtype), types.CPointer(b.dtype), c_ptr, c_ptr)
    blas_device_func = declare_device(symbol, sig, link=LTOIR(code.data), abi="c")

    def impl(_, alpha, a, b, beta, c, _arg6=None, _arg7=None, _arg8=None):
        aptr = get_array_pointer(a)
        bptr = get_array_pointer(b)
        cptr = get_array_pointer(c)
        alpha_ptr = get_value_ptr(c_value_type(alpha))
        beta_ptr = get_value_ptr(c_value_type(beta))

        blas_device_func(alpha_ptr, aptr, bptr, beta_ptr, cptr)

    return impl


def _build_ldabc_impl(MM: Matmul, alpha, a, lda, b, ldb, beta, c, ldc):
    if (
        not all(isinstance(x, types.Number) for x in (alpha, beta))
        or not all(isinstance(x, types.Array) for x in (a, b, c))
        or not all(isinstance(x, types.Integer) for x in (lda, ldb, ldc))
        or not _check_array_value_types(MM, a, b, c)
    ):
        return None

    code, symbol = compile_blas_execute(
        MM,
        code_type=get_default_code_type(),
        execute_api="dynamic_leading_dimensions",
    )

    c_value_type = MM.c_value_type
    ld_ptr = types.CPointer(types.uint32)
    c_ptr = types.CPointer(c.dtype)
    sig = types.void(c_ptr, types.CPointer(a.dtype), ld_ptr, types.CPointer(b.dtype), ld_ptr, c_ptr, c_ptr, ld_ptr)
    blas_device_func = declare_device(symbol, sig, link=LTOIR(code.data), abi="c")

    def impl(_, alpha, a, lda, b, ldb, beta, c, ldc):
        aptr = get_array_pointer(a)
        bptr = get_array_pointer(b)
        cptr = get_array_pointer(c)
        alpha_ptr = get_value_ptr(c_value_type(alpha))
        beta_ptr = get_value_ptr(c_value_type(beta))
        lda_ptr = int_to_uint32_ptr(lda)
        ldb_ptr = int_to_uint32_ptr(ldb)
        ldc_ptr = int_to_uint32_ptr(ldc)

        blas_device_func(alpha_ptr, aptr, lda_ptr, bptr, ldb_ptr, beta_ptr, cptr, ldc_ptr)

    return impl


# ==============================================
# Unsupported API surface
# ==============================================

_UNSUPPORTED_BLAS_METHODS = (
    "get_accumulator",
    "suggest_accumulator",
    "get_layout_smem_a",
    "get_layout_smem_b",
    "get_layout_smem_c",
    "get_layout_gmem_a",
    "get_layout_gmem_b",
    "get_layout_gmem_c",
    "suggest_layout_smem_a",
    "suggest_layout_smem_b",
    "suggest_layout_smem_c",
    "suggest_layout_rmem_c",
    "get_layout_rmem_c",
    "_get_accumulator_c",
    "_suggest_accumulator_c",
)
for _method in _UNSUPPORTED_BLAS_METHODS:
    overload_method(BlasType, _method, strict=False, typing_registry=typing_registry)(_unsupported)

_UNSUPPORTED_FREE_FUNCTIONS = (make_tensor, make_fragment_like, copy, copy_fragment, clear, copy_wait, axpby)
for _func in _UNSUPPORTED_FREE_FUNCTIONS:
    overload(_func, strict=False, typing_registry=typing_registry)(_unsupported)

_UNSUPPORTED_TYPES = (DevicePipeline, TilePipeline, _BlasMatmulLayout, _BlasMatmulLikeLayout)
for _cls in _UNSUPPORTED_TYPES:
    typeof_impl.register(_cls)(_unsupported)
