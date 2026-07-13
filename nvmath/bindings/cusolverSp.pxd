# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.1, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libc.stdint cimport intptr_t

from .cycusolverSp cimport *


###############################################################################
# Types
###############################################################################

ctypedef cusolverSpHandle_t Handle
ctypedef csrqrInfo_t csrqrInfo

ctypedef cudaStream_t Stream
ctypedef cusparseMatDescr_t MatDescr


###############################################################################
# Enum
###############################################################################




###############################################################################
# Functions
###############################################################################

cpdef intptr_t create() except? 0
cpdef destroy(intptr_t handle)
cpdef set_stream(intptr_t handle, intptr_t stream_id)
cpdef intptr_t get_stream(intptr_t handle) except? 0
cpdef xcsrissym_host(intptr_t handle, int m, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_end_ptr_a, intptr_t csr_col_ind_a, intptr_t issym)
cpdef scsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef dcsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef ccsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef zcsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef scsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef dcsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef ccsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef zcsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef scsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef dcsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef ccsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef zcsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef scsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef dcsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef ccsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef zcsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef scsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef dcsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef ccsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity)
cpdef zcsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity)
cpdef scsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm)
cpdef dcsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm)
cpdef ccsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm)
cpdef zcsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm)
cpdef scsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, float mu0, intptr_t x0, int maxite, float tol, intptr_t mu, intptr_t x)
cpdef dcsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, double mu0, intptr_t x0, int maxite, double tol, intptr_t mu, intptr_t x)
cpdef ccsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, float tol, intptr_t mu, intptr_t x)
cpdef zcsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, double tol, intptr_t mu, intptr_t x)
cpdef scsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, float mu0, intptr_t x0, int maxite, float eps, intptr_t mu, intptr_t x)
cpdef dcsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, double mu0, intptr_t x0, int maxite, double eps, intptr_t mu, intptr_t x)
cpdef ccsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, float eps, intptr_t mu, intptr_t x)
cpdef zcsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, double eps, intptr_t mu, intptr_t x)
cpdef scsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs)
cpdef dcsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs)
cpdef ccsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs)
cpdef zcsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs)
cpdef xcsrsymrcm_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p)
cpdef xcsrsymmdq_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p)
cpdef xcsrsymamd_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p)
cpdef xcsrmetisnd_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t options, intptr_t p)
cpdef scsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz)
cpdef dcsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz)
cpdef ccsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz)
cpdef zcsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz)
cpdef size_t xcsrperm_buffer_size_host(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t q) except? 0
cpdef xcsrperm_host(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t q, intptr_t map, intptr_t p_buffer)
cpdef intptr_t create_csrqr_info() except? 0
cpdef destroy_csrqr_info(intptr_t info)
cpdef xcsrqr_analysis_batched(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t info)
cpdef tuple scsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info)
cpdef tuple dcsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info)
cpdef tuple ccsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info)
cpdef tuple zcsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info)
cpdef scsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer)
cpdef dcsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer)
cpdef ccsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer)
cpdef zcsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer)
