# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 0.7.2 to 0.8.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libc.stdint cimport intptr_t

from .cycusolverMp cimport *


###############################################################################
# Types
###############################################################################

ctypedef ncclComm_t ncclComm
ctypedef cusolverMpGrid_t Grid
ctypedef cusolverMpMatrixDescriptor_t MatrixDescriptor
ctypedef cusolverMpHandle_t Handle
ctypedef cusolverMpNewtonSchulzDescriptor_t NewtonSchulzDescriptor
ctypedef cusolverMpLoggerCallback_t LoggerCallback

ctypedef cudaStream_t Stream
ctypedef cudaDataType DataType
ctypedef libraryPropertyType_t LibraryPropertyType


###############################################################################
# Enum
###############################################################################

ctypedef cusolverMpGridMapping_t _GridMapping
ctypedef cusolverMpNewtonSchulzDescriptorAttribute_t _NewtonSchulzDescriptorAttribute


###############################################################################
# Functions
###############################################################################

cpdef intptr_t create(int device_id, intptr_t stream) except? 0
cpdef destroy(intptr_t handle)
cpdef intptr_t get_stream(intptr_t handle) except? 0
cpdef int get_version(intptr_t handle) except? 0
cpdef intptr_t create_device_grid(intptr_t handle, intptr_t comm, int32_t num_row_devices, int32_t num_col_devices, int mapping) except? 0
cpdef destroy_grid(intptr_t grid)
cpdef intptr_t create_matrix_desc(intptr_t grid, int data_type, int64_t m_a, int64_t n_a, int64_t mb_a, int64_t nb_a, uint32_t rsrc_a, uint32_t csrc_a, int64_t lld_a) except? 0
cpdef destroy_matrix_desc(intptr_t desc)
cpdef int64_t numroc(int64_t n, int64_t nb, uint32_t iproc, uint32_t isrcproc, uint32_t nprocs) except? -1
cpdef matrix_scatter_h2d(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int root, intptr_t h_src, int64_t h_ldsrc)
cpdef matrix_gather_d2h(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int root, intptr_t h_dst, int64_t h_lddst)
cpdef tuple getrf_buffer_size(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, int compute_type)
cpdef getrf(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple getrs_buffer_size(intptr_t handle, int trans, int64_t n, int64_t nrhs, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, intptr_t d_b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type)
cpdef getrs(intptr_t handle, int trans, int64_t n, int64_t nrhs, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_ipiv, intptr_t d_b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info)
cpdef tuple potrf_buffer_size(intptr_t handle, int uplo, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type)
cpdef potrf(intptr_t handle, int uplo, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple potrs_buffer_size(intptr_t handle, int uplo, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type)
cpdef potrs(intptr_t handle, int uplo, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple ormqr_buffer_size(intptr_t handle, int side, int trans, int64_t m, int64_t n, int64_t k, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type)
cpdef ormqr(intptr_t handle, int side, int trans, int64_t m, int64_t n, int64_t k, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple ormtr_buffer_size(intptr_t handle, int side, int uplo, int trans, int64_t m, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type)
cpdef ormtr(intptr_t handle, int side, int uplo, int trans, int64_t m, int64_t n, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t tau, intptr_t c, int64_t ic, int64_t jc, intptr_t desc_c, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple gels_buffer_size(intptr_t handle, int trans, int64_t m, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type)
cpdef gels(intptr_t handle, int trans, int64_t m, int64_t n, int64_t nrhs, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple stedc_buffer_size(intptr_t handle, intptr_t compz, int64_t n, intptr_t d_d, intptr_t d_e, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t iwork)
cpdef stedc(intptr_t handle, intptr_t compz, int64_t n, intptr_t d_d, intptr_t d_e, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple geqrf_buffer_size(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, int compute_type)
cpdef geqrf(intptr_t handle, int64_t m, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple sytrd_buffer_size(intptr_t handle, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_e, intptr_t d_tau, int compute_type)
cpdef sytrd(intptr_t handle, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_e, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple syevd_buffer_size(intptr_t handle, intptr_t compz, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type)
cpdef syevd(intptr_t handle, intptr_t compz, int uplo, int64_t n, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_d, intptr_t d_q, int64_t iq, int64_t jq, intptr_t desc_q, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info)
cpdef tuple sygst_buffer_size(intptr_t handle, int ibtype, int uplo, int64_t m, int64_t ia, int64_t ja, intptr_t desc_a, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type)
cpdef sygst(intptr_t handle, int ibtype, int uplo, int64_t m, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef tuple sygvd_buffer_size(intptr_t handle, int ibtype, int jobz, int uplo, int64_t m, int64_t ia, int64_t ja, intptr_t desc_a, int64_t ib, int64_t jb, intptr_t desc_b, int64_t iz, int64_t jz, intptr_t desc_z, int compute_type)
cpdef sygvd(intptr_t handle, int ibtype, int jobz, int uplo, int64_t m, intptr_t a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t b, int64_t ib, int64_t jb, intptr_t desc_b, intptr_t w, intptr_t z, int64_t iz, int64_t jz, intptr_t desc_z, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
cpdef logger_set_file(intptr_t file)
cpdef logger_open_file(intptr_t log_file)
cpdef logger_set_level(int level)
cpdef logger_set_mask(int mask)
cpdef logger_force_disable()
cpdef set_math_mode(intptr_t handle, int mode)
cpdef int get_math_mode(intptr_t handle) except? -1
cpdef set_emulation_strategy(intptr_t handle, int strategy)
cpdef int get_emulation_strategy(intptr_t handle) except? -1
cpdef intptr_t newton_schulz_descriptor_create() except? 0
cpdef newton_schulz_descriptor_destroy(intptr_t ns_desc)
cpdef get_newton_schulz_descriptor_attribute_dtype(int attr)
cpdef newton_schulz_descriptor_set_attribute(intptr_t ns_desc, int attr, intptr_t buf, size_t size_in_bytes)
cpdef newton_schulz_descriptor_get_attribute(intptr_t ns_desc, int attr, intptr_t buf, size_t size_in_bytes, intptr_t size_in_bytes_written)
cpdef set_stream(intptr_t handle, intptr_t stream)
cpdef buffer_register(intptr_t grid, intptr_t ptr, size_t size)
cpdef buffer_deregister(intptr_t grid, intptr_t ptr)
cpdef tuple orgqr_buffer_size(intptr_t handle, int64_t m, int64_t n, int64_t k, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type)
cpdef orgqr(intptr_t handle, int64_t m, int64_t n, int64_t k, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_tau, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t d_info)
cpdef laset(intptr_t handle, int uplo, int64_t m, int64_t n, intptr_t alpha, intptr_t beta, intptr_t d_a, int64_t ia, int64_t ja, intptr_t desc_a, intptr_t d_info)
cpdef tuple newton_schulz_buffer_size(intptr_t handle, intptr_t ns_desc, int64_t m, int64_t n, intptr_t d_x, int64_t ix, int64_t jx, intptr_t desc_x, int64_t number_of_newton_schulz_iterations, intptr_t h_coeffs, int compute_type)
cpdef newton_schulz(intptr_t handle, intptr_t ns_desc, int64_t m, int64_t n, intptr_t d_x, int64_t ix, int64_t jx, intptr_t desc_x, int64_t number_of_newton_schulz_iterations, intptr_t h_coeffs, int compute_type, intptr_t d_work, size_t workspace_in_bytes_on_device, intptr_t h_work, size_t workspace_in_bytes_on_host, intptr_t info)
