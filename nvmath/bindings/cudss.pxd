# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated with version 0.8.0, generator version 0.3.1.dev1725+g07a86fe3d.d20260603. Do not modify it directly.

from libc.stdint cimport intptr_t

from .cycudss cimport *


###############################################################################
# Types
###############################################################################

ctypedef cudssHandle_t Handle
ctypedef cudssMatrix_t Matrix
ctypedef cudssData_t Data
ctypedef cudssConfig_t Config
ctypedef cudssDeviceMemHandler_t DeviceMemHandler
ctypedef cudssDistributedInterface_t DistributedInterface
ctypedef cudssThreadingInterface_t ThreadingInterface
ctypedef cudssLoggerCallback_t LoggerCallback

ctypedef cudaStream_t Stream
ctypedef libraryPropertyType_t LibraryPropertyType


###############################################################################
# Enum
###############################################################################

ctypedef cudssDataType_t _DataType
ctypedef cudssConfigParam_t _ConfigParam
ctypedef cudssDataParam_t _DataParam
ctypedef cudssPhase_t _Phase
ctypedef cudssStatus_t _Status
ctypedef cudssMatrixType_t _MatrixType
ctypedef cudssMatrixViewType_t _MatrixViewType
ctypedef cudssIndexBase_t _IndexBase
ctypedef cudssLayout_t _Layout
ctypedef cudssReorderingAlg_t _ReorderingAlg
ctypedef cudssFactorizationAlg_t _FactorizationAlg
ctypedef cudssPivotEpsilonAlg_t _PivotEpsilonAlg
ctypedef cudssSolveAlg_t _SolveAlg
ctypedef cudssMatchingAlg_t _MatchingAlg
ctypedef cudssPivotType_t _PivotType
ctypedef cudssMatrixFormat_t _MatrixFormat
ctypedef cudssOpType_t _OpType


###############################################################################
# Functions
###############################################################################

cpdef get_config_param_dtype(int attr)
cpdef config_set(intptr_t config, int param, intptr_t value, size_t size_in_bytes)
cpdef config_get(intptr_t config, int param, intptr_t value, size_t size_in_bytes, intptr_t size_written)
cpdef get_data_param_dtype(int attr)
cpdef data_set(intptr_t handle, intptr_t data, int param, intptr_t value, size_t size_in_bytes)
cpdef data_get(intptr_t handle, intptr_t data, int param, intptr_t value, size_t size_in_bytes, intptr_t size_written)
cpdef execute(intptr_t handle, int phase, intptr_t solver_config, intptr_t solver_data, intptr_t input_matrix, intptr_t solution, intptr_t rhs)
cpdef set_stream(intptr_t handle, intptr_t stream)
cpdef set_mg_streams(intptr_t handle, streams, int stream_count)
cpdef set_comm_layer(intptr_t handle, comm_lib_file_name)
cpdef set_threading_layer(intptr_t handle, thr_lib_file_name)
cpdef intptr_t config_create() except? 0
cpdef config_destroy(intptr_t solver_config)
cpdef intptr_t data_create(intptr_t handle) except? 0
cpdef data_destroy(intptr_t handle, intptr_t solver_data)
cpdef intptr_t create() except? 0
cpdef intptr_t create_mg(int device_count, device_indices) except? 0
cpdef destroy(intptr_t handle)
cpdef int get_property(int property_type) except? -1
cpdef intptr_t matrix_create_dn(int64_t nrows, int64_t ncols, int64_t ld, intptr_t values, int value_type, int layout) except? 0
cpdef intptr_t matrix_create_csr(int64_t nrows, int64_t ncols, int64_t nnz, intptr_t row_start, intptr_t row_end, intptr_t col_indices, intptr_t values, int offset_type, int index_type, int value_type, int mtype, int mview, int index_base) except? 0
cpdef intptr_t matrix_create_batch_dn(int64_t batch_count, intptr_t nrows, intptr_t ncols, intptr_t ld, intptr_t values, int integer_type, int value_type, int layout) except? 0
cpdef intptr_t matrix_create_batch_csr(int64_t batch_count, intptr_t nrows, intptr_t ncols, intptr_t nnz, intptr_t row_start, intptr_t row_end, intptr_t col_indices, intptr_t values, int offset_type, int index_type, int value_type, int mtype, int mview, int index_base) except? 0
cpdef matrix_destroy(intptr_t matrix)
cpdef matrix_get_dn(intptr_t matrix, intptr_t nrows, intptr_t ncols, intptr_t ld, intptr_t values, intptr_t type, intptr_t layout)
cpdef matrix_get_csr(intptr_t matrix, intptr_t nrows, intptr_t ncols, intptr_t nnz, intptr_t row_start, intptr_t row_end, intptr_t col_indices, intptr_t values, intptr_t offset_type, intptr_t index_type, intptr_t value_type, intptr_t mtype, intptr_t mview, intptr_t index_base)
cpdef matrix_set_values(intptr_t matrix, intptr_t values)
cpdef matrix_set_csr_pointers(intptr_t matrix, intptr_t row_offsets, intptr_t row_end, intptr_t col_indices, intptr_t values)
cpdef matrix_get_batch_dn(intptr_t matrix, intptr_t batch_count, intptr_t nrows, intptr_t ncols, intptr_t ld, intptr_t values, intptr_t index_type, intptr_t value_type, intptr_t layout)
cpdef matrix_get_batch_csr(intptr_t matrix, intptr_t batch_count, intptr_t nrows, intptr_t ncols, intptr_t nnz, intptr_t row_start, intptr_t row_end, intptr_t col_indices, intptr_t values, intptr_t offset_type, intptr_t index_type, intptr_t value_type, intptr_t mtype, intptr_t mview, intptr_t index_base)
cpdef matrix_set_batch_values(intptr_t matrix, intptr_t values)
cpdef matrix_set_batch_csr_pointers(intptr_t matrix, intptr_t row_offsets, intptr_t row_end, intptr_t col_indices, intptr_t values)
cpdef int matrix_get_format(intptr_t matrix) except? -1
cpdef matrix_set_distribution_row1d(intptr_t matrix, int64_t first_row, int64_t last_row)
cpdef matrix_get_distribution_row1d(intptr_t matrix, intptr_t first_row, intptr_t last_row)
cpdef get_device_mem_handler(intptr_t handle, intptr_t handler)
cpdef set_device_mem_handler(intptr_t handle, intptr_t handler)
cpdef logger_open_file(log_file)
cpdef logger_set_level(int level)
cpdef logger_set_mask(int mask)
cpdef logger_force_disable()

cpdef bint set_async_workspace_allocator(intptr_t cudss_handle, intptr_t pool_handle) except? -1
