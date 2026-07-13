# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This module has internal utilities used in implementing the UST and related APIs.
"""

__all__ = []

import threading
from contextlib import nullcontext

import numpy as np

from nvmath.internal import utils
from nvmath.internal.ndbuffer import NDBuffer
from nvmath.internal.package_ifc import StreamHolder


class Cache(dict):
    """
    Cache for sharing kernels and matmuls.
    """

    def __init__(self):
        self.lock = threading.Lock()

    def free(self):
        with self.lock:
            for obj in self.values():
                obj.free()

    def __enter__(self):
        return self

    def __exit__(self, *args, **kwargs):
        self.free()


class LevelMap(dict):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    # TODO: for "subarray" like pos() and crd(), need to allocate one chunk and offset.
    # Also need to keep track of the offsets, or recompute? Add pos.base, crd.base?
    def to(self, device_id, stream_holder):
        level_map = LevelMap(self)
        for k in level_map:
            level_map[k] = self[k].to(device_id, stream_holder)
        return level_map

    def empty_like(self, stream_holder):
        level_map = LevelMap(self)
        for k in level_map:
            level_map[k] = utils.create_empty_tensor(
                self[k].__class__, self[k].shape, self[k].dtype, self[k].device_id, stream_holder, verify_strides=False
            )
        return level_map

    def copy_(self, src, stream_holder):
        for k in self:
            self[k].copy_(src[k], stream_holder)


_CTPS = {
    "complex64": "cuda::std::complex<float>",
    "complex128": "cuda::std::complex<double>",
    "float8_e4m3fn": "__nv_fp8_e4m3",
    "float8_e5m2": "__nv_fp8_e5m2",
    "bfloat16": "__nv_bfloat16",
    "float16": "__half",
    "float32": "float",
    "float64": "double",
    "int64": "long long",
    "int32": "int",
    "int16": "int",
    "int8": "int",
}

_NP_ENVELOPE = {
    "complex32": np.complex64,
    "complex64": np.complex64,
    "complex128": np.complex128,
    "float8_e4m3fn": np.float16,
    "float8_e5m2": np.float16,
    "bfloat16": np.float32,
    "float16": np.float16,
    "float32": np.float32,
    "float64": np.float64,
    "int64": np.int64,
    "int32": np.int32,
    "int16": np.int16,
    "int8": np.int8,
}


def type_str(tp):
    return _CTPS[tp]


def np_enveloping_type(tp):
    return _NP_ENVELOPE[tp]


def resolve_stream(stream, tensor, target_device_id=None):
    """
    Get a default package stream (based on the dense tensor package)
    or wrap user-provided stream.

    Similar logic is implemented inside statefull instances for matmul,
    ffts etc, but ust.Tensor is a standalone public API, so we need
    to implement the logic separately.
    For internal usages from stateful objects, we don't interfere
    and just use the provided StreamHolder.
    """
    # For internal use, we accept StreamHolder so that UST `to` has a
    # consistent interface with `TensorHolder.to`.
    if isinstance(stream, StreamHolder):
        return stream
    device_id = tensor.device_id
    if device_id == "cpu":
        if target_device_id is None or target_device_id == "cpu":
            return None
        device_id = target_device_id
    package = tensor._dense_tensorholder_type.device_tensor_class.name
    return utils.get_or_create_stream(device_id, stream, package)


def stream_context(stream_holder):
    if stream_holder is None:
        return nullcontext()
    return stream_holder.ctx


def as_external_tensor(tensor, stream_holder):
    """
    Return unchanged external package tensor (numpy, torch, etc.)
    or convert a NDBuffer to a host tensor if necessary.
    Ensures the tensor can be subsequently used with
    ufuncs, reductions, etc. (which are not available with NDBuffer).
    """
    if type(tensor) is not NDBuffer:
        return tensor
    if tensor.device_id == "cpu":
        return tensor.as_numpy()
    tensor_host = NDBuffer.empty_like(tensor, device_id="cpu")
    tensor_host.copy_(tensor, stream=stream_holder)
    return tensor_host.as_numpy()
