# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from numba_cuda_mlir.compiler import declare_device
from numba_cuda_mlir.extending import overload_method, typing_registry
from numba_cuda_mlir.lowering_utilities.type_conversions import to_numba_type
from numba_cuda_mlir.numba_cuda import types
from numba_cuda_mlir.numba_cuda.cudadrv.linkable_code import LTOIR

from nvmath.device.common_cuda import get_default_code_type
from nvmath.device.common_numba_cuda_mlir import HostDescriptorBase, get_array_pointer, register_dummy_type
from nvmath.device.cufftdx import FFT, compile_fft_execute

from .cufftdx_backend import _FFT_COMPILED_ARGS, _FFT_DEFINITION_ARGS


class FFTType(HostDescriptorBase):
    """
    Type class associated with the `cufftdx.FFT`.
    """

    def __init__(self, fft: FFT) -> None:
        assert isinstance(fft, FFT)
        super().__init__(fft, _FFT_DEFINITION_ARGS, "FFT")


register_dummy_type(FFTType, FFT, _FFT_DEFINITION_ARGS + _FFT_COMPILED_ARGS)


@overload_method(FFTType, "execute", strict=False, typing_registry=typing_registry)
def ol_execute(fft_numba, thread_data, smem=None):
    if not isinstance(fft_numba, FFTType):
        return
    if not isinstance(thread_data, types.Array):
        return
    if smem is not None and not isinstance(smem, (types.Array, types.Omitted)):
        return

    fft = fft_numba.host_descriptor

    value_type = to_numba_type(fft.value_type)

    if thread_data.dtype != value_type:
        raise ValueError(f"Thread data dtype {thread_data.dtype} does not match value type {value_type}")

    is_smem = smem is not None and not isinstance(smem, types.Omitted)
    if is_smem and smem.dtype != value_type:
        raise ValueError(f"Smem dtype {smem.dtype} does not match value type {value_type}")

    execute_api = (
        "register_memory" if fft.execution == "Block" and is_smem else "shared_memory" if fft.execution == "Block" else None
    )

    code, symbol = compile_fft_execute(
        fft,
        code_type=get_default_code_type(),
        execute_api=execute_api,
    )

    if not is_smem:
        sig = types.void(types.CPointer(value_type))
        device_func = declare_device(symbol, sig, link=LTOIR(code.data), abi="c")

        def impl(fft_numba, thread_data, smem=None):
            ptr = get_array_pointer(thread_data)
            device_func(ptr)

        return impl
    else:
        sig = types.void(types.CPointer(value_type), types.CPointer(value_type))
        device_func = declare_device(symbol, sig, link=LTOIR(code.data), abi="c")

        def impl(fft_numba, thread_data, smem=None):
            tptr = get_array_pointer(thread_data)
            sptr = get_array_pointer(smem)
            device_func(tptr, sptr)

        return impl
