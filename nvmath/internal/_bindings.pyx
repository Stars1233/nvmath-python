# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from cuda.bindings.driver import (
    CUresult,
    cuuint64_t as dr_cuuint64_t,
    cuStreamSynchronize,
    cuMemcpyAsync,
    cuMemsetD8Async,
    cuMemsetD16Async,
    cuMemsetD32Async,
    CUmemPool_attribute,
    cuMemPoolGetAttribute,
    cuMemPoolSetAttribute,
    cuMemPoolTrimTo,
    cuLaunchKernel,
    CUmemAccessDesc,
    CUmemLocationType,
    CUmemAccess_flags,
    cuMemPoolSetAccess,
)

from cuda.bindings.runtime import (
    cudaRuntimeGetVersion,
    cudaDriverGetVersion,
    cudaError_t,
)

ctypedef unsigned char uchar
ctypedef unsigned short ushort
ctypedef unsigned int uint

ctypedef fused memset_val_t:
    uchar
    ushort
    uint

class CudaError(RuntimeError):
    def __init__(self, error_code):
        self.error_code = error_code
        super().__init__(f"{CUresult(error_code).name}")


cdef inline check_driver_error(result):
    if result != CUresult.CUDA_SUCCESS:
        raise CudaError(result)


def check_runtime_error(result):
    if result != cudaError_t.cudaSuccess:
        raise CudaError(result)


def handle_return(tuple result):
    check_driver_error(result[0])
    cdef int out_len = len(result)
    if out_len == 1:
        return
    elif out_len == 2:
        return result[1]
    else:
        return result[1:]


def handle_runtime_return(tuple result):
    check_runtime_error(result[0])
    cdef int out_len = len(result)
    if out_len == 1:
        return
    elif out_len == 2:
        return result[1]
    else:
        return result[1:]


cpdef stream_sync(intptr_t stream):
    handle_return(
        cuStreamSynchronize(stream)
    )


cpdef memcpy_async(intptr_t dst_ptr, intptr_t src_ptr, int64_t size, intptr_t stream):
    handle_return(
       cuMemcpyAsync(
           dst_ptr,
           src_ptr,
           size,
           stream
       )
   )


cdef int _memset_async(intptr_t dst_ptr, memset_val_t* src_ptr, int64_t count, intptr_t stream) except -1:
    cdef memset_val_t val = src_ptr[0]
    if memset_val_t is uchar:
        handle_return(cuMemsetD8Async(dst_ptr, val, count, stream))
    elif memset_val_t is ushort:
        handle_return(cuMemsetD16Async(dst_ptr, val, count, stream))
    elif memset_val_t is uint:
        handle_return(cuMemsetD32Async(dst_ptr, val, count, stream))
    return 0


cpdef memset_async(int itemsize, intptr_t dst_ptr, intptr_t src_ptr, int64_t count, intptr_t stream):
    if itemsize == 1:
        _memset_async(dst_ptr, <uchar *>src_ptr, count, stream)
    elif itemsize == 2:
        _memset_async(dst_ptr, <ushort *>src_ptr, count, stream)
    elif itemsize == 4:
        _memset_async(dst_ptr, <uint *>src_ptr, count, stream)
    else:
        raise RuntimeError(f"cuMemset does not support itemsize {itemsize}")


cpdef uint64_t get_memory_pool_release_threshold(pool) except? -1:
    cdef ret = handle_return(
        cuMemPoolGetAttribute(
            pool, CUmemPool_attribute.CU_MEMPOOL_ATTR_RELEASE_THRESHOLD
        )
    )
    return ret


cpdef int set_memory_pool_release_threshold(pool, uint64_t threshold) except -1:
    handle_return(
        cuMemPoolSetAttribute(
            pool,
            CUmemPool_attribute.CU_MEMPOOL_ATTR_RELEASE_THRESHOLD,
            dr_cuuint64_t(threshold)
        )
    )
    return 0


cpdef uint64_t get_memory_pool_reserved_memory_size(pool) except? -1:
    cdef ret = handle_return(
        cuMemPoolGetAttribute(
            pool, CUmemPool_attribute.CU_MEMPOOL_ATTR_RESERVED_MEM_CURRENT
        )
    )
    return ret


cpdef uint64_t get_memory_pool_used_memory_size(pool) except? -1:
    cdef ret = handle_return(
        cuMemPoolGetAttribute(
            pool, CUmemPool_attribute.CU_MEMPOOL_ATTR_USED_MEM_CURRENT
        )
    )
    return ret


cpdef free_memory_pool_reserved_memory(pool):
   handle_return(
        cuMemPoolTrimTo(pool, 0)
    )


cpdef launch_kernel(intptr_t f, intptr_t kernel_params, int gx, int gy, int gz, int bx, int by, int bz, unsigned int shared_mem_bytes, intptr_t stream_handle):
    return handle_return(
        cuLaunchKernel(
            f,
            gx,
            gy,
            gz,
            bx,
            by,
            bz,
            shared_mem_bytes,
            stream_handle,
            kernel_params,
            0
        )
    )


cpdef int get_runtime_version() except? -1:
    return handle_runtime_return(
        cudaRuntimeGetVersion()
    )


cpdef int get_driver_version() except? -1:
    return handle_runtime_return(
        cudaDriverGetVersion()
    )


cpdef int set_memory_pool_access(intptr_t pool, int device_id) except -1:
    cdef object desc = CUmemAccessDesc()
    desc.location.type = CUmemLocationType.CU_MEM_LOCATION_TYPE_DEVICE
    desc.location.id = device_id
    desc.flags = CUmemAccess_flags.CU_MEM_ACCESS_FLAGS_PROT_READWRITE
    handle_return(cuMemPoolSetAccess(pool, (desc,), 1))
    return 0
