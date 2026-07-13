# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0


from collections.abc import Iterable
from typing import Any

import cffi
import numpy as np
from numba_cuda_mlir import cuda
from numba_cuda_mlir._mlir.dialects import llvm
from numba_cuda_mlir._mlir.extras import types as T
from numba_cuda_mlir.cuda import vector_types
from numba_cuda_mlir.extending import lowering_registry, overload, overload_attribute, typing_registry
from numba_cuda_mlir.lowering_utilities import to_mlir_type, unverified_convert
from numba_cuda_mlir.lowering_utilities.type_conversions import to_numba_type
from numba_cuda_mlir.models import PrimitiveModel
from numba_cuda_mlir.models import register_model as numba_cuda_mlir_register_model
from numba_cuda_mlir.numba_cuda import types
from numba_cuda_mlir.numba_cuda.extending import typeof_impl
from numba_cuda_mlir.numba_cuda.np import numpy_support
from numba_cuda_mlir.type_defs.vector_types import VectorType

from .types import Complex, Vector

__all__ = [
    "HostDescriptorBase",
    "overload_type_attribute",
    "register_dummy_type",
    "get_array_pointer",
]

# ==========================
# Argument-conversion helpers for JIT bodies
# ==========================

_FFI = cffi.FFI()


@cuda.jit(device=True, forceinline=True)
def get_array_pointer(arr):
    return _FFI.from_buffer(arr)


@cuda.jit(device=True, inline="always")
def int_to_uint32_ptr(val):
    local = cuda.local.array(shape=(1,), dtype=np.uint32)
    local[0] = val
    return _FFI.from_buffer(local)


@cuda.jit(device=True, forceinline=True)
def passthrough(val):
    return val


def get_value_ptr(value: Any) -> int:
    raise NotImplementedError("get_value_ptr is callable only from jitted code")


@overload(get_value_ptr, strict=False, inline="always", typing_registry=typing_registry)
def ol_get_value_ptr(value):
    # TODO(numba-cuda-mlir): Known complex types work correctly,
    # but types.Complex("complex32",types.float16) currently fails.
    # For now, handle all complex types here explicitly.
    # Ideally, all of this should be replaced by a generic as_dtype path.
    dtype = value if isinstance(value, (VectorType, types.Complex)) else numpy_support.as_dtype(value).type

    def impl(value):
        local = cuda.local.array(shape=(1,), dtype=dtype)
        local[0] = value
        return _FFI.from_buffer(local)

    return impl


# ==========================
# Type registration helpers
# ==========================


class HostDescriptorBase(types.Type):
    """
    Base numba type wrapping a host descriptor,
    subclass per API (cufftdx, cusolverdx, ...).
    """

    def __init__(
        self,
        host_descriptor,
        definition_args: Iterable[str],
        type_kind: str,
    ) -> None:
        self._host_descriptor = host_descriptor

        attributes = [
            f"{attr}={getattr(host_descriptor, attr)}" for attr in definition_args if getattr(host_descriptor, attr, None)
        ]
        attributes.sort()

        super().__init__(f"{type_kind}({','.join(attributes)})")

    @property
    def host_descriptor(self):
        return self._host_descriptor


def overload_type_attribute(
    numba_type: type[types.Type],
    attribute_base: str,
    attribute: str,
) -> None:
    """Make type attribute available inside jitted code."""
    assert issubclass(numba_type, types.Type)

    @overload_attribute(
        numba_type,
        attribute,
        inline="always",
        typing_registry=typing_registry,
        lowering_registry=lowering_registry,
    )
    def ol_attribute(api_numba):
        tp = api_numba
        if attribute_base != "":
            tp = getattr(tp, attribute_base)
        val = getattr(tp, attribute)
        return lambda api_numba: val


class _DummyMlirModel(PrimitiveModel):
    """Shared data model for numba types that have no runtime memory footprint."""

    def __init__(self, dmm, fe_type) -> None:
        super().__init__(dmm, fe_type, T.i8())


def register_dummy_type(
    numba_type: type[types.Type],
    base_type: type,
    attributes: Iterable[str],
    *,
    attribute_base: str | None = None,
) -> None:
    """
    Register a dummy numba-cuda-mlir type that exists only at typing time.

    Bundles five effects:
      * typeof_impl.register(base_type)
      * register_model(numba_type) with the shared dummy PrimitiveModel
      * to_mlir_type.register(numba_type) returning T.i8()
      * unverified_convert.register(base_type) returning llvm.mlir_undef(T.i8())
      * an overload_type_attribute(numba_type, attribute_base, attribute)
        for each name in attributes.
    """
    if attribute_base is None and issubclass(numba_type, HostDescriptorBase):
        attribute_base = "host_descriptor"
    assert attribute_base is not None

    @typeof_impl.register(base_type)
    def _typeof(val, context):
        return numba_type(val)

    numba_cuda_mlir_register_model(numba_type)(_DummyMlirModel)

    @to_mlir_type.register(numba_type)
    def _to_mlir(val, context):
        return T.i8()

    @unverified_convert.register(base_type)
    def _unverified_convert(val, target_type, signed: bool = False):
        assert target_type == T.i8()
        return llvm.mlir_undef(T.i8())

    for attribute in attributes:
        overload_type_attribute(numba_type, attribute_base, attribute)


# ==========================
# Vector/Complex typing
# ==========================


@to_numba_type.register(Vector)
def _(val: Vector) -> types.Type:
    return getattr(vector_types, f"{np.dtype(val.real_dtype).name}x{val.size}")


@to_numba_type.register(Complex)
def _(val: Complex) -> types.Type:
    # real_type = to_numba_type(val.real_dtype)
    real_type = to_numba_type(np.dtype(val.real_dtype))
    assert isinstance(real_type, types.Float)
    return types.Complex(f"complex{real_type.bitwidth * 2}", real_type)


# TODO: do we need both to_numba_type and typeof_impl for Vector and Complex?
@typeof_impl.register(Vector)
@typeof_impl.register(Complex)
def _typeof_host_type(val, c):
    return typeof_impl(to_numba_type(val), c)
