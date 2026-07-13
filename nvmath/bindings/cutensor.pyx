# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
#
# This code was automatically generated across versions from 2.5.0 to 2.6.0, generator version 0.3.1.dev1471+g7122059e9. Do not modify it directly.

cimport cython  # NOQA
cimport cpython
from libcpp.vector cimport vector
from cuda.pathfinder import load_nvidia_dynamic_lib

from ._internal.utils cimport get_resource_ptr, get_resource_ptrs, nullable_unique_ptr

from enum import IntEnum as _IntEnum

import ctypes
import sys
import threading
import numpy as _numpy


cdef object __symbol_lock = threading.Lock()
_COMPUTE_DESC_INIT = False
_COMPUTE_DESC_16F = None
_COMPUTE_DESC_16BF = None
_COMPUTE_DESC_TF32 = None
_COMPUTE_DESC_3XTF32 = None
_COMPUTE_DESC_32F = None
_COMPUTE_DESC_64F = None
_COMPUTE_DESC_4X16F = None
_COMPUTE_DESC_9X16BF = None
_COMPUTE_DESC_8XINT8 = None

def _load_cutensor_compute_descriptors():
    global _COMPUTE_DESC_INIT
    if _COMPUTE_DESC_INIT:
        return

    with __symbol_lock:
        try:
            lib_handle = load_nvidia_dynamic_lib("cutensor")
            if sys.platform == "win32":
                lib = ctypes.WinDLL(lib_handle.abs_path)
            else:
                lib = ctypes.CDLL(lib_handle.abs_path)
            global _COMPUTE_DESC_16F, _COMPUTE_DESC_16BF, _COMPUTE_DESC_TF32, _COMPUTE_DESC_3XTF32, _COMPUTE_DESC_32F, _COMPUTE_DESC_64F
            global _COMPUTE_DESC_4X16F, _COMPUTE_DESC_9X16BF, _COMPUTE_DESC_8XINT8
            _COMPUTE_DESC_16F = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_16F").value
            _COMPUTE_DESC_16BF = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_16BF").value
            _COMPUTE_DESC_TF32 = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_TF32").value
            _COMPUTE_DESC_3XTF32 = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_3XTF32").value
            _COMPUTE_DESC_32F = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_32F").value
            _COMPUTE_DESC_64F = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_64F").value
            _COMPUTE_DESC_4X16F = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_4X16F").value
            _COMPUTE_DESC_9X16BF = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_9X16BF").value
            _COMPUTE_DESC_8XINT8 = ctypes.c_void_p.in_dll(lib, "CUTENSOR_COMPUTE_DESC_8XINT8").value
            _COMPUTE_DESC_INIT = True
        except:
            raise ImportError("Failed to load cutensor library")


class ComputeDesc:
    """See `cutensorComputeDescriptor_t`."""

    @classmethod
    def COMPUTE_16F(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_16F

    @classmethod
    def COMPUTE_16BF(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_16BF

    @classmethod
    def COMPUTE_TF32(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_TF32

    @classmethod
    def COMPUTE_3XTF32(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_3XTF32

    @classmethod
    def COMPUTE_32F(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_32F

    @classmethod
    def COMPUTE_64F(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_64F

    @classmethod
    def COMPUTE_4X16F(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_4X16F

    @classmethod
    def COMPUTE_9X16BF(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_9X16BF

    @classmethod
    def COMPUTE_8XINT8(cls):
        _load_cutensor_compute_descriptors()
        return _COMPUTE_DESC_8XINT8

###############################################################################
# Enum
###############################################################################

class Operator(_IntEnum):
    """
    See `cutensorOperator_t`.
    """
    OP_IDENTITY = CUTENSOR_OP_IDENTITY
    OP_SQRT = CUTENSOR_OP_SQRT
    OP_RELU = CUTENSOR_OP_RELU
    OP_CONJ = CUTENSOR_OP_CONJ
    OP_RCP = CUTENSOR_OP_RCP
    OP_SIGMOID = CUTENSOR_OP_SIGMOID
    OP_TANH = CUTENSOR_OP_TANH
    OP_EXP = CUTENSOR_OP_EXP
    OP_LOG = CUTENSOR_OP_LOG
    OP_ABS = CUTENSOR_OP_ABS
    OP_NEG = CUTENSOR_OP_NEG
    OP_SIN = CUTENSOR_OP_SIN
    OP_COS = CUTENSOR_OP_COS
    OP_TAN = CUTENSOR_OP_TAN
    OP_SINH = CUTENSOR_OP_SINH
    OP_COSH = CUTENSOR_OP_COSH
    OP_ASIN = CUTENSOR_OP_ASIN
    OP_ACOS = CUTENSOR_OP_ACOS
    OP_ATAN = CUTENSOR_OP_ATAN
    OP_ASINH = CUTENSOR_OP_ASINH
    OP_ACOSH = CUTENSOR_OP_ACOSH
    OP_ATANH = CUTENSOR_OP_ATANH
    OP_CEIL = CUTENSOR_OP_CEIL
    OP_FLOOR = CUTENSOR_OP_FLOOR
    OP_MISH = CUTENSOR_OP_MISH
    OP_SWISH = CUTENSOR_OP_SWISH
    OP_SOFT_PLUS = CUTENSOR_OP_SOFT_PLUS
    OP_SOFT_SIGN = CUTENSOR_OP_SOFT_SIGN
    OP_ADD = CUTENSOR_OP_ADD
    OP_MUL = CUTENSOR_OP_MUL
    OP_MAX = CUTENSOR_OP_MAX
    OP_MIN = CUTENSOR_OP_MIN
    OP_UNKNOWN = CUTENSOR_OP_UNKNOWN

class Status(_IntEnum):
    """
    See `cutensorStatus_t`.
    """
    SUCCESS = CUTENSOR_STATUS_SUCCESS
    NOT_INITIALIZED = CUTENSOR_STATUS_NOT_INITIALIZED
    ALLOC_FAILED = CUTENSOR_STATUS_ALLOC_FAILED
    INVALID_VALUE = CUTENSOR_STATUS_INVALID_VALUE
    ARCH_MISMATCH = CUTENSOR_STATUS_ARCH_MISMATCH
    MAPPING_ERROR = CUTENSOR_STATUS_MAPPING_ERROR
    EXECUTION_FAILED = CUTENSOR_STATUS_EXECUTION_FAILED
    INTERNAL_ERROR = CUTENSOR_STATUS_INTERNAL_ERROR
    NOT_SUPPORTED = CUTENSOR_STATUS_NOT_SUPPORTED
    LICENSE_ERROR = CUTENSOR_STATUS_LICENSE_ERROR
    CUBLAS_ERROR = CUTENSOR_STATUS_CUBLAS_ERROR
    CUDA_ERROR = CUTENSOR_STATUS_CUDA_ERROR
    INSUFFICIENT_WORKSPACE = CUTENSOR_STATUS_INSUFFICIENT_WORKSPACE
    INSUFFICIENT_DRIVER = CUTENSOR_STATUS_INSUFFICIENT_DRIVER
    IO_ERROR = CUTENSOR_STATUS_IO_ERROR

class Algo(_IntEnum):
    """
    See `cutensorAlgo_t`.
    """
    DEFAULT_PATIENT = CUTENSOR_ALGO_DEFAULT_PATIENT
    GETT = CUTENSOR_ALGO_GETT
    TGETT = CUTENSOR_ALGO_TGETT
    TTGT = CUTENSOR_ALGO_TTGT
    DEFAULT = CUTENSOR_ALGO_DEFAULT

class WorksizePreference(_IntEnum):
    """
    See `cutensorWorksizePreference_t`.
    """
    WORKSPACE_MIN = CUTENSOR_WORKSPACE_MIN
    WORKSPACE_DEFAULT = CUTENSOR_WORKSPACE_DEFAULT
    WORKSPACE_MAX = CUTENSOR_WORKSPACE_MAX

class OperationDescriptorAttribute(_IntEnum):
    """
    See `cutensorOperationDescriptorAttribute_t`.
    """
    TAG = CUTENSOR_OPERATION_DESCRIPTOR_TAG
    SCALAR_TYPE = CUTENSOR_OPERATION_DESCRIPTOR_SCALAR_TYPE
    FLOPS = CUTENSOR_OPERATION_DESCRIPTOR_FLOPS
    MOVED_BYTES = CUTENSOR_OPERATION_DESCRIPTOR_MOVED_BYTES
    PADDING_LEFT = CUTENSOR_OPERATION_DESCRIPTOR_PADDING_LEFT
    PADDING_RIGHT = CUTENSOR_OPERATION_DESCRIPTOR_PADDING_RIGHT
    PADDING_VALUE = CUTENSOR_OPERATION_DESCRIPTOR_PADDING_VALUE

class PlanPreferenceAttribute(_IntEnum):
    """
    See `cutensorPlanPreferenceAttribute_t`.
    """
    AUTOTUNE_MODE = CUTENSOR_PLAN_PREFERENCE_AUTOTUNE_MODE
    CACHE_MODE = CUTENSOR_PLAN_PREFERENCE_CACHE_MODE
    INCREMENTAL_COUNT = CUTENSOR_PLAN_PREFERENCE_INCREMENTAL_COUNT
    ALGO = CUTENSOR_PLAN_PREFERENCE_ALGO
    KERNEL_RANK = CUTENSOR_PLAN_PREFERENCE_KERNEL_RANK
    JIT = CUTENSOR_PLAN_PREFERENCE_JIT
    GPU_ARCH = CUTENSOR_PLAN_PREFERENCE_GPU_ARCH

class AutotuneMode(_IntEnum):
    """
    See `cutensorAutotuneMode_t`.
    """
    NONE = CUTENSOR_AUTOTUNE_MODE_NONE
    INCREMENTAL = CUTENSOR_AUTOTUNE_MODE_INCREMENTAL

class JitMode(_IntEnum):
    """
    See `cutensorJitMode_t`.
    """
    NONE = CUTENSOR_JIT_MODE_NONE
    DEFAULT = CUTENSOR_JIT_MODE_DEFAULT

class CacheMode(_IntEnum):
    """
    See `cutensorCacheMode_t`.
    """
    NONE = CUTENSOR_CACHE_MODE_NONE
    PEDANTIC = CUTENSOR_CACHE_MODE_PEDANTIC

class PlanAttribute(_IntEnum):
    """
    See `cutensorPlanAttribute_t`.
    """
    REQUIRED_WORKSPACE = CUTENSOR_PLAN_REQUIRED_WORKSPACE


###############################################################################
# Error handling
###############################################################################

cdef class cuTENSORError(Exception):

    def __init__(self, status):
        self.status = status
        s = Status(status)
        cdef str err = f"{s.name} ({s.value})"
        super(cuTENSORError, self).__init__(err)

    def __reduce__(self):
        return (type(self), (self.status,))


@cython.profile(False)
cpdef inline check_status(int status):
    if status != 0:
        raise cuTENSORError(status)


###############################################################################
# Wrapper functions
###############################################################################

cpdef intptr_t create() except? 0:
    """See `cutensorCreate`."""
    cdef Handle handle
    with nogil:
        __status__ = cutensorCreate(&handle)
    check_status(__status__)
    return <intptr_t>handle


cpdef destroy(intptr_t handle):
    """See `cutensorDestroy`."""
    with nogil:
        __status__ = cutensorDestroy(<Handle>handle)
    check_status(__status__)


cpdef handle_resize_plan_cache(intptr_t handle, uint32_t num_entries):
    """See `cutensorHandleResizePlanCache`."""
    with nogil:
        __status__ = cutensorHandleResizePlanCache(<Handle>handle, <const uint32_t>num_entries)
    check_status(__status__)


cpdef handle_write_plan_cache_to_file(intptr_t handle, filename):
    """See `cutensorHandleWritePlanCacheToFile`."""
    if not isinstance(filename, str):
        raise TypeError("filename must be a Python str")
    cdef bytes _temp_filename_ = (<str>filename).encode()
    cdef char* _filename_ = _temp_filename_
    with nogil:
        __status__ = cutensorHandleWritePlanCacheToFile(<const Handle>handle, <const char*>_filename_)
    check_status(__status__)


cpdef uint32_t handle_read_plan_cache_from_file(intptr_t handle, filename) except? -1:
    """See `cutensorHandleReadPlanCacheFromFile`."""
    if not isinstance(filename, str):
        raise TypeError("filename must be a Python str")
    cdef bytes _temp_filename_ = (<str>filename).encode()
    cdef char* _filename_ = _temp_filename_
    cdef uint32_t num_cachelines_read
    with nogil:
        __status__ = cutensorHandleReadPlanCacheFromFile(<Handle>handle, <const char*>_filename_, &num_cachelines_read)
    check_status(__status__)
    return num_cachelines_read


cpdef write_kernel_cache_to_file(intptr_t handle, filename):
    """See `cutensorWriteKernelCacheToFile`."""
    if not isinstance(filename, str):
        raise TypeError("filename must be a Python str")
    cdef bytes _temp_filename_ = (<str>filename).encode()
    cdef char* _filename_ = _temp_filename_
    with nogil:
        __status__ = cutensorWriteKernelCacheToFile(<const Handle>handle, <const char*>_filename_)
    check_status(__status__)


cpdef read_kernel_cache_from_file(intptr_t handle, filename):
    """See `cutensorReadKernelCacheFromFile`."""
    if not isinstance(filename, str):
        raise TypeError("filename must be a Python str")
    cdef bytes _temp_filename_ = (<str>filename).encode()
    cdef char* _filename_ = _temp_filename_
    with nogil:
        __status__ = cutensorReadKernelCacheFromFile(<Handle>handle, <const char*>_filename_)
    check_status(__status__)


cpdef intptr_t create_tensor_descriptor(intptr_t handle, uint32_t num_modes, extent, stride, int data_type, uint32_t alignment_requirement) except? 0:
    """See `cutensorCreateTensorDescriptor`."""
    cdef nullable_unique_ptr[ vector[int64_t] ] _extent_
    get_resource_ptr[int64_t](_extent_, extent, <int64_t*>NULL)
    cdef nullable_unique_ptr[ vector[int64_t] ] _stride_
    get_resource_ptr[int64_t](_stride_, stride, <int64_t*>NULL)
    cdef TensorDescriptor desc
    with nogil:
        __status__ = cutensorCreateTensorDescriptor(<const Handle>handle, &desc, <const uint32_t>num_modes, <const int64_t*>(_extent_.data()), <const int64_t*>(_stride_.data()), <DataType>data_type, alignment_requirement)
    check_status(__status__)
    return <intptr_t>desc


cpdef destroy_tensor_descriptor(intptr_t desc):
    """See `cutensorDestroyTensorDescriptor`."""
    with nogil:
        __status__ = cutensorDestroyTensorDescriptor(<TensorDescriptor>desc)
    check_status(__status__)


cpdef intptr_t create_elementwise_trinary(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_b, mode_b, int op_b, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, int op_ab, int op_abc, intptr_t desc_compute) except? 0:
    """See `cutensorCreateElementwiseTrinary`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_b_
    get_resource_ptr[int32_t](_mode_b_, mode_b, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateElementwiseTrinary(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_b, <const int32_t*>(_mode_b_.data()), <_Operator>op_b, <const TensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const TensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <_Operator>op_ab, <_Operator>op_abc, <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef elementwise_trinary_execute(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t beta, intptr_t b, intptr_t gamma, intptr_t c, intptr_t d, intptr_t stream):
    """See `cutensorElementwiseTrinaryExecute`."""
    with nogil:
        __status__ = cutensorElementwiseTrinaryExecute(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <const void*>beta, <const void*>b, <const void*>gamma, <const void*>c, <void*>d, <Stream>stream)
    check_status(__status__)


cpdef intptr_t create_elementwise_binary(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, int op_ac, intptr_t desc_compute) except? 0:
    """See `cutensorCreateElementwiseBinary`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateElementwiseBinary(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const TensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <_Operator>op_ac, <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef elementwise_binary_execute(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t gamma, intptr_t c, intptr_t d, intptr_t stream):
    """See `cutensorElementwiseBinaryExecute`."""
    with nogil:
        __status__ = cutensorElementwiseBinaryExecute(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <const void*>gamma, <const void*>c, <void*>d, <Stream>stream)
    check_status(__status__)


cpdef intptr_t create_permutation(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_b, mode_b, intptr_t desc_compute) except? 0:
    """See `cutensorCreatePermutation`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_b_
    get_resource_ptr[int32_t](_mode_b_, mode_b, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreatePermutation(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_b, <const int32_t*>(_mode_b_.data()), <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef permute(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t b, intptr_t stream):
    """See `cutensorPermute`."""
    with nogil:
        __status__ = cutensorPermute(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <void*>b, <const Stream>stream)
    check_status(__status__)


cpdef intptr_t create_contraction(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_b, mode_b, int op_b, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, intptr_t desc_compute) except? 0:
    """See `cutensorCreateContraction`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_b_
    get_resource_ptr[int32_t](_mode_b_, mode_b, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateContraction(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_b, <const int32_t*>(_mode_b_.data()), <_Operator>op_b, <const TensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const TensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef destroy_operation_descriptor(intptr_t desc):
    """See `cutensorDestroyOperationDescriptor`."""
    with nogil:
        __status__ = cutensorDestroyOperationDescriptor(<OperationDescriptor>desc)
    check_status(__status__)


######################### Python specific utility #########################

cdef dict operation_descriptor_attribute_sizes = {
    CUTENSOR_OPERATION_DESCRIPTOR_TAG: _numpy.int32,
    CUTENSOR_OPERATION_DESCRIPTOR_SCALAR_TYPE: _numpy.int32,
    CUTENSOR_OPERATION_DESCRIPTOR_FLOPS: _numpy.float32,
    CUTENSOR_OPERATION_DESCRIPTOR_MOVED_BYTES: _numpy.float32,
    CUTENSOR_OPERATION_DESCRIPTOR_PADDING_LEFT: _numpy.uint32,
    CUTENSOR_OPERATION_DESCRIPTOR_PADDING_RIGHT: _numpy.uint32,
    CUTENSOR_OPERATION_DESCRIPTOR_PADDING_VALUE: _numpy.uint64,
}

cpdef get_operation_descriptor_attribute_dtype(int attr):
    """Get the Python data type of the corresponding OperationDescriptorAttribute attribute.

    Args:
        attr (OperationDescriptorAttribute): The attribute to query.

    Returns:
        The data type of the queried attribute.

    .. note:: This API has no C counterpart and is a convenient helper for
        allocating memory for :func:`operation_descriptor_get_attribute`, :func:`operation_descriptor_set_attribute`.
    """
    return operation_descriptor_attribute_sizes[attr]

###########################################################################

cpdef operation_descriptor_set_attribute(intptr_t handle, intptr_t desc, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cutensorOperationDescriptorSetAttribute`."""
    with nogil:
        __status__ = cutensorOperationDescriptorSetAttribute(<const Handle>handle, <OperationDescriptor>desc, <_OperationDescriptorAttribute>attr, <const void*>buf, size_in_bytes)
    check_status(__status__)


cpdef operation_descriptor_get_attribute(intptr_t handle, intptr_t desc, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cutensorOperationDescriptorGetAttribute`."""
    with nogil:
        __status__ = cutensorOperationDescriptorGetAttribute(<const Handle>handle, <OperationDescriptor>desc, <_OperationDescriptorAttribute>attr, <void*>buf, size_in_bytes)
    check_status(__status__)


cpdef intptr_t create_plan_preference(intptr_t handle, int algo, int jit_mode) except? 0:
    """See `cutensorCreatePlanPreference`."""
    cdef PlanPreference pref
    with nogil:
        __status__ = cutensorCreatePlanPreference(<const Handle>handle, &pref, <_Algo>algo, <_JitMode>jit_mode)
    check_status(__status__)
    return <intptr_t>pref


cpdef destroy_plan_preference(intptr_t pref):
    """See `cutensorDestroyPlanPreference`."""
    with nogil:
        __status__ = cutensorDestroyPlanPreference(<PlanPreference>pref)
    check_status(__status__)


######################### Python specific utility #########################

cdef dict plan_preference_attribute_sizes = {
    CUTENSOR_PLAN_PREFERENCE_AUTOTUNE_MODE: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_CACHE_MODE: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_INCREMENTAL_COUNT: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_ALGO: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_KERNEL_RANK: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_JIT: _numpy.int32,
    CUTENSOR_PLAN_PREFERENCE_GPU_ARCH: _numpy.int32,
}

cpdef get_plan_preference_attribute_dtype(int attr):
    """Get the Python data type of the corresponding PlanPreferenceAttribute attribute.

    Args:
        attr (PlanPreferenceAttribute): The attribute to query.

    Returns:
        The data type of the queried attribute.

    .. note:: This API has no C counterpart and is a convenient helper for
        allocating memory for :func:`plan_preference_get_attribute`, :func:`plan_preference_set_attribute`.
    """
    return plan_preference_attribute_sizes[attr]

###########################################################################

cpdef plan_preference_get_attribute(intptr_t handle, intptr_t pref, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cutensorPlanPreferenceGetAttribute`."""
    with nogil:
        __status__ = cutensorPlanPreferenceGetAttribute(<const Handle>handle, <PlanPreference>pref, <_PlanPreferenceAttribute>attr, <void*>buf, size_in_bytes)
    check_status(__status__)


cpdef plan_preference_set_attribute(intptr_t handle, intptr_t pref, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cutensorPlanPreferenceSetAttribute`."""
    with nogil:
        __status__ = cutensorPlanPreferenceSetAttribute(<const Handle>handle, <PlanPreference>pref, <_PlanPreferenceAttribute>attr, <const void*>buf, size_in_bytes)
    check_status(__status__)


######################### Python specific utility #########################

cdef dict plan_attribute_sizes = {
    CUTENSOR_PLAN_REQUIRED_WORKSPACE: _numpy.uint64,
}

cpdef get_plan_attribute_dtype(int attr):
    """Get the Python data type of the corresponding PlanAttribute attribute.

    Args:
        attr (PlanAttribute): The attribute to query.

    Returns:
        The data type of the queried attribute.

    .. note:: This API has no C counterpart and is a convenient helper for
        allocating memory for :func:`plan_get_attribute`.
    """
    return plan_attribute_sizes[attr]

###########################################################################

cpdef plan_get_attribute(intptr_t handle, intptr_t plan, int attr, intptr_t buf, size_t size_in_bytes):
    """See `cutensorPlanGetAttribute`."""
    with nogil:
        __status__ = cutensorPlanGetAttribute(<const Handle>handle, <const Plan>plan, <_PlanAttribute>attr, <void*>buf, size_in_bytes)
    check_status(__status__)


cpdef uint64_t estimate_workspace_size(intptr_t handle, intptr_t desc, intptr_t plan_pref, int workspace_pref) except? -1:
    """See `cutensorEstimateWorkspaceSize`."""
    cdef uint64_t workspace_size_estimate
    with nogil:
        __status__ = cutensorEstimateWorkspaceSize(<const Handle>handle, <const OperationDescriptor>desc, <const PlanPreference>plan_pref, <const _WorksizePreference>workspace_pref, &workspace_size_estimate)
    check_status(__status__)
    return workspace_size_estimate


cpdef intptr_t create_plan(intptr_t handle, intptr_t desc, intptr_t pref, uint64_t workspace_size_limit) except? 0:
    """See `cutensorCreatePlan`."""
    cdef Plan plan
    with nogil:
        __status__ = cutensorCreatePlan(<const Handle>handle, &plan, <const OperationDescriptor>desc, <const PlanPreference>pref, workspace_size_limit)
    check_status(__status__)
    return <intptr_t>plan


cpdef destroy_plan(intptr_t plan):
    """See `cutensorDestroyPlan`."""
    with nogil:
        __status__ = cutensorDestroyPlan(<Plan>plan)
    check_status(__status__)


cpdef contract(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t b, intptr_t beta, intptr_t c, intptr_t d, intptr_t workspace, uint64_t workspace_size, intptr_t stream):
    """See `cutensorContract`."""
    with nogil:
        __status__ = cutensorContract(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <const void*>b, <const void*>beta, <const void*>c, <void*>d, <void*>workspace, workspace_size, <Stream>stream)
    check_status(__status__)


cpdef intptr_t create_reduction(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, int op_reduce, intptr_t desc_compute) except? 0:
    """See `cutensorCreateReduction`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateReduction(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const TensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <_Operator>op_reduce, <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef reduce(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t beta, intptr_t c, intptr_t d, intptr_t workspace, uint64_t workspace_size, intptr_t stream):
    """See `cutensorReduce`."""
    with nogil:
        __status__ = cutensorReduce(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <const void*>beta, <const void*>c, <void*>d, <void*>workspace, workspace_size, <Stream>stream)
    check_status(__status__)


cpdef intptr_t create_contraction_trinary(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_b, mode_b, int op_b, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, int op_d, intptr_t desc_e, mode_e, intptr_t desc_compute) except? 0:
    """See `cutensorCreateContractionTrinary`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_b_
    get_resource_ptr[int32_t](_mode_b_, mode_b, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_e_
    get_resource_ptr[int32_t](_mode_e_, mode_e, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateContractionTrinary(<const Handle>handle, &desc, <const TensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const TensorDescriptor>desc_b, <const int32_t*>(_mode_b_.data()), <_Operator>op_b, <const TensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const TensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <_Operator>op_d, <const TensorDescriptor>desc_e, <const int32_t*>(_mode_e_.data()), <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef contract_trinary(intptr_t handle, intptr_t plan, intptr_t alpha, intptr_t a, intptr_t b, intptr_t c, intptr_t beta, intptr_t d, intptr_t e, intptr_t workspace, uint64_t workspace_size, intptr_t stream):
    """See `cutensorContractTrinary`."""
    with nogil:
        __status__ = cutensorContractTrinary(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void*>a, <const void*>b, <const void*>c, <const void*>beta, <const void*>d, <void*>e, <void*>workspace, workspace_size, <Stream>stream)
    check_status(__status__)


cpdef intptr_t create_block_sparse_tensor_descriptor(intptr_t handle, uint32_t num_modes, uint64_t num_non_zero_blocks, num_sections_per_mode, extent, non_zero_coordinates, stride, int data_type) except? 0:
    """See `cutensorCreateBlockSparseTensorDescriptor`."""
    cdef nullable_unique_ptr[ vector[uint32_t] ] _num_sections_per_mode_
    get_resource_ptr[uint32_t](_num_sections_per_mode_, num_sections_per_mode, <uint32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int64_t] ] _extent_
    get_resource_ptr[int64_t](_extent_, extent, <int64_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _non_zero_coordinates_
    get_resource_ptr[int32_t](_non_zero_coordinates_, non_zero_coordinates, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int64_t] ] _stride_
    get_resource_ptr[int64_t](_stride_, stride, <int64_t*>NULL)
    cdef BlockSparseTensorDescriptor desc
    with nogil:
        __status__ = cutensorCreateBlockSparseTensorDescriptor(<Handle>handle, &desc, <const uint32_t>num_modes, <const uint64_t>num_non_zero_blocks, <const uint32_t*>(_num_sections_per_mode_.data()), <const int64_t*>(_extent_.data()), <const int32_t*>(_non_zero_coordinates_.data()), <const int64_t*>(_stride_.data()), <DataType>data_type)
    check_status(__status__)
    return <intptr_t>desc


cpdef destroy_block_sparse_tensor_descriptor(intptr_t desc):
    """See `cutensorDestroyBlockSparseTensorDescriptor`."""
    with nogil:
        __status__ = cutensorDestroyBlockSparseTensorDescriptor(<BlockSparseTensorDescriptor>desc)
    check_status(__status__)


cpdef intptr_t create_block_sparse_contraction(intptr_t handle, intptr_t desc_a, mode_a, int op_a, intptr_t desc_b, mode_b, int op_b, intptr_t desc_c, mode_c, int op_c, intptr_t desc_d, mode_d, intptr_t desc_compute) except? 0:
    """See `cutensorCreateBlockSparseContraction`."""
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_a_
    get_resource_ptr[int32_t](_mode_a_, mode_a, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_b_
    get_resource_ptr[int32_t](_mode_b_, mode_b, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_c_
    get_resource_ptr[int32_t](_mode_c_, mode_c, <int32_t*>NULL)
    cdef nullable_unique_ptr[ vector[int32_t] ] _mode_d_
    get_resource_ptr[int32_t](_mode_d_, mode_d, <int32_t*>NULL)
    cdef OperationDescriptor desc
    with nogil:
        __status__ = cutensorCreateBlockSparseContraction(<const Handle>handle, &desc, <const BlockSparseTensorDescriptor>desc_a, <const int32_t*>(_mode_a_.data()), <_Operator>op_a, <const BlockSparseTensorDescriptor>desc_b, <const int32_t*>(_mode_b_.data()), <_Operator>op_b, <const BlockSparseTensorDescriptor>desc_c, <const int32_t*>(_mode_c_.data()), <_Operator>op_c, <const BlockSparseTensorDescriptor>desc_d, <const int32_t*>(_mode_d_.data()), <const ComputeDescriptor>desc_compute)
    check_status(__status__)
    return <intptr_t>desc


cpdef block_sparse_contract(intptr_t handle, intptr_t plan, intptr_t alpha, a, b, intptr_t beta, c, d, intptr_t workspace, uint64_t workspace_size, intptr_t stream):
    """See `cutensorBlockSparseContract`."""
    cdef nullable_unique_ptr[ vector[void*] ] _a_
    get_resource_ptrs[void](_a_, a, <void*>NULL)
    cdef nullable_unique_ptr[ vector[void*] ] _b_
    get_resource_ptrs[void](_b_, b, <void*>NULL)
    cdef nullable_unique_ptr[ vector[void*] ] _c_
    get_resource_ptrs[void](_c_, c, <void*>NULL)
    cdef nullable_unique_ptr[ vector[void*] ] _d_
    get_resource_ptrs[void](_d_, d, <void*>NULL)
    with nogil:
        __status__ = cutensorBlockSparseContract(<const Handle>handle, <const Plan>plan, <const void*>alpha, <const void* const*>(_a_.data()), <const void* const*>(_b_.data()), <const void*>beta, <const void* const*>(_c_.data()), <void* const*>(_d_.data()), <void*>workspace, workspace_size, <Stream>stream)
    check_status(__status__)


cpdef str get_error_string(int error):
    """See `cutensorGetErrorString`."""
    cdef bytes _output_
    _output_ = cutensorGetErrorString(<const _Status>error)
    return _output_.decode()


cpdef size_t get_version() except? 0:
    """See `cutensorGetVersion`."""
    return cutensorGetVersion()


cpdef size_t get_cudart_version() except? 0:
    """See `cutensorGetCudartVersion`."""
    return cutensorGetCudartVersion()


cpdef logger_set_file(intptr_t file):
    """See `cutensorLoggerSetFile`."""
    with nogil:
        __status__ = cutensorLoggerSetFile(<FILE*>file)
    check_status(__status__)


cpdef logger_open_file(log_file):
    """See `cutensorLoggerOpenFile`."""
    if not isinstance(log_file, str):
        raise TypeError("log_file must be a Python str")
    cdef bytes _temp_log_file_ = (<str>log_file).encode()
    cdef char* _log_file_ = _temp_log_file_
    with nogil:
        __status__ = cutensorLoggerOpenFile(<const char*>_log_file_)
    check_status(__status__)


cpdef logger_set_level(int32_t level):
    """See `cutensorLoggerSetLevel`."""
    with nogil:
        __status__ = cutensorLoggerSetLevel(level)
    check_status(__status__)


cpdef logger_set_mask(int32_t mask):
    """See `cutensorLoggerSetMask`."""
    with nogil:
        __status__ = cutensorLoggerSetMask(mask)
    check_status(__status__)


cpdef logger_force_disable():
    """See `cutensorLoggerForceDisable`."""
    with nogil:
        __status__ = cutensorLoggerForceDisable()
    check_status(__status__)


###############################################################################
