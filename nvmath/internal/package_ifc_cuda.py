# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to cuda.core operations.
"""

__all__ = ["CUDAPackage"]

import contextlib
import functools

from cuda.core import Stream

from ._device_utils import get_device
from .package_ifc import Package


# cuda.core's ``Device.default_stream`` wraps a CUDA driver *sentinel* pointer
# (``CU_STREAM_LEGACY = 0x1`` or ``CU_STREAM_PER_THREAD = 0x2``) that is constant
# for the life of the process, so the (device_id -> ptr) map can be cached.
@functools.cache
def _get_current_stream_ptr(device_id: int) -> int:
    return int(get_device(device_id).default_stream.handle)


class CUDAPackage(Package[Stream]):
    @staticmethod
    def get_current_stream(device_id: int):
        # Use get_device to ensure the cuda.core
        # device has been initialized.
        # In cuda.core 0.5.0, Stream.__hash__ requires context
        # to be set.
        # See https://github.com/NVIDIA/cuda-python/issues/1480
        # TODO(ktokarski): Once we drop support for cuda.core 0.5.0,
        # we can remove this precaution.
        device = get_device(device_id)
        return device.default_stream

    @staticmethod
    def to_stream_pointer(stream: Stream) -> int:  # type: ignore[override]
        return int(stream.handle)

    get_current_stream_ptr = staticmethod(_get_current_stream_ptr)

    @staticmethod
    def to_stream_context(stream: Stream):  # type: ignore[override]
        return contextlib.nullcontext(stream)

    @staticmethod
    def create_external_stream(device_id: int, stream_ptr: int) -> Stream:
        return Stream.from_handle(stream_ptr)

    @classmethod
    def create_stream(cls, external: Stream, device_id: int) -> Stream:  # type: ignore[override]
        return external
