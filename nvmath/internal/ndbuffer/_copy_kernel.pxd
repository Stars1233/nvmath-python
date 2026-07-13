# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

cimport cython
from libc.stdint cimport intptr_t
from .._layout._layout cimport StridedLayout


cdef int launch_copy_kernel(StridedLayout dst, StridedLayout src, intptr_t dst_ptr, intptr_t src_ptr, int device_id, intptr_t stream_ptr, object logger) except -1
