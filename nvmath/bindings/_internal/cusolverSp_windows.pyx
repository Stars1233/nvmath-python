# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.1, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libc.stdint cimport intptr_t, uintptr_t

from .cublas cimport load_library as load_cublas
from .cusparse cimport load_library as load_cusparse

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
cdef bint __py_cusolverSp_init = False

cdef void* __cusolverSpCreate = NULL
cdef void* __cusolverSpDestroy = NULL
cdef void* __cusolverSpSetStream = NULL
cdef void* __cusolverSpGetStream = NULL
cdef void* __cusolverSpXcsrissymHost = NULL
cdef void* __cusolverSpScsrlsvluHost = NULL
cdef void* __cusolverSpDcsrlsvluHost = NULL
cdef void* __cusolverSpCcsrlsvluHost = NULL
cdef void* __cusolverSpZcsrlsvluHost = NULL
cdef void* __cusolverSpScsrlsvqr = NULL
cdef void* __cusolverSpDcsrlsvqr = NULL
cdef void* __cusolverSpCcsrlsvqr = NULL
cdef void* __cusolverSpZcsrlsvqr = NULL
cdef void* __cusolverSpScsrlsvqrHost = NULL
cdef void* __cusolverSpDcsrlsvqrHost = NULL
cdef void* __cusolverSpCcsrlsvqrHost = NULL
cdef void* __cusolverSpZcsrlsvqrHost = NULL
cdef void* __cusolverSpScsrlsvcholHost = NULL
cdef void* __cusolverSpDcsrlsvcholHost = NULL
cdef void* __cusolverSpCcsrlsvcholHost = NULL
cdef void* __cusolverSpZcsrlsvcholHost = NULL
cdef void* __cusolverSpScsrlsvchol = NULL
cdef void* __cusolverSpDcsrlsvchol = NULL
cdef void* __cusolverSpCcsrlsvchol = NULL
cdef void* __cusolverSpZcsrlsvchol = NULL
cdef void* __cusolverSpScsrlsqvqrHost = NULL
cdef void* __cusolverSpDcsrlsqvqrHost = NULL
cdef void* __cusolverSpCcsrlsqvqrHost = NULL
cdef void* __cusolverSpZcsrlsqvqrHost = NULL
cdef void* __cusolverSpScsreigvsiHost = NULL
cdef void* __cusolverSpDcsreigvsiHost = NULL
cdef void* __cusolverSpCcsreigvsiHost = NULL
cdef void* __cusolverSpZcsreigvsiHost = NULL
cdef void* __cusolverSpScsreigvsi = NULL
cdef void* __cusolverSpDcsreigvsi = NULL
cdef void* __cusolverSpCcsreigvsi = NULL
cdef void* __cusolverSpZcsreigvsi = NULL
cdef void* __cusolverSpScsreigsHost = NULL
cdef void* __cusolverSpDcsreigsHost = NULL
cdef void* __cusolverSpCcsreigsHost = NULL
cdef void* __cusolverSpZcsreigsHost = NULL
cdef void* __cusolverSpXcsrsymrcmHost = NULL
cdef void* __cusolverSpXcsrsymmdqHost = NULL
cdef void* __cusolverSpXcsrsymamdHost = NULL
cdef void* __cusolverSpXcsrmetisndHost = NULL
cdef void* __cusolverSpScsrzfdHost = NULL
cdef void* __cusolverSpDcsrzfdHost = NULL
cdef void* __cusolverSpCcsrzfdHost = NULL
cdef void* __cusolverSpZcsrzfdHost = NULL
cdef void* __cusolverSpXcsrperm_bufferSizeHost = NULL
cdef void* __cusolverSpXcsrpermHost = NULL
cdef void* __cusolverSpCreateCsrqrInfo = NULL
cdef void* __cusolverSpDestroyCsrqrInfo = NULL
cdef void* __cusolverSpXcsrqrAnalysisBatched = NULL
cdef void* __cusolverSpScsrqrBufferInfoBatched = NULL
cdef void* __cusolverSpDcsrqrBufferInfoBatched = NULL
cdef void* __cusolverSpCcsrqrBufferInfoBatched = NULL
cdef void* __cusolverSpZcsrqrBufferInfoBatched = NULL
cdef void* __cusolverSpScsrqrsvBatched = NULL
cdef void* __cusolverSpDcsrqrsvBatched = NULL
cdef void* __cusolverSpCcsrqrsvBatched = NULL
cdef void* __cusolverSpZcsrqrsvBatched = NULL


cdef inline list get_site_packages():
    return [site.getusersitepackages()] + site.getsitepackages()


cdef load_library(const int driver_ver):
    return load_nvidia_dynamic_lib("cusolver")._handle_uint


cdef int _check_or_init_cusolverSp() except -1 nogil:
    global __py_cusolverSp_init
    if __py_cusolverSp_init:
        return 0

    with gil, __symbol_lock:
        # Recheck the flag after obtaining the locks
        if __py_cusolverSp_init:
            return 0

        driver_ver = get_cuda_version()

        # Load library
        handle = load_library(driver_ver)

        # Load function
        global __cusolverSpCreate
        __cusolverSpCreate = GetProcAddress(handle, 'cusolverSpCreate')

        global __cusolverSpDestroy
        __cusolverSpDestroy = GetProcAddress(handle, 'cusolverSpDestroy')

        global __cusolverSpSetStream
        __cusolverSpSetStream = GetProcAddress(handle, 'cusolverSpSetStream')

        global __cusolverSpGetStream
        __cusolverSpGetStream = GetProcAddress(handle, 'cusolverSpGetStream')

        global __cusolverSpXcsrissymHost
        __cusolverSpXcsrissymHost = GetProcAddress(handle, 'cusolverSpXcsrissymHost')

        global __cusolverSpScsrlsvluHost
        __cusolverSpScsrlsvluHost = GetProcAddress(handle, 'cusolverSpScsrlsvluHost')

        global __cusolverSpDcsrlsvluHost
        __cusolverSpDcsrlsvluHost = GetProcAddress(handle, 'cusolverSpDcsrlsvluHost')

        global __cusolverSpCcsrlsvluHost
        __cusolverSpCcsrlsvluHost = GetProcAddress(handle, 'cusolverSpCcsrlsvluHost')

        global __cusolverSpZcsrlsvluHost
        __cusolverSpZcsrlsvluHost = GetProcAddress(handle, 'cusolverSpZcsrlsvluHost')

        global __cusolverSpScsrlsvqr
        __cusolverSpScsrlsvqr = GetProcAddress(handle, 'cusolverSpScsrlsvqr')

        global __cusolverSpDcsrlsvqr
        __cusolverSpDcsrlsvqr = GetProcAddress(handle, 'cusolverSpDcsrlsvqr')

        global __cusolverSpCcsrlsvqr
        __cusolverSpCcsrlsvqr = GetProcAddress(handle, 'cusolverSpCcsrlsvqr')

        global __cusolverSpZcsrlsvqr
        __cusolverSpZcsrlsvqr = GetProcAddress(handle, 'cusolverSpZcsrlsvqr')

        global __cusolverSpScsrlsvqrHost
        __cusolverSpScsrlsvqrHost = GetProcAddress(handle, 'cusolverSpScsrlsvqrHost')

        global __cusolverSpDcsrlsvqrHost
        __cusolverSpDcsrlsvqrHost = GetProcAddress(handle, 'cusolverSpDcsrlsvqrHost')

        global __cusolverSpCcsrlsvqrHost
        __cusolverSpCcsrlsvqrHost = GetProcAddress(handle, 'cusolverSpCcsrlsvqrHost')

        global __cusolverSpZcsrlsvqrHost
        __cusolverSpZcsrlsvqrHost = GetProcAddress(handle, 'cusolverSpZcsrlsvqrHost')

        global __cusolverSpScsrlsvcholHost
        __cusolverSpScsrlsvcholHost = GetProcAddress(handle, 'cusolverSpScsrlsvcholHost')

        global __cusolverSpDcsrlsvcholHost
        __cusolverSpDcsrlsvcholHost = GetProcAddress(handle, 'cusolverSpDcsrlsvcholHost')

        global __cusolverSpCcsrlsvcholHost
        __cusolverSpCcsrlsvcholHost = GetProcAddress(handle, 'cusolverSpCcsrlsvcholHost')

        global __cusolverSpZcsrlsvcholHost
        __cusolverSpZcsrlsvcholHost = GetProcAddress(handle, 'cusolverSpZcsrlsvcholHost')

        global __cusolverSpScsrlsvchol
        __cusolverSpScsrlsvchol = GetProcAddress(handle, 'cusolverSpScsrlsvchol')

        global __cusolverSpDcsrlsvchol
        __cusolverSpDcsrlsvchol = GetProcAddress(handle, 'cusolverSpDcsrlsvchol')

        global __cusolverSpCcsrlsvchol
        __cusolverSpCcsrlsvchol = GetProcAddress(handle, 'cusolverSpCcsrlsvchol')

        global __cusolverSpZcsrlsvchol
        __cusolverSpZcsrlsvchol = GetProcAddress(handle, 'cusolverSpZcsrlsvchol')

        global __cusolverSpScsrlsqvqrHost
        __cusolverSpScsrlsqvqrHost = GetProcAddress(handle, 'cusolverSpScsrlsqvqrHost')

        global __cusolverSpDcsrlsqvqrHost
        __cusolverSpDcsrlsqvqrHost = GetProcAddress(handle, 'cusolverSpDcsrlsqvqrHost')

        global __cusolverSpCcsrlsqvqrHost
        __cusolverSpCcsrlsqvqrHost = GetProcAddress(handle, 'cusolverSpCcsrlsqvqrHost')

        global __cusolverSpZcsrlsqvqrHost
        __cusolverSpZcsrlsqvqrHost = GetProcAddress(handle, 'cusolverSpZcsrlsqvqrHost')

        global __cusolverSpScsreigvsiHost
        __cusolverSpScsreigvsiHost = GetProcAddress(handle, 'cusolverSpScsreigvsiHost')

        global __cusolverSpDcsreigvsiHost
        __cusolverSpDcsreigvsiHost = GetProcAddress(handle, 'cusolverSpDcsreigvsiHost')

        global __cusolverSpCcsreigvsiHost
        __cusolverSpCcsreigvsiHost = GetProcAddress(handle, 'cusolverSpCcsreigvsiHost')

        global __cusolverSpZcsreigvsiHost
        __cusolverSpZcsreigvsiHost = GetProcAddress(handle, 'cusolverSpZcsreigvsiHost')

        global __cusolverSpScsreigvsi
        __cusolverSpScsreigvsi = GetProcAddress(handle, 'cusolverSpScsreigvsi')

        global __cusolverSpDcsreigvsi
        __cusolverSpDcsreigvsi = GetProcAddress(handle, 'cusolverSpDcsreigvsi')

        global __cusolverSpCcsreigvsi
        __cusolverSpCcsreigvsi = GetProcAddress(handle, 'cusolverSpCcsreigvsi')

        global __cusolverSpZcsreigvsi
        __cusolverSpZcsreigvsi = GetProcAddress(handle, 'cusolverSpZcsreigvsi')

        global __cusolverSpScsreigsHost
        __cusolverSpScsreigsHost = GetProcAddress(handle, 'cusolverSpScsreigsHost')

        global __cusolverSpDcsreigsHost
        __cusolverSpDcsreigsHost = GetProcAddress(handle, 'cusolverSpDcsreigsHost')

        global __cusolverSpCcsreigsHost
        __cusolverSpCcsreigsHost = GetProcAddress(handle, 'cusolverSpCcsreigsHost')

        global __cusolverSpZcsreigsHost
        __cusolverSpZcsreigsHost = GetProcAddress(handle, 'cusolverSpZcsreigsHost')

        global __cusolverSpXcsrsymrcmHost
        __cusolverSpXcsrsymrcmHost = GetProcAddress(handle, 'cusolverSpXcsrsymrcmHost')

        global __cusolverSpXcsrsymmdqHost
        __cusolverSpXcsrsymmdqHost = GetProcAddress(handle, 'cusolverSpXcsrsymmdqHost')

        global __cusolverSpXcsrsymamdHost
        __cusolverSpXcsrsymamdHost = GetProcAddress(handle, 'cusolverSpXcsrsymamdHost')

        global __cusolverSpXcsrmetisndHost
        __cusolverSpXcsrmetisndHost = GetProcAddress(handle, 'cusolverSpXcsrmetisndHost')

        global __cusolverSpScsrzfdHost
        __cusolverSpScsrzfdHost = GetProcAddress(handle, 'cusolverSpScsrzfdHost')

        global __cusolverSpDcsrzfdHost
        __cusolverSpDcsrzfdHost = GetProcAddress(handle, 'cusolverSpDcsrzfdHost')

        global __cusolverSpCcsrzfdHost
        __cusolverSpCcsrzfdHost = GetProcAddress(handle, 'cusolverSpCcsrzfdHost')

        global __cusolverSpZcsrzfdHost
        __cusolverSpZcsrzfdHost = GetProcAddress(handle, 'cusolverSpZcsrzfdHost')

        global __cusolverSpXcsrperm_bufferSizeHost
        __cusolverSpXcsrperm_bufferSizeHost = GetProcAddress(handle, 'cusolverSpXcsrperm_bufferSizeHost')

        global __cusolverSpXcsrpermHost
        __cusolverSpXcsrpermHost = GetProcAddress(handle, 'cusolverSpXcsrpermHost')

        global __cusolverSpCreateCsrqrInfo
        __cusolverSpCreateCsrqrInfo = GetProcAddress(handle, 'cusolverSpCreateCsrqrInfo')

        global __cusolverSpDestroyCsrqrInfo
        __cusolverSpDestroyCsrqrInfo = GetProcAddress(handle, 'cusolverSpDestroyCsrqrInfo')

        global __cusolverSpXcsrqrAnalysisBatched
        __cusolverSpXcsrqrAnalysisBatched = GetProcAddress(handle, 'cusolverSpXcsrqrAnalysisBatched')

        global __cusolverSpScsrqrBufferInfoBatched
        __cusolverSpScsrqrBufferInfoBatched = GetProcAddress(handle, 'cusolverSpScsrqrBufferInfoBatched')

        global __cusolverSpDcsrqrBufferInfoBatched
        __cusolverSpDcsrqrBufferInfoBatched = GetProcAddress(handle, 'cusolverSpDcsrqrBufferInfoBatched')

        global __cusolverSpCcsrqrBufferInfoBatched
        __cusolverSpCcsrqrBufferInfoBatched = GetProcAddress(handle, 'cusolverSpCcsrqrBufferInfoBatched')

        global __cusolverSpZcsrqrBufferInfoBatched
        __cusolverSpZcsrqrBufferInfoBatched = GetProcAddress(handle, 'cusolverSpZcsrqrBufferInfoBatched')

        global __cusolverSpScsrqrsvBatched
        __cusolverSpScsrqrsvBatched = GetProcAddress(handle, 'cusolverSpScsrqrsvBatched')

        global __cusolverSpDcsrqrsvBatched
        __cusolverSpDcsrqrsvBatched = GetProcAddress(handle, 'cusolverSpDcsrqrsvBatched')

        global __cusolverSpCcsrqrsvBatched
        __cusolverSpCcsrqrsvBatched = GetProcAddress(handle, 'cusolverSpCcsrqrsvBatched')

        global __cusolverSpZcsrqrsvBatched
        __cusolverSpZcsrqrsvBatched = GetProcAddress(handle, 'cusolverSpZcsrqrsvBatched')

        __py_cusolverSp_init = True
        return 0


cdef dict func_ptrs = None


cpdef dict _inspect_function_pointers():
    global func_ptrs
    if func_ptrs is not None:
        return func_ptrs

    _check_or_init_cusolverSp()
    cdef dict data = {}

    global __cusolverSpCreate
    data["__cusolverSpCreate"] = <intptr_t>__cusolverSpCreate

    global __cusolverSpDestroy
    data["__cusolverSpDestroy"] = <intptr_t>__cusolverSpDestroy

    global __cusolverSpSetStream
    data["__cusolverSpSetStream"] = <intptr_t>__cusolverSpSetStream

    global __cusolverSpGetStream
    data["__cusolverSpGetStream"] = <intptr_t>__cusolverSpGetStream

    global __cusolverSpXcsrissymHost
    data["__cusolverSpXcsrissymHost"] = <intptr_t>__cusolverSpXcsrissymHost

    global __cusolverSpScsrlsvluHost
    data["__cusolverSpScsrlsvluHost"] = <intptr_t>__cusolverSpScsrlsvluHost

    global __cusolverSpDcsrlsvluHost
    data["__cusolverSpDcsrlsvluHost"] = <intptr_t>__cusolverSpDcsrlsvluHost

    global __cusolverSpCcsrlsvluHost
    data["__cusolverSpCcsrlsvluHost"] = <intptr_t>__cusolverSpCcsrlsvluHost

    global __cusolverSpZcsrlsvluHost
    data["__cusolverSpZcsrlsvluHost"] = <intptr_t>__cusolverSpZcsrlsvluHost

    global __cusolverSpScsrlsvqr
    data["__cusolverSpScsrlsvqr"] = <intptr_t>__cusolverSpScsrlsvqr

    global __cusolverSpDcsrlsvqr
    data["__cusolverSpDcsrlsvqr"] = <intptr_t>__cusolverSpDcsrlsvqr

    global __cusolverSpCcsrlsvqr
    data["__cusolverSpCcsrlsvqr"] = <intptr_t>__cusolverSpCcsrlsvqr

    global __cusolverSpZcsrlsvqr
    data["__cusolverSpZcsrlsvqr"] = <intptr_t>__cusolverSpZcsrlsvqr

    global __cusolverSpScsrlsvqrHost
    data["__cusolverSpScsrlsvqrHost"] = <intptr_t>__cusolverSpScsrlsvqrHost

    global __cusolverSpDcsrlsvqrHost
    data["__cusolverSpDcsrlsvqrHost"] = <intptr_t>__cusolverSpDcsrlsvqrHost

    global __cusolverSpCcsrlsvqrHost
    data["__cusolverSpCcsrlsvqrHost"] = <intptr_t>__cusolverSpCcsrlsvqrHost

    global __cusolverSpZcsrlsvqrHost
    data["__cusolverSpZcsrlsvqrHost"] = <intptr_t>__cusolverSpZcsrlsvqrHost

    global __cusolverSpScsrlsvcholHost
    data["__cusolverSpScsrlsvcholHost"] = <intptr_t>__cusolverSpScsrlsvcholHost

    global __cusolverSpDcsrlsvcholHost
    data["__cusolverSpDcsrlsvcholHost"] = <intptr_t>__cusolverSpDcsrlsvcholHost

    global __cusolverSpCcsrlsvcholHost
    data["__cusolverSpCcsrlsvcholHost"] = <intptr_t>__cusolverSpCcsrlsvcholHost

    global __cusolverSpZcsrlsvcholHost
    data["__cusolverSpZcsrlsvcholHost"] = <intptr_t>__cusolverSpZcsrlsvcholHost

    global __cusolverSpScsrlsvchol
    data["__cusolverSpScsrlsvchol"] = <intptr_t>__cusolverSpScsrlsvchol

    global __cusolverSpDcsrlsvchol
    data["__cusolverSpDcsrlsvchol"] = <intptr_t>__cusolverSpDcsrlsvchol

    global __cusolverSpCcsrlsvchol
    data["__cusolverSpCcsrlsvchol"] = <intptr_t>__cusolverSpCcsrlsvchol

    global __cusolverSpZcsrlsvchol
    data["__cusolverSpZcsrlsvchol"] = <intptr_t>__cusolverSpZcsrlsvchol

    global __cusolverSpScsrlsqvqrHost
    data["__cusolverSpScsrlsqvqrHost"] = <intptr_t>__cusolverSpScsrlsqvqrHost

    global __cusolverSpDcsrlsqvqrHost
    data["__cusolverSpDcsrlsqvqrHost"] = <intptr_t>__cusolverSpDcsrlsqvqrHost

    global __cusolverSpCcsrlsqvqrHost
    data["__cusolverSpCcsrlsqvqrHost"] = <intptr_t>__cusolverSpCcsrlsqvqrHost

    global __cusolverSpZcsrlsqvqrHost
    data["__cusolverSpZcsrlsqvqrHost"] = <intptr_t>__cusolverSpZcsrlsqvqrHost

    global __cusolverSpScsreigvsiHost
    data["__cusolverSpScsreigvsiHost"] = <intptr_t>__cusolverSpScsreigvsiHost

    global __cusolverSpDcsreigvsiHost
    data["__cusolverSpDcsreigvsiHost"] = <intptr_t>__cusolverSpDcsreigvsiHost

    global __cusolverSpCcsreigvsiHost
    data["__cusolverSpCcsreigvsiHost"] = <intptr_t>__cusolverSpCcsreigvsiHost

    global __cusolverSpZcsreigvsiHost
    data["__cusolverSpZcsreigvsiHost"] = <intptr_t>__cusolverSpZcsreigvsiHost

    global __cusolverSpScsreigvsi
    data["__cusolverSpScsreigvsi"] = <intptr_t>__cusolverSpScsreigvsi

    global __cusolverSpDcsreigvsi
    data["__cusolverSpDcsreigvsi"] = <intptr_t>__cusolverSpDcsreigvsi

    global __cusolverSpCcsreigvsi
    data["__cusolverSpCcsreigvsi"] = <intptr_t>__cusolverSpCcsreigvsi

    global __cusolverSpZcsreigvsi
    data["__cusolverSpZcsreigvsi"] = <intptr_t>__cusolverSpZcsreigvsi

    global __cusolverSpScsreigsHost
    data["__cusolverSpScsreigsHost"] = <intptr_t>__cusolverSpScsreigsHost

    global __cusolverSpDcsreigsHost
    data["__cusolverSpDcsreigsHost"] = <intptr_t>__cusolverSpDcsreigsHost

    global __cusolverSpCcsreigsHost
    data["__cusolverSpCcsreigsHost"] = <intptr_t>__cusolverSpCcsreigsHost

    global __cusolverSpZcsreigsHost
    data["__cusolverSpZcsreigsHost"] = <intptr_t>__cusolverSpZcsreigsHost

    global __cusolverSpXcsrsymrcmHost
    data["__cusolverSpXcsrsymrcmHost"] = <intptr_t>__cusolverSpXcsrsymrcmHost

    global __cusolverSpXcsrsymmdqHost
    data["__cusolverSpXcsrsymmdqHost"] = <intptr_t>__cusolverSpXcsrsymmdqHost

    global __cusolverSpXcsrsymamdHost
    data["__cusolverSpXcsrsymamdHost"] = <intptr_t>__cusolverSpXcsrsymamdHost

    global __cusolverSpXcsrmetisndHost
    data["__cusolverSpXcsrmetisndHost"] = <intptr_t>__cusolverSpXcsrmetisndHost

    global __cusolverSpScsrzfdHost
    data["__cusolverSpScsrzfdHost"] = <intptr_t>__cusolverSpScsrzfdHost

    global __cusolverSpDcsrzfdHost
    data["__cusolverSpDcsrzfdHost"] = <intptr_t>__cusolverSpDcsrzfdHost

    global __cusolverSpCcsrzfdHost
    data["__cusolverSpCcsrzfdHost"] = <intptr_t>__cusolverSpCcsrzfdHost

    global __cusolverSpZcsrzfdHost
    data["__cusolverSpZcsrzfdHost"] = <intptr_t>__cusolverSpZcsrzfdHost

    global __cusolverSpXcsrperm_bufferSizeHost
    data["__cusolverSpXcsrperm_bufferSizeHost"] = <intptr_t>__cusolverSpXcsrperm_bufferSizeHost

    global __cusolverSpXcsrpermHost
    data["__cusolverSpXcsrpermHost"] = <intptr_t>__cusolverSpXcsrpermHost

    global __cusolverSpCreateCsrqrInfo
    data["__cusolverSpCreateCsrqrInfo"] = <intptr_t>__cusolverSpCreateCsrqrInfo

    global __cusolverSpDestroyCsrqrInfo
    data["__cusolverSpDestroyCsrqrInfo"] = <intptr_t>__cusolverSpDestroyCsrqrInfo

    global __cusolverSpXcsrqrAnalysisBatched
    data["__cusolverSpXcsrqrAnalysisBatched"] = <intptr_t>__cusolverSpXcsrqrAnalysisBatched

    global __cusolverSpScsrqrBufferInfoBatched
    data["__cusolverSpScsrqrBufferInfoBatched"] = <intptr_t>__cusolverSpScsrqrBufferInfoBatched

    global __cusolverSpDcsrqrBufferInfoBatched
    data["__cusolverSpDcsrqrBufferInfoBatched"] = <intptr_t>__cusolverSpDcsrqrBufferInfoBatched

    global __cusolverSpCcsrqrBufferInfoBatched
    data["__cusolverSpCcsrqrBufferInfoBatched"] = <intptr_t>__cusolverSpCcsrqrBufferInfoBatched

    global __cusolverSpZcsrqrBufferInfoBatched
    data["__cusolverSpZcsrqrBufferInfoBatched"] = <intptr_t>__cusolverSpZcsrqrBufferInfoBatched

    global __cusolverSpScsrqrsvBatched
    data["__cusolverSpScsrqrsvBatched"] = <intptr_t>__cusolverSpScsrqrsvBatched

    global __cusolverSpDcsrqrsvBatched
    data["__cusolverSpDcsrqrsvBatched"] = <intptr_t>__cusolverSpDcsrqrsvBatched

    global __cusolverSpCcsrqrsvBatched
    data["__cusolverSpCcsrqrsvBatched"] = <intptr_t>__cusolverSpCcsrqrsvBatched

    global __cusolverSpZcsrqrsvBatched
    data["__cusolverSpZcsrqrsvBatched"] = <intptr_t>__cusolverSpZcsrqrsvBatched

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

cdef cusolverStatus_t _cusolverSpCreate(cusolverSpHandle_t* handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCreate
    _check_or_init_cusolverSp()
    if __cusolverSpCreate == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCreate is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t*) noexcept nogil>__cusolverSpCreate)(
        handle)


cdef cusolverStatus_t _cusolverSpDestroy(cusolverSpHandle_t handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDestroy
    _check_or_init_cusolverSp()
    if __cusolverSpDestroy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDestroy is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t) noexcept nogil>__cusolverSpDestroy)(
        handle)


cdef cusolverStatus_t _cusolverSpSetStream(cusolverSpHandle_t handle, cudaStream_t streamId) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpSetStream
    _check_or_init_cusolverSp()
    if __cusolverSpSetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpSetStream is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, cudaStream_t) noexcept nogil>__cusolverSpSetStream)(
        handle, streamId)


cdef cusolverStatus_t _cusolverSpGetStream(cusolverSpHandle_t handle, cudaStream_t* streamId) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpGetStream
    _check_or_init_cusolverSp()
    if __cusolverSpGetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpGetStream is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, cudaStream_t*) noexcept nogil>__cusolverSpGetStream)(
        handle, streamId)


cdef cusolverStatus_t _cusolverSpXcsrissymHost(cusolverSpHandle_t handle, int m, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrEndPtrA, const int* csrColIndA, int* issym) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrissymHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrissymHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrissymHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const int*, const int*, const int*, int*) noexcept nogil>__cusolverSpXcsrissymHost)(
        handle, m, nnzA, descrA, csrRowPtrA, csrEndPtrA, csrColIndA, issym)


cdef cusolverStatus_t _cusolverSpScsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsvluHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsvluHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsvluHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int, float*, int*) noexcept nogil>__cusolverSpScsrlsvluHost)(
        handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpDcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsvluHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsvluHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsvluHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int, double*, int*) noexcept nogil>__cusolverSpDcsrlsvluHost)(
        handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpCcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsvluHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsvluHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsvluHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int, cuComplex*, int*) noexcept nogil>__cusolverSpCcsrlsvluHost)(
        handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpZcsrlsvluHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsvluHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsvluHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsvluHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int, cuDoubleComplex*, int*) noexcept nogil>__cusolverSpZcsrlsvluHost)(
        handle, n, nnzA, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpScsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsvqr
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsvqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsvqr is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int, float*, int*) noexcept nogil>__cusolverSpScsrlsvqr)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpDcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsvqr
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsvqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsvqr is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int, double*, int*) noexcept nogil>__cusolverSpDcsrlsvqr)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpCcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsvqr
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsvqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsvqr is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int, cuComplex*, int*) noexcept nogil>__cusolverSpCcsrlsvqr)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpZcsrlsvqr(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsvqr
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsvqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsvqr is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int, cuDoubleComplex*, int*) noexcept nogil>__cusolverSpZcsrlsvqr)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpScsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int, float*, int*) noexcept nogil>__cusolverSpScsrlsvqrHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpDcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int, double*, int*) noexcept nogil>__cusolverSpDcsrlsvqrHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpCcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int, cuComplex*, int*) noexcept nogil>__cusolverSpCcsrlsvqrHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpZcsrlsvqrHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int, cuDoubleComplex*, int*) noexcept nogil>__cusolverSpZcsrlsvqrHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpScsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsvcholHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsvcholHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsvcholHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int, float*, int*) noexcept nogil>__cusolverSpScsrlsvcholHost)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpDcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsvcholHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsvcholHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsvcholHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int, double*, int*) noexcept nogil>__cusolverSpDcsrlsvcholHost)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpCcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsvcholHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsvcholHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsvcholHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int, cuComplex*, int*) noexcept nogil>__cusolverSpCcsrlsvcholHost)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpZcsrlsvcholHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsvcholHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsvcholHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsvcholHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int, cuDoubleComplex*, int*) noexcept nogil>__cusolverSpZcsrlsvcholHost)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpScsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, const float* b, float tol, int reorder, float* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsvchol
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsvchol == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsvchol is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int, float*, int*) noexcept nogil>__cusolverSpScsrlsvchol)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpDcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, const double* b, double tol, int reorder, double* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsvchol
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsvchol == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsvchol is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int, double*, int*) noexcept nogil>__cusolverSpDcsrlsvchol)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpCcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuComplex* b, float tol, int reorder, cuComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsvchol
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsvchol == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsvchol is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int, cuComplex*, int*) noexcept nogil>__cusolverSpCcsrlsvchol)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpZcsrlsvchol(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, const cuDoubleComplex* b, double tol, int reorder, cuDoubleComplex* x, int* singularity) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsvchol
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsvchol == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsvchol is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int, cuDoubleComplex*, int*) noexcept nogil>__cusolverSpZcsrlsvchol)(
        handle, m, nnz, descrA, csrVal, csrRowPtr, csrColInd, b, tol, reorder, x, singularity)


cdef cusolverStatus_t _cusolverSpScsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float tol, int* rankA, float* x, int* p, float* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrlsqvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsrlsqvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrlsqvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float, int*, float*, int*, float*) noexcept nogil>__cusolverSpScsrlsqvqrHost)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t _cusolverSpDcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double tol, int* rankA, double* x, int* p, double* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrlsqvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrlsqvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrlsqvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double, int*, double*, int*, double*) noexcept nogil>__cusolverSpDcsrlsqvqrHost)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t _cusolverSpCcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, float tol, int* rankA, cuComplex* x, int* p, float* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrlsqvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrlsqvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrlsqvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, float, int*, cuComplex*, int*, float*) noexcept nogil>__cusolverSpCcsrlsqvqrHost)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t _cusolverSpZcsrlsqvqrHost(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, double tol, int* rankA, cuDoubleComplex* x, int* p, double* min_norm) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrlsqvqrHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrlsqvqrHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrlsqvqrHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, double, int*, cuDoubleComplex*, int*, double*) noexcept nogil>__cusolverSpZcsrlsqvqrHost)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, tol, rankA, x, p, min_norm)


cdef cusolverStatus_t _cusolverSpScsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, float mu0, const float* x0, int maxite, float tol, float* mu, float* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsreigvsiHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsreigvsiHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsreigvsiHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, float, const float*, int, float, float*, float*) noexcept nogil>__cusolverSpScsreigvsiHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t _cusolverSpDcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, double mu0, const double* x0, int maxite, double tol, double* mu, double* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsreigvsiHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsreigvsiHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsreigvsiHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, double, const double*, int, double, double*, double*) noexcept nogil>__cusolverSpDcsreigvsiHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t _cusolverSpCcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex mu0, const cuComplex* x0, int maxite, float tol, cuComplex* mu, cuComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsreigvsiHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsreigvsiHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsreigvsiHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, cuComplex, const cuComplex*, int, float, cuComplex*, cuComplex*) noexcept nogil>__cusolverSpCcsreigvsiHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t _cusolverSpZcsreigvsiHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex mu0, const cuDoubleComplex* x0, int maxite, double tol, cuDoubleComplex* mu, cuDoubleComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsreigvsiHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsreigvsiHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsreigvsiHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, cuDoubleComplex, const cuDoubleComplex*, int, double, cuDoubleComplex*, cuDoubleComplex*) noexcept nogil>__cusolverSpZcsreigvsiHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, tol, mu, x)


cdef cusolverStatus_t _cusolverSpScsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, float mu0, const float* x0, int maxite, float eps, float* mu, float* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsreigvsi
    _check_or_init_cusolverSp()
    if __cusolverSpScsreigvsi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsreigvsi is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, float, const float*, int, float, float*, float*) noexcept nogil>__cusolverSpScsreigvsi)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t _cusolverSpDcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, double mu0, const double* x0, int maxite, double eps, double* mu, double* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsreigvsi
    _check_or_init_cusolverSp()
    if __cusolverSpDcsreigvsi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsreigvsi is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, double, const double*, int, double, double*, double*) noexcept nogil>__cusolverSpDcsreigvsi)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t _cusolverSpCcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex mu0, const cuComplex* x0, int maxite, float eps, cuComplex* mu, cuComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsreigvsi
    _check_or_init_cusolverSp()
    if __cusolverSpCcsreigvsi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsreigvsi is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, cuComplex, const cuComplex*, int, float, cuComplex*, cuComplex*) noexcept nogil>__cusolverSpCcsreigvsi)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t _cusolverSpZcsreigvsi(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex mu0, const cuDoubleComplex* x0, int maxite, double eps, cuDoubleComplex* mu, cuDoubleComplex* x) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsreigvsi
    _check_or_init_cusolverSp()
    if __cusolverSpZcsreigvsi == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsreigvsi is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, cuDoubleComplex, const cuDoubleComplex*, int, double, cuDoubleComplex*, cuDoubleComplex*) noexcept nogil>__cusolverSpZcsreigvsi)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, mu0, x0, maxite, eps, mu, x)


cdef cusolverStatus_t _cusolverSpScsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex left_bottom_corner, cuComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsreigsHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsreigsHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsreigsHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, cuComplex, cuComplex, int*) noexcept nogil>__cusolverSpScsreigsHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t _cusolverSpDcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex left_bottom_corner, cuDoubleComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsreigsHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsreigsHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsreigsHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, cuDoubleComplex, cuDoubleComplex, int*) noexcept nogil>__cusolverSpDcsreigsHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t _cusolverSpCcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuComplex left_bottom_corner, cuComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsreigsHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsreigsHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsreigsHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, cuComplex, cuComplex, int*) noexcept nogil>__cusolverSpCcsreigsHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t _cusolverSpZcsreigsHost(cusolverSpHandle_t handle, int m, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, cuDoubleComplex left_bottom_corner, cuDoubleComplex right_upper_corner, int* num_eigs) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsreigsHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsreigsHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsreigsHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, cuDoubleComplex, cuDoubleComplex, int*) noexcept nogil>__cusolverSpZcsreigsHost)(
        handle, m, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, left_bottom_corner, right_upper_corner, num_eigs)


cdef cusolverStatus_t _cusolverSpXcsrsymrcmHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrsymrcmHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrsymrcmHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrsymrcmHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const int*, const int*, int*) noexcept nogil>__cusolverSpXcsrsymrcmHost)(
        handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t _cusolverSpXcsrsymmdqHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrsymmdqHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrsymmdqHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrsymmdqHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const int*, const int*, int*) noexcept nogil>__cusolverSpXcsrsymmdqHost)(
        handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t _cusolverSpXcsrsymamdHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrsymamdHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrsymamdHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrsymamdHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const int*, const int*, int*) noexcept nogil>__cusolverSpXcsrsymamdHost)(
        handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, p)


cdef cusolverStatus_t _cusolverSpXcsrmetisndHost(cusolverSpHandle_t handle, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, const int64_t* options, int* p) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrmetisndHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrmetisndHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrmetisndHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const int*, const int*, const int64_t*, int*) noexcept nogil>__cusolverSpXcsrmetisndHost)(
        handle, n, nnzA, descrA, csrRowPtrA, csrColIndA, options, p)


cdef cusolverStatus_t _cusolverSpScsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrzfdHost
    _check_or_init_cusolverSp()
    if __cusolverSpScsrzfdHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrzfdHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int*, int*) noexcept nogil>__cusolverSpScsrzfdHost)(
        handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t _cusolverSpDcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrzfdHost
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrzfdHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrzfdHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int*, int*) noexcept nogil>__cusolverSpDcsrzfdHost)(
        handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t _cusolverSpCcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrzfdHost
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrzfdHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrzfdHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int*, int*) noexcept nogil>__cusolverSpCcsrzfdHost)(
        handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t _cusolverSpZcsrzfdHost(cusolverSpHandle_t handle, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, int* P, int* numnz) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrzfdHost
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrzfdHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrzfdHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int*, int*) noexcept nogil>__cusolverSpZcsrzfdHost)(
        handle, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, P, numnz)


cdef cusolverStatus_t _cusolverSpXcsrperm_bufferSizeHost(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, const int* p, const int* q, size_t* bufferSizeInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrperm_bufferSizeHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrperm_bufferSizeHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrperm_bufferSizeHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const int*, const int*, const int*, const int*, size_t*) noexcept nogil>__cusolverSpXcsrperm_bufferSizeHost)(
        handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, p, q, bufferSizeInBytes)


cdef cusolverStatus_t _cusolverSpXcsrpermHost(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, int* csrRowPtrA, int* csrColIndA, const int* p, const int* q, int* map, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrpermHost
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrpermHost == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrpermHost is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, int*, int*, const int*, const int*, int*, void*) noexcept nogil>__cusolverSpXcsrpermHost)(
        handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, p, q, map, pBuffer)


cdef cusolverStatus_t _cusolverSpCreateCsrqrInfo(csrqrInfo_t* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCreateCsrqrInfo
    _check_or_init_cusolverSp()
    if __cusolverSpCreateCsrqrInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCreateCsrqrInfo is not found")
    return (<cusolverStatus_t (*)(csrqrInfo_t*) noexcept nogil>__cusolverSpCreateCsrqrInfo)(
        info)


cdef cusolverStatus_t _cusolverSpDestroyCsrqrInfo(csrqrInfo_t info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDestroyCsrqrInfo
    _check_or_init_cusolverSp()
    if __cusolverSpDestroyCsrqrInfo == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDestroyCsrqrInfo is not found")
    return (<cusolverStatus_t (*)(csrqrInfo_t) noexcept nogil>__cusolverSpDestroyCsrqrInfo)(
        info)


cdef cusolverStatus_t _cusolverSpXcsrqrAnalysisBatched(cusolverSpHandle_t handle, int m, int n, int nnzA, const cusparseMatDescr_t descrA, const int* csrRowPtrA, const int* csrColIndA, csrqrInfo_t info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpXcsrqrAnalysisBatched
    _check_or_init_cusolverSp()
    if __cusolverSpXcsrqrAnalysisBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpXcsrqrAnalysisBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const int*, const int*, csrqrInfo_t) noexcept nogil>__cusolverSpXcsrqrAnalysisBatched)(
        handle, m, n, nnzA, descrA, csrRowPtrA, csrColIndA, info)


cdef cusolverStatus_t _cusolverSpScsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrqrBufferInfoBatched
    _check_or_init_cusolverSp()
    if __cusolverSpScsrqrBufferInfoBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrqrBufferInfoBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, int, csrqrInfo_t, size_t*, size_t*) noexcept nogil>__cusolverSpScsrqrBufferInfoBatched)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t _cusolverSpDcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrqrBufferInfoBatched
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrqrBufferInfoBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrqrBufferInfoBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, int, csrqrInfo_t, size_t*, size_t*) noexcept nogil>__cusolverSpDcsrqrBufferInfoBatched)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t _cusolverSpCcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrqrBufferInfoBatched
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrqrBufferInfoBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrqrBufferInfoBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, int, csrqrInfo_t, size_t*, size_t*) noexcept nogil>__cusolverSpCcsrqrBufferInfoBatched)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t _cusolverSpZcsrqrBufferInfoBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrVal, const int* csrRowPtr, const int* csrColInd, int batchSize, csrqrInfo_t info, size_t* internalDataInBytes, size_t* workspaceInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrqrBufferInfoBatched
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrqrBufferInfoBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrqrBufferInfoBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, int, csrqrInfo_t, size_t*, size_t*) noexcept nogil>__cusolverSpZcsrqrBufferInfoBatched)(
        handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd, batchSize, info, internalDataInBytes, workspaceInBytes)


cdef cusolverStatus_t _cusolverSpScsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const float* csrValA, const int* csrRowPtrA, const int* csrColIndA, const float* b, float* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpScsrqrsvBatched
    _check_or_init_cusolverSp()
    if __cusolverSpScsrqrsvBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpScsrqrsvBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const float*, const int*, const int*, const float*, float*, int, csrqrInfo_t, void*) noexcept nogil>__cusolverSpScsrqrsvBatched)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t _cusolverSpDcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const double* csrValA, const int* csrRowPtrA, const int* csrColIndA, const double* b, double* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpDcsrqrsvBatched
    _check_or_init_cusolverSp()
    if __cusolverSpDcsrqrsvBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpDcsrqrsvBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const double*, const int*, const int*, const double*, double*, int, csrqrInfo_t, void*) noexcept nogil>__cusolverSpDcsrqrsvBatched)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t _cusolverSpCcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuComplex* b, cuComplex* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpCcsrqrsvBatched
    _check_or_init_cusolverSp()
    if __cusolverSpCcsrqrsvBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpCcsrqrsvBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuComplex*, const int*, const int*, const cuComplex*, cuComplex*, int, csrqrInfo_t, void*) noexcept nogil>__cusolverSpCcsrqrsvBatched)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)


cdef cusolverStatus_t _cusolverSpZcsrqrsvBatched(cusolverSpHandle_t handle, int m, int n, int nnz, const cusparseMatDescr_t descrA, const cuDoubleComplex* csrValA, const int* csrRowPtrA, const int* csrColIndA, const cuDoubleComplex* b, cuDoubleComplex* x, int batchSize, csrqrInfo_t info, void* pBuffer) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverSpZcsrqrsvBatched
    _check_or_init_cusolverSp()
    if __cusolverSpZcsrqrsvBatched == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverSpZcsrqrsvBatched is not found")
    return (<cusolverStatus_t (*)(cusolverSpHandle_t, int, int, int, const cusparseMatDescr_t, const cuDoubleComplex*, const int*, const int*, const cuDoubleComplex*, cuDoubleComplex*, int, csrqrInfo_t, void*) noexcept nogil>__cusolverSpZcsrqrsvBatched)(
        handle, m, n, nnz, descrA, csrValA, csrRowPtrA, csrColIndA, b, x, batchSize, info, pBuffer)
