# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

cimport cython
from libc.stdint cimport intptr_t
from .._layout._layout cimport StridedLayout

# cdef class Exporting

@cython.final
cdef class NDBuffer:
    cdef readonly StridedLayout layout
    cdef readonly object data
    cdef int data_device_id
    cdef readonly intptr_t data_ptr
    cdef readonly str dtype_name

    cdef readonly NDBuffer base

    # We use numpy_view internally to dispatch host memory
    # operations to numpy (e.g. h2h copy).
    # If the dtype_name is not supported by numpy, we still
    # create a numpy view for internal use with any dtype
    # of the corresponding itemsize, but such a view
    # should not be returned to the user
    cdef object numpy_view
    cdef bint has_supported_dtype

    # lazy evaluated properties
    cdef str prop_device   # "cpu" or "cuda"
    cdef object prop_device_id   # "cpu" or int

    cdef inline int init_from_data(NDBuffer self, StridedLayout layout, object data, intptr_t data_ptr, str dtype_name, int data_device_id) except -1:
        self.layout = layout
        self.data = data
        self.data_ptr = data_ptr
        self.data_device_id = data_device_id
        self.dtype_name = dtype_name
        return 0
