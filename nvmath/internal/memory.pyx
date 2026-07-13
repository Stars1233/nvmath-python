# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

cimport cython
from libc.stdint cimport int64_t, intptr_t, uint64_t
from ._bindings cimport (
    free_memory_pool_reserved_memory as _free_memory_pool_reserved_memory,
    get_runtime_version,
    get_driver_version,
    set_memory_pool_access,
    set_memory_pool_release_threshold,
)

cdef extern from "limits.h":
    cdef uint64_t ULLONG_MAX

import os
import threading
import logging
import warnings

from cuda.core import system, Device, LegacyPinnedMemoryResource

_is_pinned_memory_pool_supported = None
from cuda.core import PinnedMemoryResource, PinnedMemoryResourceOptions


from nvmath.internal._device_utils import get_device


_thread_local = threading.local()
_pinned_pool_lock = threading.Lock()
_pinned_memory_pools = []


cdef inline _get_local_mrs():
    """
    Device memory resource cache is thread-local but we actually
    put there and reuse cuda.core.Device(device_id).memory_resouce
    instances across threads.
    """
    try:
        return _thread_local.mem_resources
    except AttributeError:
        _thread_local.mem_resources = mrs = [None] * system.get_num_devices()
        return mrs


cdef bint is_pinned_memory_pool_supported() except? -1:
    global _is_pinned_memory_pool_supported
    if _is_pinned_memory_pool_supported is not None:
        return _is_pinned_memory_pool_supported
    cdef str env_flag = os.environ.get('NVMATH_DISABLE_PINNED_MEMORY_POOL')
    if env_flag and env_flag.lower()[:1] not in ['0', 'f']:
        _is_pinned_memory_pool_supported = False
        warnings.warn(
            "Pinned memory pool was disabled with the "
            "NVMATH_DISABLE_PINNED_MEMORY_POOL environment variable. "
            "Memory transfers between host and device may unnecessarily block."
        )
        return False
    _is_pinned_memory_pool_supported = (
        get_runtime_version() >= 12060
        and get_driver_version() >= 12060
    )
    if not _is_pinned_memory_pool_supported:
        warnings.warn(
            "Pinned memory pool support is not available. "
            "Memory transfers between host and device may unnecessarily block. "
            "Please upgrade the CUDA driver and runtime to at least 12.6."
        )
    return _is_pinned_memory_pool_supported


cdef object _get_pinned_async_memory_resource(int device_id):
    """
    We create separate private pinned memory resource pools per device,
    reused across threads.
    """
    cdef object mr
    cdef object current_device = Device()
    cdef object new_device = Device(device_id)
    with _pinned_pool_lock:
        try:
            new_device.set_current()
            if len(_pinned_memory_pools) == 0:
                _pinned_memory_pools.extend([None] * system.get_num_devices())
            mr = _pinned_memory_pools[device_id]
            if mr is not None:
                return mr

            # pass dummy empty options to force creation of a new memory resource
            mr = PinnedMemoryResource(options=PinnedMemoryResourceOptions())
            # Neither cuda async memory pools nor the cuda.core wrappers
            # by default ensure that the memory is visible to devices.
            # We need to manually set it, otherwise:
            # - direct access from device could lead to invalid mem access
            # - cuda memcopies would silently fallback to pagable copy
            set_memory_pool_access(int(mr.handle), device_id)
            _pinned_memory_pools[device_id] = mr
            # If we kept the default 0 threshold, we would risk extremely
            # slow and fully synchronous release of memory back to OS
            # happening repeatedly
            set_memory_pool_release_threshold(int(mr.handle), ULLONG_MAX)
            return mr
        finally:
            current_device.set_current()


cpdef object get_pinned_async_memory_resource(int device_id):
    """
    Get a memory resource that allocates host pinned memory
    accessible (mapped into device address space) by the given device.

    .. note::
        This is experimental API, it may be removed or changed
        (including functional changes e.g. as to sharing returned memory resources
        across devices, threads, or packages).

    .. note::
        The function may return None if pinned mem pool is not supported
        or if the environment variable NVMATH_DISABLE_PINNED_MEMORY_POOL is set.
        Pinned memory pool support was added in CUDA 12.6 and requires cuda.core >= 0.5.0.

    """
    cdef object mr
    try:
        mr = _pinned_memory_pools[device_id]
    except IndexError:
        mr = None
    if mr is not None or not is_pinned_memory_pool_supported():
        return mr
    return _get_pinned_async_memory_resource(device_id)


cpdef object get_legacy_pinned_memory_resource(int device_id):
    """
    Returns cuda.core's mem resource that is a wrapper
    around cuMemAllocHost/cuMemFreeHost. It de-facto meets
    stream-oriented semantics but via expensive host-device
    synchronizations at every allocation and deallocation.

    .. note::
        The API is experimental and may be removed or changed
        without notice.
    """
    try:
        return _thread_local.legacy_pinned_mr
    except AttributeError:
        get_device(device_id)  # ensure cuda ctx is initialized
        _thread_local.legacy_pinned_mr = LegacyPinnedMemoryResource()
        return _thread_local.legacy_pinned_mr



cpdef get_device_memory_resource(int device_id):
    """
    Returns cuda.core.MemoryResource instance for the given device.
    The instances are cached per thread and reused for subsequent calls.
    """
    mrs = _get_local_mrs()
    mr = mrs[device_id]
    if mr is None:
        mrs[device_id] = mr = get_device(device_id).memory_resource
    return mr


cdef get_default_stream(int device_id):
    """
    Returns the default stream for the given device.
    """
    cdef default_stream = None
    try:
        default_stream = _thread_local.default_streams[device_id]
    except AttributeError:
        _thread_local.default_streams = [None] * system.get_num_devices()
    if default_stream is None:
        _thread_local.default_streams[device_id] = default_stream = get_device(device_id).default_stream
    return default_stream


cdef inline str _print_stream(stream):
    if stream is None:
        return "None"
    return str(int(stream.handle))


cdef inline int64_t _round_up_allocation_size(int64_t size) except? -1 nogil:
    """
    Rounds up the allocation size to the nearest multiple of 512 bytes.
    """
    return (size + 511) & ~511


cdef class _MemoryPointer:
    """
    Temporary internal NDBuffer allocation adapter class. NDBuffer expects
    custom allocator to return a cuda.core.Buffer instance. Until all supported
    cuda.core versions have unified support for wrapping external allocations
    with Buffer.from_handle, this class servers as an adapter/workaround.

    WARNING: This is internal tool subject to change/removal without notice.

    Internally, it is used conditionally to provide debug logging on deallocation.
        We can get rid of this class and use weakref.finalize for Buffer with cuda.core >= 0.6.0.

    The only publicly exposed field is the handle - a base pointer to the allocated memory.
    """
    cdef public intptr_t handle
    cdef public object owner
    cdef object logger
    cdef str dealloc_message
    cdef str alloc_stream

    @classmethod
    def from_handle(cls, intptr_t handle, owner):
        cdef _MemoryPointer self = _MemoryPointer.__new__(_MemoryPointer)
        self._init_from_handle(handle, owner)
        return self

    def __del__(self):
        if self.logger is not None:
            self.logger.debug(self.dealloc_message.format(stream=self.alloc_stream))

    def close(self, stream):
        if self.owner is None:
            return
        self.owner.close(stream)
        self.owner = None
        if self.logger is not None:
            self.logger.debug(self.dealloc_message.format(stream=_print_stream(stream)))
            self.logger = None
            self.dealloc_message = None

    cdef inline _init_from_buffer(self, buffer, stream, logger, dealloc_message):
        self.handle = int(buffer.handle)
        self.owner = buffer
        self.logger = logger
        self.dealloc_message = dealloc_message
        self.alloc_stream = _print_stream(stream)

    cdef inline _init_from_handle(self, intptr_t handle, owner):
        self.handle = handle
        self.owner = owner


cpdef allocate_from_mr(mr, int64_t size, stream, int device_id, logger = None):
    """
    Common helper for allocating memory from a memory resource.
    It rounds-up the allocation size to the nearest multiple of 512 bytes
    and provides debug logging if requested.
    """
    cdef bint has_debug_logging = logger is not None and logger.isEnabledFor(logging.DEBUG)
    size = _round_up_allocation_size(size)
    cdef buffer = mr.allocate(size, stream=stream)
    if not has_debug_logging:
        return buffer
    cdef intptr_t handle = int(buffer.handle)
    logger.debug(
        f"MemoryResource {mr} (allocate memory): size = {size}, "
        f"ptr = {handle}, device_id = {device_id}, "
        f"stream = {_print_stream(stream)}"
    )
    cdef str dealloc_message = (
        f"MemoryResource {mr} (release memory): size = {size}, "
        f"ptr = {handle}, device_id = {device_id}, stream = {{stream}}"
    )
    cdef _MemoryPointer mem_ptr = _MemoryPointer.__new__(_MemoryPointer)
    mem_ptr._init_from_buffer(buffer, stream, logger, dealloc_message)
    return mem_ptr


cpdef free_reserved_memory(bint sync = True):
    """
    Asks driver to free reserved unused memory from
    memory resources cached by get_device_memory_resource.
    Internally, the function calls cuMemPoolTrimTo with 0 size, which should
    release back to OS all unused memory from the current memory pool.

    Note:
    1. The function does not attempt to discover memory pools existing
    outside of the `nvmath.internal.memory` thread-local cache. In other words,
    if the calling thread never called get_device_memory_resource(device_id),
    the device's memory won't be affected by this function.
    Moreover, there may be multiple memory pools per device,
    this function will only affect the memory pool associated with the
    memory resource returned by get_device_memory_resource(device_id).

    2. The cuda memory pool underlying the resource returned with
    get_device_memory_resource(device_id) may be shared with different
    packages, so this call may affect other packages'.
    """
    for device_id, mr in enumerate(_get_local_mrs()):
        if mr is not None:
            # the driver seems to be very conservative in identifying
            # unused memory, doing a full device sync helps
            if sync:
                get_device(device_id).sync()
            _free_memory_pool_reserved_memory(mr.handle)
