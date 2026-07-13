# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.1, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libcpp.vector cimport vector

from .cusolver cimport check_status
from ._internal.utils cimport get_resource_ptrs, nullable_unique_ptr

from enum import IntEnum as _IntEnum


###############################################################################
# Enum
###############################################################################




###############################################################################
# Wrapper functions
###############################################################################

cpdef intptr_t create() except? 0:
    """See `cusolverSpCreate`."""
    cdef Handle handle
    with nogil:
        __status__ = cusolverSpCreate(&handle)
    check_status(__status__)
    return <intptr_t>handle


cpdef destroy(intptr_t handle):
    """See `cusolverSpDestroy`."""
    with nogil:
        __status__ = cusolverSpDestroy(<Handle>handle)
    check_status(__status__)


cpdef set_stream(intptr_t handle, intptr_t stream_id):
    """See `cusolverSpSetStream`."""
    with nogil:
        __status__ = cusolverSpSetStream(<Handle>handle, <Stream>stream_id)
    check_status(__status__)


cpdef intptr_t get_stream(intptr_t handle) except? 0:
    """See `cusolverSpGetStream`."""
    cdef Stream stream_id
    with nogil:
        __status__ = cusolverSpGetStream(<Handle>handle, &stream_id)
    check_status(__status__)
    return <intptr_t>stream_id


cpdef xcsrissym_host(intptr_t handle, int m, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_end_ptr_a, intptr_t csr_col_ind_a, intptr_t issym):
    """See `cusolverSpXcsrissymHost`."""
    with nogil:
        __status__ = cusolverSpXcsrissymHost(<Handle>handle, m, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_end_ptr_a, <const int*>csr_col_ind_a, <int*>issym)
    check_status(__status__)


cpdef scsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpScsrlsvluHost`."""
    with nogil:
        __status__ = cusolverSpScsrlsvluHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const float*>b, tol, reorder, <float*>x, <int*>singularity)
    check_status(__status__)


cpdef dcsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpDcsrlsvluHost`."""
    with nogil:
        __status__ = cusolverSpDcsrlsvluHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const double*>b, tol, reorder, <double*>x, <int*>singularity)
    check_status(__status__)


cpdef ccsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpCcsrlsvluHost`."""
    with nogil:
        __status__ = cusolverSpCcsrlsvluHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuComplex*>b, tol, reorder, <cuComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef zcsrlsvlu_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpZcsrlsvluHost`."""
    with nogil:
        __status__ = cusolverSpZcsrlsvluHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuDoubleComplex*>b, tol, reorder, <cuDoubleComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef scsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpScsrlsvqr`."""
    with nogil:
        __status__ = cusolverSpScsrlsvqr(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const float*>b, tol, reorder, <float*>x, <int*>singularity)
    check_status(__status__)


cpdef dcsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpDcsrlsvqr`."""
    with nogil:
        __status__ = cusolverSpDcsrlsvqr(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const double*>b, tol, reorder, <double*>x, <int*>singularity)
    check_status(__status__)


cpdef ccsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpCcsrlsvqr`."""
    with nogil:
        __status__ = cusolverSpCcsrlsvqr(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuComplex*>b, tol, reorder, <cuComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef zcsrlsvqr(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpZcsrlsvqr`."""
    with nogil:
        __status__ = cusolverSpZcsrlsvqr(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuDoubleComplex*>b, tol, reorder, <cuDoubleComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef scsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpScsrlsvqrHost`."""
    with nogil:
        __status__ = cusolverSpScsrlsvqrHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const float*>b, tol, reorder, <float*>x, <int*>singularity)
    check_status(__status__)


cpdef dcsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpDcsrlsvqrHost`."""
    with nogil:
        __status__ = cusolverSpDcsrlsvqrHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const double*>b, tol, reorder, <double*>x, <int*>singularity)
    check_status(__status__)


cpdef ccsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpCcsrlsvqrHost`."""
    with nogil:
        __status__ = cusolverSpCcsrlsvqrHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuComplex*>b, tol, reorder, <cuComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef zcsrlsvqr_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpZcsrlsvqrHost`."""
    with nogil:
        __status__ = cusolverSpZcsrlsvqrHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuDoubleComplex*>b, tol, reorder, <cuDoubleComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef scsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpScsrlsvcholHost`."""
    with nogil:
        __status__ = cusolverSpScsrlsvcholHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const float*>b, tol, reorder, <float*>x, <int*>singularity)
    check_status(__status__)


cpdef dcsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpDcsrlsvcholHost`."""
    with nogil:
        __status__ = cusolverSpDcsrlsvcholHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const double*>b, tol, reorder, <double*>x, <int*>singularity)
    check_status(__status__)


cpdef ccsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpCcsrlsvcholHost`."""
    with nogil:
        __status__ = cusolverSpCcsrlsvcholHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuComplex*>b, tol, reorder, <cuComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef zcsrlsvchol_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpZcsrlsvcholHost`."""
    with nogil:
        __status__ = cusolverSpZcsrlsvcholHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuDoubleComplex*>b, tol, reorder, <cuDoubleComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef scsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpScsrlsvchol`."""
    with nogil:
        __status__ = cusolverSpScsrlsvchol(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const float*>b, tol, reorder, <float*>x, <int*>singularity)
    check_status(__status__)


cpdef dcsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpDcsrlsvchol`."""
    with nogil:
        __status__ = cusolverSpDcsrlsvchol(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const double*>b, tol, reorder, <double*>x, <int*>singularity)
    check_status(__status__)


cpdef ccsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, float tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpCcsrlsvchol`."""
    with nogil:
        __status__ = cusolverSpCcsrlsvchol(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuComplex*>b, tol, reorder, <cuComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef zcsrlsvchol(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, intptr_t b, double tol, int reorder, intptr_t x, intptr_t singularity):
    """See `cusolverSpZcsrlsvchol`."""
    with nogil:
        __status__ = cusolverSpZcsrlsvchol(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, <const cuDoubleComplex*>b, tol, reorder, <cuDoubleComplex*>x, <int*>singularity)
    check_status(__status__)


cpdef scsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm):
    """See `cusolverSpScsrlsqvqrHost`."""
    with nogil:
        __status__ = cusolverSpScsrlsqvqrHost(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const float*>b, tol, <int*>rank_a, <float*>x, <int*>p, <float*>min_norm)
    check_status(__status__)


cpdef dcsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm):
    """See `cusolverSpDcsrlsqvqrHost`."""
    with nogil:
        __status__ = cusolverSpDcsrlsqvqrHost(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const double*>b, tol, <int*>rank_a, <double*>x, <int*>p, <double*>min_norm)
    check_status(__status__)


cpdef ccsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, float tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm):
    """See `cusolverSpCcsrlsqvqrHost`."""
    with nogil:
        __status__ = cusolverSpCcsrlsqvqrHost(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuComplex*>b, tol, <int*>rank_a, <cuComplex*>x, <int*>p, <float*>min_norm)
    check_status(__status__)


cpdef zcsrlsqvqr_host(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, double tol, intptr_t rank_a, intptr_t x, intptr_t p, intptr_t min_norm):
    """See `cusolverSpZcsrlsqvqrHost`."""
    with nogil:
        __status__ = cusolverSpZcsrlsqvqrHost(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuDoubleComplex*>b, tol, <int*>rank_a, <cuDoubleComplex*>x, <int*>p, <double*>min_norm)
    check_status(__status__)


cpdef scsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, float mu0, intptr_t x0, int maxite, float tol, intptr_t mu, intptr_t x):
    """See `cusolverSpScsreigvsiHost`."""
    with nogil:
        __status__ = cusolverSpScsreigvsiHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, mu0, <const float*>x0, maxite, tol, <float*>mu, <float*>x)
    check_status(__status__)


cpdef dcsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, double mu0, intptr_t x0, int maxite, double tol, intptr_t mu, intptr_t x):
    """See `cusolverSpDcsreigvsiHost`."""
    with nogil:
        __status__ = cusolverSpDcsreigvsiHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, mu0, <const double*>x0, maxite, tol, <double*>mu, <double*>x)
    check_status(__status__)


cpdef ccsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, float tol, intptr_t mu, intptr_t x):
    """See `cusolverSpCcsreigvsiHost`."""
    cdef cuComplex _mu0_ = cuComplex(mu0.real, mu0.imag)
    with nogil:
        __status__ = cusolverSpCcsreigvsiHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuComplex>_mu0_, <const cuComplex*>x0, maxite, tol, <cuComplex*>mu, <cuComplex*>x)
    check_status(__status__)


cpdef zcsreigvsi_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, double tol, intptr_t mu, intptr_t x):
    """See `cusolverSpZcsreigvsiHost`."""
    cdef cuDoubleComplex _mu0_ = cuDoubleComplex(mu0.real, mu0.imag)
    with nogil:
        __status__ = cusolverSpZcsreigvsiHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuDoubleComplex>_mu0_, <const cuDoubleComplex*>x0, maxite, tol, <cuDoubleComplex*>mu, <cuDoubleComplex*>x)
    check_status(__status__)


cpdef scsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, float mu0, intptr_t x0, int maxite, float eps, intptr_t mu, intptr_t x):
    """See `cusolverSpScsreigvsi`."""
    with nogil:
        __status__ = cusolverSpScsreigvsi(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, mu0, <const float*>x0, maxite, eps, <float*>mu, <float*>x)
    check_status(__status__)


cpdef dcsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, double mu0, intptr_t x0, int maxite, double eps, intptr_t mu, intptr_t x):
    """See `cusolverSpDcsreigvsi`."""
    with nogil:
        __status__ = cusolverSpDcsreigvsi(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, mu0, <const double*>x0, maxite, eps, <double*>mu, <double*>x)
    check_status(__status__)


cpdef ccsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, float eps, intptr_t mu, intptr_t x):
    """See `cusolverSpCcsreigvsi`."""
    cdef cuComplex _mu0_ = cuComplex(mu0.real, mu0.imag)
    with nogil:
        __status__ = cusolverSpCcsreigvsi(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuComplex>_mu0_, <const cuComplex*>x0, maxite, eps, <cuComplex*>mu, <cuComplex*>x)
    check_status(__status__)


cpdef zcsreigvsi(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex mu0, intptr_t x0, int maxite, double eps, intptr_t mu, intptr_t x):
    """See `cusolverSpZcsreigvsi`."""
    cdef cuDoubleComplex _mu0_ = cuDoubleComplex(mu0.real, mu0.imag)
    with nogil:
        __status__ = cusolverSpZcsreigvsi(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuDoubleComplex>_mu0_, <const cuDoubleComplex*>x0, maxite, eps, <cuDoubleComplex*>mu, <cuDoubleComplex*>x)
    check_status(__status__)


cpdef scsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs):
    """See `cusolverSpScsreigsHost`."""
    cdef cuComplex _left_bottom_corner_ = cuComplex(left_bottom_corner.real, left_bottom_corner.imag)
    cdef cuComplex _right_upper_corner_ = cuComplex(right_upper_corner.real, right_upper_corner.imag)
    with nogil:
        __status__ = cusolverSpScsreigsHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuComplex>_left_bottom_corner_, <cuComplex>_right_upper_corner_, <int*>num_eigs)
    check_status(__status__)


cpdef dcsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs):
    """See `cusolverSpDcsreigsHost`."""
    cdef cuDoubleComplex _left_bottom_corner_ = cuDoubleComplex(left_bottom_corner.real, left_bottom_corner.imag)
    cdef cuDoubleComplex _right_upper_corner_ = cuDoubleComplex(right_upper_corner.real, right_upper_corner.imag)
    with nogil:
        __status__ = cusolverSpDcsreigsHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuDoubleComplex>_left_bottom_corner_, <cuDoubleComplex>_right_upper_corner_, <int*>num_eigs)
    check_status(__status__)


cpdef ccsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs):
    """See `cusolverSpCcsreigsHost`."""
    cdef cuComplex _left_bottom_corner_ = cuComplex(left_bottom_corner.real, left_bottom_corner.imag)
    cdef cuComplex _right_upper_corner_ = cuComplex(right_upper_corner.real, right_upper_corner.imag)
    with nogil:
        __status__ = cusolverSpCcsreigsHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuComplex>_left_bottom_corner_, <cuComplex>_right_upper_corner_, <int*>num_eigs)
    check_status(__status__)


cpdef zcsreigs_host(intptr_t handle, int m, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, complex left_bottom_corner, complex right_upper_corner, intptr_t num_eigs):
    """See `cusolverSpZcsreigsHost`."""
    cdef cuDoubleComplex _left_bottom_corner_ = cuDoubleComplex(left_bottom_corner.real, left_bottom_corner.imag)
    cdef cuDoubleComplex _right_upper_corner_ = cuDoubleComplex(right_upper_corner.real, right_upper_corner.imag)
    with nogil:
        __status__ = cusolverSpZcsreigsHost(<Handle>handle, m, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <cuDoubleComplex>_left_bottom_corner_, <cuDoubleComplex>_right_upper_corner_, <int*>num_eigs)
    check_status(__status__)


cpdef xcsrsymrcm_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p):
    """See `cusolverSpXcsrsymrcmHost`."""
    with nogil:
        __status__ = cusolverSpXcsrsymrcmHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p)
    check_status(__status__)


cpdef xcsrsymmdq_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p):
    """See `cusolverSpXcsrsymmdqHost`."""
    with nogil:
        __status__ = cusolverSpXcsrsymmdqHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p)
    check_status(__status__)


cpdef xcsrsymamd_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p):
    """See `cusolverSpXcsrsymamdHost`."""
    with nogil:
        __status__ = cusolverSpXcsrsymamdHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p)
    check_status(__status__)


cpdef xcsrmetisnd_host(intptr_t handle, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t options, intptr_t p):
    """See `cusolverSpXcsrmetisndHost`."""
    with nogil:
        __status__ = cusolverSpXcsrmetisndHost(<Handle>handle, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const int64_t*>options, <int*>p)
    check_status(__status__)


cpdef scsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz):
    """See `cusolverSpScsrzfdHost`."""
    with nogil:
        __status__ = cusolverSpScsrzfdHost(<Handle>handle, n, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p, <int*>numnz)
    check_status(__status__)


cpdef dcsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz):
    """See `cusolverSpDcsrzfdHost`."""
    with nogil:
        __status__ = cusolverSpDcsrzfdHost(<Handle>handle, n, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p, <int*>numnz)
    check_status(__status__)


cpdef ccsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz):
    """See `cusolverSpCcsrzfdHost`."""
    with nogil:
        __status__ = cusolverSpCcsrzfdHost(<Handle>handle, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p, <int*>numnz)
    check_status(__status__)


cpdef zcsrzfd_host(intptr_t handle, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t numnz):
    """See `cusolverSpZcsrzfdHost`."""
    with nogil:
        __status__ = cusolverSpZcsrzfdHost(<Handle>handle, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <int*>p, <int*>numnz)
    check_status(__status__)


cpdef size_t xcsrperm_buffer_size_host(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t q) except? 0:
    """See `cusolverSpXcsrperm_bufferSizeHost`."""
    cdef size_t buffer_size_in_bytes
    with nogil:
        __status__ = cusolverSpXcsrperm_bufferSizeHost(<Handle>handle, m, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const int*>p, <const int*>q, &buffer_size_in_bytes)
    check_status(__status__)
    return buffer_size_in_bytes


cpdef xcsrperm_host(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t p, intptr_t q, intptr_t map, intptr_t p_buffer):
    """See `cusolverSpXcsrpermHost`."""
    with nogil:
        __status__ = cusolverSpXcsrpermHost(<Handle>handle, m, n, nnz_a, <const cusparseMatDescr_t>descr_a, <int*>csr_row_ptr_a, <int*>csr_col_ind_a, <const int*>p, <const int*>q, <int*>map, <void*>p_buffer)
    check_status(__status__)


cpdef intptr_t create_csrqr_info() except? 0:
    """See `cusolverSpCreateCsrqrInfo`."""
    cdef csrqrInfo info
    with nogil:
        __status__ = cusolverSpCreateCsrqrInfo(&info)
    check_status(__status__)
    return <intptr_t>info


cpdef destroy_csrqr_info(intptr_t info):
    """See `cusolverSpDestroyCsrqrInfo`."""
    with nogil:
        __status__ = cusolverSpDestroyCsrqrInfo(<csrqrInfo>info)
    check_status(__status__)


cpdef xcsrqr_analysis_batched(intptr_t handle, int m, int n, int nnz_a, intptr_t descr_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t info):
    """See `cusolverSpXcsrqrAnalysisBatched`."""
    with nogil:
        __status__ = cusolverSpXcsrqrAnalysisBatched(<Handle>handle, m, n, nnz_a, <const cusparseMatDescr_t>descr_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <csrqrInfo>info)
    check_status(__status__)


cpdef tuple scsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info):
    """See `cusolverSpScsrqrBufferInfoBatched`."""
    cdef size_t internal_data_in_bytes
    cdef size_t workspace_in_bytes
    with nogil:
        __status__ = cusolverSpScsrqrBufferInfoBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, batch_size, <csrqrInfo>info, &internal_data_in_bytes, &workspace_in_bytes)
    check_status(__status__)
    return (internal_data_in_bytes, workspace_in_bytes)


cpdef tuple dcsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info):
    """See `cusolverSpDcsrqrBufferInfoBatched`."""
    cdef size_t internal_data_in_bytes
    cdef size_t workspace_in_bytes
    with nogil:
        __status__ = cusolverSpDcsrqrBufferInfoBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, batch_size, <csrqrInfo>info, &internal_data_in_bytes, &workspace_in_bytes)
    check_status(__status__)
    return (internal_data_in_bytes, workspace_in_bytes)


cpdef tuple ccsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info):
    """See `cusolverSpCcsrqrBufferInfoBatched`."""
    cdef size_t internal_data_in_bytes
    cdef size_t workspace_in_bytes
    with nogil:
        __status__ = cusolverSpCcsrqrBufferInfoBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, batch_size, <csrqrInfo>info, &internal_data_in_bytes, &workspace_in_bytes)
    check_status(__status__)
    return (internal_data_in_bytes, workspace_in_bytes)


cpdef tuple zcsrqr_buffer_info_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val, intptr_t csr_row_ptr, intptr_t csr_col_ind, int batch_size, intptr_t info):
    """See `cusolverSpZcsrqrBufferInfoBatched`."""
    cdef size_t internal_data_in_bytes
    cdef size_t workspace_in_bytes
    with nogil:
        __status__ = cusolverSpZcsrqrBufferInfoBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val, <const int*>csr_row_ptr, <const int*>csr_col_ind, batch_size, <csrqrInfo>info, &internal_data_in_bytes, &workspace_in_bytes)
    check_status(__status__)
    return (internal_data_in_bytes, workspace_in_bytes)


cpdef scsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer):
    """See `cusolverSpScsrqrsvBatched`."""
    with nogil:
        __status__ = cusolverSpScsrqrsvBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const float*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const float*>b, <float*>x, batch_size, <csrqrInfo>info, <void*>p_buffer)
    check_status(__status__)


cpdef dcsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer):
    """See `cusolverSpDcsrqrsvBatched`."""
    with nogil:
        __status__ = cusolverSpDcsrqrsvBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const double*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const double*>b, <double*>x, batch_size, <csrqrInfo>info, <void*>p_buffer)
    check_status(__status__)


cpdef ccsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer):
    """See `cusolverSpCcsrqrsvBatched`."""
    with nogil:
        __status__ = cusolverSpCcsrqrsvBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuComplex*>b, <cuComplex*>x, batch_size, <csrqrInfo>info, <void*>p_buffer)
    check_status(__status__)


cpdef zcsrqrsv_batched(intptr_t handle, int m, int n, int nnz, intptr_t descr_a, intptr_t csr_val_a, intptr_t csr_row_ptr_a, intptr_t csr_col_ind_a, intptr_t b, intptr_t x, int batch_size, intptr_t info, intptr_t p_buffer):
    """See `cusolverSpZcsrqrsvBatched`."""
    with nogil:
        __status__ = cusolverSpZcsrqrsvBatched(<Handle>handle, m, n, nnz, <const cusparseMatDescr_t>descr_a, <const cuDoubleComplex*>csr_val_a, <const int*>csr_row_ptr_a, <const int*>csr_col_ind_a, <const cuDoubleComplex*>b, <cuDoubleComplex*>x, batch_size, <csrqrInfo>info, <void*>p_buffer)
    check_status(__status__)
