# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 0.7.2 to 0.8.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

cimport cython  # NOQA
from libc.stdint cimport int64_t
from libcpp.vector cimport vector

from .cusolver import Status
from enum import IntEnum as _IntEnum

import numpy as _numpy

###############################################################################
# Enum
###############################################################################

class GridMapping(_IntEnum):
    """
    See `cusolverMpGridMapping_t`.
    """
    ROW_MAJOR = CUSOLVERMP_GRID_MAPPING_ROW_MAJOR
    COL_MAJOR = CUSOLVERMP_GRID_MAPPING_COL_MAJOR

class NewtonSchulzDescriptorAttribute(_IntEnum):
    """
    See `cusolverMpNewtonSchulzDescriptorAttribute_t`.
    """
    NORMALIZE = CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_NORMALIZE
    REDUCE_VIA_COMPUTE_TYPE = CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_REDUCE_VIA_COMPUTE_TYPE

###############################################################################
# Error handling
###############################################################################

class cuSOLVERMpError(Exception):

    def __init__(self, status):
        self.status = status
        s = Status(status)
        cdef str err = (
            f"{s.name} ({s.value}). You can set CUSOLVERMP_LOG_LEVEL=5 "
            "and CUSOLVERDN_LOG_LEVEL=5 environment variables to enable logging to learn more."
        )
        super(cuSOLVERMpError, self).__init__(err)

    def __reduce__(self):
        return (type(self), (self.status,))


@cython.profile(False)
cpdef inline check_status(int status):
    if status != 0:
        raise cuSOLVERMpError(status)


###############################################################################
# Wrapper functions
###############################################################################

cpdef intptr_t create(int device_id, intptr_t stream) except? 0:
    """See `cusolverMpCreate`."""
    cdef Handle handle
    with nogil:
        __status__ = cusolverMpCreate(&handle, device_id, <Stream>stream)
    check_status(__status__)
    return <intptr_t>handle


cpdef destroy(intptr_t handle):
    """See `cusolverMpDestroy`."""
    with nogil:
        __status__ = cusolverMpDestroy(<Handle>handle)
    check_status(__status__)


cpdef intptr_t get_stream(intptr_t handle) except? 0:
    """See `cusolverMpGetStream`."""
    cdef Stream stream
    with nogil:
        __status__ = cusolverMpGetStream(<Handle>handle, &stream)
    check_status(__status__)
    return <intptr_t>stream


cpdef int get_version(intptr_t handle) except? 0:
    """See `cusolverMpGetVersion`."""
    cdef int version
    with nogil:
        __status__ = cusolverMpGetVersion(<Handle>handle, &version)
    check_status(__status__)
    return version


cpdef intptr_t create_device_grid(intptr_t handle, intptr_t comm, int32_t num_row_devices, int32_t num_col_devices, int mapping) except? 0:
    """See `cusolverMpCreateDeviceGrid`."""
    cdef Grid grid
    with nogil:
        __status__ = cusolverMpCreateDeviceGrid(<Handle>handle, &grid, <const ncclComm>comm, num_row_devices, num_col_devices, <const _GridMapping>mapping)
    check_status(__status__)
    return <intptr_t>grid


cpdef destroy_grid(intptr_t grid):
    """See `cusolverMpDestroyGrid`."""
    with nogil:
        __status__ = cusolverMpDestroyGrid(<Grid>grid)
    check_status(__status__)


cpdef intptr_t create_matrix_desc(intptr_t grid, int data_type, int64_t m_a, int64_t n_a, int64_t mb_a, int64_t nb_a, uint32_t rsrc_a, uint32_t csrc_a, int64_t lld_a) except? 0:
    """See `cusolverMpCreateMatrixDesc`."""
    cdef MatrixDescriptor desc
    with nogil:
        __status__ = cusolverMpCreateMatrixDesc(&desc, <Grid>grid, <DataType>data_type, m_a, n_a, mb_a, nb_a, rsrc_a, csrc_a, lld_a)
    check_status(__status__)
    return <intptr_t>desc


cpdef destroy_matrix_desc(intptr_t desc):
    """See `cusolverMpDestroyMatrixDesc`."""
    with nogil:
        __status__ = cusolverMpDestroyMatrixDesc(<MatrixDescriptor>desc)
    check_status(__status__)


cpdef int64_t numroc(int64_t n, int64_t nb, uint32_t iproc, uint32_t isrcproc, uint32_t nprocs) except? -1:
    """See `cusolverMpNUMROC`."""
    return cusolverMpNUMROC(n, nb, iproc, isrcproc, nprocs)


cpdef matrix_scatter_h2d(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int root, intptr_t h_src, int64_t h_ldsrc):
    """See `cusolverMpMatrixScatterH2D`."""
    with nogil:
        __status__ = cusolverMpMatrixScatterH2D(<Handle>handle, m, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, root, <const void*>h_src, h_ldsrc)
    check_status(__status__)


cpdef matrix_gather_d2h(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int root, intptr_t h_dst, int64_t h_lddst):
    """See `cusolverMpMatrixGatherD2H`."""
    with nogil:
        __status__ = cusolverMpMatrixGatherD2H(<Handle>handle, m, n, <const void*>d_a, ia, ja, <MatrixDescriptor>desc_a, root, <void*>h_dst, h_lddst)
    check_status(__status__)


cpdef tuple getrf_buffer_size(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, int compute_type):
    """See `cusolverMpGetrf_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpGetrf_bufferSize(<Handle>handle, m, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <int64_t*>d_ipiv, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef getrf(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpGetrf`."""
    with nogil:
        __status__ = cusolverMpGetrf(<Handle>handle, m, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <int64_t*>d_ipiv, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple getrs_buffer_size(intptr_t handle, int trans, int64_t n, int64_t nrhs, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, intptr_t d_b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type):
    """See `cusolverMpGetrs_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpGetrs_bufferSize(<Handle>handle, <cublasOperation_t>trans, n, nrhs, <const void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <const int64_t*>d_ipiv, <void*>d_b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef getrs(intptr_t handle, int trans, int64_t n, int64_t nrhs, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, intptr_t d_b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info):
    """See `cusolverMpGetrs`."""
    with nogil:
        __status__ = cusolverMpGetrs(<Handle>handle, <cublasOperation_t>trans, n, nrhs, <const void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <const int64_t*>d_ipiv, <void*>d_b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>d_info)
    check_status(__status__)


cpdef tuple potrf_buffer_size(intptr_t handle, int uplo, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type):
    """See `cusolverMpPotrf_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpPotrf_bufferSize(<Handle>handle, <cublasFillMode_t>uplo, n, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef potrf(intptr_t handle, int uplo, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpPotrf`."""
    with nogil:
        __status__ = cusolverMpPotrf(<Handle>handle, <cublasFillMode_t>uplo, n, <void*>a, ia, ja, <MatrixDescriptor>desc_a, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple potrs_buffer_size(intptr_t handle, int uplo, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type):
    """See `cusolverMpPotrs_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpPotrs_bufferSize(<Handle>handle, <cublasFillMode_t>uplo, n, nrhs, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef potrs(intptr_t handle, int uplo, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpPotrs`."""
    with nogil:
        __status__ = cusolverMpPotrs(<Handle>handle, <cublasFillMode_t>uplo, n, nrhs, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <void*>b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple ormqr_buffer_size(intptr_t handle, int side, int trans, int64_t m, int64_t n, int64_t k, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type):
    """See `cusolverMpOrmqr_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpOrmqr_bufferSize(<Handle>handle, <cublasSideMode_t>side, <cublasOperation_t>trans, m, n, k, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>tau, <void*>c, ic, jc, <MatrixDescriptor>desc_c, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef ormqr(intptr_t handle, int side, int trans, int64_t m, int64_t n, int64_t k, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpOrmqr`."""
    with nogil:
        __status__ = cusolverMpOrmqr(<Handle>handle, <cublasSideMode_t>side, <cublasOperation_t>trans, m, n, k, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>tau, <void*>c, ic, jc, <MatrixDescriptor>desc_c, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple ormtr_buffer_size(intptr_t handle, int side, int uplo, int trans, int64_t m, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type):
    """See `cusolverMpOrmtr_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpOrmtr_bufferSize(<Handle>handle, <cublasSideMode_t>side, <cublasFillMode_t>uplo, <cublasOperation_t>trans, m, n, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>tau, <void*>c, ic, jc, <MatrixDescriptor>desc_c, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef ormtr(intptr_t handle, int side, int uplo, int trans, int64_t m, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpOrmtr`."""
    with nogil:
        __status__ = cusolverMpOrmtr(<Handle>handle, <cublasSideMode_t>side, <cublasFillMode_t>uplo, <cublasOperation_t>trans, m, n, <const void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>tau, <void*>c, ic, jc, <MatrixDescriptor>desc_c, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple gels_buffer_size(intptr_t handle, int trans, int64_t m, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type):
    """See `cusolverMpGels_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpGels_bufferSize(<Handle>handle, <cublasOperation_t>trans, m, n, nrhs, <void*>a, ia, ja, <MatrixDescriptor>desc_a, <void*>b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef gels(intptr_t handle, int trans, int64_t m, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpGels`."""
    with nogil:
        __status__ = cusolverMpGels(<Handle>handle, <cublasOperation_t>trans, m, n, nrhs, <void*>a, ia, ja, <MatrixDescriptor>desc_a, <void*>b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple stedc_buffer_size(intptr_t handle, intptr_t compz, int64_t n, intptr_t d_d, intptr_t d_e, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t iwork):
    """See `cusolverMpStedc_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpStedc_bufferSize(<Handle>handle, <char*>compz, n, <void*>d_d, <void*>d_e, <void*>d_q, iq, jq, <MatrixDescriptor>desc_q, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host, <int*>iwork)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef stedc(intptr_t handle, intptr_t compz, int64_t n, intptr_t d_d, intptr_t d_e, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpStedc`."""
    with nogil:
        __status__ = cusolverMpStedc(<Handle>handle, <char*>compz, n, <void*>d_d, <void*>d_e, <void*>d_q, iq, jq, <MatrixDescriptor>desc_q, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple geqrf_buffer_size(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type):
    """See `cusolverMpGeqrf_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpGeqrf_bufferSize(<Handle>handle, m, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef geqrf(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpGeqrf`."""
    with nogil:
        __status__ = cusolverMpGeqrf(<Handle>handle, m, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <void*>d_tau, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple sytrd_buffer_size(intptr_t handle, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_e, intptr_t d_tau, int compute_type):
    """See `cusolverMpSytrd_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpSytrd_bufferSize(<Handle>handle, <cublasFillMode_t>uplo, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <void*>d_d, <void*>d_e, <void*>d_tau, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef sytrd(intptr_t handle, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_e, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpSytrd`."""
    with nogil:
        __status__ = cusolverMpSytrd(<Handle>handle, <cublasFillMode_t>uplo, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <void*>d_d, <void*>d_e, <void*>d_tau, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple syevd_buffer_size(intptr_t handle, intptr_t compz, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type):
    """See `cusolverMpSyevd_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpSyevd_bufferSize(<Handle>handle, <char*>compz, <cublasFillMode_t>uplo, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <void*>d_d, <void*>d_q, iq, jq, <MatrixDescriptor>desc_q, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef syevd(intptr_t handle, intptr_t compz, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info):
    """See `cusolverMpSyevd`."""
    with nogil:
        __status__ = cusolverMpSyevd(<Handle>handle, <char*>compz, <cublasFillMode_t>uplo, n, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <void*>d_d, <void*>d_q, iq, jq, <MatrixDescriptor>desc_q, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>d_info)
    check_status(__status__)


cpdef tuple sygst_buffer_size(intptr_t handle, int ibtype, int uplo, int64_t m, int64_t ia, int64_t ja, intptr_t desc_a, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type):
    """See `cusolverMpSygst_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpSygst_bufferSize(<Handle>handle, <cusolverEigType_t>ibtype, <cublasFillMode_t>uplo, m, ia, ja, <MatrixDescriptor>desc_a, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef sygst(intptr_t handle, int ibtype, int uplo, int64_t m, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpSygst`."""
    with nogil:
        __status__ = cusolverMpSygst(<Handle>handle, <cusolverEigType_t>ibtype, <cublasFillMode_t>uplo, m, <void*>a, ia, ja, <MatrixDescriptor>desc_a, <const void*>b, ib, jb, <MatrixDescriptor>desc_b, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef tuple sygvd_buffer_size(intptr_t handle, int ibtype, int jobz, int uplo, int64_t m, int64_t ia, int64_t ja, intptr_t desc_a, int64_t ib, int64_t jb, intptr_t desc_b, int64_t iz, int64_t jz, intptr_t desc_z, int compute_type):
    """See `cusolverMpSygvd_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpSygvd_bufferSize(<Handle>handle, <cusolverEigType_t>ibtype, <cusolverEigMode_t>jobz, <cublasFillMode_t>uplo, m, ia, ja, <MatrixDescriptor>desc_a, ib, jb, <MatrixDescriptor>desc_b, iz, jz, <MatrixDescriptor>desc_z, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef sygvd(intptr_t handle, int ibtype, int jobz, int uplo, int64_t m, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, intptr_t w, intptr_t z, int64_t iz, int64_t jz, intptr_t desc_z, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpSygvd`."""
    with nogil:
        __status__ = cusolverMpSygvd(<Handle>handle, <cusolverEigType_t>ibtype, <cusolverEigMode_t>jobz, <cublasFillMode_t>uplo, m, <void*>a, ia, ja, <MatrixDescriptor>desc_a, <void*>b, ib, jb, <MatrixDescriptor>desc_b, <void*>w, <void*>z, iz, jz, <MatrixDescriptor>desc_z, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)


cpdef logger_set_file(intptr_t file):
    """See `cusolverMpLoggerSetFile`."""
    with nogil:
        __status__ = cusolverMpLoggerSetFile(<FILE*>file)
    check_status(__status__)


cpdef logger_open_file(intptr_t log_file):
    """See `cusolverMpLoggerOpenFile`."""
    with nogil:
        __status__ = cusolverMpLoggerOpenFile(<const char*>log_file)
    check_status(__status__)


cpdef logger_set_level(int level):
    """See `cusolverMpLoggerSetLevel`."""
    with nogil:
        __status__ = cusolverMpLoggerSetLevel(level)
    check_status(__status__)


cpdef logger_set_mask(int mask):
    """See `cusolverMpLoggerSetMask`."""
    with nogil:
        __status__ = cusolverMpLoggerSetMask(mask)
    check_status(__status__)


cpdef logger_force_disable():
    """See `cusolverMpLoggerForceDisable`."""
    with nogil:
        __status__ = cusolverMpLoggerForceDisable()
    check_status(__status__)


cpdef set_math_mode(intptr_t handle, int mode):
    """See `cusolverMpSetMathMode`."""
    with nogil:
        __status__ = cusolverMpSetMathMode(<Handle>handle, <cusolverMathMode_t>mode)
    check_status(__status__)


cpdef int get_math_mode(intptr_t handle) except? -1:
    """See `cusolverMpGetMathMode`."""
    cdef cusolverMathMode_t mode
    with nogil:
        __status__ = cusolverMpGetMathMode(<Handle>handle, &mode)
    check_status(__status__)
    return <int>mode


cpdef set_emulation_strategy(intptr_t handle, int strategy):
    """See `cusolverMpSetEmulationStrategy`."""
    with nogil:
        __status__ = cusolverMpSetEmulationStrategy(<Handle>handle, <cudaEmulationStrategy_t>strategy)
    check_status(__status__)


cpdef int get_emulation_strategy(intptr_t handle) except? -1:
    """See `cusolverMpGetEmulationStrategy`."""
    cdef cudaEmulationStrategy_t strategy
    with nogil:
        __status__ = cusolverMpGetEmulationStrategy(<Handle>handle, &strategy)
    check_status(__status__)
    return <int>strategy


cpdef intptr_t newton_schulz_descriptor_create() except? 0:
    """See `cusolverMpNewtonSchulzDescriptorCreate`."""
    cdef NewtonSchulzDescriptor ns_desc
    with nogil:
        __status__ = cusolverMpNewtonSchulzDescriptorCreate(&ns_desc)
    check_status(__status__)
    return <intptr_t>ns_desc


cpdef newton_schulz_descriptor_destroy(intptr_t ns_desc):
    """See `cusolverMpNewtonSchulzDescriptorDestroy`."""
    with nogil:
        __status__ = cusolverMpNewtonSchulzDescriptorDestroy(<NewtonSchulzDescriptor>ns_desc)
    check_status(__status__)


######################### Python specific utility #########################

cdef dict newton_schulz_descriptor_attribute_sizes = {
    CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_NORMALIZE: _numpy.int32,
    CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_REDUCE_VIA_COMPUTE_TYPE: _numpy.int32,
}

cpdef get_newton_schulz_descriptor_attribute_dtype(int attr):
    """Get the Python data type of the corresponding NewtonSchulzDescriptorAttribute attribute.

    Args:
        attr (NewtonSchulzDescriptorAttribute): The attribute to query.

    Returns:
        The data type of the queried attribute.

    .. note:: This API has no C counterpart and is a convenient helper for
        allocating memory for :func:`newton_schulz_descriptor_get_attribute`, :func:`newton_schulz_descriptor_set_attribute`.
    """
    return newton_schulz_descriptor_attribute_sizes[attr]

###########################################################################

cpdef newton_schulz_descriptor_set_attribute(intptr_t ns_desc, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cusolverMpNewtonSchulzDescriptorSetAttribute`."""
    with nogil:
        __status__ = cusolverMpNewtonSchulzDescriptorSetAttribute(<NewtonSchulzDescriptor>ns_desc, <_NewtonSchulzDescriptorAttribute>attr, <const void*>buf, size_in_bytes)
    check_status(__status__)


cpdef newton_schulz_descriptor_get_attribute(intptr_t ns_desc, int attr, intptr_t buf, size_t size_in_bytes, intptr_t size_in_bytes_written):
    """See `cusolverMpNewtonSchulzDescriptorGetAttribute`."""
    with nogil:
        __status__ = cusolverMpNewtonSchulzDescriptorGetAttribute(<NewtonSchulzDescriptor>ns_desc, <_NewtonSchulzDescriptorAttribute>attr, <void*>buf, size_in_bytes, <size_t*>size_in_bytes_written)
    check_status(__status__)


cpdef set_stream(intptr_t handle, intptr_t stream):
    """See `cusolverMpSetStream`."""
    with nogil:
        __status__ = cusolverMpSetStream(<Handle>handle, <Stream>stream)
    check_status(__status__)


cpdef buffer_register(intptr_t grid, intptr_t ptr, size_t size):
    """See `cusolverMpBufferRegister`."""
    with nogil:
        __status__ = cusolverMpBufferRegister(<Grid>grid, <void*>ptr, size)
    check_status(__status__)


cpdef buffer_deregister(intptr_t grid, intptr_t ptr):
    """See `cusolverMpBufferDeregister`."""
    with nogil:
        __status__ = cusolverMpBufferDeregister(<Grid>grid, <void*>ptr)
    check_status(__status__)


cpdef tuple orgqr_buffer_size(intptr_t handle, int64_t m, int64_t n, int64_t k, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type):
    """See `cusolverMpOrgqr_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpOrgqr_bufferSize(<Handle>handle, m, n, k, <const void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <const void*>d_tau, <DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef orgqr(intptr_t handle, int64_t m, int64_t n, int64_t k, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info):
    """See `cusolverMpOrgqr`."""
    with nogil:
        __status__ = cusolverMpOrgqr(<Handle>handle, m, n, k, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <const void*>d_tau, <DataType>compute_type, <void*>d_work, workspace_in_bytes_on_device, <void*>h_work, workspace_in_bytes_on_host, <int*>d_info)
    check_status(__status__)


cpdef laset(intptr_t handle, int uplo, int64_t m, int64_t n, intptr_t alpha, intptr_t beta, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_info):
    """See `cusolverMpLaset`."""
    with nogil:
        __status__ = cusolverMpLaset(<Handle>handle, <cublasFillMode_t>uplo, m, n, <const void*>alpha, <const void*>beta, <void*>d_a, ia, ja, <MatrixDescriptor>desc_a, <int*>d_info)
    check_status(__status__)


cpdef tuple newton_schulz_buffer_size(intptr_t handle, intptr_t ns_desc, int64_t m, int64_t n, intptr_t d_x, int64_t ix, int64_t jx, intptr_t desc_x, int64_t number_of_newton_schulz_iterations, intptr_t h_coeffs, int compute_type):
    """See `cusolverMpNewtonSchulz_bufferSize`."""
    cdef size_t workspace_in_bytes_on_device
    cdef size_t workspace_in_bytes_on_host
    with nogil:
        __status__ = cusolverMpNewtonSchulz_bufferSize(<Handle>handle, <NewtonSchulzDescriptor>ns_desc, <const int64_t>m, <const int64_t>n, <void*>d_x, <const int64_t>ix, <const int64_t>jx, <const MatrixDescriptor>desc_x, <const int64_t>number_of_newton_schulz_iterations, <const void*>h_coeffs, <const DataType>compute_type, &workspace_in_bytes_on_device, &workspace_in_bytes_on_host)
    check_status(__status__)
    return (workspace_in_bytes_on_device, workspace_in_bytes_on_host)


cpdef newton_schulz(intptr_t handle, intptr_t ns_desc, int64_t m, int64_t n, intptr_t d_x, int64_t ix, int64_t jx, intptr_t desc_x, int64_t number_of_newton_schulz_iterations, intptr_t h_coeffs, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info):
    """See `cusolverMpNewtonSchulz`."""
    with nogil:
        __status__ = cusolverMpNewtonSchulz(<Handle>handle, <NewtonSchulzDescriptor>ns_desc, <const int64_t>m, <const int64_t>n, <void*>d_x, <const int64_t>ix, <const int64_t>jx, <const MatrixDescriptor>desc_x, <const int64_t>number_of_newton_schulz_iterations, <const void*>h_coeffs, <const DataType>compute_type, <void*>d_work, <const size_t>workspace_in_bytes_on_device, <void*>h_work, <const size_t>workspace_in_bytes_on_host, <int*>info)
    check_status(__status__)
