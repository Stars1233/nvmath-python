# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to CuPy operations.
"""

__all__ = ["CupyPackage"]

import cupy as cp

from . import utils
from .package_ifc import Package, _cuda_core_stream_holder

_CUPY_MAJOR = int(cp.__version__.split(".")[0])

# Using the functional API is faster than setting a device context
if _CUPY_MAJOR >= 13:
    _get_current_stream = cp.cuda.get_current_stream
else:

    def _get_current_stream(device_id: int):
        with utils.device_ctx(device_id):
            stream = cp.cuda.get_current_stream()
        return stream


# CuPy v14 deprecated ``cp.cuda.ExternalStream(int)`` in favor of
# ``cp.cuda.Stream.from_external(obj)``, where ``obj`` must implement the
# CUDA stream protocol.
if _CUPY_MAJOR >= 14:

    def _create_external_stream(stream_ptr: int):
        return cp.cuda.Stream.from_external(_cuda_core_stream_holder(stream_ptr))

else:
    _create_external_stream = cp.cuda.ExternalStream


class CupyPackage(Package[cp.cuda.Stream]):
    @staticmethod
    def get_current_stream(device_id: int):
        return _get_current_stream(device_id)

    @staticmethod
    def to_stream_pointer(stream: cp.cuda.Stream) -> int:
        return stream.ptr

    # Goal: return the raw ``cudaStream_t`` int for the current stream on a
    # given device. CuPy has a binding-level ptr getter at the runtime
    # layer, but at the time this method was added it was only exposed as
    # a Cython ``cdef`` function not callable from Python, so we can't
    # reach it directly. ``cp.cuda.get_current_stream().ptr`` is nearly
    # as fast empirically because CuPy caches the per-thread Stream object on
    # ``_ThreadLocal.current_stream``.
    @staticmethod
    def get_current_stream_ptr(device_id: int) -> int:
        return _get_current_stream(device_id).ptr

    @staticmethod
    def to_stream_context(stream: cp.cuda.Stream):
        return stream

    @staticmethod
    def create_external_stream(device_id: int, stream_ptr: int):
        return _create_external_stream(stream_ptr)
