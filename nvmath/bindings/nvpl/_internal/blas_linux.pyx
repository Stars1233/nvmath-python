# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 25.5 to 26.5, generator version 0.3.1.dev1725+ge72d09d68.d20260601. Do not modify it directly.

import os

cimport cython
from libc.stdint cimport intptr_t

from ..._internal.utils import FunctionNotFoundError, NotSupportedError

import threading

###############################################################################
# Extern
###############################################################################

cdef extern from "<dlfcn.h>" nogil:
    void* dlopen(const char*, int)
    char* dlerror()
    void* dlsym(void*, const char*)
    int dlclose(void*)

    enum:
        RTLD_LAZY
        RTLD_NOW
        RTLD_GLOBAL
        RTLD_LOCAL

    const void* RTLD_DEFAULT 'RTLD_DEFAULT'


###############################################################################
# Wrapper init
###############################################################################

cdef object __symbol_lock = threading.Lock()
cdef bint __py_nvpl_blas_init = False
cdef str __current_so_name = ""
# From MKL 2026.0.0 onward, only libmkl_rt.so.3 is shipped; keep libmkl_rt.so.2 in the probe order for older installs.
# NVPL>=26.5, MKL provide both ILP64 and LP64 APIs through these artifacts. For openBLAS, it's probably only LP64.
# Use libnvpl_blas_lp64_gomp.so.0 so that LP64 symbols are LP64 and ILP64 symbols are true ILP64.
# https://docs.nvidia.com/nvpl/latest/blas/programming_model/building_and_linking.html#ilp64-64-suffix-symbols
cdef tuple __lib_so_names = ("libnvpl_blas_lp64_gomp.so.0", "libmkl_rt.so.3", "libmkl_rt.so.2",  "libopenblas.so.0",)


cdef void* __MKL_Set_Num_Threads_Local = NULL
cdef void* __MKL_Set_Num_Threads = NULL
cdef void* __openblas_set_num_threads = NULL
cdef void* __openblas_set_num_threads_local = NULL
cdef void* __nvpl_blas_get_version = NULL
cdef void* __nvpl_blas_get_max_threads = NULL
cdef void* __nvpl_blas_set_num_threads = NULL
cdef void* __nvpl_blas_set_num_threads_local = NULL
cdef void* __cblas_sgemv = NULL
cdef void* __cblas_sgbmv = NULL
cdef void* __cblas_strmv = NULL
cdef void* __cblas_stbmv = NULL
cdef void* __cblas_stpmv = NULL
cdef void* __cblas_strsv = NULL
cdef void* __cblas_stbsv = NULL
cdef void* __cblas_stpsv = NULL
cdef void* __cblas_dgemv = NULL
cdef void* __cblas_dgbmv = NULL
cdef void* __cblas_dtrmv = NULL
cdef void* __cblas_dtbmv = NULL
cdef void* __cblas_dtpmv = NULL
cdef void* __cblas_dtrsv = NULL
cdef void* __cblas_dtbsv = NULL
cdef void* __cblas_dtpsv = NULL
cdef void* __cblas_cgemv = NULL
cdef void* __cblas_cgbmv = NULL
cdef void* __cblas_ctrmv = NULL
cdef void* __cblas_ctbmv = NULL
cdef void* __cblas_ctpmv = NULL
cdef void* __cblas_ctrsv = NULL
cdef void* __cblas_ctbsv = NULL
cdef void* __cblas_ctpsv = NULL
cdef void* __cblas_zgemv = NULL
cdef void* __cblas_zgbmv = NULL
cdef void* __cblas_ztrmv = NULL
cdef void* __cblas_ztbmv = NULL
cdef void* __cblas_ztpmv = NULL
cdef void* __cblas_ztrsv = NULL
cdef void* __cblas_ztbsv = NULL
cdef void* __cblas_ztpsv = NULL
cdef void* __cblas_ssymv = NULL
cdef void* __cblas_ssbmv = NULL
cdef void* __cblas_sspmv = NULL
cdef void* __cblas_sger = NULL
cdef void* __cblas_ssyr = NULL
cdef void* __cblas_sspr = NULL
cdef void* __cblas_ssyr2 = NULL
cdef void* __cblas_sspr2 = NULL
cdef void* __cblas_dsymv = NULL
cdef void* __cblas_dsbmv = NULL
cdef void* __cblas_dspmv = NULL
cdef void* __cblas_dger = NULL
cdef void* __cblas_dsyr = NULL
cdef void* __cblas_dspr = NULL
cdef void* __cblas_dsyr2 = NULL
cdef void* __cblas_dspr2 = NULL
cdef void* __cblas_chemv = NULL
cdef void* __cblas_chbmv = NULL
cdef void* __cblas_chpmv = NULL
cdef void* __cblas_cgeru = NULL
cdef void* __cblas_cgerc = NULL
cdef void* __cblas_cher = NULL
cdef void* __cblas_chpr = NULL
cdef void* __cblas_cher2 = NULL
cdef void* __cblas_chpr2 = NULL
cdef void* __cblas_zhemv = NULL
cdef void* __cblas_zhbmv = NULL
cdef void* __cblas_zhpmv = NULL
cdef void* __cblas_zgeru = NULL
cdef void* __cblas_zgerc = NULL
cdef void* __cblas_zher = NULL
cdef void* __cblas_zhpr = NULL
cdef void* __cblas_zher2 = NULL
cdef void* __cblas_zhpr2 = NULL
cdef void* __cblas_sgemm = NULL
cdef void* __cblas_ssymm = NULL
cdef void* __cblas_ssyrk = NULL
cdef void* __cblas_ssyr2k = NULL
cdef void* __cblas_strmm = NULL
cdef void* __cblas_strsm = NULL
cdef void* __cblas_dgemm = NULL
cdef void* __cblas_dsymm = NULL
cdef void* __cblas_dsyrk = NULL
cdef void* __cblas_dsyr2k = NULL
cdef void* __cblas_dtrmm = NULL
cdef void* __cblas_dtrsm = NULL
cdef void* __cblas_cgemm = NULL
cdef void* __cblas_csymm = NULL
cdef void* __cblas_csyrk = NULL
cdef void* __cblas_csyr2k = NULL
cdef void* __cblas_ctrmm = NULL
cdef void* __cblas_ctrsm = NULL
cdef void* __cblas_zgemm = NULL
cdef void* __cblas_zsymm = NULL
cdef void* __cblas_zsyrk = NULL
cdef void* __cblas_zsyr2k = NULL
cdef void* __cblas_ztrmm = NULL
cdef void* __cblas_ztrsm = NULL
cdef void* __cblas_chemm = NULL
cdef void* __cblas_cherk = NULL
cdef void* __cblas_cher2k = NULL
cdef void* __cblas_zhemm = NULL
cdef void* __cblas_zherk = NULL
cdef void* __cblas_zher2k = NULL
cdef void* __cblas_sgemm_batch = NULL
cdef void* __cblas_dgemm_batch = NULL
cdef void* __cblas_cgemm_batch = NULL
cdef void* __cblas_zgemm_batch = NULL
cdef void* __cblas_sgemm_batch_strided = NULL
cdef void* __cblas_dgemm_batch_strided = NULL
cdef void* __cblas_cgemm_batch_strided = NULL
cdef void* __cblas_zgemm_batch_strided = NULL
cdef void* __cblas_sgemmt = NULL
cdef void* __cblas_dgemmt = NULL
cdef void* __cblas_cgemmt = NULL
cdef void* __cblas_zgemmt = NULL
cdef void* __cblas_sgemv_64 = NULL
cdef void* __cblas_sgbmv_64 = NULL
cdef void* __cblas_strmv_64 = NULL
cdef void* __cblas_stbmv_64 = NULL
cdef void* __cblas_stpmv_64 = NULL
cdef void* __cblas_strsv_64 = NULL
cdef void* __cblas_stbsv_64 = NULL
cdef void* __cblas_stpsv_64 = NULL
cdef void* __cblas_dgemv_64 = NULL
cdef void* __cblas_dgbmv_64 = NULL
cdef void* __cblas_dtrmv_64 = NULL
cdef void* __cblas_dtbmv_64 = NULL
cdef void* __cblas_dtpmv_64 = NULL
cdef void* __cblas_dtrsv_64 = NULL
cdef void* __cblas_dtbsv_64 = NULL
cdef void* __cblas_dtpsv_64 = NULL
cdef void* __cblas_cgemv_64 = NULL
cdef void* __cblas_cgbmv_64 = NULL
cdef void* __cblas_ctrmv_64 = NULL
cdef void* __cblas_ctbmv_64 = NULL
cdef void* __cblas_ctpmv_64 = NULL
cdef void* __cblas_ctrsv_64 = NULL
cdef void* __cblas_ctbsv_64 = NULL
cdef void* __cblas_ctpsv_64 = NULL
cdef void* __cblas_zgemv_64 = NULL
cdef void* __cblas_zgbmv_64 = NULL
cdef void* __cblas_ztrmv_64 = NULL
cdef void* __cblas_ztbmv_64 = NULL
cdef void* __cblas_ztpmv_64 = NULL
cdef void* __cblas_ztrsv_64 = NULL
cdef void* __cblas_ztbsv_64 = NULL
cdef void* __cblas_ztpsv_64 = NULL
cdef void* __cblas_ssymv_64 = NULL
cdef void* __cblas_ssbmv_64 = NULL
cdef void* __cblas_sspmv_64 = NULL
cdef void* __cblas_sger_64 = NULL
cdef void* __cblas_ssyr_64 = NULL
cdef void* __cblas_sspr_64 = NULL
cdef void* __cblas_ssyr2_64 = NULL
cdef void* __cblas_sspr2_64 = NULL
cdef void* __cblas_dsymv_64 = NULL
cdef void* __cblas_dsbmv_64 = NULL
cdef void* __cblas_dspmv_64 = NULL
cdef void* __cblas_dger_64 = NULL
cdef void* __cblas_dsyr_64 = NULL
cdef void* __cblas_dspr_64 = NULL
cdef void* __cblas_dsyr2_64 = NULL
cdef void* __cblas_dspr2_64 = NULL
cdef void* __cblas_chemv_64 = NULL
cdef void* __cblas_chbmv_64 = NULL
cdef void* __cblas_chpmv_64 = NULL
cdef void* __cblas_cgeru_64 = NULL
cdef void* __cblas_cgerc_64 = NULL
cdef void* __cblas_cher_64 = NULL
cdef void* __cblas_chpr_64 = NULL
cdef void* __cblas_cher2_64 = NULL
cdef void* __cblas_chpr2_64 = NULL
cdef void* __cblas_zhemv_64 = NULL
cdef void* __cblas_zhbmv_64 = NULL
cdef void* __cblas_zhpmv_64 = NULL
cdef void* __cblas_zgeru_64 = NULL
cdef void* __cblas_zgerc_64 = NULL
cdef void* __cblas_zher_64 = NULL
cdef void* __cblas_zhpr_64 = NULL
cdef void* __cblas_zher2_64 = NULL
cdef void* __cblas_zhpr2_64 = NULL
cdef void* __cblas_sgemm_64 = NULL
cdef void* __cblas_ssymm_64 = NULL
cdef void* __cblas_ssyrk_64 = NULL
cdef void* __cblas_ssyr2k_64 = NULL
cdef void* __cblas_strmm_64 = NULL
cdef void* __cblas_strsm_64 = NULL
cdef void* __cblas_dgemm_64 = NULL
cdef void* __cblas_dsymm_64 = NULL
cdef void* __cblas_dsyrk_64 = NULL
cdef void* __cblas_dsyr2k_64 = NULL
cdef void* __cblas_dtrmm_64 = NULL
cdef void* __cblas_dtrsm_64 = NULL
cdef void* __cblas_cgemm_64 = NULL
cdef void* __cblas_csymm_64 = NULL
cdef void* __cblas_csyrk_64 = NULL
cdef void* __cblas_csyr2k_64 = NULL
cdef void* __cblas_ctrmm_64 = NULL
cdef void* __cblas_ctrsm_64 = NULL
cdef void* __cblas_zgemm_64 = NULL
cdef void* __cblas_zsymm_64 = NULL
cdef void* __cblas_zsyrk_64 = NULL
cdef void* __cblas_zsyr2k_64 = NULL
cdef void* __cblas_ztrmm_64 = NULL
cdef void* __cblas_ztrsm_64 = NULL
cdef void* __cblas_chemm_64 = NULL
cdef void* __cblas_cherk_64 = NULL
cdef void* __cblas_cher2k_64 = NULL
cdef void* __cblas_zhemm_64 = NULL
cdef void* __cblas_zherk_64 = NULL
cdef void* __cblas_zher2k_64 = NULL
cdef void* __cblas_sgemmt_64 = NULL
cdef void* __cblas_dgemmt_64 = NULL
cdef void* __cblas_cgemmt_64 = NULL
cdef void* __cblas_zgemmt_64 = NULL
cdef void* __cblas_sgemm_batch_64 = NULL
cdef void* __cblas_dgemm_batch_64 = NULL
cdef void* __cblas_cgemm_batch_64 = NULL
cdef void* __cblas_zgemm_batch_64 = NULL
cdef void* __cblas_sgemm_batch_strided_64 = NULL
cdef void* __cblas_dgemm_batch_strided_64 = NULL
cdef void* __cblas_cgemm_batch_strided_64 = NULL
cdef void* __cblas_zgemm_batch_strided_64 = NULL


cdef void* load_library() except* with gil:
    cdef void* handle
    cdef str all_err_msg = ""
    cdef str env_lib_so_name = os.getenv("NVMATH_BLAS_CPU_LIBRARY", "")

    if env_lib_so_name != "":
        handle = dlopen(env_lib_so_name.encode(), RTLD_NOW | RTLD_GLOBAL)
        if handle != NULL:
            global __current_so_name
            __current_so_name = env_lib_so_name
            return handle
        else:
            error_msg = dlerror()
        raise RuntimeError(
            f"Failed to dlopen NVMATH_BLAS_CPU_LIBRARY={env_lib_so_name}. "
            f"Please check that NVMATH_BLAS_CPU_LIBRARY is the name of a lib on the LD_LIBRARY_PATH. {error_msg.decode()}"
        )

    if len(__lib_so_names) == 0:
        raise RuntimeError("Cannot load BLAS-compatible library. No lib names were specified.")
    for so_name in __lib_so_names:
        handle = dlopen(so_name.encode(), RTLD_NOW | RTLD_GLOBAL)
        if handle != NULL:
            global __current_so_name
            __current_so_name = so_name
            return handle
        else:
            error_msg = dlerror()
            all_err_msg += f"\n{error_msg.decode()}"
    else:
        all_libs = ", ".join(__lib_so_names)
        raise RuntimeError(
            f"Failed to dlopen all of the following libraries: {all_libs}. "
            "Install/add one of these libraries to LD_LIBRARY_PATH or"
            f"use environment variable NVMATH_BLAS_CPU_LIBRARY to name a lib on the LD_LIBRARY_PATH. {all_err_msg}"
        )
    return handle


cdef int _check_or_init_nvpl_blas() except -1 nogil:
    global __py_nvpl_blas_init
    if __py_nvpl_blas_init:
        return 0

    cdef void* handle = NULL

    with gil, __symbol_lock:
        # Recheck the flag after obtaining the locks
        if __py_nvpl_blas_init:
            return 0

        # Load function
        global __MKL_Set_Num_Threads_Local
        __MKL_Set_Num_Threads_Local = dlsym(RTLD_DEFAULT, 'MKL_Set_Num_Threads_Local')
        if __MKL_Set_Num_Threads_Local == NULL:
            if handle == NULL:
                handle = load_library()
            __MKL_Set_Num_Threads_Local = dlsym(handle, 'MKL_Set_Num_Threads_Local')

        global __MKL_Set_Num_Threads
        __MKL_Set_Num_Threads = dlsym(RTLD_DEFAULT, 'MKL_Set_Num_Threads')
        if __MKL_Set_Num_Threads == NULL:
            if handle == NULL:
                handle = load_library()
            __MKL_Set_Num_Threads = dlsym(handle, 'MKL_Set_Num_Threads')

        global __openblas_set_num_threads
        __openblas_set_num_threads = dlsym(RTLD_DEFAULT, 'openblas_set_num_threads')
        if __openblas_set_num_threads == NULL:
            if handle == NULL:
                handle = load_library()
            __openblas_set_num_threads = dlsym(handle, 'openblas_set_num_threads')

        global __openblas_set_num_threads_local
        __openblas_set_num_threads_local = dlsym(RTLD_DEFAULT, 'openblas_set_num_threads_local')
        if __openblas_set_num_threads_local == NULL:
            if handle == NULL:
                handle = load_library()
            __openblas_set_num_threads_local = dlsym(handle, 'openblas_set_num_threads_local')

        global __nvpl_blas_get_version
        __nvpl_blas_get_version = dlsym(RTLD_DEFAULT, 'nvpl_blas_get_version')
        if __nvpl_blas_get_version == NULL:
            if handle == NULL:
                handle = load_library()
            __nvpl_blas_get_version = dlsym(handle, 'nvpl_blas_get_version')

        global __nvpl_blas_get_max_threads
        __nvpl_blas_get_max_threads = dlsym(RTLD_DEFAULT, 'nvpl_blas_get_max_threads')
        if __nvpl_blas_get_max_threads == NULL:
            if handle == NULL:
                handle = load_library()
            __nvpl_blas_get_max_threads = dlsym(handle, 'nvpl_blas_get_max_threads')

        global __nvpl_blas_set_num_threads
        __nvpl_blas_set_num_threads = dlsym(RTLD_DEFAULT, 'nvpl_blas_set_num_threads')
        if __nvpl_blas_set_num_threads == NULL:
            if handle == NULL:
                handle = load_library()
            __nvpl_blas_set_num_threads = dlsym(handle, 'nvpl_blas_set_num_threads')

        global __nvpl_blas_set_num_threads_local
        __nvpl_blas_set_num_threads_local = dlsym(RTLD_DEFAULT, 'nvpl_blas_set_num_threads_local')
        if __nvpl_blas_set_num_threads_local == NULL:
            if handle == NULL:
                handle = load_library()
            __nvpl_blas_set_num_threads_local = dlsym(handle, 'nvpl_blas_set_num_threads_local')

        global __cblas_sgemv
        __cblas_sgemv = dlsym(RTLD_DEFAULT, 'cblas_sgemv')
        if __cblas_sgemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemv = dlsym(handle, 'cblas_sgemv')

        global __cblas_sgbmv
        __cblas_sgbmv = dlsym(RTLD_DEFAULT, 'cblas_sgbmv')
        if __cblas_sgbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgbmv = dlsym(handle, 'cblas_sgbmv')

        global __cblas_strmv
        __cblas_strmv = dlsym(RTLD_DEFAULT, 'cblas_strmv')
        if __cblas_strmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strmv = dlsym(handle, 'cblas_strmv')

        global __cblas_stbmv
        __cblas_stbmv = dlsym(RTLD_DEFAULT, 'cblas_stbmv')
        if __cblas_stbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stbmv = dlsym(handle, 'cblas_stbmv')

        global __cblas_stpmv
        __cblas_stpmv = dlsym(RTLD_DEFAULT, 'cblas_stpmv')
        if __cblas_stpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stpmv = dlsym(handle, 'cblas_stpmv')

        global __cblas_strsv
        __cblas_strsv = dlsym(RTLD_DEFAULT, 'cblas_strsv')
        if __cblas_strsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strsv = dlsym(handle, 'cblas_strsv')

        global __cblas_stbsv
        __cblas_stbsv = dlsym(RTLD_DEFAULT, 'cblas_stbsv')
        if __cblas_stbsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stbsv = dlsym(handle, 'cblas_stbsv')

        global __cblas_stpsv
        __cblas_stpsv = dlsym(RTLD_DEFAULT, 'cblas_stpsv')
        if __cblas_stpsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stpsv = dlsym(handle, 'cblas_stpsv')

        global __cblas_dgemv
        __cblas_dgemv = dlsym(RTLD_DEFAULT, 'cblas_dgemv')
        if __cblas_dgemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemv = dlsym(handle, 'cblas_dgemv')

        global __cblas_dgbmv
        __cblas_dgbmv = dlsym(RTLD_DEFAULT, 'cblas_dgbmv')
        if __cblas_dgbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgbmv = dlsym(handle, 'cblas_dgbmv')

        global __cblas_dtrmv
        __cblas_dtrmv = dlsym(RTLD_DEFAULT, 'cblas_dtrmv')
        if __cblas_dtrmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrmv = dlsym(handle, 'cblas_dtrmv')

        global __cblas_dtbmv
        __cblas_dtbmv = dlsym(RTLD_DEFAULT, 'cblas_dtbmv')
        if __cblas_dtbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtbmv = dlsym(handle, 'cblas_dtbmv')

        global __cblas_dtpmv
        __cblas_dtpmv = dlsym(RTLD_DEFAULT, 'cblas_dtpmv')
        if __cblas_dtpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtpmv = dlsym(handle, 'cblas_dtpmv')

        global __cblas_dtrsv
        __cblas_dtrsv = dlsym(RTLD_DEFAULT, 'cblas_dtrsv')
        if __cblas_dtrsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrsv = dlsym(handle, 'cblas_dtrsv')

        global __cblas_dtbsv
        __cblas_dtbsv = dlsym(RTLD_DEFAULT, 'cblas_dtbsv')
        if __cblas_dtbsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtbsv = dlsym(handle, 'cblas_dtbsv')

        global __cblas_dtpsv
        __cblas_dtpsv = dlsym(RTLD_DEFAULT, 'cblas_dtpsv')
        if __cblas_dtpsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtpsv = dlsym(handle, 'cblas_dtpsv')

        global __cblas_cgemv
        __cblas_cgemv = dlsym(RTLD_DEFAULT, 'cblas_cgemv')
        if __cblas_cgemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemv = dlsym(handle, 'cblas_cgemv')

        global __cblas_cgbmv
        __cblas_cgbmv = dlsym(RTLD_DEFAULT, 'cblas_cgbmv')
        if __cblas_cgbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgbmv = dlsym(handle, 'cblas_cgbmv')

        global __cblas_ctrmv
        __cblas_ctrmv = dlsym(RTLD_DEFAULT, 'cblas_ctrmv')
        if __cblas_ctrmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrmv = dlsym(handle, 'cblas_ctrmv')

        global __cblas_ctbmv
        __cblas_ctbmv = dlsym(RTLD_DEFAULT, 'cblas_ctbmv')
        if __cblas_ctbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctbmv = dlsym(handle, 'cblas_ctbmv')

        global __cblas_ctpmv
        __cblas_ctpmv = dlsym(RTLD_DEFAULT, 'cblas_ctpmv')
        if __cblas_ctpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctpmv = dlsym(handle, 'cblas_ctpmv')

        global __cblas_ctrsv
        __cblas_ctrsv = dlsym(RTLD_DEFAULT, 'cblas_ctrsv')
        if __cblas_ctrsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrsv = dlsym(handle, 'cblas_ctrsv')

        global __cblas_ctbsv
        __cblas_ctbsv = dlsym(RTLD_DEFAULT, 'cblas_ctbsv')
        if __cblas_ctbsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctbsv = dlsym(handle, 'cblas_ctbsv')

        global __cblas_ctpsv
        __cblas_ctpsv = dlsym(RTLD_DEFAULT, 'cblas_ctpsv')
        if __cblas_ctpsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctpsv = dlsym(handle, 'cblas_ctpsv')

        global __cblas_zgemv
        __cblas_zgemv = dlsym(RTLD_DEFAULT, 'cblas_zgemv')
        if __cblas_zgemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemv = dlsym(handle, 'cblas_zgemv')

        global __cblas_zgbmv
        __cblas_zgbmv = dlsym(RTLD_DEFAULT, 'cblas_zgbmv')
        if __cblas_zgbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgbmv = dlsym(handle, 'cblas_zgbmv')

        global __cblas_ztrmv
        __cblas_ztrmv = dlsym(RTLD_DEFAULT, 'cblas_ztrmv')
        if __cblas_ztrmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrmv = dlsym(handle, 'cblas_ztrmv')

        global __cblas_ztbmv
        __cblas_ztbmv = dlsym(RTLD_DEFAULT, 'cblas_ztbmv')
        if __cblas_ztbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztbmv = dlsym(handle, 'cblas_ztbmv')

        global __cblas_ztpmv
        __cblas_ztpmv = dlsym(RTLD_DEFAULT, 'cblas_ztpmv')
        if __cblas_ztpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztpmv = dlsym(handle, 'cblas_ztpmv')

        global __cblas_ztrsv
        __cblas_ztrsv = dlsym(RTLD_DEFAULT, 'cblas_ztrsv')
        if __cblas_ztrsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrsv = dlsym(handle, 'cblas_ztrsv')

        global __cblas_ztbsv
        __cblas_ztbsv = dlsym(RTLD_DEFAULT, 'cblas_ztbsv')
        if __cblas_ztbsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztbsv = dlsym(handle, 'cblas_ztbsv')

        global __cblas_ztpsv
        __cblas_ztpsv = dlsym(RTLD_DEFAULT, 'cblas_ztpsv')
        if __cblas_ztpsv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztpsv = dlsym(handle, 'cblas_ztpsv')

        global __cblas_ssymv
        __cblas_ssymv = dlsym(RTLD_DEFAULT, 'cblas_ssymv')
        if __cblas_ssymv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssymv = dlsym(handle, 'cblas_ssymv')

        global __cblas_ssbmv
        __cblas_ssbmv = dlsym(RTLD_DEFAULT, 'cblas_ssbmv')
        if __cblas_ssbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssbmv = dlsym(handle, 'cblas_ssbmv')

        global __cblas_sspmv
        __cblas_sspmv = dlsym(RTLD_DEFAULT, 'cblas_sspmv')
        if __cblas_sspmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspmv = dlsym(handle, 'cblas_sspmv')

        global __cblas_sger
        __cblas_sger = dlsym(RTLD_DEFAULT, 'cblas_sger')
        if __cblas_sger == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sger = dlsym(handle, 'cblas_sger')

        global __cblas_ssyr
        __cblas_ssyr = dlsym(RTLD_DEFAULT, 'cblas_ssyr')
        if __cblas_ssyr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr = dlsym(handle, 'cblas_ssyr')

        global __cblas_sspr
        __cblas_sspr = dlsym(RTLD_DEFAULT, 'cblas_sspr')
        if __cblas_sspr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspr = dlsym(handle, 'cblas_sspr')

        global __cblas_ssyr2
        __cblas_ssyr2 = dlsym(RTLD_DEFAULT, 'cblas_ssyr2')
        if __cblas_ssyr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr2 = dlsym(handle, 'cblas_ssyr2')

        global __cblas_sspr2
        __cblas_sspr2 = dlsym(RTLD_DEFAULT, 'cblas_sspr2')
        if __cblas_sspr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspr2 = dlsym(handle, 'cblas_sspr2')

        global __cblas_dsymv
        __cblas_dsymv = dlsym(RTLD_DEFAULT, 'cblas_dsymv')
        if __cblas_dsymv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsymv = dlsym(handle, 'cblas_dsymv')

        global __cblas_dsbmv
        __cblas_dsbmv = dlsym(RTLD_DEFAULT, 'cblas_dsbmv')
        if __cblas_dsbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsbmv = dlsym(handle, 'cblas_dsbmv')

        global __cblas_dspmv
        __cblas_dspmv = dlsym(RTLD_DEFAULT, 'cblas_dspmv')
        if __cblas_dspmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspmv = dlsym(handle, 'cblas_dspmv')

        global __cblas_dger
        __cblas_dger = dlsym(RTLD_DEFAULT, 'cblas_dger')
        if __cblas_dger == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dger = dlsym(handle, 'cblas_dger')

        global __cblas_dsyr
        __cblas_dsyr = dlsym(RTLD_DEFAULT, 'cblas_dsyr')
        if __cblas_dsyr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr = dlsym(handle, 'cblas_dsyr')

        global __cblas_dspr
        __cblas_dspr = dlsym(RTLD_DEFAULT, 'cblas_dspr')
        if __cblas_dspr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspr = dlsym(handle, 'cblas_dspr')

        global __cblas_dsyr2
        __cblas_dsyr2 = dlsym(RTLD_DEFAULT, 'cblas_dsyr2')
        if __cblas_dsyr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr2 = dlsym(handle, 'cblas_dsyr2')

        global __cblas_dspr2
        __cblas_dspr2 = dlsym(RTLD_DEFAULT, 'cblas_dspr2')
        if __cblas_dspr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspr2 = dlsym(handle, 'cblas_dspr2')

        global __cblas_chemv
        __cblas_chemv = dlsym(RTLD_DEFAULT, 'cblas_chemv')
        if __cblas_chemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chemv = dlsym(handle, 'cblas_chemv')

        global __cblas_chbmv
        __cblas_chbmv = dlsym(RTLD_DEFAULT, 'cblas_chbmv')
        if __cblas_chbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chbmv = dlsym(handle, 'cblas_chbmv')

        global __cblas_chpmv
        __cblas_chpmv = dlsym(RTLD_DEFAULT, 'cblas_chpmv')
        if __cblas_chpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpmv = dlsym(handle, 'cblas_chpmv')

        global __cblas_cgeru
        __cblas_cgeru = dlsym(RTLD_DEFAULT, 'cblas_cgeru')
        if __cblas_cgeru == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgeru = dlsym(handle, 'cblas_cgeru')

        global __cblas_cgerc
        __cblas_cgerc = dlsym(RTLD_DEFAULT, 'cblas_cgerc')
        if __cblas_cgerc == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgerc = dlsym(handle, 'cblas_cgerc')

        global __cblas_cher
        __cblas_cher = dlsym(RTLD_DEFAULT, 'cblas_cher')
        if __cblas_cher == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher = dlsym(handle, 'cblas_cher')

        global __cblas_chpr
        __cblas_chpr = dlsym(RTLD_DEFAULT, 'cblas_chpr')
        if __cblas_chpr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpr = dlsym(handle, 'cblas_chpr')

        global __cblas_cher2
        __cblas_cher2 = dlsym(RTLD_DEFAULT, 'cblas_cher2')
        if __cblas_cher2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher2 = dlsym(handle, 'cblas_cher2')

        global __cblas_chpr2
        __cblas_chpr2 = dlsym(RTLD_DEFAULT, 'cblas_chpr2')
        if __cblas_chpr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpr2 = dlsym(handle, 'cblas_chpr2')

        global __cblas_zhemv
        __cblas_zhemv = dlsym(RTLD_DEFAULT, 'cblas_zhemv')
        if __cblas_zhemv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhemv = dlsym(handle, 'cblas_zhemv')

        global __cblas_zhbmv
        __cblas_zhbmv = dlsym(RTLD_DEFAULT, 'cblas_zhbmv')
        if __cblas_zhbmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhbmv = dlsym(handle, 'cblas_zhbmv')

        global __cblas_zhpmv
        __cblas_zhpmv = dlsym(RTLD_DEFAULT, 'cblas_zhpmv')
        if __cblas_zhpmv == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpmv = dlsym(handle, 'cblas_zhpmv')

        global __cblas_zgeru
        __cblas_zgeru = dlsym(RTLD_DEFAULT, 'cblas_zgeru')
        if __cblas_zgeru == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgeru = dlsym(handle, 'cblas_zgeru')

        global __cblas_zgerc
        __cblas_zgerc = dlsym(RTLD_DEFAULT, 'cblas_zgerc')
        if __cblas_zgerc == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgerc = dlsym(handle, 'cblas_zgerc')

        global __cblas_zher
        __cblas_zher = dlsym(RTLD_DEFAULT, 'cblas_zher')
        if __cblas_zher == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher = dlsym(handle, 'cblas_zher')

        global __cblas_zhpr
        __cblas_zhpr = dlsym(RTLD_DEFAULT, 'cblas_zhpr')
        if __cblas_zhpr == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpr = dlsym(handle, 'cblas_zhpr')

        global __cblas_zher2
        __cblas_zher2 = dlsym(RTLD_DEFAULT, 'cblas_zher2')
        if __cblas_zher2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher2 = dlsym(handle, 'cblas_zher2')

        global __cblas_zhpr2
        __cblas_zhpr2 = dlsym(RTLD_DEFAULT, 'cblas_zhpr2')
        if __cblas_zhpr2 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpr2 = dlsym(handle, 'cblas_zhpr2')

        global __cblas_sgemm
        __cblas_sgemm = dlsym(RTLD_DEFAULT, 'cblas_sgemm')
        if __cblas_sgemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm = dlsym(handle, 'cblas_sgemm')

        global __cblas_ssymm
        __cblas_ssymm = dlsym(RTLD_DEFAULT, 'cblas_ssymm')
        if __cblas_ssymm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssymm = dlsym(handle, 'cblas_ssymm')

        global __cblas_ssyrk
        __cblas_ssyrk = dlsym(RTLD_DEFAULT, 'cblas_ssyrk')
        if __cblas_ssyrk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyrk = dlsym(handle, 'cblas_ssyrk')

        global __cblas_ssyr2k
        __cblas_ssyr2k = dlsym(RTLD_DEFAULT, 'cblas_ssyr2k')
        if __cblas_ssyr2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr2k = dlsym(handle, 'cblas_ssyr2k')

        global __cblas_strmm
        __cblas_strmm = dlsym(RTLD_DEFAULT, 'cblas_strmm')
        if __cblas_strmm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strmm = dlsym(handle, 'cblas_strmm')

        global __cblas_strsm
        __cblas_strsm = dlsym(RTLD_DEFAULT, 'cblas_strsm')
        if __cblas_strsm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strsm = dlsym(handle, 'cblas_strsm')

        global __cblas_dgemm
        __cblas_dgemm = dlsym(RTLD_DEFAULT, 'cblas_dgemm')
        if __cblas_dgemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm = dlsym(handle, 'cblas_dgemm')

        global __cblas_dsymm
        __cblas_dsymm = dlsym(RTLD_DEFAULT, 'cblas_dsymm')
        if __cblas_dsymm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsymm = dlsym(handle, 'cblas_dsymm')

        global __cblas_dsyrk
        __cblas_dsyrk = dlsym(RTLD_DEFAULT, 'cblas_dsyrk')
        if __cblas_dsyrk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyrk = dlsym(handle, 'cblas_dsyrk')

        global __cblas_dsyr2k
        __cblas_dsyr2k = dlsym(RTLD_DEFAULT, 'cblas_dsyr2k')
        if __cblas_dsyr2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr2k = dlsym(handle, 'cblas_dsyr2k')

        global __cblas_dtrmm
        __cblas_dtrmm = dlsym(RTLD_DEFAULT, 'cblas_dtrmm')
        if __cblas_dtrmm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrmm = dlsym(handle, 'cblas_dtrmm')

        global __cblas_dtrsm
        __cblas_dtrsm = dlsym(RTLD_DEFAULT, 'cblas_dtrsm')
        if __cblas_dtrsm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrsm = dlsym(handle, 'cblas_dtrsm')

        global __cblas_cgemm
        __cblas_cgemm = dlsym(RTLD_DEFAULT, 'cblas_cgemm')
        if __cblas_cgemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm = dlsym(handle, 'cblas_cgemm')

        global __cblas_csymm
        __cblas_csymm = dlsym(RTLD_DEFAULT, 'cblas_csymm')
        if __cblas_csymm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csymm = dlsym(handle, 'cblas_csymm')

        global __cblas_csyrk
        __cblas_csyrk = dlsym(RTLD_DEFAULT, 'cblas_csyrk')
        if __cblas_csyrk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csyrk = dlsym(handle, 'cblas_csyrk')

        global __cblas_csyr2k
        __cblas_csyr2k = dlsym(RTLD_DEFAULT, 'cblas_csyr2k')
        if __cblas_csyr2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csyr2k = dlsym(handle, 'cblas_csyr2k')

        global __cblas_ctrmm
        __cblas_ctrmm = dlsym(RTLD_DEFAULT, 'cblas_ctrmm')
        if __cblas_ctrmm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrmm = dlsym(handle, 'cblas_ctrmm')

        global __cblas_ctrsm
        __cblas_ctrsm = dlsym(RTLD_DEFAULT, 'cblas_ctrsm')
        if __cblas_ctrsm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrsm = dlsym(handle, 'cblas_ctrsm')

        global __cblas_zgemm
        __cblas_zgemm = dlsym(RTLD_DEFAULT, 'cblas_zgemm')
        if __cblas_zgemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm = dlsym(handle, 'cblas_zgemm')

        global __cblas_zsymm
        __cblas_zsymm = dlsym(RTLD_DEFAULT, 'cblas_zsymm')
        if __cblas_zsymm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsymm = dlsym(handle, 'cblas_zsymm')

        global __cblas_zsyrk
        __cblas_zsyrk = dlsym(RTLD_DEFAULT, 'cblas_zsyrk')
        if __cblas_zsyrk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsyrk = dlsym(handle, 'cblas_zsyrk')

        global __cblas_zsyr2k
        __cblas_zsyr2k = dlsym(RTLD_DEFAULT, 'cblas_zsyr2k')
        if __cblas_zsyr2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsyr2k = dlsym(handle, 'cblas_zsyr2k')

        global __cblas_ztrmm
        __cblas_ztrmm = dlsym(RTLD_DEFAULT, 'cblas_ztrmm')
        if __cblas_ztrmm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrmm = dlsym(handle, 'cblas_ztrmm')

        global __cblas_ztrsm
        __cblas_ztrsm = dlsym(RTLD_DEFAULT, 'cblas_ztrsm')
        if __cblas_ztrsm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrsm = dlsym(handle, 'cblas_ztrsm')

        global __cblas_chemm
        __cblas_chemm = dlsym(RTLD_DEFAULT, 'cblas_chemm')
        if __cblas_chemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chemm = dlsym(handle, 'cblas_chemm')

        global __cblas_cherk
        __cblas_cherk = dlsym(RTLD_DEFAULT, 'cblas_cherk')
        if __cblas_cherk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cherk = dlsym(handle, 'cblas_cherk')

        global __cblas_cher2k
        __cblas_cher2k = dlsym(RTLD_DEFAULT, 'cblas_cher2k')
        if __cblas_cher2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher2k = dlsym(handle, 'cblas_cher2k')

        global __cblas_zhemm
        __cblas_zhemm = dlsym(RTLD_DEFAULT, 'cblas_zhemm')
        if __cblas_zhemm == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhemm = dlsym(handle, 'cblas_zhemm')

        global __cblas_zherk
        __cblas_zherk = dlsym(RTLD_DEFAULT, 'cblas_zherk')
        if __cblas_zherk == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zherk = dlsym(handle, 'cblas_zherk')

        global __cblas_zher2k
        __cblas_zher2k = dlsym(RTLD_DEFAULT, 'cblas_zher2k')
        if __cblas_zher2k == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher2k = dlsym(handle, 'cblas_zher2k')

        global __cblas_sgemm_batch
        __cblas_sgemm_batch = dlsym(RTLD_DEFAULT, 'cblas_sgemm_batch')
        if __cblas_sgemm_batch == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm_batch = dlsym(handle, 'cblas_sgemm_batch')

        global __cblas_dgemm_batch
        __cblas_dgemm_batch = dlsym(RTLD_DEFAULT, 'cblas_dgemm_batch')
        if __cblas_dgemm_batch == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm_batch = dlsym(handle, 'cblas_dgemm_batch')

        global __cblas_cgemm_batch
        __cblas_cgemm_batch = dlsym(RTLD_DEFAULT, 'cblas_cgemm_batch')
        if __cblas_cgemm_batch == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm_batch = dlsym(handle, 'cblas_cgemm_batch')

        global __cblas_zgemm_batch
        __cblas_zgemm_batch = dlsym(RTLD_DEFAULT, 'cblas_zgemm_batch')
        if __cblas_zgemm_batch == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm_batch = dlsym(handle, 'cblas_zgemm_batch')

        global __cblas_sgemm_batch_strided
        __cblas_sgemm_batch_strided = dlsym(RTLD_DEFAULT, 'cblas_sgemm_batch_strided')
        if __cblas_sgemm_batch_strided == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm_batch_strided = dlsym(handle, 'cblas_sgemm_batch_strided')

        global __cblas_dgemm_batch_strided
        __cblas_dgemm_batch_strided = dlsym(RTLD_DEFAULT, 'cblas_dgemm_batch_strided')
        if __cblas_dgemm_batch_strided == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm_batch_strided = dlsym(handle, 'cblas_dgemm_batch_strided')

        global __cblas_cgemm_batch_strided
        __cblas_cgemm_batch_strided = dlsym(RTLD_DEFAULT, 'cblas_cgemm_batch_strided')
        if __cblas_cgemm_batch_strided == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm_batch_strided = dlsym(handle, 'cblas_cgemm_batch_strided')

        global __cblas_zgemm_batch_strided
        __cblas_zgemm_batch_strided = dlsym(RTLD_DEFAULT, 'cblas_zgemm_batch_strided')
        if __cblas_zgemm_batch_strided == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm_batch_strided = dlsym(handle, 'cblas_zgemm_batch_strided')

        global __cblas_sgemmt
        __cblas_sgemmt = dlsym(RTLD_DEFAULT, 'cblas_sgemmt')
        if __cblas_sgemmt == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemmt = dlsym(handle, 'cblas_sgemmt')

        global __cblas_dgemmt
        __cblas_dgemmt = dlsym(RTLD_DEFAULT, 'cblas_dgemmt')
        if __cblas_dgemmt == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemmt = dlsym(handle, 'cblas_dgemmt')

        global __cblas_cgemmt
        __cblas_cgemmt = dlsym(RTLD_DEFAULT, 'cblas_cgemmt')
        if __cblas_cgemmt == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemmt = dlsym(handle, 'cblas_cgemmt')

        global __cblas_zgemmt
        __cblas_zgemmt = dlsym(RTLD_DEFAULT, 'cblas_zgemmt')
        if __cblas_zgemmt == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemmt = dlsym(handle, 'cblas_zgemmt')

        global __cblas_sgemv_64
        __cblas_sgemv_64 = dlsym(RTLD_DEFAULT, 'cblas_sgemv_64')
        if __cblas_sgemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemv_64 = dlsym(handle, 'cblas_sgemv_64')

        global __cblas_sgbmv_64
        __cblas_sgbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_sgbmv_64')
        if __cblas_sgbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgbmv_64 = dlsym(handle, 'cblas_sgbmv_64')

        global __cblas_strmv_64
        __cblas_strmv_64 = dlsym(RTLD_DEFAULT, 'cblas_strmv_64')
        if __cblas_strmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strmv_64 = dlsym(handle, 'cblas_strmv_64')

        global __cblas_stbmv_64
        __cblas_stbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_stbmv_64')
        if __cblas_stbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stbmv_64 = dlsym(handle, 'cblas_stbmv_64')

        global __cblas_stpmv_64
        __cblas_stpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_stpmv_64')
        if __cblas_stpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stpmv_64 = dlsym(handle, 'cblas_stpmv_64')

        global __cblas_strsv_64
        __cblas_strsv_64 = dlsym(RTLD_DEFAULT, 'cblas_strsv_64')
        if __cblas_strsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strsv_64 = dlsym(handle, 'cblas_strsv_64')

        global __cblas_stbsv_64
        __cblas_stbsv_64 = dlsym(RTLD_DEFAULT, 'cblas_stbsv_64')
        if __cblas_stbsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stbsv_64 = dlsym(handle, 'cblas_stbsv_64')

        global __cblas_stpsv_64
        __cblas_stpsv_64 = dlsym(RTLD_DEFAULT, 'cblas_stpsv_64')
        if __cblas_stpsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_stpsv_64 = dlsym(handle, 'cblas_stpsv_64')

        global __cblas_dgemv_64
        __cblas_dgemv_64 = dlsym(RTLD_DEFAULT, 'cblas_dgemv_64')
        if __cblas_dgemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemv_64 = dlsym(handle, 'cblas_dgemv_64')

        global __cblas_dgbmv_64
        __cblas_dgbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dgbmv_64')
        if __cblas_dgbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgbmv_64 = dlsym(handle, 'cblas_dgbmv_64')

        global __cblas_dtrmv_64
        __cblas_dtrmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtrmv_64')
        if __cblas_dtrmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrmv_64 = dlsym(handle, 'cblas_dtrmv_64')

        global __cblas_dtbmv_64
        __cblas_dtbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtbmv_64')
        if __cblas_dtbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtbmv_64 = dlsym(handle, 'cblas_dtbmv_64')

        global __cblas_dtpmv_64
        __cblas_dtpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtpmv_64')
        if __cblas_dtpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtpmv_64 = dlsym(handle, 'cblas_dtpmv_64')

        global __cblas_dtrsv_64
        __cblas_dtrsv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtrsv_64')
        if __cblas_dtrsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrsv_64 = dlsym(handle, 'cblas_dtrsv_64')

        global __cblas_dtbsv_64
        __cblas_dtbsv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtbsv_64')
        if __cblas_dtbsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtbsv_64 = dlsym(handle, 'cblas_dtbsv_64')

        global __cblas_dtpsv_64
        __cblas_dtpsv_64 = dlsym(RTLD_DEFAULT, 'cblas_dtpsv_64')
        if __cblas_dtpsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtpsv_64 = dlsym(handle, 'cblas_dtpsv_64')

        global __cblas_cgemv_64
        __cblas_cgemv_64 = dlsym(RTLD_DEFAULT, 'cblas_cgemv_64')
        if __cblas_cgemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemv_64 = dlsym(handle, 'cblas_cgemv_64')

        global __cblas_cgbmv_64
        __cblas_cgbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_cgbmv_64')
        if __cblas_cgbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgbmv_64 = dlsym(handle, 'cblas_cgbmv_64')

        global __cblas_ctrmv_64
        __cblas_ctrmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctrmv_64')
        if __cblas_ctrmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrmv_64 = dlsym(handle, 'cblas_ctrmv_64')

        global __cblas_ctbmv_64
        __cblas_ctbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctbmv_64')
        if __cblas_ctbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctbmv_64 = dlsym(handle, 'cblas_ctbmv_64')

        global __cblas_ctpmv_64
        __cblas_ctpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctpmv_64')
        if __cblas_ctpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctpmv_64 = dlsym(handle, 'cblas_ctpmv_64')

        global __cblas_ctrsv_64
        __cblas_ctrsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctrsv_64')
        if __cblas_ctrsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrsv_64 = dlsym(handle, 'cblas_ctrsv_64')

        global __cblas_ctbsv_64
        __cblas_ctbsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctbsv_64')
        if __cblas_ctbsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctbsv_64 = dlsym(handle, 'cblas_ctbsv_64')

        global __cblas_ctpsv_64
        __cblas_ctpsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ctpsv_64')
        if __cblas_ctpsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctpsv_64 = dlsym(handle, 'cblas_ctpsv_64')

        global __cblas_zgemv_64
        __cblas_zgemv_64 = dlsym(RTLD_DEFAULT, 'cblas_zgemv_64')
        if __cblas_zgemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemv_64 = dlsym(handle, 'cblas_zgemv_64')

        global __cblas_zgbmv_64
        __cblas_zgbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_zgbmv_64')
        if __cblas_zgbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgbmv_64 = dlsym(handle, 'cblas_zgbmv_64')

        global __cblas_ztrmv_64
        __cblas_ztrmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztrmv_64')
        if __cblas_ztrmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrmv_64 = dlsym(handle, 'cblas_ztrmv_64')

        global __cblas_ztbmv_64
        __cblas_ztbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztbmv_64')
        if __cblas_ztbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztbmv_64 = dlsym(handle, 'cblas_ztbmv_64')

        global __cblas_ztpmv_64
        __cblas_ztpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztpmv_64')
        if __cblas_ztpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztpmv_64 = dlsym(handle, 'cblas_ztpmv_64')

        global __cblas_ztrsv_64
        __cblas_ztrsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztrsv_64')
        if __cblas_ztrsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrsv_64 = dlsym(handle, 'cblas_ztrsv_64')

        global __cblas_ztbsv_64
        __cblas_ztbsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztbsv_64')
        if __cblas_ztbsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztbsv_64 = dlsym(handle, 'cblas_ztbsv_64')

        global __cblas_ztpsv_64
        __cblas_ztpsv_64 = dlsym(RTLD_DEFAULT, 'cblas_ztpsv_64')
        if __cblas_ztpsv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztpsv_64 = dlsym(handle, 'cblas_ztpsv_64')

        global __cblas_ssymv_64
        __cblas_ssymv_64 = dlsym(RTLD_DEFAULT, 'cblas_ssymv_64')
        if __cblas_ssymv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssymv_64 = dlsym(handle, 'cblas_ssymv_64')

        global __cblas_ssbmv_64
        __cblas_ssbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_ssbmv_64')
        if __cblas_ssbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssbmv_64 = dlsym(handle, 'cblas_ssbmv_64')

        global __cblas_sspmv_64
        __cblas_sspmv_64 = dlsym(RTLD_DEFAULT, 'cblas_sspmv_64')
        if __cblas_sspmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspmv_64 = dlsym(handle, 'cblas_sspmv_64')

        global __cblas_sger_64
        __cblas_sger_64 = dlsym(RTLD_DEFAULT, 'cblas_sger_64')
        if __cblas_sger_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sger_64 = dlsym(handle, 'cblas_sger_64')

        global __cblas_ssyr_64
        __cblas_ssyr_64 = dlsym(RTLD_DEFAULT, 'cblas_ssyr_64')
        if __cblas_ssyr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr_64 = dlsym(handle, 'cblas_ssyr_64')

        global __cblas_sspr_64
        __cblas_sspr_64 = dlsym(RTLD_DEFAULT, 'cblas_sspr_64')
        if __cblas_sspr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspr_64 = dlsym(handle, 'cblas_sspr_64')

        global __cblas_ssyr2_64
        __cblas_ssyr2_64 = dlsym(RTLD_DEFAULT, 'cblas_ssyr2_64')
        if __cblas_ssyr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr2_64 = dlsym(handle, 'cblas_ssyr2_64')

        global __cblas_sspr2_64
        __cblas_sspr2_64 = dlsym(RTLD_DEFAULT, 'cblas_sspr2_64')
        if __cblas_sspr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sspr2_64 = dlsym(handle, 'cblas_sspr2_64')

        global __cblas_dsymv_64
        __cblas_dsymv_64 = dlsym(RTLD_DEFAULT, 'cblas_dsymv_64')
        if __cblas_dsymv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsymv_64 = dlsym(handle, 'cblas_dsymv_64')

        global __cblas_dsbmv_64
        __cblas_dsbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dsbmv_64')
        if __cblas_dsbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsbmv_64 = dlsym(handle, 'cblas_dsbmv_64')

        global __cblas_dspmv_64
        __cblas_dspmv_64 = dlsym(RTLD_DEFAULT, 'cblas_dspmv_64')
        if __cblas_dspmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspmv_64 = dlsym(handle, 'cblas_dspmv_64')

        global __cblas_dger_64
        __cblas_dger_64 = dlsym(RTLD_DEFAULT, 'cblas_dger_64')
        if __cblas_dger_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dger_64 = dlsym(handle, 'cblas_dger_64')

        global __cblas_dsyr_64
        __cblas_dsyr_64 = dlsym(RTLD_DEFAULT, 'cblas_dsyr_64')
        if __cblas_dsyr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr_64 = dlsym(handle, 'cblas_dsyr_64')

        global __cblas_dspr_64
        __cblas_dspr_64 = dlsym(RTLD_DEFAULT, 'cblas_dspr_64')
        if __cblas_dspr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspr_64 = dlsym(handle, 'cblas_dspr_64')

        global __cblas_dsyr2_64
        __cblas_dsyr2_64 = dlsym(RTLD_DEFAULT, 'cblas_dsyr2_64')
        if __cblas_dsyr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr2_64 = dlsym(handle, 'cblas_dsyr2_64')

        global __cblas_dspr2_64
        __cblas_dspr2_64 = dlsym(RTLD_DEFAULT, 'cblas_dspr2_64')
        if __cblas_dspr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dspr2_64 = dlsym(handle, 'cblas_dspr2_64')

        global __cblas_chemv_64
        __cblas_chemv_64 = dlsym(RTLD_DEFAULT, 'cblas_chemv_64')
        if __cblas_chemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chemv_64 = dlsym(handle, 'cblas_chemv_64')

        global __cblas_chbmv_64
        __cblas_chbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_chbmv_64')
        if __cblas_chbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chbmv_64 = dlsym(handle, 'cblas_chbmv_64')

        global __cblas_chpmv_64
        __cblas_chpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_chpmv_64')
        if __cblas_chpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpmv_64 = dlsym(handle, 'cblas_chpmv_64')

        global __cblas_cgeru_64
        __cblas_cgeru_64 = dlsym(RTLD_DEFAULT, 'cblas_cgeru_64')
        if __cblas_cgeru_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgeru_64 = dlsym(handle, 'cblas_cgeru_64')

        global __cblas_cgerc_64
        __cblas_cgerc_64 = dlsym(RTLD_DEFAULT, 'cblas_cgerc_64')
        if __cblas_cgerc_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgerc_64 = dlsym(handle, 'cblas_cgerc_64')

        global __cblas_cher_64
        __cblas_cher_64 = dlsym(RTLD_DEFAULT, 'cblas_cher_64')
        if __cblas_cher_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher_64 = dlsym(handle, 'cblas_cher_64')

        global __cblas_chpr_64
        __cblas_chpr_64 = dlsym(RTLD_DEFAULT, 'cblas_chpr_64')
        if __cblas_chpr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpr_64 = dlsym(handle, 'cblas_chpr_64')

        global __cblas_cher2_64
        __cblas_cher2_64 = dlsym(RTLD_DEFAULT, 'cblas_cher2_64')
        if __cblas_cher2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher2_64 = dlsym(handle, 'cblas_cher2_64')

        global __cblas_chpr2_64
        __cblas_chpr2_64 = dlsym(RTLD_DEFAULT, 'cblas_chpr2_64')
        if __cblas_chpr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chpr2_64 = dlsym(handle, 'cblas_chpr2_64')

        global __cblas_zhemv_64
        __cblas_zhemv_64 = dlsym(RTLD_DEFAULT, 'cblas_zhemv_64')
        if __cblas_zhemv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhemv_64 = dlsym(handle, 'cblas_zhemv_64')

        global __cblas_zhbmv_64
        __cblas_zhbmv_64 = dlsym(RTLD_DEFAULT, 'cblas_zhbmv_64')
        if __cblas_zhbmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhbmv_64 = dlsym(handle, 'cblas_zhbmv_64')

        global __cblas_zhpmv_64
        __cblas_zhpmv_64 = dlsym(RTLD_DEFAULT, 'cblas_zhpmv_64')
        if __cblas_zhpmv_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpmv_64 = dlsym(handle, 'cblas_zhpmv_64')

        global __cblas_zgeru_64
        __cblas_zgeru_64 = dlsym(RTLD_DEFAULT, 'cblas_zgeru_64')
        if __cblas_zgeru_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgeru_64 = dlsym(handle, 'cblas_zgeru_64')

        global __cblas_zgerc_64
        __cblas_zgerc_64 = dlsym(RTLD_DEFAULT, 'cblas_zgerc_64')
        if __cblas_zgerc_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgerc_64 = dlsym(handle, 'cblas_zgerc_64')

        global __cblas_zher_64
        __cblas_zher_64 = dlsym(RTLD_DEFAULT, 'cblas_zher_64')
        if __cblas_zher_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher_64 = dlsym(handle, 'cblas_zher_64')

        global __cblas_zhpr_64
        __cblas_zhpr_64 = dlsym(RTLD_DEFAULT, 'cblas_zhpr_64')
        if __cblas_zhpr_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpr_64 = dlsym(handle, 'cblas_zhpr_64')

        global __cblas_zher2_64
        __cblas_zher2_64 = dlsym(RTLD_DEFAULT, 'cblas_zher2_64')
        if __cblas_zher2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher2_64 = dlsym(handle, 'cblas_zher2_64')

        global __cblas_zhpr2_64
        __cblas_zhpr2_64 = dlsym(RTLD_DEFAULT, 'cblas_zhpr2_64')
        if __cblas_zhpr2_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhpr2_64 = dlsym(handle, 'cblas_zhpr2_64')

        global __cblas_sgemm_64
        __cblas_sgemm_64 = dlsym(RTLD_DEFAULT, 'cblas_sgemm_64')
        if __cblas_sgemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm_64 = dlsym(handle, 'cblas_sgemm_64')

        global __cblas_ssymm_64
        __cblas_ssymm_64 = dlsym(RTLD_DEFAULT, 'cblas_ssymm_64')
        if __cblas_ssymm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssymm_64 = dlsym(handle, 'cblas_ssymm_64')

        global __cblas_ssyrk_64
        __cblas_ssyrk_64 = dlsym(RTLD_DEFAULT, 'cblas_ssyrk_64')
        if __cblas_ssyrk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyrk_64 = dlsym(handle, 'cblas_ssyrk_64')

        global __cblas_ssyr2k_64
        __cblas_ssyr2k_64 = dlsym(RTLD_DEFAULT, 'cblas_ssyr2k_64')
        if __cblas_ssyr2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ssyr2k_64 = dlsym(handle, 'cblas_ssyr2k_64')

        global __cblas_strmm_64
        __cblas_strmm_64 = dlsym(RTLD_DEFAULT, 'cblas_strmm_64')
        if __cblas_strmm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strmm_64 = dlsym(handle, 'cblas_strmm_64')

        global __cblas_strsm_64
        __cblas_strsm_64 = dlsym(RTLD_DEFAULT, 'cblas_strsm_64')
        if __cblas_strsm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_strsm_64 = dlsym(handle, 'cblas_strsm_64')

        global __cblas_dgemm_64
        __cblas_dgemm_64 = dlsym(RTLD_DEFAULT, 'cblas_dgemm_64')
        if __cblas_dgemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm_64 = dlsym(handle, 'cblas_dgemm_64')

        global __cblas_dsymm_64
        __cblas_dsymm_64 = dlsym(RTLD_DEFAULT, 'cblas_dsymm_64')
        if __cblas_dsymm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsymm_64 = dlsym(handle, 'cblas_dsymm_64')

        global __cblas_dsyrk_64
        __cblas_dsyrk_64 = dlsym(RTLD_DEFAULT, 'cblas_dsyrk_64')
        if __cblas_dsyrk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyrk_64 = dlsym(handle, 'cblas_dsyrk_64')

        global __cblas_dsyr2k_64
        __cblas_dsyr2k_64 = dlsym(RTLD_DEFAULT, 'cblas_dsyr2k_64')
        if __cblas_dsyr2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dsyr2k_64 = dlsym(handle, 'cblas_dsyr2k_64')

        global __cblas_dtrmm_64
        __cblas_dtrmm_64 = dlsym(RTLD_DEFAULT, 'cblas_dtrmm_64')
        if __cblas_dtrmm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrmm_64 = dlsym(handle, 'cblas_dtrmm_64')

        global __cblas_dtrsm_64
        __cblas_dtrsm_64 = dlsym(RTLD_DEFAULT, 'cblas_dtrsm_64')
        if __cblas_dtrsm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dtrsm_64 = dlsym(handle, 'cblas_dtrsm_64')

        global __cblas_cgemm_64
        __cblas_cgemm_64 = dlsym(RTLD_DEFAULT, 'cblas_cgemm_64')
        if __cblas_cgemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm_64 = dlsym(handle, 'cblas_cgemm_64')

        global __cblas_csymm_64
        __cblas_csymm_64 = dlsym(RTLD_DEFAULT, 'cblas_csymm_64')
        if __cblas_csymm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csymm_64 = dlsym(handle, 'cblas_csymm_64')

        global __cblas_csyrk_64
        __cblas_csyrk_64 = dlsym(RTLD_DEFAULT, 'cblas_csyrk_64')
        if __cblas_csyrk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csyrk_64 = dlsym(handle, 'cblas_csyrk_64')

        global __cblas_csyr2k_64
        __cblas_csyr2k_64 = dlsym(RTLD_DEFAULT, 'cblas_csyr2k_64')
        if __cblas_csyr2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_csyr2k_64 = dlsym(handle, 'cblas_csyr2k_64')

        global __cblas_ctrmm_64
        __cblas_ctrmm_64 = dlsym(RTLD_DEFAULT, 'cblas_ctrmm_64')
        if __cblas_ctrmm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrmm_64 = dlsym(handle, 'cblas_ctrmm_64')

        global __cblas_ctrsm_64
        __cblas_ctrsm_64 = dlsym(RTLD_DEFAULT, 'cblas_ctrsm_64')
        if __cblas_ctrsm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ctrsm_64 = dlsym(handle, 'cblas_ctrsm_64')

        global __cblas_zgemm_64
        __cblas_zgemm_64 = dlsym(RTLD_DEFAULT, 'cblas_zgemm_64')
        if __cblas_zgemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm_64 = dlsym(handle, 'cblas_zgemm_64')

        global __cblas_zsymm_64
        __cblas_zsymm_64 = dlsym(RTLD_DEFAULT, 'cblas_zsymm_64')
        if __cblas_zsymm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsymm_64 = dlsym(handle, 'cblas_zsymm_64')

        global __cblas_zsyrk_64
        __cblas_zsyrk_64 = dlsym(RTLD_DEFAULT, 'cblas_zsyrk_64')
        if __cblas_zsyrk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsyrk_64 = dlsym(handle, 'cblas_zsyrk_64')

        global __cblas_zsyr2k_64
        __cblas_zsyr2k_64 = dlsym(RTLD_DEFAULT, 'cblas_zsyr2k_64')
        if __cblas_zsyr2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zsyr2k_64 = dlsym(handle, 'cblas_zsyr2k_64')

        global __cblas_ztrmm_64
        __cblas_ztrmm_64 = dlsym(RTLD_DEFAULT, 'cblas_ztrmm_64')
        if __cblas_ztrmm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrmm_64 = dlsym(handle, 'cblas_ztrmm_64')

        global __cblas_ztrsm_64
        __cblas_ztrsm_64 = dlsym(RTLD_DEFAULT, 'cblas_ztrsm_64')
        if __cblas_ztrsm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_ztrsm_64 = dlsym(handle, 'cblas_ztrsm_64')

        global __cblas_chemm_64
        __cblas_chemm_64 = dlsym(RTLD_DEFAULT, 'cblas_chemm_64')
        if __cblas_chemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_chemm_64 = dlsym(handle, 'cblas_chemm_64')

        global __cblas_cherk_64
        __cblas_cherk_64 = dlsym(RTLD_DEFAULT, 'cblas_cherk_64')
        if __cblas_cherk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cherk_64 = dlsym(handle, 'cblas_cherk_64')

        global __cblas_cher2k_64
        __cblas_cher2k_64 = dlsym(RTLD_DEFAULT, 'cblas_cher2k_64')
        if __cblas_cher2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cher2k_64 = dlsym(handle, 'cblas_cher2k_64')

        global __cblas_zhemm_64
        __cblas_zhemm_64 = dlsym(RTLD_DEFAULT, 'cblas_zhemm_64')
        if __cblas_zhemm_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zhemm_64 = dlsym(handle, 'cblas_zhemm_64')

        global __cblas_zherk_64
        __cblas_zherk_64 = dlsym(RTLD_DEFAULT, 'cblas_zherk_64')
        if __cblas_zherk_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zherk_64 = dlsym(handle, 'cblas_zherk_64')

        global __cblas_zher2k_64
        __cblas_zher2k_64 = dlsym(RTLD_DEFAULT, 'cblas_zher2k_64')
        if __cblas_zher2k_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zher2k_64 = dlsym(handle, 'cblas_zher2k_64')

        global __cblas_sgemmt_64
        __cblas_sgemmt_64 = dlsym(RTLD_DEFAULT, 'cblas_sgemmt_64')
        if __cblas_sgemmt_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemmt_64 = dlsym(handle, 'cblas_sgemmt_64')

        global __cblas_dgemmt_64
        __cblas_dgemmt_64 = dlsym(RTLD_DEFAULT, 'cblas_dgemmt_64')
        if __cblas_dgemmt_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemmt_64 = dlsym(handle, 'cblas_dgemmt_64')

        global __cblas_cgemmt_64
        __cblas_cgemmt_64 = dlsym(RTLD_DEFAULT, 'cblas_cgemmt_64')
        if __cblas_cgemmt_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemmt_64 = dlsym(handle, 'cblas_cgemmt_64')

        global __cblas_zgemmt_64
        __cblas_zgemmt_64 = dlsym(RTLD_DEFAULT, 'cblas_zgemmt_64')
        if __cblas_zgemmt_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemmt_64 = dlsym(handle, 'cblas_zgemmt_64')

        global __cblas_sgemm_batch_64
        __cblas_sgemm_batch_64 = dlsym(RTLD_DEFAULT, 'cblas_sgemm_batch_64')
        if __cblas_sgemm_batch_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm_batch_64 = dlsym(handle, 'cblas_sgemm_batch_64')

        global __cblas_dgemm_batch_64
        __cblas_dgemm_batch_64 = dlsym(RTLD_DEFAULT, 'cblas_dgemm_batch_64')
        if __cblas_dgemm_batch_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm_batch_64 = dlsym(handle, 'cblas_dgemm_batch_64')

        global __cblas_cgemm_batch_64
        __cblas_cgemm_batch_64 = dlsym(RTLD_DEFAULT, 'cblas_cgemm_batch_64')
        if __cblas_cgemm_batch_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm_batch_64 = dlsym(handle, 'cblas_cgemm_batch_64')

        global __cblas_zgemm_batch_64
        __cblas_zgemm_batch_64 = dlsym(RTLD_DEFAULT, 'cblas_zgemm_batch_64')
        if __cblas_zgemm_batch_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm_batch_64 = dlsym(handle, 'cblas_zgemm_batch_64')

        global __cblas_sgemm_batch_strided_64
        __cblas_sgemm_batch_strided_64 = dlsym(RTLD_DEFAULT, 'cblas_sgemm_batch_strided_64')
        if __cblas_sgemm_batch_strided_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_sgemm_batch_strided_64 = dlsym(handle, 'cblas_sgemm_batch_strided_64')

        global __cblas_dgemm_batch_strided_64
        __cblas_dgemm_batch_strided_64 = dlsym(RTLD_DEFAULT, 'cblas_dgemm_batch_strided_64')
        if __cblas_dgemm_batch_strided_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_dgemm_batch_strided_64 = dlsym(handle, 'cblas_dgemm_batch_strided_64')

        global __cblas_cgemm_batch_strided_64
        __cblas_cgemm_batch_strided_64 = dlsym(RTLD_DEFAULT, 'cblas_cgemm_batch_strided_64')
        if __cblas_cgemm_batch_strided_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_cgemm_batch_strided_64 = dlsym(handle, 'cblas_cgemm_batch_strided_64')

        global __cblas_zgemm_batch_strided_64
        __cblas_zgemm_batch_strided_64 = dlsym(RTLD_DEFAULT, 'cblas_zgemm_batch_strided_64')
        if __cblas_zgemm_batch_strided_64 == NULL:
            if handle == NULL:
                handle = load_library()
            __cblas_zgemm_batch_strided_64 = dlsym(handle, 'cblas_zgemm_batch_strided_64')

        __py_nvpl_blas_init = True
        return 0


cdef dict func_ptrs = None


cpdef void _set_lib_so_names(tuple lib_so_names):
    global __lib_so_names
    __lib_so_names = lib_so_names


cpdef tuple _get_lib_so_names():
    global __lib_so_names
    return __lib_so_names


cpdef str _get_current_lib_so_name():
    global __current_so_name
    return __current_so_name


cpdef dict _inspect_function_pointers():
    global func_ptrs
    if func_ptrs is not None:
        return func_ptrs

    _check_or_init_nvpl_blas()
    cdef dict data = {}

    global __MKL_Set_Num_Threads_Local
    data["__MKL_Set_Num_Threads_Local"] = <intptr_t>__MKL_Set_Num_Threads_Local

    global __MKL_Set_Num_Threads
    data["__MKL_Set_Num_Threads"] = <intptr_t>__MKL_Set_Num_Threads

    global __openblas_set_num_threads
    data["__openblas_set_num_threads"] = <intptr_t>__openblas_set_num_threads

    global __openblas_set_num_threads_local
    data["__openblas_set_num_threads_local"] = <intptr_t>__openblas_set_num_threads_local

    global __nvpl_blas_get_version
    data["__nvpl_blas_get_version"] = <intptr_t>__nvpl_blas_get_version

    global __nvpl_blas_get_max_threads
    data["__nvpl_blas_get_max_threads"] = <intptr_t>__nvpl_blas_get_max_threads

    global __nvpl_blas_set_num_threads
    data["__nvpl_blas_set_num_threads"] = <intptr_t>__nvpl_blas_set_num_threads

    global __nvpl_blas_set_num_threads_local
    data["__nvpl_blas_set_num_threads_local"] = <intptr_t>__nvpl_blas_set_num_threads_local

    global __cblas_sgemv
    data["__cblas_sgemv"] = <intptr_t>__cblas_sgemv

    global __cblas_sgbmv
    data["__cblas_sgbmv"] = <intptr_t>__cblas_sgbmv

    global __cblas_strmv
    data["__cblas_strmv"] = <intptr_t>__cblas_strmv

    global __cblas_stbmv
    data["__cblas_stbmv"] = <intptr_t>__cblas_stbmv

    global __cblas_stpmv
    data["__cblas_stpmv"] = <intptr_t>__cblas_stpmv

    global __cblas_strsv
    data["__cblas_strsv"] = <intptr_t>__cblas_strsv

    global __cblas_stbsv
    data["__cblas_stbsv"] = <intptr_t>__cblas_stbsv

    global __cblas_stpsv
    data["__cblas_stpsv"] = <intptr_t>__cblas_stpsv

    global __cblas_dgemv
    data["__cblas_dgemv"] = <intptr_t>__cblas_dgemv

    global __cblas_dgbmv
    data["__cblas_dgbmv"] = <intptr_t>__cblas_dgbmv

    global __cblas_dtrmv
    data["__cblas_dtrmv"] = <intptr_t>__cblas_dtrmv

    global __cblas_dtbmv
    data["__cblas_dtbmv"] = <intptr_t>__cblas_dtbmv

    global __cblas_dtpmv
    data["__cblas_dtpmv"] = <intptr_t>__cblas_dtpmv

    global __cblas_dtrsv
    data["__cblas_dtrsv"] = <intptr_t>__cblas_dtrsv

    global __cblas_dtbsv
    data["__cblas_dtbsv"] = <intptr_t>__cblas_dtbsv

    global __cblas_dtpsv
    data["__cblas_dtpsv"] = <intptr_t>__cblas_dtpsv

    global __cblas_cgemv
    data["__cblas_cgemv"] = <intptr_t>__cblas_cgemv

    global __cblas_cgbmv
    data["__cblas_cgbmv"] = <intptr_t>__cblas_cgbmv

    global __cblas_ctrmv
    data["__cblas_ctrmv"] = <intptr_t>__cblas_ctrmv

    global __cblas_ctbmv
    data["__cblas_ctbmv"] = <intptr_t>__cblas_ctbmv

    global __cblas_ctpmv
    data["__cblas_ctpmv"] = <intptr_t>__cblas_ctpmv

    global __cblas_ctrsv
    data["__cblas_ctrsv"] = <intptr_t>__cblas_ctrsv

    global __cblas_ctbsv
    data["__cblas_ctbsv"] = <intptr_t>__cblas_ctbsv

    global __cblas_ctpsv
    data["__cblas_ctpsv"] = <intptr_t>__cblas_ctpsv

    global __cblas_zgemv
    data["__cblas_zgemv"] = <intptr_t>__cblas_zgemv

    global __cblas_zgbmv
    data["__cblas_zgbmv"] = <intptr_t>__cblas_zgbmv

    global __cblas_ztrmv
    data["__cblas_ztrmv"] = <intptr_t>__cblas_ztrmv

    global __cblas_ztbmv
    data["__cblas_ztbmv"] = <intptr_t>__cblas_ztbmv

    global __cblas_ztpmv
    data["__cblas_ztpmv"] = <intptr_t>__cblas_ztpmv

    global __cblas_ztrsv
    data["__cblas_ztrsv"] = <intptr_t>__cblas_ztrsv

    global __cblas_ztbsv
    data["__cblas_ztbsv"] = <intptr_t>__cblas_ztbsv

    global __cblas_ztpsv
    data["__cblas_ztpsv"] = <intptr_t>__cblas_ztpsv

    global __cblas_ssymv
    data["__cblas_ssymv"] = <intptr_t>__cblas_ssymv

    global __cblas_ssbmv
    data["__cblas_ssbmv"] = <intptr_t>__cblas_ssbmv

    global __cblas_sspmv
    data["__cblas_sspmv"] = <intptr_t>__cblas_sspmv

    global __cblas_sger
    data["__cblas_sger"] = <intptr_t>__cblas_sger

    global __cblas_ssyr
    data["__cblas_ssyr"] = <intptr_t>__cblas_ssyr

    global __cblas_sspr
    data["__cblas_sspr"] = <intptr_t>__cblas_sspr

    global __cblas_ssyr2
    data["__cblas_ssyr2"] = <intptr_t>__cblas_ssyr2

    global __cblas_sspr2
    data["__cblas_sspr2"] = <intptr_t>__cblas_sspr2

    global __cblas_dsymv
    data["__cblas_dsymv"] = <intptr_t>__cblas_dsymv

    global __cblas_dsbmv
    data["__cblas_dsbmv"] = <intptr_t>__cblas_dsbmv

    global __cblas_dspmv
    data["__cblas_dspmv"] = <intptr_t>__cblas_dspmv

    global __cblas_dger
    data["__cblas_dger"] = <intptr_t>__cblas_dger

    global __cblas_dsyr
    data["__cblas_dsyr"] = <intptr_t>__cblas_dsyr

    global __cblas_dspr
    data["__cblas_dspr"] = <intptr_t>__cblas_dspr

    global __cblas_dsyr2
    data["__cblas_dsyr2"] = <intptr_t>__cblas_dsyr2

    global __cblas_dspr2
    data["__cblas_dspr2"] = <intptr_t>__cblas_dspr2

    global __cblas_chemv
    data["__cblas_chemv"] = <intptr_t>__cblas_chemv

    global __cblas_chbmv
    data["__cblas_chbmv"] = <intptr_t>__cblas_chbmv

    global __cblas_chpmv
    data["__cblas_chpmv"] = <intptr_t>__cblas_chpmv

    global __cblas_cgeru
    data["__cblas_cgeru"] = <intptr_t>__cblas_cgeru

    global __cblas_cgerc
    data["__cblas_cgerc"] = <intptr_t>__cblas_cgerc

    global __cblas_cher
    data["__cblas_cher"] = <intptr_t>__cblas_cher

    global __cblas_chpr
    data["__cblas_chpr"] = <intptr_t>__cblas_chpr

    global __cblas_cher2
    data["__cblas_cher2"] = <intptr_t>__cblas_cher2

    global __cblas_chpr2
    data["__cblas_chpr2"] = <intptr_t>__cblas_chpr2

    global __cblas_zhemv
    data["__cblas_zhemv"] = <intptr_t>__cblas_zhemv

    global __cblas_zhbmv
    data["__cblas_zhbmv"] = <intptr_t>__cblas_zhbmv

    global __cblas_zhpmv
    data["__cblas_zhpmv"] = <intptr_t>__cblas_zhpmv

    global __cblas_zgeru
    data["__cblas_zgeru"] = <intptr_t>__cblas_zgeru

    global __cblas_zgerc
    data["__cblas_zgerc"] = <intptr_t>__cblas_zgerc

    global __cblas_zher
    data["__cblas_zher"] = <intptr_t>__cblas_zher

    global __cblas_zhpr
    data["__cblas_zhpr"] = <intptr_t>__cblas_zhpr

    global __cblas_zher2
    data["__cblas_zher2"] = <intptr_t>__cblas_zher2

    global __cblas_zhpr2
    data["__cblas_zhpr2"] = <intptr_t>__cblas_zhpr2

    global __cblas_sgemm
    data["__cblas_sgemm"] = <intptr_t>__cblas_sgemm

    global __cblas_ssymm
    data["__cblas_ssymm"] = <intptr_t>__cblas_ssymm

    global __cblas_ssyrk
    data["__cblas_ssyrk"] = <intptr_t>__cblas_ssyrk

    global __cblas_ssyr2k
    data["__cblas_ssyr2k"] = <intptr_t>__cblas_ssyr2k

    global __cblas_strmm
    data["__cblas_strmm"] = <intptr_t>__cblas_strmm

    global __cblas_strsm
    data["__cblas_strsm"] = <intptr_t>__cblas_strsm

    global __cblas_dgemm
    data["__cblas_dgemm"] = <intptr_t>__cblas_dgemm

    global __cblas_dsymm
    data["__cblas_dsymm"] = <intptr_t>__cblas_dsymm

    global __cblas_dsyrk
    data["__cblas_dsyrk"] = <intptr_t>__cblas_dsyrk

    global __cblas_dsyr2k
    data["__cblas_dsyr2k"] = <intptr_t>__cblas_dsyr2k

    global __cblas_dtrmm
    data["__cblas_dtrmm"] = <intptr_t>__cblas_dtrmm

    global __cblas_dtrsm
    data["__cblas_dtrsm"] = <intptr_t>__cblas_dtrsm

    global __cblas_cgemm
    data["__cblas_cgemm"] = <intptr_t>__cblas_cgemm

    global __cblas_csymm
    data["__cblas_csymm"] = <intptr_t>__cblas_csymm

    global __cblas_csyrk
    data["__cblas_csyrk"] = <intptr_t>__cblas_csyrk

    global __cblas_csyr2k
    data["__cblas_csyr2k"] = <intptr_t>__cblas_csyr2k

    global __cblas_ctrmm
    data["__cblas_ctrmm"] = <intptr_t>__cblas_ctrmm

    global __cblas_ctrsm
    data["__cblas_ctrsm"] = <intptr_t>__cblas_ctrsm

    global __cblas_zgemm
    data["__cblas_zgemm"] = <intptr_t>__cblas_zgemm

    global __cblas_zsymm
    data["__cblas_zsymm"] = <intptr_t>__cblas_zsymm

    global __cblas_zsyrk
    data["__cblas_zsyrk"] = <intptr_t>__cblas_zsyrk

    global __cblas_zsyr2k
    data["__cblas_zsyr2k"] = <intptr_t>__cblas_zsyr2k

    global __cblas_ztrmm
    data["__cblas_ztrmm"] = <intptr_t>__cblas_ztrmm

    global __cblas_ztrsm
    data["__cblas_ztrsm"] = <intptr_t>__cblas_ztrsm

    global __cblas_chemm
    data["__cblas_chemm"] = <intptr_t>__cblas_chemm

    global __cblas_cherk
    data["__cblas_cherk"] = <intptr_t>__cblas_cherk

    global __cblas_cher2k
    data["__cblas_cher2k"] = <intptr_t>__cblas_cher2k

    global __cblas_zhemm
    data["__cblas_zhemm"] = <intptr_t>__cblas_zhemm

    global __cblas_zherk
    data["__cblas_zherk"] = <intptr_t>__cblas_zherk

    global __cblas_zher2k
    data["__cblas_zher2k"] = <intptr_t>__cblas_zher2k

    global __cblas_sgemm_batch
    data["__cblas_sgemm_batch"] = <intptr_t>__cblas_sgemm_batch

    global __cblas_dgemm_batch
    data["__cblas_dgemm_batch"] = <intptr_t>__cblas_dgemm_batch

    global __cblas_cgemm_batch
    data["__cblas_cgemm_batch"] = <intptr_t>__cblas_cgemm_batch

    global __cblas_zgemm_batch
    data["__cblas_zgemm_batch"] = <intptr_t>__cblas_zgemm_batch

    global __cblas_sgemm_batch_strided
    data["__cblas_sgemm_batch_strided"] = <intptr_t>__cblas_sgemm_batch_strided

    global __cblas_dgemm_batch_strided
    data["__cblas_dgemm_batch_strided"] = <intptr_t>__cblas_dgemm_batch_strided

    global __cblas_cgemm_batch_strided
    data["__cblas_cgemm_batch_strided"] = <intptr_t>__cblas_cgemm_batch_strided

    global __cblas_zgemm_batch_strided
    data["__cblas_zgemm_batch_strided"] = <intptr_t>__cblas_zgemm_batch_strided

    global __cblas_sgemmt
    data["__cblas_sgemmt"] = <intptr_t>__cblas_sgemmt

    global __cblas_dgemmt
    data["__cblas_dgemmt"] = <intptr_t>__cblas_dgemmt

    global __cblas_cgemmt
    data["__cblas_cgemmt"] = <intptr_t>__cblas_cgemmt

    global __cblas_zgemmt
    data["__cblas_zgemmt"] = <intptr_t>__cblas_zgemmt

    global __cblas_sgemv_64
    data["__cblas_sgemv_64"] = <intptr_t>__cblas_sgemv_64

    global __cblas_sgbmv_64
    data["__cblas_sgbmv_64"] = <intptr_t>__cblas_sgbmv_64

    global __cblas_strmv_64
    data["__cblas_strmv_64"] = <intptr_t>__cblas_strmv_64

    global __cblas_stbmv_64
    data["__cblas_stbmv_64"] = <intptr_t>__cblas_stbmv_64

    global __cblas_stpmv_64
    data["__cblas_stpmv_64"] = <intptr_t>__cblas_stpmv_64

    global __cblas_strsv_64
    data["__cblas_strsv_64"] = <intptr_t>__cblas_strsv_64

    global __cblas_stbsv_64
    data["__cblas_stbsv_64"] = <intptr_t>__cblas_stbsv_64

    global __cblas_stpsv_64
    data["__cblas_stpsv_64"] = <intptr_t>__cblas_stpsv_64

    global __cblas_dgemv_64
    data["__cblas_dgemv_64"] = <intptr_t>__cblas_dgemv_64

    global __cblas_dgbmv_64
    data["__cblas_dgbmv_64"] = <intptr_t>__cblas_dgbmv_64

    global __cblas_dtrmv_64
    data["__cblas_dtrmv_64"] = <intptr_t>__cblas_dtrmv_64

    global __cblas_dtbmv_64
    data["__cblas_dtbmv_64"] = <intptr_t>__cblas_dtbmv_64

    global __cblas_dtpmv_64
    data["__cblas_dtpmv_64"] = <intptr_t>__cblas_dtpmv_64

    global __cblas_dtrsv_64
    data["__cblas_dtrsv_64"] = <intptr_t>__cblas_dtrsv_64

    global __cblas_dtbsv_64
    data["__cblas_dtbsv_64"] = <intptr_t>__cblas_dtbsv_64

    global __cblas_dtpsv_64
    data["__cblas_dtpsv_64"] = <intptr_t>__cblas_dtpsv_64

    global __cblas_cgemv_64
    data["__cblas_cgemv_64"] = <intptr_t>__cblas_cgemv_64

    global __cblas_cgbmv_64
    data["__cblas_cgbmv_64"] = <intptr_t>__cblas_cgbmv_64

    global __cblas_ctrmv_64
    data["__cblas_ctrmv_64"] = <intptr_t>__cblas_ctrmv_64

    global __cblas_ctbmv_64
    data["__cblas_ctbmv_64"] = <intptr_t>__cblas_ctbmv_64

    global __cblas_ctpmv_64
    data["__cblas_ctpmv_64"] = <intptr_t>__cblas_ctpmv_64

    global __cblas_ctrsv_64
    data["__cblas_ctrsv_64"] = <intptr_t>__cblas_ctrsv_64

    global __cblas_ctbsv_64
    data["__cblas_ctbsv_64"] = <intptr_t>__cblas_ctbsv_64

    global __cblas_ctpsv_64
    data["__cblas_ctpsv_64"] = <intptr_t>__cblas_ctpsv_64

    global __cblas_zgemv_64
    data["__cblas_zgemv_64"] = <intptr_t>__cblas_zgemv_64

    global __cblas_zgbmv_64
    data["__cblas_zgbmv_64"] = <intptr_t>__cblas_zgbmv_64

    global __cblas_ztrmv_64
    data["__cblas_ztrmv_64"] = <intptr_t>__cblas_ztrmv_64

    global __cblas_ztbmv_64
    data["__cblas_ztbmv_64"] = <intptr_t>__cblas_ztbmv_64

    global __cblas_ztpmv_64
    data["__cblas_ztpmv_64"] = <intptr_t>__cblas_ztpmv_64

    global __cblas_ztrsv_64
    data["__cblas_ztrsv_64"] = <intptr_t>__cblas_ztrsv_64

    global __cblas_ztbsv_64
    data["__cblas_ztbsv_64"] = <intptr_t>__cblas_ztbsv_64

    global __cblas_ztpsv_64
    data["__cblas_ztpsv_64"] = <intptr_t>__cblas_ztpsv_64

    global __cblas_ssymv_64
    data["__cblas_ssymv_64"] = <intptr_t>__cblas_ssymv_64

    global __cblas_ssbmv_64
    data["__cblas_ssbmv_64"] = <intptr_t>__cblas_ssbmv_64

    global __cblas_sspmv_64
    data["__cblas_sspmv_64"] = <intptr_t>__cblas_sspmv_64

    global __cblas_sger_64
    data["__cblas_sger_64"] = <intptr_t>__cblas_sger_64

    global __cblas_ssyr_64
    data["__cblas_ssyr_64"] = <intptr_t>__cblas_ssyr_64

    global __cblas_sspr_64
    data["__cblas_sspr_64"] = <intptr_t>__cblas_sspr_64

    global __cblas_ssyr2_64
    data["__cblas_ssyr2_64"] = <intptr_t>__cblas_ssyr2_64

    global __cblas_sspr2_64
    data["__cblas_sspr2_64"] = <intptr_t>__cblas_sspr2_64

    global __cblas_dsymv_64
    data["__cblas_dsymv_64"] = <intptr_t>__cblas_dsymv_64

    global __cblas_dsbmv_64
    data["__cblas_dsbmv_64"] = <intptr_t>__cblas_dsbmv_64

    global __cblas_dspmv_64
    data["__cblas_dspmv_64"] = <intptr_t>__cblas_dspmv_64

    global __cblas_dger_64
    data["__cblas_dger_64"] = <intptr_t>__cblas_dger_64

    global __cblas_dsyr_64
    data["__cblas_dsyr_64"] = <intptr_t>__cblas_dsyr_64

    global __cblas_dspr_64
    data["__cblas_dspr_64"] = <intptr_t>__cblas_dspr_64

    global __cblas_dsyr2_64
    data["__cblas_dsyr2_64"] = <intptr_t>__cblas_dsyr2_64

    global __cblas_dspr2_64
    data["__cblas_dspr2_64"] = <intptr_t>__cblas_dspr2_64

    global __cblas_chemv_64
    data["__cblas_chemv_64"] = <intptr_t>__cblas_chemv_64

    global __cblas_chbmv_64
    data["__cblas_chbmv_64"] = <intptr_t>__cblas_chbmv_64

    global __cblas_chpmv_64
    data["__cblas_chpmv_64"] = <intptr_t>__cblas_chpmv_64

    global __cblas_cgeru_64
    data["__cblas_cgeru_64"] = <intptr_t>__cblas_cgeru_64

    global __cblas_cgerc_64
    data["__cblas_cgerc_64"] = <intptr_t>__cblas_cgerc_64

    global __cblas_cher_64
    data["__cblas_cher_64"] = <intptr_t>__cblas_cher_64

    global __cblas_chpr_64
    data["__cblas_chpr_64"] = <intptr_t>__cblas_chpr_64

    global __cblas_cher2_64
    data["__cblas_cher2_64"] = <intptr_t>__cblas_cher2_64

    global __cblas_chpr2_64
    data["__cblas_chpr2_64"] = <intptr_t>__cblas_chpr2_64

    global __cblas_zhemv_64
    data["__cblas_zhemv_64"] = <intptr_t>__cblas_zhemv_64

    global __cblas_zhbmv_64
    data["__cblas_zhbmv_64"] = <intptr_t>__cblas_zhbmv_64

    global __cblas_zhpmv_64
    data["__cblas_zhpmv_64"] = <intptr_t>__cblas_zhpmv_64

    global __cblas_zgeru_64
    data["__cblas_zgeru_64"] = <intptr_t>__cblas_zgeru_64

    global __cblas_zgerc_64
    data["__cblas_zgerc_64"] = <intptr_t>__cblas_zgerc_64

    global __cblas_zher_64
    data["__cblas_zher_64"] = <intptr_t>__cblas_zher_64

    global __cblas_zhpr_64
    data["__cblas_zhpr_64"] = <intptr_t>__cblas_zhpr_64

    global __cblas_zher2_64
    data["__cblas_zher2_64"] = <intptr_t>__cblas_zher2_64

    global __cblas_zhpr2_64
    data["__cblas_zhpr2_64"] = <intptr_t>__cblas_zhpr2_64

    global __cblas_sgemm_64
    data["__cblas_sgemm_64"] = <intptr_t>__cblas_sgemm_64

    global __cblas_ssymm_64
    data["__cblas_ssymm_64"] = <intptr_t>__cblas_ssymm_64

    global __cblas_ssyrk_64
    data["__cblas_ssyrk_64"] = <intptr_t>__cblas_ssyrk_64

    global __cblas_ssyr2k_64
    data["__cblas_ssyr2k_64"] = <intptr_t>__cblas_ssyr2k_64

    global __cblas_strmm_64
    data["__cblas_strmm_64"] = <intptr_t>__cblas_strmm_64

    global __cblas_strsm_64
    data["__cblas_strsm_64"] = <intptr_t>__cblas_strsm_64

    global __cblas_dgemm_64
    data["__cblas_dgemm_64"] = <intptr_t>__cblas_dgemm_64

    global __cblas_dsymm_64
    data["__cblas_dsymm_64"] = <intptr_t>__cblas_dsymm_64

    global __cblas_dsyrk_64
    data["__cblas_dsyrk_64"] = <intptr_t>__cblas_dsyrk_64

    global __cblas_dsyr2k_64
    data["__cblas_dsyr2k_64"] = <intptr_t>__cblas_dsyr2k_64

    global __cblas_dtrmm_64
    data["__cblas_dtrmm_64"] = <intptr_t>__cblas_dtrmm_64

    global __cblas_dtrsm_64
    data["__cblas_dtrsm_64"] = <intptr_t>__cblas_dtrsm_64

    global __cblas_cgemm_64
    data["__cblas_cgemm_64"] = <intptr_t>__cblas_cgemm_64

    global __cblas_csymm_64
    data["__cblas_csymm_64"] = <intptr_t>__cblas_csymm_64

    global __cblas_csyrk_64
    data["__cblas_csyrk_64"] = <intptr_t>__cblas_csyrk_64

    global __cblas_csyr2k_64
    data["__cblas_csyr2k_64"] = <intptr_t>__cblas_csyr2k_64

    global __cblas_ctrmm_64
    data["__cblas_ctrmm_64"] = <intptr_t>__cblas_ctrmm_64

    global __cblas_ctrsm_64
    data["__cblas_ctrsm_64"] = <intptr_t>__cblas_ctrsm_64

    global __cblas_zgemm_64
    data["__cblas_zgemm_64"] = <intptr_t>__cblas_zgemm_64

    global __cblas_zsymm_64
    data["__cblas_zsymm_64"] = <intptr_t>__cblas_zsymm_64

    global __cblas_zsyrk_64
    data["__cblas_zsyrk_64"] = <intptr_t>__cblas_zsyrk_64

    global __cblas_zsyr2k_64
    data["__cblas_zsyr2k_64"] = <intptr_t>__cblas_zsyr2k_64

    global __cblas_ztrmm_64
    data["__cblas_ztrmm_64"] = <intptr_t>__cblas_ztrmm_64

    global __cblas_ztrsm_64
    data["__cblas_ztrsm_64"] = <intptr_t>__cblas_ztrsm_64

    global __cblas_chemm_64
    data["__cblas_chemm_64"] = <intptr_t>__cblas_chemm_64

    global __cblas_cherk_64
    data["__cblas_cherk_64"] = <intptr_t>__cblas_cherk_64

    global __cblas_cher2k_64
    data["__cblas_cher2k_64"] = <intptr_t>__cblas_cher2k_64

    global __cblas_zhemm_64
    data["__cblas_zhemm_64"] = <intptr_t>__cblas_zhemm_64

    global __cblas_zherk_64
    data["__cblas_zherk_64"] = <intptr_t>__cblas_zherk_64

    global __cblas_zher2k_64
    data["__cblas_zher2k_64"] = <intptr_t>__cblas_zher2k_64

    global __cblas_sgemmt_64
    data["__cblas_sgemmt_64"] = <intptr_t>__cblas_sgemmt_64

    global __cblas_dgemmt_64
    data["__cblas_dgemmt_64"] = <intptr_t>__cblas_dgemmt_64

    global __cblas_cgemmt_64
    data["__cblas_cgemmt_64"] = <intptr_t>__cblas_cgemmt_64

    global __cblas_zgemmt_64
    data["__cblas_zgemmt_64"] = <intptr_t>__cblas_zgemmt_64

    global __cblas_sgemm_batch_64
    data["__cblas_sgemm_batch_64"] = <intptr_t>__cblas_sgemm_batch_64

    global __cblas_dgemm_batch_64
    data["__cblas_dgemm_batch_64"] = <intptr_t>__cblas_dgemm_batch_64

    global __cblas_cgemm_batch_64
    data["__cblas_cgemm_batch_64"] = <intptr_t>__cblas_cgemm_batch_64

    global __cblas_zgemm_batch_64
    data["__cblas_zgemm_batch_64"] = <intptr_t>__cblas_zgemm_batch_64

    global __cblas_sgemm_batch_strided_64
    data["__cblas_sgemm_batch_strided_64"] = <intptr_t>__cblas_sgemm_batch_strided_64

    global __cblas_dgemm_batch_strided_64
    data["__cblas_dgemm_batch_strided_64"] = <intptr_t>__cblas_dgemm_batch_strided_64

    global __cblas_cgemm_batch_strided_64
    data["__cblas_cgemm_batch_strided_64"] = <intptr_t>__cblas_cgemm_batch_strided_64

    global __cblas_zgemm_batch_strided_64
    data["__cblas_zgemm_batch_strided_64"] = <intptr_t>__cblas_zgemm_batch_strided_64

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

cdef int _MKL_mkl_set_num_threads_local(int nth) except?-42 nogil:
    global __MKL_Set_Num_Threads_Local
    _check_or_init_nvpl_blas()
    if __MKL_Set_Num_Threads_Local == NULL:
        with gil:
            raise FunctionNotFoundError("function MKL_Set_Num_Threads_Local is not found")
    return (<int (*)(int) noexcept nogil>__MKL_Set_Num_Threads_Local)(
        nth)


@cython.show_performance_hints(False)
cdef void _MKL_mkl_set_num_threads(int nth) except* nogil:
    global __MKL_Set_Num_Threads
    _check_or_init_nvpl_blas()
    if __MKL_Set_Num_Threads == NULL:
        with gil:
            raise FunctionNotFoundError("function MKL_Set_Num_Threads is not found")
    (<void (*)(int) noexcept nogil>__MKL_Set_Num_Threads)(
        nth)


@cython.show_performance_hints(False)
cdef void _openblas_openblas_set_num_threads(int num_threads) except* nogil:
    global __openblas_set_num_threads
    _check_or_init_nvpl_blas()
    if __openblas_set_num_threads == NULL:
        with gil:
            raise FunctionNotFoundError("function openblas_set_num_threads is not found")
    (<void (*)(int) noexcept nogil>__openblas_set_num_threads)(
        num_threads)


cdef int _openblas_openblas_set_num_threads_local(int num_threads) except?-42 nogil:
    global __openblas_set_num_threads_local
    _check_or_init_nvpl_blas()
    if __openblas_set_num_threads_local == NULL:
        with gil:
            raise FunctionNotFoundError("function openblas_set_num_threads_local is not found")
    return (<int (*)(int) noexcept nogil>__openblas_set_num_threads_local)(
        num_threads)


cdef int _nvpl_blas_get_version() except?-42 nogil:
    global __nvpl_blas_get_version
    _check_or_init_nvpl_blas()
    if __nvpl_blas_get_version == NULL:
        with gil:
            raise FunctionNotFoundError("function nvpl_blas_get_version is not found")
    return (<int (*)() noexcept nogil>__nvpl_blas_get_version)(
        )


cdef int _nvpl_blas_get_max_threads() except?-42 nogil:
    global __nvpl_blas_get_max_threads
    _check_or_init_nvpl_blas()
    if __nvpl_blas_get_max_threads == NULL:
        with gil:
            raise FunctionNotFoundError("function nvpl_blas_get_max_threads is not found")
    return (<int (*)() noexcept nogil>__nvpl_blas_get_max_threads)(
        )


@cython.show_performance_hints(False)
cdef void _nvpl_blas_set_num_threads(int nthr) except* nogil:
    global __nvpl_blas_set_num_threads
    _check_or_init_nvpl_blas()
    if __nvpl_blas_set_num_threads == NULL:
        with gil:
            raise FunctionNotFoundError("function nvpl_blas_set_num_threads is not found")
    (<void (*)(int) noexcept nogil>__nvpl_blas_set_num_threads)(
        nthr)


cdef int _nvpl_blas_set_num_threads_local(int nthr_local) except?-42 nogil:
    global __nvpl_blas_set_num_threads_local
    _check_or_init_nvpl_blas()
    if __nvpl_blas_set_num_threads_local == NULL:
        with gil:
            raise FunctionNotFoundError("function nvpl_blas_set_num_threads_local is not found")
    return (<int (*)(int) noexcept nogil>__nvpl_blas_set_num_threads_local)(
        nthr_local)


@cython.show_performance_hints(False)
cdef void _cblas_sgemv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const float alpha, const float* A, const nvpl_int_t lda, const float* X, const nvpl_int_t incX, const float beta, float* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_sgemv
    _check_or_init_nvpl_blas()
    if __cblas_sgemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_sgemv)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sgbmv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t KL, const nvpl_int_t KU, const float alpha, const float* A, const nvpl_int_t lda, const float* X, const nvpl_int_t incX, const float beta, float* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_sgbmv
    _check_or_init_nvpl_blas()
    if __cblas_sgbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_sgbmv)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_strmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const float* A, const nvpl_int_t lda, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_strmv
    _check_or_init_nvpl_blas()
    if __cblas_strmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_strmv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const float* A, const nvpl_int_t lda, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_stbmv
    _check_or_init_nvpl_blas()
    if __cblas_stbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_stbmv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const float* Ap, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_stpmv
    _check_or_init_nvpl_blas()
    if __cblas_stpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const float*, float*, const nvpl_int_t) noexcept nogil>__cblas_stpmv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_strsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const float* A, const nvpl_int_t lda, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_strsv
    _check_or_init_nvpl_blas()
    if __cblas_strsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_strsv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stbsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const float* A, const nvpl_int_t lda, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_stbsv
    _check_or_init_nvpl_blas()
    if __cblas_stbsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stbsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_stbsv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stpsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const float* Ap, float* X, const nvpl_int_t incX) except* nogil:
    global __cblas_stpsv
    _check_or_init_nvpl_blas()
    if __cblas_stpsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stpsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const float*, float*, const nvpl_int_t) noexcept nogil>__cblas_stpsv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dgemv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const double alpha, const double* A, const nvpl_int_t lda, const double* X, const nvpl_int_t incX, const double beta, double* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_dgemv
    _check_or_init_nvpl_blas()
    if __cblas_dgemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dgemv)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dgbmv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t KL, const nvpl_int_t KU, const double alpha, const double* A, const nvpl_int_t lda, const double* X, const nvpl_int_t incX, const double beta, double* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_dgbmv
    _check_or_init_nvpl_blas()
    if __cblas_dgbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dgbmv)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dtrmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const double* A, const nvpl_int_t lda, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtrmv
    _check_or_init_nvpl_blas()
    if __cblas_dtrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtrmv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const double* A, const nvpl_int_t lda, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtbmv
    _check_or_init_nvpl_blas()
    if __cblas_dtbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtbmv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const double* Ap, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtpmv
    _check_or_init_nvpl_blas()
    if __cblas_dtpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const double*, double*, const nvpl_int_t) noexcept nogil>__cblas_dtpmv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtrsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const double* A, const nvpl_int_t lda, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtrsv
    _check_or_init_nvpl_blas()
    if __cblas_dtrsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtrsv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtbsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const double* A, const nvpl_int_t lda, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtbsv
    _check_or_init_nvpl_blas()
    if __cblas_dtbsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtbsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtbsv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtpsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const double* Ap, double* X, const nvpl_int_t incX) except* nogil:
    global __cblas_dtpsv
    _check_or_init_nvpl_blas()
    if __cblas_dtpsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtpsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const double*, double*, const nvpl_int_t) noexcept nogil>__cblas_dtpsv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_cgemv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_cgemv
    _check_or_init_nvpl_blas()
    if __cblas_cgemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_cgemv)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_cgbmv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t KL, const nvpl_int_t KU, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_cgbmv
    _check_or_init_nvpl_blas()
    if __cblas_cgbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_cgbmv)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ctrmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctrmv
    _check_or_init_nvpl_blas()
    if __cblas_ctrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctrmv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctbmv
    _check_or_init_nvpl_blas()
    if __cblas_ctbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctbmv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* Ap, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctpmv
    _check_or_init_nvpl_blas()
    if __cblas_ctpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_ctpmv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctrsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctrsv
    _check_or_init_nvpl_blas()
    if __cblas_ctrsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctrsv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctbsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctbsv
    _check_or_init_nvpl_blas()
    if __cblas_ctbsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctbsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctbsv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctpsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* Ap, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ctpsv
    _check_or_init_nvpl_blas()
    if __cblas_ctpsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctpsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_ctpsv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_zgemv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_zgemv
    _check_or_init_nvpl_blas()
    if __cblas_zgemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zgemv)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zgbmv(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t KL, const nvpl_int_t KU, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_zgbmv
    _check_or_init_nvpl_blas()
    if __cblas_zgbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zgbmv)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ztrmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztrmv
    _check_or_init_nvpl_blas()
    if __cblas_ztrmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztrmv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztbmv
    _check_or_init_nvpl_blas()
    if __cblas_ztbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztbmv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* Ap, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztpmv
    _check_or_init_nvpl_blas()
    if __cblas_ztpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_ztpmv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztrsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztrsv
    _check_or_init_nvpl_blas()
    if __cblas_ztrsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztrsv)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztbsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const nvpl_int_t K, const void* A, const nvpl_int_t lda, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztbsv
    _check_or_init_nvpl_blas()
    if __cblas_ztbsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztbsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztbsv)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztpsv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t N, const void* Ap, void* X, const nvpl_int_t incX) except* nogil:
    global __cblas_ztpsv
    _check_or_init_nvpl_blas()
    if __cblas_ztpsv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztpsv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_ztpsv)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ssymv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* A, const nvpl_int_t lda, const float* X, const nvpl_int_t incX, const float beta, float* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_ssymv
    _check_or_init_nvpl_blas()
    if __cblas_ssymv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssymv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_ssymv)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ssbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const float* X, const nvpl_int_t incX, const float beta, float* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_ssbmv
    _check_or_init_nvpl_blas()
    if __cblas_ssbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_ssbmv)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sspmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* Ap, const float* X, const nvpl_int_t incX, const float beta, float* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_sspmv
    _check_or_init_nvpl_blas()
    if __cblas_sspmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_sspmv)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sger(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const float alpha, const float* X, const nvpl_int_t incX, const float* Y, const nvpl_int_t incY, float* A, const nvpl_int_t lda) except* nogil:
    global __cblas_sger
    _check_or_init_nvpl_blas()
    if __cblas_sger == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sger is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_sger)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* X, const nvpl_int_t incX, float* A, const nvpl_int_t lda) except* nogil:
    global __cblas_ssyr
    _check_or_init_nvpl_blas()
    if __cblas_ssyr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_ssyr)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_sspr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* X, const nvpl_int_t incX, float* Ap) except* nogil:
    global __cblas_sspr
    _check_or_init_nvpl_blas()
    if __cblas_sspr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const nvpl_int_t, float*) noexcept nogil>__cblas_sspr)(
        order, Uplo, N, alpha, X, incX, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* X, const nvpl_int_t incX, const float* Y, const nvpl_int_t incY, float* A, const nvpl_int_t lda) except* nogil:
    global __cblas_ssyr2
    _check_or_init_nvpl_blas()
    if __cblas_ssyr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_ssyr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_sspr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const float* X, const nvpl_int_t incX, const float* Y, const nvpl_int_t incY, float* A) except* nogil:
    global __cblas_sspr2
    _check_or_init_nvpl_blas()
    if __cblas_sspr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, float*) noexcept nogil>__cblas_sspr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A)


@cython.show_performance_hints(False)
cdef void _cblas_dsymv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* A, const nvpl_int_t lda, const double* X, const nvpl_int_t incX, const double beta, double* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_dsymv
    _check_or_init_nvpl_blas()
    if __cblas_dsymv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsymv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dsymv)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dsbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const double* X, const nvpl_int_t incX, const double beta, double* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_dsbmv
    _check_or_init_nvpl_blas()
    if __cblas_dsbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dsbmv)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dspmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* Ap, const double* X, const nvpl_int_t incX, const double beta, double* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_dspmv
    _check_or_init_nvpl_blas()
    if __cblas_dspmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dspmv)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dger(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const double alpha, const double* X, const nvpl_int_t incX, const double* Y, const nvpl_int_t incY, double* A, const nvpl_int_t lda) except* nogil:
    global __cblas_dger
    _check_or_init_nvpl_blas()
    if __cblas_dger == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dger is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dger)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* X, const nvpl_int_t incX, double* A, const nvpl_int_t lda) except* nogil:
    global __cblas_dsyr
    _check_or_init_nvpl_blas()
    if __cblas_dsyr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dsyr)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dspr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* X, const nvpl_int_t incX, double* Ap) except* nogil:
    global __cblas_dspr
    _check_or_init_nvpl_blas()
    if __cblas_dspr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const nvpl_int_t, double*) noexcept nogil>__cblas_dspr)(
        order, Uplo, N, alpha, X, incX, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* X, const nvpl_int_t incX, const double* Y, const nvpl_int_t incY, double* A, const nvpl_int_t lda) except* nogil:
    global __cblas_dsyr2
    _check_or_init_nvpl_blas()
    if __cblas_dsyr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dsyr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dspr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const double* X, const nvpl_int_t incX, const double* Y, const nvpl_int_t incY, double* A) except* nogil:
    global __cblas_dspr2
    _check_or_init_nvpl_blas()
    if __cblas_dspr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, double*) noexcept nogil>__cblas_dspr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A)


@cython.show_performance_hints(False)
cdef void _cblas_chemv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_chemv
    _check_or_init_nvpl_blas()
    if __cblas_chemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_chemv)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_chbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_chbmv
    _check_or_init_nvpl_blas()
    if __cblas_chbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_chbmv)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_chpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* Ap, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_chpmv
    _check_or_init_nvpl_blas()
    if __cblas_chpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_chpmv)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_cgeru(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_cgeru
    _check_or_init_nvpl_blas()
    if __cblas_cgeru == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgeru is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_cgeru)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_cgerc(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_cgerc
    _check_or_init_nvpl_blas()
    if __cblas_cgerc == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgerc is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_cgerc)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_cher(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const void* X, const nvpl_int_t incX, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_cher
    _check_or_init_nvpl_blas()
    if __cblas_cher == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_cher)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_chpr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const float alpha, const void* X, const nvpl_int_t incX, void* A) except* nogil:
    global __cblas_chpr
    _check_or_init_nvpl_blas()
    if __cblas_chpr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const float, const void*, const nvpl_int_t, void*) noexcept nogil>__cblas_chpr)(
        order, Uplo, N, alpha, X, incX, A)


@cython.show_performance_hints(False)
cdef void _cblas_cher2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_cher2
    _check_or_init_nvpl_blas()
    if __cblas_cher2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_cher2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_chpr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* Ap) except* nogil:
    global __cblas_chpr2
    _check_or_init_nvpl_blas()
    if __cblas_chpr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*) noexcept nogil>__cblas_chpr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_zhemv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_zhemv
    _check_or_init_nvpl_blas()
    if __cblas_zhemv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhemv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zhemv)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zhbmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_zhbmv
    _check_or_init_nvpl_blas()
    if __cblas_zhbmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhbmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zhbmv)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zhpmv(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* Ap, const void* X, const nvpl_int_t incX, const void* beta, void* Y, const nvpl_int_t incY) except* nogil:
    global __cblas_zhpmv
    _check_or_init_nvpl_blas()
    if __cblas_zhpmv == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpmv is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zhpmv)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zgeru(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_zgeru
    _check_or_init_nvpl_blas()
    if __cblas_zgeru == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgeru is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_zgeru)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zgerc(const CBLAS_ORDER order, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_zgerc
    _check_or_init_nvpl_blas()
    if __cblas_zgerc == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgerc is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_zgerc)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zher(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const void* X, const nvpl_int_t incX, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_zher
    _check_or_init_nvpl_blas()
    if __cblas_zher == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_zher)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zhpr(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const double alpha, const void* X, const nvpl_int_t incX, void* A) except* nogil:
    global __cblas_zhpr
    _check_or_init_nvpl_blas()
    if __cblas_zhpr == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpr is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const double, const void*, const nvpl_int_t, void*) noexcept nogil>__cblas_zhpr)(
        order, Uplo, N, alpha, X, incX, A)


@cython.show_performance_hints(False)
cdef void _cblas_zher2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* A, const nvpl_int_t lda) except* nogil:
    global __cblas_zher2
    _check_or_init_nvpl_blas()
    if __cblas_zher2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_zher2)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zhpr2(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int_t N, const void* alpha, const void* X, const nvpl_int_t incX, const void* Y, const nvpl_int_t incY, void* Ap) except* nogil:
    global __cblas_zhpr2
    _check_or_init_nvpl_blas()
    if __cblas_zhpr2 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpr2 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, void*) noexcept nogil>__cblas_zhpr2)(
        order, Uplo, N, alpha, X, incX, Y, incY, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const float* B, const nvpl_int_t ldb, const float beta, float* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_sgemm
    _check_or_init_nvpl_blas()
    if __cblas_sgemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_sgemm)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssymm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const float alpha, const float* A, const nvpl_int_t lda, const float* B, const nvpl_int_t ldb, const float beta, float* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_ssymm
    _check_or_init_nvpl_blas()
    if __cblas_ssymm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssymm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_ssymm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssyrk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const float beta, float* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_ssyrk
    _check_or_init_nvpl_blas()
    if __cblas_ssyrk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyrk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_ssyrk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const float* B, const nvpl_int_t ldb, const float beta, float* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_ssyr2k
    _check_or_init_nvpl_blas()
    if __cblas_ssyr2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_ssyr2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_strmm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const float alpha, const float* A, const nvpl_int_t lda, float* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_strmm
    _check_or_init_nvpl_blas()
    if __cblas_strmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strmm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_strmm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_strsm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const float alpha, const float* A, const nvpl_int_t lda, float* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_strsm
    _check_or_init_nvpl_blas()
    if __cblas_strsm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strsm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, float*, const nvpl_int_t) noexcept nogil>__cblas_strsm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const double* B, const nvpl_int_t ldb, const double beta, double* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_dgemm
    _check_or_init_nvpl_blas()
    if __cblas_dgemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dgemm)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsymm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const double alpha, const double* A, const nvpl_int_t lda, const double* B, const nvpl_int_t ldb, const double beta, double* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_dsymm
    _check_or_init_nvpl_blas()
    if __cblas_dsymm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsymm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dsymm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsyrk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const double beta, double* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_dsyrk
    _check_or_init_nvpl_blas()
    if __cblas_dsyrk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyrk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dsyrk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const double* B, const nvpl_int_t ldb, const double beta, double* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_dsyr2k
    _check_or_init_nvpl_blas()
    if __cblas_dsyr2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dsyr2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dtrmm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const double alpha, const double* A, const nvpl_int_t lda, double* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_dtrmm
    _check_or_init_nvpl_blas()
    if __cblas_dtrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrmm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtrmm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_dtrsm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const double alpha, const double* A, const nvpl_int_t lda, double* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_dtrsm
    _check_or_init_nvpl_blas()
    if __cblas_dtrsm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrsm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, double*, const nvpl_int_t) noexcept nogil>__cblas_dtrsm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_cgemm
    _check_or_init_nvpl_blas()
    if __cblas_cgemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_cgemm)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csymm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_csymm
    _check_or_init_nvpl_blas()
    if __cblas_csymm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csymm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_csymm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csyrk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_csyrk
    _check_or_init_nvpl_blas()
    if __cblas_csyrk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csyrk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_csyrk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csyr2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_csyr2k
    _check_or_init_nvpl_blas()
    if __cblas_csyr2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csyr2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_csyr2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ctrmm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, void* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_ctrmm
    _check_or_init_nvpl_blas()
    if __cblas_ctrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrmm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctrmm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_ctrsm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, void* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_ctrsm
    _check_or_init_nvpl_blas()
    if __cblas_ctrsm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrsm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ctrsm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zgemm
    _check_or_init_nvpl_blas()
    if __cblas_zgemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zgemm)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsymm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zsymm
    _check_or_init_nvpl_blas()
    if __cblas_zsymm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsymm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zsymm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsyrk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zsyrk
    _check_or_init_nvpl_blas()
    if __cblas_zsyrk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsyrk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zsyrk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsyr2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zsyr2k
    _check_or_init_nvpl_blas()
    if __cblas_zsyr2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsyr2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zsyr2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ztrmm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, void* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_ztrmm
    _check_or_init_nvpl_blas()
    if __cblas_ztrmm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrmm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztrmm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_ztrsm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, void* B, const nvpl_int_t ldb) except* nogil:
    global __cblas_ztrsm
    _check_or_init_nvpl_blas()
    if __cblas_ztrsm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrsm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, void*, const nvpl_int_t) noexcept nogil>__cblas_ztrsm)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_chemm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_chemm
    _check_or_init_nvpl_blas()
    if __cblas_chemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_chemm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cherk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const void* A, const nvpl_int_t lda, const float beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_cherk
    _check_or_init_nvpl_blas()
    if __cblas_cherk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cherk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const float, const void*, const nvpl_int_t, const float, void*, const nvpl_int_t) noexcept nogil>__cblas_cherk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cher2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const float beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_cher2k
    _check_or_init_nvpl_blas()
    if __cblas_cher2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const float, void*, const nvpl_int_t) noexcept nogil>__cblas_cher2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zhemm(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int_t M, const nvpl_int_t N, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zhemm
    _check_or_init_nvpl_blas()
    if __cblas_zhemm == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhemm is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zhemm)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zherk(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const void* A, const nvpl_int_t lda, const double beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zherk
    _check_or_init_nvpl_blas()
    if __cblas_zherk == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zherk is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const double, const void*, const nvpl_int_t, const double, void*, const nvpl_int_t) noexcept nogil>__cblas_zherk)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zher2k(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const double beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zher2k
    _check_or_init_nvpl_blas()
    if __cblas_zher2k == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher2k is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const double, void*, const nvpl_int_t) noexcept nogil>__cblas_zher2k)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm_batch(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int_t* M_array, nvpl_int_t* N_array, nvpl_int_t* K_array, const float* alpha_array, const float** A_array, nvpl_int_t* lda_array, const float** B_array, nvpl_int_t* ldb_array, const float* beta_array, float** C_array, nvpl_int_t* ldc_array, nvpl_int_t group_count, nvpl_int_t* group_size) except* nogil:
    global __cblas_sgemm_batch
    _check_or_init_nvpl_blas()
    if __cblas_sgemm_batch == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm_batch is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int_t*, nvpl_int_t*, nvpl_int_t*, const float*, const float**, nvpl_int_t*, const float**, nvpl_int_t*, const float*, float**, nvpl_int_t*, nvpl_int_t, nvpl_int_t*) noexcept nogil>__cblas_sgemm_batch)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm_batch(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int_t* M_array, nvpl_int_t* N_array, nvpl_int_t* K_array, const double* alpha_array, const double** A_array, nvpl_int_t* lda_array, const double** B_array, nvpl_int_t* ldb_array, const double* beta_array, double** C_array, nvpl_int_t* ldc_array, nvpl_int_t group_count, nvpl_int_t* group_size) except* nogil:
    global __cblas_dgemm_batch
    _check_or_init_nvpl_blas()
    if __cblas_dgemm_batch == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm_batch is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int_t*, nvpl_int_t*, nvpl_int_t*, const double*, const double**, nvpl_int_t*, const double**, nvpl_int_t*, const double*, double**, nvpl_int_t*, nvpl_int_t, nvpl_int_t*) noexcept nogil>__cblas_dgemm_batch)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm_batch(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int_t* M_array, nvpl_int_t* N_array, nvpl_int_t* K_array, const void* alpha_array, const void** A_array, nvpl_int_t* lda_array, const void** B_array, nvpl_int_t* ldb_array, const void* beta_array, void** C_array, nvpl_int_t* ldc_array, nvpl_int_t group_count, nvpl_int_t* group_size) except* nogil:
    global __cblas_cgemm_batch
    _check_or_init_nvpl_blas()
    if __cblas_cgemm_batch == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm_batch is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int_t*, nvpl_int_t*, nvpl_int_t*, const void*, const void**, nvpl_int_t*, const void**, nvpl_int_t*, const void*, void**, nvpl_int_t*, nvpl_int_t, nvpl_int_t*) noexcept nogil>__cblas_cgemm_batch)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm_batch(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int_t* M_array, nvpl_int_t* N_array, nvpl_int_t* K_array, const void* alpha_array, const void** A_array, nvpl_int_t* lda_array, const void** B_array, nvpl_int_t* ldb_array, const void* beta_array, void** C_array, nvpl_int_t* ldc_array, nvpl_int_t group_count, nvpl_int_t* group_size) except* nogil:
    global __cblas_zgemm_batch
    _check_or_init_nvpl_blas()
    if __cblas_zgemm_batch == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm_batch is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int_t*, nvpl_int_t*, nvpl_int_t*, const void*, const void**, nvpl_int_t*, const void**, nvpl_int_t*, const void*, void**, nvpl_int_t*, nvpl_int_t, nvpl_int_t*) noexcept nogil>__cblas_zgemm_batch)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm_batch_strided(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const nvpl_int_t stridea, const float* B, const nvpl_int_t ldb, const nvpl_int_t strideb, const float beta, float* C, const nvpl_int_t ldc, const nvpl_int_t stridec, const nvpl_int_t batch_size) except* nogil:
    global __cblas_sgemm_batch_strided
    _check_or_init_nvpl_blas()
    if __cblas_sgemm_batch_strided == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm_batch_strided is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const nvpl_int_t, const float*, const nvpl_int_t, const nvpl_int_t, const float, float*, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t) noexcept nogil>__cblas_sgemm_batch_strided)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm_batch_strided(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const nvpl_int_t stridea, const double* B, const nvpl_int_t ldb, const nvpl_int_t strideb, const double beta, double* C, const nvpl_int_t ldc, const nvpl_int_t stridec, const nvpl_int_t batch_size) except* nogil:
    global __cblas_dgemm_batch_strided
    _check_or_init_nvpl_blas()
    if __cblas_dgemm_batch_strided == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm_batch_strided is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const nvpl_int_t, const double*, const nvpl_int_t, const nvpl_int_t, const double, double*, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t) noexcept nogil>__cblas_dgemm_batch_strided)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm_batch_strided(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const nvpl_int_t stridea, const void* B, const nvpl_int_t ldb, const nvpl_int_t strideb, const void* beta, void* C, const nvpl_int_t ldc, const nvpl_int_t stridec, const nvpl_int_t batch_size) except* nogil:
    global __cblas_cgemm_batch_strided
    _check_or_init_nvpl_blas()
    if __cblas_cgemm_batch_strided == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm_batch_strided is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, const nvpl_int_t, const void*, void*, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t) noexcept nogil>__cblas_cgemm_batch_strided)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm_batch_strided(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t M, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const nvpl_int_t stridea, const void* B, const nvpl_int_t ldb, const nvpl_int_t strideb, const void* beta, void* C, const nvpl_int_t ldc, const nvpl_int_t stridec, const nvpl_int_t batch_size) except* nogil:
    global __cblas_zgemm_batch_strided
    _check_or_init_nvpl_blas()
    if __cblas_zgemm_batch_strided == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm_batch_strided is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const nvpl_int_t, const void*, const nvpl_int_t, const nvpl_int_t, const void*, void*, const nvpl_int_t, const nvpl_int_t, const nvpl_int_t) noexcept nogil>__cblas_zgemm_batch_strided)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_sgemmt(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t N, const nvpl_int_t K, const float alpha, const float* A, const nvpl_int_t lda, const float* B, const nvpl_int_t ldb, const float beta, float* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_sgemmt
    _check_or_init_nvpl_blas()
    if __cblas_sgemmt == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemmt is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const float, const float*, const nvpl_int_t, const float*, const nvpl_int_t, const float, float*, const nvpl_int_t) noexcept nogil>__cblas_sgemmt)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dgemmt(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t N, const nvpl_int_t K, const double alpha, const double* A, const nvpl_int_t lda, const double* B, const nvpl_int_t ldb, const double beta, double* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_dgemmt
    _check_or_init_nvpl_blas()
    if __cblas_dgemmt == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemmt is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const double, const double*, const nvpl_int_t, const double*, const nvpl_int_t, const double, double*, const nvpl_int_t) noexcept nogil>__cblas_dgemmt)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cgemmt(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_cgemmt
    _check_or_init_nvpl_blas()
    if __cblas_cgemmt == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemmt is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_cgemmt)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zgemmt(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int_t N, const nvpl_int_t K, const void* alpha, const void* A, const nvpl_int_t lda, const void* B, const nvpl_int_t ldb, const void* beta, void* C, const nvpl_int_t ldc) except* nogil:
    global __cblas_zgemmt
    _check_or_init_nvpl_blas()
    if __cblas_zgemmt == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemmt is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int_t, const nvpl_int_t, const void*, const void*, const nvpl_int_t, const void*, const nvpl_int_t, const void*, void*, const nvpl_int_t) noexcept nogil>__cblas_zgemmt)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_sgemv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const float alpha, const float* A, const nvpl_int64_t lda, const float* X, const nvpl_int64_t incX, const float beta, float* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_sgemv_64
    _check_or_init_nvpl_blas()
    if __cblas_sgemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_sgemv_64)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sgbmv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t KL, const nvpl_int64_t KU, const float alpha, const float* A, const nvpl_int64_t lda, const float* X, const nvpl_int64_t incX, const float beta, float* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_sgbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_sgbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_sgbmv_64)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_strmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const float* A, const nvpl_int64_t lda, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_strmv_64
    _check_or_init_nvpl_blas()
    if __cblas_strmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_strmv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const float* A, const nvpl_int64_t lda, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_stbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_stbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_stbmv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const float* Ap, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_stpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_stpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const float*, float*, const nvpl_int64_t) noexcept nogil>__cblas_stpmv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_strsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const float* A, const nvpl_int64_t lda, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_strsv_64
    _check_or_init_nvpl_blas()
    if __cblas_strsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_strsv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stbsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const float* A, const nvpl_int64_t lda, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_stbsv_64
    _check_or_init_nvpl_blas()
    if __cblas_stbsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stbsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_stbsv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_stpsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const float* Ap, float* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_stpsv_64
    _check_or_init_nvpl_blas()
    if __cblas_stpsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_stpsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const float*, float*, const nvpl_int64_t) noexcept nogil>__cblas_stpsv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dgemv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const double alpha, const double* A, const nvpl_int64_t lda, const double* X, const nvpl_int64_t incX, const double beta, double* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_dgemv_64
    _check_or_init_nvpl_blas()
    if __cblas_dgemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dgemv_64)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dgbmv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t KL, const nvpl_int64_t KU, const double alpha, const double* A, const nvpl_int64_t lda, const double* X, const nvpl_int64_t incX, const double beta, double* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_dgbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dgbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dgbmv_64)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dtrmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const double* A, const nvpl_int64_t lda, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtrmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtrmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtrmv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const double* A, const nvpl_int64_t lda, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtbmv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const double* Ap, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const double*, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtpmv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtrsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const double* A, const nvpl_int64_t lda, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtrsv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtrsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtrsv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtbsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const double* A, const nvpl_int64_t lda, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtbsv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtbsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtbsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtbsv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_dtpsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const double* Ap, double* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_dtpsv_64
    _check_or_init_nvpl_blas()
    if __cblas_dtpsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtpsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const double*, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtpsv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_cgemv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_cgemv_64
    _check_or_init_nvpl_blas()
    if __cblas_cgemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgemv_64)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_cgbmv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t KL, const nvpl_int64_t KU, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_cgbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_cgbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgbmv_64)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ctrmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctrmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctrmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctrmv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctbmv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* Ap, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctpmv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctrsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctrsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctrsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctrsv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctbsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctbsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctbsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctbsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctbsv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ctpsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* Ap, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ctpsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ctpsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctpsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctpsv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_zgemv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_zgemv_64
    _check_or_init_nvpl_blas()
    if __cblas_zgemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgemv_64)(
        order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zgbmv_64(const CBLAS_ORDER order, const CBLAS_TRANSPOSE TransA, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t KL, const nvpl_int64_t KU, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_zgbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_zgbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgbmv_64)(
        order, TransA, M, N, KL, KU, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ztrmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztrmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztrmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztrmv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztbmv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* Ap, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztpmv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztrsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztrsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztrsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztrsv_64)(
        order, Uplo, TransA, Diag, N, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztbsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const nvpl_int64_t K, const void* A, const nvpl_int64_t lda, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztbsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztbsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztbsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztbsv_64)(
        order, Uplo, TransA, Diag, N, K, A, lda, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ztpsv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t N, const void* Ap, void* X, const nvpl_int64_t incX) except* nogil:
    global __cblas_ztpsv_64
    _check_or_init_nvpl_blas()
    if __cblas_ztpsv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztpsv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztpsv_64)(
        order, Uplo, TransA, Diag, N, Ap, X, incX)


@cython.show_performance_hints(False)
cdef void _cblas_ssymv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* A, const nvpl_int64_t lda, const float* X, const nvpl_int64_t incX, const float beta, float* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_ssymv_64
    _check_or_init_nvpl_blas()
    if __cblas_ssymv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssymv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssymv_64)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_ssbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const float* X, const nvpl_int64_t incX, const float beta, float* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_ssbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_ssbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssbmv_64)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sspmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* Ap, const float* X, const nvpl_int64_t incX, const float beta, float* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_sspmv_64
    _check_or_init_nvpl_blas()
    if __cblas_sspmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_sspmv_64)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_sger_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const float alpha, const float* X, const nvpl_int64_t incX, const float* Y, const nvpl_int64_t incY, float* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_sger_64
    _check_or_init_nvpl_blas()
    if __cblas_sger_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sger_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_sger_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* X, const nvpl_int64_t incX, float* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_ssyr_64
    _check_or_init_nvpl_blas()
    if __cblas_ssyr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssyr_64)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_sspr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* X, const nvpl_int64_t incX, float* Ap) except* nogil:
    global __cblas_sspr_64
    _check_or_init_nvpl_blas()
    if __cblas_sspr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, float*) noexcept nogil>__cblas_sspr_64)(
        order, Uplo, N, alpha, X, incX, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* X, const nvpl_int64_t incX, const float* Y, const nvpl_int64_t incY, float* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_ssyr2_64
    _check_or_init_nvpl_blas()
    if __cblas_ssyr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssyr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_sspr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const float* X, const nvpl_int64_t incX, const float* Y, const nvpl_int64_t incY, float* A) except* nogil:
    global __cblas_sspr2_64
    _check_or_init_nvpl_blas()
    if __cblas_sspr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sspr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, float*) noexcept nogil>__cblas_sspr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A)


@cython.show_performance_hints(False)
cdef void _cblas_dsymv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* A, const nvpl_int64_t lda, const double* X, const nvpl_int64_t incX, const double beta, double* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_dsymv_64
    _check_or_init_nvpl_blas()
    if __cblas_dsymv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsymv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsymv_64)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dsbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const double* X, const nvpl_int64_t incX, const double beta, double* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_dsbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dsbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsbmv_64)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dspmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* Ap, const double* X, const nvpl_int64_t incX, const double beta, double* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_dspmv_64
    _check_or_init_nvpl_blas()
    if __cblas_dspmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dspmv_64)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_dger_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const double alpha, const double* X, const nvpl_int64_t incX, const double* Y, const nvpl_int64_t incY, double* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_dger_64
    _check_or_init_nvpl_blas()
    if __cblas_dger_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dger_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dger_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* X, const nvpl_int64_t incX, double* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_dsyr_64
    _check_or_init_nvpl_blas()
    if __cblas_dsyr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsyr_64)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dspr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* X, const nvpl_int64_t incX, double* Ap) except* nogil:
    global __cblas_dspr_64
    _check_or_init_nvpl_blas()
    if __cblas_dspr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, double*) noexcept nogil>__cblas_dspr_64)(
        order, Uplo, N, alpha, X, incX, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* X, const nvpl_int64_t incX, const double* Y, const nvpl_int64_t incY, double* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_dsyr2_64
    _check_or_init_nvpl_blas()
    if __cblas_dsyr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsyr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_dspr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const double* X, const nvpl_int64_t incX, const double* Y, const nvpl_int64_t incY, double* A) except* nogil:
    global __cblas_dspr2_64
    _check_or_init_nvpl_blas()
    if __cblas_dspr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dspr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, double*) noexcept nogil>__cblas_dspr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A)


@cython.show_performance_hints(False)
cdef void _cblas_chemv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_chemv_64
    _check_or_init_nvpl_blas()
    if __cblas_chemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_chemv_64)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_chbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_chbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_chbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_chbmv_64)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_chpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* Ap, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_chpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_chpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_chpmv_64)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_cgeru_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_cgeru_64
    _check_or_init_nvpl_blas()
    if __cblas_cgeru_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgeru_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgeru_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_cgerc_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_cgerc_64
    _check_or_init_nvpl_blas()
    if __cblas_cgerc_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgerc_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgerc_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_cher_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const void* X, const nvpl_int64_t incX, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_cher_64
    _check_or_init_nvpl_blas()
    if __cblas_cher_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_cher_64)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_chpr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const float alpha, const void* X, const nvpl_int64_t incX, void* A) except* nogil:
    global __cblas_chpr_64
    _check_or_init_nvpl_blas()
    if __cblas_chpr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const float, const void*, const nvpl_int64_t, void*) noexcept nogil>__cblas_chpr_64)(
        order, Uplo, N, alpha, X, incX, A)


@cython.show_performance_hints(False)
cdef void _cblas_cher2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_cher2_64
    _check_or_init_nvpl_blas()
    if __cblas_cher2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_cher2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_chpr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* Ap) except* nogil:
    global __cblas_chpr2_64
    _check_or_init_nvpl_blas()
    if __cblas_chpr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chpr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*) noexcept nogil>__cblas_chpr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_zhemv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_zhemv_64
    _check_or_init_nvpl_blas()
    if __cblas_zhemv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhemv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zhemv_64)(
        order, Uplo, N, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zhbmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_zhbmv_64
    _check_or_init_nvpl_blas()
    if __cblas_zhbmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhbmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zhbmv_64)(
        order, Uplo, N, K, alpha, A, lda, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zhpmv_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* Ap, const void* X, const nvpl_int64_t incX, const void* beta, void* Y, const nvpl_int64_t incY) except* nogil:
    global __cblas_zhpmv_64
    _check_or_init_nvpl_blas()
    if __cblas_zhpmv_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpmv_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zhpmv_64)(
        order, Uplo, N, alpha, Ap, X, incX, beta, Y, incY)


@cython.show_performance_hints(False)
cdef void _cblas_zgeru_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_zgeru_64
    _check_or_init_nvpl_blas()
    if __cblas_zgeru_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgeru_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgeru_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zgerc_64(const CBLAS_ORDER order, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_zgerc_64
    _check_or_init_nvpl_blas()
    if __cblas_zgerc_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgerc_64 is not found")
    (<void (*)(const CBLAS_ORDER, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgerc_64)(
        order, M, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zher_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const void* X, const nvpl_int64_t incX, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_zher_64
    _check_or_init_nvpl_blas()
    if __cblas_zher_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_zher_64)(
        order, Uplo, N, alpha, X, incX, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zhpr_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const double alpha, const void* X, const nvpl_int64_t incX, void* A) except* nogil:
    global __cblas_zhpr_64
    _check_or_init_nvpl_blas()
    if __cblas_zhpr_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpr_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const double, const void*, const nvpl_int64_t, void*) noexcept nogil>__cblas_zhpr_64)(
        order, Uplo, N, alpha, X, incX, A)


@cython.show_performance_hints(False)
cdef void _cblas_zher2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* A, const nvpl_int64_t lda) except* nogil:
    global __cblas_zher2_64
    _check_or_init_nvpl_blas()
    if __cblas_zher2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_zher2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, A, lda)


@cython.show_performance_hints(False)
cdef void _cblas_zhpr2_64(const CBLAS_ORDER order, const CBLAS_UPLO Uplo, const nvpl_int64_t N, const void* alpha, const void* X, const nvpl_int64_t incX, const void* Y, const nvpl_int64_t incY, void* Ap) except* nogil:
    global __cblas_zhpr2_64
    _check_or_init_nvpl_blas()
    if __cblas_zhpr2_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhpr2_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, void*) noexcept nogil>__cblas_zhpr2_64)(
        order, Uplo, N, alpha, X, incX, Y, incY, Ap)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const float* B, const nvpl_int64_t ldb, const float beta, float* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_sgemm_64
    _check_or_init_nvpl_blas()
    if __cblas_sgemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_sgemm_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssymm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const float alpha, const float* A, const nvpl_int64_t lda, const float* B, const nvpl_int64_t ldb, const float beta, float* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_ssymm_64
    _check_or_init_nvpl_blas()
    if __cblas_ssymm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssymm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssymm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssyrk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const float beta, float* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_ssyrk_64
    _check_or_init_nvpl_blas()
    if __cblas_ssyrk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyrk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssyrk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ssyr2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const float* B, const nvpl_int64_t ldb, const float beta, float* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_ssyr2k_64
    _check_or_init_nvpl_blas()
    if __cblas_ssyr2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ssyr2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_ssyr2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_strmm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const float alpha, const float* A, const nvpl_int64_t lda, float* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_strmm_64
    _check_or_init_nvpl_blas()
    if __cblas_strmm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strmm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_strmm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_strsm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const float alpha, const float* A, const nvpl_int64_t lda, float* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_strsm_64
    _check_or_init_nvpl_blas()
    if __cblas_strsm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_strsm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, float*, const nvpl_int64_t) noexcept nogil>__cblas_strsm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const double* B, const nvpl_int64_t ldb, const double beta, double* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_dgemm_64
    _check_or_init_nvpl_blas()
    if __cblas_dgemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dgemm_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsymm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const double alpha, const double* A, const nvpl_int64_t lda, const double* B, const nvpl_int64_t ldb, const double beta, double* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_dsymm_64
    _check_or_init_nvpl_blas()
    if __cblas_dsymm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsymm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsymm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsyrk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const double beta, double* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_dsyrk_64
    _check_or_init_nvpl_blas()
    if __cblas_dsyrk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyrk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsyrk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dsyr2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const double* B, const nvpl_int64_t ldb, const double beta, double* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_dsyr2k_64
    _check_or_init_nvpl_blas()
    if __cblas_dsyr2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dsyr2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dsyr2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dtrmm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const double alpha, const double* A, const nvpl_int64_t lda, double* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_dtrmm_64
    _check_or_init_nvpl_blas()
    if __cblas_dtrmm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrmm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtrmm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_dtrsm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const double alpha, const double* A, const nvpl_int64_t lda, double* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_dtrsm_64
    _check_or_init_nvpl_blas()
    if __cblas_dtrsm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dtrsm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, double*, const nvpl_int64_t) noexcept nogil>__cblas_dtrsm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_cgemm_64
    _check_or_init_nvpl_blas()
    if __cblas_cgemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgemm_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csymm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_csymm_64
    _check_or_init_nvpl_blas()
    if __cblas_csymm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csymm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_csymm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csyrk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_csyrk_64
    _check_or_init_nvpl_blas()
    if __cblas_csyrk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csyrk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_csyrk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_csyr2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_csyr2k_64
    _check_or_init_nvpl_blas()
    if __cblas_csyr2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_csyr2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_csyr2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ctrmm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, void* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_ctrmm_64
    _check_or_init_nvpl_blas()
    if __cblas_ctrmm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrmm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctrmm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_ctrsm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, void* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_ctrsm_64
    _check_or_init_nvpl_blas()
    if __cblas_ctrsm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ctrsm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ctrsm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zgemm_64
    _check_or_init_nvpl_blas()
    if __cblas_zgemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgemm_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsymm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zsymm_64
    _check_or_init_nvpl_blas()
    if __cblas_zsymm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsymm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zsymm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsyrk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zsyrk_64
    _check_or_init_nvpl_blas()
    if __cblas_zsyrk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsyrk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zsyrk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zsyr2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zsyr2k_64
    _check_or_init_nvpl_blas()
    if __cblas_zsyr2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zsyr2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zsyr2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_ztrmm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, void* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_ztrmm_64
    _check_or_init_nvpl_blas()
    if __cblas_ztrmm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrmm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztrmm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_ztrsm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_DIAG Diag, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, void* B, const nvpl_int64_t ldb) except* nogil:
    global __cblas_ztrsm_64
    _check_or_init_nvpl_blas()
    if __cblas_ztrsm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_ztrsm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_DIAG, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, void*, const nvpl_int64_t) noexcept nogil>__cblas_ztrsm_64)(
        Order, Side, Uplo, TransA, Diag, M, N, alpha, A, lda, B, ldb)


@cython.show_performance_hints(False)
cdef void _cblas_chemm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_chemm_64
    _check_or_init_nvpl_blas()
    if __cblas_chemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_chemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_chemm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cherk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const void* A, const nvpl_int64_t lda, const float beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_cherk_64
    _check_or_init_nvpl_blas()
    if __cblas_cherk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cherk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const float, const void*, const nvpl_int64_t, const float, void*, const nvpl_int64_t) noexcept nogil>__cblas_cherk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cher2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const float beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_cher2k_64
    _check_or_init_nvpl_blas()
    if __cblas_cher2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cher2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const float, void*, const nvpl_int64_t) noexcept nogil>__cblas_cher2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zhemm_64(const CBLAS_ORDER Order, const CBLAS_SIDE Side, const CBLAS_UPLO Uplo, const nvpl_int64_t M, const nvpl_int64_t N, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zhemm_64
    _check_or_init_nvpl_blas()
    if __cblas_zhemm_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zhemm_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_SIDE, const CBLAS_UPLO, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zhemm_64)(
        Order, Side, Uplo, M, N, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zherk_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const void* A, const nvpl_int64_t lda, const double beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zherk_64
    _check_or_init_nvpl_blas()
    if __cblas_zherk_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zherk_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const double, const void*, const nvpl_int64_t, const double, void*, const nvpl_int64_t) noexcept nogil>__cblas_zherk_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zher2k_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE Trans, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const double beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zher2k_64
    _check_or_init_nvpl_blas()
    if __cblas_zher2k_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zher2k_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const double, void*, const nvpl_int64_t) noexcept nogil>__cblas_zher2k_64)(
        Order, Uplo, Trans, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_sgemmt_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const float* B, const nvpl_int64_t ldb, const float beta, float* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_sgemmt_64
    _check_or_init_nvpl_blas()
    if __cblas_sgemmt_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemmt_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const float*, const nvpl_int64_t, const float, float*, const nvpl_int64_t) noexcept nogil>__cblas_sgemmt_64)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_dgemmt_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const double* B, const nvpl_int64_t ldb, const double beta, double* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_dgemmt_64
    _check_or_init_nvpl_blas()
    if __cblas_dgemmt_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemmt_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const double*, const nvpl_int64_t, const double, double*, const nvpl_int64_t) noexcept nogil>__cblas_dgemmt_64)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_cgemmt_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_cgemmt_64
    _check_or_init_nvpl_blas()
    if __cblas_cgemmt_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemmt_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_cgemmt_64)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_zgemmt_64(const CBLAS_ORDER Order, const CBLAS_UPLO Uplo, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const void* B, const nvpl_int64_t ldb, const void* beta, void* C, const nvpl_int64_t ldc) except* nogil:
    global __cblas_zgemmt_64
    _check_or_init_nvpl_blas()
    if __cblas_zgemmt_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemmt_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_UPLO, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const void*, const nvpl_int64_t, const void*, void*, const nvpl_int64_t) noexcept nogil>__cblas_zgemmt_64)(
        Order, Uplo, TransA, TransB, N, K, alpha, A, lda, B, ldb, beta, C, ldc)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm_batch_64(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int64_t* M_array, nvpl_int64_t* N_array, nvpl_int64_t* K_array, const float* alpha_array, const float** A_array, nvpl_int64_t* lda_array, const float** B_array, nvpl_int64_t* ldb_array, const float* beta_array, float** C_array, nvpl_int64_t* ldc_array, nvpl_int64_t group_count, nvpl_int64_t* group_size) except* nogil:
    global __cblas_sgemm_batch_64
    _check_or_init_nvpl_blas()
    if __cblas_sgemm_batch_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm_batch_64 is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int64_t*, nvpl_int64_t*, nvpl_int64_t*, const float*, const float**, nvpl_int64_t*, const float**, nvpl_int64_t*, const float*, float**, nvpl_int64_t*, nvpl_int64_t, nvpl_int64_t*) noexcept nogil>__cblas_sgemm_batch_64)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm_batch_64(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int64_t* M_array, nvpl_int64_t* N_array, nvpl_int64_t* K_array, const double* alpha_array, const double** A_array, nvpl_int64_t* lda_array, const double** B_array, nvpl_int64_t* ldb_array, const double* beta_array, double** C_array, nvpl_int64_t* ldc_array, nvpl_int64_t group_count, nvpl_int64_t* group_size) except* nogil:
    global __cblas_dgemm_batch_64
    _check_or_init_nvpl_blas()
    if __cblas_dgemm_batch_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm_batch_64 is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int64_t*, nvpl_int64_t*, nvpl_int64_t*, const double*, const double**, nvpl_int64_t*, const double**, nvpl_int64_t*, const double*, double**, nvpl_int64_t*, nvpl_int64_t, nvpl_int64_t*) noexcept nogil>__cblas_dgemm_batch_64)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm_batch_64(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int64_t* M_array, nvpl_int64_t* N_array, nvpl_int64_t* K_array, const void* alpha_array, const void** A_array, nvpl_int64_t* lda_array, const void** B_array, nvpl_int64_t* ldb_array, const void* beta_array, void** C_array, nvpl_int64_t* ldc_array, nvpl_int64_t group_count, nvpl_int64_t* group_size) except* nogil:
    global __cblas_cgemm_batch_64
    _check_or_init_nvpl_blas()
    if __cblas_cgemm_batch_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm_batch_64 is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int64_t*, nvpl_int64_t*, nvpl_int64_t*, const void*, const void**, nvpl_int64_t*, const void**, nvpl_int64_t*, const void*, void**, nvpl_int64_t*, nvpl_int64_t, nvpl_int64_t*) noexcept nogil>__cblas_cgemm_batch_64)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm_batch_64(CBLAS_ORDER Order, CBLAS_TRANSPOSE* TransA_array, CBLAS_TRANSPOSE* TransB_array, nvpl_int64_t* M_array, nvpl_int64_t* N_array, nvpl_int64_t* K_array, const void* alpha_array, const void** A_array, nvpl_int64_t* lda_array, const void** B_array, nvpl_int64_t* ldb_array, const void* beta_array, void** C_array, nvpl_int64_t* ldc_array, nvpl_int64_t group_count, nvpl_int64_t* group_size) except* nogil:
    global __cblas_zgemm_batch_64
    _check_or_init_nvpl_blas()
    if __cblas_zgemm_batch_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm_batch_64 is not found")
    (<void (*)(CBLAS_ORDER, CBLAS_TRANSPOSE*, CBLAS_TRANSPOSE*, nvpl_int64_t*, nvpl_int64_t*, nvpl_int64_t*, const void*, const void**, nvpl_int64_t*, const void**, nvpl_int64_t*, const void*, void**, nvpl_int64_t*, nvpl_int64_t, nvpl_int64_t*) noexcept nogil>__cblas_zgemm_batch_64)(
        Order, TransA_array, TransB_array, M_array, N_array, K_array, alpha_array, A_array, lda_array, B_array, ldb_array, beta_array, C_array, ldc_array, group_count, group_size)


@cython.show_performance_hints(False)
cdef void _cblas_sgemm_batch_strided_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const float alpha, const float* A, const nvpl_int64_t lda, const nvpl_int64_t stridea, const float* B, const nvpl_int64_t ldb, const nvpl_int64_t strideb, const float beta, float* C, const nvpl_int64_t ldc, const nvpl_int64_t stridec, const nvpl_int64_t batch_size) except* nogil:
    global __cblas_sgemm_batch_strided_64
    _check_or_init_nvpl_blas()
    if __cblas_sgemm_batch_strided_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_sgemm_batch_strided_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const float, const float*, const nvpl_int64_t, const nvpl_int64_t, const float*, const nvpl_int64_t, const nvpl_int64_t, const float, float*, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t) noexcept nogil>__cblas_sgemm_batch_strided_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_dgemm_batch_strided_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const double alpha, const double* A, const nvpl_int64_t lda, const nvpl_int64_t stridea, const double* B, const nvpl_int64_t ldb, const nvpl_int64_t strideb, const double beta, double* C, const nvpl_int64_t ldc, const nvpl_int64_t stridec, const nvpl_int64_t batch_size) except* nogil:
    global __cblas_dgemm_batch_strided_64
    _check_or_init_nvpl_blas()
    if __cblas_dgemm_batch_strided_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_dgemm_batch_strided_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const double, const double*, const nvpl_int64_t, const nvpl_int64_t, const double*, const nvpl_int64_t, const nvpl_int64_t, const double, double*, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t) noexcept nogil>__cblas_dgemm_batch_strided_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_cgemm_batch_strided_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const nvpl_int64_t stridea, const void* B, const nvpl_int64_t ldb, const nvpl_int64_t strideb, const void* beta, void* C, const nvpl_int64_t ldc, const nvpl_int64_t stridec, const nvpl_int64_t batch_size) except* nogil:
    global __cblas_cgemm_batch_strided_64
    _check_or_init_nvpl_blas()
    if __cblas_cgemm_batch_strided_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_cgemm_batch_strided_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, const nvpl_int64_t, const void*, void*, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t) noexcept nogil>__cblas_cgemm_batch_strided_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)


@cython.show_performance_hints(False)
cdef void _cblas_zgemm_batch_strided_64(const CBLAS_ORDER Order, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const nvpl_int64_t M, const nvpl_int64_t N, const nvpl_int64_t K, const void* alpha, const void* A, const nvpl_int64_t lda, const nvpl_int64_t stridea, const void* B, const nvpl_int64_t ldb, const nvpl_int64_t strideb, const void* beta, void* C, const nvpl_int64_t ldc, const nvpl_int64_t stridec, const nvpl_int64_t batch_size) except* nogil:
    global __cblas_zgemm_batch_strided_64
    _check_or_init_nvpl_blas()
    if __cblas_zgemm_batch_strided_64 == NULL:
        with gil:
            raise FunctionNotFoundError("function cblas_zgemm_batch_strided_64 is not found")
    (<void (*)(const CBLAS_ORDER, const CBLAS_TRANSPOSE, const CBLAS_TRANSPOSE, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t, const void*, const void*, const nvpl_int64_t, const nvpl_int64_t, const void*, const nvpl_int64_t, const nvpl_int64_t, const void*, void*, const nvpl_int64_t, const nvpl_int64_t, const nvpl_int64_t) noexcept nogil>__cblas_zgemm_batch_strided_64)(
        Order, TransA, TransB, M, N, K, alpha, A, lda, stridea, B, ldb, strideb, beta, C, ldc, stridec, batch_size)
