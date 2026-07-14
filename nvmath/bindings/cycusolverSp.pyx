# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.1, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from ._internal cimport cusolverSp as _cusolverSp


###############################################################################
# Wrapper functions
###############################################################################

cdef cusolverStatus_t cusolverSpCreate(cusolverSpHandle_t* handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCreate(handle)


cdef cusolverStatus_t cusolverSpDestroy(cusolverSpHandle_t handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDestroy(handle)


cdef cusolverStatus_t cusolverSpSetStream(cusolverSpHandle_t handle, cudaStream_t streamId) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpSetStream(handle, streamId)


cdef cusolverStatus_t cusolverSpGetStream(cusolverSpHandle_t handle, cudaStream_t* streamId) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpGetStream(handle, streamId)


cdef cusolverStatus_t cusolverSpXcsrissymHost(cusolverSpHandle_t handle, int m, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrEndPtrA, const int* csrColIndA, int* issym) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrissymHost(handle, m, nnzA, descrA, csrRowPtrA, csrEndPtrA, csrColIndA, issym)


cdef cusolverStatus_t cusolverSpScsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsvluHost(handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpDcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsvluHost(handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpCcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsvluHost(handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpZcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsvluHost(handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpScsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsvqr(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpDcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsvqr(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpCcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsvqr(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpZcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsvqr(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpScsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsvqrHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpDcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsvqrHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpCcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsvqrHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpZcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsvqrHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpScsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsvcholHost(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpDcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsvcholHost(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpCcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsvcholHost(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpZcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsvcholHost(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpScsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsvchol(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpDcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsvchol(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpCcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsvchol(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpZcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsvchol(handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t cusolverSpScsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int* rankA, float* x, int* p, float* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrlsqvqrHost(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t cusolverSpDcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int* rankA, double* x, int* p, double* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrlsqvqrHost(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t cusolverSpCcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int* rankA, cuComplex* x, int* p, float* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrlsqvqrHost(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t cusolverSpZcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int* rankA, cuDoubleComplex* x, int* p, double* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrlsqvqrHost(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t cusolverSpScsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, float mu0, const float* x0, int maxite, float tol, float* mu, float* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsreigvsiHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t cusolverSpDcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, double mu0, const double* x0, int maxite, double tol, double* mu, double* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsreigvsiHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t cusolverSpCcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex mu0, const cuComplex* x0, int maxite, float tol, cuComplex* mu, cuComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsreigvsiHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t cusolverSpZcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex mu0, const cuDoubleComplex* x0, int maxite, double tol, cuDoubleComplex* mu, cuDoubleComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsreigvsiHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t cusolverSpScsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, float mu0, const float* x0, int maxite, float eps, float* mu, float* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsreigvsi(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t cusolverSpDcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, double mu0, const double* x0, int maxite, double eps, double* mu, double* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsreigvsi(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t cusolverSpCcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex mu0, const cuComplex* x0, int maxite, float eps, cuComplex* mu, cuComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsreigvsi(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t cusolverSpZcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex mu0, const cuDoubleComplex* x0, int maxite, double eps, cuDoubleComplex* mu, cuDoubleComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsreigvsi(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t cusolverSpScsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex left_bottom_corner, cuComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsreigsHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t cusolverSpDcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex left_bottom_corner, cuDoubleComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsreigsHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t cusolverSpCcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex left_bottom_corner, cuComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsreigsHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t cusolverSpZcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex left_bottom_corner, cuDoubleComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsreigsHost(handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t cusolverSpXcsrsymrcmHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrsymrcmHost(handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t cusolverSpXcsrsymmdqHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrsymmdqHost(handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t cusolverSpXcsrsymamdHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrsymamdHost(handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t cusolverSpXcsrmetisndHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, const int64_t* options, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrmetisndHost(handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, options, p)


cdef cusolverStatus_t cusolverSpScsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrzfdHost(handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t cusolverSpDcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrzfdHost(handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t cusolverSpCcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrzfdHost(handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t cusolverSpZcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrzfdHost(handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t cusolverSpXcsrperm_bufferSizeHost(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, const int* p, const int* q, size_t* bufferSizeInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrperm_bufferSizeHost(handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, p, q, bufferSizeInBytes)


cdef cusolverStatus_t cusolverSpXcsrpermHost(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, int* csrRowPtrA, int* csrColIndA, const int* p, const int* q, int* map, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrpermHost(handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, p, q, map, pBuffer)


cdef cusolverStatus_t cusolverSpCreateCsrqrInfo(csrqrInfo_t* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCreateCsrqrInfo(info)


cdef cusolverStatus_t cusolverSpDestroyCsrqrInfo(csrqrInfo_t info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDestroyCsrqrInfo(info)


cdef cusolverStatus_t cusolverSpXcsrqrAnalysisBatched(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, csrqrInfo_t info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpXcsrqrAnalysisBatched(handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, info)


cdef cusolverStatus_t cusolverSpScsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrqrBufferInfoBatched(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t cusolverSpDcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrqrBufferInfoBatched(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t cusolverSpCcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrqrBufferInfoBatched(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t cusolverSpZcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrqrBufferInfoBatched(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t cusolverSpScsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpScsrqrsvBatched(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t cusolverSpDcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpDcsrqrsvBatched(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t cusolverSpCcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, cuComplex* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpCcsrqrsvBatched(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t cusolverSpZcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, cuDoubleComplex* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    return _cusolverSp._cusolverSpZcsrqrsvBatched(handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)
