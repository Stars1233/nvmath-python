# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import contextlib
import itertools

import numpy as np

from nvmath.internal.memory import free_reserved_memory
from nvmath.internal.ndbuffer import NDBuffer
from nvmath.internal.tensor_wrapper import maybe_register_package
from nvmath.internal.utils import device_ctx as _device_ctx
from nvmath.internal.utils import get_or_create_stream

try:
    import cupy as cp
except ImportError:
    cp = None


import cuda.bindings.driver as driver
from cuda.core import Buffer, MemoryResource


class Param:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def __bool__(self):
        return bool(self.value)

    def pretty_name(self):
        if hasattr(self.value, "name"):
            value_str = self.value.name
        else:
            value_str = str(self.value)
        return f"{self.name}.{value_str}"


class DummySlice:
    def __getitem__(self, value):
        return value


_SL = DummySlice()


def idfn(val):
    """
    Pytest does not pretty print (repr/str) parameters of custom types.
    """
    if hasattr(val, "pretty_name"):
        return val.pretty_name()
    # use default pytest pretty printing
    return None


def arange(device_id, stream_holder, volume, dtype):
    if device_id == "cpu":
        a = np.arange(1, volume + 1, dtype=dtype)
        if dtype in (np.complex64, np.complex128):
            a = (a + 1j * np.arange(volume, 0, -1, dtype=dtype)).astype(dtype)
        return a
    elif isinstance(device_id, int):
        if cp is None:
            raise ValueError("cupy is not installed")
        with cp.cuda.Device(device_id), stream_holder.ctx:
            a = cp.arange(1, volume + 1, dtype=dtype)
            if dtype in (cp.complex64, cp.complex128):
                a = (a + 1j * cp.arange(volume, 0, -1, dtype=dtype)).astype(dtype)
            return a
    else:
        raise ValueError(f"Invalid device_id: {device_id}")


def zeros(device_id, stream_holder, shape, dtype):
    if device_id == "cpu":
        return np.zeros(shape, dtype=dtype)
    elif isinstance(device_id, int):
        if cp is None:
            raise ValueError("cupy is not installed")
        with cp.cuda.Device(device_id), stream_holder.ctx:
            return cp.zeros(shape, dtype=dtype)
    else:
        raise ValueError(f"Invalid device_id: {device_id}")


def create_stream(device_id):
    if device_id == "cpu":
        return None
    elif isinstance(device_id, int):
        if cp is None:
            raise ValueError("cupy is not installed")
        maybe_register_package("cupy")
        with cp.cuda.Device(device_id):
            stream = cp.cuda.Stream(non_blocking=True)
            return get_or_create_stream(device_id, stream, "cupy")
    else:
        raise ValueError(f"Invalid device_id: {device_id}")


def free_memory():
    free_reserved_memory()
    if cp is not None:
        cp.get_default_memory_pool().free_all_blocks()


def package(a):
    if isinstance(a, np.ndarray):
        return np
    if isinstance(a, cp.ndarray):
        return cp
    raise ValueError(f"Invalid array: {type(a)}")


def as_ndbuffer(a):
    if isinstance(a, np.ndarray):
        return NDBuffer.from_numpy(a)
    if isinstance(a, cp.ndarray):
        return NDBuffer.from_cupy(a)
    raise ValueError(f"Invalid array: {type(a)}")


def array_ptr(a):
    if isinstance(a, np.ndarray):
        return a.ctypes.data
    if isinstance(a, cp.ndarray):
        return a.data.ptr
    raise ValueError(f"Invalid array: {type(a)}")


def assert_equal(a, b):
    ap = package(a)
    bp = package(b)
    assert ap is bp, f"package of a ({ap}) and b ({bp}) differ"
    ap.testing.assert_array_equal(a, b)


def random_non_empty_slice(rng, shape):
    ndim = len(shape)
    slicable_indicies = [i for i in range(ndim) if shape[i] > 1]
    sliced_ndim = rng.randint(1, len(slicable_indicies))
    sliced_indicies = rng.sample(slicable_indicies, sliced_ndim)
    slices = [slice(None)] * ndim
    for i in sliced_indicies:
        slice_size = rng.randint(1, shape[i] - 1)
        slice_start = rng.randint(0, shape[i] - slice_size)
        slice_end = slice_start + slice_size
        slices[i] = slice(slice_start, slice_end)
    return tuple(slices)


def random_negated_strides(rng, shape):
    ndim = len(shape)
    negated_ndim = rng.randint(1, ndim)
    negated_indicies = rng.sample(range(ndim), negated_ndim)
    slices = [slice(None)] * ndim
    for i in negated_indicies:
        slices[i] = slice(None, None, -1)
    return tuple(slices)


def inv(p):
    inv_p = [0] * len(p)
    for i, d in enumerate(p):
        inv_p[d] = i
    return tuple(inv_p)


def permuted(strides, permutation):
    return tuple(strides[i] for i in permutation)


def random_permutations(rng, perm_len, cutoff_len=3, sample_size=6):
    if perm_len <= cutoff_len:
        return list(itertools.permutations(range(perm_len)))
    perms = []
    for _ in range(sample_size):
        perm = list(range(perm_len))
        rng.shuffle(perm)
        # in principle, we could end up with a duplicate random perm
        # but chances decrease exponentially with the length of the
        # perm and it's not very harmful anyway
        perms.append(tuple(perm))
    return perms


def long_shape(rng, ndim, num_non_unit_dims=5, max_dim_size=6):
    dims = [min(i + 2, max_dim_size) for i in range(num_non_unit_dims)]
    dims.extend(1 for i in range(ndim - num_non_unit_dims))
    rng.shuffle(dims)
    return tuple(dims)


def dense_c_strides(shape, itemsize):
    strides = [0] * len(shape)
    stride = 1
    for i in range(len(shape) - 1, -1, -1):
        strides[i] = stride * itemsize
        stride *= shape[i]
    return tuple(strides)


def abs_strides(strides):
    return tuple(abs(s) for s in strides)


def almost_equal_strides(shape, strides, strides_ref):
    for extent, stride, stride_ref in zip(shape, strides, strides_ref, strict=True):
        if extent != 1 and stride != stride_ref:
            return False
    return True


def as_cp_array(ndbuffer, device_id: int | None = None):
    base_ptr, size_in_bytes, offset_in_bytes = ndbuffer.raw_memory_range_info
    mem = cp.cuda.UnownedMemory(
        base_ptr,
        size_in_bytes,
        owner=ndbuffer.data,
        device_id=device_id if device_id is not None else ndbuffer.device_id,
    )
    memptr = cp.cuda.MemoryPointer(mem, offset=offset_in_bytes)
    return cp.ndarray(
        shape=ndbuffer.shape,
        strides=ndbuffer.strides_in_bytes,
        dtype=ndbuffer.dtype_name,
        memptr=memptr,
    )


def as_array(ndbuffer):
    if ndbuffer.device_id == "cpu":
        return ndbuffer.as_numpy()
    else:
        return as_cp_array(ndbuffer)


# Cuda.core dummy memory resources


def handle_return(ret):
    if ret[0] != driver.CUresult.CUDA_SUCCESS:
        raise RuntimeError(f"CUDA error: {driver.CUresult(ret[0]).name}")
    if len(ret) == 1:
        return
    elif len(ret) == 2:
        return ret[1]
    else:
        return ret[1:]


class DummyDeviceMemoryResource(MemoryResource):
    def __init__(self, device_id):
        self._device_id = device_id
        self.active_allocs = {}
        self.seen_streams = set()

    def allocate(self, size, *, stream=None) -> Buffer:
        if stream is not None:
            self.seen_streams.add(int(stream.handle))
        with device_ctx(self.device_id):
            ptr = handle_return(driver.cuMemAlloc(size))
            ptr = int(ptr)
            buffer = Buffer.from_handle(ptr=ptr, size=size, mr=self)
            self.active_allocs[ptr] = ptr
            return buffer

    def deallocate(self, ptr, size, stream=None):
        del self.active_allocs[ptr]
        handle_return(driver.cuMemFree(ptr))

    @property
    def is_device_accessible(self) -> bool:
        return True

    @property
    def is_host_accessible(self) -> bool:
        return False

    @property
    def device_id(self) -> int:
        return self._device_id


class DummyHostMemoryResource(MemoryResource):
    def __init__(self):
        self.active_allocs = {}
        self.seen_streams = set()

    def allocate(self, size, *, stream=None) -> Buffer:
        if stream is not None:
            self.seen_streams.add(int(stream.handle))
        a = np.zeros(size, dtype=np.uint8)
        ptr = int(a.ctypes.data)
        self.active_allocs[ptr] = a
        return Buffer.from_handle(ptr=ptr, size=size, mr=self)

    def deallocate(self, ptr, size, stream=None):
        del self.active_allocs[ptr]

    @property
    def is_device_accessible(self) -> bool:
        return False

    @property
    def is_host_accessible(self) -> bool:
        return True

    @property
    def device_id(self) -> int:
        return -1


class DummyPinnedMemoryResource(MemoryResource):
    def __init__(self):
        self.active_allocs = {}
        self.seen_streams = set()

    def allocate(self, size, *, stream=None) -> Buffer:
        if stream is not None:
            self.seen_streams.add(int(stream.handle))
        ptr = handle_return(driver.cuMemAllocHost(size))
        ptr = int(ptr)
        buffer = Buffer.from_handle(ptr=ptr, size=size, mr=self)
        self.active_allocs[ptr] = ptr
        return buffer

    def deallocate(self, ptr, size, stream=None):
        del self.active_allocs[ptr]
        handle_return(driver.cuMemFreeHost(ptr))

    @property
    def is_device_accessible(self) -> bool:
        return True

    @property
    def is_host_accessible(self) -> bool:
        return True

    @property
    def device_id(self) -> int:
        return -1


def device_ctx(device_id):
    return _device_ctx(device_id) if isinstance(device_id, int) else contextlib.nullcontext()


def stream_ctx(stream):
    return stream.ctx if stream is not None else contextlib.nullcontext()


def mem_locations_from_direction(device_id: int, direction):
    if direction == "h2d":
        return "cpu", device_id
    elif direction == "d2h":
        return device_id, "cpu"
    elif direction == "d2d":
        return device_id, device_id
    else:
        assert direction == "h2h"
        return "cpu", "cpu"
