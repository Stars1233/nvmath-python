# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated with version 0.8.0, generator version 0.3.1.dev1725+g07a86fe3d.d20260603. Do not modify it directly.
# This layer exposes the C header to Cython as-is.

from libc.stdint cimport int64_t
from libc.stdio cimport FILE

from ._internal.common_types cimport cudaDataType, cudaDataType_t, cudaStream_t, libraryPropertyType, libraryPropertyType_t, cuComplex, cuDoubleComplex


###############################################################################
# Types (structs, enums, ...)
###############################################################################

# enums
ctypedef enum cudssDataType_t "cudssDataType_t":
    CUDSS_DATA_TYPE_UNSET "CUDSS_DATA_TYPE_UNSET" = 1024
    CUDSS_R_32F "CUDSS_R_32F" = 0
    CUDSS_R_64F "CUDSS_R_64F" = 1
    CUDSS_C_32F "CUDSS_C_32F" = 4
    CUDSS_C_64F "CUDSS_C_64F" = 5
    CUDSS_R_64F_64F "CUDSS_R_64F_64F" = (1025 + CUDSS_R_64F)
    CUDSS_R_32I "CUDSS_R_32I" = 10
    CUDSS_R_64I "CUDSS_R_64I" = 24

ctypedef enum cudssConfigParam_t "cudssConfigParam_t":
    CUDSS_CONFIG_REORDERING_ALG "CUDSS_CONFIG_REORDERING_ALG"
    CUDSS_CONFIG_FACTORIZATION_ALG "CUDSS_CONFIG_FACTORIZATION_ALG"
    CUDSS_CONFIG_SOLVE_ALG "CUDSS_CONFIG_SOLVE_ALG"
    CUDSS_CONFIG_MATCHING_ALG "CUDSS_CONFIG_MATCHING_ALG"
    CUDSS_CONFIG_SOLVE_MODE "CUDSS_CONFIG_SOLVE_MODE"
    CUDSS_CONFIG_IR_N_STEPS "CUDSS_CONFIG_IR_N_STEPS"
    CUDSS_CONFIG_IR_TOL "CUDSS_CONFIG_IR_TOL"
    CUDSS_CONFIG_PIVOT_TYPE "CUDSS_CONFIG_PIVOT_TYPE"
    CUDSS_CONFIG_PIVOT_THRESHOLD "CUDSS_CONFIG_PIVOT_THRESHOLD"
    CUDSS_CONFIG_PIVOT_EPSILON "CUDSS_CONFIG_PIVOT_EPSILON"
    CUDSS_CONFIG_MAX_LU_NNZ "CUDSS_CONFIG_MAX_LU_NNZ"
    CUDSS_CONFIG_HYBRID_MEMORY_MODE "CUDSS_CONFIG_HYBRID_MEMORY_MODE"
    CUDSS_CONFIG_HYBRID_DEVICE_MEMORY_LIMIT "CUDSS_CONFIG_HYBRID_DEVICE_MEMORY_LIMIT"
    CUDSS_CONFIG_USE_CUDA_REGISTER_MEMORY "CUDSS_CONFIG_USE_CUDA_REGISTER_MEMORY"
    CUDSS_CONFIG_HOST_NTHREADS "CUDSS_CONFIG_HOST_NTHREADS"
    CUDSS_CONFIG_HYBRID_EXECUTE_MODE "CUDSS_CONFIG_HYBRID_EXECUTE_MODE"
    CUDSS_CONFIG_PIVOT_EPSILON_ALG "CUDSS_CONFIG_PIVOT_EPSILON_ALG"
    CUDSS_CONFIG_ND_NLEVELS "CUDSS_CONFIG_ND_NLEVELS"
    CUDSS_CONFIG_UBATCH_SIZE "CUDSS_CONFIG_UBATCH_SIZE"
    CUDSS_CONFIG_UBATCH_INDEX "CUDSS_CONFIG_UBATCH_INDEX"
    CUDSS_CONFIG_USE_SUPERPANELS "CUDSS_CONFIG_USE_SUPERPANELS"
    CUDSS_CONFIG_DEVICE_COUNT "CUDSS_CONFIG_DEVICE_COUNT"
    CUDSS_CONFIG_DEVICE_INDICES "CUDSS_CONFIG_DEVICE_INDICES"
    CUDSS_CONFIG_SCHUR_MODE "CUDSS_CONFIG_SCHUR_MODE"
    CUDSS_CONFIG_DETERMINISTIC_MODE "CUDSS_CONFIG_DETERMINISTIC_MODE"
    CUDSS_CONFIG_ND_UBFACTOR "CUDSS_CONFIG_ND_UBFACTOR"

ctypedef enum cudssDataParam_t "cudssDataParam_t":
    CUDSS_DATA_INFO "CUDSS_DATA_INFO"
    CUDSS_DATA_LU_NNZ "CUDSS_DATA_LU_NNZ"
    CUDSS_DATA_NPIVOTS "CUDSS_DATA_NPIVOTS"
    CUDSS_DATA_INERTIA "CUDSS_DATA_INERTIA"
    CUDSS_DATA_PERM_REORDER_ROW "CUDSS_DATA_PERM_REORDER_ROW"
    CUDSS_DATA_PERM_REORDER_COL "CUDSS_DATA_PERM_REORDER_COL"
    CUDSS_DATA_PERM_ROW "CUDSS_DATA_PERM_ROW"
    CUDSS_DATA_PERM_COL "CUDSS_DATA_PERM_COL"
    CUDSS_DATA_DIAG "CUDSS_DATA_DIAG"
    CUDSS_DATA_USER_PERM "CUDSS_DATA_USER_PERM"
    CUDSS_DATA_HYBRID_DEVICE_MEMORY_MIN "CUDSS_DATA_HYBRID_DEVICE_MEMORY_MIN"
    CUDSS_DATA_COMM_DEVICE "CUDSS_DATA_COMM_DEVICE"
    CUDSS_DATA_COMM_HOST "CUDSS_DATA_COMM_HOST"
    CUDSS_DATA_MEMORY_ESTIMATES "CUDSS_DATA_MEMORY_ESTIMATES"
    CUDSS_DATA_PERM_MATCHING "CUDSS_DATA_PERM_MATCHING"
    CUDSS_DATA_SCALE_ROW "CUDSS_DATA_SCALE_ROW"
    CUDSS_DATA_SCALE_COL "CUDSS_DATA_SCALE_COL"
    CUDSS_DATA_NSUPERPANELS "CUDSS_DATA_NSUPERPANELS"
    CUDSS_DATA_USER_SCHUR_INDICES "CUDSS_DATA_USER_SCHUR_INDICES"
    CUDSS_DATA_SCHUR_SHAPE "CUDSS_DATA_SCHUR_SHAPE"
    CUDSS_DATA_SCHUR_MATRIX "CUDSS_DATA_SCHUR_MATRIX"
    CUDSS_DATA_USER_ND_PARTITION_TREE "CUDSS_DATA_USER_ND_PARTITION_TREE"
    CUDSS_DATA_ND_PARTITION_TREE "CUDSS_DATA_ND_PARTITION_TREE"
    CUDSS_DATA_USER_HOST_INTERRUPT "CUDSS_DATA_USER_HOST_INTERRUPT"
    CUDSS_DATA_IR_N_STEPS "CUDSS_DATA_IR_N_STEPS"
    CUDSS_DATA_UBATCH_MASK "CUDSS_DATA_UBATCH_MASK"
    CUDSS_DATA_FLOPS "CUDSS_DATA_FLOPS"

ctypedef enum cudssPhase_t "cudssPhase_t":
    CUDSS_PHASE_REORDERING "CUDSS_PHASE_REORDERING" = (1 << 0)
    CUDSS_PHASE_SYMBOLIC_FACTORIZATION "CUDSS_PHASE_SYMBOLIC_FACTORIZATION" = (1 << 1)
    CUDSS_PHASE_ANALYSIS "CUDSS_PHASE_ANALYSIS" = (CUDSS_PHASE_REORDERING | CUDSS_PHASE_SYMBOLIC_FACTORIZATION)
    CUDSS_PHASE_FACTORIZATION "CUDSS_PHASE_FACTORIZATION" = (1 << 2)
    CUDSS_PHASE_REFACTORIZATION "CUDSS_PHASE_REFACTORIZATION" = (1 << 3)
    CUDSS_PHASE_SOLVE_FWD_PERM "CUDSS_PHASE_SOLVE_FWD_PERM" = (1 << 4)
    CUDSS_PHASE_SOLVE_FWD "CUDSS_PHASE_SOLVE_FWD" = (1 << 5)
    CUDSS_PHASE_SOLVE_DIAG "CUDSS_PHASE_SOLVE_DIAG" = (1 << 6)
    CUDSS_PHASE_SOLVE_BWD "CUDSS_PHASE_SOLVE_BWD" = (1 << 7)
    CUDSS_PHASE_SOLVE_BWD_PERM "CUDSS_PHASE_SOLVE_BWD_PERM" = (1 << 8)
    CUDSS_PHASE_SOLVE_REFINEMENT "CUDSS_PHASE_SOLVE_REFINEMENT" = (1 << 9)
    CUDSS_PHASE_SOLVE "CUDSS_PHASE_SOLVE" = (((((CUDSS_PHASE_SOLVE_FWD_PERM | CUDSS_PHASE_SOLVE_FWD) | CUDSS_PHASE_SOLVE_DIAG) | CUDSS_PHASE_SOLVE_BWD) | CUDSS_PHASE_SOLVE_BWD_PERM) | CUDSS_PHASE_SOLVE_REFINEMENT)

ctypedef enum cudssStatus_t "cudssStatus_t":
    CUDSS_STATUS_SUCCESS "CUDSS_STATUS_SUCCESS" = 0
    CUDSS_STATUS_NOT_INITIALIZED "CUDSS_STATUS_NOT_INITIALIZED" = 1
    CUDSS_STATUS_ALLOC_FAILED "CUDSS_STATUS_ALLOC_FAILED" = 2
    CUDSS_STATUS_INVALID_VALUE "CUDSS_STATUS_INVALID_VALUE" = 3
    CUDSS_STATUS_NOT_SUPPORTED "CUDSS_STATUS_NOT_SUPPORTED" = 4
    CUDSS_STATUS_EXECUTION_FAILED "CUDSS_STATUS_EXECUTION_FAILED" = 5
    CUDSS_STATUS_INTERNAL_ERROR "CUDSS_STATUS_INTERNAL_ERROR" = 6
    CUDSS_STATUS_IR_FAILED "CUDSS_STATUS_IR_FAILED" = 7
    _CUDSSSTATUS_T_INTERNAL_LOADING_ERROR "_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR" = -42

ctypedef enum cudssMatrixType_t "cudssMatrixType_t":
    CUDSS_MTYPE_GENERAL "CUDSS_MTYPE_GENERAL"
    CUDSS_MTYPE_SYMMETRIC "CUDSS_MTYPE_SYMMETRIC"
    CUDSS_MTYPE_HERMITIAN "CUDSS_MTYPE_HERMITIAN"
    CUDSS_MTYPE_SPD "CUDSS_MTYPE_SPD"
    CUDSS_MTYPE_HPD "CUDSS_MTYPE_HPD"

ctypedef enum cudssMatrixViewType_t "cudssMatrixViewType_t":
    CUDSS_MVIEW_FULL "CUDSS_MVIEW_FULL"
    CUDSS_MVIEW_LOWER "CUDSS_MVIEW_LOWER"
    CUDSS_MVIEW_UPPER "CUDSS_MVIEW_UPPER"

ctypedef enum cudssIndexBase_t "cudssIndexBase_t":
    CUDSS_BASE_ZERO "CUDSS_BASE_ZERO"
    CUDSS_BASE_ONE "CUDSS_BASE_ONE"

ctypedef enum cudssLayout_t "cudssLayout_t":
    CUDSS_LAYOUT_COL_MAJOR "CUDSS_LAYOUT_COL_MAJOR"
    CUDSS_LAYOUT_ROW_MAJOR "CUDSS_LAYOUT_ROW_MAJOR"

ctypedef enum cudssReorderingAlg_t "cudssReorderingAlg_t":
    CUDSS_REORDERING_ALG_DEFAULT "CUDSS_REORDERING_ALG_DEFAULT"
    CUDSS_REORDERING_ALG_BTF_COLAMD "CUDSS_REORDERING_ALG_BTF_COLAMD"
    CUDSS_REORDERING_ALG_COLAMD "CUDSS_REORDERING_ALG_COLAMD"
    CUDSS_REORDERING_ALG_AMD "CUDSS_REORDERING_ALG_AMD"
    CUDSS_REORDERING_ALG_NESTED_DISSECTION "CUDSS_REORDERING_ALG_NESTED_DISSECTION"
    CUDSS_REORDERING_ALG_NONE "CUDSS_REORDERING_ALG_NONE"

ctypedef enum cudssFactorizationAlg_t "cudssFactorizationAlg_t":
    CUDSS_FACTORIZATION_ALG_DEFAULT "CUDSS_FACTORIZATION_ALG_DEFAULT"
    CUDSS_FACTORIZATION_ALG_MULTIBLOCK "CUDSS_FACTORIZATION_ALG_MULTIBLOCK"
    CUDSS_FACTORIZATION_ALG_GENERAL "CUDSS_FACTORIZATION_ALG_GENERAL"

ctypedef enum cudssPivotEpsilonAlg_t "cudssPivotEpsilonAlg_t":
    CUDSS_PIVOT_EPSILON_ALG_DEFAULT "CUDSS_PIVOT_EPSILON_ALG_DEFAULT"
    CUDSS_PIVOT_EPSILON_ALG_SCALED "CUDSS_PIVOT_EPSILON_ALG_SCALED"
    CUDSS_PIVOT_EPSILON_ALG_STATIC "CUDSS_PIVOT_EPSILON_ALG_STATIC"

ctypedef enum cudssSolveAlg_t "cudssSolveAlg_t":
    CUDSS_SOLVE_ALG_DEFAULT "CUDSS_SOLVE_ALG_DEFAULT"
    CUDSS_SOLVE_ALG_GENERAL "CUDSS_SOLVE_ALG_GENERAL"

ctypedef enum cudssMatchingAlg_t "cudssMatchingAlg_t":
    CUDSS_MATCHING_ALG_NONE "CUDSS_MATCHING_ALG_NONE" = 0
    CUDSS_MATCHING_ALG_MAX_DIAG_COUNT "CUDSS_MATCHING_ALG_MAX_DIAG_COUNT" = 1
    CUDSS_MATCHING_ALG_MAX_MIN_DIAG "CUDSS_MATCHING_ALG_MAX_MIN_DIAG" = 2
    CUDSS_MATCHING_ALG_MAX_MIN_DIAG_ALT "CUDSS_MATCHING_ALG_MAX_MIN_DIAG_ALT" = 3
    CUDSS_MATCHING_ALG_MAX_DIAG_SUM "CUDSS_MATCHING_ALG_MAX_DIAG_SUM" = 4
    CUDSS_MATCHING_ALG_MAX_DIAG_PRODUCT "CUDSS_MATCHING_ALG_MAX_DIAG_PRODUCT" = 5
    CUDSS_MATCHING_ALG_AUTO "CUDSS_MATCHING_ALG_AUTO" = 6

ctypedef enum cudssPivotType_t "cudssPivotType_t":
    CUDSS_PIVOT_AUTO "CUDSS_PIVOT_AUTO"
    CUDSS_PIVOT_NONE "CUDSS_PIVOT_NONE"
    CUDSS_PIVOT_GLOBAL_COL "CUDSS_PIVOT_GLOBAL_COL"
    CUDSS_PIVOT_GLOBAL_ROW "CUDSS_PIVOT_GLOBAL_ROW"
    CUDSS_PIVOT_DIAGONAL "CUDSS_PIVOT_DIAGONAL"
    CUDSS_PIVOT_LOCAL_BLOCK "CUDSS_PIVOT_LOCAL_BLOCK"
    CUDSS_PIVOT_BUNCH_KAUFMAN "CUDSS_PIVOT_BUNCH_KAUFMAN"

ctypedef enum cudssMatrixFormat_t "cudssMatrixFormat_t":
    CUDSS_MFORMAT_DENSE "CUDSS_MFORMAT_DENSE" = 1
    CUDSS_MFORMAT_CSR "CUDSS_MFORMAT_CSR" = 2
    CUDSS_MFORMAT_BATCH "CUDSS_MFORMAT_BATCH" = 4
    CUDSS_MFORMAT_DISTRIBUTED "CUDSS_MFORMAT_DISTRIBUTED" = 8

ctypedef enum cudssOpType_t "cudssOpType_t":
    CUDSS_SUM "CUDSS_SUM"
    CUDSS_MAX "CUDSS_MAX"
    CUDSS_MIN "CUDSS_MIN"


# types
ctypedef void* cudssHandle_t 'cudssHandle_t'

ctypedef void* cudssMatrix_t 'cudssMatrix_t'

ctypedef void* cudssData_t 'cudssData_t'

ctypedef void* cudssConfig_t 'cudssConfig_t'

ctypedef struct cudssDeviceMemHandler_t 'cudssDeviceMemHandler_t':
    void* ctx
    int (*device_alloc)(void*, void**, size_t, cudaStream_t)
    int (*device_free)(void*, void*, size_t, cudaStream_t)
    char name[64]

ctypedef struct cudssDistributedInterface_t 'cudssDistributedInterface_t':
    int (*cudssCommRankDevice)(void*, int*)
    int (*cudssCommSizeDevice)(void*, int*)
    int (*cudssSendDevice)(const void*, int, cudssDataType_t, int, int, void*, cudaStream_t)
    int (*cudssRecvDevice)(void*, int, cudssDataType_t, int, int, void*, cudaStream_t)
    int (*cudssBcastDevice)(void*, int, cudssDataType_t, int, void*, cudaStream_t)
    int (*cudssReduceDevice)(const void*, void*, int, cudssDataType_t, cudssOpType_t, int, void*, cudaStream_t)
    int (*cudssAllreduceDevice)(const void*, void*, int, cudssDataType_t, cudssOpType_t, void*, cudaStream_t)
    int (*cudssScattervDevice)(const void*, const int*, const int*, cudssDataType_t, void*, int, cudssDataType_t, int, void*, cudaStream_t)
    int (*cudssCommSplitDevice)(const void*, int, int, void*)
    int (*cudssCommFreeDevice)(void*)
    int (*cudssCommRankHost)(void*, int*)
    int (*cudssCommSizeHost)(void*, int*)
    int (*cudssSendHost)(const void*, int, cudssDataType_t, int, int, void*, cudaStream_t)
    int (*cudssRecvHost)(void*, int, cudssDataType_t, int, int, void*, cudaStream_t)
    int (*cudssBcastHost)(void*, int, cudssDataType_t, int, void*, cudaStream_t)
    int (*cudssReduceHost)(const void*, void*, int, cudssDataType_t, cudssOpType_t, int, void*, cudaStream_t)
    int (*cudssAllreduceHost)(const void*, void*, int, cudssDataType_t, cudssOpType_t, void*, cudaStream_t)
    int (*cudssScattervHost)(const void*, const int*, const int*, cudssDataType_t, void*, int, cudssDataType_t, int, void*, cudaStream_t)
    int (*cudssCommSplitHost)(const void*, int, int, void*)
    int (*cudssCommFreeHost)(void*)
    int (*cudssDistributedGetProperty)(libraryPropertyType, int*)

ctypedef struct cudssThreadingInterface_t 'cudssThreadingInterface_t':
    int (*cudssGetMaxThreads)()
    void (*cudssParallelFor)(int, int, void*, cudss_thr_func_t)
    int (*cudssThreadingGetProperty)(libraryPropertyType, int*)

ctypedef void (*cudssLoggerCallback_t 'cudssLoggerCallback_t')(
    int logLevel,
    const char* functionName,
    const char* message
)


###############################################################################
# Functions
###############################################################################

cdef cudssStatus_t cudssConfigSet(cudssConfig_t config, cudssConfigParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssConfigGet(const cudssConfig_t config, cudssConfigParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssDataSet(const cudssHandle_t handle, cudssData_t data, cudssDataParam_t param, const void* value, size_t sizeInBytes) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssDataGet(const cudssHandle_t handle, const cudssData_t data, cudssDataParam_t param, void* value, size_t sizeInBytes, size_t* sizeWritten) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssExecute(cudssHandle_t handle, int phase, const cudssConfig_t solverConfig, cudssData_t solverData, const cudssMatrix_t inputMatrix, cudssMatrix_t solution, const cudssMatrix_t rhs) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssSetStream(cudssHandle_t handle, cudaStream_t stream) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssSetMgStreams(cudssHandle_t handle, const cudaStream_t* streams, int stream_count) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssSetCommLayer(cudssHandle_t handle, const char* commLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssSetThreadingLayer(cudssHandle_t handle, const char* thrLibFileName) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssConfigCreate(cudssConfig_t* solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssConfigDestroy(cudssConfig_t solverConfig) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssDataCreate(const cudssHandle_t handle, cudssData_t* solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssDataDestroy(cudssHandle_t handle, cudssData_t solverData) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssCreate(cudssHandle_t* handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssCreateMg(cudssHandle_t* handle_pt, int device_count, const int* device_indices) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssDestroy(cudssHandle_t handle) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssGetProperty(libraryPropertyType propertyType, int* value) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixCreateDn(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t ld, const void* values, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixCreateCsr(cudssMatrix_t* matrix, int64_t nrows, int64_t ncols, int64_t nnz, const void* rowStart, const void* rowEnd, const void* colIndices, const void* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixCreateBatchDn(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* ld, const void* const* values, cudssDataType_t integerType, cudssDataType_t valueType, cudssLayout_t layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixCreateBatchCsr(cudssMatrix_t* matrix, int64_t batchCount, const void* nrows, const void* ncols, const void* nnz, const void* const* rowStart, const void* const* rowEnd, const void* const* colIndices, const void* const* values, cudssDataType_t offsetType, cudssDataType_t indexType, cudssDataType_t valueType, cudssMatrixType_t mtype, cudssMatrixViewType_t mview, cudssIndexBase_t indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixDestroy(cudssMatrix_t matrix) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetDn(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* ld, void** values, cudssDataType_t* type, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetCsr(const cudssMatrix_t matrix, int64_t* nrows, int64_t* ncols, int64_t* nnz, void** rowStart, void** rowEnd, void** colIndices, void** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixSetValues(cudssMatrix_t matrix, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixSetCsrPointers(cudssMatrix_t matrix, const void* rowOffsets, const void* rowEnd, const void* colIndices, const void* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetBatchDn(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** ld, void*** values, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssLayout_t* layout) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetBatchCsr(const cudssMatrix_t matrix, int64_t* batchCount, void** nrows, void** ncols, void** nnz, void*** rowStart, void*** rowEnd, void*** colIndices, void*** values, cudssDataType_t* offsetType, cudssDataType_t* indexType, cudssDataType_t* valueType, cudssMatrixType_t* mtype, cudssMatrixViewType_t* mview, cudssIndexBase_t* indexBase) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixSetBatchValues(cudssMatrix_t matrix, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixSetBatchCsrPointers(cudssMatrix_t matrix, const void* const* rowOffsets, const void* const* rowEnd, const void* const* colIndices, const void* const* values) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetFormat(const cudssMatrix_t matrix, int* format) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixSetDistributionRow1d(cudssMatrix_t matrix, int64_t first_row, int64_t last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssMatrixGetDistributionRow1d(const cudssMatrix_t matrix, int64_t* first_row, int64_t* last_row) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssGetDeviceMemHandler(const cudssHandle_t handle, cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssSetDeviceMemHandler(cudssHandle_t handle, const cudssDeviceMemHandler_t* handler) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerSetCallback(cudssLoggerCallback_t callback) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerSetFile(FILE* file) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerOpenFile(const char* logFile) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerSetLevel(int level) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerSetMask(int mask) except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
cdef cudssStatus_t cudssLoggerForceDisable() except?_CUDSSSTATUS_T_INTERNAL_LOADING_ERROR nogil
