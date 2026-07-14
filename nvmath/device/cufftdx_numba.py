# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from numba import cuda
from numba.core import cgutils, typing
from numba.cuda.cudaimpl import lower_constant
from numba.cuda.extending import overload_method, typeof_impl
from numba.cuda.models import register_model
from numba.extending import types

from nvmath.device.common_cuda import get_default_code_type
from nvmath.device.cufftdx import FFT, compile_fft_execute

from .common_numba import (
    NUMBA_FE_TYPES_TO_NUMBA_IR,
    EmptyStructModel,
    declare_cabi_device,
    get_array_ptr,
    overload_type_attribute,
)
from .cufftdx_backend import _FFT_COMPILED_ARGS, _FFT_DEFINITION_ARGS


class FFTType(types.Type):
    """
    Type class associated with the `cufftdx.FFT`.
    """

    def __init__(self, fft: FFT):
        assert isinstance(fft, FFT)
        self._fft = fft
        attributes = [f"{attr}={getattr(fft, attr)}" for attr in _FFT_DEFINITION_ARGS if getattr(fft, attr)]
        attributes.sort()

        self.name = "FFT(" + ",".join(attributes) + ")"

    @property
    def fft(self) -> FFT:
        return self._fft


register_model(FFTType)(EmptyStructModel)


@lower_constant(FFTType)
def constant_dummy(context, builder, typ, pyval):
    struct_ptr = cgutils.create_struct_proxy(typ)(context, builder)
    return struct_ptr._getvalue()


@typeof_impl.register(FFT)
def typeof_fft_numba(val: FFT, c: typing.Context) -> FFTType:
    return FFTType(val)


for attribute in _FFT_DEFINITION_ARGS + _FFT_COMPILED_ARGS:
    overload_type_attribute(FFTType, "fft", attribute)


# Numba does not support method overload or variadic arguments, so we using
# default values as a workaround
# https://github.com/numba/numba/issues/9980
# https://github.com/numba/numba/issues/9979
# https://github.com/numba/numba/issues/10143
@overload_method(FFTType, "execute", jit_options={"forceinline": True}, strict=False)
def ol_fft_numba_execute(fft_numba: FFTType, _arg1, _arg2=None):
    if _arg2 in {None, types.Omitted(None), types.none}:
        return ol_fft_type_execute_rmem(fft_numba, _arg1)
    return ol_fft_type_execute_smem(fft_numba, _arg1, _arg2)


def ol_fft_type_execute_rmem(
    fft_numba: FFTType,
    thread_data: types.Array,
):
    if not isinstance(fft_numba, FFTType):
        return
    if not isinstance(thread_data, types.Array):
        return

    FFT = fft_numba.fft
    value_type = NUMBA_FE_TYPES_TO_NUMBA_IR[FFT.value_type]
    if thread_data.dtype != value_type:
        return

    code, symbol = compile_fft_execute(
        FFT,
        code_type=get_default_code_type(),
        execute_api="shared_memory" if FFT.execution == "Block" else None,
    )

    lto = cuda.LTOIR(code.data)

    sig = types.void(types.CPointer(value_type))
    fft_device_func = declare_cabi_device(symbol, sig, link=lto)

    def impl(_, thread_data, _arg2=None):
        tptr = get_array_ptr(thread_data)
        fft_device_func(tptr)

    return impl


def ol_fft_type_execute_smem(
    fft_numba: FFTType,
    thread_data: types.Array,
    smem: types.Array,
):
    if not isinstance(fft_numba, FFTType):
        return
    if not isinstance(thread_data, types.Array):
        return
    if not isinstance(smem, types.Array):
        return
    FFT = fft_numba.fft
    value_type = NUMBA_FE_TYPES_TO_NUMBA_IR[FFT.value_type]
    if smem.dtype != value_type:
        return
    if thread_data.dtype != value_type:
        return

    code, symbol = compile_fft_execute(
        FFT,
        code_type=get_default_code_type(),
        execute_api="register_memory" if FFT.execution == "Block" else None,
    )

    lto = cuda.LTOIR(code.data)

    value_type = NUMBA_FE_TYPES_TO_NUMBA_IR[FFT.value_type]
    sig = types.void(types.CPointer(value_type), types.CPointer(value_type))
    fft_device_func = declare_cabi_device(symbol, sig, link=lto)

    def impl(_, thread_data, smem):
        tptr = get_array_ptr(thread_data)
        sptr = get_array_ptr(smem)
        fft_device_func(tptr, sptr)

    return impl
