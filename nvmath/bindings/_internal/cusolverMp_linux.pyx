# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 0.7.2 to 0.8.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

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
cdef bint __py_cusolverMp_init = False

cdef void* __cusolverMpCreate = NULL
cdef void* __cusolverMpDestroy = NULL
cdef void* __cusolverMpGetStream = NULL
cdef void* __cusolverMpGetVersion = NULL
cdef void* __cusolverMpCreateDeviceGrid = NULL
cdef void* __cusolverMpDestroyGrid = NULL
cdef void* __cusolverMpCreateMatrixDesc = NULL
cdef void* __cusolverMpDestroyMatrixDesc = NULL
cdef void* __cusolverMpNUMROC = NULL
cdef void* __cusolverMpMatrixScatterH2D = NULL
cdef void* __cusolverMpMatrixGatherD2H = NULL
cdef void* __cusolverMpGetrf_bufferSize = NULL
cdef void* __cusolverMpGetrf = NULL
cdef void* __cusolverMpGetrs_bufferSize = NULL
cdef void* __cusolverMpGetrs = NULL
cdef void* __cusolverMpPotrf_bufferSize = NULL
cdef void* __cusolverMpPotrf = NULL
cdef void* __cusolverMpPotrs_bufferSize = NULL
cdef void* __cusolverMpPotrs = NULL
cdef void* __cusolverMpOrmqr_bufferSize = NULL
cdef void* __cusolverMpOrmqr = NULL
cdef void* __cusolverMpOrmtr_bufferSize = NULL
cdef void* __cusolverMpOrmtr = NULL
cdef void* __cusolverMpGels_bufferSize = NULL
cdef void* __cusolverMpGels = NULL
cdef void* __cusolverMpStedc_bufferSize = NULL
cdef void* __cusolverMpStedc = NULL
cdef void* __cusolverMpGeqrf_bufferSize = NULL
cdef void* __cusolverMpGeqrf = NULL
cdef void* __cusolverMpSytrd_bufferSize = NULL
cdef void* __cusolverMpSytrd = NULL
cdef void* __cusolverMpSyevd_bufferSize = NULL
cdef void* __cusolverMpSyevd = NULL
cdef void* __cusolverMpSygst_bufferSize = NULL
cdef void* __cusolverMpSygst = NULL
cdef void* __cusolverMpSygvd_bufferSize = NULL
cdef void* __cusolverMpSygvd = NULL
cdef void* __cusolverMpLoggerSetFile = NULL
cdef void* __cusolverMpLoggerOpenFile = NULL
cdef void* __cusolverMpLoggerSetLevel = NULL
cdef void* __cusolverMpLoggerSetMask = NULL
cdef void* __cusolverMpLoggerForceDisable = NULL
cdef void* __cusolverMpSetMathMode = NULL
cdef void* __cusolverMpGetMathMode = NULL
cdef void* __cusolverMpSetEmulationStrategy = NULL
cdef void* __cusolverMpGetEmulationStrategy = NULL
cdef void* __cusolverMpNewtonSchulzDescriptorCreate = NULL
cdef void* __cusolverMpNewtonSchulzDescriptorDestroy = NULL
cdef void* __cusolverMpNewtonSchulzDescriptorSetAttribute = NULL
cdef void* __cusolverMpNewtonSchulzDescriptorGetAttribute = NULL
cdef void* __cusolverMpSetStream = NULL
cdef void* __cusolverMpBufferRegister = NULL
cdef void* __cusolverMpBufferDeregister = NULL
cdef void* __cusolverMpOrgqr_bufferSize = NULL
cdef void* __cusolverMpOrgqr = NULL
cdef void* __cusolverMpLaset = NULL
cdef void* __cusolverMpNewtonSchulz_bufferSize = NULL
cdef void* __cusolverMpNewtonSchulz = NULL


cdef void* load_library() except* with gil:
    cdef uintptr_t handle = load_nvidia_dynamic_lib("cusolverMp")._handle_uint
    return <void*>handle


cdef int _check_or_init_cusolverMp() except -1 nogil:
    global __py_cusolverMp_init
    if __py_cusolverMp_init:
        return 0

    cdef void* handle = NULL

    with gil, __symbol_lock:
        # Recheck the flag after obtaining the locks
        if __py_cusolverMp_init:
            return 0

        # Load function
        global __cusolverMpCreate
        __cusolverMpCreate = dlsym(RTLD_DEFAULT, 'cusolverMpCreate')
        if __cusolverMpCreate == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpCreate = dlsym(handle, 'cusolverMpCreate')

        global __cusolverMpDestroy
        __cusolverMpDestroy = dlsym(RTLD_DEFAULT, 'cusolverMpDestroy')
        if __cusolverMpDestroy == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpDestroy = dlsym(handle, 'cusolverMpDestroy')

        global __cusolverMpGetStream
        __cusolverMpGetStream = dlsym(RTLD_DEFAULT, 'cusolverMpGetStream')
        if __cusolverMpGetStream == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetStream = dlsym(handle, 'cusolverMpGetStream')

        global __cusolverMpGetVersion
        __cusolverMpGetVersion = dlsym(RTLD_DEFAULT, 'cusolverMpGetVersion')
        if __cusolverMpGetVersion == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetVersion = dlsym(handle, 'cusolverMpGetVersion')

        global __cusolverMpCreateDeviceGrid
        __cusolverMpCreateDeviceGrid = dlsym(RTLD_DEFAULT, 'cusolverMpCreateDeviceGrid')
        if __cusolverMpCreateDeviceGrid == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpCreateDeviceGrid = dlsym(handle, 'cusolverMpCreateDeviceGrid')

        global __cusolverMpDestroyGrid
        __cusolverMpDestroyGrid = dlsym(RTLD_DEFAULT, 'cusolverMpDestroyGrid')
        if __cusolverMpDestroyGrid == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpDestroyGrid = dlsym(handle, 'cusolverMpDestroyGrid')

        global __cusolverMpCreateMatrixDesc
        __cusolverMpCreateMatrixDesc = dlsym(RTLD_DEFAULT, 'cusolverMpCreateMatrixDesc')
        if __cusolverMpCreateMatrixDesc == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpCreateMatrixDesc = dlsym(handle, 'cusolverMpCreateMatrixDesc')

        global __cusolverMpDestroyMatrixDesc
        __cusolverMpDestroyMatrixDesc = dlsym(RTLD_DEFAULT, 'cusolverMpDestroyMatrixDesc')
        if __cusolverMpDestroyMatrixDesc == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpDestroyMatrixDesc = dlsym(handle, 'cusolverMpDestroyMatrixDesc')

        global __cusolverMpNUMROC
        __cusolverMpNUMROC = dlsym(RTLD_DEFAULT, 'cusolverMpNUMROC')
        if __cusolverMpNUMROC == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNUMROC = dlsym(handle, 'cusolverMpNUMROC')

        global __cusolverMpMatrixScatterH2D
        __cusolverMpMatrixScatterH2D = dlsym(RTLD_DEFAULT, 'cusolverMpMatrixScatterH2D')
        if __cusolverMpMatrixScatterH2D == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpMatrixScatterH2D = dlsym(handle, 'cusolverMpMatrixScatterH2D')

        global __cusolverMpMatrixGatherD2H
        __cusolverMpMatrixGatherD2H = dlsym(RTLD_DEFAULT, 'cusolverMpMatrixGatherD2H')
        if __cusolverMpMatrixGatherD2H == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpMatrixGatherD2H = dlsym(handle, 'cusolverMpMatrixGatherD2H')

        global __cusolverMpGetrf_bufferSize
        __cusolverMpGetrf_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpGetrf_bufferSize')
        if __cusolverMpGetrf_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetrf_bufferSize = dlsym(handle, 'cusolverMpGetrf_bufferSize')

        global __cusolverMpGetrf
        __cusolverMpGetrf = dlsym(RTLD_DEFAULT, 'cusolverMpGetrf')
        if __cusolverMpGetrf == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetrf = dlsym(handle, 'cusolverMpGetrf')

        global __cusolverMpGetrs_bufferSize
        __cusolverMpGetrs_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpGetrs_bufferSize')
        if __cusolverMpGetrs_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetrs_bufferSize = dlsym(handle, 'cusolverMpGetrs_bufferSize')

        global __cusolverMpGetrs
        __cusolverMpGetrs = dlsym(RTLD_DEFAULT, 'cusolverMpGetrs')
        if __cusolverMpGetrs == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetrs = dlsym(handle, 'cusolverMpGetrs')

        global __cusolverMpPotrf_bufferSize
        __cusolverMpPotrf_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpPotrf_bufferSize')
        if __cusolverMpPotrf_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpPotrf_bufferSize = dlsym(handle, 'cusolverMpPotrf_bufferSize')

        global __cusolverMpPotrf
        __cusolverMpPotrf = dlsym(RTLD_DEFAULT, 'cusolverMpPotrf')
        if __cusolverMpPotrf == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpPotrf = dlsym(handle, 'cusolverMpPotrf')

        global __cusolverMpPotrs_bufferSize
        __cusolverMpPotrs_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpPotrs_bufferSize')
        if __cusolverMpPotrs_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpPotrs_bufferSize = dlsym(handle, 'cusolverMpPotrs_bufferSize')

        global __cusolverMpPotrs
        __cusolverMpPotrs = dlsym(RTLD_DEFAULT, 'cusolverMpPotrs')
        if __cusolverMpPotrs == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpPotrs = dlsym(handle, 'cusolverMpPotrs')

        global __cusolverMpOrmqr_bufferSize
        __cusolverMpOrmqr_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpOrmqr_bufferSize')
        if __cusolverMpOrmqr_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrmqr_bufferSize = dlsym(handle, 'cusolverMpOrmqr_bufferSize')

        global __cusolverMpOrmqr
        __cusolverMpOrmqr = dlsym(RTLD_DEFAULT, 'cusolverMpOrmqr')
        if __cusolverMpOrmqr == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrmqr = dlsym(handle, 'cusolverMpOrmqr')

        global __cusolverMpOrmtr_bufferSize
        __cusolverMpOrmtr_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpOrmtr_bufferSize')
        if __cusolverMpOrmtr_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrmtr_bufferSize = dlsym(handle, 'cusolverMpOrmtr_bufferSize')

        global __cusolverMpOrmtr
        __cusolverMpOrmtr = dlsym(RTLD_DEFAULT, 'cusolverMpOrmtr')
        if __cusolverMpOrmtr == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrmtr = dlsym(handle, 'cusolverMpOrmtr')

        global __cusolverMpGels_bufferSize
        __cusolverMpGels_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpGels_bufferSize')
        if __cusolverMpGels_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGels_bufferSize = dlsym(handle, 'cusolverMpGels_bufferSize')

        global __cusolverMpGels
        __cusolverMpGels = dlsym(RTLD_DEFAULT, 'cusolverMpGels')
        if __cusolverMpGels == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGels = dlsym(handle, 'cusolverMpGels')

        global __cusolverMpStedc_bufferSize
        __cusolverMpStedc_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpStedc_bufferSize')
        if __cusolverMpStedc_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpStedc_bufferSize = dlsym(handle, 'cusolverMpStedc_bufferSize')

        global __cusolverMpStedc
        __cusolverMpStedc = dlsym(RTLD_DEFAULT, 'cusolverMpStedc')
        if __cusolverMpStedc == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpStedc = dlsym(handle, 'cusolverMpStedc')

        global __cusolverMpGeqrf_bufferSize
        __cusolverMpGeqrf_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpGeqrf_bufferSize')
        if __cusolverMpGeqrf_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGeqrf_bufferSize = dlsym(handle, 'cusolverMpGeqrf_bufferSize')

        global __cusolverMpGeqrf
        __cusolverMpGeqrf = dlsym(RTLD_DEFAULT, 'cusolverMpGeqrf')
        if __cusolverMpGeqrf == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGeqrf = dlsym(handle, 'cusolverMpGeqrf')

        global __cusolverMpSytrd_bufferSize
        __cusolverMpSytrd_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpSytrd_bufferSize')
        if __cusolverMpSytrd_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSytrd_bufferSize = dlsym(handle, 'cusolverMpSytrd_bufferSize')

        global __cusolverMpSytrd
        __cusolverMpSytrd = dlsym(RTLD_DEFAULT, 'cusolverMpSytrd')
        if __cusolverMpSytrd == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSytrd = dlsym(handle, 'cusolverMpSytrd')

        global __cusolverMpSyevd_bufferSize
        __cusolverMpSyevd_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpSyevd_bufferSize')
        if __cusolverMpSyevd_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSyevd_bufferSize = dlsym(handle, 'cusolverMpSyevd_bufferSize')

        global __cusolverMpSyevd
        __cusolverMpSyevd = dlsym(RTLD_DEFAULT, 'cusolverMpSyevd')
        if __cusolverMpSyevd == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSyevd = dlsym(handle, 'cusolverMpSyevd')

        global __cusolverMpSygst_bufferSize
        __cusolverMpSygst_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpSygst_bufferSize')
        if __cusolverMpSygst_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSygst_bufferSize = dlsym(handle, 'cusolverMpSygst_bufferSize')

        global __cusolverMpSygst
        __cusolverMpSygst = dlsym(RTLD_DEFAULT, 'cusolverMpSygst')
        if __cusolverMpSygst == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSygst = dlsym(handle, 'cusolverMpSygst')

        global __cusolverMpSygvd_bufferSize
        __cusolverMpSygvd_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpSygvd_bufferSize')
        if __cusolverMpSygvd_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSygvd_bufferSize = dlsym(handle, 'cusolverMpSygvd_bufferSize')

        global __cusolverMpSygvd
        __cusolverMpSygvd = dlsym(RTLD_DEFAULT, 'cusolverMpSygvd')
        if __cusolverMpSygvd == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSygvd = dlsym(handle, 'cusolverMpSygvd')

        global __cusolverMpLoggerSetFile
        __cusolverMpLoggerSetFile = dlsym(RTLD_DEFAULT, 'cusolverMpLoggerSetFile')
        if __cusolverMpLoggerSetFile == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLoggerSetFile = dlsym(handle, 'cusolverMpLoggerSetFile')

        global __cusolverMpLoggerOpenFile
        __cusolverMpLoggerOpenFile = dlsym(RTLD_DEFAULT, 'cusolverMpLoggerOpenFile')
        if __cusolverMpLoggerOpenFile == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLoggerOpenFile = dlsym(handle, 'cusolverMpLoggerOpenFile')

        global __cusolverMpLoggerSetLevel
        __cusolverMpLoggerSetLevel = dlsym(RTLD_DEFAULT, 'cusolverMpLoggerSetLevel')
        if __cusolverMpLoggerSetLevel == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLoggerSetLevel = dlsym(handle, 'cusolverMpLoggerSetLevel')

        global __cusolverMpLoggerSetMask
        __cusolverMpLoggerSetMask = dlsym(RTLD_DEFAULT, 'cusolverMpLoggerSetMask')
        if __cusolverMpLoggerSetMask == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLoggerSetMask = dlsym(handle, 'cusolverMpLoggerSetMask')

        global __cusolverMpLoggerForceDisable
        __cusolverMpLoggerForceDisable = dlsym(RTLD_DEFAULT, 'cusolverMpLoggerForceDisable')
        if __cusolverMpLoggerForceDisable == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLoggerForceDisable = dlsym(handle, 'cusolverMpLoggerForceDisable')

        global __cusolverMpSetMathMode
        __cusolverMpSetMathMode = dlsym(RTLD_DEFAULT, 'cusolverMpSetMathMode')
        if __cusolverMpSetMathMode == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSetMathMode = dlsym(handle, 'cusolverMpSetMathMode')

        global __cusolverMpGetMathMode
        __cusolverMpGetMathMode = dlsym(RTLD_DEFAULT, 'cusolverMpGetMathMode')
        if __cusolverMpGetMathMode == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetMathMode = dlsym(handle, 'cusolverMpGetMathMode')

        global __cusolverMpSetEmulationStrategy
        __cusolverMpSetEmulationStrategy = dlsym(RTLD_DEFAULT, 'cusolverMpSetEmulationStrategy')
        if __cusolverMpSetEmulationStrategy == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSetEmulationStrategy = dlsym(handle, 'cusolverMpSetEmulationStrategy')

        global __cusolverMpGetEmulationStrategy
        __cusolverMpGetEmulationStrategy = dlsym(RTLD_DEFAULT, 'cusolverMpGetEmulationStrategy')
        if __cusolverMpGetEmulationStrategy == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpGetEmulationStrategy = dlsym(handle, 'cusolverMpGetEmulationStrategy')

        global __cusolverMpNewtonSchulzDescriptorCreate
        __cusolverMpNewtonSchulzDescriptorCreate = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulzDescriptorCreate')
        if __cusolverMpNewtonSchulzDescriptorCreate == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulzDescriptorCreate = dlsym(handle, 'cusolverMpNewtonSchulzDescriptorCreate')

        global __cusolverMpNewtonSchulzDescriptorDestroy
        __cusolverMpNewtonSchulzDescriptorDestroy = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulzDescriptorDestroy')
        if __cusolverMpNewtonSchulzDescriptorDestroy == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulzDescriptorDestroy = dlsym(handle, 'cusolverMpNewtonSchulzDescriptorDestroy')

        global __cusolverMpNewtonSchulzDescriptorSetAttribute
        __cusolverMpNewtonSchulzDescriptorSetAttribute = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulzDescriptorSetAttribute')
        if __cusolverMpNewtonSchulzDescriptorSetAttribute == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulzDescriptorSetAttribute = dlsym(handle, 'cusolverMpNewtonSchulzDescriptorSetAttribute')

        global __cusolverMpNewtonSchulzDescriptorGetAttribute
        __cusolverMpNewtonSchulzDescriptorGetAttribute = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulzDescriptorGetAttribute')
        if __cusolverMpNewtonSchulzDescriptorGetAttribute == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulzDescriptorGetAttribute = dlsym(handle, 'cusolverMpNewtonSchulzDescriptorGetAttribute')

        global __cusolverMpSetStream
        __cusolverMpSetStream = dlsym(RTLD_DEFAULT, 'cusolverMpSetStream')
        if __cusolverMpSetStream == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpSetStream = dlsym(handle, 'cusolverMpSetStream')

        global __cusolverMpBufferRegister
        __cusolverMpBufferRegister = dlsym(RTLD_DEFAULT, 'cusolverMpBufferRegister')
        if __cusolverMpBufferRegister == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpBufferRegister = dlsym(handle, 'cusolverMpBufferRegister')

        global __cusolverMpBufferDeregister
        __cusolverMpBufferDeregister = dlsym(RTLD_DEFAULT, 'cusolverMpBufferDeregister')
        if __cusolverMpBufferDeregister == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpBufferDeregister = dlsym(handle, 'cusolverMpBufferDeregister')

        global __cusolverMpOrgqr_bufferSize
        __cusolverMpOrgqr_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpOrgqr_bufferSize')
        if __cusolverMpOrgqr_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrgqr_bufferSize = dlsym(handle, 'cusolverMpOrgqr_bufferSize')

        global __cusolverMpOrgqr
        __cusolverMpOrgqr = dlsym(RTLD_DEFAULT, 'cusolverMpOrgqr')
        if __cusolverMpOrgqr == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpOrgqr = dlsym(handle, 'cusolverMpOrgqr')

        global __cusolverMpLaset
        __cusolverMpLaset = dlsym(RTLD_DEFAULT, 'cusolverMpLaset')
        if __cusolverMpLaset == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpLaset = dlsym(handle, 'cusolverMpLaset')

        global __cusolverMpNewtonSchulz_bufferSize
        __cusolverMpNewtonSchulz_bufferSize = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulz_bufferSize')
        if __cusolverMpNewtonSchulz_bufferSize == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulz_bufferSize = dlsym(handle, 'cusolverMpNewtonSchulz_bufferSize')

        global __cusolverMpNewtonSchulz
        __cusolverMpNewtonSchulz = dlsym(RTLD_DEFAULT, 'cusolverMpNewtonSchulz')
        if __cusolverMpNewtonSchulz == NULL:
            if handle == NULL:
                handle = load_library()
            __cusolverMpNewtonSchulz = dlsym(handle, 'cusolverMpNewtonSchulz')
        __py_cusolverMp_init = True
        return 0


cdef dict func_ptrs = None


cpdef dict _inspect_function_pointers():
    global func_ptrs
    if func_ptrs is not None:
        return func_ptrs

    _check_or_init_cusolverMp()
    cdef dict data = {}

    global __cusolverMpCreate
    data["__cusolverMpCreate"] = <intptr_t>__cusolverMpCreate

    global __cusolverMpDestroy
    data["__cusolverMpDestroy"] = <intptr_t>__cusolverMpDestroy

    global __cusolverMpGetStream
    data["__cusolverMpGetStream"] = <intptr_t>__cusolverMpGetStream

    global __cusolverMpGetVersion
    data["__cusolverMpGetVersion"] = <intptr_t>__cusolverMpGetVersion

    global __cusolverMpCreateDeviceGrid
    data["__cusolverMpCreateDeviceGrid"] = <intptr_t>__cusolverMpCreateDeviceGrid

    global __cusolverMpDestroyGrid
    data["__cusolverMpDestroyGrid"] = <intptr_t>__cusolverMpDestroyGrid

    global __cusolverMpCreateMatrixDesc
    data["__cusolverMpCreateMatrixDesc"] = <intptr_t>__cusolverMpCreateMatrixDesc

    global __cusolverMpDestroyMatrixDesc
    data["__cusolverMpDestroyMatrixDesc"] = <intptr_t>__cusolverMpDestroyMatrixDesc

    global __cusolverMpNUMROC
    data["__cusolverMpNUMROC"] = <intptr_t>__cusolverMpNUMROC

    global __cusolverMpMatrixScatterH2D
    data["__cusolverMpMatrixScatterH2D"] = <intptr_t>__cusolverMpMatrixScatterH2D

    global __cusolverMpMatrixGatherD2H
    data["__cusolverMpMatrixGatherD2H"] = <intptr_t>__cusolverMpMatrixGatherD2H

    global __cusolverMpGetrf_bufferSize
    data["__cusolverMpGetrf_bufferSize"] = <intptr_t>__cusolverMpGetrf_bufferSize

    global __cusolverMpGetrf
    data["__cusolverMpGetrf"] = <intptr_t>__cusolverMpGetrf

    global __cusolverMpGetrs_bufferSize
    data["__cusolverMpGetrs_bufferSize"] = <intptr_t>__cusolverMpGetrs_bufferSize

    global __cusolverMpGetrs
    data["__cusolverMpGetrs"] = <intptr_t>__cusolverMpGetrs

    global __cusolverMpPotrf_bufferSize
    data["__cusolverMpPotrf_bufferSize"] = <intptr_t>__cusolverMpPotrf_bufferSize

    global __cusolverMpPotrf
    data["__cusolverMpPotrf"] = <intptr_t>__cusolverMpPotrf

    global __cusolverMpPotrs_bufferSize
    data["__cusolverMpPotrs_bufferSize"] = <intptr_t>__cusolverMpPotrs_bufferSize

    global __cusolverMpPotrs
    data["__cusolverMpPotrs"] = <intptr_t>__cusolverMpPotrs

    global __cusolverMpOrmqr_bufferSize
    data["__cusolverMpOrmqr_bufferSize"] = <intptr_t>__cusolverMpOrmqr_bufferSize

    global __cusolverMpOrmqr
    data["__cusolverMpOrmqr"] = <intptr_t>__cusolverMpOrmqr

    global __cusolverMpOrmtr_bufferSize
    data["__cusolverMpOrmtr_bufferSize"] = <intptr_t>__cusolverMpOrmtr_bufferSize

    global __cusolverMpOrmtr
    data["__cusolverMpOrmtr"] = <intptr_t>__cusolverMpOrmtr

    global __cusolverMpGels_bufferSize
    data["__cusolverMpGels_bufferSize"] = <intptr_t>__cusolverMpGels_bufferSize

    global __cusolverMpGels
    data["__cusolverMpGels"] = <intptr_t>__cusolverMpGels

    global __cusolverMpStedc_bufferSize
    data["__cusolverMpStedc_bufferSize"] = <intptr_t>__cusolverMpStedc_bufferSize

    global __cusolverMpStedc
    data["__cusolverMpStedc"] = <intptr_t>__cusolverMpStedc

    global __cusolverMpGeqrf_bufferSize
    data["__cusolverMpGeqrf_bufferSize"] = <intptr_t>__cusolverMpGeqrf_bufferSize

    global __cusolverMpGeqrf
    data["__cusolverMpGeqrf"] = <intptr_t>__cusolverMpGeqrf

    global __cusolverMpSytrd_bufferSize
    data["__cusolverMpSytrd_bufferSize"] = <intptr_t>__cusolverMpSytrd_bufferSize

    global __cusolverMpSytrd
    data["__cusolverMpSytrd"] = <intptr_t>__cusolverMpSytrd

    global __cusolverMpSyevd_bufferSize
    data["__cusolverMpSyevd_bufferSize"] = <intptr_t>__cusolverMpSyevd_bufferSize

    global __cusolverMpSyevd
    data["__cusolverMpSyevd"] = <intptr_t>__cusolverMpSyevd

    global __cusolverMpSygst_bufferSize
    data["__cusolverMpSygst_bufferSize"] = <intptr_t>__cusolverMpSygst_bufferSize

    global __cusolverMpSygst
    data["__cusolverMpSygst"] = <intptr_t>__cusolverMpSygst

    global __cusolverMpSygvd_bufferSize
    data["__cusolverMpSygvd_bufferSize"] = <intptr_t>__cusolverMpSygvd_bufferSize

    global __cusolverMpSygvd
    data["__cusolverMpSygvd"] = <intptr_t>__cusolverMpSygvd

    global __cusolverMpLoggerSetFile
    data["__cusolverMpLoggerSetFile"] = <intptr_t>__cusolverMpLoggerSetFile

    global __cusolverMpLoggerOpenFile
    data["__cusolverMpLoggerOpenFile"] = <intptr_t>__cusolverMpLoggerOpenFile

    global __cusolverMpLoggerSetLevel
    data["__cusolverMpLoggerSetLevel"] = <intptr_t>__cusolverMpLoggerSetLevel

    global __cusolverMpLoggerSetMask
    data["__cusolverMpLoggerSetMask"] = <intptr_t>__cusolverMpLoggerSetMask

    global __cusolverMpLoggerForceDisable
    data["__cusolverMpLoggerForceDisable"] = <intptr_t>__cusolverMpLoggerForceDisable

    global __cusolverMpSetMathMode
    data["__cusolverMpSetMathMode"] = <intptr_t>__cusolverMpSetMathMode

    global __cusolverMpGetMathMode
    data["__cusolverMpGetMathMode"] = <intptr_t>__cusolverMpGetMathMode

    global __cusolverMpSetEmulationStrategy
    data["__cusolverMpSetEmulationStrategy"] = <intptr_t>__cusolverMpSetEmulationStrategy

    global __cusolverMpGetEmulationStrategy
    data["__cusolverMpGetEmulationStrategy"] = <intptr_t>__cusolverMpGetEmulationStrategy

    global __cusolverMpNewtonSchulzDescriptorCreate
    data["__cusolverMpNewtonSchulzDescriptorCreate"] = <intptr_t>__cusolverMpNewtonSchulzDescriptorCreate

    global __cusolverMpNewtonSchulzDescriptorDestroy
    data["__cusolverMpNewtonSchulzDescriptorDestroy"] = <intptr_t>__cusolverMpNewtonSchulzDescriptorDestroy

    global __cusolverMpNewtonSchulzDescriptorSetAttribute
    data["__cusolverMpNewtonSchulzDescriptorSetAttribute"] = <intptr_t>__cusolverMpNewtonSchulzDescriptorSetAttribute

    global __cusolverMpNewtonSchulzDescriptorGetAttribute
    data["__cusolverMpNewtonSchulzDescriptorGetAttribute"] = <intptr_t>__cusolverMpNewtonSchulzDescriptorGetAttribute

    global __cusolverMpSetStream
    data["__cusolverMpSetStream"] = <intptr_t>__cusolverMpSetStream

    global __cusolverMpBufferRegister
    data["__cusolverMpBufferRegister"] = <intptr_t>__cusolverMpBufferRegister

    global __cusolverMpBufferDeregister
    data["__cusolverMpBufferDeregister"] = <intptr_t>__cusolverMpBufferDeregister

    global __cusolverMpOrgqr_bufferSize
    data["__cusolverMpOrgqr_bufferSize"] = <intptr_t>__cusolverMpOrgqr_bufferSize

    global __cusolverMpOrgqr
    data["__cusolverMpOrgqr"] = <intptr_t>__cusolverMpOrgqr

    global __cusolverMpLaset
    data["__cusolverMpLaset"] = <intptr_t>__cusolverMpLaset

    global __cusolverMpNewtonSchulz_bufferSize
    data["__cusolverMpNewtonSchulz_bufferSize"] = <intptr_t>__cusolverMpNewtonSchulz_bufferSize

    global __cusolverMpNewtonSchulz
    data["__cusolverMpNewtonSchulz"] = <intptr_t>__cusolverMpNewtonSchulz

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

cdef cusolverStatus_t _cusolverMpCreate(cusolverMpHandle_t* handle, int deviceId, cudaStream_t stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpCreate
    _check_or_init_cusolverMp()
    if __cusolverMpCreate == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpCreate is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t*, int, cudaStream_t) noexcept nogil>__cusolverMpCreate)(
        handle, deviceId, stream)


cdef cusolverStatus_t _cusolverMpDestroy(cusolverMpHandle_t handle) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpDestroy
    _check_or_init_cusolverMp()
    if __cusolverMpDestroy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpDestroy is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t) noexcept nogil>__cusolverMpDestroy)(
        handle)


cdef cusolverStatus_t _cusolverMpGetStream(cusolverMpHandle_t handle, cudaStream_t* stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetStream
    _check_or_init_cusolverMp()
    if __cusolverMpGetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetStream is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cudaStream_t*) noexcept nogil>__cusolverMpGetStream)(
        handle, stream)


cdef cusolverStatus_t _cusolverMpGetVersion(cusolverMpHandle_t handle, int* version) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetVersion
    _check_or_init_cusolverMp()
    if __cusolverMpGetVersion == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetVersion is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int*) noexcept nogil>__cusolverMpGetVersion)(
        handle, version)


cdef cusolverStatus_t _cusolverMpCreateDeviceGrid(cusolverMpHandle_t handle, cusolverMpGrid_t* grid, const ncclComm_t comm, int32_t numRowDevices, int32_t numColDevices, const cusolverMpGridMapping_t mapping) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpCreateDeviceGrid
    _check_or_init_cusolverMp()
    if __cusolverMpCreateDeviceGrid == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpCreateDeviceGrid is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverMpGrid_t*, const ncclComm_t, int32_t, int32_t, const cusolverMpGridMapping_t) noexcept nogil>__cusolverMpCreateDeviceGrid)(
        handle, grid, comm, numRowDevices, numColDevices, mapping)


cdef cusolverStatus_t _cusolverMpDestroyGrid(cusolverMpGrid_t grid) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpDestroyGrid
    _check_or_init_cusolverMp()
    if __cusolverMpDestroyGrid == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpDestroyGrid is not found")
    return (<cusolverStatus_t (*)(cusolverMpGrid_t) noexcept nogil>__cusolverMpDestroyGrid)(
        grid)


cdef cusolverStatus_t _cusolverMpCreateMatrixDesc(cusolverMpMatrixDescriptor_t* desc, cusolverMpGrid_t grid, cudaDataType dataType, int64_t M_A, int64_t N_A, int64_t MB_A, int64_t NB_A, uint32_t RSRC_A, uint32_t CSRC_A, int64_t LLD_A) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpCreateMatrixDesc
    _check_or_init_cusolverMp()
    if __cusolverMpCreateMatrixDesc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpCreateMatrixDesc is not found")
    return (<cusolverStatus_t (*)(cusolverMpMatrixDescriptor_t*, cusolverMpGrid_t, cudaDataType, int64_t, int64_t, int64_t, int64_t, uint32_t, uint32_t, int64_t) noexcept nogil>__cusolverMpCreateMatrixDesc)(
        desc, grid, dataType, M_A, N_A, MB_A, NB_A, RSRC_A, CSRC_A, LLD_A)


cdef cusolverStatus_t _cusolverMpDestroyMatrixDesc(cusolverMpMatrixDescriptor_t desc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpDestroyMatrixDesc
    _check_or_init_cusolverMp()
    if __cusolverMpDestroyMatrixDesc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpDestroyMatrixDesc is not found")
    return (<cusolverStatus_t (*)(cusolverMpMatrixDescriptor_t) noexcept nogil>__cusolverMpDestroyMatrixDesc)(
        desc)


cdef int64_t _cusolverMpNUMROC(int64_t n, int64_t nb, uint32_t iproc, uint32_t isrcproc, uint32_t nprocs) except?-42 nogil:
    global __cusolverMpNUMROC
    _check_or_init_cusolverMp()
    if __cusolverMpNUMROC == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNUMROC is not found")
    return (<int64_t (*)(int64_t, int64_t, uint32_t, uint32_t, uint32_t) noexcept nogil>__cusolverMpNUMROC)(
        n, nb, iproc, isrcproc, nprocs)


cdef cusolverStatus_t _cusolverMpMatrixScatterH2D(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int root, const void* h_src, int64_t h_ldsrc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpMatrixScatterH2D
    _check_or_init_cusolverMp()
    if __cusolverMpMatrixScatterH2D == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpMatrixScatterH2D is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int, const void*, int64_t) noexcept nogil>__cusolverMpMatrixScatterH2D)(
        handle, M, N, d_A, IA, JA, descA, root, h_src, h_ldsrc)


cdef cusolverStatus_t _cusolverMpMatrixGatherD2H(cusolverMpHandle_t handle, int64_t M, int64_t N, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int root, void* h_dst, int64_t h_lddst) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpMatrixGatherD2H
    _check_or_init_cusolverMp()
    if __cusolverMpMatrixGatherD2H == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpMatrixGatherD2H is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int, void*, int64_t) noexcept nogil>__cusolverMpMatrixGatherD2H)(
        handle, M, N, d_A, IA, JA, descA, root, h_dst, h_lddst)


cdef cusolverStatus_t _cusolverMpGetrf_bufferSize(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int64_t* d_ipiv, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetrf_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpGetrf_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetrf_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int64_t*, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpGetrf_bufferSize)(
        handle, M, N, d_A, IA, JA, descA, d_ipiv, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpGetrf(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int64_t* d_ipiv, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetrf
    _check_or_init_cusolverMp()
    if __cusolverMpGetrf == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetrf is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int64_t*, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpGetrf)(
        handle, M, N, d_A, IA, JA, descA, d_ipiv, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpGetrs_bufferSize(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t N, int64_t NRHS, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, const int64_t* d_ipiv, void* d_B, int64_t IB, int64_t JB, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetrs_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpGetrs_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetrs_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasOperation_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const int64_t*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpGetrs_bufferSize)(
        handle, trans, N, NRHS, d_A, IA, JA, descA, d_ipiv, d_B, IB, JB, descB, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpGetrs(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t N, int64_t NRHS, const void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, const int64_t* d_ipiv, void* d_B, int64_t IB, int64_t JB, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetrs
    _check_or_init_cusolverMp()
    if __cusolverMpGetrs == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetrs is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasOperation_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const int64_t*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpGetrs)(
        handle, trans, N, NRHS, d_A, IA, JA, descA, d_ipiv, d_B, IB, JB, descB, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, d_info)


cdef cusolverStatus_t _cusolverMpPotrf_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpPotrf_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpPotrf_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpPotrf_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpPotrf_bufferSize)(
        handle, uplo, n, a, ia, ja, descA, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpPotrf(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpPotrf
    _check_or_init_cusolverMp()
    if __cusolverMpPotrf == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpPotrf is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpPotrf)(
        handle, uplo, n, a, ia, ja, descA, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpPotrs_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, int64_t nrhs, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpPotrs_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpPotrs_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpPotrs_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpPotrs_bufferSize)(
        handle, uplo, n, nrhs, a, ia, ja, descA, b, ib, jb, descB, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpPotrs(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t n, int64_t nrhs, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpPotrs
    _check_or_init_cusolverMp()
    if __cusolverMpPotrs == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpPotrs is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpPotrs)(
        handle, uplo, n, nrhs, a, ia, ja, descA, b, ib, jb, descB, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpOrmqr_bufferSize(cusolverMpHandle_t handle, cublasSideMode_t side, cublasOperation_t trans, int64_t m, int64_t n, int64_t k, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrmqr_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpOrmqr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrmqr_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasSideMode_t, cublasOperation_t, int64_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpOrmqr_bufferSize)(
        handle, side, trans, m, n, k, a, ia, ja, descA, tau, c, ic, jc, descC, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpOrmqr(cusolverMpHandle_t handle, cublasSideMode_t side, cublasOperation_t trans, int64_t m, int64_t n, int64_t k, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrmqr
    _check_or_init_cusolverMp()
    if __cusolverMpOrmqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrmqr is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasSideMode_t, cublasOperation_t, int64_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpOrmqr)(
        handle, side, trans, m, n, k, a, ia, ja, descA, tau, c, ic, jc, descC, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpOrmtr_bufferSize(cusolverMpHandle_t handle, cublasSideMode_t side, cublasFillMode_t uplo, cublasOperation_t trans, int64_t m, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrmtr_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpOrmtr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrmtr_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasSideMode_t, cublasFillMode_t, cublasOperation_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpOrmtr_bufferSize)(
        handle, side, uplo, trans, m, n, a, ia, ja, descA, tau, c, ic, jc, descC, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpOrmtr(cusolverMpHandle_t handle, cublasSideMode_t side, cublasFillMode_t uplo, cublasOperation_t trans, int64_t m, int64_t n, const void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* tau, void* c, int64_t ic, int64_t jc, cusolverMpMatrixDescriptor_t descC, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrmtr
    _check_or_init_cusolverMp()
    if __cusolverMpOrmtr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrmtr is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasSideMode_t, cublasFillMode_t, cublasOperation_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpOrmtr)(
        handle, side, uplo, trans, m, n, a, ia, ja, descA, tau, c, ic, jc, descC, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpGels_bufferSize(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t m, int64_t n, int64_t nrhs, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGels_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpGels_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGels_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasOperation_t, int64_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpGels_bufferSize)(
        handle, trans, m, n, nrhs, a, ia, ja, descA, b, ib, jb, descB, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpGels(cusolverMpHandle_t handle, cublasOperation_t trans, int64_t m, int64_t n, int64_t nrhs, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGels
    _check_or_init_cusolverMp()
    if __cusolverMpGels == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGels is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasOperation_t, int64_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpGels)(
        handle, trans, m, n, nrhs, a, ia, ja, descA, b, ib, jb, descB, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpStedc_bufferSize(cusolverMpHandle_t handle, char* compz, int64_t N, void* d_D, void* d_E, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost, int* iwork) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpStedc_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpStedc_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpStedc_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, char*, int64_t, void*, void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*, int*) noexcept nogil>__cusolverMpStedc_bufferSize)(
        handle, compz, N, d_D, d_E, d_Q, IQ, JQ, descQ, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost, iwork)


cdef cusolverStatus_t _cusolverMpStedc(cusolverMpHandle_t handle, char* compz, int64_t N, void* d_D, void* d_E, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpStedc
    _check_or_init_cusolverMp()
    if __cusolverMpStedc == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpStedc is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, char*, int64_t, void*, void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpStedc)(
        handle, compz, N, d_D, d_E, d_Q, IQ, JQ, descQ, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpGeqrf_bufferSize(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGeqrf_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpGeqrf_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGeqrf_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpGeqrf_bufferSize)(
        handle, M, N, d_A, IA, JA, descA, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpGeqrf(cusolverMpHandle_t handle, int64_t M, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_tau, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGeqrf
    _check_or_init_cusolverMp()
    if __cusolverMpGeqrf == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGeqrf is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpGeqrf)(
        handle, M, N, d_A, IA, JA, descA, d_tau, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpSytrd_bufferSize(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_E, void* d_TAU, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSytrd_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpSytrd_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSytrd_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, void*, void*, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpSytrd_bufferSize)(
        handle, uplo, N, d_A, IA, JA, descA, d_D, d_E, d_TAU, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpSytrd(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_E, void* d_TAU, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSytrd
    _check_or_init_cusolverMp()
    if __cusolverMpSytrd == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSytrd is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, void*, void*, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpSytrd)(
        handle, uplo, N, d_A, IA, JA, descA, d_D, d_E, d_TAU, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpSyevd_bufferSize(cusolverMpHandle_t handle, char* compz, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSyevd_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpSyevd_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSyevd_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, char*, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpSyevd_bufferSize)(
        handle, compz, uplo, N, d_A, IA, JA, descA, d_D, d_Q, IQ, JQ, descQ, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpSyevd(cusolverMpHandle_t handle, char* compz, cublasFillMode_t uplo, int64_t N, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, void* d_D, void* d_Q, int64_t IQ, int64_t JQ, cusolverMpMatrixDescriptor_t descQ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSyevd
    _check_or_init_cusolverMp()
    if __cusolverMpSyevd == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSyevd is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, char*, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpSyevd)(
        handle, compz, uplo, N, d_A, IA, JA, descA, d_D, d_Q, IQ, JQ, descQ, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, d_info)


cdef cusolverStatus_t _cusolverMpSygst_bufferSize(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cublasFillMode_t uplo, int64_t m, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSygst_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpSygst_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSygst_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverEigType_t, cublasFillMode_t, int64_t, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpSygst_bufferSize)(
        handle, ibtype, uplo, m, ia, ja, descA, ib, jb, descB, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpSygst(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cublasFillMode_t uplo, int64_t m, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSygst
    _check_or_init_cusolverMp()
    if __cusolverMpSygst == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSygst is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverEigType_t, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpSygst)(
        handle, ibtype, uplo, m, a, ia, ja, descA, b, ib, jb, descB, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpSygvd_bufferSize(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cusolverEigMode_t jobz, cublasFillMode_t uplo, int64_t m, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, int64_t iz, int64_t jz, cusolverMpMatrixDescriptor_t descZ, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSygvd_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpSygvd_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSygvd_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverEigType_t, cusolverEigMode_t, cublasFillMode_t, int64_t, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpSygvd_bufferSize)(
        handle, ibtype, jobz, uplo, m, ia, ja, descA, ib, jb, descB, iz, jz, descZ, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpSygvd(cusolverMpHandle_t handle, cusolverEigType_t ibtype, cusolverEigMode_t jobz, cublasFillMode_t uplo, int64_t m, void* a, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, void* b, int64_t ib, int64_t jb, cusolverMpMatrixDescriptor_t descB, void* w, void* z, int64_t iz, int64_t jz, cusolverMpMatrixDescriptor_t descZ, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSygvd
    _check_or_init_cusolverMp()
    if __cusolverMpSygvd == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSygvd is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverEigType_t, cusolverEigMode_t, cublasFillMode_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpSygvd)(
        handle, ibtype, jobz, uplo, m, a, ia, ja, descA, b, ib, jb, descB, w, z, iz, jz, descZ, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)


cdef cusolverStatus_t _cusolverMpLoggerSetFile(FILE* file) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLoggerSetFile
    _check_or_init_cusolverMp()
    if __cusolverMpLoggerSetFile == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLoggerSetFile is not found")
    return (<cusolverStatus_t (*)(FILE*) noexcept nogil>__cusolverMpLoggerSetFile)(
        file)


cdef cusolverStatus_t _cusolverMpLoggerOpenFile(const char* logFile) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLoggerOpenFile
    _check_or_init_cusolverMp()
    if __cusolverMpLoggerOpenFile == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLoggerOpenFile is not found")
    return (<cusolverStatus_t (*)(const char*) noexcept nogil>__cusolverMpLoggerOpenFile)(
        logFile)


cdef cusolverStatus_t _cusolverMpLoggerSetLevel(int level) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLoggerSetLevel
    _check_or_init_cusolverMp()
    if __cusolverMpLoggerSetLevel == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLoggerSetLevel is not found")
    return (<cusolverStatus_t (*)(int) noexcept nogil>__cusolverMpLoggerSetLevel)(
        level)


cdef cusolverStatus_t _cusolverMpLoggerSetMask(int mask) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLoggerSetMask
    _check_or_init_cusolverMp()
    if __cusolverMpLoggerSetMask == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLoggerSetMask is not found")
    return (<cusolverStatus_t (*)(int) noexcept nogil>__cusolverMpLoggerSetMask)(
        mask)


cdef cusolverStatus_t _cusolverMpLoggerForceDisable() except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLoggerForceDisable
    _check_or_init_cusolverMp()
    if __cusolverMpLoggerForceDisable == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLoggerForceDisable is not found")
    return (<cusolverStatus_t (*)() noexcept nogil>__cusolverMpLoggerForceDisable)(
        )


cdef cusolverStatus_t _cusolverMpSetMathMode(cusolverMpHandle_t handle, cusolverMathMode_t mode) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSetMathMode
    _check_or_init_cusolverMp()
    if __cusolverMpSetMathMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSetMathMode is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverMathMode_t) noexcept nogil>__cusolverMpSetMathMode)(
        handle, mode)


cdef cusolverStatus_t _cusolverMpGetMathMode(cusolverMpHandle_t handle, cusolverMathMode_t* mode) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetMathMode
    _check_or_init_cusolverMp()
    if __cusolverMpGetMathMode == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetMathMode is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverMathMode_t*) noexcept nogil>__cusolverMpGetMathMode)(
        handle, mode)


cdef cusolverStatus_t _cusolverMpSetEmulationStrategy(cusolverMpHandle_t handle, cudaEmulationStrategy_t strategy) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSetEmulationStrategy
    _check_or_init_cusolverMp()
    if __cusolverMpSetEmulationStrategy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSetEmulationStrategy is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cudaEmulationStrategy_t) noexcept nogil>__cusolverMpSetEmulationStrategy)(
        handle, strategy)


cdef cusolverStatus_t _cusolverMpGetEmulationStrategy(cusolverMpHandle_t handle, cudaEmulationStrategy_t* strategy) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpGetEmulationStrategy
    _check_or_init_cusolverMp()
    if __cusolverMpGetEmulationStrategy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpGetEmulationStrategy is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cudaEmulationStrategy_t*) noexcept nogil>__cusolverMpGetEmulationStrategy)(
        handle, strategy)


cdef cusolverStatus_t _cusolverMpNewtonSchulzDescriptorCreate(cusolverMpNewtonSchulzDescriptor_t* nsDesc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulzDescriptorCreate
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulzDescriptorCreate == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulzDescriptorCreate is not found")
    return (<cusolverStatus_t (*)(cusolverMpNewtonSchulzDescriptor_t*) noexcept nogil>__cusolverMpNewtonSchulzDescriptorCreate)(
        nsDesc)


cdef cusolverStatus_t _cusolverMpNewtonSchulzDescriptorDestroy(cusolverMpNewtonSchulzDescriptor_t nsDesc) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulzDescriptorDestroy
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulzDescriptorDestroy == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulzDescriptorDestroy is not found")
    return (<cusolverStatus_t (*)(cusolverMpNewtonSchulzDescriptor_t) noexcept nogil>__cusolverMpNewtonSchulzDescriptorDestroy)(
        nsDesc)


cdef cusolverStatus_t _cusolverMpNewtonSchulzDescriptorSetAttribute(cusolverMpNewtonSchulzDescriptor_t nsDesc, cusolverMpNewtonSchulzDescriptorAttribute_t attr, const void* buf, size_t sizeInBytes) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulzDescriptorSetAttribute
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulzDescriptorSetAttribute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulzDescriptorSetAttribute is not found")
    return (<cusolverStatus_t (*)(cusolverMpNewtonSchulzDescriptor_t, cusolverMpNewtonSchulzDescriptorAttribute_t, const void*, size_t) noexcept nogil>__cusolverMpNewtonSchulzDescriptorSetAttribute)(
        nsDesc, attr, buf, sizeInBytes)


cdef cusolverStatus_t _cusolverMpNewtonSchulzDescriptorGetAttribute(cusolverMpNewtonSchulzDescriptor_t nsDesc, cusolverMpNewtonSchulzDescriptorAttribute_t attr, void* buf, size_t sizeInBytes, size_t* sizeInBytesWritten) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulzDescriptorGetAttribute
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulzDescriptorGetAttribute == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulzDescriptorGetAttribute is not found")
    return (<cusolverStatus_t (*)(cusolverMpNewtonSchulzDescriptor_t, cusolverMpNewtonSchulzDescriptorAttribute_t, void*, size_t, size_t*) noexcept nogil>__cusolverMpNewtonSchulzDescriptorGetAttribute)(
        nsDesc, attr, buf, sizeInBytes, sizeInBytesWritten)


cdef cusolverStatus_t _cusolverMpSetStream(cusolverMpHandle_t handle, cudaStream_t stream) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpSetStream
    _check_or_init_cusolverMp()
    if __cusolverMpSetStream == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpSetStream is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cudaStream_t) noexcept nogil>__cusolverMpSetStream)(
        handle, stream)


cdef cusolverStatus_t _cusolverMpBufferRegister(cusolverMpGrid_t grid, void* ptr, size_t size) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpBufferRegister
    _check_or_init_cusolverMp()
    if __cusolverMpBufferRegister == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpBufferRegister is not found")
    return (<cusolverStatus_t (*)(cusolverMpGrid_t, void*, size_t) noexcept nogil>__cusolverMpBufferRegister)(
        grid, ptr, size)


cdef cusolverStatus_t _cusolverMpBufferDeregister(cusolverMpGrid_t grid, void* ptr) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpBufferDeregister
    _check_or_init_cusolverMp()
    if __cusolverMpBufferDeregister == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpBufferDeregister is not found")
    return (<cusolverStatus_t (*)(cusolverMpGrid_t, void*) noexcept nogil>__cusolverMpBufferDeregister)(
        grid, ptr)


cdef cusolverStatus_t _cusolverMpOrgqr_bufferSize(cusolverMpHandle_t handle, int64_t m, int64_t n, int64_t k, const void* d_A, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* d_tau, cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrgqr_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpOrgqr_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrgqr_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, int64_t, const void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpOrgqr_bufferSize)(
        handle, m, n, k, d_A, ia, ja, descA, d_tau, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpOrgqr(cusolverMpHandle_t handle, int64_t m, int64_t n, int64_t k, void* d_A, int64_t ia, int64_t ja, cusolverMpMatrixDescriptor_t descA, const void* d_tau, cudaDataType_t computeType, void* d_work, size_t workspaceInBytesOnDevice, void* h_work, size_t workspaceInBytesOnHost, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpOrgqr
    _check_or_init_cusolverMp()
    if __cusolverMpOrgqr == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpOrgqr is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, int64_t, int64_t, int64_t, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, const void*, cudaDataType_t, void*, size_t, void*, size_t, int*) noexcept nogil>__cusolverMpOrgqr)(
        handle, m, n, k, d_A, ia, ja, descA, d_tau, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, d_info)


cdef cusolverStatus_t _cusolverMpLaset(cusolverMpHandle_t handle, cublasFillMode_t uplo, int64_t M, int64_t N, const void* alpha, const void* beta, void* d_A, int64_t IA, int64_t JA, cusolverMpMatrixDescriptor_t descA, int* d_info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpLaset
    _check_or_init_cusolverMp()
    if __cusolverMpLaset == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpLaset is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cublasFillMode_t, int64_t, int64_t, const void*, const void*, void*, int64_t, int64_t, cusolverMpMatrixDescriptor_t, int*) noexcept nogil>__cusolverMpLaset)(
        handle, uplo, M, N, alpha, beta, d_A, IA, JA, descA, d_info)


cdef cusolverStatus_t _cusolverMpNewtonSchulz_bufferSize(cusolverMpHandle_t handle, cusolverMpNewtonSchulzDescriptor_t nsDesc, const int64_t m, const int64_t n, void* d_x, const int64_t ix, const int64_t jx, const cusolverMpMatrixDescriptor_t descX, const int64_t numberOfNewtonSchulzIterations, const void* h_coeffs, const cudaDataType_t computeType, size_t* workspaceInBytesOnDevice, size_t* workspaceInBytesOnHost) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulz_bufferSize
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulz_bufferSize == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulz_bufferSize is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverMpNewtonSchulzDescriptor_t, const int64_t, const int64_t, void*, const int64_t, const int64_t, const cusolverMpMatrixDescriptor_t, const int64_t, const void*, const cudaDataType_t, size_t*, size_t*) noexcept nogil>__cusolverMpNewtonSchulz_bufferSize)(
        handle, nsDesc, m, n, d_x, ix, jx, descX, numberOfNewtonSchulzIterations, h_coeffs, computeType, workspaceInBytesOnDevice, workspaceInBytesOnHost)


cdef cusolverStatus_t _cusolverMpNewtonSchulz(cusolverMpHandle_t handle, cusolverMpNewtonSchulzDescriptor_t nsDesc, const int64_t m, const int64_t n, void* d_x, const int64_t ix, const int64_t jx, const cusolverMpMatrixDescriptor_t descX, const int64_t numberOfNewtonSchulzIterations, const void* h_coeffs, const cudaDataType_t computeType, void* d_work, const size_t workspaceInBytesOnDevice, void* h_work, const size_t workspaceInBytesOnHost, int* info) except?_CUSOLVERSTATUS_T_INTERNAL_LOADING_ERROR nogil:
    global __cusolverMpNewtonSchulz
    _check_or_init_cusolverMp()
    if __cusolverMpNewtonSchulz == NULL:
        with gil:
            raise FunctionNotFoundError("function cusolverMpNewtonSchulz is not found")
    return (<cusolverStatus_t (*)(cusolverMpHandle_t, cusolverMpNewtonSchulzDescriptor_t, const int64_t, const int64_t, void*, const int64_t, const int64_t, const cusolverMpMatrixDescriptor_t, const int64_t, const void*, const cudaDataType_t, void*, const size_t, void*, const size_t, int*) noexcept nogil>__cusolverMpNewtonSchulz)(
        handle, nsDesc, m, n, d_x, ix, jx, descX, numberOfNewtonSchulzIterations, h_coeffs, computeType, d_work, workspaceInBytesOnDevice, h_work, workspaceInBytesOnHost, info)
