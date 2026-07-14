# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libc.stdint cimport intptr_t, uintptr_t

import os
import site
import threading

from .utils import FunctionNotFoundError, NotSupportedError

from cuda.pathfinder import load_nvidia_dynamic_lib

from libc.stddef cimport wchar_t
from libc.stdint cimport uintptr_t
from cpython cimport PyUnicode_AsWideCharString, PyMem_Free

# You must 'from .utils import NotSupportedError' before using this template

cdef extern from "windows.h" nogil:
    ctypedef void* HMODULE
    ctypedef void* HANDLE
    ctypedef void* FARPROC
    ctypedef unsigned long DWORD
    ctypedef const wchar_t *LPCWSTR
    ctypedef const char *LPCSTR

    cdef DWORD LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800
    cdef DWORD LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x00001000
    cdef DWORD LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR = 0x00000100

    HMODULE _LoadLibraryExW "LoadLibraryExW"(
        LPCWSTR lpLibFileName,
        HANDLE hFile,
        DWORD dwFlags
    )

    FARPROC _GetProcAddress "GetProcAddress"(HMODULE hModule, LPCSTR lpProcName)

cdef inline uintptr_t LoadLibraryExW(str path, HANDLE hFile, DWORD dwFlags):
    cdef uintptr_t result
    cdef wchar_t* wpath = PyUnicode_AsWideCharString(path, NULL)
    with nogil:
        result = <uintptr_t>_LoadLibraryExW(
            wpath,
            hFile,
            dwFlags
        )
    PyMem_Free(wpath)
    return result

cdef inline void *GetProcAddress(uintptr_t hModule, const char* lpProcName) nogil:
    return _GetProcAddress(<HMODULE>hModule, lpProcName)

cdef int get_cuda_version():
    cdef int err, driver_ver = 0

    # Load driver to check version
    handle = LoadLibraryExW("nvcuda.dll", NULL, LOAD_LIBRARY_SEARCH_SYSTEM32)
    if handle == 0:
        raise NotSupportedError('CUDA driver is not found')
    cuDriverGetVersion = GetProcAddress(handle, 'cuDriverGetVersion')
    if cuDriverGetVersion == NULL:
        raise RuntimeError('Did not find cuDriverGetVersion symbol in nvcuda.dll')
    err = (<int (*)(int*) noexcept nogil>cuDriverGetVersion)(&driver_ver)
    if err != 0:
        raise RuntimeError(f'cuDriverGetVersion returned error code {err}')

    return driver_ver


###############################################################################
# Wrapper init
###############################################################################

cdef object __symbol_lock = threading.Lock()
cdef bint __py_cusparse_init = False

cdef void* __cusparseCreate = NULL
cdef void* __cusparseDestroy = NULL
cdef void* __cusparseGetVersion = NULL
cdef void* __cusparseGetProperty = NULL
cdef void* __cusparseGetErrorName = NULL
cdef void* __cusparseGetErrorString = NULL
cdef void* __cusparseSetStream = NULL
cdef void* __cusparseGetStream = NULL
cdef void* __cusparseGetPointerMode = NULL
cdef void* __cusparseSetPointerMode = NULL
cdef void* __cusparseLoggerSetCallback = NULL
cdef void* __cusparseLoggerSetFile = NULL
cdef void* __cusparseLoggerOpenFile = NULL
cdef void* __cusparseLoggerSetLevel = NULL
cdef void* __cusparseLoggerSetMask = NULL
cdef void* __cusparseLoggerForceDisable = NULL
cdef void* __cusparseCreateMatDescr = NULL
cdef void* __cusparseDestroyMatDescr = NULL
cdef void* __cusparseSetMatType = NULL
cdef void* __cusparseGetMatType = NULL
cdef void* __cusparseSetMatFillMode = NULL
cdef void* __cusparseGetMatFillMode = NULL
cdef void* __cusparseSetMatDiagType = NULL
cdef void* __cusparseGetMatDiagType = NULL
cdef void* __cusparseSetMatIndexBase = NULL
cdef void* __cusparseGetMatIndexBase = NULL
cdef void* __cusparseCreateCsric02Info = NULL
cdef void* __cusparseDestroyCsric02Info = NULL
cdef void* __cusparseCreateBsric02Info = NULL
cdef void* __cusparseDestroyBsric02Info = NULL
cdef void* __cusparseCreateCsrilu02Info = NULL
cdef void* __cusparseDestroyCsrilu02Info = NULL
cdef void* __cusparseCreateBsrilu02Info = NULL
cdef void* __cusparseDestroyBsrilu02Info = NULL
cdef void* __cusparseCreateBsrsv2Info = NULL
cdef void* __cusparseDestroyBsrsv2Info = NULL
cdef void* __cusparseCreateBsrsm2Info = NULL
cdef void* __cusparseDestroyBsrsm2Info = NULL
cdef void* __cusparseCreateCsru2csrInfo = NULL
cdef void* __cusparseDestroyCsru2csrInfo = NULL
cdef void* __cusparseCreateColorInfo = NULL
cdef void* __cusparseDestroyColorInfo = NULL
cdef void* __cusparseSetColorAlgs = NULL
cdef void* __cusparseGetColorAlgs = NULL
cdef void* __cusparseCreatePruneInfo = NULL
cdef void* __cusparseDestroyPruneInfo = NULL
cdef void* __cusparseSgemvi = NULL
cdef void* __cusparseSgemvi_bufferSize = NULL
cdef void* __cusparseDgemvi = NULL
cdef void* __cusparseDgemvi_bufferSize = NULL
cdef void* __cusparseCgemvi = NULL
cdef void* __cusparseCgemvi_bufferSize = NULL
cdef void* __cusparseZgemvi = NULL
cdef void* __cusparseZgemvi_bufferSize = NULL
cdef void* __cusparseSbsrmv = NULL
cdef void* __cusparseDbsrmv = NULL
cdef void* __cusparseCbsrmv = NULL
cdef void* __cusparseZbsrmv = NULL
cdef void* __cusparseSbsrxmv = NULL
cdef void* __cusparseDbsrxmv = NULL
cdef void* __cusparseCbsrxmv = NULL
cdef void* __cusparseZbsrxmv = NULL
cdef void* __cusparseXbsrsv2_zeroPivot = NULL
cdef void* __cusparseSbsrsv2_bufferSize = NULL
cdef void* __cusparseDbsrsv2_bufferSize = NULL
cdef void* __cusparseCbsrsv2_bufferSize = NULL
cdef void* __cusparseZbsrsv2_bufferSize = NULL
cdef void* __cusparseSbsrsv2_bufferSizeExt = NULL
cdef void* __cusparseDbsrsv2_bufferSizeExt = NULL
cdef void* __cusparseCbsrsv2_bufferSizeExt = NULL
cdef void* __cusparseZbsrsv2_bufferSizeExt = NULL
cdef void* __cusparseSbsrsv2_analysis = NULL
cdef void* __cusparseDbsrsv2_analysis = NULL
cdef void* __cusparseCbsrsv2_analysis = NULL
cdef void* __cusparseZbsrsv2_analysis = NULL
cdef void* __cusparseSbsrsv2_solve = NULL
cdef void* __cusparseDbsrsv2_solve = NULL
cdef void* __cusparseCbsrsv2_solve = NULL
cdef void* __cusparseZbsrsv2_solve = NULL
cdef void* __cusparseSbsrmm = NULL
cdef void* __cusparseDbsrmm = NULL
cdef void* __cusparseCbsrmm = NULL
cdef void* __cusparseZbsrmm = NULL
cdef void* __cusparseXbsrsm2_zeroPivot = NULL
cdef void* __cusparseSbsrsm2_bufferSize = NULL
cdef void* __cusparseDbsrsm2_bufferSize = NULL
cdef void* __cusparseCbsrsm2_bufferSize = NULL
cdef void* __cusparseZbsrsm2_bufferSize = NULL
cdef void* __cusparseSbsrsm2_bufferSizeExt = NULL
cdef void* __cusparseDbsrsm2_bufferSizeExt = NULL
cdef void* __cusparseCbsrsm2_bufferSizeExt = NULL
cdef void* __cusparseZbsrsm2_bufferSizeExt = NULL
cdef void* __cusparseSbsrsm2_analysis = NULL
cdef void* __cusparseDbsrsm2_analysis = NULL
cdef void* __cusparseCbsrsm2_analysis = NULL
cdef void* __cusparseZbsrsm2_analysis = NULL
cdef void* __cusparseSbsrsm2_solve = NULL
cdef void* __cusparseDbsrsm2_solve = NULL
cdef void* __cusparseCbsrsm2_solve = NULL
cdef void* __cusparseZbsrsm2_solve = NULL
cdef void* __cusparseScsrilu02_numericBoost = NULL
cdef void* __cusparseDcsrilu02_numericBoost = NULL
cdef void* __cusparseCcsrilu02_numericBoost = NULL
cdef void* __cusparseZcsrilu02_numericBoost = NULL
cdef void* __cusparseXcsrilu02_zeroPivot = NULL
cdef void* __cusparseScsrilu02_bufferSize = NULL
cdef void* __cusparseDcsrilu02_bufferSize = NULL
cdef void* __cusparseCcsrilu02_bufferSize = NULL
cdef void* __cusparseZcsrilu02_bufferSize = NULL
cdef void* __cusparseScsrilu02_bufferSizeExt = NULL
cdef void* __cusparseDcsrilu02_bufferSizeExt = NULL
cdef void* __cusparseCcsrilu02_bufferSizeExt = NULL
cdef void* __cusparseZcsrilu02_bufferSizeExt = NULL
cdef void* __cusparseScsrilu02_analysis = NULL
cdef void* __cusparseDcsrilu02_analysis = NULL
cdef void* __cusparseCcsrilu02_analysis = NULL
cdef void* __cusparseZcsrilu02_analysis = NULL
cdef void* __cusparseScsrilu02 = NULL
cdef void* __cusparseDcsrilu02 = NULL
cdef void* __cusparseCcsrilu02 = NULL
cdef void* __cusparseZcsrilu02 = NULL
cdef void* __cusparseSbsrilu02_numericBoost = NULL
cdef void* __cusparseDbsrilu02_numericBoost = NULL
cdef void* __cusparseCbsrilu02_numericBoost = NULL
cdef void* __cusparseZbsrilu02_numericBoost = NULL
cdef void* __cusparseXbsrilu02_zeroPivot = NULL
cdef void* __cusparseSbsrilu02_bufferSize = NULL
cdef void* __cusparseDbsrilu02_bufferSize = NULL
cdef void* __cusparseCbsrilu02_bufferSize = NULL
cdef void* __cusparseZbsrilu02_bufferSize = NULL
cdef void* __cusparseSbsrilu02_bufferSizeExt = NULL
cdef void* __cusparseDbsrilu02_bufferSizeExt = NULL
cdef void* __cusparseCbsrilu02_bufferSizeExt = NULL
cdef void* __cusparseZbsrilu02_bufferSizeExt = NULL
cdef void* __cusparseSbsrilu02_analysis = NULL
cdef void* __cusparseDbsrilu02_analysis = NULL
cdef void* __cusparseCbsrilu02_analysis = NULL
cdef void* __cusparseZbsrilu02_analysis = NULL
cdef void* __cusparseSbsrilu02 = NULL
cdef void* __cusparseDbsrilu02 = NULL
cdef void* __cusparseCbsrilu02 = NULL
cdef void* __cusparseZbsrilu02 = NULL
cdef void* __cusparseXcsric02_zeroPivot = NULL
cdef void* __cusparseScsric02_bufferSize = NULL
cdef void* __cusparseDcsric02_bufferSize = NULL
cdef void* __cusparseCcsric02_bufferSize = NULL
cdef void* __cusparseZcsric02_bufferSize = NULL
cdef void* __cusparseScsric02_bufferSizeExt = NULL
cdef void* __cusparseDcsric02_bufferSizeExt = NULL
cdef void* __cusparseCcsric02_bufferSizeExt = NULL
cdef void* __cusparseZcsric02_bufferSizeExt = NULL
cdef void* __cusparseScsric02_analysis = NULL
cdef void* __cusparseDcsric02_analysis = NULL
cdef void* __cusparseCcsric02_analysis = NULL
cdef void* __cusparseZcsric02_analysis = NULL
cdef void* __cusparseScsric02 = NULL
cdef void* __cusparseDcsric02 = NULL
cdef void* __cusparseCcsric02 = NULL
cdef void* __cusparseZcsric02 = NULL
cdef void* __cusparseXbsric02_zeroPivot = NULL
cdef void* __cusparseSbsric02_bufferSize = NULL
cdef void* __cusparseDbsric02_bufferSize = NULL
cdef void* __cusparseCbsric02_bufferSize = NULL
cdef void* __cusparseZbsric02_bufferSize = NULL
cdef void* __cusparseSbsric02_bufferSizeExt = NULL
cdef void* __cusparseDbsric02_bufferSizeExt = NULL
cdef void* __cusparseCbsric02_bufferSizeExt = NULL
cdef void* __cusparseZbsric02_bufferSizeExt = NULL
cdef void* __cusparseSbsric02_analysis = NULL
cdef void* __cusparseDbsric02_analysis = NULL
cdef void* __cusparseCbsric02_analysis = NULL
cdef void* __cusparseZbsric02_analysis = NULL
cdef void* __cusparseSbsric02 = NULL
cdef void* __cusparseDbsric02 = NULL
cdef void* __cusparseCbsric02 = NULL
cdef void* __cusparseZbsric02 = NULL
cdef void* __cusparseSgtsv2_bufferSizeExt = NULL
cdef void* __cusparseDgtsv2_bufferSizeExt = NULL
cdef void* __cusparseCgtsv2_bufferSizeExt = NULL
cdef void* __cusparseZgtsv2_bufferSizeExt = NULL
cdef void* __cusparseSgtsv2 = NULL
cdef void* __cusparseDgtsv2 = NULL
cdef void* __cusparseCgtsv2 = NULL
cdef void* __cusparseZgtsv2 = NULL
cdef void* __cusparseSgtsv2_nopivot_bufferSizeExt = NULL
cdef void* __cusparseDgtsv2_nopivot_bufferSizeExt = NULL
cdef void* __cusparseCgtsv2_nopivot_bufferSizeExt = NULL
cdef void* __cusparseZgtsv2_nopivot_bufferSizeExt = NULL
cdef void* __cusparseSgtsv2_nopivot = NULL
cdef void* __cusparseDgtsv2_nopivot = NULL
cdef void* __cusparseCgtsv2_nopivot = NULL
cdef void* __cusparseZgtsv2_nopivot = NULL
cdef void* __cusparseSgtsv2StridedBatch_bufferSizeExt = NULL
cdef void* __cusparseDgtsv2StridedBatch_bufferSizeExt = NULL
cdef void* __cusparseCgtsv2StridedBatch_bufferSizeExt = NULL
cdef void* __cusparseZgtsv2StridedBatch_bufferSizeExt = NULL
cdef void* __cusparseSgtsv2StridedBatch = NULL
cdef void* __cusparseDgtsv2StridedBatch = NULL
cdef void* __cusparseCgtsv2StridedBatch = NULL
cdef void* __cusparseZgtsv2StridedBatch = NULL
cdef void* __cusparseSgtsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseDgtsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseCgtsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseZgtsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseSgtsvInterleavedBatch = NULL
cdef void* __cusparseDgtsvInterleavedBatch = NULL
cdef void* __cusparseCgtsvInterleavedBatch = NULL
cdef void* __cusparseZgtsvInterleavedBatch = NULL
cdef void* __cusparseSgpsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseDgpsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseCgpsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseZgpsvInterleavedBatch_bufferSizeExt = NULL
cdef void* __cusparseSgpsvInterleavedBatch = NULL
cdef void* __cusparseDgpsvInterleavedBatch = NULL
cdef void* __cusparseCgpsvInterleavedBatch = NULL
cdef void* __cusparseZgpsvInterleavedBatch = NULL
cdef void* __cusparseScsrgeam2_bufferSizeExt = NULL
cdef void* __cusparseDcsrgeam2_bufferSizeExt = NULL
cdef void* __cusparseCcsrgeam2_bufferSizeExt = NULL
cdef void* __cusparseZcsrgeam2_bufferSizeExt = NULL
cdef void* __cusparseXcsrgeam2Nnz = NULL
cdef void* __cusparseScsrgeam2 = NULL
cdef void* __cusparseDcsrgeam2 = NULL
cdef void* __cusparseCcsrgeam2 = NULL
cdef void* __cusparseZcsrgeam2 = NULL
cdef void* __cusparseScsrcolor = NULL
cdef void* __cusparseDcsrcolor = NULL
cdef void* __cusparseCcsrcolor = NULL
cdef void* __cusparseZcsrcolor = NULL
cdef void* __cusparseSnnz = NULL
cdef void* __cusparseDnnz = NULL
cdef void* __cusparseCnnz = NULL
cdef void* __cusparseZnnz = NULL
cdef void* __cusparseSnnz_compress = NULL
cdef void* __cusparseDnnz_compress = NULL
cdef void* __cusparseCnnz_compress = NULL
cdef void* __cusparseZnnz_compress = NULL
cdef void* __cusparseScsr2csr_compress = NULL
cdef void* __cusparseDcsr2csr_compress = NULL
cdef void* __cusparseCcsr2csr_compress = NULL
cdef void* __cusparseZcsr2csr_compress = NULL
cdef void* __cusparseXcoo2csr = NULL
cdef void* __cusparseXcsr2coo = NULL
cdef void* __cusparseXcsr2bsrNnz = NULL
cdef void* __cusparseScsr2bsr = NULL
cdef void* __cusparseDcsr2bsr = NULL
cdef void* __cusparseCcsr2bsr = NULL
cdef void* __cusparseZcsr2bsr = NULL
cdef void* __cusparseSbsr2csr = NULL
cdef void* __cusparseDbsr2csr = NULL
cdef void* __cusparseCbsr2csr = NULL
cdef void* __cusparseZbsr2csr = NULL
cdef void* __cusparseSgebsr2gebsc_bufferSize = NULL
cdef void* __cusparseDgebsr2gebsc_bufferSize = NULL
cdef void* __cusparseCgebsr2gebsc_bufferSize = NULL
cdef void* __cusparseZgebsr2gebsc_bufferSize = NULL
cdef void* __cusparseSgebsr2gebsc_bufferSizeExt = NULL
cdef void* __cusparseDgebsr2gebsc_bufferSizeExt = NULL
cdef void* __cusparseCgebsr2gebsc_bufferSizeExt = NULL
cdef void* __cusparseZgebsr2gebsc_bufferSizeExt = NULL
cdef void* __cusparseSgebsr2gebsc = NULL
cdef void* __cusparseDgebsr2gebsc = NULL
cdef void* __cusparseCgebsr2gebsc = NULL
cdef void* __cusparseZgebsr2gebsc = NULL
cdef void* __cusparseXgebsr2csr = NULL
cdef void* __cusparseSgebsr2csr = NULL
cdef void* __cusparseDgebsr2csr = NULL
cdef void* __cusparseCgebsr2csr = NULL
cdef void* __cusparseZgebsr2csr = NULL
cdef void* __cusparseScsr2gebsr_bufferSize = NULL
cdef void* __cusparseDcsr2gebsr_bufferSize = NULL
cdef void* __cusparseCcsr2gebsr_bufferSize = NULL
cdef void* __cusparseZcsr2gebsr_bufferSize = NULL
cdef void* __cusparseScsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseDcsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseCcsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseZcsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseXcsr2gebsrNnz = NULL
cdef void* __cusparseScsr2gebsr = NULL
cdef void* __cusparseDcsr2gebsr = NULL
cdef void* __cusparseCcsr2gebsr = NULL
cdef void* __cusparseZcsr2gebsr = NULL
cdef void* __cusparseSgebsr2gebsr_bufferSize = NULL
cdef void* __cusparseDgebsr2gebsr_bufferSize = NULL
cdef void* __cusparseCgebsr2gebsr_bufferSize = NULL
cdef void* __cusparseZgebsr2gebsr_bufferSize = NULL
cdef void* __cusparseSgebsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseDgebsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseCgebsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseZgebsr2gebsr_bufferSizeExt = NULL
cdef void* __cusparseXgebsr2gebsrNnz = NULL
cdef void* __cusparseSgebsr2gebsr = NULL
cdef void* __cusparseDgebsr2gebsr = NULL
cdef void* __cusparseCgebsr2gebsr = NULL
cdef void* __cusparseZgebsr2gebsr = NULL
cdef void* __cusparseCreateIdentityPermutation = NULL
cdef void* __cusparseXcoosort_bufferSizeExt = NULL
cdef void* __cusparseXcoosortByRow = NULL
cdef void* __cusparseXcoosortByColumn = NULL
cdef void* __cusparseXcsrsort_bufferSizeExt = NULL
cdef void* __cusparseXcsrsort = NULL
cdef void* __cusparseXcscsort_bufferSizeExt = NULL
cdef void* __cusparseXcscsort = NULL
cdef void* __cusparseScsru2csr_bufferSizeExt = NULL
cdef void* __cusparseDcsru2csr_bufferSizeExt = NULL
cdef void* __cusparseCcsru2csr_bufferSizeExt = NULL
cdef void* __cusparseZcsru2csr_bufferSizeExt = NULL
cdef void* __cusparseScsru2csr = NULL
cdef void* __cusparseDcsru2csr = NULL
cdef void* __cusparseCcsru2csr = NULL
cdef void* __cusparseZcsru2csr = NULL
cdef void* __cusparseScsr2csru = NULL
cdef void* __cusparseDcsr2csru = NULL
cdef void* __cusparseCcsr2csru = NULL
cdef void* __cusparseZcsr2csru = NULL
cdef void* __cusparseSpruneDense2csr_bufferSizeExt = NULL
cdef void* __cusparseDpruneDense2csr_bufferSizeExt = NULL
cdef void* __cusparseSpruneDense2csrNnz = NULL
cdef void* __cusparseDpruneDense2csrNnz = NULL
cdef void* __cusparseSpruneDense2csr = NULL
cdef void* __cusparseDpruneDense2csr = NULL
cdef void* __cusparseSpruneCsr2csr_bufferSizeExt = NULL
cdef void* __cusparseDpruneCsr2csr_bufferSizeExt = NULL
cdef void* __cusparseSpruneCsr2csrNnz = NULL
cdef void* __cusparseDpruneCsr2csrNnz = NULL
cdef void* __cusparseSpruneCsr2csr = NULL
cdef void* __cusparseDpruneCsr2csr = NULL
cdef void* __cusparseSpruneDense2csrByPercentage_bufferSizeExt = NULL
cdef void* __cusparseDpruneDense2csrByPercentage_bufferSizeExt = NULL
cdef void* __cusparseSpruneDense2csrNnzByPercentage = NULL
cdef void* __cusparseDpruneDense2csrNnzByPercentage = NULL
cdef void* __cusparseSpruneDense2csrByPercentage = NULL
cdef void* __cusparseDpruneDense2csrByPercentage = NULL
cdef void* __cusparseSpruneCsr2csrByPercentage_bufferSizeExt = NULL
cdef void* __cusparseDpruneCsr2csrByPercentage_bufferSizeExt = NULL
cdef void* __cusparseSpruneCsr2csrNnzByPercentage = NULL
cdef void* __cusparseDpruneCsr2csrNnzByPercentage = NULL
cdef void* __cusparseSpruneCsr2csrByPercentage = NULL
cdef void* __cusparseDpruneCsr2csrByPercentage = NULL
cdef void* __cusparseCsr2cscEx2 = NULL
cdef void* __cusparseCsr2cscEx2_bufferSize = NULL
cdef void* __cusparseCreateSpVec = NULL
cdef void* __cusparseCreateConstSpVec = NULL
cdef void* __cusparseDestroySpVec = NULL
cdef void* __cusparseSpVecGet = NULL
cdef void* __cusparseConstSpVecGet = NULL
cdef void* __cusparseSpVecGetIndexBase = NULL
cdef void* __cusparseSpVecGetValues = NULL
cdef void* __cusparseConstSpVecGetValues = NULL
cdef void* __cusparseSpVecSetValues = NULL
cdef void* __cusparseCreateDnVec = NULL
cdef void* __cusparseCreateConstDnVec = NULL
cdef void* __cusparseDestroyDnVec = NULL
cdef void* __cusparseDnVecGet = NULL
cdef void* __cusparseConstDnVecGet = NULL
cdef void* __cusparseDnVecGetValues = NULL
cdef void* __cusparseConstDnVecGetValues = NULL
cdef void* __cusparseDnVecSetValues = NULL
cdef void* __cusparseDestroySpMat = NULL
cdef void* __cusparseSpMatGetFormat = NULL
cdef void* __cusparseSpMatGetIndexBase = NULL
cdef void* __cusparseSpMatGetValues = NULL
cdef void* __cusparseConstSpMatGetValues = NULL
cdef void* __cusparseSpMatSetValues = NULL
cdef void* __cusparseSpMatGetSize = NULL
cdef void* __cusparseSpMatGetStridedBatch = NULL
cdef void* __cusparseCooSetStridedBatch = NULL
cdef void* __cusparseCsrSetStridedBatch = NULL
cdef void* __cusparseSpMatGetAttribute = NULL
cdef void* __cusparseSpMatSetAttribute = NULL
cdef void* __cusparseCreateCsr = NULL
cdef void* __cusparseCreateConstCsr = NULL
cdef void* __cusparseCreateCsc = NULL
cdef void* __cusparseCreateConstCsc = NULL
cdef void* __cusparseCsrGet = NULL
cdef void* __cusparseConstCsrGet = NULL
cdef void* __cusparseCscGet = NULL
cdef void* __cusparseConstCscGet = NULL
cdef void* __cusparseCsrSetPointers = NULL
cdef void* __cusparseCscSetPointers = NULL
cdef void* __cusparseCreateCoo = NULL
cdef void* __cusparseCreateConstCoo = NULL
cdef void* __cusparseCooGet = NULL
cdef void* __cusparseConstCooGet = NULL
cdef void* __cusparseCooSetPointers = NULL
cdef void* __cusparseCreateBlockedEll = NULL
cdef void* __cusparseCreateConstBlockedEll = NULL
cdef void* __cusparseBlockedEllGet = NULL
cdef void* __cusparseConstBlockedEllGet = NULL
cdef void* __cusparseCreateDnMat = NULL
cdef void* __cusparseCreateConstDnMat = NULL
cdef void* __cusparseDestroyDnMat = NULL
cdef void* __cusparseDnMatGet = NULL
cdef void* __cusparseConstDnMatGet = NULL
cdef void* __cusparseDnMatGetValues = NULL
cdef void* __cusparseConstDnMatGetValues = NULL
cdef void* __cusparseDnMatSetValues = NULL
cdef void* __cusparseDnMatSetStridedBatch = NULL
cdef void* __cusparseDnMatGetStridedBatch = NULL
cdef void* __cusparseAxpby = NULL
cdef void* __cusparseGather = NULL
cdef void* __cusparseScatter = NULL
cdef void* __cusparseRot = NULL
cdef void* __cusparseSpVV_bufferSize = NULL
cdef void* __cusparseSpVV = NULL
cdef void* __cusparseSparseToDense_bufferSize = NULL
cdef void* __cusparseSparseToDense = NULL
cdef void* __cusparseDenseToSparse_bufferSize = NULL
cdef void* __cusparseDenseToSparse_analysis = NULL
cdef void* __cusparseDenseToSparse_convert = NULL
cdef void* __cusparseSpMV = NULL
cdef void* __cusparseSpMV_bufferSize = NULL
cdef void* __cusparseSpSV_createDescr = NULL
cdef void* __cusparseSpSV_destroyDescr = NULL
cdef void* __cusparseSpSV_bufferSize = NULL
cdef void* __cusparseSpSV_analysis = NULL
cdef void* __cusparseSpSV_solve = NULL
cdef void* __cusparseSpSM_createDescr = NULL
cdef void* __cusparseSpSM_destroyDescr = NULL
cdef void* __cusparseSpSM_bufferSize = NULL
cdef void* __cusparseSpSM_analysis = NULL
cdef void* __cusparseSpSM_solve = NULL
cdef void* __cusparseSpMM_bufferSize = NULL
cdef void* __cusparseSpMM_preprocess = NULL
cdef void* __cusparseSpMM = NULL
cdef void* __cusparseSpGEMM_createDescr = NULL
cdef void* __cusparseSpGEMM_destroyDescr = NULL
cdef void* __cusparseSpGEMM_workEstimation = NULL
cdef void* __cusparseSpGEMM_getNumProducts = NULL
cdef void* __cusparseSpGEMM_estimateMemory = NULL
cdef void* __cusparseSpGEMM_compute = NULL
cdef void* __cusparseSpGEMM_copy = NULL
cdef void* __cusparseSpGEMMreuse_workEstimation = NULL
cdef void* __cusparseSpGEMMreuse_nnz = NULL
cdef void* __cusparseSpGEMMreuse_copy = NULL
cdef void* __cusparseSpGEMMreuse_compute = NULL
cdef void* __cusparseSDDMM_bufferSize = NULL
cdef void* __cusparseSDDMM_preprocess = NULL
cdef void* __cusparseSDDMM = NULL
cdef void* __cusparseSpMMOp_createPlan = NULL
cdef void* __cusparseSpMMOp = NULL
cdef void* __cusparseSpMMOp_destroyPlan = NULL
cdef void* __cusparseBsrSetStridedBatch = NULL
cdef void* __cusparseCreateBsr = NULL
cdef void* __cusparseCreateConstBsr = NULL
cdef void* __cusparseCreateSlicedEll = NULL
cdef void* __cusparseCreateConstSlicedEll = NULL
cdef void* __cusparseSpSV_updateMatrix = NULL
cdef void* __cusparseSpMV_preprocess = NULL
cdef void* __cusparseSpSM_updateMatrix = NULL
cdef void* __cusparseSpMVOp_createDescr = NULL
cdef void* __cusparseSpMVOp_destroyDescr = NULL
cdef void* __cusparseSpMVOp_createPlan = NULL
cdef void* __cusparseSpMVOp_destroyPlan = NULL
cdef void* __cusparseSpMVOp_setGlobalUserData = NULL
cdef void* __cusparseSpMVOp = NULL
cdef void* __cusparseSpMVOp_bufferSize = NULL


cdef inline list get_site_packages():
    return [site.getusersitepackages()] + site.getsitepackages()


cdef void* load_library(const int driver_ver) except* with gil:
    cdef uintptr_t handle = load_nvidia_dynamic_lib("cusparse")._handle_uint
    return <void*>handle


cdef int _check_or_init_cusparse() except -1 nogil:
    global __py_cusparse_init
    if __py_cusparse_init:
        return 0

    with gil, __symbol_lock:
        # Recheck the flag after obtaining the locks
        if __py_cusparse_init:
            return 0

        driver_ver = get_cuda_version()

        # Load library
        handle = <intptr_t>load_library(driver_ver)

        # Load function
        global __cusparseCreate
        __cusparseCreate = GetProcAddress(handle, 'cusparseCreate')

        global __cusparseDestroy
        __cusparseDestroy = GetProcAddress(handle, 'cusparseDestroy')

        global __cusparseGetVersion
        __cusparseGetVersion = GetProcAddress(handle, 'cusparseGetVersion')

        global __cusparseGetProperty
        __cusparseGetProperty = GetProcAddress(handle, 'cusparseGetProperty')

        global __cusparseGetErrorName
        __cusparseGetErrorName = GetProcAddress(handle, 'cusparseGetErrorName')

        global __cusparseGetErrorString
        __cusparseGetErrorString = GetProcAddress(handle, 'cusparseGetErrorString')

        global __cusparseSetStream
        __cusparseSetStream = GetProcAddress(handle, 'cusparseSetStream')

        global __cusparseGetStream
        __cusparseGetStream = GetProcAddress(handle, 'cusparseGetStream')

        global __cusparseGetPointerMode
        __cusparseGetPointerMode = GetProcAddress(handle, 'cusparseGetPointerMode')

        global __cusparseSetPointerMode
        __cusparseSetPointerMode = GetProcAddress(handle, 'cusparseSetPointerMode')

        global __cusparseLoggerSetCallback
        __cusparseLoggerSetCallback = GetProcAddress(handle, 'cusparseLoggerSetCallback')

        global __cusparseLoggerSetFile
        __cusparseLoggerSetFile = GetProcAddress(handle, 'cusparseLoggerSetFile')

        global __cusparseLoggerOpenFile
        __cusparseLoggerOpenFile = GetProcAddress(handle, 'cusparseLoggerOpenFile')

        global __cusparseLoggerSetLevel
        __cusparseLoggerSetLevel = GetProcAddress(handle, 'cusparseLoggerSetLevel')

        global __cusparseLoggerSetMask
        __cusparseLoggerSetMask = GetProcAddress(handle, 'cusparseLoggerSetMask')

        global __cusparseLoggerForceDisable
        __cusparseLoggerForceDisable = GetProcAddress(handle, 'cusparseLoggerForceDisable')

        global __cusparseCreateMatDescr
        __cusparseCreateMatDescr = GetProcAddress(handle, 'cusparseCreateMatDescr')

        global __cusparseDestroyMatDescr
        __cusparseDestroyMatDescr = GetProcAddress(handle, 'cusparseDestroyMatDescr')

        global __cusparseSetMatType
        __cusparseSetMatType = GetProcAddress(handle, 'cusparseSetMatType')

        global __cusparseGetMatType
        __cusparseGetMatType = GetProcAddress(handle, 'cusparseGetMatType')

        global __cusparseSetMatFillMode
        __cusparseSetMatFillMode = GetProcAddress(handle, 'cusparseSetMatFillMode')

        global __cusparseGetMatFillMode
        __cusparseGetMatFillMode = GetProcAddress(handle, 'cusparseGetMatFillMode')

        global __cusparseSetMatDiagType
        __cusparseSetMatDiagType = GetProcAddress(handle, 'cusparseSetMatDiagType')

        global __cusparseGetMatDiagType
        __cusparseGetMatDiagType = GetProcAddress(handle, 'cusparseGetMatDiagType')

        global __cusparseSetMatIndexBase
        __cusparseSetMatIndexBase = GetProcAddress(handle, 'cusparseSetMatIndexBase')

        global __cusparseGetMatIndexBase
        __cusparseGetMatIndexBase = GetProcAddress(handle, 'cusparseGetMatIndexBase')

        global __cusparseCreateCsric02Info
        __cusparseCreateCsric02Info = GetProcAddress(handle, 'cusparseCreateCsric02Info')

        global __cusparseDestroyCsric02Info
        __cusparseDestroyCsric02Info = GetProcAddress(handle, 'cusparseDestroyCsric02Info')

        global __cusparseCreateBsric02Info
        __cusparseCreateBsric02Info = GetProcAddress(handle, 'cusparseCreateBsric02Info')

        global __cusparseDestroyBsric02Info
        __cusparseDestroyBsric02Info = GetProcAddress(handle, 'cusparseDestroyBsric02Info')

        global __cusparseCreateCsrilu02Info
        __cusparseCreateCsrilu02Info = GetProcAddress(handle, 'cusparseCreateCsrilu02Info')

        global __cusparseDestroyCsrilu02Info
        __cusparseDestroyCsrilu02Info = GetProcAddress(handle, 'cusparseDestroyCsrilu02Info')

        global __cusparseCreateBsrilu02Info
        __cusparseCreateBsrilu02Info = GetProcAddress(handle, 'cusparseCreateBsrilu02Info')

        global __cusparseDestroyBsrilu02Info
        __cusparseDestroyBsrilu02Info = GetProcAddress(handle, 'cusparseDestroyBsrilu02Info')

        global __cusparseCreateBsrsv2Info
        __cusparseCreateBsrsv2Info = GetProcAddress(handle, 'cusparseCreateBsrsv2Info')

        global __cusparseDestroyBsrsv2Info
        __cusparseDestroyBsrsv2Info = GetProcAddress(handle, 'cusparseDestroyBsrsv2Info')

        global __cusparseCreateBsrsm2Info
        __cusparseCreateBsrsm2Info = GetProcAddress(handle, 'cusparseCreateBsrsm2Info')

        global __cusparseDestroyBsrsm2Info
        __cusparseDestroyBsrsm2Info = GetProcAddress(handle, 'cusparseDestroyBsrsm2Info')

        global __cusparseCreateCsru2csrInfo
        __cusparseCreateCsru2csrInfo = GetProcAddress(handle, 'cusparseCreateCsru2csrInfo')

        global __cusparseDestroyCsru2csrInfo
        __cusparseDestroyCsru2csrInfo = GetProcAddress(handle, 'cusparseDestroyCsru2csrInfo')

        global __cusparseCreateColorInfo
        __cusparseCreateColorInfo = GetProcAddress(handle, 'cusparseCreateColorInfo')

        global __cusparseDestroyColorInfo
        __cusparseDestroyColorInfo = GetProcAddress(handle, 'cusparseDestroyColorInfo')

        global __cusparseSetColorAlgs
        __cusparseSetColorAlgs = GetProcAddress(handle, 'cusparseSetColorAlgs')

        global __cusparseGetColorAlgs
        __cusparseGetColorAlgs = GetProcAddress(handle, 'cusparseGetColorAlgs')

        global __cusparseCreatePruneInfo
        __cusparseCreatePruneInfo = GetProcAddress(handle, 'cusparseCreatePruneInfo')

        global __cusparseDestroyPruneInfo
        __cusparseDestroyPruneInfo = GetProcAddress(handle, 'cusparseDestroyPruneInfo')

        global __cusparseSgemvi
        __cusparseSgemvi = GetProcAddress(handle, 'cusparseSgemvi')

        global __cusparseSgemvi_bufferSize
        __cusparseSgemvi_bufferSize = GetProcAddress(handle, 'cusparseSgemvi_bufferSize')

        global __cusparseDgemvi
        __cusparseDgemvi = GetProcAddress(handle, 'cusparseDgemvi')

        global __cusparseDgemvi_bufferSize
        __cusparseDgemvi_bufferSize = GetProcAddress(handle, 'cusparseDgemvi_bufferSize')

        global __cusparseCgemvi
        __cusparseCgemvi = GetProcAddress(handle, 'cusparseCgemvi')

        global __cusparseCgemvi_bufferSize
        __cusparseCgemvi_bufferSize = GetProcAddress(handle, 'cusparseCgemvi_bufferSize')

        global __cusparseZgemvi
        __cusparseZgemvi = GetProcAddress(handle, 'cusparseZgemvi')

        global __cusparseZgemvi_bufferSize
        __cusparseZgemvi_bufferSize = GetProcAddress(handle, 'cusparseZgemvi_bufferSize')

        global __cusparseSbsrmv
        __cusparseSbsrmv = GetProcAddress(handle, 'cusparseSbsrmv')

        global __cusparseDbsrmv
        __cusparseDbsrmv = GetProcAddress(handle, 'cusparseDbsrmv')

        global __cusparseCbsrmv
        __cusparseCbsrmv = GetProcAddress(handle, 'cusparseCbsrmv')

        global __cusparseZbsrmv
        __cusparseZbsrmv = GetProcAddress(handle, 'cusparseZbsrmv')

        global __cusparseSbsrxmv
        __cusparseSbsrxmv = GetProcAddress(handle, 'cusparseSbsrxmv')

        global __cusparseDbsrxmv
        __cusparseDbsrxmv = GetProcAddress(handle, 'cusparseDbsrxmv')

        global __cusparseCbsrxmv
        __cusparseCbsrxmv = GetProcAddress(handle, 'cusparseCbsrxmv')

        global __cusparseZbsrxmv
        __cusparseZbsrxmv = GetProcAddress(handle, 'cusparseZbsrxmv')

        global __cusparseXbsrsv2_zeroPivot
        __cusparseXbsrsv2_zeroPivot = GetProcAddress(handle, 'cusparseXbsrsv2_zeroPivot')

        global __cusparseSbsrsv2_bufferSize
        __cusparseSbsrsv2_bufferSize = GetProcAddress(handle, 'cusparseSbsrsv2_bufferSize')

        global __cusparseDbsrsv2_bufferSize
        __cusparseDbsrsv2_bufferSize = GetProcAddress(handle, 'cusparseDbsrsv2_bufferSize')

        global __cusparseCbsrsv2_bufferSize
        __cusparseCbsrsv2_bufferSize = GetProcAddress(handle, 'cusparseCbsrsv2_bufferSize')

        global __cusparseZbsrsv2_bufferSize
        __cusparseZbsrsv2_bufferSize = GetProcAddress(handle, 'cusparseZbsrsv2_bufferSize')

        global __cusparseSbsrsv2_bufferSizeExt
        __cusparseSbsrsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseSbsrsv2_bufferSizeExt')

        global __cusparseDbsrsv2_bufferSizeExt
        __cusparseDbsrsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseDbsrsv2_bufferSizeExt')

        global __cusparseCbsrsv2_bufferSizeExt
        __cusparseCbsrsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseCbsrsv2_bufferSizeExt')

        global __cusparseZbsrsv2_bufferSizeExt
        __cusparseZbsrsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseZbsrsv2_bufferSizeExt')

        global __cusparseSbsrsv2_analysis
        __cusparseSbsrsv2_analysis = GetProcAddress(handle, 'cusparseSbsrsv2_analysis')

        global __cusparseDbsrsv2_analysis
        __cusparseDbsrsv2_analysis = GetProcAddress(handle, 'cusparseDbsrsv2_analysis')

        global __cusparseCbsrsv2_analysis
        __cusparseCbsrsv2_analysis = GetProcAddress(handle, 'cusparseCbsrsv2_analysis')

        global __cusparseZbsrsv2_analysis
        __cusparseZbsrsv2_analysis = GetProcAddress(handle, 'cusparseZbsrsv2_analysis')

        global __cusparseSbsrsv2_solve
        __cusparseSbsrsv2_solve = GetProcAddress(handle, 'cusparseSbsrsv2_solve')

        global __cusparseDbsrsv2_solve
        __cusparseDbsrsv2_solve = GetProcAddress(handle, 'cusparseDbsrsv2_solve')

        global __cusparseCbsrsv2_solve
        __cusparseCbsrsv2_solve = GetProcAddress(handle, 'cusparseCbsrsv2_solve')

        global __cusparseZbsrsv2_solve
        __cusparseZbsrsv2_solve = GetProcAddress(handle, 'cusparseZbsrsv2_solve')

        global __cusparseSbsrmm
        __cusparseSbsrmm = GetProcAddress(handle, 'cusparseSbsrmm')

        global __cusparseDbsrmm
        __cusparseDbsrmm = GetProcAddress(handle, 'cusparseDbsrmm')

        global __cusparseCbsrmm
        __cusparseCbsrmm = GetProcAddress(handle, 'cusparseCbsrmm')

        global __cusparseZbsrmm
        __cusparseZbsrmm = GetProcAddress(handle, 'cusparseZbsrmm')

        global __cusparseXbsrsm2_zeroPivot
        __cusparseXbsrsm2_zeroPivot = GetProcAddress(handle, 'cusparseXbsrsm2_zeroPivot')

        global __cusparseSbsrsm2_bufferSize
        __cusparseSbsrsm2_bufferSize = GetProcAddress(handle, 'cusparseSbsrsm2_bufferSize')

        global __cusparseDbsrsm2_bufferSize
        __cusparseDbsrsm2_bufferSize = GetProcAddress(handle, 'cusparseDbsrsm2_bufferSize')

        global __cusparseCbsrsm2_bufferSize
        __cusparseCbsrsm2_bufferSize = GetProcAddress(handle, 'cusparseCbsrsm2_bufferSize')

        global __cusparseZbsrsm2_bufferSize
        __cusparseZbsrsm2_bufferSize = GetProcAddress(handle, 'cusparseZbsrsm2_bufferSize')

        global __cusparseSbsrsm2_bufferSizeExt
        __cusparseSbsrsm2_bufferSizeExt = GetProcAddress(handle, 'cusparseSbsrsm2_bufferSizeExt')

        global __cusparseDbsrsm2_bufferSizeExt
        __cusparseDbsrsm2_bufferSizeExt = GetProcAddress(handle, 'cusparseDbsrsm2_bufferSizeExt')

        global __cusparseCbsrsm2_bufferSizeExt
        __cusparseCbsrsm2_bufferSizeExt = GetProcAddress(handle, 'cusparseCbsrsm2_bufferSizeExt')

        global __cusparseZbsrsm2_bufferSizeExt
        __cusparseZbsrsm2_bufferSizeExt = GetProcAddress(handle, 'cusparseZbsrsm2_bufferSizeExt')

        global __cusparseSbsrsm2_analysis
        __cusparseSbsrsm2_analysis = GetProcAddress(handle, 'cusparseSbsrsm2_analysis')

        global __cusparseDbsrsm2_analysis
        __cusparseDbsrsm2_analysis = GetProcAddress(handle, 'cusparseDbsrsm2_analysis')

        global __cusparseCbsrsm2_analysis
        __cusparseCbsrsm2_analysis = GetProcAddress(handle, 'cusparseCbsrsm2_analysis')

        global __cusparseZbsrsm2_analysis
        __cusparseZbsrsm2_analysis = GetProcAddress(handle, 'cusparseZbsrsm2_analysis')

        global __cusparseSbsrsm2_solve
        __cusparseSbsrsm2_solve = GetProcAddress(handle, 'cusparseSbsrsm2_solve')

        global __cusparseDbsrsm2_solve
        __cusparseDbsrsm2_solve = GetProcAddress(handle, 'cusparseDbsrsm2_solve')

        global __cusparseCbsrsm2_solve
        __cusparseCbsrsm2_solve = GetProcAddress(handle, 'cusparseCbsrsm2_solve')

        global __cusparseZbsrsm2_solve
        __cusparseZbsrsm2_solve = GetProcAddress(handle, 'cusparseZbsrsm2_solve')

        global __cusparseScsrilu02_numericBoost
        __cusparseScsrilu02_numericBoost = GetProcAddress(handle, 'cusparseScsrilu02_numericBoost')

        global __cusparseDcsrilu02_numericBoost
        __cusparseDcsrilu02_numericBoost = GetProcAddress(handle, 'cusparseDcsrilu02_numericBoost')

        global __cusparseCcsrilu02_numericBoost
        __cusparseCcsrilu02_numericBoost = GetProcAddress(handle, 'cusparseCcsrilu02_numericBoost')

        global __cusparseZcsrilu02_numericBoost
        __cusparseZcsrilu02_numericBoost = GetProcAddress(handle, 'cusparseZcsrilu02_numericBoost')

        global __cusparseXcsrilu02_zeroPivot
        __cusparseXcsrilu02_zeroPivot = GetProcAddress(handle, 'cusparseXcsrilu02_zeroPivot')

        global __cusparseScsrilu02_bufferSize
        __cusparseScsrilu02_bufferSize = GetProcAddress(handle, 'cusparseScsrilu02_bufferSize')

        global __cusparseDcsrilu02_bufferSize
        __cusparseDcsrilu02_bufferSize = GetProcAddress(handle, 'cusparseDcsrilu02_bufferSize')

        global __cusparseCcsrilu02_bufferSize
        __cusparseCcsrilu02_bufferSize = GetProcAddress(handle, 'cusparseCcsrilu02_bufferSize')

        global __cusparseZcsrilu02_bufferSize
        __cusparseZcsrilu02_bufferSize = GetProcAddress(handle, 'cusparseZcsrilu02_bufferSize')

        global __cusparseScsrilu02_bufferSizeExt
        __cusparseScsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseScsrilu02_bufferSizeExt')

        global __cusparseDcsrilu02_bufferSizeExt
        __cusparseDcsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseDcsrilu02_bufferSizeExt')

        global __cusparseCcsrilu02_bufferSizeExt
        __cusparseCcsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseCcsrilu02_bufferSizeExt')

        global __cusparseZcsrilu02_bufferSizeExt
        __cusparseZcsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseZcsrilu02_bufferSizeExt')

        global __cusparseScsrilu02_analysis
        __cusparseScsrilu02_analysis = GetProcAddress(handle, 'cusparseScsrilu02_analysis')

        global __cusparseDcsrilu02_analysis
        __cusparseDcsrilu02_analysis = GetProcAddress(handle, 'cusparseDcsrilu02_analysis')

        global __cusparseCcsrilu02_analysis
        __cusparseCcsrilu02_analysis = GetProcAddress(handle, 'cusparseCcsrilu02_analysis')

        global __cusparseZcsrilu02_analysis
        __cusparseZcsrilu02_analysis = GetProcAddress(handle, 'cusparseZcsrilu02_analysis')

        global __cusparseScsrilu02
        __cusparseScsrilu02 = GetProcAddress(handle, 'cusparseScsrilu02')

        global __cusparseDcsrilu02
        __cusparseDcsrilu02 = GetProcAddress(handle, 'cusparseDcsrilu02')

        global __cusparseCcsrilu02
        __cusparseCcsrilu02 = GetProcAddress(handle, 'cusparseCcsrilu02')

        global __cusparseZcsrilu02
        __cusparseZcsrilu02 = GetProcAddress(handle, 'cusparseZcsrilu02')

        global __cusparseSbsrilu02_numericBoost
        __cusparseSbsrilu02_numericBoost = GetProcAddress(handle, 'cusparseSbsrilu02_numericBoost')

        global __cusparseDbsrilu02_numericBoost
        __cusparseDbsrilu02_numericBoost = GetProcAddress(handle, 'cusparseDbsrilu02_numericBoost')

        global __cusparseCbsrilu02_numericBoost
        __cusparseCbsrilu02_numericBoost = GetProcAddress(handle, 'cusparseCbsrilu02_numericBoost')

        global __cusparseZbsrilu02_numericBoost
        __cusparseZbsrilu02_numericBoost = GetProcAddress(handle, 'cusparseZbsrilu02_numericBoost')

        global __cusparseXbsrilu02_zeroPivot
        __cusparseXbsrilu02_zeroPivot = GetProcAddress(handle, 'cusparseXbsrilu02_zeroPivot')

        global __cusparseSbsrilu02_bufferSize
        __cusparseSbsrilu02_bufferSize = GetProcAddress(handle, 'cusparseSbsrilu02_bufferSize')

        global __cusparseDbsrilu02_bufferSize
        __cusparseDbsrilu02_bufferSize = GetProcAddress(handle, 'cusparseDbsrilu02_bufferSize')

        global __cusparseCbsrilu02_bufferSize
        __cusparseCbsrilu02_bufferSize = GetProcAddress(handle, 'cusparseCbsrilu02_bufferSize')

        global __cusparseZbsrilu02_bufferSize
        __cusparseZbsrilu02_bufferSize = GetProcAddress(handle, 'cusparseZbsrilu02_bufferSize')

        global __cusparseSbsrilu02_bufferSizeExt
        __cusparseSbsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseSbsrilu02_bufferSizeExt')

        global __cusparseDbsrilu02_bufferSizeExt
        __cusparseDbsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseDbsrilu02_bufferSizeExt')

        global __cusparseCbsrilu02_bufferSizeExt
        __cusparseCbsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseCbsrilu02_bufferSizeExt')

        global __cusparseZbsrilu02_bufferSizeExt
        __cusparseZbsrilu02_bufferSizeExt = GetProcAddress(handle, 'cusparseZbsrilu02_bufferSizeExt')

        global __cusparseSbsrilu02_analysis
        __cusparseSbsrilu02_analysis = GetProcAddress(handle, 'cusparseSbsrilu02_analysis')

        global __cusparseDbsrilu02_analysis
        __cusparseDbsrilu02_analysis = GetProcAddress(handle, 'cusparseDbsrilu02_analysis')

        global __cusparseCbsrilu02_analysis
        __cusparseCbsrilu02_analysis = GetProcAddress(handle, 'cusparseCbsrilu02_analysis')

        global __cusparseZbsrilu02_analysis
        __cusparseZbsrilu02_analysis = GetProcAddress(handle, 'cusparseZbsrilu02_analysis')

        global __cusparseSbsrilu02
        __cusparseSbsrilu02 = GetProcAddress(handle, 'cusparseSbsrilu02')

        global __cusparseDbsrilu02
        __cusparseDbsrilu02 = GetProcAddress(handle, 'cusparseDbsrilu02')

        global __cusparseCbsrilu02
        __cusparseCbsrilu02 = GetProcAddress(handle, 'cusparseCbsrilu02')

        global __cusparseZbsrilu02
        __cusparseZbsrilu02 = GetProcAddress(handle, 'cusparseZbsrilu02')

        global __cusparseXcsric02_zeroPivot
        __cusparseXcsric02_zeroPivot = GetProcAddress(handle, 'cusparseXcsric02_zeroPivot')

        global __cusparseScsric02_bufferSize
        __cusparseScsric02_bufferSize = GetProcAddress(handle, 'cusparseScsric02_bufferSize')

        global __cusparseDcsric02_bufferSize
        __cusparseDcsric02_bufferSize = GetProcAddress(handle, 'cusparseDcsric02_bufferSize')

        global __cusparseCcsric02_bufferSize
        __cusparseCcsric02_bufferSize = GetProcAddress(handle, 'cusparseCcsric02_bufferSize')

        global __cusparseZcsric02_bufferSize
        __cusparseZcsric02_bufferSize = GetProcAddress(handle, 'cusparseZcsric02_bufferSize')

        global __cusparseScsric02_bufferSizeExt
        __cusparseScsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseScsric02_bufferSizeExt')

        global __cusparseDcsric02_bufferSizeExt
        __cusparseDcsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseDcsric02_bufferSizeExt')

        global __cusparseCcsric02_bufferSizeExt
        __cusparseCcsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseCcsric02_bufferSizeExt')

        global __cusparseZcsric02_bufferSizeExt
        __cusparseZcsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseZcsric02_bufferSizeExt')

        global __cusparseScsric02_analysis
        __cusparseScsric02_analysis = GetProcAddress(handle, 'cusparseScsric02_analysis')

        global __cusparseDcsric02_analysis
        __cusparseDcsric02_analysis = GetProcAddress(handle, 'cusparseDcsric02_analysis')

        global __cusparseCcsric02_analysis
        __cusparseCcsric02_analysis = GetProcAddress(handle, 'cusparseCcsric02_analysis')

        global __cusparseZcsric02_analysis
        __cusparseZcsric02_analysis = GetProcAddress(handle, 'cusparseZcsric02_analysis')

        global __cusparseScsric02
        __cusparseScsric02 = GetProcAddress(handle, 'cusparseScsric02')

        global __cusparseDcsric02
        __cusparseDcsric02 = GetProcAddress(handle, 'cusparseDcsric02')

        global __cusparseCcsric02
        __cusparseCcsric02 = GetProcAddress(handle, 'cusparseCcsric02')

        global __cusparseZcsric02
        __cusparseZcsric02 = GetProcAddress(handle, 'cusparseZcsric02')

        global __cusparseXbsric02_zeroPivot
        __cusparseXbsric02_zeroPivot = GetProcAddress(handle, 'cusparseXbsric02_zeroPivot')

        global __cusparseSbsric02_bufferSize
        __cusparseSbsric02_bufferSize = GetProcAddress(handle, 'cusparseSbsric02_bufferSize')

        global __cusparseDbsric02_bufferSize
        __cusparseDbsric02_bufferSize = GetProcAddress(handle, 'cusparseDbsric02_bufferSize')

        global __cusparseCbsric02_bufferSize
        __cusparseCbsric02_bufferSize = GetProcAddress(handle, 'cusparseCbsric02_bufferSize')

        global __cusparseZbsric02_bufferSize
        __cusparseZbsric02_bufferSize = GetProcAddress(handle, 'cusparseZbsric02_bufferSize')

        global __cusparseSbsric02_bufferSizeExt
        __cusparseSbsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseSbsric02_bufferSizeExt')

        global __cusparseDbsric02_bufferSizeExt
        __cusparseDbsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseDbsric02_bufferSizeExt')

        global __cusparseCbsric02_bufferSizeExt
        __cusparseCbsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseCbsric02_bufferSizeExt')

        global __cusparseZbsric02_bufferSizeExt
        __cusparseZbsric02_bufferSizeExt = GetProcAddress(handle, 'cusparseZbsric02_bufferSizeExt')

        global __cusparseSbsric02_analysis
        __cusparseSbsric02_analysis = GetProcAddress(handle, 'cusparseSbsric02_analysis')

        global __cusparseDbsric02_analysis
        __cusparseDbsric02_analysis = GetProcAddress(handle, 'cusparseDbsric02_analysis')

        global __cusparseCbsric02_analysis
        __cusparseCbsric02_analysis = GetProcAddress(handle, 'cusparseCbsric02_analysis')

        global __cusparseZbsric02_analysis
        __cusparseZbsric02_analysis = GetProcAddress(handle, 'cusparseZbsric02_analysis')

        global __cusparseSbsric02
        __cusparseSbsric02 = GetProcAddress(handle, 'cusparseSbsric02')

        global __cusparseDbsric02
        __cusparseDbsric02 = GetProcAddress(handle, 'cusparseDbsric02')

        global __cusparseCbsric02
        __cusparseCbsric02 = GetProcAddress(handle, 'cusparseCbsric02')

        global __cusparseZbsric02
        __cusparseZbsric02 = GetProcAddress(handle, 'cusparseZbsric02')

        global __cusparseSgtsv2_bufferSizeExt
        __cusparseSgtsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseSgtsv2_bufferSizeExt')

        global __cusparseDgtsv2_bufferSizeExt
        __cusparseDgtsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseDgtsv2_bufferSizeExt')

        global __cusparseCgtsv2_bufferSizeExt
        __cusparseCgtsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseCgtsv2_bufferSizeExt')

        global __cusparseZgtsv2_bufferSizeExt
        __cusparseZgtsv2_bufferSizeExt = GetProcAddress(handle, 'cusparseZgtsv2_bufferSizeExt')

        global __cusparseSgtsv2
        __cusparseSgtsv2 = GetProcAddress(handle, 'cusparseSgtsv2')

        global __cusparseDgtsv2
        __cusparseDgtsv2 = GetProcAddress(handle, 'cusparseDgtsv2')

        global __cusparseCgtsv2
        __cusparseCgtsv2 = GetProcAddress(handle, 'cusparseCgtsv2')

        global __cusparseZgtsv2
        __cusparseZgtsv2 = GetProcAddress(handle, 'cusparseZgtsv2')

        global __cusparseSgtsv2_nopivot_bufferSizeExt
        __cusparseSgtsv2_nopivot_bufferSizeExt = GetProcAddress(handle, 'cusparseSgtsv2_nopivot_bufferSizeExt')

        global __cusparseDgtsv2_nopivot_bufferSizeExt
        __cusparseDgtsv2_nopivot_bufferSizeExt = GetProcAddress(handle, 'cusparseDgtsv2_nopivot_bufferSizeExt')

        global __cusparseCgtsv2_nopivot_bufferSizeExt
        __cusparseCgtsv2_nopivot_bufferSizeExt = GetProcAddress(handle, 'cusparseCgtsv2_nopivot_bufferSizeExt')

        global __cusparseZgtsv2_nopivot_bufferSizeExt
        __cusparseZgtsv2_nopivot_bufferSizeExt = GetProcAddress(handle, 'cusparseZgtsv2_nopivot_bufferSizeExt')

        global __cusparseSgtsv2_nopivot
        __cusparseSgtsv2_nopivot = GetProcAddress(handle, 'cusparseSgtsv2_nopivot')

        global __cusparseDgtsv2_nopivot
        __cusparseDgtsv2_nopivot = GetProcAddress(handle, 'cusparseDgtsv2_nopivot')

        global __cusparseCgtsv2_nopivot
        __cusparseCgtsv2_nopivot = GetProcAddress(handle, 'cusparseCgtsv2_nopivot')

        global __cusparseZgtsv2_nopivot
        __cusparseZgtsv2_nopivot = GetProcAddress(handle, 'cusparseZgtsv2_nopivot')

        global __cusparseSgtsv2StridedBatch_bufferSizeExt
        __cusparseSgtsv2StridedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseSgtsv2StridedBatch_bufferSizeExt')

        global __cusparseDgtsv2StridedBatch_bufferSizeExt
        __cusparseDgtsv2StridedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseDgtsv2StridedBatch_bufferSizeExt')

        global __cusparseCgtsv2StridedBatch_bufferSizeExt
        __cusparseCgtsv2StridedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseCgtsv2StridedBatch_bufferSizeExt')

        global __cusparseZgtsv2StridedBatch_bufferSizeExt
        __cusparseZgtsv2StridedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseZgtsv2StridedBatch_bufferSizeExt')

        global __cusparseSgtsv2StridedBatch
        __cusparseSgtsv2StridedBatch = GetProcAddress(handle, 'cusparseSgtsv2StridedBatch')

        global __cusparseDgtsv2StridedBatch
        __cusparseDgtsv2StridedBatch = GetProcAddress(handle, 'cusparseDgtsv2StridedBatch')

        global __cusparseCgtsv2StridedBatch
        __cusparseCgtsv2StridedBatch = GetProcAddress(handle, 'cusparseCgtsv2StridedBatch')

        global __cusparseZgtsv2StridedBatch
        __cusparseZgtsv2StridedBatch = GetProcAddress(handle, 'cusparseZgtsv2StridedBatch')

        global __cusparseSgtsvInterleavedBatch_bufferSizeExt
        __cusparseSgtsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseSgtsvInterleavedBatch_bufferSizeExt')

        global __cusparseDgtsvInterleavedBatch_bufferSizeExt
        __cusparseDgtsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseDgtsvInterleavedBatch_bufferSizeExt')

        global __cusparseCgtsvInterleavedBatch_bufferSizeExt
        __cusparseCgtsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseCgtsvInterleavedBatch_bufferSizeExt')

        global __cusparseZgtsvInterleavedBatch_bufferSizeExt
        __cusparseZgtsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseZgtsvInterleavedBatch_bufferSizeExt')

        global __cusparseSgtsvInterleavedBatch
        __cusparseSgtsvInterleavedBatch = GetProcAddress(handle, 'cusparseSgtsvInterleavedBatch')

        global __cusparseDgtsvInterleavedBatch
        __cusparseDgtsvInterleavedBatch = GetProcAddress(handle, 'cusparseDgtsvInterleavedBatch')

        global __cusparseCgtsvInterleavedBatch
        __cusparseCgtsvInterleavedBatch = GetProcAddress(handle, 'cusparseCgtsvInterleavedBatch')

        global __cusparseZgtsvInterleavedBatch
        __cusparseZgtsvInterleavedBatch = GetProcAddress(handle, 'cusparseZgtsvInterleavedBatch')

        global __cusparseSgpsvInterleavedBatch_bufferSizeExt
        __cusparseSgpsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseSgpsvInterleavedBatch_bufferSizeExt')

        global __cusparseDgpsvInterleavedBatch_bufferSizeExt
        __cusparseDgpsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseDgpsvInterleavedBatch_bufferSizeExt')

        global __cusparseCgpsvInterleavedBatch_bufferSizeExt
        __cusparseCgpsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseCgpsvInterleavedBatch_bufferSizeExt')

        global __cusparseZgpsvInterleavedBatch_bufferSizeExt
        __cusparseZgpsvInterleavedBatch_bufferSizeExt = GetProcAddress(handle, 'cusparseZgpsvInterleavedBatch_bufferSizeExt')

        global __cusparseSgpsvInterleavedBatch
        __cusparseSgpsvInterleavedBatch = GetProcAddress(handle, 'cusparseSgpsvInterleavedBatch')

        global __cusparseDgpsvInterleavedBatch
        __cusparseDgpsvInterleavedBatch = GetProcAddress(handle, 'cusparseDgpsvInterleavedBatch')

        global __cusparseCgpsvInterleavedBatch
        __cusparseCgpsvInterleavedBatch = GetProcAddress(handle, 'cusparseCgpsvInterleavedBatch')

        global __cusparseZgpsvInterleavedBatch
        __cusparseZgpsvInterleavedBatch = GetProcAddress(handle, 'cusparseZgpsvInterleavedBatch')

        global __cusparseScsrgeam2_bufferSizeExt
        __cusparseScsrgeam2_bufferSizeExt = GetProcAddress(handle, 'cusparseScsrgeam2_bufferSizeExt')

        global __cusparseDcsrgeam2_bufferSizeExt
        __cusparseDcsrgeam2_bufferSizeExt = GetProcAddress(handle, 'cusparseDcsrgeam2_bufferSizeExt')

        global __cusparseCcsrgeam2_bufferSizeExt
        __cusparseCcsrgeam2_bufferSizeExt = GetProcAddress(handle, 'cusparseCcsrgeam2_bufferSizeExt')

        global __cusparseZcsrgeam2_bufferSizeExt
        __cusparseZcsrgeam2_bufferSizeExt = GetProcAddress(handle, 'cusparseZcsrgeam2_bufferSizeExt')

        global __cusparseXcsrgeam2Nnz
        __cusparseXcsrgeam2Nnz = GetProcAddress(handle, 'cusparseXcsrgeam2Nnz')

        global __cusparseScsrgeam2
        __cusparseScsrgeam2 = GetProcAddress(handle, 'cusparseScsrgeam2')

        global __cusparseDcsrgeam2
        __cusparseDcsrgeam2 = GetProcAddress(handle, 'cusparseDcsrgeam2')

        global __cusparseCcsrgeam2
        __cusparseCcsrgeam2 = GetProcAddress(handle, 'cusparseCcsrgeam2')

        global __cusparseZcsrgeam2
        __cusparseZcsrgeam2 = GetProcAddress(handle, 'cusparseZcsrgeam2')

        global __cusparseScsrcolor
        __cusparseScsrcolor = GetProcAddress(handle, 'cusparseScsrcolor')

        global __cusparseDcsrcolor
        __cusparseDcsrcolor = GetProcAddress(handle, 'cusparseDcsrcolor')

        global __cusparseCcsrcolor
        __cusparseCcsrcolor = GetProcAddress(handle, 'cusparseCcsrcolor')

        global __cusparseZcsrcolor
        __cusparseZcsrcolor = GetProcAddress(handle, 'cusparseZcsrcolor')

        global __cusparseSnnz
        __cusparseSnnz = GetProcAddress(handle, 'cusparseSnnz')

        global __cusparseDnnz
        __cusparseDnnz = GetProcAddress(handle, 'cusparseDnnz')

        global __cusparseCnnz
        __cusparseCnnz = GetProcAddress(handle, 'cusparseCnnz')

        global __cusparseZnnz
        __cusparseZnnz = GetProcAddress(handle, 'cusparseZnnz')

        global __cusparseSnnz_compress
        __cusparseSnnz_compress = GetProcAddress(handle, 'cusparseSnnz_compress')

        global __cusparseDnnz_compress
        __cusparseDnnz_compress = GetProcAddress(handle, 'cusparseDnnz_compress')

        global __cusparseCnnz_compress
        __cusparseCnnz_compress = GetProcAddress(handle, 'cusparseCnnz_compress')

        global __cusparseZnnz_compress
        __cusparseZnnz_compress = GetProcAddress(handle, 'cusparseZnnz_compress')

        global __cusparseScsr2csr_compress
        __cusparseScsr2csr_compress = GetProcAddress(handle, 'cusparseScsr2csr_compress')

        global __cusparseDcsr2csr_compress
        __cusparseDcsr2csr_compress = GetProcAddress(handle, 'cusparseDcsr2csr_compress')

        global __cusparseCcsr2csr_compress
        __cusparseCcsr2csr_compress = GetProcAddress(handle, 'cusparseCcsr2csr_compress')

        global __cusparseZcsr2csr_compress
        __cusparseZcsr2csr_compress = GetProcAddress(handle, 'cusparseZcsr2csr_compress')

        global __cusparseXcoo2csr
        __cusparseXcoo2csr = GetProcAddress(handle, 'cusparseXcoo2csr')

        global __cusparseXcsr2coo
        __cusparseXcsr2coo = GetProcAddress(handle, 'cusparseXcsr2coo')

        global __cusparseXcsr2bsrNnz
        __cusparseXcsr2bsrNnz = GetProcAddress(handle, 'cusparseXcsr2bsrNnz')

        global __cusparseScsr2bsr
        __cusparseScsr2bsr = GetProcAddress(handle, 'cusparseScsr2bsr')

        global __cusparseDcsr2bsr
        __cusparseDcsr2bsr = GetProcAddress(handle, 'cusparseDcsr2bsr')

        global __cusparseCcsr2bsr
        __cusparseCcsr2bsr = GetProcAddress(handle, 'cusparseCcsr2bsr')

        global __cusparseZcsr2bsr
        __cusparseZcsr2bsr = GetProcAddress(handle, 'cusparseZcsr2bsr')

        global __cusparseSbsr2csr
        __cusparseSbsr2csr = GetProcAddress(handle, 'cusparseSbsr2csr')

        global __cusparseDbsr2csr
        __cusparseDbsr2csr = GetProcAddress(handle, 'cusparseDbsr2csr')

        global __cusparseCbsr2csr
        __cusparseCbsr2csr = GetProcAddress(handle, 'cusparseCbsr2csr')

        global __cusparseZbsr2csr
        __cusparseZbsr2csr = GetProcAddress(handle, 'cusparseZbsr2csr')

        global __cusparseSgebsr2gebsc_bufferSize
        __cusparseSgebsr2gebsc_bufferSize = GetProcAddress(handle, 'cusparseSgebsr2gebsc_bufferSize')

        global __cusparseDgebsr2gebsc_bufferSize
        __cusparseDgebsr2gebsc_bufferSize = GetProcAddress(handle, 'cusparseDgebsr2gebsc_bufferSize')

        global __cusparseCgebsr2gebsc_bufferSize
        __cusparseCgebsr2gebsc_bufferSize = GetProcAddress(handle, 'cusparseCgebsr2gebsc_bufferSize')

        global __cusparseZgebsr2gebsc_bufferSize
        __cusparseZgebsr2gebsc_bufferSize = GetProcAddress(handle, 'cusparseZgebsr2gebsc_bufferSize')

        global __cusparseSgebsr2gebsc_bufferSizeExt
        __cusparseSgebsr2gebsc_bufferSizeExt = GetProcAddress(handle, 'cusparseSgebsr2gebsc_bufferSizeExt')

        global __cusparseDgebsr2gebsc_bufferSizeExt
        __cusparseDgebsr2gebsc_bufferSizeExt = GetProcAddress(handle, 'cusparseDgebsr2gebsc_bufferSizeExt')

        global __cusparseCgebsr2gebsc_bufferSizeExt
        __cusparseCgebsr2gebsc_bufferSizeExt = GetProcAddress(handle, 'cusparseCgebsr2gebsc_bufferSizeExt')

        global __cusparseZgebsr2gebsc_bufferSizeExt
        __cusparseZgebsr2gebsc_bufferSizeExt = GetProcAddress(handle, 'cusparseZgebsr2gebsc_bufferSizeExt')

        global __cusparseSgebsr2gebsc
        __cusparseSgebsr2gebsc = GetProcAddress(handle, 'cusparseSgebsr2gebsc')

        global __cusparseDgebsr2gebsc
        __cusparseDgebsr2gebsc = GetProcAddress(handle, 'cusparseDgebsr2gebsc')

        global __cusparseCgebsr2gebsc
        __cusparseCgebsr2gebsc = GetProcAddress(handle, 'cusparseCgebsr2gebsc')

        global __cusparseZgebsr2gebsc
        __cusparseZgebsr2gebsc = GetProcAddress(handle, 'cusparseZgebsr2gebsc')

        global __cusparseXgebsr2csr
        __cusparseXgebsr2csr = GetProcAddress(handle, 'cusparseXgebsr2csr')

        global __cusparseSgebsr2csr
        __cusparseSgebsr2csr = GetProcAddress(handle, 'cusparseSgebsr2csr')

        global __cusparseDgebsr2csr
        __cusparseDgebsr2csr = GetProcAddress(handle, 'cusparseDgebsr2csr')

        global __cusparseCgebsr2csr
        __cusparseCgebsr2csr = GetProcAddress(handle, 'cusparseCgebsr2csr')

        global __cusparseZgebsr2csr
        __cusparseZgebsr2csr = GetProcAddress(handle, 'cusparseZgebsr2csr')

        global __cusparseScsr2gebsr_bufferSize
        __cusparseScsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseScsr2gebsr_bufferSize')

        global __cusparseDcsr2gebsr_bufferSize
        __cusparseDcsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseDcsr2gebsr_bufferSize')

        global __cusparseCcsr2gebsr_bufferSize
        __cusparseCcsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseCcsr2gebsr_bufferSize')

        global __cusparseZcsr2gebsr_bufferSize
        __cusparseZcsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseZcsr2gebsr_bufferSize')

        global __cusparseScsr2gebsr_bufferSizeExt
        __cusparseScsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseScsr2gebsr_bufferSizeExt')

        global __cusparseDcsr2gebsr_bufferSizeExt
        __cusparseDcsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseDcsr2gebsr_bufferSizeExt')

        global __cusparseCcsr2gebsr_bufferSizeExt
        __cusparseCcsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseCcsr2gebsr_bufferSizeExt')

        global __cusparseZcsr2gebsr_bufferSizeExt
        __cusparseZcsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseZcsr2gebsr_bufferSizeExt')

        global __cusparseXcsr2gebsrNnz
        __cusparseXcsr2gebsrNnz = GetProcAddress(handle, 'cusparseXcsr2gebsrNnz')

        global __cusparseScsr2gebsr
        __cusparseScsr2gebsr = GetProcAddress(handle, 'cusparseScsr2gebsr')

        global __cusparseDcsr2gebsr
        __cusparseDcsr2gebsr = GetProcAddress(handle, 'cusparseDcsr2gebsr')

        global __cusparseCcsr2gebsr
        __cusparseCcsr2gebsr = GetProcAddress(handle, 'cusparseCcsr2gebsr')

        global __cusparseZcsr2gebsr
        __cusparseZcsr2gebsr = GetProcAddress(handle, 'cusparseZcsr2gebsr')

        global __cusparseSgebsr2gebsr_bufferSize
        __cusparseSgebsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseSgebsr2gebsr_bufferSize')

        global __cusparseDgebsr2gebsr_bufferSize
        __cusparseDgebsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseDgebsr2gebsr_bufferSize')

        global __cusparseCgebsr2gebsr_bufferSize
        __cusparseCgebsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseCgebsr2gebsr_bufferSize')

        global __cusparseZgebsr2gebsr_bufferSize
        __cusparseZgebsr2gebsr_bufferSize = GetProcAddress(handle, 'cusparseZgebsr2gebsr_bufferSize')

        global __cusparseSgebsr2gebsr_bufferSizeExt
        __cusparseSgebsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseSgebsr2gebsr_bufferSizeExt')

        global __cusparseDgebsr2gebsr_bufferSizeExt
        __cusparseDgebsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseDgebsr2gebsr_bufferSizeExt')

        global __cusparseCgebsr2gebsr_bufferSizeExt
        __cusparseCgebsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseCgebsr2gebsr_bufferSizeExt')

        global __cusparseZgebsr2gebsr_bufferSizeExt
        __cusparseZgebsr2gebsr_bufferSizeExt = GetProcAddress(handle, 'cusparseZgebsr2gebsr_bufferSizeExt')

        global __cusparseXgebsr2gebsrNnz
        __cusparseXgebsr2gebsrNnz = GetProcAddress(handle, 'cusparseXgebsr2gebsrNnz')

        global __cusparseSgebsr2gebsr
        __cusparseSgebsr2gebsr = GetProcAddress(handle, 'cusparseSgebsr2gebsr')

        global __cusparseDgebsr2gebsr
        __cusparseDgebsr2gebsr = GetProcAddress(handle, 'cusparseDgebsr2gebsr')

        global __cusparseCgebsr2gebsr
        __cusparseCgebsr2gebsr = GetProcAddress(handle, 'cusparseCgebsr2gebsr')

        global __cusparseZgebsr2gebsr
        __cusparseZgebsr2gebsr = GetProcAddress(handle, 'cusparseZgebsr2gebsr')

        global __cusparseCreateIdentityPermutation
        __cusparseCreateIdentityPermutation = GetProcAddress(handle, 'cusparseCreateIdentityPermutation')

        global __cusparseXcoosort_bufferSizeExt
        __cusparseXcoosort_bufferSizeExt = GetProcAddress(handle, 'cusparseXcoosort_bufferSizeExt')

        global __cusparseXcoosortByRow
        __cusparseXcoosortByRow = GetProcAddress(handle, 'cusparseXcoosortByRow')

        global __cusparseXcoosortByColumn
        __cusparseXcoosortByColumn = GetProcAddress(handle, 'cusparseXcoosortByColumn')

        global __cusparseXcsrsort_bufferSizeExt
        __cusparseXcsrsort_bufferSizeExt = GetProcAddress(handle, 'cusparseXcsrsort_bufferSizeExt')

        global __cusparseXcsrsort
        __cusparseXcsrsort = GetProcAddress(handle, 'cusparseXcsrsort')

        global __cusparseXcscsort_bufferSizeExt
        __cusparseXcscsort_bufferSizeExt = GetProcAddress(handle, 'cusparseXcscsort_bufferSizeExt')

        global __cusparseXcscsort
        __cusparseXcscsort = GetProcAddress(handle, 'cusparseXcscsort')

        global __cusparseScsru2csr_bufferSizeExt
        __cusparseScsru2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseScsru2csr_bufferSizeExt')

        global __cusparseDcsru2csr_bufferSizeExt
        __cusparseDcsru2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseDcsru2csr_bufferSizeExt')

        global __cusparseCcsru2csr_bufferSizeExt
        __cusparseCcsru2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseCcsru2csr_bufferSizeExt')

        global __cusparseZcsru2csr_bufferSizeExt
        __cusparseZcsru2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseZcsru2csr_bufferSizeExt')

        global __cusparseScsru2csr
        __cusparseScsru2csr = GetProcAddress(handle, 'cusparseScsru2csr')

        global __cusparseDcsru2csr
        __cusparseDcsru2csr = GetProcAddress(handle, 'cusparseDcsru2csr')

        global __cusparseCcsru2csr
        __cusparseCcsru2csr = GetProcAddress(handle, 'cusparseCcsru2csr')

        global __cusparseZcsru2csr
        __cusparseZcsru2csr = GetProcAddress(handle, 'cusparseZcsru2csr')

        global __cusparseScsr2csru
        __cusparseScsr2csru = GetProcAddress(handle, 'cusparseScsr2csru')

        global __cusparseDcsr2csru
        __cusparseDcsr2csru = GetProcAddress(handle, 'cusparseDcsr2csru')

        global __cusparseCcsr2csru
        __cusparseCcsr2csru = GetProcAddress(handle, 'cusparseCcsr2csru')

        global __cusparseZcsr2csru
        __cusparseZcsr2csru = GetProcAddress(handle, 'cusparseZcsr2csru')

        global __cusparseSpruneDense2csr_bufferSizeExt
        __cusparseSpruneDense2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseSpruneDense2csr_bufferSizeExt')

        global __cusparseDpruneDense2csr_bufferSizeExt
        __cusparseDpruneDense2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseDpruneDense2csr_bufferSizeExt')

        global __cusparseSpruneDense2csrNnz
        __cusparseSpruneDense2csrNnz = GetProcAddress(handle, 'cusparseSpruneDense2csrNnz')

        global __cusparseDpruneDense2csrNnz
        __cusparseDpruneDense2csrNnz = GetProcAddress(handle, 'cusparseDpruneDense2csrNnz')

        global __cusparseSpruneDense2csr
        __cusparseSpruneDense2csr = GetProcAddress(handle, 'cusparseSpruneDense2csr')

        global __cusparseDpruneDense2csr
        __cusparseDpruneDense2csr = GetProcAddress(handle, 'cusparseDpruneDense2csr')

        global __cusparseSpruneCsr2csr_bufferSizeExt
        __cusparseSpruneCsr2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseSpruneCsr2csr_bufferSizeExt')

        global __cusparseDpruneCsr2csr_bufferSizeExt
        __cusparseDpruneCsr2csr_bufferSizeExt = GetProcAddress(handle, 'cusparseDpruneCsr2csr_bufferSizeExt')

        global __cusparseSpruneCsr2csrNnz
        __cusparseSpruneCsr2csrNnz = GetProcAddress(handle, 'cusparseSpruneCsr2csrNnz')

        global __cusparseDpruneCsr2csrNnz
        __cusparseDpruneCsr2csrNnz = GetProcAddress(handle, 'cusparseDpruneCsr2csrNnz')

        global __cusparseSpruneCsr2csr
        __cusparseSpruneCsr2csr = GetProcAddress(handle, 'cusparseSpruneCsr2csr')

        global __cusparseDpruneCsr2csr
        __cusparseDpruneCsr2csr = GetProcAddress(handle, 'cusparseDpruneCsr2csr')

        global __cusparseSpruneDense2csrByPercentage_bufferSizeExt
        __cusparseSpruneDense2csrByPercentage_bufferSizeExt = GetProcAddress(handle, 'cusparseSpruneDense2csrByPercentage_bufferSizeExt')

        global __cusparseDpruneDense2csrByPercentage_bufferSizeExt
        __cusparseDpruneDense2csrByPercentage_bufferSizeExt = GetProcAddress(handle, 'cusparseDpruneDense2csrByPercentage_bufferSizeExt')

        global __cusparseSpruneDense2csrNnzByPercentage
        __cusparseSpruneDense2csrNnzByPercentage = GetProcAddress(handle, 'cusparseSpruneDense2csrNnzByPercentage')

        global __cusparseDpruneDense2csrNnzByPercentage
        __cusparseDpruneDense2csrNnzByPercentage = GetProcAddress(handle, 'cusparseDpruneDense2csrNnzByPercentage')

        global __cusparseSpruneDense2csrByPercentage
        __cusparseSpruneDense2csrByPercentage = GetProcAddress(handle, 'cusparseSpruneDense2csrByPercentage')

        global __cusparseDpruneDense2csrByPercentage
        __cusparseDpruneDense2csrByPercentage = GetProcAddress(handle, 'cusparseDpruneDense2csrByPercentage')

        global __cusparseSpruneCsr2csrByPercentage_bufferSizeExt
        __cusparseSpruneCsr2csrByPercentage_bufferSizeExt = GetProcAddress(handle, 'cusparseSpruneCsr2csrByPercentage_bufferSizeExt')

        global __cusparseDpruneCsr2csrByPercentage_bufferSizeExt
        __cusparseDpruneCsr2csrByPercentage_bufferSizeExt = GetProcAddress(handle, 'cusparseDpruneCsr2csrByPercentage_bufferSizeExt')

        global __cusparseSpruneCsr2csrNnzByPercentage
        __cusparseSpruneCsr2csrNnzByPercentage = GetProcAddress(handle, 'cusparseSpruneCsr2csrNnzByPercentage')

        global __cusparseDpruneCsr2csrNnzByPercentage
        __cusparseDpruneCsr2csrNnzByPercentage = GetProcAddress(handle, 'cusparseDpruneCsr2csrNnzByPercentage')

        global __cusparseSpruneCsr2csrByPercentage
        __cusparseSpruneCsr2csrByPercentage = GetProcAddress(handle, 'cusparseSpruneCsr2csrByPercentage')

        global __cusparseDpruneCsr2csrByPercentage
        __cusparseDpruneCsr2csrByPercentage = GetProcAddress(handle, 'cusparseDpruneCsr2csrByPercentage')

        global __cusparseCsr2cscEx2
        __cusparseCsr2cscEx2 = GetProcAddress(handle, 'cusparseCsr2cscEx2')

        global __cusparseCsr2cscEx2_bufferSize
        __cusparseCsr2cscEx2_bufferSize = GetProcAddress(handle, 'cusparseCsr2cscEx2_bufferSize')

        global __cusparseCreateSpVec
        __cusparseCreateSpVec = GetProcAddress(handle, 'cusparseCreateSpVec')

        global __cusparseCreateConstSpVec
        __cusparseCreateConstSpVec = GetProcAddress(handle, 'cusparseCreateConstSpVec')

        global __cusparseDestroySpVec
        __cusparseDestroySpVec = GetProcAddress(handle, 'cusparseDestroySpVec')

        global __cusparseSpVecGet
        __cusparseSpVecGet = GetProcAddress(handle, 'cusparseSpVecGet')

        global __cusparseConstSpVecGet
        __cusparseConstSpVecGet = GetProcAddress(handle, 'cusparseConstSpVecGet')

        global __cusparseSpVecGetIndexBase
        __cusparseSpVecGetIndexBase = GetProcAddress(handle, 'cusparseSpVecGetIndexBase')

        global __cusparseSpVecGetValues
        __cusparseSpVecGetValues = GetProcAddress(handle, 'cusparseSpVecGetValues')

        global __cusparseConstSpVecGetValues
        __cusparseConstSpVecGetValues = GetProcAddress(handle, 'cusparseConstSpVecGetValues')

        global __cusparseSpVecSetValues
        __cusparseSpVecSetValues = GetProcAddress(handle, 'cusparseSpVecSetValues')

        global __cusparseCreateDnVec
        __cusparseCreateDnVec = GetProcAddress(handle, 'cusparseCreateDnVec')

        global __cusparseCreateConstDnVec
        __cusparseCreateConstDnVec = GetProcAddress(handle, 'cusparseCreateConstDnVec')

        global __cusparseDestroyDnVec
        __cusparseDestroyDnVec = GetProcAddress(handle, 'cusparseDestroyDnVec')

        global __cusparseDnVecGet
        __cusparseDnVecGet = GetProcAddress(handle, 'cusparseDnVecGet')

        global __cusparseConstDnVecGet
        __cusparseConstDnVecGet = GetProcAddress(handle, 'cusparseConstDnVecGet')

        global __cusparseDnVecGetValues
        __cusparseDnVecGetValues = GetProcAddress(handle, 'cusparseDnVecGetValues')

        global __cusparseConstDnVecGetValues
        __cusparseConstDnVecGetValues = GetProcAddress(handle, 'cusparseConstDnVecGetValues')

        global __cusparseDnVecSetValues
        __cusparseDnVecSetValues = GetProcAddress(handle, 'cusparseDnVecSetValues')

        global __cusparseDestroySpMat
        __cusparseDestroySpMat = GetProcAddress(handle, 'cusparseDestroySpMat')

        global __cusparseSpMatGetFormat
        __cusparseSpMatGetFormat = GetProcAddress(handle, 'cusparseSpMatGetFormat')

        global __cusparseSpMatGetIndexBase
        __cusparseSpMatGetIndexBase = GetProcAddress(handle, 'cusparseSpMatGetIndexBase')

        global __cusparseSpMatGetValues
        __cusparseSpMatGetValues = GetProcAddress(handle, 'cusparseSpMatGetValues')

        global __cusparseConstSpMatGetValues
        __cusparseConstSpMatGetValues = GetProcAddress(handle, 'cusparseConstSpMatGetValues')

        global __cusparseSpMatSetValues
        __cusparseSpMatSetValues = GetProcAddress(handle, 'cusparseSpMatSetValues')

        global __cusparseSpMatGetSize
        __cusparseSpMatGetSize = GetProcAddress(handle, 'cusparseSpMatGetSize')

        global __cusparseSpMatGetStridedBatch
        __cusparseSpMatGetStridedBatch = GetProcAddress(handle, 'cusparseSpMatGetStridedBatch')

        global __cusparseCooSetStridedBatch
        __cusparseCooSetStridedBatch = GetProcAddress(handle, 'cusparseCooSetStridedBatch')

        global __cusparseCsrSetStridedBatch
        __cusparseCsrSetStridedBatch = GetProcAddress(handle, 'cusparseCsrSetStridedBatch')

        global __cusparseSpMatGetAttribute
        __cusparseSpMatGetAttribute = GetProcAddress(handle, 'cusparseSpMatGetAttribute')

        global __cusparseSpMatSetAttribute
        __cusparseSpMatSetAttribute = GetProcAddress(handle, 'cusparseSpMatSetAttribute')

        global __cusparseCreateCsr
        __cusparseCreateCsr = GetProcAddress(handle, 'cusparseCreateCsr')

        global __cusparseCreateConstCsr
        __cusparseCreateConstCsr = GetProcAddress(handle, 'cusparseCreateConstCsr')

        global __cusparseCreateCsc
        __cusparseCreateCsc = GetProcAddress(handle, 'cusparseCreateCsc')

        global __cusparseCreateConstCsc
        __cusparseCreateConstCsc = GetProcAddress(handle, 'cusparseCreateConstCsc')

        global __cusparseCsrGet
        __cusparseCsrGet = GetProcAddress(handle, 'cusparseCsrGet')

        global __cusparseConstCsrGet
        __cusparseConstCsrGet = GetProcAddress(handle, 'cusparseConstCsrGet')

        global __cusparseCscGet
        __cusparseCscGet = GetProcAddress(handle, 'cusparseCscGet')

        global __cusparseConstCscGet
        __cusparseConstCscGet = GetProcAddress(handle, 'cusparseConstCscGet')

        global __cusparseCsrSetPointers
        __cusparseCsrSetPointers = GetProcAddress(handle, 'cusparseCsrSetPointers')

        global __cusparseCscSetPointers
        __cusparseCscSetPointers = GetProcAddress(handle, 'cusparseCscSetPointers')

        global __cusparseCreateCoo
        __cusparseCreateCoo = GetProcAddress(handle, 'cusparseCreateCoo')

        global __cusparseCreateConstCoo
        __cusparseCreateConstCoo = GetProcAddress(handle, 'cusparseCreateConstCoo')

        global __cusparseCooGet
        __cusparseCooGet = GetProcAddress(handle, 'cusparseCooGet')

        global __cusparseConstCooGet
        __cusparseConstCooGet = GetProcAddress(handle, 'cusparseConstCooGet')

        global __cusparseCooSetPointers
        __cusparseCooSetPointers = GetProcAddress(handle, 'cusparseCooSetPointers')

        global __cusparseCreateBlockedEll
        __cusparseCreateBlockedEll = GetProcAddress(handle, 'cusparseCreateBlockedEll')

        global __cusparseCreateConstBlockedEll
        __cusparseCreateConstBlockedEll = GetProcAddress(handle, 'cusparseCreateConstBlockedEll')

        global __cusparseBlockedEllGet
        __cusparseBlockedEllGet = GetProcAddress(handle, 'cusparseBlockedEllGet')

        global __cusparseConstBlockedEllGet
        __cusparseConstBlockedEllGet = GetProcAddress(handle, 'cusparseConstBlockedEllGet')

        global __cusparseCreateDnMat
        __cusparseCreateDnMat = GetProcAddress(handle, 'cusparseCreateDnMat')

        global __cusparseCreateConstDnMat
        __cusparseCreateConstDnMat = GetProcAddress(handle, 'cusparseCreateConstDnMat')

        global __cusparseDestroyDnMat
        __cusparseDestroyDnMat = GetProcAddress(handle, 'cusparseDestroyDnMat')

        global __cusparseDnMatGet
        __cusparseDnMatGet = GetProcAddress(handle, 'cusparseDnMatGet')

        global __cusparseConstDnMatGet
        __cusparseConstDnMatGet = GetProcAddress(handle, 'cusparseConstDnMatGet')

        global __cusparseDnMatGetValues
        __cusparseDnMatGetValues = GetProcAddress(handle, 'cusparseDnMatGetValues')

        global __cusparseConstDnMatGetValues
        __cusparseConstDnMatGetValues = GetProcAddress(handle, 'cusparseConstDnMatGetValues')

        global __cusparseDnMatSetValues
        __cusparseDnMatSetValues = GetProcAddress(handle, 'cusparseDnMatSetValues')

        global __cusparseDnMatSetStridedBatch
        __cusparseDnMatSetStridedBatch = GetProcAddress(handle, 'cusparseDnMatSetStridedBatch')

        global __cusparseDnMatGetStridedBatch
        __cusparseDnMatGetStridedBatch = GetProcAddress(handle, 'cusparseDnMatGetStridedBatch')

        global __cusparseAxpby
        __cusparseAxpby = GetProcAddress(handle, 'cusparseAxpby')

        global __cusparseGather
        __cusparseGather = GetProcAddress(handle, 'cusparseGather')

        global __cusparseScatter
        __cusparseScatter = GetProcAddress(handle, 'cusparseScatter')

        global __cusparseRot
        __cusparseRot = GetProcAddress(handle, 'cusparseRot')

        global __cusparseSpVV_bufferSize
        __cusparseSpVV_bufferSize = GetProcAddress(handle, 'cusparseSpVV_bufferSize')

        global __cusparseSpVV
        __cusparseSpVV = GetProcAddress(handle, 'cusparseSpVV')

        global __cusparseSparseToDense_bufferSize
        __cusparseSparseToDense_bufferSize = GetProcAddress(handle, 'cusparseSparseToDense_bufferSize')

        global __cusparseSparseToDense
        __cusparseSparseToDense = GetProcAddress(handle, 'cusparseSparseToDense')

        global __cusparseDenseToSparse_bufferSize
        __cusparseDenseToSparse_bufferSize = GetProcAddress(handle, 'cusparseDenseToSparse_bufferSize')

        global __cusparseDenseToSparse_analysis
        __cusparseDenseToSparse_analysis = GetProcAddress(handle, 'cusparseDenseToSparse_analysis')

        global __cusparseDenseToSparse_convert
        __cusparseDenseToSparse_convert = GetProcAddress(handle, 'cusparseDenseToSparse_convert')

        global __cusparseSpMV
        __cusparseSpMV = GetProcAddress(handle, 'cusparseSpMV')

        global __cusparseSpMV_bufferSize
        __cusparseSpMV_bufferSize = GetProcAddress(handle, 'cusparseSpMV_bufferSize')

        global __cusparseSpSV_createDescr
        __cusparseSpSV_createDescr = GetProcAddress(handle, 'cusparseSpSV_createDescr')

        global __cusparseSpSV_destroyDescr
        __cusparseSpSV_destroyDescr = GetProcAddress(handle, 'cusparseSpSV_destroyDescr')

        global __cusparseSpSV_bufferSize
        __cusparseSpSV_bufferSize = GetProcAddress(handle, 'cusparseSpSV_bufferSize')

        global __cusparseSpSV_analysis
        __cusparseSpSV_analysis = GetProcAddress(handle, 'cusparseSpSV_analysis')

        global __cusparseSpSV_solve
        __cusparseSpSV_solve = GetProcAddress(handle, 'cusparseSpSV_solve')

        global __cusparseSpSM_createDescr
        __cusparseSpSM_createDescr = GetProcAddress(handle, 'cusparseSpSM_createDescr')

        global __cusparseSpSM_destroyDescr
        __cusparseSpSM_destroyDescr = GetProcAddress(handle, 'cusparseSpSM_destroyDescr')

        global __cusparseSpSM_bufferSize
        __cusparseSpSM_bufferSize = GetProcAddress(handle, 'cusparseSpSM_bufferSize')

        global __cusparseSpSM_analysis
        __cusparseSpSM_analysis = GetProcAddress(handle, 'cusparseSpSM_analysis')

        global __cusparseSpSM_solve
        __cusparseSpSM_solve = GetProcAddress(handle, 'cusparseSpSM_solve')

        global __cusparseSpMM_bufferSize
        __cusparseSpMM_bufferSize = GetProcAddress(handle, 'cusparseSpMM_bufferSize')

        global __cusparseSpMM_preprocess
        __cusparseSpMM_preprocess = GetProcAddress(handle, 'cusparseSpMM_preprocess')

        global __cusparseSpMM
        __cusparseSpMM = GetProcAddress(handle, 'cusparseSpMM')

        global __cusparseSpGEMM_createDescr
        __cusparseSpGEMM_createDescr = GetProcAddress(handle, 'cusparseSpGEMM_createDescr')

        global __cusparseSpGEMM_destroyDescr
        __cusparseSpGEMM_destroyDescr = GetProcAddress(handle, 'cusparseSpGEMM_destroyDescr')

        global __cusparseSpGEMM_workEstimation
        __cusparseSpGEMM_workEstimation = GetProcAddress(handle, 'cusparseSpGEMM_workEstimation')

        global __cusparseSpGEMM_getNumProducts
        __cusparseSpGEMM_getNumProducts = GetProcAddress(handle, 'cusparseSpGEMM_getNumProducts')

        global __cusparseSpGEMM_estimateMemory
        __cusparseSpGEMM_estimateMemory = GetProcAddress(handle, 'cusparseSpGEMM_estimateMemory')

        global __cusparseSpGEMM_compute
        __cusparseSpGEMM_compute = GetProcAddress(handle, 'cusparseSpGEMM_compute')

        global __cusparseSpGEMM_copy
        __cusparseSpGEMM_copy = GetProcAddress(handle, 'cusparseSpGEMM_copy')

        global __cusparseSpGEMMreuse_workEstimation
        __cusparseSpGEMMreuse_workEstimation = GetProcAddress(handle, 'cusparseSpGEMMreuse_workEstimation')

        global __cusparseSpGEMMreuse_nnz
        __cusparseSpGEMMreuse_nnz = GetProcAddress(handle, 'cusparseSpGEMMreuse_nnz')

        global __cusparseSpGEMMreuse_copy
        __cusparseSpGEMMreuse_copy = GetProcAddress(handle, 'cusparseSpGEMMreuse_copy')

        global __cusparseSpGEMMreuse_compute
        __cusparseSpGEMMreuse_compute = GetProcAddress(handle, 'cusparseSpGEMMreuse_compute')

        global __cusparseSDDMM_bufferSize
        __cusparseSDDMM_bufferSize = GetProcAddress(handle, 'cusparseSDDMM_bufferSize')

        global __cusparseSDDMM_preprocess
        __cusparseSDDMM_preprocess = GetProcAddress(handle, 'cusparseSDDMM_preprocess')

        global __cusparseSDDMM
        __cusparseSDDMM = GetProcAddress(handle, 'cusparseSDDMM')

        global __cusparseSpMMOp_createPlan
        __cusparseSpMMOp_createPlan = GetProcAddress(handle, 'cusparseSpMMOp_createPlan')

        global __cusparseSpMMOp
        __cusparseSpMMOp = GetProcAddress(handle, 'cusparseSpMMOp')

        global __cusparseSpMMOp_destroyPlan
        __cusparseSpMMOp_destroyPlan = GetProcAddress(handle, 'cusparseSpMMOp_destroyPlan')

        global __cusparseBsrSetStridedBatch
        __cusparseBsrSetStridedBatch = GetProcAddress(handle, 'cusparseBsrSetStridedBatch')

        global __cusparseCreateBsr
        __cusparseCreateBsr = GetProcAddress(handle, 'cusparseCreateBsr')

        global __cusparseCreateConstBsr
        __cusparseCreateConstBsr = GetProcAddress(handle, 'cusparseCreateConstBsr')

        global __cusparseCreateSlicedEll
        __cusparseCreateSlicedEll = GetProcAddress(handle, 'cusparseCreateSlicedEll')

        global __cusparseCreateConstSlicedEll
        __cusparseCreateConstSlicedEll = GetProcAddress(handle, 'cusparseCreateConstSlicedEll')

        global __cusparseSpSV_updateMatrix
        __cusparseSpSV_updateMatrix = GetProcAddress(handle, 'cusparseSpSV_updateMatrix')

        global __cusparseSpMV_preprocess
        __cusparseSpMV_preprocess = GetProcAddress(handle, 'cusparseSpMV_preprocess')

        global __cusparseSpSM_updateMatrix
        __cusparseSpSM_updateMatrix = GetProcAddress(handle, 'cusparseSpSM_updateMatrix')

        global __cusparseSpMVOp_createDescr
        __cusparseSpMVOp_createDescr = GetProcAddress(handle, 'cusparseSpMVOp_createDescr')

        global __cusparseSpMVOp_destroyDescr
        __cusparseSpMVOp_destroyDescr = GetProcAddress(handle, 'cusparseSpMVOp_destroyDescr')

        global __cusparseSpMVOp_createPlan
        __cusparseSpMVOp_createPlan = GetProcAddress(handle, 'cusparseSpMVOp_createPlan')

        global __cusparseSpMVOp_destroyPlan
        __cusparseSpMVOp_destroyPlan = GetProcAddress(handle, 'cusparseSpMVOp_destroyPlan')

        global __cusparseSpMVOp_setGlobalUserData
        __cusparseSpMVOp_setGlobalUserData = GetProcAddress(handle, 'cusparseSpMVOp_setGlobalUserData')

        global __cusparseSpMVOp
        __cusparseSpMVOp = GetProcAddress(handle, 'cusparseSpMVOp')

        global __cusparseSpMVOp_bufferSize
        __cusparseSpMVOp_bufferSize = GetProcAddress(handle, 'cusparseSpMVOp_bufferSize')

        __py_cusparse_init = True
        return 0


cdef dict func_ptrs = None


cpdef dict _inspect_function_pointers():
    global func_ptrs
    if func_ptrs is not None:
        return func_ptrs

    _check_or_init_cusparse()
    cdef dict data = {}

    global __cusparseCreate
    data["__cusparseCreate"] = <intptr_t>__cusparseCreate

    global __cusparseDestroy
    data["__cusparseDestroy"] = <intptr_t>__cusparseDestroy

    global __cusparseGetVersion
    data["__cusparseGetVersion"] = <intptr_t>__cusparseGetVersion

    global __cusparseGetProperty
    data["__cusparseGetProperty"] = <intptr_t>__cusparseGetProperty

    global __cusparseGetErrorName
    data["__cusparseGetErrorName"] = <intptr_t>__cusparseGetErrorName

    global __cusparseGetErrorString
    data["__cusparseGetErrorString"] = <intptr_t>__cusparseGetErrorString

    global __cusparseSetStream
    data["__cusparseSetStream"] = <intptr_t>__cusparseSetStream

    global __cusparseGetStream
    data["__cusparseGetStream"] = <intptr_t>__cusparseGetStream

    global __cusparseGetPointerMode
    data["__cusparseGetPointerMode"] = <intptr_t>__cusparseGetPointerMode

    global __cusparseSetPointerMode
    data["__cusparseSetPointerMode"] = <intptr_t>__cusparseSetPointerMode

    global __cusparseLoggerSetCallback
    data["__cusparseLoggerSetCallback"] = <intptr_t>__cusparseLoggerSetCallback

    global __cusparseLoggerSetFile
    data["__cusparseLoggerSetFile"] = <intptr_t>__cusparseLoggerSetFile

    global __cusparseLoggerOpenFile
    data["__cusparseLoggerOpenFile"] = <intptr_t>__cusparseLoggerOpenFile

    global __cusparseLoggerSetLevel
    data["__cusparseLoggerSetLevel"] = <intptr_t>__cusparseLoggerSetLevel

    global __cusparseLoggerSetMask
    data["__cusparseLoggerSetMask"] = <intptr_t>__cusparseLoggerSetMask

    global __cusparseLoggerForceDisable
    data["__cusparseLoggerForceDisable"] = <intptr_t>__cusparseLoggerForceDisable

    global __cusparseCreateMatDescr
    data["__cusparseCreateMatDescr"] = <intptr_t>__cusparseCreateMatDescr

    global __cusparseDestroyMatDescr
    data["__cusparseDestroyMatDescr"] = <intptr_t>__cusparseDestroyMatDescr

    global __cusparseSetMatType
    data["__cusparseSetMatType"] = <intptr_t>__cusparseSetMatType

    global __cusparseGetMatType
    data["__cusparseGetMatType"] = <intptr_t>__cusparseGetMatType

    global __cusparseSetMatFillMode
    data["__cusparseSetMatFillMode"] = <intptr_t>__cusparseSetMatFillMode

    global __cusparseGetMatFillMode
    data["__cusparseGetMatFillMode"] = <intptr_t>__cusparseGetMatFillMode

    global __cusparseSetMatDiagType
    data["__cusparseSetMatDiagType"] = <intptr_t>__cusparseSetMatDiagType

    global __cusparseGetMatDiagType
    data["__cusparseGetMatDiagType"] = <intptr_t>__cusparseGetMatDiagType

    global __cusparseSetMatIndexBase
    data["__cusparseSetMatIndexBase"] = <intptr_t>__cusparseSetMatIndexBase

    global __cusparseGetMatIndexBase
    data["__cusparseGetMatIndexBase"] = <intptr_t>__cusparseGetMatIndexBase

    global __cusparseCreateCsric02Info
    data["__cusparseCreateCsric02Info"] = <intptr_t>__cusparseCreateCsric02Info

    global __cusparseDestroyCsric02Info
    data["__cusparseDestroyCsric02Info"] = <intptr_t>__cusparseDestroyCsric02Info

    global __cusparseCreateBsric02Info
    data["__cusparseCreateBsric02Info"] = <intptr_t>__cusparseCreateBsric02Info

    global __cusparseDestroyBsric02Info
    data["__cusparseDestroyBsric02Info"] = <intptr_t>__cusparseDestroyBsric02Info

    global __cusparseCreateCsrilu02Info
    data["__cusparseCreateCsrilu02Info"] = <intptr_t>__cusparseCreateCsrilu02Info

    global __cusparseDestroyCsrilu02Info
    data["__cusparseDestroyCsrilu02Info"] = <intptr_t>__cusparseDestroyCsrilu02Info

    global __cusparseCreateBsrilu02Info
    data["__cusparseCreateBsrilu02Info"] = <intptr_t>__cusparseCreateBsrilu02Info

    global __cusparseDestroyBsrilu02Info
    data["__cusparseDestroyBsrilu02Info"] = <intptr_t>__cusparseDestroyBsrilu02Info

    global __cusparseCreateBsrsv2Info
    data["__cusparseCreateBsrsv2Info"] = <intptr_t>__cusparseCreateBsrsv2Info

    global __cusparseDestroyBsrsv2Info
    data["__cusparseDestroyBsrsv2Info"] = <intptr_t>__cusparseDestroyBsrsv2Info

    global __cusparseCreateBsrsm2Info
    data["__cusparseCreateBsrsm2Info"] = <intptr_t>__cusparseCreateBsrsm2Info

    global __cusparseDestroyBsrsm2Info
    data["__cusparseDestroyBsrsm2Info"] = <intptr_t>__cusparseDestroyBsrsm2Info

    global __cusparseCreateCsru2csrInfo
    data["__cusparseCreateCsru2csrInfo"] = <intptr_t>__cusparseCreateCsru2csrInfo

    global __cusparseDestroyCsru2csrInfo
    data["__cusparseDestroyCsru2csrInfo"] = <intptr_t>__cusparseDestroyCsru2csrInfo

    global __cusparseCreateColorInfo
    data["__cusparseCreateColorInfo"] = <intptr_t>__cusparseCreateColorInfo

    global __cusparseDestroyColorInfo
    data["__cusparseDestroyColorInfo"] = <intptr_t>__cusparseDestroyColorInfo

    global __cusparseSetColorAlgs
    data["__cusparseSetColorAlgs"] = <intptr_t>__cusparseSetColorAlgs

    global __cusparseGetColorAlgs
    data["__cusparseGetColorAlgs"] = <intptr_t>__cusparseGetColorAlgs

    global __cusparseCreatePruneInfo
    data["__cusparseCreatePruneInfo"] = <intptr_t>__cusparseCreatePruneInfo

    global __cusparseDestroyPruneInfo
    data["__cusparseDestroyPruneInfo"] = <intptr_t>__cusparseDestroyPruneInfo

    global __cusparseSgemvi
    data["__cusparseSgemvi"] = <intptr_t>__cusparseSgemvi

    global __cusparseSgemvi_bufferSize
    data["__cusparseSgemvi_bufferSize"] = <intptr_t>__cusparseSgemvi_bufferSize

    global __cusparseDgemvi
    data["__cusparseDgemvi"] = <intptr_t>__cusparseDgemvi

    global __cusparseDgemvi_bufferSize
    data["__cusparseDgemvi_bufferSize"] = <intptr_t>__cusparseDgemvi_bufferSize

    global __cusparseCgemvi
    data["__cusparseCgemvi"] = <intptr_t>__cusparseCgemvi

    global __cusparseCgemvi_bufferSize
    data["__cusparseCgemvi_bufferSize"] = <intptr_t>__cusparseCgemvi_bufferSize

    global __cusparseZgemvi
    data["__cusparseZgemvi"] = <intptr_t>__cusparseZgemvi

    global __cusparseZgemvi_bufferSize
    data["__cusparseZgemvi_bufferSize"] = <intptr_t>__cusparseZgemvi_bufferSize

    global __cusparseSbsrmv
    data["__cusparseSbsrmv"] = <intptr_t>__cusparseSbsrmv

    global __cusparseDbsrmv
    data["__cusparseDbsrmv"] = <intptr_t>__cusparseDbsrmv

    global __cusparseCbsrmv
    data["__cusparseCbsrmv"] = <intptr_t>__cusparseCbsrmv

    global __cusparseZbsrmv
    data["__cusparseZbsrmv"] = <intptr_t>__cusparseZbsrmv

    global __cusparseSbsrxmv
    data["__cusparseSbsrxmv"] = <intptr_t>__cusparseSbsrxmv

    global __cusparseDbsrxmv
    data["__cusparseDbsrxmv"] = <intptr_t>__cusparseDbsrxmv

    global __cusparseCbsrxmv
    data["__cusparseCbsrxmv"] = <intptr_t>__cusparseCbsrxmv

    global __cusparseZbsrxmv
    data["__cusparseZbsrxmv"] = <intptr_t>__cusparseZbsrxmv

    global __cusparseXbsrsv2_zeroPivot
    data["__cusparseXbsrsv2_zeroPivot"] = <intptr_t>__cusparseXbsrsv2_zeroPivot

    global __cusparseSbsrsv2_bufferSize
    data["__cusparseSbsrsv2_bufferSize"] = <intptr_t>__cusparseSbsrsv2_bufferSize

    global __cusparseDbsrsv2_bufferSize
    data["__cusparseDbsrsv2_bufferSize"] = <intptr_t>__cusparseDbsrsv2_bufferSize

    global __cusparseCbsrsv2_bufferSize
    data["__cusparseCbsrsv2_bufferSize"] = <intptr_t>__cusparseCbsrsv2_bufferSize

    global __cusparseZbsrsv2_bufferSize
    data["__cusparseZbsrsv2_bufferSize"] = <intptr_t>__cusparseZbsrsv2_bufferSize

    global __cusparseSbsrsv2_bufferSizeExt
    data["__cusparseSbsrsv2_bufferSizeExt"] = <intptr_t>__cusparseSbsrsv2_bufferSizeExt

    global __cusparseDbsrsv2_bufferSizeExt
    data["__cusparseDbsrsv2_bufferSizeExt"] = <intptr_t>__cusparseDbsrsv2_bufferSizeExt

    global __cusparseCbsrsv2_bufferSizeExt
    data["__cusparseCbsrsv2_bufferSizeExt"] = <intptr_t>__cusparseCbsrsv2_bufferSizeExt

    global __cusparseZbsrsv2_bufferSizeExt
    data["__cusparseZbsrsv2_bufferSizeExt"] = <intptr_t>__cusparseZbsrsv2_bufferSizeExt

    global __cusparseSbsrsv2_analysis
    data["__cusparseSbsrsv2_analysis"] = <intptr_t>__cusparseSbsrsv2_analysis

    global __cusparseDbsrsv2_analysis
    data["__cusparseDbsrsv2_analysis"] = <intptr_t>__cusparseDbsrsv2_analysis

    global __cusparseCbsrsv2_analysis
    data["__cusparseCbsrsv2_analysis"] = <intptr_t>__cusparseCbsrsv2_analysis

    global __cusparseZbsrsv2_analysis
    data["__cusparseZbsrsv2_analysis"] = <intptr_t>__cusparseZbsrsv2_analysis

    global __cusparseSbsrsv2_solve
    data["__cusparseSbsrsv2_solve"] = <intptr_t>__cusparseSbsrsv2_solve

    global __cusparseDbsrsv2_solve
    data["__cusparseDbsrsv2_solve"] = <intptr_t>__cusparseDbsrsv2_solve

    global __cusparseCbsrsv2_solve
    data["__cusparseCbsrsv2_solve"] = <intptr_t>__cusparseCbsrsv2_solve

    global __cusparseZbsrsv2_solve
    data["__cusparseZbsrsv2_solve"] = <intptr_t>__cusparseZbsrsv2_solve

    global __cusparseSbsrmm
    data["__cusparseSbsrmm"] = <intptr_t>__cusparseSbsrmm

    global __cusparseDbsrmm
    data["__cusparseDbsrmm"] = <intptr_t>__cusparseDbsrmm

    global __cusparseCbsrmm
    data["__cusparseCbsrmm"] = <intptr_t>__cusparseCbsrmm

    global __cusparseZbsrmm
    data["__cusparseZbsrmm"] = <intptr_t>__cusparseZbsrmm

    global __cusparseXbsrsm2_zeroPivot
    data["__cusparseXbsrsm2_zeroPivot"] = <intptr_t>__cusparseXbsrsm2_zeroPivot

    global __cusparseSbsrsm2_bufferSize
    data["__cusparseSbsrsm2_bufferSize"] = <intptr_t>__cusparseSbsrsm2_bufferSize

    global __cusparseDbsrsm2_bufferSize
    data["__cusparseDbsrsm2_bufferSize"] = <intptr_t>__cusparseDbsrsm2_bufferSize

    global __cusparseCbsrsm2_bufferSize
    data["__cusparseCbsrsm2_bufferSize"] = <intptr_t>__cusparseCbsrsm2_bufferSize

    global __cusparseZbsrsm2_bufferSize
    data["__cusparseZbsrsm2_bufferSize"] = <intptr_t>__cusparseZbsrsm2_bufferSize

    global __cusparseSbsrsm2_bufferSizeExt
    data["__cusparseSbsrsm2_bufferSizeExt"] = <intptr_t>__cusparseSbsrsm2_bufferSizeExt

    global __cusparseDbsrsm2_bufferSizeExt
    data["__cusparseDbsrsm2_bufferSizeExt"] = <intptr_t>__cusparseDbsrsm2_bufferSizeExt

    global __cusparseCbsrsm2_bufferSizeExt
    data["__cusparseCbsrsm2_bufferSizeExt"] = <intptr_t>__cusparseCbsrsm2_bufferSizeExt

    global __cusparseZbsrsm2_bufferSizeExt
    data["__cusparseZbsrsm2_bufferSizeExt"] = <intptr_t>__cusparseZbsrsm2_bufferSizeExt

    global __cusparseSbsrsm2_analysis
    data["__cusparseSbsrsm2_analysis"] = <intptr_t>__cusparseSbsrsm2_analysis

    global __cusparseDbsrsm2_analysis
    data["__cusparseDbsrsm2_analysis"] = <intptr_t>__cusparseDbsrsm2_analysis

    global __cusparseCbsrsm2_analysis
    data["__cusparseCbsrsm2_analysis"] = <intptr_t>__cusparseCbsrsm2_analysis

    global __cusparseZbsrsm2_analysis
    data["__cusparseZbsrsm2_analysis"] = <intptr_t>__cusparseZbsrsm2_analysis

    global __cusparseSbsrsm2_solve
    data["__cusparseSbsrsm2_solve"] = <intptr_t>__cusparseSbsrsm2_solve

    global __cusparseDbsrsm2_solve
    data["__cusparseDbsrsm2_solve"] = <intptr_t>__cusparseDbsrsm2_solve

    global __cusparseCbsrsm2_solve
    data["__cusparseCbsrsm2_solve"] = <intptr_t>__cusparseCbsrsm2_solve

    global __cusparseZbsrsm2_solve
    data["__cusparseZbsrsm2_solve"] = <intptr_t>__cusparseZbsrsm2_solve

    global __cusparseScsrilu02_numericBoost
    data["__cusparseScsrilu02_numericBoost"] = <intptr_t>__cusparseScsrilu02_numericBoost

    global __cusparseDcsrilu02_numericBoost
    data["__cusparseDcsrilu02_numericBoost"] = <intptr_t>__cusparseDcsrilu02_numericBoost

    global __cusparseCcsrilu02_numericBoost
    data["__cusparseCcsrilu02_numericBoost"] = <intptr_t>__cusparseCcsrilu02_numericBoost

    global __cusparseZcsrilu02_numericBoost
    data["__cusparseZcsrilu02_numericBoost"] = <intptr_t>__cusparseZcsrilu02_numericBoost

    global __cusparseXcsrilu02_zeroPivot
    data["__cusparseXcsrilu02_zeroPivot"] = <intptr_t>__cusparseXcsrilu02_zeroPivot

    global __cusparseScsrilu02_bufferSize
    data["__cusparseScsrilu02_bufferSize"] = <intptr_t>__cusparseScsrilu02_bufferSize

    global __cusparseDcsrilu02_bufferSize
    data["__cusparseDcsrilu02_bufferSize"] = <intptr_t>__cusparseDcsrilu02_bufferSize

    global __cusparseCcsrilu02_bufferSize
    data["__cusparseCcsrilu02_bufferSize"] = <intptr_t>__cusparseCcsrilu02_bufferSize

    global __cusparseZcsrilu02_bufferSize
    data["__cusparseZcsrilu02_bufferSize"] = <intptr_t>__cusparseZcsrilu02_bufferSize

    global __cusparseScsrilu02_bufferSizeExt
    data["__cusparseScsrilu02_bufferSizeExt"] = <intptr_t>__cusparseScsrilu02_bufferSizeExt

    global __cusparseDcsrilu02_bufferSizeExt
    data["__cusparseDcsrilu02_bufferSizeExt"] = <intptr_t>__cusparseDcsrilu02_bufferSizeExt

    global __cusparseCcsrilu02_bufferSizeExt
    data["__cusparseCcsrilu02_bufferSizeExt"] = <intptr_t>__cusparseCcsrilu02_bufferSizeExt

    global __cusparseZcsrilu02_bufferSizeExt
    data["__cusparseZcsrilu02_bufferSizeExt"] = <intptr_t>__cusparseZcsrilu02_bufferSizeExt

    global __cusparseScsrilu02_analysis
    data["__cusparseScsrilu02_analysis"] = <intptr_t>__cusparseScsrilu02_analysis

    global __cusparseDcsrilu02_analysis
    data["__cusparseDcsrilu02_analysis"] = <intptr_t>__cusparseDcsrilu02_analysis

    global __cusparseCcsrilu02_analysis
    data["__cusparseCcsrilu02_analysis"] = <intptr_t>__cusparseCcsrilu02_analysis

    global __cusparseZcsrilu02_analysis
    data["__cusparseZcsrilu02_analysis"] = <intptr_t>__cusparseZcsrilu02_analysis

    global __cusparseScsrilu02
    data["__cusparseScsrilu02"] = <intptr_t>__cusparseScsrilu02

    global __cusparseDcsrilu02
    data["__cusparseDcsrilu02"] = <intptr_t>__cusparseDcsrilu02

    global __cusparseCcsrilu02
    data["__cusparseCcsrilu02"] = <intptr_t>__cusparseCcsrilu02

    global __cusparseZcsrilu02
    data["__cusparseZcsrilu02"] = <intptr_t>__cusparseZcsrilu02

    global __cusparseSbsrilu02_numericBoost
    data["__cusparseSbsrilu02_numericBoost"] = <intptr_t>__cusparseSbsrilu02_numericBoost

    global __cusparseDbsrilu02_numericBoost
    data["__cusparseDbsrilu02_numericBoost"] = <intptr_t>__cusparseDbsrilu02_numericBoost

    global __cusparseCbsrilu02_numericBoost
    data["__cusparseCbsrilu02_numericBoost"] = <intptr_t>__cusparseCbsrilu02_numericBoost

    global __cusparseZbsrilu02_numericBoost
    data["__cusparseZbsrilu02_numericBoost"] = <intptr_t>__cusparseZbsrilu02_numericBoost

    global __cusparseXbsrilu02_zeroPivot
    data["__cusparseXbsrilu02_zeroPivot"] = <intptr_t>__cusparseXbsrilu02_zeroPivot

    global __cusparseSbsrilu02_bufferSize
    data["__cusparseSbsrilu02_bufferSize"] = <intptr_t>__cusparseSbsrilu02_bufferSize

    global __cusparseDbsrilu02_bufferSize
    data["__cusparseDbsrilu02_bufferSize"] = <intptr_t>__cusparseDbsrilu02_bufferSize

    global __cusparseCbsrilu02_bufferSize
    data["__cusparseCbsrilu02_bufferSize"] = <intptr_t>__cusparseCbsrilu02_bufferSize

    global __cusparseZbsrilu02_bufferSize
    data["__cusparseZbsrilu02_bufferSize"] = <intptr_t>__cusparseZbsrilu02_bufferSize

    global __cusparseSbsrilu02_bufferSizeExt
    data["__cusparseSbsrilu02_bufferSizeExt"] = <intptr_t>__cusparseSbsrilu02_bufferSizeExt

    global __cusparseDbsrilu02_bufferSizeExt
    data["__cusparseDbsrilu02_bufferSizeExt"] = <intptr_t>__cusparseDbsrilu02_bufferSizeExt

    global __cusparseCbsrilu02_bufferSizeExt
    data["__cusparseCbsrilu02_bufferSizeExt"] = <intptr_t>__cusparseCbsrilu02_bufferSizeExt

    global __cusparseZbsrilu02_bufferSizeExt
    data["__cusparseZbsrilu02_bufferSizeExt"] = <intptr_t>__cusparseZbsrilu02_bufferSizeExt

    global __cusparseSbsrilu02_analysis
    data["__cusparseSbsrilu02_analysis"] = <intptr_t>__cusparseSbsrilu02_analysis

    global __cusparseDbsrilu02_analysis
    data["__cusparseDbsrilu02_analysis"] = <intptr_t>__cusparseDbsrilu02_analysis

    global __cusparseCbsrilu02_analysis
    data["__cusparseCbsrilu02_analysis"] = <intptr_t>__cusparseCbsrilu02_analysis

    global __cusparseZbsrilu02_analysis
    data["__cusparseZbsrilu02_analysis"] = <intptr_t>__cusparseZbsrilu02_analysis

    global __cusparseSbsrilu02
    data["__cusparseSbsrilu02"] = <intptr_t>__cusparseSbsrilu02

    global __cusparseDbsrilu02
    data["__cusparseDbsrilu02"] = <intptr_t>__cusparseDbsrilu02

    global __cusparseCbsrilu02
    data["__cusparseCbsrilu02"] = <intptr_t>__cusparseCbsrilu02

    global __cusparseZbsrilu02
    data["__cusparseZbsrilu02"] = <intptr_t>__cusparseZbsrilu02

    global __cusparseXcsric02_zeroPivot
    data["__cusparseXcsric02_zeroPivot"] = <intptr_t>__cusparseXcsric02_zeroPivot

    global __cusparseScsric02_bufferSize
    data["__cusparseScsric02_bufferSize"] = <intptr_t>__cusparseScsric02_bufferSize

    global __cusparseDcsric02_bufferSize
    data["__cusparseDcsric02_bufferSize"] = <intptr_t>__cusparseDcsric02_bufferSize

    global __cusparseCcsric02_bufferSize
    data["__cusparseCcsric02_bufferSize"] = <intptr_t>__cusparseCcsric02_bufferSize

    global __cusparseZcsric02_bufferSize
    data["__cusparseZcsric02_bufferSize"] = <intptr_t>__cusparseZcsric02_bufferSize

    global __cusparseScsric02_bufferSizeExt
    data["__cusparseScsric02_bufferSizeExt"] = <intptr_t>__cusparseScsric02_bufferSizeExt

    global __cusparseDcsric02_bufferSizeExt
    data["__cusparseDcsric02_bufferSizeExt"] = <intptr_t>__cusparseDcsric02_bufferSizeExt

    global __cusparseCcsric02_bufferSizeExt
    data["__cusparseCcsric02_bufferSizeExt"] = <intptr_t>__cusparseCcsric02_bufferSizeExt

    global __cusparseZcsric02_bufferSizeExt
    data["__cusparseZcsric02_bufferSizeExt"] = <intptr_t>__cusparseZcsric02_bufferSizeExt

    global __cusparseScsric02_analysis
    data["__cusparseScsric02_analysis"] = <intptr_t>__cusparseScsric02_analysis

    global __cusparseDcsric02_analysis
    data["__cusparseDcsric02_analysis"] = <intptr_t>__cusparseDcsric02_analysis

    global __cusparseCcsric02_analysis
    data["__cusparseCcsric02_analysis"] = <intptr_t>__cusparseCcsric02_analysis

    global __cusparseZcsric02_analysis
    data["__cusparseZcsric02_analysis"] = <intptr_t>__cusparseZcsric02_analysis

    global __cusparseScsric02
    data["__cusparseScsric02"] = <intptr_t>__cusparseScsric02

    global __cusparseDcsric02
    data["__cusparseDcsric02"] = <intptr_t>__cusparseDcsric02

    global __cusparseCcsric02
    data["__cusparseCcsric02"] = <intptr_t>__cusparseCcsric02

    global __cusparseZcsric02
    data["__cusparseZcsric02"] = <intptr_t>__cusparseZcsric02

    global __cusparseXbsric02_zeroPivot
    data["__cusparseXbsric02_zeroPivot"] = <intptr_t>__cusparseXbsric02_zeroPivot

    global __cusparseSbsric02_bufferSize
    data["__cusparseSbsric02_bufferSize"] = <intptr_t>__cusparseSbsric02_bufferSize

    global __cusparseDbsric02_bufferSize
    data["__cusparseDbsric02_bufferSize"] = <intptr_t>__cusparseDbsric02_bufferSize

    global __cusparseCbsric02_bufferSize
    data["__cusparseCbsric02_bufferSize"] = <intptr_t>__cusparseCbsric02_bufferSize

    global __cusparseZbsric02_bufferSize
    data["__cusparseZbsric02_bufferSize"] = <intptr_t>__cusparseZbsric02_bufferSize

    global __cusparseSbsric02_bufferSizeExt
    data["__cusparseSbsric02_bufferSizeExt"] = <intptr_t>__cusparseSbsric02_bufferSizeExt

    global __cusparseDbsric02_bufferSizeExt
    data["__cusparseDbsric02_bufferSizeExt"] = <intptr_t>__cusparseDbsric02_bufferSizeExt

    global __cusparseCbsric02_bufferSizeExt
    data["__cusparseCbsric02_bufferSizeExt"] = <intptr_t>__cusparseCbsric02_bufferSizeExt

    global __cusparseZbsric02_bufferSizeExt
    data["__cusparseZbsric02_bufferSizeExt"] = <intptr_t>__cusparseZbsric02_bufferSizeExt

    global __cusparseSbsric02_analysis
    data["__cusparseSbsric02_analysis"] = <intptr_t>__cusparseSbsric02_analysis

    global __cusparseDbsric02_analysis
    data["__cusparseDbsric02_analysis"] = <intptr_t>__cusparseDbsric02_analysis

    global __cusparseCbsric02_analysis
    data["__cusparseCbsric02_analysis"] = <intptr_t>__cusparseCbsric02_analysis

    global __cusparseZbsric02_analysis
    data["__cusparseZbsric02_analysis"] = <intptr_t>__cusparseZbsric02_analysis

    global __cusparseSbsric02
    data["__cusparseSbsric02"] = <intptr_t>__cusparseSbsric02

    global __cusparseDbsric02
    data["__cusparseDbsric02"] = <intptr_t>__cusparseDbsric02

    global __cusparseCbsric02
    data["__cusparseCbsric02"] = <intptr_t>__cusparseCbsric02

    global __cusparseZbsric02
    data["__cusparseZbsric02"] = <intptr_t>__cusparseZbsric02

    global __cusparseSgtsv2_bufferSizeExt
    data["__cusparseSgtsv2_bufferSizeExt"] = <intptr_t>__cusparseSgtsv2_bufferSizeExt

    global __cusparseDgtsv2_bufferSizeExt
    data["__cusparseDgtsv2_bufferSizeExt"] = <intptr_t>__cusparseDgtsv2_bufferSizeExt

    global __cusparseCgtsv2_bufferSizeExt
    data["__cusparseCgtsv2_bufferSizeExt"] = <intptr_t>__cusparseCgtsv2_bufferSizeExt

    global __cusparseZgtsv2_bufferSizeExt
    data["__cusparseZgtsv2_bufferSizeExt"] = <intptr_t>__cusparseZgtsv2_bufferSizeExt

    global __cusparseSgtsv2
    data["__cusparseSgtsv2"] = <intptr_t>__cusparseSgtsv2

    global __cusparseDgtsv2
    data["__cusparseDgtsv2"] = <intptr_t>__cusparseDgtsv2

    global __cusparseCgtsv2
    data["__cusparseCgtsv2"] = <intptr_t>__cusparseCgtsv2

    global __cusparseZgtsv2
    data["__cusparseZgtsv2"] = <intptr_t>__cusparseZgtsv2

    global __cusparseSgtsv2_nopivot_bufferSizeExt
    data["__cusparseSgtsv2_nopivot_bufferSizeExt"] = <intptr_t>__cusparseSgtsv2_nopivot_bufferSizeExt

    global __cusparseDgtsv2_nopivot_bufferSizeExt
    data["__cusparseDgtsv2_nopivot_bufferSizeExt"] = <intptr_t>__cusparseDgtsv2_nopivot_bufferSizeExt

    global __cusparseCgtsv2_nopivot_bufferSizeExt
    data["__cusparseCgtsv2_nopivot_bufferSizeExt"] = <intptr_t>__cusparseCgtsv2_nopivot_bufferSizeExt

    global __cusparseZgtsv2_nopivot_bufferSizeExt
    data["__cusparseZgtsv2_nopivot_bufferSizeExt"] = <intptr_t>__cusparseZgtsv2_nopivot_bufferSizeExt

    global __cusparseSgtsv2_nopivot
    data["__cusparseSgtsv2_nopivot"] = <intptr_t>__cusparseSgtsv2_nopivot

    global __cusparseDgtsv2_nopivot
    data["__cusparseDgtsv2_nopivot"] = <intptr_t>__cusparseDgtsv2_nopivot

    global __cusparseCgtsv2_nopivot
    data["__cusparseCgtsv2_nopivot"] = <intptr_t>__cusparseCgtsv2_nopivot

    global __cusparseZgtsv2_nopivot
    data["__cusparseZgtsv2_nopivot"] = <intptr_t>__cusparseZgtsv2_nopivot

    global __cusparseSgtsv2StridedBatch_bufferSizeExt
    data["__cusparseSgtsv2StridedBatch_bufferSizeExt"] = <intptr_t>__cusparseSgtsv2StridedBatch_bufferSizeExt

    global __cusparseDgtsv2StridedBatch_bufferSizeExt
    data["__cusparseDgtsv2StridedBatch_bufferSizeExt"] = <intptr_t>__cusparseDgtsv2StridedBatch_bufferSizeExt

    global __cusparseCgtsv2StridedBatch_bufferSizeExt
    data["__cusparseCgtsv2StridedBatch_bufferSizeExt"] = <intptr_t>__cusparseCgtsv2StridedBatch_bufferSizeExt

    global __cusparseZgtsv2StridedBatch_bufferSizeExt
    data["__cusparseZgtsv2StridedBatch_bufferSizeExt"] = <intptr_t>__cusparseZgtsv2StridedBatch_bufferSizeExt

    global __cusparseSgtsv2StridedBatch
    data["__cusparseSgtsv2StridedBatch"] = <intptr_t>__cusparseSgtsv2StridedBatch

    global __cusparseDgtsv2StridedBatch
    data["__cusparseDgtsv2StridedBatch"] = <intptr_t>__cusparseDgtsv2StridedBatch

    global __cusparseCgtsv2StridedBatch
    data["__cusparseCgtsv2StridedBatch"] = <intptr_t>__cusparseCgtsv2StridedBatch

    global __cusparseZgtsv2StridedBatch
    data["__cusparseZgtsv2StridedBatch"] = <intptr_t>__cusparseZgtsv2StridedBatch

    global __cusparseSgtsvInterleavedBatch_bufferSizeExt
    data["__cusparseSgtsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseSgtsvInterleavedBatch_bufferSizeExt

    global __cusparseDgtsvInterleavedBatch_bufferSizeExt
    data["__cusparseDgtsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseDgtsvInterleavedBatch_bufferSizeExt

    global __cusparseCgtsvInterleavedBatch_bufferSizeExt
    data["__cusparseCgtsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseCgtsvInterleavedBatch_bufferSizeExt

    global __cusparseZgtsvInterleavedBatch_bufferSizeExt
    data["__cusparseZgtsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseZgtsvInterleavedBatch_bufferSizeExt

    global __cusparseSgtsvInterleavedBatch
    data["__cusparseSgtsvInterleavedBatch"] = <intptr_t>__cusparseSgtsvInterleavedBatch

    global __cusparseDgtsvInterleavedBatch
    data["__cusparseDgtsvInterleavedBatch"] = <intptr_t>__cusparseDgtsvInterleavedBatch

    global __cusparseCgtsvInterleavedBatch
    data["__cusparseCgtsvInterleavedBatch"] = <intptr_t>__cusparseCgtsvInterleavedBatch

    global __cusparseZgtsvInterleavedBatch
    data["__cusparseZgtsvInterleavedBatch"] = <intptr_t>__cusparseZgtsvInterleavedBatch

    global __cusparseSgpsvInterleavedBatch_bufferSizeExt
    data["__cusparseSgpsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseSgpsvInterleavedBatch_bufferSizeExt

    global __cusparseDgpsvInterleavedBatch_bufferSizeExt
    data["__cusparseDgpsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseDgpsvInterleavedBatch_bufferSizeExt

    global __cusparseCgpsvInterleavedBatch_bufferSizeExt
    data["__cusparseCgpsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseCgpsvInterleavedBatch_bufferSizeExt

    global __cusparseZgpsvInterleavedBatch_bufferSizeExt
    data["__cusparseZgpsvInterleavedBatch_bufferSizeExt"] = <intptr_t>__cusparseZgpsvInterleavedBatch_bufferSizeExt

    global __cusparseSgpsvInterleavedBatch
    data["__cusparseSgpsvInterleavedBatch"] = <intptr_t>__cusparseSgpsvInterleavedBatch

    global __cusparseDgpsvInterleavedBatch
    data["__cusparseDgpsvInterleavedBatch"] = <intptr_t>__cusparseDgpsvInterleavedBatch

    global __cusparseCgpsvInterleavedBatch
    data["__cusparseCgpsvInterleavedBatch"] = <intptr_t>__cusparseCgpsvInterleavedBatch

    global __cusparseZgpsvInterleavedBatch
    data["__cusparseZgpsvInterleavedBatch"] = <intptr_t>__cusparseZgpsvInterleavedBatch

    global __cusparseScsrgeam2_bufferSizeExt
    data["__cusparseScsrgeam2_bufferSizeExt"] = <intptr_t>__cusparseScsrgeam2_bufferSizeExt

    global __cusparseDcsrgeam2_bufferSizeExt
    data["__cusparseDcsrgeam2_bufferSizeExt"] = <intptr_t>__cusparseDcsrgeam2_bufferSizeExt

    global __cusparseCcsrgeam2_bufferSizeExt
    data["__cusparseCcsrgeam2_bufferSizeExt"] = <intptr_t>__cusparseCcsrgeam2_bufferSizeExt

    global __cusparseZcsrgeam2_bufferSizeExt
    data["__cusparseZcsrgeam2_bufferSizeExt"] = <intptr_t>__cusparseZcsrgeam2_bufferSizeExt

    global __cusparseXcsrgeam2Nnz
    data["__cusparseXcsrgeam2Nnz"] = <intptr_t>__cusparseXcsrgeam2Nnz

    global __cusparseScsrgeam2
    data["__cusparseScsrgeam2"] = <intptr_t>__cusparseScsrgeam2

    global __cusparseDcsrgeam2
    data["__cusparseDcsrgeam2"] = <intptr_t>__cusparseDcsrgeam2

    global __cusparseCcsrgeam2
    data["__cusparseCcsrgeam2"] = <intptr_t>__cusparseCcsrgeam2

    global __cusparseZcsrgeam2
    data["__cusparseZcsrgeam2"] = <intptr_t>__cusparseZcsrgeam2

    global __cusparseScsrcolor
    data["__cusparseScsrcolor"] = <intptr_t>__cusparseScsrcolor

    global __cusparseDcsrcolor
    data["__cusparseDcsrcolor"] = <intptr_t>__cusparseDcsrcolor

    global __cusparseCcsrcolor
    data["__cusparseCcsrcolor"] = <intptr_t>__cusparseCcsrcolor

    global __cusparseZcsrcolor
    data["__cusparseZcsrcolor"] = <intptr_t>__cusparseZcsrcolor

    global __cusparseSnnz
    data["__cusparseSnnz"] = <intptr_t>__cusparseSnnz

    global __cusparseDnnz
    data["__cusparseDnnz"] = <intptr_t>__cusparseDnnz

    global __cusparseCnnz
    data["__cusparseCnnz"] = <intptr_t>__cusparseCnnz

    global __cusparseZnnz
    data["__cusparseZnnz"] = <intptr_t>__cusparseZnnz

    global __cusparseSnnz_compress
    data["__cusparseSnnz_compress"] = <intptr_t>__cusparseSnnz_compress

    global __cusparseDnnz_compress
    data["__cusparseDnnz_compress"] = <intptr_t>__cusparseDnnz_compress

    global __cusparseCnnz_compress
    data["__cusparseCnnz_compress"] = <intptr_t>__cusparseCnnz_compress

    global __cusparseZnnz_compress
    data["__cusparseZnnz_compress"] = <intptr_t>__cusparseZnnz_compress

    global __cusparseScsr2csr_compress
    data["__cusparseScsr2csr_compress"] = <intptr_t>__cusparseScsr2csr_compress

    global __cusparseDcsr2csr_compress
    data["__cusparseDcsr2csr_compress"] = <intptr_t>__cusparseDcsr2csr_compress

    global __cusparseCcsr2csr_compress
    data["__cusparseCcsr2csr_compress"] = <intptr_t>__cusparseCcsr2csr_compress

    global __cusparseZcsr2csr_compress
    data["__cusparseZcsr2csr_compress"] = <intptr_t>__cusparseZcsr2csr_compress

    global __cusparseXcoo2csr
    data["__cusparseXcoo2csr"] = <intptr_t>__cusparseXcoo2csr

    global __cusparseXcsr2coo
    data["__cusparseXcsr2coo"] = <intptr_t>__cusparseXcsr2coo

    global __cusparseXcsr2bsrNnz
    data["__cusparseXcsr2bsrNnz"] = <intptr_t>__cusparseXcsr2bsrNnz

    global __cusparseScsr2bsr
    data["__cusparseScsr2bsr"] = <intptr_t>__cusparseScsr2bsr

    global __cusparseDcsr2bsr
    data["__cusparseDcsr2bsr"] = <intptr_t>__cusparseDcsr2bsr

    global __cusparseCcsr2bsr
    data["__cusparseCcsr2bsr"] = <intptr_t>__cusparseCcsr2bsr

    global __cusparseZcsr2bsr
    data["__cusparseZcsr2bsr"] = <intptr_t>__cusparseZcsr2bsr

    global __cusparseSbsr2csr
    data["__cusparseSbsr2csr"] = <intptr_t>__cusparseSbsr2csr

    global __cusparseDbsr2csr
    data["__cusparseDbsr2csr"] = <intptr_t>__cusparseDbsr2csr

    global __cusparseCbsr2csr
    data["__cusparseCbsr2csr"] = <intptr_t>__cusparseCbsr2csr

    global __cusparseZbsr2csr
    data["__cusparseZbsr2csr"] = <intptr_t>__cusparseZbsr2csr

    global __cusparseSgebsr2gebsc_bufferSize
    data["__cusparseSgebsr2gebsc_bufferSize"] = <intptr_t>__cusparseSgebsr2gebsc_bufferSize

    global __cusparseDgebsr2gebsc_bufferSize
    data["__cusparseDgebsr2gebsc_bufferSize"] = <intptr_t>__cusparseDgebsr2gebsc_bufferSize

    global __cusparseCgebsr2gebsc_bufferSize
    data["__cusparseCgebsr2gebsc_bufferSize"] = <intptr_t>__cusparseCgebsr2gebsc_bufferSize

    global __cusparseZgebsr2gebsc_bufferSize
    data["__cusparseZgebsr2gebsc_bufferSize"] = <intptr_t>__cusparseZgebsr2gebsc_bufferSize

    global __cusparseSgebsr2gebsc_bufferSizeExt
    data["__cusparseSgebsr2gebsc_bufferSizeExt"] = <intptr_t>__cusparseSgebsr2gebsc_bufferSizeExt

    global __cusparseDgebsr2gebsc_bufferSizeExt
    data["__cusparseDgebsr2gebsc_bufferSizeExt"] = <intptr_t>__cusparseDgebsr2gebsc_bufferSizeExt

    global __cusparseCgebsr2gebsc_bufferSizeExt
    data["__cusparseCgebsr2gebsc_bufferSizeExt"] = <intptr_t>__cusparseCgebsr2gebsc_bufferSizeExt

    global __cusparseZgebsr2gebsc_bufferSizeExt
    data["__cusparseZgebsr2gebsc_bufferSizeExt"] = <intptr_t>__cusparseZgebsr2gebsc_bufferSizeExt

    global __cusparseSgebsr2gebsc
    data["__cusparseSgebsr2gebsc"] = <intptr_t>__cusparseSgebsr2gebsc

    global __cusparseDgebsr2gebsc
    data["__cusparseDgebsr2gebsc"] = <intptr_t>__cusparseDgebsr2gebsc

    global __cusparseCgebsr2gebsc
    data["__cusparseCgebsr2gebsc"] = <intptr_t>__cusparseCgebsr2gebsc

    global __cusparseZgebsr2gebsc
    data["__cusparseZgebsr2gebsc"] = <intptr_t>__cusparseZgebsr2gebsc

    global __cusparseXgebsr2csr
    data["__cusparseXgebsr2csr"] = <intptr_t>__cusparseXgebsr2csr

    global __cusparseSgebsr2csr
    data["__cusparseSgebsr2csr"] = <intptr_t>__cusparseSgebsr2csr

    global __cusparseDgebsr2csr
    data["__cusparseDgebsr2csr"] = <intptr_t>__cusparseDgebsr2csr

    global __cusparseCgebsr2csr
    data["__cusparseCgebsr2csr"] = <intptr_t>__cusparseCgebsr2csr

    global __cusparseZgebsr2csr
    data["__cusparseZgebsr2csr"] = <intptr_t>__cusparseZgebsr2csr

    global __cusparseScsr2gebsr_bufferSize
    data["__cusparseScsr2gebsr_bufferSize"] = <intptr_t>__cusparseScsr2gebsr_bufferSize

    global __cusparseDcsr2gebsr_bufferSize
    data["__cusparseDcsr2gebsr_bufferSize"] = <intptr_t>__cusparseDcsr2gebsr_bufferSize

    global __cusparseCcsr2gebsr_bufferSize
    data["__cusparseCcsr2gebsr_bufferSize"] = <intptr_t>__cusparseCcsr2gebsr_bufferSize

    global __cusparseZcsr2gebsr_bufferSize
    data["__cusparseZcsr2gebsr_bufferSize"] = <intptr_t>__cusparseZcsr2gebsr_bufferSize

    global __cusparseScsr2gebsr_bufferSizeExt
    data["__cusparseScsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseScsr2gebsr_bufferSizeExt

    global __cusparseDcsr2gebsr_bufferSizeExt
    data["__cusparseDcsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseDcsr2gebsr_bufferSizeExt

    global __cusparseCcsr2gebsr_bufferSizeExt
    data["__cusparseCcsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseCcsr2gebsr_bufferSizeExt

    global __cusparseZcsr2gebsr_bufferSizeExt
    data["__cusparseZcsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseZcsr2gebsr_bufferSizeExt

    global __cusparseXcsr2gebsrNnz
    data["__cusparseXcsr2gebsrNnz"] = <intptr_t>__cusparseXcsr2gebsrNnz

    global __cusparseScsr2gebsr
    data["__cusparseScsr2gebsr"] = <intptr_t>__cusparseScsr2gebsr

    global __cusparseDcsr2gebsr
    data["__cusparseDcsr2gebsr"] = <intptr_t>__cusparseDcsr2gebsr

    global __cusparseCcsr2gebsr
    data["__cusparseCcsr2gebsr"] = <intptr_t>__cusparseCcsr2gebsr

    global __cusparseZcsr2gebsr
    data["__cusparseZcsr2gebsr"] = <intptr_t>__cusparseZcsr2gebsr

    global __cusparseSgebsr2gebsr_bufferSize
    data["__cusparseSgebsr2gebsr_bufferSize"] = <intptr_t>__cusparseSgebsr2gebsr_bufferSize

    global __cusparseDgebsr2gebsr_bufferSize
    data["__cusparseDgebsr2gebsr_bufferSize"] = <intptr_t>__cusparseDgebsr2gebsr_bufferSize

    global __cusparseCgebsr2gebsr_bufferSize
    data["__cusparseCgebsr2gebsr_bufferSize"] = <intptr_t>__cusparseCgebsr2gebsr_bufferSize

    global __cusparseZgebsr2gebsr_bufferSize
    data["__cusparseZgebsr2gebsr_bufferSize"] = <intptr_t>__cusparseZgebsr2gebsr_bufferSize

    global __cusparseSgebsr2gebsr_bufferSizeExt
    data["__cusparseSgebsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseSgebsr2gebsr_bufferSizeExt

    global __cusparseDgebsr2gebsr_bufferSizeExt
    data["__cusparseDgebsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseDgebsr2gebsr_bufferSizeExt

    global __cusparseCgebsr2gebsr_bufferSizeExt
    data["__cusparseCgebsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseCgebsr2gebsr_bufferSizeExt

    global __cusparseZgebsr2gebsr_bufferSizeExt
    data["__cusparseZgebsr2gebsr_bufferSizeExt"] = <intptr_t>__cusparseZgebsr2gebsr_bufferSizeExt

    global __cusparseXgebsr2gebsrNnz
    data["__cusparseXgebsr2gebsrNnz"] = <intptr_t>__cusparseXgebsr2gebsrNnz

    global __cusparseSgebsr2gebsr
    data["__cusparseSgebsr2gebsr"] = <intptr_t>__cusparseSgebsr2gebsr

    global __cusparseDgebsr2gebsr
    data["__cusparseDgebsr2gebsr"] = <intptr_t>__cusparseDgebsr2gebsr

    global __cusparseCgebsr2gebsr
    data["__cusparseCgebsr2gebsr"] = <intptr_t>__cusparseCgebsr2gebsr

    global __cusparseZgebsr2gebsr
    data["__cusparseZgebsr2gebsr"] = <intptr_t>__cusparseZgebsr2gebsr

    global __cusparseCreateIdentityPermutation
    data["__cusparseCreateIdentityPermutation"] = <intptr_t>__cusparseCreateIdentityPermutation

    global __cusparseXcoosort_bufferSizeExt
    data["__cusparseXcoosort_bufferSizeExt"] = <intptr_t>__cusparseXcoosort_bufferSizeExt

    global __cusparseXcoosortByRow
    data["__cusparseXcoosortByRow"] = <intptr_t>__cusparseXcoosortByRow

    global __cusparseXcoosortByColumn
    data["__cusparseXcoosortByColumn"] = <intptr_t>__cusparseXcoosortByColumn

    global __cusparseXcsrsort_bufferSizeExt
    data["__cusparseXcsrsort_bufferSizeExt"] = <intptr_t>__cusparseXcsrsort_bufferSizeExt

    global __cusparseXcsrsort
    data["__cusparseXcsrsort"] = <intptr_t>__cusparseXcsrsort

    global __cusparseXcscsort_bufferSizeExt
    data["__cusparseXcscsort_bufferSizeExt"] = <intptr_t>__cusparseXcscsort_bufferSizeExt

    global __cusparseXcscsort
    data["__cusparseXcscsort"] = <intptr_t>__cusparseXcscsort

    global __cusparseScsru2csr_bufferSizeExt
    data["__cusparseScsru2csr_bufferSizeExt"] = <intptr_t>__cusparseScsru2csr_bufferSizeExt

    global __cusparseDcsru2csr_bufferSizeExt
    data["__cusparseDcsru2csr_bufferSizeExt"] = <intptr_t>__cusparseDcsru2csr_bufferSizeExt

    global __cusparseCcsru2csr_bufferSizeExt
    data["__cusparseCcsru2csr_bufferSizeExt"] = <intptr_t>__cusparseCcsru2csr_bufferSizeExt

    global __cusparseZcsru2csr_bufferSizeExt
    data["__cusparseZcsru2csr_bufferSizeExt"] = <intptr_t>__cusparseZcsru2csr_bufferSizeExt

    global __cusparseScsru2csr
    data["__cusparseScsru2csr"] = <intptr_t>__cusparseScsru2csr

    global __cusparseDcsru2csr
    data["__cusparseDcsru2csr"] = <intptr_t>__cusparseDcsru2csr

    global __cusparseCcsru2csr
    data["__cusparseCcsru2csr"] = <intptr_t>__cusparseCcsru2csr

    global __cusparseZcsru2csr
    data["__cusparseZcsru2csr"] = <intptr_t>__cusparseZcsru2csr

    global __cusparseScsr2csru
    data["__cusparseScsr2csru"] = <intptr_t>__cusparseScsr2csru

    global __cusparseDcsr2csru
    data["__cusparseDcsr2csru"] = <intptr_t>__cusparseDcsr2csru

    global __cusparseCcsr2csru
    data["__cusparseCcsr2csru"] = <intptr_t>__cusparseCcsr2csru

    global __cusparseZcsr2csru
    data["__cusparseZcsr2csru"] = <intptr_t>__cusparseZcsr2csru

    global __cusparseSpruneDense2csr_bufferSizeExt
    data["__cusparseSpruneDense2csr_bufferSizeExt"] = <intptr_t>__cusparseSpruneDense2csr_bufferSizeExt

    global __cusparseDpruneDense2csr_bufferSizeExt
    data["__cusparseDpruneDense2csr_bufferSizeExt"] = <intptr_t>__cusparseDpruneDense2csr_bufferSizeExt

    global __cusparseSpruneDense2csrNnz
    data["__cusparseSpruneDense2csrNnz"] = <intptr_t>__cusparseSpruneDense2csrNnz

    global __cusparseDpruneDense2csrNnz
    data["__cusparseDpruneDense2csrNnz"] = <intptr_t>__cusparseDpruneDense2csrNnz

    global __cusparseSpruneDense2csr
    data["__cusparseSpruneDense2csr"] = <intptr_t>__cusparseSpruneDense2csr

    global __cusparseDpruneDense2csr
    data["__cusparseDpruneDense2csr"] = <intptr_t>__cusparseDpruneDense2csr

    global __cusparseSpruneCsr2csr_bufferSizeExt
    data["__cusparseSpruneCsr2csr_bufferSizeExt"] = <intptr_t>__cusparseSpruneCsr2csr_bufferSizeExt

    global __cusparseDpruneCsr2csr_bufferSizeExt
    data["__cusparseDpruneCsr2csr_bufferSizeExt"] = <intptr_t>__cusparseDpruneCsr2csr_bufferSizeExt

    global __cusparseSpruneCsr2csrNnz
    data["__cusparseSpruneCsr2csrNnz"] = <intptr_t>__cusparseSpruneCsr2csrNnz

    global __cusparseDpruneCsr2csrNnz
    data["__cusparseDpruneCsr2csrNnz"] = <intptr_t>__cusparseDpruneCsr2csrNnz

    global __cusparseSpruneCsr2csr
    data["__cusparseSpruneCsr2csr"] = <intptr_t>__cusparseSpruneCsr2csr

    global __cusparseDpruneCsr2csr
    data["__cusparseDpruneCsr2csr"] = <intptr_t>__cusparseDpruneCsr2csr

    global __cusparseSpruneDense2csrByPercentage_bufferSizeExt
    data["__cusparseSpruneDense2csrByPercentage_bufferSizeExt"] = <intptr_t>__cusparseSpruneDense2csrByPercentage_bufferSizeExt

    global __cusparseDpruneDense2csrByPercentage_bufferSizeExt
    data["__cusparseDpruneDense2csrByPercentage_bufferSizeExt"] = <intptr_t>__cusparseDpruneDense2csrByPercentage_bufferSizeExt

    global __cusparseSpruneDense2csrNnzByPercentage
    data["__cusparseSpruneDense2csrNnzByPercentage"] = <intptr_t>__cusparseSpruneDense2csrNnzByPercentage

    global __cusparseDpruneDense2csrNnzByPercentage
    data["__cusparseDpruneDense2csrNnzByPercentage"] = <intptr_t>__cusparseDpruneDense2csrNnzByPercentage

    global __cusparseSpruneDense2csrByPercentage
    data["__cusparseSpruneDense2csrByPercentage"] = <intptr_t>__cusparseSpruneDense2csrByPercentage

    global __cusparseDpruneDense2csrByPercentage
    data["__cusparseDpruneDense2csrByPercentage"] = <intptr_t>__cusparseDpruneDense2csrByPercentage

    global __cusparseSpruneCsr2csrByPercentage_bufferSizeExt
    data["__cusparseSpruneCsr2csrByPercentage_bufferSizeExt"] = <intptr_t>__cusparseSpruneCsr2csrByPercentage_bufferSizeExt

    global __cusparseDpruneCsr2csrByPercentage_bufferSizeExt
    data["__cusparseDpruneCsr2csrByPercentage_bufferSizeExt"] = <intptr_t>__cusparseDpruneCsr2csrByPercentage_bufferSizeExt

    global __cusparseSpruneCsr2csrNnzByPercentage
    data["__cusparseSpruneCsr2csrNnzByPercentage"] = <intptr_t>__cusparseSpruneCsr2csrNnzByPercentage

    global __cusparseDpruneCsr2csrNnzByPercentage
    data["__cusparseDpruneCsr2csrNnzByPercentage"] = <intptr_t>__cusparseDpruneCsr2csrNnzByPercentage

    global __cusparseSpruneCsr2csrByPercentage
    data["__cusparseSpruneCsr2csrByPercentage"] = <intptr_t>__cusparseSpruneCsr2csrByPercentage

    global __cusparseDpruneCsr2csrByPercentage
    data["__cusparseDpruneCsr2csrByPercentage"] = <intptr_t>__cusparseDpruneCsr2csrByPercentage

    global __cusparseCsr2cscEx2
    data["__cusparseCsr2cscEx2"] = <intptr_t>__cusparseCsr2cscEx2

    global __cusparseCsr2cscEx2_bufferSize
    data["__cusparseCsr2cscEx2_bufferSize"] = <intptr_t>__cusparseCsr2cscEx2_bufferSize

    global __cusparseCreateSpVec
    data["__cusparseCreateSpVec"] = <intptr_t>__cusparseCreateSpVec

    global __cusparseCreateConstSpVec
    data["__cusparseCreateConstSpVec"] = <intptr_t>__cusparseCreateConstSpVec

    global __cusparseDestroySpVec
    data["__cusparseDestroySpVec"] = <intptr_t>__cusparseDestroySpVec

    global __cusparseSpVecGet
    data["__cusparseSpVecGet"] = <intptr_t>__cusparseSpVecGet

    global __cusparseConstSpVecGet
    data["__cusparseConstSpVecGet"] = <intptr_t>__cusparseConstSpVecGet

    global __cusparseSpVecGetIndexBase
    data["__cusparseSpVecGetIndexBase"] = <intptr_t>__cusparseSpVecGetIndexBase

    global __cusparseSpVecGetValues
    data["__cusparseSpVecGetValues"] = <intptr_t>__cusparseSpVecGetValues

    global __cusparseConstSpVecGetValues
    data["__cusparseConstSpVecGetValues"] = <intptr_t>__cusparseConstSpVecGetValues

    global __cusparseSpVecSetValues
    data["__cusparseSpVecSetValues"] = <intptr_t>__cusparseSpVecSetValues

    global __cusparseCreateDnVec
    data["__cusparseCreateDnVec"] = <intptr_t>__cusparseCreateDnVec

    global __cusparseCreateConstDnVec
    data["__cusparseCreateConstDnVec"] = <intptr_t>__cusparseCreateConstDnVec

    global __cusparseDestroyDnVec
    data["__cusparseDestroyDnVec"] = <intptr_t>__cusparseDestroyDnVec

    global __cusparseDnVecGet
    data["__cusparseDnVecGet"] = <intptr_t>__cusparseDnVecGet

    global __cusparseConstDnVecGet
    data["__cusparseConstDnVecGet"] = <intptr_t>__cusparseConstDnVecGet

    global __cusparseDnVecGetValues
    data["__cusparseDnVecGetValues"] = <intptr_t>__cusparseDnVecGetValues

    global __cusparseConstDnVecGetValues
    data["__cusparseConstDnVecGetValues"] = <intptr_t>__cusparseConstDnVecGetValues

    global __cusparseDnVecSetValues
    data["__cusparseDnVecSetValues"] = <intptr_t>__cusparseDnVecSetValues

    global __cusparseDestroySpMat
    data["__cusparseDestroySpMat"] = <intptr_t>__cusparseDestroySpMat

    global __cusparseSpMatGetFormat
    data["__cusparseSpMatGetFormat"] = <intptr_t>__cusparseSpMatGetFormat

    global __cusparseSpMatGetIndexBase
    data["__cusparseSpMatGetIndexBase"] = <intptr_t>__cusparseSpMatGetIndexBase

    global __cusparseSpMatGetValues
    data["__cusparseSpMatGetValues"] = <intptr_t>__cusparseSpMatGetValues

    global __cusparseConstSpMatGetValues
    data["__cusparseConstSpMatGetValues"] = <intptr_t>__cusparseConstSpMatGetValues

    global __cusparseSpMatSetValues
    data["__cusparseSpMatSetValues"] = <intptr_t>__cusparseSpMatSetValues

    global __cusparseSpMatGetSize
    data["__cusparseSpMatGetSize"] = <intptr_t>__cusparseSpMatGetSize

    global __cusparseSpMatGetStridedBatch
    data["__cusparseSpMatGetStridedBatch"] = <intptr_t>__cusparseSpMatGetStridedBatch

    global __cusparseCooSetStridedBatch
    data["__cusparseCooSetStridedBatch"] = <intptr_t>__cusparseCooSetStridedBatch

    global __cusparseCsrSetStridedBatch
    data["__cusparseCsrSetStridedBatch"] = <intptr_t>__cusparseCsrSetStridedBatch

    global __cusparseSpMatGetAttribute
    data["__cusparseSpMatGetAttribute"] = <intptr_t>__cusparseSpMatGetAttribute

    global __cusparseSpMatSetAttribute
    data["__cusparseSpMatSetAttribute"] = <intptr_t>__cusparseSpMatSetAttribute

    global __cusparseCreateCsr
    data["__cusparseCreateCsr"] = <intptr_t>__cusparseCreateCsr

    global __cusparseCreateConstCsr
    data["__cusparseCreateConstCsr"] = <intptr_t>__cusparseCreateConstCsr

    global __cusparseCreateCsc
    data["__cusparseCreateCsc"] = <intptr_t>__cusparseCreateCsc

    global __cusparseCreateConstCsc
    data["__cusparseCreateConstCsc"] = <intptr_t>__cusparseCreateConstCsc

    global __cusparseCsrGet
    data["__cusparseCsrGet"] = <intptr_t>__cusparseCsrGet

    global __cusparseConstCsrGet
    data["__cusparseConstCsrGet"] = <intptr_t>__cusparseConstCsrGet

    global __cusparseCscGet
    data["__cusparseCscGet"] = <intptr_t>__cusparseCscGet

    global __cusparseConstCscGet
    data["__cusparseConstCscGet"] = <intptr_t>__cusparseConstCscGet

    global __cusparseCsrSetPointers
    data["__cusparseCsrSetPointers"] = <intptr_t>__cusparseCsrSetPointers

    global __cusparseCscSetPointers
    data["__cusparseCscSetPointers"] = <intptr_t>__cusparseCscSetPointers

    global __cusparseCreateCoo
    data["__cusparseCreateCoo"] = <intptr_t>__cusparseCreateCoo

    global __cusparseCreateConstCoo
    data["__cusparseCreateConstCoo"] = <intptr_t>__cusparseCreateConstCoo

    global __cusparseCooGet
    data["__cusparseCooGet"] = <intptr_t>__cusparseCooGet

    global __cusparseConstCooGet
    data["__cusparseConstCooGet"] = <intptr_t>__cusparseConstCooGet

    global __cusparseCooSetPointers
    data["__cusparseCooSetPointers"] = <intptr_t>__cusparseCooSetPointers

    global __cusparseCreateBlockedEll
    data["__cusparseCreateBlockedEll"] = <intptr_t>__cusparseCreateBlockedEll

    global __cusparseCreateConstBlockedEll
    data["__cusparseCreateConstBlockedEll"] = <intptr_t>__cusparseCreateConstBlockedEll

    global __cusparseBlockedEllGet
    data["__cusparseBlockedEllGet"] = <intptr_t>__cusparseBlockedEllGet

    global __cusparseConstBlockedEllGet
    data["__cusparseConstBlockedEllGet"] = <intptr_t>__cusparseConstBlockedEllGet

    global __cusparseCreateDnMat
    data["__cusparseCreateDnMat"] = <intptr_t>__cusparseCreateDnMat

    global __cusparseCreateConstDnMat
    data["__cusparseCreateConstDnMat"] = <intptr_t>__cusparseCreateConstDnMat

    global __cusparseDestroyDnMat
    data["__cusparseDestroyDnMat"] = <intptr_t>__cusparseDestroyDnMat

    global __cusparseDnMatGet
    data["__cusparseDnMatGet"] = <intptr_t>__cusparseDnMatGet

    global __cusparseConstDnMatGet
    data["__cusparseConstDnMatGet"] = <intptr_t>__cusparseConstDnMatGet

    global __cusparseDnMatGetValues
    data["__cusparseDnMatGetValues"] = <intptr_t>__cusparseDnMatGetValues

    global __cusparseConstDnMatGetValues
    data["__cusparseConstDnMatGetValues"] = <intptr_t>__cusparseConstDnMatGetValues

    global __cusparseDnMatSetValues
    data["__cusparseDnMatSetValues"] = <intptr_t>__cusparseDnMatSetValues

    global __cusparseDnMatSetStridedBatch
    data["__cusparseDnMatSetStridedBatch"] = <intptr_t>__cusparseDnMatSetStridedBatch

    global __cusparseDnMatGetStridedBatch
    data["__cusparseDnMatGetStridedBatch"] = <intptr_t>__cusparseDnMatGetStridedBatch

    global __cusparseAxpby
    data["__cusparseAxpby"] = <intptr_t>__cusparseAxpby

    global __cusparseGather
    data["__cusparseGather"] = <intptr_t>__cusparseGather

    global __cusparseScatter
    data["__cusparseScatter"] = <intptr_t>__cusparseScatter

    global __cusparseRot
    data["__cusparseRot"] = <intptr_t>__cusparseRot

    global __cusparseSpVV_bufferSize
    data["__cusparseSpVV_bufferSize"] = <intptr_t>__cusparseSpVV_bufferSize

    global __cusparseSpVV
    data["__cusparseSpVV"] = <intptr_t>__cusparseSpVV

    global __cusparseSparseToDense_bufferSize
    data["__cusparseSparseToDense_bufferSize"] = <intptr_t>__cusparseSparseToDense_bufferSize

    global __cusparseSparseToDense
    data["__cusparseSparseToDense"] = <intptr_t>__cusparseSparseToDense

    global __cusparseDenseToSparse_bufferSize
    data["__cusparseDenseToSparse_bufferSize"] = <intptr_t>__cusparseDenseToSparse_bufferSize

    global __cusparseDenseToSparse_analysis
    data["__cusparseDenseToSparse_analysis"] = <intptr_t>__cusparseDenseToSparse_analysis

    global __cusparseDenseToSparse_convert
    data["__cusparseDenseToSparse_convert"] = <intptr_t>__cusparseDenseToSparse_convert

    global __cusparseSpMV
    data["__cusparseSpMV"] = <intptr_t>__cusparseSpMV

    global __cusparseSpMV_bufferSize
    data["__cusparseSpMV_bufferSize"] = <intptr_t>__cusparseSpMV_bufferSize

    global __cusparseSpSV_createDescr
    data["__cusparseSpSV_createDescr"] = <intptr_t>__cusparseSpSV_createDescr

    global __cusparseSpSV_destroyDescr
    data["__cusparseSpSV_destroyDescr"] = <intptr_t>__cusparseSpSV_destroyDescr

    global __cusparseSpSV_bufferSize
    data["__cusparseSpSV_bufferSize"] = <intptr_t>__cusparseSpSV_bufferSize

    global __cusparseSpSV_analysis
    data["__cusparseSpSV_analysis"] = <intptr_t>__cusparseSpSV_analysis

    global __cusparseSpSV_solve
    data["__cusparseSpSV_solve"] = <intptr_t>__cusparseSpSV_solve

    global __cusparseSpSM_createDescr
    data["__cusparseSpSM_createDescr"] = <intptr_t>__cusparseSpSM_createDescr

    global __cusparseSpSM_destroyDescr
    data["__cusparseSpSM_destroyDescr"] = <intptr_t>__cusparseSpSM_destroyDescr

    global __cusparseSpSM_bufferSize
    data["__cusparseSpSM_bufferSize"] = <intptr_t>__cusparseSpSM_bufferSize

    global __cusparseSpSM_analysis
    data["__cusparseSpSM_analysis"] = <intptr_t>__cusparseSpSM_analysis

    global __cusparseSpSM_solve
    data["__cusparseSpSM_solve"] = <intptr_t>__cusparseSpSM_solve

    global __cusparseSpMM_bufferSize
    data["__cusparseSpMM_bufferSize"] = <intptr_t>__cusparseSpMM_bufferSize

    global __cusparseSpMM_preprocess
    data["__cusparseSpMM_preprocess"] = <intptr_t>__cusparseSpMM_preprocess

    global __cusparseSpMM
    data["__cusparseSpMM"] = <intptr_t>__cusparseSpMM

    global __cusparseSpGEMM_createDescr
    data["__cusparseSpGEMM_createDescr"] = <intptr_t>__cusparseSpGEMM_createDescr

    global __cusparseSpGEMM_destroyDescr
    data["__cusparseSpGEMM_destroyDescr"] = <intptr_t>__cusparseSpGEMM_destroyDescr

    global __cusparseSpGEMM_workEstimation
    data["__cusparseSpGEMM_workEstimation"] = <intptr_t>__cusparseSpGEMM_workEstimation

    global __cusparseSpGEMM_getNumProducts
    data["__cusparseSpGEMM_getNumProducts"] = <intptr_t>__cusparseSpGEMM_getNumProducts

    global __cusparseSpGEMM_estimateMemory
    data["__cusparseSpGEMM_estimateMemory"] = <intptr_t>__cusparseSpGEMM_estimateMemory

    global __cusparseSpGEMM_compute
    data["__cusparseSpGEMM_compute"] = <intptr_t>__cusparseSpGEMM_compute

    global __cusparseSpGEMM_copy
    data["__cusparseSpGEMM_copy"] = <intptr_t>__cusparseSpGEMM_copy

    global __cusparseSpGEMMreuse_workEstimation
    data["__cusparseSpGEMMreuse_workEstimation"] = <intptr_t>__cusparseSpGEMMreuse_workEstimation

    global __cusparseSpGEMMreuse_nnz
    data["__cusparseSpGEMMreuse_nnz"] = <intptr_t>__cusparseSpGEMMreuse_nnz

    global __cusparseSpGEMMreuse_copy
    data["__cusparseSpGEMMreuse_copy"] = <intptr_t>__cusparseSpGEMMreuse_copy

    global __cusparseSpGEMMreuse_compute
    data["__cusparseSpGEMMreuse_compute"] = <intptr_t>__cusparseSpGEMMreuse_compute

    global __cusparseSDDMM_bufferSize
    data["__cusparseSDDMM_bufferSize"] = <intptr_t>__cusparseSDDMM_bufferSize

    global __cusparseSDDMM_preprocess
    data["__cusparseSDDMM_preprocess"] = <intptr_t>__cusparseSDDMM_preprocess

    global __cusparseSDDMM
    data["__cusparseSDDMM"] = <intptr_t>__cusparseSDDMM

    global __cusparseSpMMOp_createPlan
    data["__cusparseSpMMOp_createPlan"] = <intptr_t>__cusparseSpMMOp_createPlan

    global __cusparseSpMMOp
    data["__cusparseSpMMOp"] = <intptr_t>__cusparseSpMMOp

    global __cusparseSpMMOp_destroyPlan
    data["__cusparseSpMMOp_destroyPlan"] = <intptr_t>__cusparseSpMMOp_destroyPlan

    global __cusparseBsrSetStridedBatch
    data["__cusparseBsrSetStridedBatch"] = <intptr_t>__cusparseBsrSetStridedBatch

    global __cusparseCreateBsr
    data["__cusparseCreateBsr"] = <intptr_t>__cusparseCreateBsr

    global __cusparseCreateConstBsr
    data["__cusparseCreateConstBsr"] = <intptr_t>__cusparseCreateConstBsr

    global __cusparseCreateSlicedEll
    data["__cusparseCreateSlicedEll"] = <intptr_t>__cusparseCreateSlicedEll

    global __cusparseCreateConstSlicedEll
    data["__cusparseCreateConstSlicedEll"] = <intptr_t>__cusparseCreateConstSlicedEll

    global __cusparseSpSV_updateMatrix
    data["__cusparseSpSV_updateMatrix"] = <intptr_t>__cusparseSpSV_updateMatrix

    global __cusparseSpMV_preprocess
    data["__cusparseSpMV_preprocess"] = <intptr_t>__cusparseSpMV_preprocess

    global __cusparseSpSM_updateMatrix
    data["__cusparseSpSM_updateMatrix"] = <intptr_t>__cusparseSpSM_updateMatrix

    global __cusparseSpMVOp_createDescr
    data["__cusparseSpMVOp_createDescr"] = <intptr_t>__cusparseSpMVOp_createDescr

    global __cusparseSpMVOp_destroyDescr
    data["__cusparseSpMVOp_destroyDescr"] = <intptr_t>__cusparseSpMVOp_destroyDescr

    global __cusparseSpMVOp_createPlan
    data["__cusparseSpMVOp_createPlan"] = <intptr_t>__cusparseSpMVOp_createPlan

    global __cusparseSpMVOp_destroyPlan
    data["__cusparseSpMVOp_destroyPlan"] = <intptr_t>__cusparseSpMVOp_destroyPlan

    global __cusparseSpMVOp_setGlobalUserData
    data["__cusparseSpMVOp_setGlobalUserData"] = <intptr_t>__cusparseSpMVOp_setGlobalUserData

    global __cusparseSpMVOp
    data["__cusparseSpMVOp"] = <intptr_t>__cusparseSpMVOp

    global __cusparseSpMVOp_bufferSize
    data["__cusparseSpMVOp_bufferSize"] = <intptr_t>__cusparseSpMVOp_bufferSize

    func_ptrs = data
    return data


cpdef _inspect_function_pointer(str name):
    global func_ptrs
    if func_ptrs is None:
        func_ptrs = _inspect_function_pointers()
    return func_ptrs[name]


###############################################################################
# Wrapper functions
###############################################################################

cdef cusparseStatus_t _cusparseCreate(cusparseHandle_t* handle) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreate
    _check_or_init_cusparse()
    if __cusparseCreate == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreate is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t*) noexcept nogil>__cusparseCreate)(
        handle)


cdef cusparseStatus_t _cusparseDestroy(cusparseHandle_t handle) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroy
    _check_or_init_cusparse()
    if __cusparseDestroy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroy is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t) noexcept nogil>__cusparseDestroy)(
        handle)


cdef cusparseStatus_t _cusparseGetVersion(cusparseHandle_t handle, int* version) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetVersion
    _check_or_init_cusparse()
    if __cusparseGetVersion == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetVersion is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int*) noexcept nogil>__cusparseGetVersion)(
        handle, version)


cdef cusparseStatus_t _cusparseGetProperty(libraryPropertyType type, int* value) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetProperty
    _check_or_init_cusparse()
    if __cusparseGetProperty == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetProperty is not found")
    return (<cusparseStatus_t (*)(libraryPropertyType, int*) noexcept nogil>__cusparseGetProperty)(
        type, value)


cdef const char* _cusparseGetErrorName(cusparseStatus_t status) except?NULL nogil:
    global __cusparseGetErrorName
    _check_or_init_cusparse()
    if __cusparseGetErrorName == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetErrorName is not found")
    return (<const char* (*)(cusparseStatus_t) noexcept nogil>__cusparseGetErrorName)(
        status)


cdef const char* _cusparseGetErrorString(cusparseStatus_t status) except?NULL nogil:
    global __cusparseGetErrorString
    _check_or_init_cusparse()
    if __cusparseGetErrorString == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetErrorString is not found")
    return (<const char* (*)(cusparseStatus_t) noexcept nogil>__cusparseGetErrorString)(
        status)


cdef cusparseStatus_t _cusparseSetStream(cusparseHandle_t handle, cudaStream_t streamId) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetStream
    _check_or_init_cusparse()
    if __cusparseSetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetStream is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cudaStream_t) noexcept nogil>__cusparseSetStream)(
        handle, streamId)


cdef cusparseStatus_t _cusparseGetStream(cusparseHandle_t handle, cudaStream_t* streamId) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetStream
    _check_or_init_cusparse()
    if __cusparseGetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetStream is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cudaStream_t*) noexcept nogil>__cusparseGetStream)(
        handle, streamId)


cdef cusparseStatus_t _cusparseGetPointerMode(cusparseHandle_t handle, cusparsePointerMode_t* mode) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetPointerMode
    _check_or_init_cusparse()
    if __cusparseGetPointerMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetPointerMode is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparsePointerMode_t*) noexcept nogil>__cusparseGetPointerMode)(
        handle, mode)


cdef cusparseStatus_t _cusparseSetPointerMode(cusparseHandle_t handle, cusparsePointerMode_t mode) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetPointerMode
    _check_or_init_cusparse()
    if __cusparseSetPointerMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetPointerMode is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparsePointerMode_t) noexcept nogil>__cusparseSetPointerMode)(
        handle, mode)


cdef cusparseStatus_t _cusparseLoggerSetCallback(cusparseLoggerCallback_t callback) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerSetCallback
    _check_or_init_cusparse()
    if __cusparseLoggerSetCallback == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerSetCallback is not found")
    return (<cusparseStatus_t (*)(cusparseLoggerCallback_t) noexcept nogil>__cusparseLoggerSetCallback)(
        callback)


cdef cusparseStatus_t _cusparseLoggerSetFile(FILE* file) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerSetFile
    _check_or_init_cusparse()
    if __cusparseLoggerSetFile == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerSetFile is not found")
    return (<cusparseStatus_t (*)(FILE*) noexcept nogil>__cusparseLoggerSetFile)(
        file)


cdef cusparseStatus_t _cusparseLoggerOpenFile(const char* logFile) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerOpenFile
    _check_or_init_cusparse()
    if __cusparseLoggerOpenFile == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerOpenFile is not found")
    return (<cusparseStatus_t (*)(const char*) noexcept nogil>__cusparseLoggerOpenFile)(
        logFile)


cdef cusparseStatus_t _cusparseLoggerSetLevel(int level) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerSetLevel
    _check_or_init_cusparse()
    if __cusparseLoggerSetLevel == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerSetLevel is not found")
    return (<cusparseStatus_t (*)(int) noexcept nogil>__cusparseLoggerSetLevel)(
        level)


cdef cusparseStatus_t _cusparseLoggerSetMask(int mask) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerSetMask
    _check_or_init_cusparse()
    if __cusparseLoggerSetMask == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerSetMask is not found")
    return (<cusparseStatus_t (*)(int) noexcept nogil>__cusparseLoggerSetMask)(
        mask)


cdef cusparseStatus_t _cusparseLoggerForceDisable() except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseLoggerForceDisable
    _check_or_init_cusparse()
    if __cusparseLoggerForceDisable == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseLoggerForceDisable is not found")
    return (<cusparseStatus_t (*)() noexcept nogil>__cusparseLoggerForceDisable)(
        )


cdef cusparseStatus_t _cusparseCreateMatDescr(cusparseMatDescr_t* descrA) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateMatDescr
    _check_or_init_cusparse()
    if __cusparseCreateMatDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateMatDescr is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t*) noexcept nogil>__cusparseCreateMatDescr)(
        descrA)


cdef cusparseStatus_t _cusparseDestroyMatDescr(cusparseMatDescr_t descrA) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyMatDescr
    _check_or_init_cusparse()
    if __cusparseDestroyMatDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyMatDescr is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t) noexcept nogil>__cusparseDestroyMatDescr)(
        descrA)


cdef cusparseStatus_t _cusparseSetMatType(cusparseMatDescr_t descrA, cusparseMatrixType_t type) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetMatType
    _check_or_init_cusparse()
    if __cusparseSetMatType == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetMatType is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t, cusparseMatrixType_t) noexcept nogil>__cusparseSetMatType)(
        descrA, type)


cdef cusparseMatrixType_t _cusparseGetMatType(const cusparseMatDescr_t descrA) except?_CUSPARSEMATRIXTYPE_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetMatType
    _check_or_init_cusparse()
    if __cusparseGetMatType == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetMatType is not found")
    return (<cusparseMatrixType_t (*)(const cusparseMatDescr_t) noexcept nogil>__cusparseGetMatType)(
        descrA)


cdef cusparseStatus_t _cusparseSetMatFillMode(cusparseMatDescr_t descrA, cusparseFillMode_t fillMode) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetMatFillMode
    _check_or_init_cusparse()
    if __cusparseSetMatFillMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetMatFillMode is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t, cusparseFillMode_t) noexcept nogil>__cusparseSetMatFillMode)(
        descrA, fillMode)


cdef cusparseFillMode_t _cusparseGetMatFillMode(const cusparseMatDescr_t descrA) except?_CUSPARSEFILLMODE_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetMatFillMode
    _check_or_init_cusparse()
    if __cusparseGetMatFillMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetMatFillMode is not found")
    return (<cusparseFillMode_t (*)(const cusparseMatDescr_t) noexcept nogil>__cusparseGetMatFillMode)(
        descrA)


cdef cusparseStatus_t _cusparseSetMatDiagType(cusparseMatDescr_t descrA, cusparseDiagType_t diagType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetMatDiagType
    _check_or_init_cusparse()
    if __cusparseSetMatDiagType == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetMatDiagType is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t, cusparseDiagType_t) noexcept nogil>__cusparseSetMatDiagType)(
        descrA, diagType)


cdef cusparseDiagType_t _cusparseGetMatDiagType(const cusparseMatDescr_t descrA) except?_CUSPARSEDIAGTYPE_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetMatDiagType
    _check_or_init_cusparse()
    if __cusparseGetMatDiagType == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetMatDiagType is not found")
    return (<cusparseDiagType_t (*)(const cusparseMatDescr_t) noexcept nogil>__cusparseGetMatDiagType)(
        descrA)


cdef cusparseStatus_t _cusparseSetMatIndexBase(cusparseMatDescr_t descrA, cusparseIndexBase_t base) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetMatIndexBase
    _check_or_init_cusparse()
    if __cusparseSetMatIndexBase == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetMatIndexBase is not found")
    return (<cusparseStatus_t (*)(cusparseMatDescr_t, cusparseIndexBase_t) noexcept nogil>__cusparseSetMatIndexBase)(
        descrA, base)


cdef cusparseIndexBase_t _cusparseGetMatIndexBase(const cusparseMatDescr_t descrA) except?_CUSPARSEINDEXBASE_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetMatIndexBase
    _check_or_init_cusparse()
    if __cusparseGetMatIndexBase == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetMatIndexBase is not found")
    return (<cusparseIndexBase_t (*)(const cusparseMatDescr_t) noexcept nogil>__cusparseGetMatIndexBase)(
        descrA)


cdef cusparseStatus_t _cusparseCreateCsric02Info(csric02Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCsric02Info
    _check_or_init_cusparse()
    if __cusparseCreateCsric02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCsric02Info is not found")
    return (<cusparseStatus_t (*)(csric02Info_t*) noexcept nogil>__cusparseCreateCsric02Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyCsric02Info(csric02Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyCsric02Info
    _check_or_init_cusparse()
    if __cusparseDestroyCsric02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyCsric02Info is not found")
    return (<cusparseStatus_t (*)(csric02Info_t) noexcept nogil>__cusparseDestroyCsric02Info)(
        info)


cdef cusparseStatus_t _cusparseCreateBsric02Info(bsric02Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBsric02Info
    _check_or_init_cusparse()
    if __cusparseCreateBsric02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBsric02Info is not found")
    return (<cusparseStatus_t (*)(bsric02Info_t*) noexcept nogil>__cusparseCreateBsric02Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyBsric02Info(bsric02Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyBsric02Info
    _check_or_init_cusparse()
    if __cusparseDestroyBsric02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyBsric02Info is not found")
    return (<cusparseStatus_t (*)(bsric02Info_t) noexcept nogil>__cusparseDestroyBsric02Info)(
        info)


cdef cusparseStatus_t _cusparseCreateCsrilu02Info(csrilu02Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCsrilu02Info
    _check_or_init_cusparse()
    if __cusparseCreateCsrilu02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCsrilu02Info is not found")
    return (<cusparseStatus_t (*)(csrilu02Info_t*) noexcept nogil>__cusparseCreateCsrilu02Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyCsrilu02Info(csrilu02Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyCsrilu02Info
    _check_or_init_cusparse()
    if __cusparseDestroyCsrilu02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyCsrilu02Info is not found")
    return (<cusparseStatus_t (*)(csrilu02Info_t) noexcept nogil>__cusparseDestroyCsrilu02Info)(
        info)


cdef cusparseStatus_t _cusparseCreateBsrilu02Info(bsrilu02Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBsrilu02Info
    _check_or_init_cusparse()
    if __cusparseCreateBsrilu02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBsrilu02Info is not found")
    return (<cusparseStatus_t (*)(bsrilu02Info_t*) noexcept nogil>__cusparseCreateBsrilu02Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyBsrilu02Info(bsrilu02Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyBsrilu02Info
    _check_or_init_cusparse()
    if __cusparseDestroyBsrilu02Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyBsrilu02Info is not found")
    return (<cusparseStatus_t (*)(bsrilu02Info_t) noexcept nogil>__cusparseDestroyBsrilu02Info)(
        info)


cdef cusparseStatus_t _cusparseCreateBsrsv2Info(bsrsv2Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBsrsv2Info
    _check_or_init_cusparse()
    if __cusparseCreateBsrsv2Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBsrsv2Info is not found")
    return (<cusparseStatus_t (*)(bsrsv2Info_t*) noexcept nogil>__cusparseCreateBsrsv2Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyBsrsv2Info(bsrsv2Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyBsrsv2Info
    _check_or_init_cusparse()
    if __cusparseDestroyBsrsv2Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyBsrsv2Info is not found")
    return (<cusparseStatus_t (*)(bsrsv2Info_t) noexcept nogil>__cusparseDestroyBsrsv2Info)(
        info)


cdef cusparseStatus_t _cusparseCreateBsrsm2Info(bsrsm2Info_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBsrsm2Info
    _check_or_init_cusparse()
    if __cusparseCreateBsrsm2Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBsrsm2Info is not found")
    return (<cusparseStatus_t (*)(bsrsm2Info_t*) noexcept nogil>__cusparseCreateBsrsm2Info)(
        info)


cdef cusparseStatus_t _cusparseDestroyBsrsm2Info(bsrsm2Info_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyBsrsm2Info
    _check_or_init_cusparse()
    if __cusparseDestroyBsrsm2Info == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyBsrsm2Info is not found")
    return (<cusparseStatus_t (*)(bsrsm2Info_t) noexcept nogil>__cusparseDestroyBsrsm2Info)(
        info)


cdef cusparseStatus_t _cusparseCreateCsru2csrInfo(csru2csrInfo_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCsru2csrInfo
    _check_or_init_cusparse()
    if __cusparseCreateCsru2csrInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCsru2csrInfo is not found")
    return (<cusparseStatus_t (*)(csru2csrInfo_t*) noexcept nogil>__cusparseCreateCsru2csrInfo)(
        info)


cdef cusparseStatus_t _cusparseDestroyCsru2csrInfo(csru2csrInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyCsru2csrInfo
    _check_or_init_cusparse()
    if __cusparseDestroyCsru2csrInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyCsru2csrInfo is not found")
    return (<cusparseStatus_t (*)(csru2csrInfo_t) noexcept nogil>__cusparseDestroyCsru2csrInfo)(
        info)


cdef cusparseStatus_t _cusparseCreateColorInfo(cusparseColorInfo_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateColorInfo
    _check_or_init_cusparse()
    if __cusparseCreateColorInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateColorInfo is not found")
    return (<cusparseStatus_t (*)(cusparseColorInfo_t*) noexcept nogil>__cusparseCreateColorInfo)(
        info)


cdef cusparseStatus_t _cusparseDestroyColorInfo(cusparseColorInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyColorInfo
    _check_or_init_cusparse()
    if __cusparseDestroyColorInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyColorInfo is not found")
    return (<cusparseStatus_t (*)(cusparseColorInfo_t) noexcept nogil>__cusparseDestroyColorInfo)(
        info)


cdef cusparseStatus_t _cusparseSetColorAlgs(cusparseColorInfo_t info, cusparseColorAlg_t alg) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSetColorAlgs
    _check_or_init_cusparse()
    if __cusparseSetColorAlgs == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSetColorAlgs is not found")
    return (<cusparseStatus_t (*)(cusparseColorInfo_t, cusparseColorAlg_t) noexcept nogil>__cusparseSetColorAlgs)(
        info, alg)


cdef cusparseStatus_t _cusparseGetColorAlgs(cusparseColorInfo_t info, cusparseColorAlg_t* alg) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGetColorAlgs
    _check_or_init_cusparse()
    if __cusparseGetColorAlgs == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGetColorAlgs is not found")
    return (<cusparseStatus_t (*)(cusparseColorInfo_t, cusparseColorAlg_t*) noexcept nogil>__cusparseGetColorAlgs)(
        info, alg)


cdef cusparseStatus_t _cusparseCreatePruneInfo(pruneInfo_t* info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreatePruneInfo
    _check_or_init_cusparse()
    if __cusparseCreatePruneInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreatePruneInfo is not found")
    return (<cusparseStatus_t (*)(pruneInfo_t*) noexcept nogil>__cusparseCreatePruneInfo)(
        info)


cdef cusparseStatus_t _cusparseDestroyPruneInfo(pruneInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyPruneInfo
    _check_or_init_cusparse()
    if __cusparseDestroyPruneInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyPruneInfo is not found")
    return (<cusparseStatus_t (*)(pruneInfo_t) noexcept nogil>__cusparseDestroyPruneInfo)(
        info)


cdef cusparseStatus_t _cusparseSgemvi(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, const float* alpha, const float* A, int lda, int nnz, const float* xVal, const int* xInd, const float* beta, float* y, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgemvi
    _check_or_init_cusparse()
    if __cusparseSgemvi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgemvi is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, const float*, const float*, int, int, const float*, const int*, const float*, float*, cusparseIndexBase_t, void*) noexcept nogil>__cusparseSgemvi)(
        handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta, y, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseSgemvi_bufferSize(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, int nnz, int* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgemvi_bufferSize
    _check_or_init_cusparse()
    if __cusparseSgemvi_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgemvi_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, int, int*) noexcept nogil>__cusparseSgemvi_bufferSize)(
        handle, transA, m, n, nnz, pBufferSize)


cdef cusparseStatus_t _cusparseDgemvi(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, const double* alpha, const double* A, int lda, int nnz, const double* xVal, const int* xInd, const double* beta, double* y, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgemvi
    _check_or_init_cusparse()
    if __cusparseDgemvi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgemvi is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, const double*, const double*, int, int, const double*, const int*, const double*, double*, cusparseIndexBase_t, void*) noexcept nogil>__cusparseDgemvi)(
        handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta, y, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseDgemvi_bufferSize(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, int nnz, int* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgemvi_bufferSize
    _check_or_init_cusparse()
    if __cusparseDgemvi_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgemvi_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, int, int*) noexcept nogil>__cusparseDgemvi_bufferSize)(
        handle, transA, m, n, nnz, pBufferSize)


cdef cusparseStatus_t _cusparseCgemvi(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, const cuComplex* alpha, const cuComplex* A, int lda, int nnz, const cuComplex* xVal, const int* xInd, const cuComplex* beta, cuComplex* y, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgemvi
    _check_or_init_cusparse()
    if __cusparseCgemvi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgemvi is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, const cuComplex*, const cuComplex*, int, int, const cuComplex*, const int*, const cuComplex*, cuComplex*, cusparseIndexBase_t, void*) noexcept nogil>__cusparseCgemvi)(
        handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta, y, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseCgemvi_bufferSize(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, int nnz, int* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgemvi_bufferSize
    _check_or_init_cusparse()
    if __cusparseCgemvi_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgemvi_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, int, int*) noexcept nogil>__cusparseCgemvi_bufferSize)(
        handle, transA, m, n, nnz, pBufferSize)


cdef cusparseStatus_t _cusparseZgemvi(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, const cuDoubleComplex* alpha, const cuDoubleComplex* A, int lda, int nnz, const cuDoubleComplex* xVal, const int* xInd, const cuDoubleComplex* beta, cuDoubleComplex* y, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgemvi
    _check_or_init_cusparse()
    if __cusparseZgemvi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgemvi is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, int, int, const cuDoubleComplex*, const int*, const cuDoubleComplex*, cuDoubleComplex*, cusparseIndexBase_t, void*) noexcept nogil>__cusparseZgemvi)(
        handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta, y, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseZgemvi_bufferSize(cusparseHandle_t handle, cusparseOperation_t transA, int m, int n, int nnz, int* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgemvi_bufferSize
    _check_or_init_cusparse()
    if __cusparseZgemvi_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgemvi_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, int, int, int, int*) noexcept nogil>__cusparseZgemvi_bufferSize)(
        handle, transA, m, n, nnz, pBufferSize)


cdef cusparseStatus_t _cusparseSbsrmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nb, int nnzb, const float* alpha, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const float* x, const float* beta, float* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrmv
    _check_or_init_cusparse()
    if __cusparseSbsrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, int, const float*, const float*, float*) noexcept nogil>__cusparseSbsrmv)(
        handle, dirA, transA, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseDbsrmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nb, int nnzb, const double* alpha, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const double* x, const double* beta, double* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrmv
    _check_or_init_cusparse()
    if __cusparseDbsrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, int, const double*, const double*, double*) noexcept nogil>__cusparseDbsrmv)(
        handle, dirA, transA, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseCbsrmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nb, int nnzb, const cuComplex* alpha, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cuComplex* x, const cuComplex* beta, cuComplex* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrmv
    _check_or_init_cusparse()
    if __cusparseCbsrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, const cuComplex*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, const cuComplex*, const cuComplex*, cuComplex*) noexcept nogil>__cusparseCbsrmv)(
        handle, dirA, transA, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseZbsrmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nb, int nnzb, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cuDoubleComplex* x, const cuDoubleComplex* beta, cuDoubleComplex* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrmv
    _check_or_init_cusparse()
    if __cusparseZbsrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, const cuDoubleComplex*, const cuDoubleComplex*, cuDoubleComplex*) noexcept nogil>__cusparseZbsrmv)(
        handle, dirA, transA, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseSbsrxmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int sizeOfMask, int mb, int nb, int nnzb, const float* alpha, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedMaskPtrA, const int* bsrSortedRowPtrA, const int* bsrSortedEndPtrA, const int* bsrSortedColIndA, int blockDim, const float* x, const float* beta, float* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrxmv
    _check_or_init_cusparse()
    if __cusparseSbsrxmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrxmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, const int*, const int*, int, const float*, const float*, float*) noexcept nogil>__cusparseSbsrxmv)(
        handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedMaskPtrA, bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseDbsrxmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int sizeOfMask, int mb, int nb, int nnzb, const double* alpha, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedMaskPtrA, const int* bsrSortedRowPtrA, const int* bsrSortedEndPtrA, const int* bsrSortedColIndA, int blockDim, const double* x, const double* beta, double* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrxmv
    _check_or_init_cusparse()
    if __cusparseDbsrxmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrxmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, const int*, const int*, int, const double*, const double*, double*) noexcept nogil>__cusparseDbsrxmv)(
        handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedMaskPtrA, bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseCbsrxmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int sizeOfMask, int mb, int nb, int nnzb, const cuComplex* alpha, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedMaskPtrA, const int* bsrSortedRowPtrA, const int* bsrSortedEndPtrA, const int* bsrSortedColIndA, int blockDim, const cuComplex* x, const cuComplex* beta, cuComplex* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrxmv
    _check_or_init_cusparse()
    if __cusparseCbsrxmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrxmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, int, const cuComplex*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const int*, const int*, int, const cuComplex*, const cuComplex*, cuComplex*) noexcept nogil>__cusparseCbsrxmv)(
        handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedMaskPtrA, bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseZbsrxmv(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int sizeOfMask, int mb, int nb, int nnzb, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedMaskPtrA, const int* bsrSortedRowPtrA, const int* bsrSortedEndPtrA, const int* bsrSortedColIndA, int blockDim, const cuDoubleComplex* x, const cuDoubleComplex* beta, cuDoubleComplex* y) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrxmv
    _check_or_init_cusparse()
    if __cusparseZbsrxmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrxmv is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const int*, const int*, int, const cuDoubleComplex*, const cuDoubleComplex*, cuDoubleComplex*) noexcept nogil>__cusparseZbsrxmv)(
        handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedMaskPtrA, bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA, blockDim, x, beta, y)


cdef cusparseStatus_t _cusparseXbsrsv2_zeroPivot(cusparseHandle_t handle, bsrsv2Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXbsrsv2_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXbsrsv2_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXbsrsv2_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrsv2Info_t, int*) noexcept nogil>__cusparseXbsrsv2_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseSbsrsv2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsv2_bufferSize
    _check_or_init_cusparse()
    if __cusparseSbsrsv2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsv2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrsv2Info_t, int*) noexcept nogil>__cusparseSbsrsv2_bufferSize)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDbsrsv2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsv2_bufferSize
    _check_or_init_cusparse()
    if __cusparseDbsrsv2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsv2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrsv2Info_t, int*) noexcept nogil>__cusparseDbsrsv2_bufferSize)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCbsrsv2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsv2_bufferSize
    _check_or_init_cusparse()
    if __cusparseCbsrsv2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsv2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrsv2Info_t, int*) noexcept nogil>__cusparseCbsrsv2_bufferSize)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZbsrsv2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsv2_bufferSize
    _check_or_init_cusparse()
    if __cusparseZbsrsv2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsv2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrsv2Info_t, int*) noexcept nogil>__cusparseZbsrsv2_bufferSize)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSbsrsv2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockSize, bsrsv2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSbsrsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrsv2Info_t, size_t*) noexcept nogil>__cusparseSbsrsv2_bufferSizeExt)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseDbsrsv2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockSize, bsrsv2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDbsrsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrsv2Info_t, size_t*) noexcept nogil>__cusparseDbsrsv2_bufferSizeExt)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseCbsrsv2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockSize, bsrsv2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCbsrsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrsv2Info_t, size_t*) noexcept nogil>__cusparseCbsrsv2_bufferSizeExt)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseZbsrsv2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockSize, bsrsv2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZbsrsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrsv2Info_t, size_t*) noexcept nogil>__cusparseZbsrsv2_bufferSizeExt)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseSbsrsv2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsv2_analysis
    _check_or_init_cusparse()
    if __cusparseSbsrsv2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsv2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, bsrsv2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrsv2_analysis)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrsv2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsv2_analysis
    _check_or_init_cusparse()
    if __cusparseDbsrsv2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsv2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, bsrsv2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrsv2_analysis)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrsv2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsv2_analysis
    _check_or_init_cusparse()
    if __cusparseCbsrsv2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsv2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, bsrsv2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrsv2_analysis)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrsv2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsv2_analysis
    _check_or_init_cusparse()
    if __cusparseZbsrsv2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsv2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, bsrsv2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrsv2_analysis)(
        handle, dirA, transA, mb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseSbsrsv2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const float* alpha, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, const float* f, float* x, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsv2_solve
    _check_or_init_cusparse()
    if __cusparseSbsrsv2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsv2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, int, bsrsv2Info_t, const float*, float*, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrsv2_solve)(
        handle, dirA, transA, mb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, f, x, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrsv2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const double* alpha, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, const double* f, double* x, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsv2_solve
    _check_or_init_cusparse()
    if __cusparseDbsrsv2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsv2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, int, bsrsv2Info_t, const double*, double*, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrsv2_solve)(
        handle, dirA, transA, mb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, f, x, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrsv2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cuComplex* alpha, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, const cuComplex* f, cuComplex* x, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsv2_solve
    _check_or_init_cusparse()
    if __cusparseCbsrsv2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsv2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cuComplex*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, bsrsv2Info_t, const cuComplex*, cuComplex*, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrsv2_solve)(
        handle, dirA, transA, mb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, f, x, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrsv2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, int mb, int nnzb, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, bsrsv2Info_t info, const cuDoubleComplex* f, cuDoubleComplex* x, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsv2_solve
    _check_or_init_cusparse()
    if __cusparseZbsrsv2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsv2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, bsrsv2Info_t, const cuDoubleComplex*, cuDoubleComplex*, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrsv2_solve)(
        handle, dirA, transA, mb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, info, f, x, policy, pBuffer)


cdef cusparseStatus_t _cusparseSbsrmm(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int kb, int nnzb, const float* alpha, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, const int blockSize, const float* B, const int ldb, const float* beta, float* C, int ldc) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrmm
    _check_or_init_cusparse()
    if __cusparseSbsrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrmm is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, const int, const float*, const int, const float*, float*, int) noexcept nogil>__cusparseSbsrmm)(
        handle, dirA, transA, transB, mb, n, kb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, B, ldb, beta, C, ldc)


cdef cusparseStatus_t _cusparseDbsrmm(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int kb, int nnzb, const double* alpha, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, const int blockSize, const double* B, const int ldb, const double* beta, double* C, int ldc) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrmm
    _check_or_init_cusparse()
    if __cusparseDbsrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrmm is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, const int, const double*, const int, const double*, double*, int) noexcept nogil>__cusparseDbsrmm)(
        handle, dirA, transA, transB, mb, n, kb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, B, ldb, beta, C, ldc)


cdef cusparseStatus_t _cusparseCbsrmm(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int kb, int nnzb, const cuComplex* alpha, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, const int blockSize, const cuComplex* B, const int ldb, const cuComplex* beta, cuComplex* C, int ldc) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrmm
    _check_or_init_cusparse()
    if __cusparseCbsrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrmm is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, int, const cuComplex*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const int, const cuComplex*, const int, const cuComplex*, cuComplex*, int) noexcept nogil>__cusparseCbsrmm)(
        handle, dirA, transA, transB, mb, n, kb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, B, ldb, beta, C, ldc)


cdef cusparseStatus_t _cusparseZbsrmm(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int kb, int nnzb, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, const int blockSize, const cuDoubleComplex* B, const int ldb, const cuDoubleComplex* beta, cuDoubleComplex* C, int ldc) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrmm
    _check_or_init_cusparse()
    if __cusparseZbsrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrmm is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const int, const cuDoubleComplex*, const int, const cuDoubleComplex*, cuDoubleComplex*, int) noexcept nogil>__cusparseZbsrmm)(
        handle, dirA, transA, transB, mb, n, kb, nnzb, alpha, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockSize, B, ldb, beta, C, ldc)


cdef cusparseStatus_t _cusparseXbsrsm2_zeroPivot(cusparseHandle_t handle, bsrsm2Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXbsrsm2_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXbsrsm2_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXbsrsm2_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrsm2Info_t, int*) noexcept nogil>__cusparseXbsrsm2_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseSbsrsm2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsm2_bufferSize
    _check_or_init_cusparse()
    if __cusparseSbsrsm2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsm2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrsm2Info_t, int*) noexcept nogil>__cusparseSbsrsm2_bufferSize)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDbsrsm2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsm2_bufferSize
    _check_or_init_cusparse()
    if __cusparseDbsrsm2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsm2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrsm2Info_t, int*) noexcept nogil>__cusparseDbsrsm2_bufferSize)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCbsrsm2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsm2_bufferSize
    _check_or_init_cusparse()
    if __cusparseCbsrsm2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsm2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrsm2Info_t, int*) noexcept nogil>__cusparseCbsrsm2_bufferSize)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZbsrsm2_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsm2_bufferSize
    _check_or_init_cusparse()
    if __cusparseZbsrsm2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsm2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrsm2Info_t, int*) noexcept nogil>__cusparseZbsrsm2_bufferSize)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSbsrsm2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsm2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSbsrsm2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsm2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrsm2Info_t, size_t*) noexcept nogil>__cusparseSbsrsm2_bufferSizeExt)(
        handle, dirA, transA, transB, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseDbsrsm2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsm2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDbsrsm2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsm2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrsm2Info_t, size_t*) noexcept nogil>__cusparseDbsrsm2_bufferSizeExt)(
        handle, dirA, transA, transB, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseCbsrsm2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsm2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCbsrsm2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsm2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrsm2Info_t, size_t*) noexcept nogil>__cusparseCbsrsm2_bufferSizeExt)(
        handle, dirA, transA, transB, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseZbsrsm2_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transB, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsm2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZbsrsm2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsm2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrsm2Info_t, size_t*) noexcept nogil>__cusparseZbsrsm2_bufferSizeExt)(
        handle, dirA, transA, transB, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseSbsrsm2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsm2_analysis
    _check_or_init_cusparse()
    if __cusparseSbsrsm2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsm2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, bsrsm2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrsm2_analysis)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrsm2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsm2_analysis
    _check_or_init_cusparse()
    if __cusparseDbsrsm2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsm2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, bsrsm2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrsm2_analysis)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrsm2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsm2_analysis
    _check_or_init_cusparse()
    if __cusparseCbsrsm2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsm2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, bsrsm2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrsm2_analysis)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrsm2_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsm2_analysis
    _check_or_init_cusparse()
    if __cusparseZbsrsm2_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsm2_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, bsrsm2Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrsm2_analysis)(
        handle, dirA, transA, transXY, mb, n, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseSbsrsm2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const float* alpha, const cusparseMatDescr_t descrA, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, const float* B, int ldb, float* X, int ldx, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrsm2_solve
    _check_or_init_cusparse()
    if __cusparseSbsrsm2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrsm2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, int, bsrsm2Info_t, const float*, int, float*, int, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrsm2_solve)(
        handle, dirA, transA, transXY, mb, n, nnzb, alpha, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, B, ldb, X, ldx, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrsm2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const double* alpha, const cusparseMatDescr_t descrA, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, const double* B, int ldb, double* X, int ldx, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrsm2_solve
    _check_or_init_cusparse()
    if __cusparseDbsrsm2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrsm2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, int, bsrsm2Info_t, const double*, int, double*, int, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrsm2_solve)(
        handle, dirA, transA, transXY, mb, n, nnzb, alpha, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, B, ldb, X, ldx, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrsm2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cuComplex* alpha, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, const cuComplex* B, int ldb, cuComplex* X, int ldx, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrsm2_solve
    _check_or_init_cusparse()
    if __cusparseCbsrsm2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrsm2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cuComplex*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, bsrsm2Info_t, const cuComplex*, int, cuComplex*, int, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrsm2_solve)(
        handle, dirA, transA, transXY, mb, n, nnzb, alpha, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, B, ldb, X, ldx, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrsm2_solve(cusparseHandle_t handle, cusparseDirection_t dirA, cusparseOperation_t transA, cusparseOperation_t transXY, int mb, int n, int nnzb, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrsm2Info_t info, const cuDoubleComplex* B, int ldb, cuDoubleComplex* X, int ldx, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrsm2_solve
    _check_or_init_cusparse()
    if __cusparseZbsrsm2_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrsm2_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, cusparseOperation_t, cusparseOperation_t, int, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, bsrsm2Info_t, const cuDoubleComplex*, int, cuDoubleComplex*, int, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrsm2_solve)(
        handle, dirA, transA, transXY, mb, n, nnzb, alpha, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, B, ldb, X, ldx, policy, pBuffer)


cdef cusparseStatus_t _cusparseScsrilu02_numericBoost(cusparseHandle_t handle, csrilu02Info_t info, int enable_boost, double* tol, float* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseScsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csrilu02Info_t, int, double*, float*) noexcept nogil>__cusparseScsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseDcsrilu02_numericBoost(cusparseHandle_t handle, csrilu02Info_t info, int enable_boost, double* tol, double* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseDcsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csrilu02Info_t, int, double*, double*) noexcept nogil>__cusparseDcsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseCcsrilu02_numericBoost(cusparseHandle_t handle, csrilu02Info_t info, int enable_boost, double* tol, cuComplex* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseCcsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csrilu02Info_t, int, double*, cuComplex*) noexcept nogil>__cusparseCcsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseZcsrilu02_numericBoost(cusparseHandle_t handle, csrilu02Info_t info, int enable_boost, double* tol, cuDoubleComplex* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseZcsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csrilu02Info_t, int, double*, cuDoubleComplex*) noexcept nogil>__cusparseZcsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseXcsrilu02_zeroPivot(cusparseHandle_t handle, csrilu02Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsrilu02_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXcsrilu02_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsrilu02_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csrilu02Info_t, int*) noexcept nogil>__cusparseXcsrilu02_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseScsrilu02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseScsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csrilu02Info_t, int*) noexcept nogil>__cusparseScsrilu02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDcsrilu02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseDcsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csrilu02Info_t, int*) noexcept nogil>__cusparseDcsrilu02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCcsrilu02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseCcsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csrilu02Info_t, int*) noexcept nogil>__cusparseCcsrilu02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZcsrilu02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseZcsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csrilu02Info_t, int*) noexcept nogil>__cusparseZcsrilu02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseScsrilu02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseScsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csrilu02Info_t, size_t*) noexcept nogil>__cusparseScsrilu02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseDcsrilu02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDcsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csrilu02Info_t, size_t*) noexcept nogil>__cusparseDcsrilu02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseCcsrilu02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCcsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csrilu02Info_t, size_t*) noexcept nogil>__cusparseCcsrilu02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseZcsrilu02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZcsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csrilu02Info_t, size_t*) noexcept nogil>__cusparseZcsrilu02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseScsrilu02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseScsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseScsrilu02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDcsrilu02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseDcsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDcsrilu02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCcsrilu02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseCcsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCcsrilu02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZcsrilu02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseZcsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZcsrilu02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseScsrilu02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrilu02
    _check_or_init_cusparse()
    if __cusparseScsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseScsrilu02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDcsrilu02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrilu02
    _check_or_init_cusparse()
    if __cusparseDcsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDcsrilu02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCcsrilu02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrilu02
    _check_or_init_cusparse()
    if __cusparseCcsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCcsrilu02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZcsrilu02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrilu02
    _check_or_init_cusparse()
    if __cusparseZcsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZcsrilu02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseSbsrilu02_numericBoost(cusparseHandle_t handle, bsrilu02Info_t info, int enable_boost, double* tol, float* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseSbsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrilu02Info_t, int, double*, float*) noexcept nogil>__cusparseSbsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseDbsrilu02_numericBoost(cusparseHandle_t handle, bsrilu02Info_t info, int enable_boost, double* tol, double* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseDbsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrilu02Info_t, int, double*, double*) noexcept nogil>__cusparseDbsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseCbsrilu02_numericBoost(cusparseHandle_t handle, bsrilu02Info_t info, int enable_boost, double* tol, cuComplex* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseCbsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrilu02Info_t, int, double*, cuComplex*) noexcept nogil>__cusparseCbsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseZbsrilu02_numericBoost(cusparseHandle_t handle, bsrilu02Info_t info, int enable_boost, double* tol, cuDoubleComplex* boost_val) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrilu02_numericBoost
    _check_or_init_cusparse()
    if __cusparseZbsrilu02_numericBoost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrilu02_numericBoost is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrilu02Info_t, int, double*, cuDoubleComplex*) noexcept nogil>__cusparseZbsrilu02_numericBoost)(
        handle, info, enable_boost, tol, boost_val)


cdef cusparseStatus_t _cusparseXbsrilu02_zeroPivot(cusparseHandle_t handle, bsrilu02Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXbsrilu02_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXbsrilu02_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXbsrilu02_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsrilu02Info_t, int*) noexcept nogil>__cusparseXbsrilu02_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseSbsrilu02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseSbsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrilu02Info_t, int*) noexcept nogil>__cusparseSbsrilu02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDbsrilu02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseDbsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrilu02Info_t, int*) noexcept nogil>__cusparseDbsrilu02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCbsrilu02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseCbsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrilu02Info_t, int*) noexcept nogil>__cusparseCbsrilu02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZbsrilu02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrilu02_bufferSize
    _check_or_init_cusparse()
    if __cusparseZbsrilu02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrilu02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrilu02Info_t, int*) noexcept nogil>__cusparseZbsrilu02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSbsrilu02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSbsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrilu02Info_t, size_t*) noexcept nogil>__cusparseSbsrilu02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseDbsrilu02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDbsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrilu02Info_t, size_t*) noexcept nogil>__cusparseDbsrilu02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseCbsrilu02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCbsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrilu02Info_t, size_t*) noexcept nogil>__cusparseCbsrilu02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseZbsrilu02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsrilu02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrilu02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZbsrilu02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrilu02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrilu02Info_t, size_t*) noexcept nogil>__cusparseZbsrilu02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseSbsrilu02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseSbsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrilu02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrilu02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseDbsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrilu02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrilu02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseCbsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrilu02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrilu02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrilu02_analysis
    _check_or_init_cusparse()
    if __cusparseZbsrilu02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrilu02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrilu02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseSbsrilu02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsrilu02
    _check_or_init_cusparse()
    if __cusparseSbsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsrilu02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsrilu02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsrilu02
    _check_or_init_cusparse()
    if __cusparseDbsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsrilu02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsrilu02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsrilu02
    _check_or_init_cusparse()
    if __cusparseCbsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsrilu02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsrilu02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsrilu02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsrilu02
    _check_or_init_cusparse()
    if __cusparseZbsrilu02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsrilu02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsrilu02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsrilu02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseXcsric02_zeroPivot(cusparseHandle_t handle, csric02Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsric02_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXcsric02_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsric02_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, csric02Info_t, int*) noexcept nogil>__cusparseXcsric02_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseScsric02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseScsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csric02Info_t, int*) noexcept nogil>__cusparseScsric02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDcsric02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseDcsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csric02Info_t, int*) noexcept nogil>__cusparseDcsric02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCcsric02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseCcsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csric02Info_t, int*) noexcept nogil>__cusparseCcsric02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZcsric02_bufferSize(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseZcsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csric02Info_t, int*) noexcept nogil>__cusparseZcsric02_bufferSize)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseScsric02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseScsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csric02Info_t, size_t*) noexcept nogil>__cusparseScsric02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseDcsric02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDcsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csric02Info_t, size_t*) noexcept nogil>__cusparseDcsric02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseCcsric02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCcsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csric02Info_t, size_t*) noexcept nogil>__cusparseCcsric02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseZcsric02_bufferSizeExt(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedVal, const int* csrSortedRowPtr, const int* csrSortedColInd, csric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZcsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csric02Info_t, size_t*) noexcept nogil>__cusparseZcsric02_bufferSizeExt)(
        handle, m, nnz, descrA, csrSortedVal, csrSortedRowPtr, csrSortedColInd, info, pBufferSize)


cdef cusparseStatus_t _cusparseScsric02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsric02_analysis
    _check_or_init_cusparse()
    if __cusparseScsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseScsric02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDcsric02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsric02_analysis
    _check_or_init_cusparse()
    if __cusparseDcsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDcsric02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCcsric02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsric02_analysis
    _check_or_init_cusparse()
    if __cusparseCcsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCcsric02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZcsric02_analysis(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsric02_analysis
    _check_or_init_cusparse()
    if __cusparseZcsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZcsric02_analysis)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseScsric02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, float* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsric02
    _check_or_init_cusparse()
    if __cusparseScsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseScsric02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDcsric02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, double* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsric02
    _check_or_init_cusparse()
    if __cusparseDcsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDcsric02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCcsric02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsric02
    _check_or_init_cusparse()
    if __cusparseCcsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCcsric02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZcsric02(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrSortedValA_valM, const int* csrSortedRowPtrA, const int* csrSortedColIndA, csric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsric02
    _check_or_init_cusparse()
    if __cusparseZcsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, csric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZcsric02)(
        handle, m, nnz, descrA, csrSortedValA_valM, csrSortedRowPtrA, csrSortedColIndA, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseXbsric02_zeroPivot(cusparseHandle_t handle, bsric02Info_t info, int* position) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXbsric02_zeroPivot
    _check_or_init_cusparse()
    if __cusparseXbsric02_zeroPivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXbsric02_zeroPivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, bsric02Info_t, int*) noexcept nogil>__cusparseXbsric02_zeroPivot)(
        handle, info, position)


cdef cusparseStatus_t _cusparseSbsric02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseSbsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsric02Info_t, int*) noexcept nogil>__cusparseSbsric02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDbsric02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseDbsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsric02Info_t, int*) noexcept nogil>__cusparseDbsric02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCbsric02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseCbsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsric02Info_t, int*) noexcept nogil>__cusparseCbsric02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZbsric02_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsric02_bufferSize
    _check_or_init_cusparse()
    if __cusparseZbsric02_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsric02_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsric02Info_t, int*) noexcept nogil>__cusparseZbsric02_bufferSize)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSbsric02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSbsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsric02Info_t, size_t*) noexcept nogil>__cusparseSbsric02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseDbsric02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDbsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsric02Info_t, size_t*) noexcept nogil>__cusparseDbsric02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseCbsric02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCbsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsric02Info_t, size_t*) noexcept nogil>__cusparseCbsric02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseZbsric02_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockSize, bsric02Info_t info, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsric02_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZbsric02_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsric02_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsric02Info_t, size_t*) noexcept nogil>__cusparseZbsric02_bufferSizeExt)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockSize, info, pBufferSize)


cdef cusparseStatus_t _cusparseSbsric02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pInputBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsric02_analysis
    _check_or_init_cusparse()
    if __cusparseSbsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsric02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pInputBuffer)


cdef cusparseStatus_t _cusparseDbsric02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pInputBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsric02_analysis
    _check_or_init_cusparse()
    if __cusparseDbsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsric02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pInputBuffer)


cdef cusparseStatus_t _cusparseCbsric02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pInputBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsric02_analysis
    _check_or_init_cusparse()
    if __cusparseCbsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsric02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pInputBuffer)


cdef cusparseStatus_t _cusparseZbsric02_analysis(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pInputBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsric02_analysis
    _check_or_init_cusparse()
    if __cusparseZbsric02_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsric02_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsric02_analysis)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pInputBuffer)


cdef cusparseStatus_t _cusparseSbsric02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsric02
    _check_or_init_cusparse()
    if __cusparseSbsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, float*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseSbsric02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseDbsric02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsric02
    _check_or_init_cusparse()
    if __cusparseDbsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, double*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseDbsric02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseCbsric02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsric02
    _check_or_init_cusparse()
    if __cusparseCbsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuComplex*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseCbsric02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseZbsric02(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nnzb, const cusparseMatDescr_t descrA, cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int blockDim, bsric02Info_t info, cusparseSolvePolicy_t policy, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsric02
    _check_or_init_cusparse()
    if __cusparseZbsric02 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsric02 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, const int*, int, bsric02Info_t, cusparseSolvePolicy_t, void*) noexcept nogil>__cusparseZbsric02)(
        handle, dirA, mb, nnzb, descrA, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy, pBuffer)


cdef cusparseStatus_t _cusparseSgtsv2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const float* dl, const float* d, const float* du, const float* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgtsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, const float*, int, size_t*) noexcept nogil>__cusparseSgtsv2_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgtsv2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const double* dl, const double* d, const double* du, const double* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgtsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, const double*, int, size_t*) noexcept nogil>__cusparseDgtsv2_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgtsv2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuComplex* dl, const cuComplex* d, const cuComplex* du, const cuComplex* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgtsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, int, size_t*) noexcept nogil>__cusparseCgtsv2_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgtsv2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, const cuDoubleComplex* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgtsv2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, int, size_t*) noexcept nogil>__cusparseZgtsv2_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgtsv2(cusparseHandle_t handle, int m, int n, const float* dl, const float* d, const float* du, float* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2
    _check_or_init_cusparse()
    if __cusparseSgtsv2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, float*, int, void*) noexcept nogil>__cusparseSgtsv2)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseDgtsv2(cusparseHandle_t handle, int m, int n, const double* dl, const double* d, const double* du, double* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2
    _check_or_init_cusparse()
    if __cusparseDgtsv2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, double*, int, void*) noexcept nogil>__cusparseDgtsv2)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseCgtsv2(cusparseHandle_t handle, int m, int n, const cuComplex* dl, const cuComplex* d, const cuComplex* du, cuComplex* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2
    _check_or_init_cusparse()
    if __cusparseCgtsv2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, cuComplex*, int, void*) noexcept nogil>__cusparseCgtsv2)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseZgtsv2(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, cuDoubleComplex* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2
    _check_or_init_cusparse()
    if __cusparseZgtsv2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, cuDoubleComplex*, int, void*) noexcept nogil>__cusparseZgtsv2)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseSgtsv2_nopivot_bufferSizeExt(cusparseHandle_t handle, int m, int n, const float* dl, const float* d, const float* du, const float* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2_nopivot_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgtsv2_nopivot_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2_nopivot_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, const float*, int, size_t*) noexcept nogil>__cusparseSgtsv2_nopivot_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgtsv2_nopivot_bufferSizeExt(cusparseHandle_t handle, int m, int n, const double* dl, const double* d, const double* du, const double* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2_nopivot_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgtsv2_nopivot_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2_nopivot_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, const double*, int, size_t*) noexcept nogil>__cusparseDgtsv2_nopivot_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgtsv2_nopivot_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuComplex* dl, const cuComplex* d, const cuComplex* du, const cuComplex* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2_nopivot_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgtsv2_nopivot_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2_nopivot_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, int, size_t*) noexcept nogil>__cusparseCgtsv2_nopivot_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgtsv2_nopivot_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, const cuDoubleComplex* B, int ldb, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2_nopivot_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgtsv2_nopivot_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2_nopivot_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, int, size_t*) noexcept nogil>__cusparseZgtsv2_nopivot_bufferSizeExt)(
        handle, m, n, dl, d, du, B, ldb, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgtsv2_nopivot(cusparseHandle_t handle, int m, int n, const float* dl, const float* d, const float* du, float* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2_nopivot
    _check_or_init_cusparse()
    if __cusparseSgtsv2_nopivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2_nopivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, float*, int, void*) noexcept nogil>__cusparseSgtsv2_nopivot)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseDgtsv2_nopivot(cusparseHandle_t handle, int m, int n, const double* dl, const double* d, const double* du, double* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2_nopivot
    _check_or_init_cusparse()
    if __cusparseDgtsv2_nopivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2_nopivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, double*, int, void*) noexcept nogil>__cusparseDgtsv2_nopivot)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseCgtsv2_nopivot(cusparseHandle_t handle, int m, int n, const cuComplex* dl, const cuComplex* d, const cuComplex* du, cuComplex* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2_nopivot
    _check_or_init_cusparse()
    if __cusparseCgtsv2_nopivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2_nopivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, cuComplex*, int, void*) noexcept nogil>__cusparseCgtsv2_nopivot)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseZgtsv2_nopivot(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, cuDoubleComplex* B, int ldb, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2_nopivot
    _check_or_init_cusparse()
    if __cusparseZgtsv2_nopivot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2_nopivot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, cuDoubleComplex*, int, void*) noexcept nogil>__cusparseZgtsv2_nopivot)(
        handle, m, n, dl, d, du, B, ldb, pBuffer)


cdef cusparseStatus_t _cusparseSgtsv2StridedBatch_bufferSizeExt(cusparseHandle_t handle, int m, const float* dl, const float* d, const float* du, const float* x, int batchCount, int batchStride, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2StridedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgtsv2StridedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2StridedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const float*, const float*, const float*, const float*, int, int, size_t*) noexcept nogil>__cusparseSgtsv2StridedBatch_bufferSizeExt)(
        handle, m, dl, d, du, x, batchCount, batchStride, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgtsv2StridedBatch_bufferSizeExt(cusparseHandle_t handle, int m, const double* dl, const double* d, const double* du, const double* x, int batchCount, int batchStride, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2StridedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgtsv2StridedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2StridedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const double*, const double*, const double*, const double*, int, int, size_t*) noexcept nogil>__cusparseDgtsv2StridedBatch_bufferSizeExt)(
        handle, m, dl, d, du, x, batchCount, batchStride, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgtsv2StridedBatch_bufferSizeExt(cusparseHandle_t handle, int m, const cuComplex* dl, const cuComplex* d, const cuComplex* du, const cuComplex* x, int batchCount, int batchStride, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2StridedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgtsv2StridedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2StridedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, int, int, size_t*) noexcept nogil>__cusparseCgtsv2StridedBatch_bufferSizeExt)(
        handle, m, dl, d, du, x, batchCount, batchStride, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgtsv2StridedBatch_bufferSizeExt(cusparseHandle_t handle, int m, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, const cuDoubleComplex* x, int batchCount, int batchStride, size_t* bufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2StridedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgtsv2StridedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2StridedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, int, int, size_t*) noexcept nogil>__cusparseZgtsv2StridedBatch_bufferSizeExt)(
        handle, m, dl, d, du, x, batchCount, batchStride, bufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgtsv2StridedBatch(cusparseHandle_t handle, int m, const float* dl, const float* d, const float* du, float* x, int batchCount, int batchStride, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsv2StridedBatch
    _check_or_init_cusparse()
    if __cusparseSgtsv2StridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsv2StridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const float*, const float*, const float*, float*, int, int, void*) noexcept nogil>__cusparseSgtsv2StridedBatch)(
        handle, m, dl, d, du, x, batchCount, batchStride, pBuffer)


cdef cusparseStatus_t _cusparseDgtsv2StridedBatch(cusparseHandle_t handle, int m, const double* dl, const double* d, const double* du, double* x, int batchCount, int batchStride, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsv2StridedBatch
    _check_or_init_cusparse()
    if __cusparseDgtsv2StridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsv2StridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const double*, const double*, const double*, double*, int, int, void*) noexcept nogil>__cusparseDgtsv2StridedBatch)(
        handle, m, dl, d, du, x, batchCount, batchStride, pBuffer)


cdef cusparseStatus_t _cusparseCgtsv2StridedBatch(cusparseHandle_t handle, int m, const cuComplex* dl, const cuComplex* d, const cuComplex* du, cuComplex* x, int batchCount, int batchStride, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsv2StridedBatch
    _check_or_init_cusparse()
    if __cusparseCgtsv2StridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsv2StridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cuComplex*, const cuComplex*, const cuComplex*, cuComplex*, int, int, void*) noexcept nogil>__cusparseCgtsv2StridedBatch)(
        handle, m, dl, d, du, x, batchCount, batchStride, pBuffer)


cdef cusparseStatus_t _cusparseZgtsv2StridedBatch(cusparseHandle_t handle, int m, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, cuDoubleComplex* x, int batchCount, int batchStride, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsv2StridedBatch
    _check_or_init_cusparse()
    if __cusparseZgtsv2StridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsv2StridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, cuDoubleComplex*, int, int, void*) noexcept nogil>__cusparseZgtsv2StridedBatch)(
        handle, m, dl, d, du, x, batchCount, batchStride, pBuffer)


cdef cusparseStatus_t _cusparseSgtsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const float* dl, const float* d, const float* du, const float* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgtsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, const float*, int, size_t*) noexcept nogil>__cusparseSgtsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, dl, d, du, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgtsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const double* dl, const double* d, const double* du, const double* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgtsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, const double*, int, size_t*) noexcept nogil>__cusparseDgtsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, dl, d, du, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgtsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const cuComplex* dl, const cuComplex* d, const cuComplex* du, const cuComplex* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgtsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, int, size_t*) noexcept nogil>__cusparseCgtsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, dl, d, du, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgtsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, const cuDoubleComplex* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgtsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, int, size_t*) noexcept nogil>__cusparseZgtsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, dl, d, du, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgtsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, float* dl, float* d, float* du, float* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgtsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseSgtsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgtsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, float*, float*, float*, float*, int, void*) noexcept nogil>__cusparseSgtsvInterleavedBatch)(
        handle, algo, m, dl, d, du, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseDgtsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, double* dl, double* d, double* du, double* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgtsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseDgtsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgtsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, double*, double*, double*, double*, int, void*) noexcept nogil>__cusparseDgtsvInterleavedBatch)(
        handle, algo, m, dl, d, du, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseCgtsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, cuComplex* dl, cuComplex* d, cuComplex* du, cuComplex* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgtsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseCgtsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgtsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, cuComplex*, cuComplex*, cuComplex*, cuComplex*, int, void*) noexcept nogil>__cusparseCgtsvInterleavedBatch)(
        handle, algo, m, dl, d, du, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseZgtsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, cuDoubleComplex* dl, cuDoubleComplex* d, cuDoubleComplex* du, cuDoubleComplex* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgtsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseZgtsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgtsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, int, void*) noexcept nogil>__cusparseZgtsvInterleavedBatch)(
        handle, algo, m, dl, d, du, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseSgpsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const float* ds, const float* dl, const float* d, const float* du, const float* dw, const float* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgpsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgpsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgpsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const float*, const float*, const float*, const float*, const float*, int, size_t*) noexcept nogil>__cusparseSgpsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgpsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const double* ds, const double* dl, const double* d, const double* du, const double* dw, const double* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgpsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgpsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgpsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const double*, const double*, const double*, const double*, const double*, int, size_t*) noexcept nogil>__cusparseDgpsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgpsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const cuComplex* ds, const cuComplex* dl, const cuComplex* d, const cuComplex* du, const cuComplex* dw, const cuComplex* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgpsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgpsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgpsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, const cuComplex*, int, size_t*) noexcept nogil>__cusparseCgpsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgpsvInterleavedBatch_bufferSizeExt(cusparseHandle_t handle, int algo, int m, const cuDoubleComplex* ds, const cuDoubleComplex* dl, const cuDoubleComplex* d, const cuDoubleComplex* du, const cuDoubleComplex* dw, const cuDoubleComplex* x, int batchCount, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgpsvInterleavedBatch_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgpsvInterleavedBatch_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgpsvInterleavedBatch_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, const cuDoubleComplex*, int, size_t*) noexcept nogil>__cusparseZgpsvInterleavedBatch_bufferSizeExt)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgpsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, float* ds, float* dl, float* d, float* du, float* dw, float* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgpsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseSgpsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgpsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, float*, float*, float*, float*, float*, float*, int, void*) noexcept nogil>__cusparseSgpsvInterleavedBatch)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseDgpsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, double* ds, double* dl, double* d, double* du, double* dw, double* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgpsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseDgpsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgpsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, double*, double*, double*, double*, double*, double*, int, void*) noexcept nogil>__cusparseDgpsvInterleavedBatch)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseCgpsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, cuComplex* ds, cuComplex* dl, cuComplex* d, cuComplex* du, cuComplex* dw, cuComplex* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgpsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseCgpsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgpsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, cuComplex*, cuComplex*, cuComplex*, cuComplex*, cuComplex*, cuComplex*, int, void*) noexcept nogil>__cusparseCgpsvInterleavedBatch)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseZgpsvInterleavedBatch(cusparseHandle_t handle, int algo, int m, cuDoubleComplex* ds, cuDoubleComplex* dl, cuDoubleComplex* d, cuDoubleComplex* du, cuDoubleComplex* dw, cuDoubleComplex* x, int batchCount, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgpsvInterleavedBatch
    _check_or_init_cusparse()
    if __cusparseZgpsvInterleavedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgpsvInterleavedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, cuDoubleComplex*, int, void*) noexcept nogil>__cusparseZgpsvInterleavedBatch)(
        handle, algo, m, ds, dl, d, du, dw, x, batchCount, pBuffer)


cdef cusparseStatus_t _cusparseScsrgeam2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const float* alpha, const cusparseMatDescr_t descrA, int nnzA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* beta, const cusparseMatDescr_t descrB, int nnzB, const float* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, const float* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrgeam2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseScsrgeam2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrgeam2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const cusparseMatDescr_t, int, const float*, const int*, const int*, const float*, const cusparseMatDescr_t, int, const float*, const int*, const int*, const cusparseMatDescr_t, const float*, const int*, const int*, size_t*) noexcept nogil>__cusparseScsrgeam2_bufferSizeExt)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDcsrgeam2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const double* alpha, const cusparseMatDescr_t descrA, int nnzA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* beta, const cusparseMatDescr_t descrB, int nnzB, const double* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, const double* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrgeam2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDcsrgeam2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrgeam2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const cusparseMatDescr_t, int, const double*, const int*, const int*, const double*, const cusparseMatDescr_t, int, const double*, const int*, const int*, const cusparseMatDescr_t, const double*, const int*, const int*, size_t*) noexcept nogil>__cusparseDcsrgeam2_bufferSizeExt)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCcsrgeam2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuComplex* alpha, const cusparseMatDescr_t descrA, int nnzA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cuComplex* beta, const cusparseMatDescr_t descrB, int nnzB, const cuComplex* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, const cuComplex* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrgeam2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCcsrgeam2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrgeam2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cusparseMatDescr_t, int, const cuComplex*, const int*, const int*, const cuComplex*, const cusparseMatDescr_t, int, const cuComplex*, const int*, const int*, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, size_t*) noexcept nogil>__cusparseCcsrgeam2_bufferSizeExt)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZcsrgeam2_bufferSizeExt(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, int nnzA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cuDoubleComplex* beta, const cusparseMatDescr_t descrB, int nnzB, const cuDoubleComplex* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, const cuDoubleComplex* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrgeam2_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZcsrgeam2_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrgeam2_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, int, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, const cusparseMatDescr_t, int, const cuDoubleComplex*, const int*, const int*, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, size_t*) noexcept nogil>__cusparseZcsrgeam2_bufferSizeExt)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseXcsrgeam2Nnz(cusparseHandle_t handle, int m, int n, const cusparseMatDescr_t descrA, int nnzA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrB, int nnzB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, void* workspace) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsrgeam2Nnz
    _check_or_init_cusparse()
    if __cusparseXcsrgeam2Nnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsrgeam2Nnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, int, const int*, const int*, const cusparseMatDescr_t, int, const int*, const int*, const cusparseMatDescr_t, int*, int*, void*) noexcept nogil>__cusparseXcsrgeam2Nnz)(
        handle, m, n, descrA, nnzA, csrSortedRowPtrA, csrSortedColIndA, descrB, nnzB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, workspace)


cdef cusparseStatus_t _cusparseScsrgeam2(cusparseHandle_t handle, int m, int n, const float* alpha, const cusparseMatDescr_t descrA, int nnzA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* beta, const cusparseMatDescr_t descrB, int nnzB, const float* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, float* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrgeam2
    _check_or_init_cusparse()
    if __cusparseScsrgeam2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrgeam2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, const cusparseMatDescr_t, int, const float*, const int*, const int*, const float*, const cusparseMatDescr_t, int, const float*, const int*, const int*, const cusparseMatDescr_t, float*, int*, int*, void*) noexcept nogil>__cusparseScsrgeam2)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseDcsrgeam2(cusparseHandle_t handle, int m, int n, const double* alpha, const cusparseMatDescr_t descrA, int nnzA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* beta, const cusparseMatDescr_t descrB, int nnzB, const double* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, double* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrgeam2
    _check_or_init_cusparse()
    if __cusparseDcsrgeam2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrgeam2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, const cusparseMatDescr_t, int, const double*, const int*, const int*, const double*, const cusparseMatDescr_t, int, const double*, const int*, const int*, const cusparseMatDescr_t, double*, int*, int*, void*) noexcept nogil>__cusparseDcsrgeam2)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseCcsrgeam2(cusparseHandle_t handle, int m, int n, const cuComplex* alpha, const cusparseMatDescr_t descrA, int nnzA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cuComplex* beta, const cusparseMatDescr_t descrB, int nnzB, const cuComplex* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, cuComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrgeam2
    _check_or_init_cusparse()
    if __cusparseCcsrgeam2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrgeam2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuComplex*, const cusparseMatDescr_t, int, const cuComplex*, const int*, const int*, const cuComplex*, const cusparseMatDescr_t, int, const cuComplex*, const int*, const int*, const cusparseMatDescr_t, cuComplex*, int*, int*, void*) noexcept nogil>__cusparseCcsrgeam2)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseZcsrgeam2(cusparseHandle_t handle, int m, int n, const cuDoubleComplex* alpha, const cusparseMatDescr_t descrA, int nnzA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cuDoubleComplex* beta, const cusparseMatDescr_t descrB, int nnzB, const cuDoubleComplex* csrSortedValB, const int* csrSortedRowPtrB, const int* csrSortedColIndB, const cusparseMatDescr_t descrC, cuDoubleComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrgeam2
    _check_or_init_cusparse()
    if __cusparseZcsrgeam2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrgeam2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cuDoubleComplex*, const cusparseMatDescr_t, int, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, const cusparseMatDescr_t, int, const cuDoubleComplex*, const int*, const int*, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*, void*) noexcept nogil>__cusparseZcsrgeam2)(
        handle, m, n, alpha, descrA, nnzA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB, csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseScsrcolor(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* fractionToColor, int* ncolors, int* coloring, int* reordering, const cusparseColorInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsrcolor
    _check_or_init_cusparse()
    if __cusparseScsrcolor == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsrcolor is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, int*, int*, int*, const cusparseColorInfo_t) noexcept nogil>__cusparseScsrcolor)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, fractionToColor, ncolors, coloring, reordering, info)


cdef cusparseStatus_t _cusparseDcsrcolor(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* fractionToColor, int* ncolors, int* coloring, int* reordering, const cusparseColorInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsrcolor
    _check_or_init_cusparse()
    if __cusparseDcsrcolor == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsrcolor is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, int*, int*, int*, const cusparseColorInfo_t) noexcept nogil>__cusparseDcsrcolor)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, fractionToColor, ncolors, coloring, reordering, info)


cdef cusparseStatus_t _cusparseCcsrcolor(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* fractionToColor, int* ncolors, int* coloring, int* reordering, const cusparseColorInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsrcolor
    _check_or_init_cusparse()
    if __cusparseCcsrcolor == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsrcolor is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const float*, int*, int*, int*, const cusparseColorInfo_t) noexcept nogil>__cusparseCcsrcolor)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, fractionToColor, ncolors, coloring, reordering, info)


cdef cusparseStatus_t _cusparseZcsrcolor(cusparseHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* fractionToColor, int* ncolors, int* coloring, int* reordering, const cusparseColorInfo_t info) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsrcolor
    _check_or_init_cusparse()
    if __cusparseZcsrcolor == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsrcolor is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const double*, int*, int*, int*, const cusparseColorInfo_t) noexcept nogil>__cusparseZcsrcolor)(
        handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, fractionToColor, ncolors, coloring, reordering, info)


cdef cusparseStatus_t _cusparseSnnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const float* A, int lda, int* nnzPerRowCol, int* nnzTotalDevHostPtr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSnnz
    _check_or_init_cusparse()
    if __cusparseSnnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSnnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, int, int*, int*) noexcept nogil>__cusparseSnnz)(
        handle, dirA, m, n, descrA, A, lda, nnzPerRowCol, nnzTotalDevHostPtr)


cdef cusparseStatus_t _cusparseDnnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const double* A, int lda, int* nnzPerRowCol, int* nnzTotalDevHostPtr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnnz
    _check_or_init_cusparse()
    if __cusparseDnnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, int, int*, int*) noexcept nogil>__cusparseDnnz)(
        handle, dirA, m, n, descrA, A, lda, nnzPerRowCol, nnzTotalDevHostPtr)


cdef cusparseStatus_t _cusparseCnnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* A, int lda, int* nnzPerRowCol, int* nnzTotalDevHostPtr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCnnz
    _check_or_init_cusparse()
    if __cusparseCnnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCnnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, int, int*, int*) noexcept nogil>__cusparseCnnz)(
        handle, dirA, m, n, descrA, A, lda, nnzPerRowCol, nnzTotalDevHostPtr)


cdef cusparseStatus_t _cusparseZnnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* A, int lda, int* nnzPerRowCol, int* nnzTotalDevHostPtr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZnnz
    _check_or_init_cusparse()
    if __cusparseZnnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZnnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, int, int*, int*) noexcept nogil>__cusparseZnnz)(
        handle, dirA, m, n, descrA, A, lda, nnzPerRowCol, nnzTotalDevHostPtr)


cdef cusparseStatus_t _cusparseSnnz_compress(cusparseHandle_t handle, int m, const cusparseMatDescr_t descr, const float* csrSortedValA, const int* csrSortedRowPtrA, int* nnzPerRow, int* nnzC, float tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSnnz_compress
    _check_or_init_cusparse()
    if __cusparseSnnz_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSnnz_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cusparseMatDescr_t, const float*, const int*, int*, int*, float) noexcept nogil>__cusparseSnnz_compress)(
        handle, m, descr, csrSortedValA, csrSortedRowPtrA, nnzPerRow, nnzC, tol)


cdef cusparseStatus_t _cusparseDnnz_compress(cusparseHandle_t handle, int m, const cusparseMatDescr_t descr, const double* csrSortedValA, const int* csrSortedRowPtrA, int* nnzPerRow, int* nnzC, double tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnnz_compress
    _check_or_init_cusparse()
    if __cusparseDnnz_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnnz_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cusparseMatDescr_t, const double*, const int*, int*, int*, double) noexcept nogil>__cusparseDnnz_compress)(
        handle, m, descr, csrSortedValA, csrSortedRowPtrA, nnzPerRow, nnzC, tol)


cdef cusparseStatus_t _cusparseCnnz_compress(cusparseHandle_t handle, int m, const cusparseMatDescr_t descr, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, int* nnzPerRow, int* nnzC, cuComplex tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCnnz_compress
    _check_or_init_cusparse()
    if __cusparseCnnz_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCnnz_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cusparseMatDescr_t, const cuComplex*, const int*, int*, int*, cuComplex) noexcept nogil>__cusparseCnnz_compress)(
        handle, m, descr, csrSortedValA, csrSortedRowPtrA, nnzPerRow, nnzC, tol)


cdef cusparseStatus_t _cusparseZnnz_compress(cusparseHandle_t handle, int m, const cusparseMatDescr_t descr, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, int* nnzPerRow, int* nnzC, cuDoubleComplex tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZnnz_compress
    _check_or_init_cusparse()
    if __cusparseZnnz_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZnnz_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, int*, int*, cuDoubleComplex) noexcept nogil>__cusparseZnnz_compress)(
        handle, m, descr, csrSortedValA, csrSortedRowPtrA, nnzPerRow, nnzC, tol)


cdef cusparseStatus_t _cusparseScsr2csr_compress(cusparseHandle_t handle, int m, int n, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedColIndA, const int* csrSortedRowPtrA, int nnzA, const int* nnzPerRow, float* csrSortedValC, int* csrSortedColIndC, int* csrSortedRowPtrC, float tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2csr_compress
    _check_or_init_cusparse()
    if __cusparseScsr2csr_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2csr_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, const int*, float*, int*, int*, float) noexcept nogil>__cusparseScsr2csr_compress)(
        handle, m, n, descrA, csrSortedValA, csrSortedColIndA, csrSortedRowPtrA, nnzA, nnzPerRow, csrSortedValC, csrSortedColIndC, csrSortedRowPtrC, tol)


cdef cusparseStatus_t _cusparseDcsr2csr_compress(cusparseHandle_t handle, int m, int n, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedColIndA, const int* csrSortedRowPtrA, int nnzA, const int* nnzPerRow, double* csrSortedValC, int* csrSortedColIndC, int* csrSortedRowPtrC, double tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2csr_compress
    _check_or_init_cusparse()
    if __cusparseDcsr2csr_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2csr_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, const int*, double*, int*, int*, double) noexcept nogil>__cusparseDcsr2csr_compress)(
        handle, m, n, descrA, csrSortedValA, csrSortedColIndA, csrSortedRowPtrA, nnzA, nnzPerRow, csrSortedValC, csrSortedColIndC, csrSortedRowPtrC, tol)


cdef cusparseStatus_t _cusparseCcsr2csr_compress(cusparseHandle_t handle, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedColIndA, const int* csrSortedRowPtrA, int nnzA, const int* nnzPerRow, cuComplex* csrSortedValC, int* csrSortedColIndC, int* csrSortedRowPtrC, cuComplex tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2csr_compress
    _check_or_init_cusparse()
    if __cusparseCcsr2csr_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2csr_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, const int*, cuComplex*, int*, int*, cuComplex) noexcept nogil>__cusparseCcsr2csr_compress)(
        handle, m, n, descrA, csrSortedValA, csrSortedColIndA, csrSortedRowPtrA, nnzA, nnzPerRow, csrSortedValC, csrSortedColIndC, csrSortedRowPtrC, tol)


cdef cusparseStatus_t _cusparseZcsr2csr_compress(cusparseHandle_t handle, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedColIndA, const int* csrSortedRowPtrA, int nnzA, const int* nnzPerRow, cuDoubleComplex* csrSortedValC, int* csrSortedColIndC, int* csrSortedRowPtrC, cuDoubleComplex tol) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2csr_compress
    _check_or_init_cusparse()
    if __cusparseZcsr2csr_compress == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2csr_compress is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, const int*, cuDoubleComplex*, int*, int*, cuDoubleComplex) noexcept nogil>__cusparseZcsr2csr_compress)(
        handle, m, n, descrA, csrSortedValA, csrSortedColIndA, csrSortedRowPtrA, nnzA, nnzPerRow, csrSortedValC, csrSortedColIndC, csrSortedRowPtrC, tol)


cdef cusparseStatus_t _cusparseXcoo2csr(cusparseHandle_t handle, const int* cooRowInd, int nnz, int m, int* csrSortedRowPtr, cusparseIndexBase_t idxBase) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcoo2csr
    _check_or_init_cusparse()
    if __cusparseXcoo2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcoo2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, const int*, int, int, int*, cusparseIndexBase_t) noexcept nogil>__cusparseXcoo2csr)(
        handle, cooRowInd, nnz, m, csrSortedRowPtr, idxBase)


cdef cusparseStatus_t _cusparseXcsr2coo(cusparseHandle_t handle, const int* csrSortedRowPtr, int nnz, int m, int* cooRowInd, cusparseIndexBase_t idxBase) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsr2coo
    _check_or_init_cusparse()
    if __cusparseXcsr2coo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsr2coo is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, const int*, int, int, int*, cusparseIndexBase_t) noexcept nogil>__cusparseXcsr2coo)(
        handle, csrSortedRowPtr, nnz, m, cooRowInd, idxBase)


cdef cusparseStatus_t _cusparseXcsr2bsrNnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, int* bsrSortedRowPtrC, int* nnzTotalDevHostPtr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsr2bsrNnz
    _check_or_init_cusparse()
    if __cusparseXcsr2bsrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsr2bsrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const int*, const int*, int, const cusparseMatDescr_t, int*, int*) noexcept nogil>__cusparseXcsr2bsrNnz)(
        handle, dirA, m, n, descrA, csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC, bsrSortedRowPtrC, nnzTotalDevHostPtr)


cdef cusparseStatus_t _cusparseScsr2bsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, float* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2bsr
    _check_or_init_cusparse()
    if __cusparseScsr2bsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2bsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, const cusparseMatDescr_t, float*, int*, int*) noexcept nogil>__cusparseScsr2bsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)


cdef cusparseStatus_t _cusparseDcsr2bsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, double* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2bsr
    _check_or_init_cusparse()
    if __cusparseDcsr2bsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2bsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, const cusparseMatDescr_t, double*, int*, int*) noexcept nogil>__cusparseDcsr2bsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)


cdef cusparseStatus_t _cusparseCcsr2bsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, cuComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2bsr
    _check_or_init_cusparse()
    if __cusparseCcsr2bsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2bsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, const cusparseMatDescr_t, cuComplex*, int*, int*) noexcept nogil>__cusparseCcsr2bsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)


cdef cusparseStatus_t _cusparseZcsr2bsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, cuDoubleComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2bsr
    _check_or_init_cusparse()
    if __cusparseZcsr2bsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2bsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*) noexcept nogil>__cusparseZcsr2bsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)


cdef cusparseStatus_t _cusparseSbsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, float* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSbsr2csr
    _check_or_init_cusparse()
    if __cusparseSbsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSbsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, const cusparseMatDescr_t, float*, int*, int*) noexcept nogil>__cusparseSbsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseDbsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, double* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDbsr2csr
    _check_or_init_cusparse()
    if __cusparseDbsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDbsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, const cusparseMatDescr_t, double*, int*, int*) noexcept nogil>__cusparseDbsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseCbsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, cuComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCbsr2csr
    _check_or_init_cusparse()
    if __cusparseCbsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCbsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, const cusparseMatDescr_t, cuComplex*, int*, int*) noexcept nogil>__cusparseCbsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseZbsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int blockDim, const cusparseMatDescr_t descrC, cuDoubleComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZbsr2csr
    _check_or_init_cusparse()
    if __cusparseZbsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZbsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*) noexcept nogil>__cusparseZbsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseSgebsr2gebsc_bufferSize(cusparseHandle_t handle, int mb, int nb, int nnzb, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsc_bufferSize
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsc_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsc_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const float*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseSgebsr2gebsc_bufferSize)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgebsr2gebsc_bufferSize(cusparseHandle_t handle, int mb, int nb, int nnzb, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsc_bufferSize
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsc_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsc_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const double*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseDgebsr2gebsc_bufferSize)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgebsr2gebsc_bufferSize(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsc_bufferSize
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsc_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsc_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuComplex*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseCgebsr2gebsc_bufferSize)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgebsr2gebsc_bufferSize(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsc_bufferSize
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsc_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsc_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuDoubleComplex*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseZgebsr2gebsc_bufferSize)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgebsr2gebsc_bufferSizeExt(cusparseHandle_t handle, int mb, int nb, int nnzb, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsc_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsc_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsc_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const float*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseSgebsr2gebsc_bufferSizeExt)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseDgebsr2gebsc_bufferSizeExt(cusparseHandle_t handle, int mb, int nb, int nnzb, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsc_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsc_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsc_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const double*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseDgebsr2gebsc_bufferSizeExt)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseCgebsr2gebsc_bufferSizeExt(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsc_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsc_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsc_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuComplex*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseCgebsr2gebsc_bufferSizeExt)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseZgebsr2gebsc_bufferSizeExt(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsc_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsc_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsc_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuDoubleComplex*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseZgebsr2gebsc_bufferSizeExt)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseSgebsr2gebsc(cusparseHandle_t handle, int mb, int nb, int nnzb, const float* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, float* bscVal, int* bscRowInd, int* bscColPtr, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsc
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsc is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const float*, const int*, const int*, int, int, float*, int*, int*, cusparseAction_t, cusparseIndexBase_t, void*) noexcept nogil>__cusparseSgebsr2gebsc)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, bscVal, bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseDgebsr2gebsc(cusparseHandle_t handle, int mb, int nb, int nnzb, const double* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, double* bscVal, int* bscRowInd, int* bscColPtr, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsc
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsc is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const double*, const int*, const int*, int, int, double*, int*, int*, cusparseAction_t, cusparseIndexBase_t, void*) noexcept nogil>__cusparseDgebsr2gebsc)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, bscVal, bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseCgebsr2gebsc(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, cuComplex* bscVal, int* bscRowInd, int* bscColPtr, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsc
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsc is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuComplex*, const int*, const int*, int, int, cuComplex*, int*, int*, cusparseAction_t, cusparseIndexBase_t, void*) noexcept nogil>__cusparseCgebsr2gebsc)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, bscVal, bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseZgebsr2gebsc(cusparseHandle_t handle, int mb, int nb, int nnzb, const cuDoubleComplex* bsrSortedVal, const int* bsrSortedRowPtr, const int* bsrSortedColInd, int rowBlockDim, int colBlockDim, cuDoubleComplex* bscVal, int* bscRowInd, int* bscColPtr, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsc
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsc is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cuDoubleComplex*, const int*, const int*, int, int, cuDoubleComplex*, int*, int*, cusparseAction_t, cusparseIndexBase_t, void*) noexcept nogil>__cusparseZgebsr2gebsc)(
        handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr, bsrSortedColInd, rowBlockDim, colBlockDim, bscVal, bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)


cdef cusparseStatus_t _cusparseXgebsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDim, int colBlockDim, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXgebsr2csr
    _check_or_init_cusparse()
    if __cusparseXgebsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXgebsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const int*, const int*, int, int, const cusparseMatDescr_t, int*, int*) noexcept nogil>__cusparseXgebsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim, colBlockDim, descrC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseSgebsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDim, int colBlockDim, const cusparseMatDescr_t descrC, float* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2csr
    _check_or_init_cusparse()
    if __cusparseSgebsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, const cusparseMatDescr_t, float*, int*, int*) noexcept nogil>__cusparseSgebsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim, colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseDgebsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDim, int colBlockDim, const cusparseMatDescr_t descrC, double* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2csr
    _check_or_init_cusparse()
    if __cusparseDgebsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, const cusparseMatDescr_t, double*, int*, int*) noexcept nogil>__cusparseDgebsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim, colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseCgebsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDim, int colBlockDim, const cusparseMatDescr_t descrC, cuComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2csr
    _check_or_init_cusparse()
    if __cusparseCgebsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, const cusparseMatDescr_t, cuComplex*, int*, int*) noexcept nogil>__cusparseCgebsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim, colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseZgebsr2csr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDim, int colBlockDim, const cusparseMatDescr_t descrC, cuDoubleComplex* csrSortedValC, int* csrSortedRowPtrC, int* csrSortedColIndC) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2csr
    _check_or_init_cusparse()
    if __cusparseZgebsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*) noexcept nogil>__cusparseZgebsr2csr)(
        handle, dirA, mb, nb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim, colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)


cdef cusparseStatus_t _cusparseScsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseScsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseScsr2gebsr_bufferSize)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDcsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseDcsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseDcsr2gebsr_bufferSize)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCcsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseCcsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseCcsr2gebsr_bufferSize)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZcsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseZcsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, int*) noexcept nogil>__cusparseZcsr2gebsr_bufferSize)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseScsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseScsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseScsr2gebsr_bufferSizeExt)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseDcsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDcsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseDcsr2gebsr_bufferSizeExt)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseCcsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCcsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseCcsr2gebsr_bufferSizeExt)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseZcsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, int rowBlockDim, int colBlockDim, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZcsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, size_t*) noexcept nogil>__cusparseZcsr2gebsr_bufferSizeExt)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, rowBlockDim, colBlockDim, pBufferSize)


cdef cusparseStatus_t _cusparseXcsr2gebsrNnz(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrC, int* bsrSortedRowPtrC, int rowBlockDim, int colBlockDim, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsr2gebsrNnz
    _check_or_init_cusparse()
    if __cusparseXcsr2gebsrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsr2gebsrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const int*, const int*, const cusparseMatDescr_t, int*, int, int, int*, void*) noexcept nogil>__cusparseXcsr2gebsrNnz)(
        handle, dirA, m, n, descrA, csrSortedRowPtrA, csrSortedColIndA, descrC, bsrSortedRowPtrC, rowBlockDim, colBlockDim, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseScsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrC, float* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDim, int colBlockDim, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2gebsr
    _check_or_init_cusparse()
    if __cusparseScsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const cusparseMatDescr_t, float*, int*, int*, int, int, void*) noexcept nogil>__cusparseScsr2gebsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDim, colBlockDim, pBuffer)


cdef cusparseStatus_t _cusparseDcsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrC, double* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDim, int colBlockDim, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2gebsr
    _check_or_init_cusparse()
    if __cusparseDcsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const cusparseMatDescr_t, double*, int*, int*, int, int, void*) noexcept nogil>__cusparseDcsr2gebsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDim, colBlockDim, pBuffer)


cdef cusparseStatus_t _cusparseCcsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrC, cuComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDim, int colBlockDim, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2gebsr
    _check_or_init_cusparse()
    if __cusparseCcsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cusparseMatDescr_t, cuComplex*, int*, int*, int, int, void*) noexcept nogil>__cusparseCcsr2gebsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDim, colBlockDim, pBuffer)


cdef cusparseStatus_t _cusparseZcsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int m, int n, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const cusparseMatDescr_t descrC, cuDoubleComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDim, int colBlockDim, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2gebsr
    _check_or_init_cusparse()
    if __cusparseZcsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*, int, int, void*) noexcept nogil>__cusparseZcsr2gebsr)(
        handle, dirA, m, n, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDim, colBlockDim, pBuffer)


cdef cusparseStatus_t _cusparseSgebsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, int, int, int*) noexcept nogil>__cusparseSgebsr2gebsr_bufferSize)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDgebsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, int, int, int*) noexcept nogil>__cusparseDgebsr2gebsr_bufferSize)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCgebsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, int, int, int*) noexcept nogil>__cusparseCgebsr2gebsr_bufferSize)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZgebsr2gebsr_bufferSize(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, int* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsr_bufferSize
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsr_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, int, int, int*) noexcept nogil>__cusparseZgebsr2gebsr_bufferSize)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSgebsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, int, int, size_t*) noexcept nogil>__cusparseSgebsr2gebsr_bufferSizeExt)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSize)


cdef cusparseStatus_t _cusparseDgebsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, int, int, size_t*) noexcept nogil>__cusparseDgebsr2gebsr_bufferSizeExt)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSize)


cdef cusparseStatus_t _cusparseCgebsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, int, int, size_t*) noexcept nogil>__cusparseCgebsr2gebsr_bufferSizeExt)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSize)


cdef cusparseStatus_t _cusparseZgebsr2gebsr_bufferSizeExt(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, int rowBlockDimC, int colBlockDimC, size_t* pBufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, int, int, size_t*) noexcept nogil>__cusparseZgebsr2gebsr_bufferSizeExt)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, rowBlockDimC, colBlockDimC, pBufferSize)


cdef cusparseStatus_t _cusparseXgebsr2gebsrNnz(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, const cusparseMatDescr_t descrC, int* bsrSortedRowPtrC, int rowBlockDimC, int colBlockDimC, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXgebsr2gebsrNnz
    _check_or_init_cusparse()
    if __cusparseXgebsr2gebsrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXgebsr2gebsrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const int*, const int*, int, int, const cusparseMatDescr_t, int*, int, int, int*, void*) noexcept nogil>__cusparseXgebsr2gebsrNnz)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, descrC, bsrSortedRowPtrC, rowBlockDimC, colBlockDimC, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseSgebsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const float* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, const cusparseMatDescr_t descrC, float* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDimC, int colBlockDimC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSgebsr2gebsr
    _check_or_init_cusparse()
    if __cusparseSgebsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSgebsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, int, const cusparseMatDescr_t, float*, int*, int*, int, int, void*) noexcept nogil>__cusparseSgebsr2gebsr)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC, colBlockDimC, pBuffer)


cdef cusparseStatus_t _cusparseDgebsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const double* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, const cusparseMatDescr_t descrC, double* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDimC, int colBlockDimC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDgebsr2gebsr
    _check_or_init_cusparse()
    if __cusparseDgebsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDgebsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, int, const cusparseMatDescr_t, double*, int*, int*, int, int, void*) noexcept nogil>__cusparseDgebsr2gebsr)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC, colBlockDimC, pBuffer)


cdef cusparseStatus_t _cusparseCgebsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, const cusparseMatDescr_t descrC, cuComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDimC, int colBlockDimC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCgebsr2gebsr
    _check_or_init_cusparse()
    if __cusparseCgebsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCgebsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, int, const cusparseMatDescr_t, cuComplex*, int*, int*, int, int, void*) noexcept nogil>__cusparseCgebsr2gebsr)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC, colBlockDimC, pBuffer)


cdef cusparseStatus_t _cusparseZgebsr2gebsr(cusparseHandle_t handle, cusparseDirection_t dirA, int mb, int nb, int nnzb, const cusparseMatDescr_t descrA, const cuDoubleComplex* bsrSortedValA, const int* bsrSortedRowPtrA, const int* bsrSortedColIndA, int rowBlockDimA, int colBlockDimA, const cusparseMatDescr_t descrC, cuDoubleComplex* bsrSortedValC, int* bsrSortedRowPtrC, int* bsrSortedColIndC, int rowBlockDimC, int colBlockDimC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZgebsr2gebsr
    _check_or_init_cusparse()
    if __cusparseZgebsr2gebsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZgebsr2gebsr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseDirection_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, int, const cusparseMatDescr_t, cuDoubleComplex*, int*, int*, int, int, void*) noexcept nogil>__cusparseZgebsr2gebsr)(
        handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA, colBlockDimA, descrC, bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC, colBlockDimC, pBuffer)


cdef cusparseStatus_t _cusparseCreateIdentityPermutation(cusparseHandle_t handle, int n, int* p) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateIdentityPermutation
    _check_or_init_cusparse()
    if __cusparseCreateIdentityPermutation == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateIdentityPermutation is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int*) noexcept nogil>__cusparseCreateIdentityPermutation)(
        handle, n, p)


cdef cusparseStatus_t _cusparseXcoosort_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, const int* cooRowsA, const int* cooColsA, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcoosort_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseXcoosort_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcoosort_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const int*, const int*, size_t*) noexcept nogil>__cusparseXcoosort_bufferSizeExt)(
        handle, m, n, nnz, cooRowsA, cooColsA, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseXcoosortByRow(cusparseHandle_t handle, int m, int n, int nnz, int* cooRowsA, int* cooColsA, int* P, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcoosortByRow
    _check_or_init_cusparse()
    if __cusparseXcoosortByRow == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcoosortByRow is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, int*, int*, int*, void*) noexcept nogil>__cusparseXcoosortByRow)(
        handle, m, n, nnz, cooRowsA, cooColsA, P, pBuffer)


cdef cusparseStatus_t _cusparseXcoosortByColumn(cusparseHandle_t handle, int m, int n, int nnz, int* cooRowsA, int* cooColsA, int* P, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcoosortByColumn
    _check_or_init_cusparse()
    if __cusparseXcoosortByColumn == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcoosortByColumn is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, int*, int*, int*, void*) noexcept nogil>__cusparseXcoosortByColumn)(
        handle, m, n, nnz, cooRowsA, cooColsA, P, pBuffer)


cdef cusparseStatus_t _cusparseXcsrsort_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, const int* csrRowPtrA, const int* csrColIndA, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsrsort_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseXcsrsort_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsrsort_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const int*, const int*, size_t*) noexcept nogil>__cusparseXcsrsort_bufferSizeExt)(
        handle, m, n, nnz, csrRowPtrA, csrColIndA, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseXcsrsort(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const int* csrRowPtrA, int* csrColIndA, int* P, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcsrsort
    _check_or_init_cusparse()
    if __cusparseXcsrsort == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcsrsort is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const int*, int*, int*, void*) noexcept nogil>__cusparseXcsrsort)(
        handle, m, n, nnz, descrA, csrRowPtrA, csrColIndA, P, pBuffer)


cdef cusparseStatus_t _cusparseXcscsort_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, const int* cscColPtrA, const int* cscRowIndA, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcscsort_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseXcscsort_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcscsort_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const int*, const int*, size_t*) noexcept nogil>__cusparseXcscsort_bufferSizeExt)(
        handle, m, n, nnz, cscColPtrA, cscRowIndA, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseXcscsort(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const int* cscColPtrA, int* cscRowIndA, int* P, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseXcscsort
    _check_or_init_cusparse()
    if __cusparseXcscsort == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseXcscsort is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const int*, int*, int*, void*) noexcept nogil>__cusparseXcscsort)(
        handle, m, n, nnz, descrA, cscColPtrA, cscRowIndA, P, pBuffer)


cdef cusparseStatus_t _cusparseScsru2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, float* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsru2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseScsru2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsru2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, float*, const int*, int*, csru2csrInfo_t, size_t*) noexcept nogil>__cusparseScsru2csr_bufferSizeExt)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDcsru2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, double* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsru2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDcsru2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsru2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, double*, const int*, int*, csru2csrInfo_t, size_t*) noexcept nogil>__cusparseDcsru2csr_bufferSizeExt)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseCcsru2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, cuComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsru2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseCcsru2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsru2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, cuComplex*, const int*, int*, csru2csrInfo_t, size_t*) noexcept nogil>__cusparseCcsru2csr_bufferSizeExt)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseZcsru2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnz, cuDoubleComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsru2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseZcsru2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsru2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, cuDoubleComplex*, const int*, int*, csru2csrInfo_t, size_t*) noexcept nogil>__cusparseZcsru2csr_bufferSizeExt)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseScsru2csr(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, float* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsru2csr
    _check_or_init_cusparse()
    if __cusparseScsru2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsru2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, float*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseScsru2csr)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseDcsru2csr(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, double* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsru2csr
    _check_or_init_cusparse()
    if __cusparseDcsru2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsru2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, double*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseDcsru2csr)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseCcsru2csr(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsru2csr
    _check_or_init_cusparse()
    if __cusparseCcsru2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsru2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, cuComplex*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseCcsru2csr)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseZcsru2csr(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsru2csr
    _check_or_init_cusparse()
    if __cusparseZcsru2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsru2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseZcsru2csr)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseScsr2csru(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, float* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScsr2csru
    _check_or_init_cusparse()
    if __cusparseScsr2csru == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScsr2csru is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, float*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseScsr2csru)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseDcsr2csru(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, double* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDcsr2csru
    _check_or_init_cusparse()
    if __cusparseDcsr2csru == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDcsr2csru is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, double*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseDcsr2csru)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseCcsr2csru(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, cuComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCcsr2csru
    _check_or_init_cusparse()
    if __cusparseCcsr2csru == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCcsr2csru is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, cuComplex*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseCcsr2csru)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseZcsr2csru(cusparseHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, cuDoubleComplex* csrVal, const int* csrRowPtr, int* csrColInd, csru2csrInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseZcsr2csru
    _check_or_init_cusparse()
    if __cusparseZcsr2csru == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseZcsr2csru is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, cuDoubleComplex*, const int*, int*, csru2csrInfo_t, void*) noexcept nogil>__cusparseZcsr2csru)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, info, pBuffer)


cdef cusparseStatus_t _cusparseSpruneDense2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, const float* A, int lda, const float* threshold, const cusparseMatDescr_t descrC, const float* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, size_t*) noexcept nogil>__cusparseSpruneDense2csr_bufferSizeExt)(
        handle, m, n, A, lda, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDpruneDense2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, const double* A, int lda, const double* threshold, const cusparseMatDescr_t descrC, const double* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, size_t*) noexcept nogil>__cusparseDpruneDense2csr_bufferSizeExt)(
        handle, m, n, A, lda, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSpruneDense2csrNnz(cusparseHandle_t handle, int m, int n, const float* A, int lda, const float* threshold, const cusparseMatDescr_t descrC, int* csrRowPtrC, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csrNnz
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, const float*, const cusparseMatDescr_t, int*, int*, void*) noexcept nogil>__cusparseSpruneDense2csrNnz)(
        handle, m, n, A, lda, threshold, descrC, csrRowPtrC, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseDpruneDense2csrNnz(cusparseHandle_t handle, int m, int n, const double* A, int lda, const double* threshold, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csrNnz
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, const double*, const cusparseMatDescr_t, int*, int*, void*) noexcept nogil>__cusparseDpruneDense2csrNnz)(
        handle, m, n, A, lda, threshold, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseSpruneDense2csr(cusparseHandle_t handle, int m, int n, const float* A, int lda, const float* threshold, const cusparseMatDescr_t descrC, float* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csr
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, const float*, const cusparseMatDescr_t, float*, const int*, int*, void*) noexcept nogil>__cusparseSpruneDense2csr)(
        handle, m, n, A, lda, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseDpruneDense2csr(cusparseHandle_t handle, int m, int n, const double* A, int lda, const double* threshold, const cusparseMatDescr_t descrC, double* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csr
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, const double*, const cusparseMatDescr_t, double*, const int*, int*, void*) noexcept nogil>__cusparseDpruneDense2csr)(
        handle, m, n, A, lda, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseSpruneCsr2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* threshold, const cusparseMatDescr_t descrC, const float* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, const cusparseMatDescr_t, const float*, const int*, const int*, size_t*) noexcept nogil>__cusparseSpruneCsr2csr_bufferSizeExt)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDpruneCsr2csr_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* threshold, const cusparseMatDescr_t descrC, const double* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csr_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csr_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csr_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, const cusparseMatDescr_t, const double*, const int*, const int*, size_t*) noexcept nogil>__cusparseDpruneCsr2csr_bufferSizeExt)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSpruneCsr2csrNnz(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* threshold, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csrNnz
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, const cusparseMatDescr_t, int*, int*, void*) noexcept nogil>__cusparseSpruneCsr2csrNnz)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseDpruneCsr2csrNnz(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* threshold, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csrNnz
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csrNnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csrNnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, const cusparseMatDescr_t, int*, int*, void*) noexcept nogil>__cusparseDpruneCsr2csrNnz)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, pBuffer)


cdef cusparseStatus_t _cusparseSpruneCsr2csr(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const float* threshold, const cusparseMatDescr_t descrC, float* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csr
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, const cusparseMatDescr_t, float*, const int*, int*, void*) noexcept nogil>__cusparseSpruneCsr2csr)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseDpruneCsr2csr(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, const double* threshold, const cusparseMatDescr_t descrC, double* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csr
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, const cusparseMatDescr_t, double*, const int*, int*, void*) noexcept nogil>__cusparseDpruneCsr2csr)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, threshold, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, pBuffer)


cdef cusparseStatus_t _cusparseSpruneDense2csrByPercentage_bufferSizeExt(cusparseHandle_t handle, int m, int n, const float* A, int lda, float percentage, const cusparseMatDescr_t descrC, const float* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, pruneInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csrByPercentage_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csrByPercentage_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csrByPercentage_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, float, const cusparseMatDescr_t, const float*, const int*, const int*, pruneInfo_t, size_t*) noexcept nogil>__cusparseSpruneDense2csrByPercentage_bufferSizeExt)(
        handle, m, n, A, lda, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDpruneDense2csrByPercentage_bufferSizeExt(cusparseHandle_t handle, int m, int n, const double* A, int lda, float percentage, const cusparseMatDescr_t descrC, const double* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, pruneInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csrByPercentage_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csrByPercentage_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csrByPercentage_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, float, const cusparseMatDescr_t, const double*, const int*, const int*, pruneInfo_t, size_t*) noexcept nogil>__cusparseDpruneDense2csrByPercentage_bufferSizeExt)(
        handle, m, n, A, lda, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSpruneDense2csrNnzByPercentage(cusparseHandle_t handle, int m, int n, const float* A, int lda, float percentage, const cusparseMatDescr_t descrC, int* csrRowPtrC, int* nnzTotalDevHostPtr, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csrNnzByPercentage
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csrNnzByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csrNnzByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, float, const cusparseMatDescr_t, int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseSpruneDense2csrNnzByPercentage)(
        handle, m, n, A, lda, percentage, descrC, csrRowPtrC, nnzTotalDevHostPtr, info, pBuffer)


cdef cusparseStatus_t _cusparseDpruneDense2csrNnzByPercentage(cusparseHandle_t handle, int m, int n, const double* A, int lda, float percentage, const cusparseMatDescr_t descrC, int* csrRowPtrC, int* nnzTotalDevHostPtr, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csrNnzByPercentage
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csrNnzByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csrNnzByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, float, const cusparseMatDescr_t, int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseDpruneDense2csrNnzByPercentage)(
        handle, m, n, A, lda, percentage, descrC, csrRowPtrC, nnzTotalDevHostPtr, info, pBuffer)


cdef cusparseStatus_t _cusparseSpruneDense2csrByPercentage(cusparseHandle_t handle, int m, int n, const float* A, int lda, float percentage, const cusparseMatDescr_t descrC, float* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneDense2csrByPercentage
    _check_or_init_cusparse()
    if __cusparseSpruneDense2csrByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneDense2csrByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const float*, int, float, const cusparseMatDescr_t, float*, const int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseSpruneDense2csrByPercentage)(
        handle, m, n, A, lda, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)


cdef cusparseStatus_t _cusparseDpruneDense2csrByPercentage(cusparseHandle_t handle, int m, int n, const double* A, int lda, float percentage, const cusparseMatDescr_t descrC, double* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneDense2csrByPercentage
    _check_or_init_cusparse()
    if __cusparseDpruneDense2csrByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneDense2csrByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, const double*, int, float, const cusparseMatDescr_t, double*, const int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseDpruneDense2csrByPercentage)(
        handle, m, n, A, lda, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)


cdef cusparseStatus_t _cusparseSpruneCsr2csrByPercentage_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, const float* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, pruneInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csrByPercentage_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csrByPercentage_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csrByPercentage_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, float, const cusparseMatDescr_t, const float*, const int*, const int*, pruneInfo_t, size_t*) noexcept nogil>__cusparseSpruneCsr2csrByPercentage_bufferSizeExt)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseDpruneCsr2csrByPercentage_bufferSizeExt(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, const double* csrSortedValC, const int* csrSortedRowPtrC, const int* csrSortedColIndC, pruneInfo_t info, size_t* pBufferSizeInBytes) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csrByPercentage_bufferSizeExt
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csrByPercentage_bufferSizeExt == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csrByPercentage_bufferSizeExt is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, float, const cusparseMatDescr_t, const double*, const int*, const int*, pruneInfo_t, size_t*) noexcept nogil>__cusparseDpruneCsr2csrByPercentage_bufferSizeExt)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBufferSizeInBytes)


cdef cusparseStatus_t _cusparseSpruneCsr2csrNnzByPercentage(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csrNnzByPercentage
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csrNnzByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csrNnzByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, float, const cusparseMatDescr_t, int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseSpruneCsr2csrNnzByPercentage)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, info, pBuffer)


cdef cusparseStatus_t _cusparseDpruneCsr2csrNnzByPercentage(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, int* csrSortedRowPtrC, int* nnzTotalDevHostPtr, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csrNnzByPercentage
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csrNnzByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csrNnzByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, float, const cusparseMatDescr_t, int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseDpruneCsr2csrNnzByPercentage)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedRowPtrC, nnzTotalDevHostPtr, info, pBuffer)


cdef cusparseStatus_t _cusparseSpruneCsr2csrByPercentage(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, float* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpruneCsr2csrByPercentage
    _check_or_init_cusparse()
    if __cusparseSpruneCsr2csrByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpruneCsr2csrByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, float, const cusparseMatDescr_t, float*, const int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseSpruneCsr2csrByPercentage)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)


cdef cusparseStatus_t _cusparseDpruneCsr2csrByPercentage(cusparseHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrSortedValA, const int* csrSortedRowPtrA, const int* csrSortedColIndA, float percentage, const cusparseMatDescr_t descrC, double* csrSortedValC, const int* csrSortedRowPtrC, int* csrSortedColIndC, pruneInfo_t info, void* pBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDpruneCsr2csrByPercentage
    _check_or_init_cusparse()
    if __cusparseDpruneCsr2csrByPercentage == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDpruneCsr2csrByPercentage is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, float, const cusparseMatDescr_t, double*, const int*, int*, pruneInfo_t, void*) noexcept nogil>__cusparseDpruneCsr2csrByPercentage)(
        handle, m, n, nnzA, descrA, csrSortedValA, csrSortedRowPtrA, csrSortedColIndA, percentage, descrC, csrSortedValC, csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)


cdef cusparseStatus_t _cusparseCsr2cscEx2(cusparseHandle_t handle, int m, int n, int nnz, const void* csrVal, const int* csrRowPtr, const int* csrColInd, void* cscVal, int* cscColPtr, int* cscRowInd, cudaDataType valType, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, cusparseCsr2CscAlg_t alg, void* buffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCsr2cscEx2
    _check_or_init_cusparse()
    if __cusparseCsr2cscEx2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCsr2cscEx2 is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const void*, const int*, const int*, void*, int*, int*, cudaDataType, cusparseAction_t, cusparseIndexBase_t, cusparseCsr2CscAlg_t, void*) noexcept nogil>__cusparseCsr2cscEx2)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, cscVal, cscColPtr, cscRowInd, valType, copyValues, idxBase, alg, buffer)


cdef cusparseStatus_t _cusparseCsr2cscEx2_bufferSize(cusparseHandle_t handle, int m, int n, int nnz, const void* csrVal, const int* csrRowPtr, const int* csrColInd, void* cscVal, int* cscColPtr, int* cscRowInd, cudaDataType valType, cusparseAction_t copyValues, cusparseIndexBase_t idxBase, cusparseCsr2CscAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCsr2cscEx2_bufferSize
    _check_or_init_cusparse()
    if __cusparseCsr2cscEx2_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCsr2cscEx2_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, int, int, int, const void*, const int*, const int*, void*, int*, int*, cudaDataType, cusparseAction_t, cusparseIndexBase_t, cusparseCsr2CscAlg_t, size_t*) noexcept nogil>__cusparseCsr2cscEx2_bufferSize)(
        handle, m, n, nnz, csrVal, csrRowPtr, csrColInd, cscVal, cscColPtr, cscRowInd, valType, copyValues, idxBase, alg, bufferSize)


cdef cusparseStatus_t _cusparseCreateSpVec(cusparseSpVecDescr_t* spVecDescr, int64_t size, int64_t nnz, void* indices, void* values, cusparseIndexType_t idxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateSpVec
    _check_or_init_cusparse()
    if __cusparseCreateSpVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateSpVec is not found")
    return (<cusparseStatus_t (*)(cusparseSpVecDescr_t*, int64_t, int64_t, void*, void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateSpVec)(
        spVecDescr, size, nnz, indices, values, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstSpVec(cusparseConstSpVecDescr_t* spVecDescr, int64_t size, int64_t nnz, const void* indices, const void* values, cusparseIndexType_t idxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstSpVec
    _check_or_init_cusparse()
    if __cusparseCreateConstSpVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstSpVec is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpVecDescr_t*, int64_t, int64_t, const void*, const void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstSpVec)(
        spVecDescr, size, nnz, indices, values, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseDestroySpVec(cusparseConstSpVecDescr_t spVecDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroySpVec
    _check_or_init_cusparse()
    if __cusparseDestroySpVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroySpVec is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpVecDescr_t) noexcept nogil>__cusparseDestroySpVec)(
        spVecDescr)


cdef cusparseStatus_t _cusparseSpVecGet(cusparseSpVecDescr_t spVecDescr, int64_t* size, int64_t* nnz, void** indices, void** values, cusparseIndexType_t* idxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVecGet
    _check_or_init_cusparse()
    if __cusparseSpVecGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVecGet is not found")
    return (<cusparseStatus_t (*)(cusparseSpVecDescr_t, int64_t*, int64_t*, void**, void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseSpVecGet)(
        spVecDescr, size, nnz, indices, values, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseConstSpVecGet(cusparseConstSpVecDescr_t spVecDescr, int64_t* size, int64_t* nnz, const void** indices, const void** values, cusparseIndexType_t* idxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstSpVecGet
    _check_or_init_cusparse()
    if __cusparseConstSpVecGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstSpVecGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpVecDescr_t, int64_t*, int64_t*, const void**, const void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseConstSpVecGet)(
        spVecDescr, size, nnz, indices, values, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseSpVecGetIndexBase(cusparseConstSpVecDescr_t spVecDescr, cusparseIndexBase_t* idxBase) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVecGetIndexBase
    _check_or_init_cusparse()
    if __cusparseSpVecGetIndexBase == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVecGetIndexBase is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpVecDescr_t, cusparseIndexBase_t*) noexcept nogil>__cusparseSpVecGetIndexBase)(
        spVecDescr, idxBase)


cdef cusparseStatus_t _cusparseSpVecGetValues(cusparseSpVecDescr_t spVecDescr, void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVecGetValues
    _check_or_init_cusparse()
    if __cusparseSpVecGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVecGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseSpVecDescr_t, void**) noexcept nogil>__cusparseSpVecGetValues)(
        spVecDescr, values)


cdef cusparseStatus_t _cusparseConstSpVecGetValues(cusparseConstSpVecDescr_t spVecDescr, const void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstSpVecGetValues
    _check_or_init_cusparse()
    if __cusparseConstSpVecGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstSpVecGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpVecDescr_t, const void**) noexcept nogil>__cusparseConstSpVecGetValues)(
        spVecDescr, values)


cdef cusparseStatus_t _cusparseSpVecSetValues(cusparseSpVecDescr_t spVecDescr, void* values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVecSetValues
    _check_or_init_cusparse()
    if __cusparseSpVecSetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVecSetValues is not found")
    return (<cusparseStatus_t (*)(cusparseSpVecDescr_t, void*) noexcept nogil>__cusparseSpVecSetValues)(
        spVecDescr, values)


cdef cusparseStatus_t _cusparseCreateDnVec(cusparseDnVecDescr_t* dnVecDescr, int64_t size, void* values, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateDnVec
    _check_or_init_cusparse()
    if __cusparseCreateDnVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateDnVec is not found")
    return (<cusparseStatus_t (*)(cusparseDnVecDescr_t*, int64_t, void*, cudaDataType) noexcept nogil>__cusparseCreateDnVec)(
        dnVecDescr, size, values, valueType)


cdef cusparseStatus_t _cusparseCreateConstDnVec(cusparseConstDnVecDescr_t* dnVecDescr, int64_t size, const void* values, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstDnVec
    _check_or_init_cusparse()
    if __cusparseCreateConstDnVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstDnVec is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnVecDescr_t*, int64_t, const void*, cudaDataType) noexcept nogil>__cusparseCreateConstDnVec)(
        dnVecDescr, size, values, valueType)


cdef cusparseStatus_t _cusparseDestroyDnVec(cusparseConstDnVecDescr_t dnVecDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyDnVec
    _check_or_init_cusparse()
    if __cusparseDestroyDnVec == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyDnVec is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnVecDescr_t) noexcept nogil>__cusparseDestroyDnVec)(
        dnVecDescr)


cdef cusparseStatus_t _cusparseDnVecGet(cusparseDnVecDescr_t dnVecDescr, int64_t* size, void** values, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnVecGet
    _check_or_init_cusparse()
    if __cusparseDnVecGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnVecGet is not found")
    return (<cusparseStatus_t (*)(cusparseDnVecDescr_t, int64_t*, void**, cudaDataType*) noexcept nogil>__cusparseDnVecGet)(
        dnVecDescr, size, values, valueType)


cdef cusparseStatus_t _cusparseConstDnVecGet(cusparseConstDnVecDescr_t dnVecDescr, int64_t* size, const void** values, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstDnVecGet
    _check_or_init_cusparse()
    if __cusparseConstDnVecGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstDnVecGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnVecDescr_t, int64_t*, const void**, cudaDataType*) noexcept nogil>__cusparseConstDnVecGet)(
        dnVecDescr, size, values, valueType)


cdef cusparseStatus_t _cusparseDnVecGetValues(cusparseDnVecDescr_t dnVecDescr, void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnVecGetValues
    _check_or_init_cusparse()
    if __cusparseDnVecGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnVecGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseDnVecDescr_t, void**) noexcept nogil>__cusparseDnVecGetValues)(
        dnVecDescr, values)


cdef cusparseStatus_t _cusparseConstDnVecGetValues(cusparseConstDnVecDescr_t dnVecDescr, const void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstDnVecGetValues
    _check_or_init_cusparse()
    if __cusparseConstDnVecGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstDnVecGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnVecDescr_t, const void**) noexcept nogil>__cusparseConstDnVecGetValues)(
        dnVecDescr, values)


cdef cusparseStatus_t _cusparseDnVecSetValues(cusparseDnVecDescr_t dnVecDescr, void* values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnVecSetValues
    _check_or_init_cusparse()
    if __cusparseDnVecSetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnVecSetValues is not found")
    return (<cusparseStatus_t (*)(cusparseDnVecDescr_t, void*) noexcept nogil>__cusparseDnVecSetValues)(
        dnVecDescr, values)


cdef cusparseStatus_t _cusparseDestroySpMat(cusparseConstSpMatDescr_t spMatDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroySpMat
    _check_or_init_cusparse()
    if __cusparseDestroySpMat == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroySpMat is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t) noexcept nogil>__cusparseDestroySpMat)(
        spMatDescr)


cdef cusparseStatus_t _cusparseSpMatGetFormat(cusparseConstSpMatDescr_t spMatDescr, cusparseFormat_t* format) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetFormat
    _check_or_init_cusparse()
    if __cusparseSpMatGetFormat == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetFormat is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, cusparseFormat_t*) noexcept nogil>__cusparseSpMatGetFormat)(
        spMatDescr, format)


cdef cusparseStatus_t _cusparseSpMatGetIndexBase(cusparseConstSpMatDescr_t spMatDescr, cusparseIndexBase_t* idxBase) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetIndexBase
    _check_or_init_cusparse()
    if __cusparseSpMatGetIndexBase == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetIndexBase is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, cusparseIndexBase_t*) noexcept nogil>__cusparseSpMatGetIndexBase)(
        spMatDescr, idxBase)


cdef cusparseStatus_t _cusparseSpMatGetValues(cusparseSpMatDescr_t spMatDescr, void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetValues
    _check_or_init_cusparse()
    if __cusparseSpMatGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, void**) noexcept nogil>__cusparseSpMatGetValues)(
        spMatDescr, values)


cdef cusparseStatus_t _cusparseConstSpMatGetValues(cusparseConstSpMatDescr_t spMatDescr, const void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstSpMatGetValues
    _check_or_init_cusparse()
    if __cusparseConstSpMatGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstSpMatGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, const void**) noexcept nogil>__cusparseConstSpMatGetValues)(
        spMatDescr, values)


cdef cusparseStatus_t _cusparseSpMatSetValues(cusparseSpMatDescr_t spMatDescr, void* values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatSetValues
    _check_or_init_cusparse()
    if __cusparseSpMatSetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatSetValues is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, void*) noexcept nogil>__cusparseSpMatSetValues)(
        spMatDescr, values)


cdef cusparseStatus_t _cusparseSpMatGetSize(cusparseConstSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetSize
    _check_or_init_cusparse()
    if __cusparseSpMatGetSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetSize is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int64_t*, int64_t*, int64_t*) noexcept nogil>__cusparseSpMatGetSize)(
        spMatDescr, rows, cols, nnz)


cdef cusparseStatus_t _cusparseSpMatGetStridedBatch(cusparseConstSpMatDescr_t spMatDescr, int* batchCount) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetStridedBatch
    _check_or_init_cusparse()
    if __cusparseSpMatGetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int*) noexcept nogil>__cusparseSpMatGetStridedBatch)(
        spMatDescr, batchCount)


cdef cusparseStatus_t _cusparseCooSetStridedBatch(cusparseSpMatDescr_t spMatDescr, int batchCount, int64_t batchStride) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCooSetStridedBatch
    _check_or_init_cusparse()
    if __cusparseCooSetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCooSetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int, int64_t) noexcept nogil>__cusparseCooSetStridedBatch)(
        spMatDescr, batchCount, batchStride)


cdef cusparseStatus_t _cusparseCsrSetStridedBatch(cusparseSpMatDescr_t spMatDescr, int batchCount, int64_t offsetsBatchStride, int64_t columnsValuesBatchStride) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCsrSetStridedBatch
    _check_or_init_cusparse()
    if __cusparseCsrSetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCsrSetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int, int64_t, int64_t) noexcept nogil>__cusparseCsrSetStridedBatch)(
        spMatDescr, batchCount, offsetsBatchStride, columnsValuesBatchStride)


cdef cusparseStatus_t _cusparseSpMatGetAttribute(cusparseConstSpMatDescr_t spMatDescr, cusparseSpMatAttribute_t attribute, void* data, size_t dataSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatGetAttribute
    _check_or_init_cusparse()
    if __cusparseSpMatGetAttribute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatGetAttribute is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, cusparseSpMatAttribute_t, void*, size_t) noexcept nogil>__cusparseSpMatGetAttribute)(
        spMatDescr, attribute, data, dataSize)


cdef cusparseStatus_t _cusparseSpMatSetAttribute(cusparseSpMatDescr_t spMatDescr, cusparseSpMatAttribute_t attribute, void* data, size_t dataSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMatSetAttribute
    _check_or_init_cusparse()
    if __cusparseSpMatSetAttribute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMatSetAttribute is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, cusparseSpMatAttribute_t, void*, size_t) noexcept nogil>__cusparseSpMatSetAttribute)(
        spMatDescr, attribute, data, dataSize)


cdef cusparseStatus_t _cusparseCreateCsr(cusparseSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, void* csrRowOffsets, void* csrColInd, void* csrValues, cusparseIndexType_t csrRowOffsetsType, cusparseIndexType_t csrColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCsr
    _check_or_init_cusparse()
    if __cusparseCreateCsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCsr is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, void*, void*, void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateCsr)(
        spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd, csrValues, csrRowOffsetsType, csrColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstCsr(cusparseConstSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, const void* csrRowOffsets, const void* csrColInd, const void* csrValues, cusparseIndexType_t csrRowOffsetsType, cusparseIndexType_t csrColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstCsr
    _check_or_init_cusparse()
    if __cusparseCreateConstCsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstCsr is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, const void*, const void*, const void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstCsr)(
        spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd, csrValues, csrRowOffsetsType, csrColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateCsc(cusparseSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, void* cscColOffsets, void* cscRowInd, void* cscValues, cusparseIndexType_t cscColOffsetsType, cusparseIndexType_t cscRowIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCsc
    _check_or_init_cusparse()
    if __cusparseCreateCsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCsc is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, void*, void*, void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateCsc)(
        spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd, cscValues, cscColOffsetsType, cscRowIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstCsc(cusparseConstSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, const void* cscColOffsets, const void* cscRowInd, const void* cscValues, cusparseIndexType_t cscColOffsetsType, cusparseIndexType_t cscRowIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstCsc
    _check_or_init_cusparse()
    if __cusparseCreateConstCsc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstCsc is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, const void*, const void*, const void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstCsc)(
        spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd, cscValues, cscColOffsetsType, cscRowIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCsrGet(cusparseSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, void** csrRowOffsets, void** csrColInd, void** csrValues, cusparseIndexType_t* csrRowOffsetsType, cusparseIndexType_t* csrColIndType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCsrGet
    _check_or_init_cusparse()
    if __cusparseCsrGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCsrGet is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int64_t*, int64_t*, int64_t*, void**, void**, void**, cusparseIndexType_t*, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseCsrGet)(
        spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd, csrValues, csrRowOffsetsType, csrColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseConstCsrGet(cusparseConstSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, const void** csrRowOffsets, const void** csrColInd, const void** csrValues, cusparseIndexType_t* csrRowOffsetsType, cusparseIndexType_t* csrColIndType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstCsrGet
    _check_or_init_cusparse()
    if __cusparseConstCsrGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstCsrGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int64_t*, int64_t*, int64_t*, const void**, const void**, const void**, cusparseIndexType_t*, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseConstCsrGet)(
        spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd, csrValues, csrRowOffsetsType, csrColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCscGet(cusparseSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, void** cscColOffsets, void** cscRowInd, void** cscValues, cusparseIndexType_t* cscColOffsetsType, cusparseIndexType_t* cscRowIndType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCscGet
    _check_or_init_cusparse()
    if __cusparseCscGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCscGet is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int64_t*, int64_t*, int64_t*, void**, void**, void**, cusparseIndexType_t*, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseCscGet)(
        spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd, cscValues, cscColOffsetsType, cscRowIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseConstCscGet(cusparseConstSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, const void** cscColOffsets, const void** cscRowInd, const void** cscValues, cusparseIndexType_t* cscColOffsetsType, cusparseIndexType_t* cscRowIndType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstCscGet
    _check_or_init_cusparse()
    if __cusparseConstCscGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstCscGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int64_t*, int64_t*, int64_t*, const void**, const void**, const void**, cusparseIndexType_t*, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseConstCscGet)(
        spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd, cscValues, cscColOffsetsType, cscRowIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCsrSetPointers(cusparseSpMatDescr_t spMatDescr, void* csrRowOffsets, void* csrColInd, void* csrValues) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCsrSetPointers
    _check_or_init_cusparse()
    if __cusparseCsrSetPointers == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCsrSetPointers is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, void*, void*, void*) noexcept nogil>__cusparseCsrSetPointers)(
        spMatDescr, csrRowOffsets, csrColInd, csrValues)


cdef cusparseStatus_t _cusparseCscSetPointers(cusparseSpMatDescr_t spMatDescr, void* cscColOffsets, void* cscRowInd, void* cscValues) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCscSetPointers
    _check_or_init_cusparse()
    if __cusparseCscSetPointers == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCscSetPointers is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, void*, void*, void*) noexcept nogil>__cusparseCscSetPointers)(
        spMatDescr, cscColOffsets, cscRowInd, cscValues)


cdef cusparseStatus_t _cusparseCreateCoo(cusparseSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, void* cooRowInd, void* cooColInd, void* cooValues, cusparseIndexType_t cooIdxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateCoo
    _check_or_init_cusparse()
    if __cusparseCreateCoo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateCoo is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, void*, void*, void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateCoo)(
        spMatDescr, rows, cols, nnz, cooRowInd, cooColInd, cooValues, cooIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstCoo(cusparseConstSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, const void* cooRowInd, const void* cooColInd, const void* cooValues, cusparseIndexType_t cooIdxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstCoo
    _check_or_init_cusparse()
    if __cusparseCreateConstCoo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstCoo is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, const void*, const void*, const void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstCoo)(
        spMatDescr, rows, cols, nnz, cooRowInd, cooColInd, cooValues, cooIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCooGet(cusparseSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, void** cooRowInd, void** cooColInd, void** cooValues, cusparseIndexType_t* idxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCooGet
    _check_or_init_cusparse()
    if __cusparseCooGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCooGet is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int64_t*, int64_t*, int64_t*, void**, void**, void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseCooGet)(
        spMatDescr, rows, cols, nnz, cooRowInd, cooColInd, cooValues, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseConstCooGet(cusparseConstSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* nnz, const void** cooRowInd, const void** cooColInd, const void** cooValues, cusparseIndexType_t* idxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstCooGet
    _check_or_init_cusparse()
    if __cusparseConstCooGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstCooGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int64_t*, int64_t*, int64_t*, const void**, const void**, const void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseConstCooGet)(
        spMatDescr, rows, cols, nnz, cooRowInd, cooColInd, cooValues, idxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCooSetPointers(cusparseSpMatDescr_t spMatDescr, void* cooRows, void* cooColumns, void* cooValues) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCooSetPointers
    _check_or_init_cusparse()
    if __cusparseCooSetPointers == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCooSetPointers is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, void*, void*, void*) noexcept nogil>__cusparseCooSetPointers)(
        spMatDescr, cooRows, cooColumns, cooValues)


cdef cusparseStatus_t _cusparseCreateBlockedEll(cusparseSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t ellBlockSize, int64_t ellCols, void* ellColInd, void* ellValue, cusparseIndexType_t ellIdxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBlockedEll
    _check_or_init_cusparse()
    if __cusparseCreateBlockedEll == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBlockedEll is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, void*, void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateBlockedEll)(
        spMatDescr, rows, cols, ellBlockSize, ellCols, ellColInd, ellValue, ellIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstBlockedEll(cusparseConstSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t ellBlockSize, int64_t ellCols, const void* ellColInd, const void* ellValue, cusparseIndexType_t ellIdxType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstBlockedEll
    _check_or_init_cusparse()
    if __cusparseCreateConstBlockedEll == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstBlockedEll is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, const void*, const void*, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstBlockedEll)(
        spMatDescr, rows, cols, ellBlockSize, ellCols, ellColInd, ellValue, ellIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseBlockedEllGet(cusparseSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* ellBlockSize, int64_t* ellCols, void** ellColInd, void** ellValue, cusparseIndexType_t* ellIdxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseBlockedEllGet
    _check_or_init_cusparse()
    if __cusparseBlockedEllGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseBlockedEllGet is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int64_t*, int64_t*, int64_t*, int64_t*, void**, void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseBlockedEllGet)(
        spMatDescr, rows, cols, ellBlockSize, ellCols, ellColInd, ellValue, ellIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseConstBlockedEllGet(cusparseConstSpMatDescr_t spMatDescr, int64_t* rows, int64_t* cols, int64_t* ellBlockSize, int64_t* ellCols, const void** ellColInd, const void** ellValue, cusparseIndexType_t* ellIdxType, cusparseIndexBase_t* idxBase, cudaDataType* valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstBlockedEllGet
    _check_or_init_cusparse()
    if __cusparseConstBlockedEllGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstBlockedEllGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t, int64_t*, int64_t*, int64_t*, int64_t*, const void**, const void**, cusparseIndexType_t*, cusparseIndexBase_t*, cudaDataType*) noexcept nogil>__cusparseConstBlockedEllGet)(
        spMatDescr, rows, cols, ellBlockSize, ellCols, ellColInd, ellValue, ellIdxType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateDnMat(cusparseDnMatDescr_t* dnMatDescr, int64_t rows, int64_t cols, int64_t ld, void* values, cudaDataType valueType, cusparseOrder_t order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateDnMat
    _check_or_init_cusparse()
    if __cusparseCreateDnMat == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateDnMat is not found")
    return (<cusparseStatus_t (*)(cusparseDnMatDescr_t*, int64_t, int64_t, int64_t, void*, cudaDataType, cusparseOrder_t) noexcept nogil>__cusparseCreateDnMat)(
        dnMatDescr, rows, cols, ld, values, valueType, order)


cdef cusparseStatus_t _cusparseCreateConstDnMat(cusparseConstDnMatDescr_t* dnMatDescr, int64_t rows, int64_t cols, int64_t ld, const void* values, cudaDataType valueType, cusparseOrder_t order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstDnMat
    _check_or_init_cusparse()
    if __cusparseCreateConstDnMat == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstDnMat is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnMatDescr_t*, int64_t, int64_t, int64_t, const void*, cudaDataType, cusparseOrder_t) noexcept nogil>__cusparseCreateConstDnMat)(
        dnMatDescr, rows, cols, ld, values, valueType, order)


cdef cusparseStatus_t _cusparseDestroyDnMat(cusparseConstDnMatDescr_t dnMatDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDestroyDnMat
    _check_or_init_cusparse()
    if __cusparseDestroyDnMat == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDestroyDnMat is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnMatDescr_t) noexcept nogil>__cusparseDestroyDnMat)(
        dnMatDescr)


cdef cusparseStatus_t _cusparseDnMatGet(cusparseDnMatDescr_t dnMatDescr, int64_t* rows, int64_t* cols, int64_t* ld, void** values, cudaDataType* type, cusparseOrder_t* order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnMatGet
    _check_or_init_cusparse()
    if __cusparseDnMatGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnMatGet is not found")
    return (<cusparseStatus_t (*)(cusparseDnMatDescr_t, int64_t*, int64_t*, int64_t*, void**, cudaDataType*, cusparseOrder_t*) noexcept nogil>__cusparseDnMatGet)(
        dnMatDescr, rows, cols, ld, values, type, order)


cdef cusparseStatus_t _cusparseConstDnMatGet(cusparseConstDnMatDescr_t dnMatDescr, int64_t* rows, int64_t* cols, int64_t* ld, const void** values, cudaDataType* type, cusparseOrder_t* order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstDnMatGet
    _check_or_init_cusparse()
    if __cusparseConstDnMatGet == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstDnMatGet is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnMatDescr_t, int64_t*, int64_t*, int64_t*, const void**, cudaDataType*, cusparseOrder_t*) noexcept nogil>__cusparseConstDnMatGet)(
        dnMatDescr, rows, cols, ld, values, type, order)


cdef cusparseStatus_t _cusparseDnMatGetValues(cusparseDnMatDescr_t dnMatDescr, void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnMatGetValues
    _check_or_init_cusparse()
    if __cusparseDnMatGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnMatGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseDnMatDescr_t, void**) noexcept nogil>__cusparseDnMatGetValues)(
        dnMatDescr, values)


cdef cusparseStatus_t _cusparseConstDnMatGetValues(cusparseConstDnMatDescr_t dnMatDescr, const void** values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseConstDnMatGetValues
    _check_or_init_cusparse()
    if __cusparseConstDnMatGetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseConstDnMatGetValues is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnMatDescr_t, const void**) noexcept nogil>__cusparseConstDnMatGetValues)(
        dnMatDescr, values)


cdef cusparseStatus_t _cusparseDnMatSetValues(cusparseDnMatDescr_t dnMatDescr, void* values) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnMatSetValues
    _check_or_init_cusparse()
    if __cusparseDnMatSetValues == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnMatSetValues is not found")
    return (<cusparseStatus_t (*)(cusparseDnMatDescr_t, void*) noexcept nogil>__cusparseDnMatSetValues)(
        dnMatDescr, values)


cdef cusparseStatus_t _cusparseDnMatSetStridedBatch(cusparseDnMatDescr_t dnMatDescr, int batchCount, int64_t batchStride) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnMatSetStridedBatch
    _check_or_init_cusparse()
    if __cusparseDnMatSetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnMatSetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseDnMatDescr_t, int, int64_t) noexcept nogil>__cusparseDnMatSetStridedBatch)(
        dnMatDescr, batchCount, batchStride)


cdef cusparseStatus_t _cusparseDnMatGetStridedBatch(cusparseConstDnMatDescr_t dnMatDescr, int* batchCount, int64_t* batchStride) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDnMatGetStridedBatch
    _check_or_init_cusparse()
    if __cusparseDnMatGetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDnMatGetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseConstDnMatDescr_t, int*, int64_t*) noexcept nogil>__cusparseDnMatGetStridedBatch)(
        dnMatDescr, batchCount, batchStride)


cdef cusparseStatus_t _cusparseAxpby(cusparseHandle_t handle, const void* alpha, cusparseConstSpVecDescr_t vecX, const void* beta, cusparseDnVecDescr_t vecY) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseAxpby
    _check_or_init_cusparse()
    if __cusparseAxpby == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseAxpby is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, const void*, cusparseConstSpVecDescr_t, const void*, cusparseDnVecDescr_t) noexcept nogil>__cusparseAxpby)(
        handle, alpha, vecX, beta, vecY)


cdef cusparseStatus_t _cusparseGather(cusparseHandle_t handle, cusparseConstDnVecDescr_t vecY, cusparseSpVecDescr_t vecX) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseGather
    _check_or_init_cusparse()
    if __cusparseGather == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseGather is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstDnVecDescr_t, cusparseSpVecDescr_t) noexcept nogil>__cusparseGather)(
        handle, vecY, vecX)


cdef cusparseStatus_t _cusparseScatter(cusparseHandle_t handle, cusparseConstSpVecDescr_t vecX, cusparseDnVecDescr_t vecY) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseScatter
    _check_or_init_cusparse()
    if __cusparseScatter == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseScatter is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstSpVecDescr_t, cusparseDnVecDescr_t) noexcept nogil>__cusparseScatter)(
        handle, vecX, vecY)


cdef cusparseStatus_t _cusparseRot(cusparseHandle_t handle, const void* c_coeff, const void* s_coeff, cusparseSpVecDescr_t vecX, cusparseDnVecDescr_t vecY) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseRot
    _check_or_init_cusparse()
    if __cusparseRot == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseRot is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, const void*, const void*, cusparseSpVecDescr_t, cusparseDnVecDescr_t) noexcept nogil>__cusparseRot)(
        handle, c_coeff, s_coeff, vecX, vecY)


cdef cusparseStatus_t _cusparseSpVV_bufferSize(cusparseHandle_t handle, cusparseOperation_t opX, cusparseConstSpVecDescr_t vecX, cusparseConstDnVecDescr_t vecY, const void* result, cudaDataType computeType, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVV_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpVV_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVV_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseConstSpVecDescr_t, cusparseConstDnVecDescr_t, const void*, cudaDataType, size_t*) noexcept nogil>__cusparseSpVV_bufferSize)(
        handle, opX, vecX, vecY, result, computeType, bufferSize)


cdef cusparseStatus_t _cusparseSpVV(cusparseHandle_t handle, cusparseOperation_t opX, cusparseConstSpVecDescr_t vecX, cusparseConstDnVecDescr_t vecY, void* result, cudaDataType computeType, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpVV
    _check_or_init_cusparse()
    if __cusparseSpVV == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpVV is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseConstSpVecDescr_t, cusparseConstDnVecDescr_t, void*, cudaDataType, void*) noexcept nogil>__cusparseSpVV)(
        handle, opX, vecX, vecY, result, computeType, externalBuffer)


cdef cusparseStatus_t _cusparseSparseToDense_bufferSize(cusparseHandle_t handle, cusparseConstSpMatDescr_t matA, cusparseDnMatDescr_t matB, cusparseSparseToDenseAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSparseToDense_bufferSize
    _check_or_init_cusparse()
    if __cusparseSparseToDense_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSparseToDense_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstSpMatDescr_t, cusparseDnMatDescr_t, cusparseSparseToDenseAlg_t, size_t*) noexcept nogil>__cusparseSparseToDense_bufferSize)(
        handle, matA, matB, alg, bufferSize)


cdef cusparseStatus_t _cusparseSparseToDense(cusparseHandle_t handle, cusparseConstSpMatDescr_t matA, cusparseDnMatDescr_t matB, cusparseSparseToDenseAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSparseToDense
    _check_or_init_cusparse()
    if __cusparseSparseToDense == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSparseToDense is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstSpMatDescr_t, cusparseDnMatDescr_t, cusparseSparseToDenseAlg_t, void*) noexcept nogil>__cusparseSparseToDense)(
        handle, matA, matB, alg, externalBuffer)


cdef cusparseStatus_t _cusparseDenseToSparse_bufferSize(cusparseHandle_t handle, cusparseConstDnMatDescr_t matA, cusparseSpMatDescr_t matB, cusparseDenseToSparseAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDenseToSparse_bufferSize
    _check_or_init_cusparse()
    if __cusparseDenseToSparse_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDenseToSparse_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstDnMatDescr_t, cusparseSpMatDescr_t, cusparseDenseToSparseAlg_t, size_t*) noexcept nogil>__cusparseDenseToSparse_bufferSize)(
        handle, matA, matB, alg, bufferSize)


cdef cusparseStatus_t _cusparseDenseToSparse_analysis(cusparseHandle_t handle, cusparseConstDnMatDescr_t matA, cusparseSpMatDescr_t matB, cusparseDenseToSparseAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDenseToSparse_analysis
    _check_or_init_cusparse()
    if __cusparseDenseToSparse_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDenseToSparse_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstDnMatDescr_t, cusparseSpMatDescr_t, cusparseDenseToSparseAlg_t, void*) noexcept nogil>__cusparseDenseToSparse_analysis)(
        handle, matA, matB, alg, externalBuffer)


cdef cusparseStatus_t _cusparseDenseToSparse_convert(cusparseHandle_t handle, cusparseConstDnMatDescr_t matA, cusparseSpMatDescr_t matB, cusparseDenseToSparseAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseDenseToSparse_convert
    _check_or_init_cusparse()
    if __cusparseDenseToSparse_convert == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseDenseToSparse_convert is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseConstDnMatDescr_t, cusparseSpMatDescr_t, cusparseDenseToSparseAlg_t, void*) noexcept nogil>__cusparseDenseToSparse_convert)(
        handle, matA, matB, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpMV(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, const void* beta, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpMVAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMV
    _check_or_init_cusparse()
    if __cusparseSpMV == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMV is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, const void*, cusparseDnVecDescr_t, cudaDataType, cusparseSpMVAlg_t, void*) noexcept nogil>__cusparseSpMV)(
        handle, opA, alpha, matA, vecX, beta, vecY, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpMV_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, const void* beta, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpMVAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMV_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpMV_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMV_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, const void*, cusparseDnVecDescr_t, cudaDataType, cusparseSpMVAlg_t, size_t*) noexcept nogil>__cusparseSpMV_bufferSize)(
        handle, opA, alpha, matA, vecX, beta, vecY, computeType, alg, bufferSize)


cdef cusparseStatus_t _cusparseSpSV_createDescr(cusparseSpSVDescr_t* descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_createDescr
    _check_or_init_cusparse()
    if __cusparseSpSV_createDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_createDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpSVDescr_t*) noexcept nogil>__cusparseSpSV_createDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpSV_destroyDescr(cusparseSpSVDescr_t descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_destroyDescr
    _check_or_init_cusparse()
    if __cusparseSpSV_destroyDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_destroyDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpSVDescr_t) noexcept nogil>__cusparseSpSV_destroyDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpSV_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpSVAlg_t alg, cusparseSpSVDescr_t spsvDescr, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpSV_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t, cudaDataType, cusparseSpSVAlg_t, cusparseSpSVDescr_t, size_t*) noexcept nogil>__cusparseSpSV_bufferSize)(
        handle, opA, alpha, matA, vecX, vecY, computeType, alg, spsvDescr, bufferSize)


cdef cusparseStatus_t _cusparseSpSV_analysis(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpSVAlg_t alg, cusparseSpSVDescr_t spsvDescr, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_analysis
    _check_or_init_cusparse()
    if __cusparseSpSV_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t, cudaDataType, cusparseSpSVAlg_t, cusparseSpSVDescr_t, void*) noexcept nogil>__cusparseSpSV_analysis)(
        handle, opA, alpha, matA, vecX, vecY, computeType, alg, spsvDescr, externalBuffer)


cdef cusparseStatus_t _cusparseSpSV_solve(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpSVAlg_t alg, cusparseSpSVDescr_t spsvDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_solve
    _check_or_init_cusparse()
    if __cusparseSpSV_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t, cudaDataType, cusparseSpSVAlg_t, cusparseSpSVDescr_t) noexcept nogil>__cusparseSpSV_solve)(
        handle, opA, alpha, matA, vecX, vecY, computeType, alg, spsvDescr)


cdef cusparseStatus_t _cusparseSpSM_createDescr(cusparseSpSMDescr_t* descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_createDescr
    _check_or_init_cusparse()
    if __cusparseSpSM_createDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_createDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpSMDescr_t*) noexcept nogil>__cusparseSpSM_createDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpSM_destroyDescr(cusparseSpSMDescr_t descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_destroyDescr
    _check_or_init_cusparse()
    if __cusparseSpSM_destroyDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_destroyDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpSMDescr_t) noexcept nogil>__cusparseSpSM_destroyDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpSM_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpSMAlg_t alg, cusparseSpSMDescr_t spsmDescr, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpSM_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, cusparseDnMatDescr_t, cudaDataType, cusparseSpSMAlg_t, cusparseSpSMDescr_t, size_t*) noexcept nogil>__cusparseSpSM_bufferSize)(
        handle, opA, opB, alpha, matA, matB, matC, computeType, alg, spsmDescr, bufferSize)


cdef cusparseStatus_t _cusparseSpSM_analysis(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpSMAlg_t alg, cusparseSpSMDescr_t spsmDescr, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_analysis
    _check_or_init_cusparse()
    if __cusparseSpSM_analysis == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_analysis is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, cusparseDnMatDescr_t, cudaDataType, cusparseSpSMAlg_t, cusparseSpSMDescr_t, void*) noexcept nogil>__cusparseSpSM_analysis)(
        handle, opA, opB, alpha, matA, matB, matC, computeType, alg, spsmDescr, externalBuffer)


cdef cusparseStatus_t _cusparseSpSM_solve(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpSMAlg_t alg, cusparseSpSMDescr_t spsmDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_solve
    _check_or_init_cusparse()
    if __cusparseSpSM_solve == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_solve is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, cusparseDnMatDescr_t, cudaDataType, cusparseSpSMAlg_t, cusparseSpSMDescr_t) noexcept nogil>__cusparseSpSM_solve)(
        handle, opA, opB, alpha, matA, matB, matC, computeType, alg, spsmDescr)


cdef cusparseStatus_t _cusparseSpMM_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpMMAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMM_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpMM_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMM_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseDnMatDescr_t, cudaDataType, cusparseSpMMAlg_t, size_t*) noexcept nogil>__cusparseSpMM_bufferSize)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, bufferSize)


cdef cusparseStatus_t _cusparseSpMM_preprocess(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpMMAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMM_preprocess
    _check_or_init_cusparse()
    if __cusparseSpMM_preprocess == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMM_preprocess is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseDnMatDescr_t, cudaDataType, cusparseSpMMAlg_t, void*) noexcept nogil>__cusparseSpMM_preprocess)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpMM(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpMMAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMM
    _check_or_init_cusparse()
    if __cusparseSpMM == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMM is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseDnMatDescr_t, cudaDataType, cusparseSpMMAlg_t, void*) noexcept nogil>__cusparseSpMM)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpGEMM_createDescr(cusparseSpGEMMDescr_t* descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_createDescr
    _check_or_init_cusparse()
    if __cusparseSpGEMM_createDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_createDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpGEMMDescr_t*) noexcept nogil>__cusparseSpGEMM_createDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpGEMM_destroyDescr(cusparseSpGEMMDescr_t descr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_destroyDescr
    _check_or_init_cusparse()
    if __cusparseSpGEMM_destroyDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_destroyDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpGEMMDescr_t) noexcept nogil>__cusparseSpGEMM_destroyDescr)(
        descr)


cdef cusparseStatus_t _cusparseSpGEMM_workEstimation(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, size_t* bufferSize1, void* externalBuffer1) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_workEstimation
    _check_or_init_cusparse()
    if __cusparseSpGEMM_workEstimation == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_workEstimation is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, size_t*, void*) noexcept nogil>__cusparseSpGEMM_workEstimation)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, spgemmDescr, bufferSize1, externalBuffer1)


cdef cusparseStatus_t _cusparseSpGEMM_getNumProducts(cusparseSpGEMMDescr_t spgemmDescr, int64_t* num_prods) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_getNumProducts
    _check_or_init_cusparse()
    if __cusparseSpGEMM_getNumProducts == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_getNumProducts is not found")
    return (<cusparseStatus_t (*)(cusparseSpGEMMDescr_t, int64_t*) noexcept nogil>__cusparseSpGEMM_getNumProducts)(
        spgemmDescr, num_prods)


cdef cusparseStatus_t _cusparseSpGEMM_estimateMemory(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, float chunk_fraction, size_t* bufferSize3, void* externalBuffer3, size_t* bufferSize2) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_estimateMemory
    _check_or_init_cusparse()
    if __cusparseSpGEMM_estimateMemory == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_estimateMemory is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, float, size_t*, void*, size_t*) noexcept nogil>__cusparseSpGEMM_estimateMemory)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, spgemmDescr, chunk_fraction, bufferSize3, externalBuffer3, bufferSize2)


cdef cusparseStatus_t _cusparseSpGEMM_compute(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, size_t* bufferSize2, void* externalBuffer2) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_compute
    _check_or_init_cusparse()
    if __cusparseSpGEMM_compute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_compute is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, size_t*, void*) noexcept nogil>__cusparseSpGEMM_compute)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, spgemmDescr, bufferSize2, externalBuffer2)


cdef cusparseStatus_t _cusparseSpGEMM_copy(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMM_copy
    _check_or_init_cusparse()
    if __cusparseSpGEMM_copy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMM_copy is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t) noexcept nogil>__cusparseSpGEMM_copy)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, spgemmDescr)


cdef cusparseStatus_t _cusparseSpGEMMreuse_workEstimation(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, cusparseSpMatDescr_t matC, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, size_t* bufferSize1, void* externalBuffer1) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMMreuse_workEstimation
    _check_or_init_cusparse()
    if __cusparseSpGEMMreuse_workEstimation == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMMreuse_workEstimation is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, cusparseSpMatDescr_t, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, size_t*, void*) noexcept nogil>__cusparseSpGEMMreuse_workEstimation)(
        handle, opA, opB, matA, matB, matC, alg, spgemmDescr, bufferSize1, externalBuffer1)


cdef cusparseStatus_t _cusparseSpGEMMreuse_nnz(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, cusparseSpMatDescr_t matC, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, size_t* bufferSize2, void* externalBuffer2, size_t* bufferSize3, void* externalBuffer3, size_t* bufferSize4, void* externalBuffer4) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMMreuse_nnz
    _check_or_init_cusparse()
    if __cusparseSpGEMMreuse_nnz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMMreuse_nnz is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, cusparseSpMatDescr_t, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, size_t*, void*, size_t*, void*, size_t*, void*) noexcept nogil>__cusparseSpGEMMreuse_nnz)(
        handle, opA, opB, matA, matB, matC, alg, spgemmDescr, bufferSize2, externalBuffer2, bufferSize3, externalBuffer3, bufferSize4, externalBuffer4)


cdef cusparseStatus_t _cusparseSpGEMMreuse_copy(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, cusparseSpMatDescr_t matC, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr, size_t* bufferSize5, void* externalBuffer5) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMMreuse_copy
    _check_or_init_cusparse()
    if __cusparseSpGEMMreuse_copy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMMreuse_copy is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, cusparseSpMatDescr_t, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t, size_t*, void*) noexcept nogil>__cusparseSpGEMMreuse_copy)(
        handle, opA, opB, matA, matB, matC, alg, spgemmDescr, bufferSize5, externalBuffer5)


cdef cusparseStatus_t _cusparseSpGEMMreuse_compute(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstSpMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSpGEMMAlg_t alg, cusparseSpGEMMDescr_t spgemmDescr) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpGEMMreuse_compute
    _check_or_init_cusparse()
    if __cusparseSpGEMMreuse_compute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpGEMMreuse_compute is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstSpMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSpGEMMAlg_t, cusparseSpGEMMDescr_t) noexcept nogil>__cusparseSpGEMMreuse_compute)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, spgemmDescr)


cdef cusparseStatus_t _cusparseSDDMM_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstDnMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSDDMMAlg_t alg, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSDDMM_bufferSize
    _check_or_init_cusparse()
    if __cusparseSDDMM_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSDDMM_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstDnMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSDDMMAlg_t, size_t*) noexcept nogil>__cusparseSDDMM_bufferSize)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, bufferSize)


cdef cusparseStatus_t _cusparseSDDMM_preprocess(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstDnMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSDDMMAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSDDMM_preprocess
    _check_or_init_cusparse()
    if __cusparseSDDMM_preprocess == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSDDMM_preprocess is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstDnMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSDDMMAlg_t, void*) noexcept nogil>__cusparseSDDMM_preprocess)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSDDMM(cusparseHandle_t handle, cusparseOperation_t opA, cusparseOperation_t opB, const void* alpha, cusparseConstDnMatDescr_t matA, cusparseConstDnMatDescr_t matB, const void* beta, cusparseSpMatDescr_t matC, cudaDataType computeType, cusparseSDDMMAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSDDMM
    _check_or_init_cusparse()
    if __cusparseSDDMM == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSDDMM is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseOperation_t, const void*, cusparseConstDnMatDescr_t, cusparseConstDnMatDescr_t, const void*, cusparseSpMatDescr_t, cudaDataType, cusparseSDDMMAlg_t, void*) noexcept nogil>__cusparseSDDMM)(
        handle, opA, opB, alpha, matA, matB, beta, matC, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpMMOp_createPlan(cusparseHandle_t handle, cusparseSpMMOpPlan_t* plan, cusparseOperation_t opA, cusparseOperation_t opB, cusparseConstSpMatDescr_t matA, cusparseConstDnMatDescr_t matB, cusparseDnMatDescr_t matC, cudaDataType computeType, cusparseSpMMOpAlg_t alg, const void* addOperationLtoirBuffer, size_t addOperationBufferSize, const void* mulOperationLtoirBuffer, size_t mulOperationBufferSize, const void* epilogueLtoirBuffer, size_t epilogueBufferSize, size_t* SpMMWorkspaceSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMMOp_createPlan
    _check_or_init_cusparse()
    if __cusparseSpMMOp_createPlan == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMMOp_createPlan is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpMMOpPlan_t*, cusparseOperation_t, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstDnMatDescr_t, cusparseDnMatDescr_t, cudaDataType, cusparseSpMMOpAlg_t, const void*, size_t, const void*, size_t, const void*, size_t, size_t*) noexcept nogil>__cusparseSpMMOp_createPlan)(
        handle, plan, opA, opB, matA, matB, matC, computeType, alg, addOperationLtoirBuffer, addOperationBufferSize, mulOperationLtoirBuffer, mulOperationBufferSize, epilogueLtoirBuffer, epilogueBufferSize, SpMMWorkspaceSize)


cdef cusparseStatus_t _cusparseSpMMOp(cusparseSpMMOpPlan_t plan, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMMOp
    _check_or_init_cusparse()
    if __cusparseSpMMOp == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMMOp is not found")
    return (<cusparseStatus_t (*)(cusparseSpMMOpPlan_t, void*) noexcept nogil>__cusparseSpMMOp)(
        plan, externalBuffer)


cdef cusparseStatus_t _cusparseSpMMOp_destroyPlan(cusparseSpMMOpPlan_t plan) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMMOp_destroyPlan
    _check_or_init_cusparse()
    if __cusparseSpMMOp_destroyPlan == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMMOp_destroyPlan is not found")
    return (<cusparseStatus_t (*)(cusparseSpMMOpPlan_t) noexcept nogil>__cusparseSpMMOp_destroyPlan)(
        plan)


cdef cusparseStatus_t _cusparseBsrSetStridedBatch(cusparseSpMatDescr_t spMatDescr, int batchCount, int64_t offsetsBatchStride, int64_t columnsBatchStride, int64_t ValuesBatchStride) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseBsrSetStridedBatch
    _check_or_init_cusparse()
    if __cusparseBsrSetStridedBatch == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseBsrSetStridedBatch is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t, int, int64_t, int64_t, int64_t) noexcept nogil>__cusparseBsrSetStridedBatch)(
        spMatDescr, batchCount, offsetsBatchStride, columnsBatchStride, ValuesBatchStride)


cdef cusparseStatus_t _cusparseCreateBsr(cusparseSpMatDescr_t* spMatDescr, int64_t brows, int64_t bcols, int64_t bnnz, int64_t rowBlockSize, int64_t colBlockSize, void* bsrRowOffsets, void* bsrColInd, void* bsrValues, cusparseIndexType_t bsrRowOffsetsType, cusparseIndexType_t bsrColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType, cusparseOrder_t order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateBsr
    _check_or_init_cusparse()
    if __cusparseCreateBsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateBsr is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, int64_t, void*, void*, void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType, cusparseOrder_t) noexcept nogil>__cusparseCreateBsr)(
        spMatDescr, brows, bcols, bnnz, rowBlockSize, colBlockSize, bsrRowOffsets, bsrColInd, bsrValues, bsrRowOffsetsType, bsrColIndType, idxBase, valueType, order)


cdef cusparseStatus_t _cusparseCreateConstBsr(cusparseConstSpMatDescr_t* spMatDescr, int64_t brows, int64_t bcols, int64_t bnnz, int64_t rowBlockDim, int64_t colBlockDim, const void* bsrRowOffsets, const void* bsrColInd, const void* bsrValues, cusparseIndexType_t bsrRowOffsetsType, cusparseIndexType_t bsrColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType, cusparseOrder_t order) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstBsr
    _check_or_init_cusparse()
    if __cusparseCreateConstBsr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstBsr is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, int64_t, const void*, const void*, const void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType, cusparseOrder_t) noexcept nogil>__cusparseCreateConstBsr)(
        spMatDescr, brows, bcols, bnnz, rowBlockDim, colBlockDim, bsrRowOffsets, bsrColInd, bsrValues, bsrRowOffsetsType, bsrColIndType, idxBase, valueType, order)


cdef cusparseStatus_t _cusparseCreateSlicedEll(cusparseSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, int64_t sellValuesSize, int64_t sliceSize, void* sellSliceOffsets, void* sellColInd, void* sellValues, cusparseIndexType_t sellSliceOffsetsType, cusparseIndexType_t sellColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateSlicedEll
    _check_or_init_cusparse()
    if __cusparseCreateSlicedEll == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateSlicedEll is not found")
    return (<cusparseStatus_t (*)(cusparseSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, int64_t, void*, void*, void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateSlicedEll)(
        spMatDescr, rows, cols, nnz, sellValuesSize, sliceSize, sellSliceOffsets, sellColInd, sellValues, sellSliceOffsetsType, sellColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseCreateConstSlicedEll(cusparseConstSpMatDescr_t* spMatDescr, int64_t rows, int64_t cols, int64_t nnz, int64_t sellValuesSize, int64_t sliceSize, const void* sellSliceOffsets, const void* sellColInd, const void* sellValues, cusparseIndexType_t sellSliceOffsetsType, cusparseIndexType_t sellColIndType, cusparseIndexBase_t idxBase, cudaDataType valueType) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseCreateConstSlicedEll
    _check_or_init_cusparse()
    if __cusparseCreateConstSlicedEll == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseCreateConstSlicedEll is not found")
    return (<cusparseStatus_t (*)(cusparseConstSpMatDescr_t*, int64_t, int64_t, int64_t, int64_t, int64_t, const void*, const void*, const void*, cusparseIndexType_t, cusparseIndexType_t, cusparseIndexBase_t, cudaDataType) noexcept nogil>__cusparseCreateConstSlicedEll)(
        spMatDescr, rows, cols, nnz, sellValuesSize, sliceSize, sellSliceOffsets, sellColInd, sellValues, sellSliceOffsetsType, sellColIndType, idxBase, valueType)


cdef cusparseStatus_t _cusparseSpSV_updateMatrix(cusparseHandle_t handle, cusparseSpSVDescr_t spsvDescr, void* newValues, cusparseSpSVUpdate_t updatePart) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSV_updateMatrix
    _check_or_init_cusparse()
    if __cusparseSpSV_updateMatrix == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSV_updateMatrix is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpSVDescr_t, void*, cusparseSpSVUpdate_t) noexcept nogil>__cusparseSpSV_updateMatrix)(
        handle, spsvDescr, newValues, updatePart)


cdef cusparseStatus_t _cusparseSpMV_preprocess(cusparseHandle_t handle, cusparseOperation_t opA, const void* alpha, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, const void* beta, cusparseDnVecDescr_t vecY, cudaDataType computeType, cusparseSpMVAlg_t alg, void* externalBuffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMV_preprocess
    _check_or_init_cusparse()
    if __cusparseSpMV_preprocess == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMV_preprocess is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, const void*, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, const void*, cusparseDnVecDescr_t, cudaDataType, cusparseSpMVAlg_t, void*) noexcept nogil>__cusparseSpMV_preprocess)(
        handle, opA, alpha, matA, vecX, beta, vecY, computeType, alg, externalBuffer)


cdef cusparseStatus_t _cusparseSpSM_updateMatrix(cusparseHandle_t handle, cusparseSpSMDescr_t spsmDescr, void* newValues, cusparseSpSMUpdate_t updatePart) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpSM_updateMatrix
    _check_or_init_cusparse()
    if __cusparseSpSM_updateMatrix == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpSM_updateMatrix is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpSMDescr_t, void*, cusparseSpSMUpdate_t) noexcept nogil>__cusparseSpSM_updateMatrix)(
        handle, spsmDescr, newValues, updatePart)


cdef cusparseStatus_t _cusparseSpMVOp_createDescr(cusparseHandle_t handle, cusparseSpMVOpDescr_t* desc, cusparseOperation_t opA, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, cusparseDnVecDescr_t vecY, cusparseDnVecDescr_t vecZ, cudaDataType computeType, void* buffer) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_createDescr
    _check_or_init_cusparse()
    if __cusparseSpMVOp_createDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_createDescr is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpMVOpDescr_t*, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t, cusparseDnVecDescr_t, cudaDataType, void*) noexcept nogil>__cusparseSpMVOp_createDescr)(
        handle, desc, opA, matA, vecX, vecY, vecZ, computeType, buffer)


cdef cusparseStatus_t _cusparseSpMVOp_destroyDescr(cusparseSpMVOpDescr_t desc) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_destroyDescr
    _check_or_init_cusparse()
    if __cusparseSpMVOp_destroyDescr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_destroyDescr is not found")
    return (<cusparseStatus_t (*)(cusparseSpMVOpDescr_t) noexcept nogil>__cusparseSpMVOp_destroyDescr)(
        desc)


cdef cusparseStatus_t _cusparseSpMVOp_createPlan(cusparseHandle_t handle, cusparseSpMVOpDescr_t desc, cusparseSpMVOpPlan_t* plan, const void* code, size_t codeSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_createPlan
    _check_or_init_cusparse()
    if __cusparseSpMVOp_createPlan == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_createPlan is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpMVOpDescr_t, cusparseSpMVOpPlan_t*, const void*, size_t) noexcept nogil>__cusparseSpMVOp_createPlan)(
        handle, desc, plan, code, codeSize)


cdef cusparseStatus_t _cusparseSpMVOp_destroyPlan(cusparseSpMVOpPlan_t plan) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_destroyPlan
    _check_or_init_cusparse()
    if __cusparseSpMVOp_destroyPlan == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_destroyPlan is not found")
    return (<cusparseStatus_t (*)(cusparseSpMVOpPlan_t) noexcept nogil>__cusparseSpMVOp_destroyPlan)(
        plan)


cdef cusparseStatus_t _cusparseSpMVOp_setGlobalUserData(cusparseHandle_t handle, cusparseSpMVOpPlan_t plan, const char* global_data_name, void* input_data, size_t data_size) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_setGlobalUserData
    _check_or_init_cusparse()
    if __cusparseSpMVOp_setGlobalUserData == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_setGlobalUserData is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpMVOpPlan_t, const char*, void*, size_t) noexcept nogil>__cusparseSpMVOp_setGlobalUserData)(
        handle, plan, global_data_name, input_data, data_size)


cdef cusparseStatus_t _cusparseSpMVOp(cusparseHandle_t handle, cusparseSpMVOpPlan_t plan, const void* alpha, const void* beta, cusparseConstDnVecDescr_t vecX, cusparseConstDnVecDescr_t vecY, cusparseDnVecDescr_t vecZ) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp
    _check_or_init_cusparse()
    if __cusparseSpMVOp == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseSpMVOpPlan_t, const void*, const void*, cusparseConstDnVecDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t) noexcept nogil>__cusparseSpMVOp)(
        handle, plan, alpha, beta, vecX, vecY, vecZ)


cdef cusparseStatus_t _cusparseSpMVOp_bufferSize(cusparseHandle_t handle, cusparseOperation_t opA, cusparseConstSpMatDescr_t matA, cusparseConstDnVecDescr_t vecX, cusparseDnVecDescr_t vecY, cusparseDnVecDescr_t vecZ, cudaDataType computeType, size_t* bufferSize) except?_CUSPARSESTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusparseSpMVOp_bufferSize
    _check_or_init_cusparse()
    if __cusparseSpMVOp_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusparseSpMVOp_bufferSize is not found")
    return (<cusparseStatus_t (*)(cusparseHandle_t, cusparseOperation_t, cusparseConstSpMatDescr_t, cusparseConstDnVecDescr_t, cusparseDnVecDescr_t, cusparseDnVecDescr_t, cudaDataType, size_t*) noexcept nogil>__cusparseSpMVOp_bufferSize)(
        handle, opA, matA, vecX, vecY, vecZ, computeType, bufferSize)
