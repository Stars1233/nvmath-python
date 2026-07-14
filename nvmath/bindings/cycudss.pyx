# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated with version 0.8.0, generator version 0.3.1.dev1725+g07a86fe3d.d20260603. Do not modify it directly.

from ._internal cimport cudss as _cudss


###############################################################################
# Wrapper functions
###############################################################################

cdef cudssStatus_t cudssConfigSet(cudssConfig_t config, cudssConfigParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssConfigSet(config, param, value, sizeInBytes)


cdef cudssStatus_t cudssConfigGet(const cudssConfig_t config, cudssConfigParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssConfigGet(config, param, value, sizeInBytes, sizeWritten)


cdef cudssStatus_t cudssDataSet(const cudssHandle_t handle, cudssData_t data, cudssDataParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssDataSet(handle, data, param, value, sizeInBytes)


cdef cudssStatus_t cudssDataGet(const cudssHandle_t handle, const cudssData_t data, cudssDataParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssDataGet(handle, data, param, value, sizeInBytes, sizeWritten)


cdef cudssStatus_t cudssExecute(cudssHandle_t handle, int phase, const cudssConfig_t solverConfig, cudssData_t solverData, const cudssMatrix_t inputMatrix, cudssMatrix_t solution, const cudssMatrix_t rhs) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssExecute(handle, phase, solverConfig, solverData, inputMatrix, solution, rhs)


cdef cudssStatus_t cudssSetStream(cudssHandle_t handle, cudaStream_t stream) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssSetStream(handle, stream)


cdef cudssStatus_t cudssSetMgStreams(cudssHandle_t handle, const cudaStream_t* streams, int stream_count) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssSetMgStreams(handle, streams, stream_count)


cdef cudssStatus_t cudssSetCommLayer(cudssHandle_t handle, const char* commLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssSetCommLayer(handle, commLibFileName)


cdef cudssStatus_t cudssSetThreadingLayer(cudssHandle_t handle, const char* thrLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssSetThreadingLayer(handle, thrLibFileName)


cdef cudssStatus_t cudssConfigCreate(cudssConfig_t* solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssConfigCreate(solverConfig)


cdef cudssStatus_t cudssConfigDestroy(cudssConfig_t solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssConfigDestroy(solverConfig)


cdef cudssStatus_t cudssDataCreate(const cudssHandle_t handle, cudssData_t* solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssDataCreate(handle, solverData)


cdef cudssStatus_t cudssDataDestroy(cudssHandle_t handle, cudssData_t solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssDataDestroy(handle, solverData)


cdef cudssStatus_t cudssCreate(cudssHandle_t* handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssCreate(handle)


cdef cudssStatus_t cudssCreateMg(cudssHandle_t* handle_pt, int device_count, const int* device_indices) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssCreateMg(handle_pt, device_count, device_indices)


cdef cudssStatus_t cudssDestroy(cudssHandle_t handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssDestroy(handle)


cdef cudssStatus_t cudssGetProperty(libraryPropertyType propertyType, int* value) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssGetProperty(propertyType, value)


cdef cudssStatus_t cudssMatrixCreateDn(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t ld, const void* values, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixCreateDn(matrix, nrows, ncols, ld, values, valueType, layout)


cdef cudssStatus_t cudssMatrixCreateCsr(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t nnz, const void* rowStart, const void* rowEnd, const void* colIndices, const void* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixCreateCsr(matrix, nrows, ncols, nnz, rowStart, rowEnd, colIndices, values, offsetType, indexType, valueType, mtype, mview, indexBase)


cdef cudssStatus_t cudssMatrixCreateBatchDn(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* ld, const void* const* values, cudssDataType_t integerType, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixCreateBatchDn(matrix, batchCount, nrows, ncols, ld, values, integerType, valueType, layout)


cdef cudssStatus_t cudssMatrixCreateBatchCsr(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* nnz, const void* const* rowStart, const void* const* rowEnd, const void* const* colIndices, const void* const* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixCreateBatchCsr(matrix, batchCount, nrows, ncols, nnz, rowStart, rowEnd, colIndices, values, offsetType, indexType, valueType, mtype, mview, indexBase)


cdef cudssStatus_t cudssMatrixDestroy(cudssMatrix_t matrix) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixDestroy(matrix)


cdef cudssStatus_t cudssMatrixGetDn(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* ld, void** values, cudssDataType_t* type, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetDn(matrix, nrows, ncols, ld, values, type, layout)


cdef cudssStatus_t cudssMatrixGetCsr(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* nnz, void** rowStart, void** rowEnd, void** colIndices, void** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetCsr(matrix, nrows, ncols, nnz, rowStart, rowEnd, colIndices, values, offsetType, indexType, valueType, mtype, mview, indexBase)


cdef cudssStatus_t cudssMatrixSetValues(cudssMatrix_t matrix, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixSetValues(matrix, values)


cdef cudssStatus_t cudssMatrixSetCsrPointers(cudssMatrix_t matrix, const void* rowOffsets, const void* rowEnd, const void* colIndices, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixSetCsrPointers(matrix, rowOffsets, rowEnd, colIndices, values)


cdef cudssStatus_t cudssMatrixGetBatchDn(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** ld, void*** values, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetBatchDn(matrix, batchCount, nrows, ncols, ld, values, indexType, valueType, layout)


cdef cudssStatus_t cudssMatrixGetBatchCsr(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** nnz, void*** rowStart, void*** rowEnd, void*** colIndices, void*** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetBatchCsr(matrix, batchCount, nrows, ncols, nnz, rowStart, rowEnd, colIndices, values, offsetType, indexType, valueType, mtype, mview, indexBase)


cdef cudssStatus_t cudssMatrixSetBatchValues(cudssMatrix_t matrix, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixSetBatchValues(matrix, values)


cdef cudssStatus_t cudssMatrixSetBatchCsrPointers(cudssMatrix_t matrix, const void* const* rowOffsets, const void* const* rowEnd, const void* const* colIndices, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixSetBatchCsrPointers(matrix, rowOffsets, rowEnd, colIndices, values)


cdef cudssStatus_t cudssMatrixGetFormat(const cudssMatrix_t matrix, int* format) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetFormat(matrix, format)


cdef cudssStatus_t cudssMatrixSetDistributionRow1d(cudssMatrix_t matrix, int64_t first_row, int64_t last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixSetDistributionRow1d(matrix, first_row, last_row)


cdef cudssStatus_t cudssMatrixGetDistributionRow1d(const cudssMatrix_t matrix, int64_t* first_row, int64_t* last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssMatrixGetDistributionRow1d(matrix, first_row, last_row)


cdef cudssStatus_t cudssGetDeviceMemHandler(const cudssHandle_t handle, cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssGetDeviceMemHandler(handle, handler)


cdef cudssStatus_t cudssSetDeviceMemHandler(cudssHandle_t handle, const cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssSetDeviceMemHandler(handle, handler)


cdef cudssStatus_t cudssLoggerSetCallback(cudssLoggerCallback_t callback) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerSetCallback(callback)


cdef cudssStatus_t cudssLoggerSetFile(FILE* file) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerSetFile(file)


cdef cudssStatus_t cudssLoggerOpenFile(const char* logFile) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerOpenFile(logFile)


cdef cudssStatus_t cudssLoggerSetLevel(int level) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerSetLevel(level)


cdef cudssStatus_t cudssLoggerSetMask(int mask) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerSetMask(mask)


cdef cudssStatus_t cudssLoggerForceDisable() except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cudss._cudssLoggerForceDisable()
