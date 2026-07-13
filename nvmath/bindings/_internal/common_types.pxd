# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Shared CUDA-level Cython declarations used by generated bindings."""


cdef extern from *:
    """
    #include <driver_types.h>
    #include <library_types.h>
    #include <cuComplex.h>
    """
    ctypedef void* cudaStream_t 'cudaStream_t'
    ctypedef int cudaDataType_t 'cudaDataType_t'
    ctypedef int cudaDataType 'cudaDataType'
    ctypedef int libraryPropertyType_t 'libraryPropertyType_t'
    ctypedef int libraryPropertyType 'libraryPropertyType'

    ctypedef int cudaEmulationStrategy_t 'cudaEmulationStrategy_t'
    ctypedef int cudaEmulationMantissaControl_t 'cudaEmulationMantissaControl_t'
    ctypedef int cudaEmulationMantissaControl 'cudaEmulationMantissaControl'
    ctypedef int cudaEmulationSpecialValuesSupport_t 'cudaEmulationSpecialValuesSupport_t'
    ctypedef int cudaEmulationSpecialValuesSupport 'cudaEmulationSpecialValuesSupport'

    ctypedef struct cuComplex:
        float x
        float y
    ctypedef struct cuDoubleComplex:
        double x
        double y
