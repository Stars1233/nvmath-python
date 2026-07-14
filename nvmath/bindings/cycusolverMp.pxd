# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 0.7.2 to 0.8.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.
# This layer exposes the C header to Cython as-is.

from libc.stdint cimport int32_t, int64_t, uint32_t, uint64_t, intptr_t
from libc.stdio cimport FILE

from .cycusolver cimport *
from ._internal.common_types cimport cudaEmulationStrategy_t

###############################################################################
# Types (structs, enums, ...)
###############################################################################

# enums
ctypedef enum cusolverMpGridMapping_t "cusolverMpGridMapping_t":
    CUSOLVERMP_GRID_MAPPING_ROW_MAJOR "CUSOLVERMP_GRID_MAPPING_ROW_MAJOR" = 1
    CUSOLVERMP_GRID_MAPPING_COL_MAJOR "CUSOLVERMP_GRID_MAPPING_COL_MAJOR" = 0

ctypedef enum cusolverMpNewtonSchulzDescriptorAttribute_t "cusolverMpNewtonSchulzDescriptorAttribute_t":
    CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_NORMALIZE "CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_NORMALIZE" = 0
    CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_REDUCE_VIA_COMPUTE_TYPE "CUSOLVERMP_NEWTON_SCHULZ_DESCRIPTOR_ATTRIBUTE_REDUCE_VIA_COMPUTE_TYPE" = 1


# types
ctypedef void* ncclComm_t 'ncclComm_t'

ctypedef void* cusolverMpGrid_t 'cusolverMpGrid_t'

ctypedef void* cusolverMpMatrixDescriptor_t 'cusolverMpMatrixDescriptor_t'

ctypedef void* cusolverMpHandle_t 'cusolverMpHandle_t'

ctypedef void* cusolverMpNewtonSchulzDescriptor_t 'cusolverMpNewtonSchulzDescriptor_t'

ctypedef void (*cusolverMpLoggerCallback_t 'cusolverMpLoggerCallback_t')(
    int logLevel,
    const char* functionName,
    const char* message
)


###############################################################################
# Functions
###############################################################################

cdef cusolverStatus_t cusolverMpCreate(cusolverMpHandle_t* handle, int deviceId, cudaStream_t stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpDestroy(cusolverMpHandle_t handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetStream(cusolverMpHandle_t handle, cudaStream_t* stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetVersion(cusolverMpHandle_t handle, int* version) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpCreateDeviceGrid(cusolverMpHandle_t handle, cusolverMpGrid_t* grid, const ncclComm_t comm, int32_t numRowDevices, int32_t numColDevices, const cusolverMpGridMapping_t mapping) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpDestroyGrid(cusolverMpGrid_t grid) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpCreateMatrixDesc(cusolverMpMatrixDescriptor_t* desc, cusolverMpGrid_t grid, cudaDataType dataType, int64_t M_A, int64_t N_A, int64_t MB_A, int64_t NB_A, uint32_t RSRC_A, uint32_t CSRC_A, int64_t LLD_A) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpDestroyMatrixDesc(cusolverMpMatrixDescriptor_t desc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef int64_t cusolverMpNUMROC(int64_t n, int64_t nb, uint32_t iproc, uint32_t isrcproc, uint32_t nprocs) except?-42 nogil
cdef cusolverStatus_t cusolverMpMatrixScatterH2D(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int root, const void* h_src, int64_t h_ldsrc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpMatrixGatherD2H(cusolverMpHandle_t handle, int64_t M, int64_t N, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int root, void* h_dst, int64_t h_lddst) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetrf_bufferSize(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int64_t* d_ipiv, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetrf(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int64_t* d_ipiv, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetrs_bufferSize(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t N, int64_t NRHS, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, const int64_t* d_ipiv, void* d_B, int64_t IB, int64_t JB, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetrs(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t N, int64_t NRHS, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, const int64_t* d_ipiv, void* d_B, int64_t IB, int64_t JB, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpPotrf_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpPotrf(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpPotrs_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, int64_t nrhs, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpPotrs(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, int64_t nrhs, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrmqr_bufferSize(cusolverMpHandle_t handle, cublasSideMode_t side, cublasOperation_t trans, int64_t m, int64_t n, int64_t k, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrmqr(cusolverMpHandle_t handle, cublasSideMode_t side, cublasOperation_t trans, int64_t m, int64_t n, int64_t k, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrmtr_bufferSize(cusolverMpHandle_t handle, cublasSideMode_t side, cublasFillMode_t uplo, cublasOperation_t trans, int64_t m, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrmtr(cusolverMpHandle_t handle, cublasSideMode_t side, cublasFillMode_t uplo, cublasOperation_t trans, int64_t m, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGels_bufferSize(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t m, int64_t n, int64_t nrhs, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGels(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t m, int64_t n, int64_t nrhs, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpStedc_bufferSize(cusolverMpHandle_t handle, char* compz, int64_t N, void* d_D, void* d_E, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost, int* iwork) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpStedc(cusolverMpHandle_t handle, char* compz, int64_t N, void* d_D, void* d_E, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGeqrf_bufferSize(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGeqrf(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_tau, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSytrd_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_E, void* d_TAU, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSytrd(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_E, void* d_TAU, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSyevd_bufferSize(cusolverMpHandle_t handle, char* compz, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSyevd(cusolverMpHandle_t handle, char* compz, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSygst_bufferSize(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cublasFillMode_t uplo, int64_t m, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSygst(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cublasFillMode_t uplo, int64_t m, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSygvd_bufferSize(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cusolverEigMode_t jobz, cublasFillMode_t uplo, int64_t m, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, int64_t iz, int64_t jz, cusolverMpMatrixDescriptor_t descZ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSygvd(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cusolverEigMode_t jobz, cublasFillMode_t uplo, int64_t m, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, void* w, void* z, int64_t iz, int64_t jz, cusolverMpMatrixDescriptor_t descZ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLoggerSetFile(FILE* file) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLoggerOpenFile(const char* logFile) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLoggerSetLevel(int level) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLoggerSetMask(int mask) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLoggerForceDisable() except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSetMathMode(cusolverMpHandle_t handle, cusolverMathMode_t mode) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetMathMode(cusolverMpHandle_t handle, cusolverMathMode_t* mode) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSetEmulationStrategy(cusolverMpHandle_t handle, cudaEmulationStrategy_t strategy) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpGetEmulationStrategy(cusolverMpHandle_t handle, cudaEmulationStrategy_t* strategy) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulzDescriptorCreate(cusolverMpNewtonSchulzDescriptor_t* nsDesc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulzDescriptorDestroy(cusolverMpNewtonSchulzDescriptor_t nsDesc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulzDescriptorSetAttribute(cusolverMpNewtonSchulzDescriptor_t nsDesc, cusolverMpNewtonSchulzDescriptorAttribute_t attr, const void* buf, size_t sizeInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulzDescriptorGetAttribute(cusolverMpNewtonSchulzDescriptor_t nsDesc, cusolverMpNewtonSchulzDescriptorAttribute_t attr, void* buf, size_t sizeInBytes, size_t* sizeInBytesWritten) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpSetStream(cusolverMpHandle_t handle, cudaStream_t stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpBufferRegister(cusolverMpGrid_t grid, void* ptr, size_t size) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpBufferDeregister(cusolverMpGrid_t grid, void* ptr) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrgqr_bufferSize(cusolverMpHandle_t handle, int64_t m, int64_t n, int64_t k, const void* d_A, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* d_tau, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpOrgqr(cusolverMpHandle_t handle, int64_t m, int64_t n, int64_t k, void* d_A, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* d_tau, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpLaset(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t M, int64_t N, const void* alpha, const void* beta, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulz_bufferSize(cusolverMpHandle_t handle, cusolverMpNewtonSchulzDescriptor_t nsDesc, const int64_t m, const int64_t n, void* d_x, const int64_t ix, const int64_t jx, const cusolverMpMatrixDescriptor_t descX, const int64_t numberOfNewtonSchulzIterations, const void* h_coeffs, const cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cusolverStatus_t cusolverMpNewtonSchulz(cusolverMpHandle_t handle, cusolverMpNewtonSchulzDescriptor_t nsDesc, const int64_t m, const int64_t n, void* d_x, const int64_t ix, const int64_t jx, const cusolverMpMatrixDescriptor_t descX, const int64_t numberOfNewtonSchulzIterations, const void* h_coeffs, const cudaDataType_t computeType, void* d_work, const size_t workspaceInBytesOnDevice, void* h_work, const size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil
