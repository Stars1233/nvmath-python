# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated with version 0.8.0, generator version 0.3.1.dev1725+g07a86fe3d.d20260603. Do not modify it directly.

from ..cycudss cimport *


###############################################################################
# Wrapper functions
###############################################################################

cdef cudssStatus_t _cudssConfigSet(cudssConfig_t config, cudssConfigParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssConfigGet(const cudssConfig_t config, cudssConfigParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssDataSet(const cudssHandle_t handle, cudssData_t data, cudssDataParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssDataGet(const cudssHandle_t handle, const cudssData_t data, cudssDataParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssExecute(cudssHandle_t handle, int phase, const cudssConfig_t solverConfig, cudssData_t solverData, const cudssMatrix_t inputMatrix, cudssMatrix_t solution, const cudssMatrix_t rhs) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssSetStream(cudssHandle_t handle, cudaStream_t stream) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssSetMgStreams(cudssHandle_t handle, const cudaStream_t* streams, int stream_count) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssSetCommLayer(cudssHandle_t handle, const char* commLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssSetThreadingLayer(cudssHandle_t handle, const char* thrLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssConfigCreate(cudssConfig_t* solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssConfigDestroy(cudssConfig_t solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssDataCreate(const cudssHandle_t handle, cudssData_t* solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssDataDestroy(cudssHandle_t handle, cudssData_t solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssCreate(cudssHandle_t* handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssCreateMg(cudssHandle_t* handle_pt, int device_count, const int* device_indices) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssDestroy(cudssHandle_t handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssGetProperty(libraryPropertyType propertyType, int* value) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixCreateDn(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t ld, const void* values, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixCreateCsr(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t nnz, const void* rowStart, const void* rowEnd, const void* colIndices, const void* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixCreateBatchDn(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* ld, const void* const* values, cudssDataType_t integerType, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixCreateBatchCsr(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* nnz, const void* const* rowStart, const void* const* rowEnd, const void* const* colIndices, const void* const* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixDestroy(cudssMatrix_t matrix) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetDn(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* ld, void** values, cudssDataType_t* type, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetCsr(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* nnz, void** rowStart, void** rowEnd, void** colIndices, void** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixSetValues(cudssMatrix_t matrix, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixSetCsrPointers(cudssMatrix_t matrix, const void* rowOffsets, const void* rowEnd, const void* colIndices, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetBatchDn(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** ld, void*** values, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetBatchCsr(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** nnz, void*** rowStart, void*** rowEnd, void*** colIndices, void*** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixSetBatchValues(cudssMatrix_t matrix, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixSetBatchCsrPointers(cudssMatrix_t matrix, const void* const* rowOffsets, const void* const* rowEnd, const void* const* colIndices, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetFormat(const cudssMatrix_t matrix, int* format) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixSetDistributionRow1d(cudssMatrix_t matrix, int64_t first_row, int64_t last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssMatrixGetDistributionRow1d(const cudssMatrix_t matrix, int64_t* first_row, int64_t* last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssGetDeviceMemHandler(const cudssHandle_t handle, cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssSetDeviceMemHandler(cudssHandle_t handle, const cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerSetCallback(cudssLoggerCallback_t callback) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerSetFile(FILE* file) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerOpenFile(const char* logFile) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerSetLevel(int level) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerSetMask(int mask) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t _cudssLoggerForceDisable() except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
