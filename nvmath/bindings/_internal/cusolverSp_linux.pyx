# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 12.0.1 to 13.2.1, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

from libc.stdint cimport intptr_t, uintptr_t

import threading

from .utils import FunctionNotFoundError, NotSupportedError

from cuda.pathfinder import load_nvidia_dynamic_lib


###############################################################################
# Extern
###############################################################################

# You must 'from .utils import NotSupportedError' before using this template

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

cdef int get_cuda_version():
    cdef void* handle = NULL
    cdef int err, driver_ver = 0

    # Load driver to check version
    handle = dlopen('libcuda.so.1', RTLD_NOW | RTLD_GLOBAL)
    if handle == NULL:
        err_msg = dlerror()
        raise NotSupportedError(f'CUDA driver is not found ({err_msg.decode()})')
    cuDriverGetVersion = dlsym(handle, "cuDriverGetVersion")
    if cuDriverGetVersion == NULL:
        raise RuntimeError('Did not find cuDriverGetVersion symbol in libcuda.so.1')
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


cdef void* load_library(const int driver_ver) except* with gil:
    cdef uintptr_t handle = load_nvidia_dynamic_lib("cusolver")._handle_uint
    return <void*>handle


cdef int _check_or_init_cusolverSp() except -1 nogil:
    global __py_cusolverSp_init
    if __py_cusolverSp_init:
        return 0

    cdef void* handle = NULL

    with gil, __symbol_lock:
        # Recheck the flag after obtaining the locks
        if __py_cusolverSp_init:
            return 0

        driver_ver = get_cuda_version()

        # Load function
        global __cusolverSpCreate
        __cusolverSpCreate = dlsym(RTLD_DEFAULT, 'cusolverSpCreate')
        if __cusolverSpCreate == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCreate = dlsym(handle, 'cusolverSpCreate')

        global __cusolverSpDestroy
        __cusolverSpDestroy = dlsym(RTLD_DEFAULT, 'cusolverSpDestroy')
        if __cusolverSpDestroy == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDestroy = dlsym(handle, 'cusolverSpDestroy')

        global __cusolverSpSetStream
        __cusolverSpSetStream = dlsym(RTLD_DEFAULT, 'cusolverSpSetStream')
        if __cusolverSpSetStream == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpSetStream = dlsym(handle, 'cusolverSpSetStream')

        global __cusolverSpGetStream
        __cusolverSpGetStream = dlsym(RTLD_DEFAULT, 'cusolverSpGetStream')
        if __cusolverSpGetStream == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpGetStream = dlsym(handle, 'cusolverSpGetStream')

        global __cusolverSpXcsrissymHost
        __cusolverSpXcsrissymHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrissymHost')
        if __cusolverSpXcsrissymHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrissymHost = dlsym(handle, 'cusolverSpXcsrissymHost')

        global __cusolverSpScsrlsvluHost
        __cusolverSpScsrlsvluHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsvluHost')
        if __cusolverSpScsrlsvluHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsvluHost = dlsym(handle, 'cusolverSpScsrlsvluHost')

        global __cusolverSpDcsrlsvluHost
        __cusolverSpDcsrlsvluHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsvluHost')
        if __cusolverSpDcsrlsvluHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsvluHost = dlsym(handle, 'cusolverSpDcsrlsvluHost')

        global __cusolverSpCcsrlsvluHost
        __cusolverSpCcsrlsvluHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsvluHost')
        if __cusolverSpCcsrlsvluHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsvluHost = dlsym(handle, 'cusolverSpCcsrlsvluHost')

        global __cusolverSpZcsrlsvluHost
        __cusolverSpZcsrlsvluHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsvluHost')
        if __cusolverSpZcsrlsvluHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsvluHost = dlsym(handle, 'cusolverSpZcsrlsvluHost')

        global __cusolverSpScsrlsvqr
        __cusolverSpScsrlsvqr = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsvqr')
        if __cusolverSpScsrlsvqr == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsvqr = dlsym(handle, 'cusolverSpScsrlsvqr')

        global __cusolverSpDcsrlsvqr
        __cusolverSpDcsrlsvqr = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsvqr')
        if __cusolverSpDcsrlsvqr == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsvqr = dlsym(handle, 'cusolverSpDcsrlsvqr')

        global __cusolverSpCcsrlsvqr
        __cusolverSpCcsrlsvqr = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsvqr')
        if __cusolverSpCcsrlsvqr == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsvqr = dlsym(handle, 'cusolverSpCcsrlsvqr')

        global __cusolverSpZcsrlsvqr
        __cusolverSpZcsrlsvqr = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsvqr')
        if __cusolverSpZcsrlsvqr == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsvqr = dlsym(handle, 'cusolverSpZcsrlsvqr')

        global __cusolverSpScsrlsvqrHost
        __cusolverSpScsrlsvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsvqrHost')
        if __cusolverSpScsrlsvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsvqrHost = dlsym(handle, 'cusolverSpScsrlsvqrHost')

        global __cusolverSpDcsrlsvqrHost
        __cusolverSpDcsrlsvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsvqrHost')
        if __cusolverSpDcsrlsvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsvqrHost = dlsym(handle, 'cusolverSpDcsrlsvqrHost')

        global __cusolverSpCcsrlsvqrHost
        __cusolverSpCcsrlsvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsvqrHost')
        if __cusolverSpCcsrlsvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsvqrHost = dlsym(handle, 'cusolverSpCcsrlsvqrHost')

        global __cusolverSpZcsrlsvqrHost
        __cusolverSpZcsrlsvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsvqrHost')
        if __cusolverSpZcsrlsvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsvqrHost = dlsym(handle, 'cusolverSpZcsrlsvqrHost')

        global __cusolverSpScsrlsvcholHost
        __cusolverSpScsrlsvcholHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsvcholHost')
        if __cusolverSpScsrlsvcholHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsvcholHost = dlsym(handle, 'cusolverSpScsrlsvcholHost')

        global __cusolverSpDcsrlsvcholHost
        __cusolverSpDcsrlsvcholHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsvcholHost')
        if __cusolverSpDcsrlsvcholHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsvcholHost = dlsym(handle, 'cusolverSpDcsrlsvcholHost')

        global __cusolverSpCcsrlsvcholHost
        __cusolverSpCcsrlsvcholHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsvcholHost')
        if __cusolverSpCcsrlsvcholHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsvcholHost = dlsym(handle, 'cusolverSpCcsrlsvcholHost')

        global __cusolverSpZcsrlsvcholHost
        __cusolverSpZcsrlsvcholHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsvcholHost')
        if __cusolverSpZcsrlsvcholHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsvcholHost = dlsym(handle, 'cusolverSpZcsrlsvcholHost')

        global __cusolverSpScsrlsvchol
        __cusolverSpScsrlsvchol = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsvchol')
        if __cusolverSpScsrlsvchol == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsvchol = dlsym(handle, 'cusolverSpScsrlsvchol')

        global __cusolverSpDcsrlsvchol
        __cusolverSpDcsrlsvchol = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsvchol')
        if __cusolverSpDcsrlsvchol == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsvchol = dlsym(handle, 'cusolverSpDcsrlsvchol')

        global __cusolverSpCcsrlsvchol
        __cusolverSpCcsrlsvchol = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsvchol')
        if __cusolverSpCcsrlsvchol == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsvchol = dlsym(handle, 'cusolverSpCcsrlsvchol')

        global __cusolverSpZcsrlsvchol
        __cusolverSpZcsrlsvchol = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsvchol')
        if __cusolverSpZcsrlsvchol == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsvchol = dlsym(handle, 'cusolverSpZcsrlsvchol')

        global __cusolverSpScsrlsqvqrHost
        __cusolverSpScsrlsqvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsrlsqvqrHost')
        if __cusolverSpScsrlsqvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrlsqvqrHost = dlsym(handle, 'cusolverSpScsrlsqvqrHost')

        global __cusolverSpDcsrlsqvqrHost
        __cusolverSpDcsrlsqvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrlsqvqrHost')
        if __cusolverSpDcsrlsqvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrlsqvqrHost = dlsym(handle, 'cusolverSpDcsrlsqvqrHost')

        global __cusolverSpCcsrlsqvqrHost
        __cusolverSpCcsrlsqvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrlsqvqrHost')
        if __cusolverSpCcsrlsqvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrlsqvqrHost = dlsym(handle, 'cusolverSpCcsrlsqvqrHost')

        global __cusolverSpZcsrlsqvqrHost
        __cusolverSpZcsrlsqvqrHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrlsqvqrHost')
        if __cusolverSpZcsrlsqvqrHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrlsqvqrHost = dlsym(handle, 'cusolverSpZcsrlsqvqrHost')

        global __cusolverSpScsreigvsiHost
        __cusolverSpScsreigvsiHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsreigvsiHost')
        if __cusolverSpScsreigvsiHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsreigvsiHost = dlsym(handle, 'cusolverSpScsreigvsiHost')

        global __cusolverSpDcsreigvsiHost
        __cusolverSpDcsreigvsiHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsreigvsiHost')
        if __cusolverSpDcsreigvsiHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsreigvsiHost = dlsym(handle, 'cusolverSpDcsreigvsiHost')

        global __cusolverSpCcsreigvsiHost
        __cusolverSpCcsreigvsiHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsreigvsiHost')
        if __cusolverSpCcsreigvsiHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsreigvsiHost = dlsym(handle, 'cusolverSpCcsreigvsiHost')

        global __cusolverSpZcsreigvsiHost
        __cusolverSpZcsreigvsiHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsreigvsiHost')
        if __cusolverSpZcsreigvsiHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsreigvsiHost = dlsym(handle, 'cusolverSpZcsreigvsiHost')

        global __cusolverSpScsreigvsi
        __cusolverSpScsreigvsi = dlsym(RTLD_DEFAULT, 'cusolverSpScsreigvsi')
        if __cusolverSpScsreigvsi == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsreigvsi = dlsym(handle, 'cusolverSpScsreigvsi')

        global __cusolverSpDcsreigvsi
        __cusolverSpDcsreigvsi = dlsym(RTLD_DEFAULT, 'cusolverSpDcsreigvsi')
        if __cusolverSpDcsreigvsi == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsreigvsi = dlsym(handle, 'cusolverSpDcsreigvsi')

        global __cusolverSpCcsreigvsi
        __cusolverSpCcsreigvsi = dlsym(RTLD_DEFAULT, 'cusolverSpCcsreigvsi')
        if __cusolverSpCcsreigvsi == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsreigvsi = dlsym(handle, 'cusolverSpCcsreigvsi')

        global __cusolverSpZcsreigvsi
        __cusolverSpZcsreigvsi = dlsym(RTLD_DEFAULT, 'cusolverSpZcsreigvsi')
        if __cusolverSpZcsreigvsi == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsreigvsi = dlsym(handle, 'cusolverSpZcsreigvsi')

        global __cusolverSpScsreigsHost
        __cusolverSpScsreigsHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsreigsHost')
        if __cusolverSpScsreigsHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsreigsHost = dlsym(handle, 'cusolverSpScsreigsHost')

        global __cusolverSpDcsreigsHost
        __cusolverSpDcsreigsHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsreigsHost')
        if __cusolverSpDcsreigsHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsreigsHost = dlsym(handle, 'cusolverSpDcsreigsHost')

        global __cusolverSpCcsreigsHost
        __cusolverSpCcsreigsHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsreigsHost')
        if __cusolverSpCcsreigsHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsreigsHost = dlsym(handle, 'cusolverSpCcsreigsHost')

        global __cusolverSpZcsreigsHost
        __cusolverSpZcsreigsHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsreigsHost')
        if __cusolverSpZcsreigsHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsreigsHost = dlsym(handle, 'cusolverSpZcsreigsHost')

        global __cusolverSpXcsrsymrcmHost
        __cusolverSpXcsrsymrcmHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrsymrcmHost')
        if __cusolverSpXcsrsymrcmHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrsymrcmHost = dlsym(handle, 'cusolverSpXcsrsymrcmHost')

        global __cusolverSpXcsrsymmdqHost
        __cusolverSpXcsrsymmdqHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrsymmdqHost')
        if __cusolverSpXcsrsymmdqHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrsymmdqHost = dlsym(handle, 'cusolverSpXcsrsymmdqHost')

        global __cusolverSpXcsrsymamdHost
        __cusolverSpXcsrsymamdHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrsymamdHost')
        if __cusolverSpXcsrsymamdHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrsymamdHost = dlsym(handle, 'cusolverSpXcsrsymamdHost')

        global __cusolverSpXcsrmetisndHost
        __cusolverSpXcsrmetisndHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrmetisndHost')
        if __cusolverSpXcsrmetisndHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrmetisndHost = dlsym(handle, 'cusolverSpXcsrmetisndHost')

        global __cusolverSpScsrzfdHost
        __cusolverSpScsrzfdHost = dlsym(RTLD_DEFAULT, 'cusolverSpScsrzfdHost')
        if __cusolverSpScsrzfdHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrzfdHost = dlsym(handle, 'cusolverSpScsrzfdHost')

        global __cusolverSpDcsrzfdHost
        __cusolverSpDcsrzfdHost = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrzfdHost')
        if __cusolverSpDcsrzfdHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrzfdHost = dlsym(handle, 'cusolverSpDcsrzfdHost')

        global __cusolverSpCcsrzfdHost
        __cusolverSpCcsrzfdHost = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrzfdHost')
        if __cusolverSpCcsrzfdHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrzfdHost = dlsym(handle, 'cusolverSpCcsrzfdHost')

        global __cusolverSpZcsrzfdHost
        __cusolverSpZcsrzfdHost = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrzfdHost')
        if __cusolverSpZcsrzfdHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrzfdHost = dlsym(handle, 'cusolverSpZcsrzfdHost')

        global __cusolverSpXcsrperm_bufferSizeHost
        __cusolverSpXcsrperm_bufferSizeHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrperm_bufferSizeHost')
        if __cusolverSpXcsrperm_bufferSizeHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrperm_bufferSizeHost = dlsym(handle, 'cusolverSpXcsrperm_bufferSizeHost')

        global __cusolverSpXcsrpermHost
        __cusolverSpXcsrpermHost = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrpermHost')
        if __cusolverSpXcsrpermHost == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrpermHost = dlsym(handle, 'cusolverSpXcsrpermHost')

        global __cusolverSpCreateCsrqrInfo
        __cusolverSpCreateCsrqrInfo = dlsym(RTLD_DEFAULT, 'cusolverSpCreateCsrqrInfo')
        if __cusolverSpCreateCsrqrInfo == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCreateCsrqrInfo = dlsym(handle, 'cusolverSpCreateCsrqrInfo')

        global __cusolverSpDestroyCsrqrInfo
        __cusolverSpDestroyCsrqrInfo = dlsym(RTLD_DEFAULT, 'cusolverSpDestroyCsrqrInfo')
        if __cusolverSpDestroyCsrqrInfo == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDestroyCsrqrInfo = dlsym(handle, 'cusolverSpDestroyCsrqrInfo')

        global __cusolverSpXcsrqrAnalysisBatched
        __cusolverSpXcsrqrAnalysisBatched = dlsym(RTLD_DEFAULT, 'cusolverSpXcsrqrAnalysisBatched')
        if __cusolverSpXcsrqrAnalysisBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpXcsrqrAnalysisBatched = dlsym(handle, 'cusolverSpXcsrqrAnalysisBatched')

        global __cusolverSpScsrqrBufferInfoBatched
        __cusolverSpScsrqrBufferInfoBatched = dlsym(RTLD_DEFAULT, 'cusolverSpScsrqrBufferInfoBatched')
        if __cusolverSpScsrqrBufferInfoBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrqrBufferInfoBatched = dlsym(handle, 'cusolverSpScsrqrBufferInfoBatched')

        global __cusolverSpDcsrqrBufferInfoBatched
        __cusolverSpDcsrqrBufferInfoBatched = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrqrBufferInfoBatched')
        if __cusolverSpDcsrqrBufferInfoBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrqrBufferInfoBatched = dlsym(handle, 'cusolverSpDcsrqrBufferInfoBatched')

        global __cusolverSpCcsrqrBufferInfoBatched
        __cusolverSpCcsrqrBufferInfoBatched = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrqrBufferInfoBatched')
        if __cusolverSpCcsrqrBufferInfoBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrqrBufferInfoBatched = dlsym(handle, 'cusolverSpCcsrqrBufferInfoBatched')

        global __cusolverSpZcsrqrBufferInfoBatched
        __cusolverSpZcsrqrBufferInfoBatched = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrqrBufferInfoBatched')
        if __cusolverSpZcsrqrBufferInfoBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrqrBufferInfoBatched = dlsym(handle, 'cusolverSpZcsrqrBufferInfoBatched')

        global __cusolverSpScsrqrsvBatched
        __cusolverSpScsrqrsvBatched = dlsym(RTLD_DEFAULT, 'cusolverSpScsrqrsvBatched')
        if __cusolverSpScsrqrsvBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpScsrqrsvBatched = dlsym(handle, 'cusolverSpScsrqrsvBatched')

        global __cusolverSpDcsrqrsvBatched
        __cusolverSpDcsrqrsvBatched = dlsym(RTLD_DEFAULT, 'cusolverSpDcsrqrsvBatched')
        if __cusolverSpDcsrqrsvBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpDcsrqrsvBatched = dlsym(handle, 'cusolverSpDcsrqrsvBatched')

        global __cusolverSpCcsrqrsvBatched
        __cusolverSpCcsrqrsvBatched = dlsym(RTLD_DEFAULT, 'cusolverSpCcsrqrsvBatched')
        if __cusolverSpCcsrqrsvBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpCcsrqrsvBatched = dlsym(handle, 'cusolverSpCcsrqrsvBatched')

        global __cusolverSpZcsrqrsvBatched
        __cusolverSpZcsrqrsvBatched = dlsym(RTLD_DEFAULT, 'cusolverSpZcsrqrsvBatched')
        if __cusolverSpZcsrqrsvBatched == NULL:
            if handle == NULL:
                handle = load_library(driver_ver)
            __cusolverSpZcsrqrsvBatched = dlsym(handle, 'cusolverSpZcsrqrsvBatched')

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
