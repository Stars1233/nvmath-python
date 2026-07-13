# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import _cython_3_2_5
import enum
from typing import Any, Callable, ClassVar

__pyx_capi__: dict
__test__: dict
buffer_deregister: _cython_3_2_5.cython_function_or_method
buffer_register: _cython_3_2_5.cython_function_or_method
check_status: _cython_3_2_5.cython_function_or_method
create: _cython_3_2_5.cython_function_or_method
create_device_grid: _cython_3_2_5.cython_function_or_method
create_matrix_desc: _cython_3_2_5.cython_function_or_method
destroy: _cython_3_2_5.cython_function_or_method
destroy_grid: _cython_3_2_5.cython_function_or_method
destroy_matrix_desc: _cython_3_2_5.cython_function_or_method
gels: _cython_3_2_5.cython_function_or_method
gels_buffer_size: _cython_3_2_5.cython_function_or_method
geqrf: _cython_3_2_5.cython_function_or_method
geqrf_buffer_size: _cython_3_2_5.cython_function_or_method
get_emulation_strategy: _cython_3_2_5.cython_function_or_method
get_math_mode: _cython_3_2_5.cython_function_or_method
get_newton_schulz_descriptor_attribute_dtype: _cython_3_2_5.cython_function_or_method
get_stream: _cython_3_2_5.cython_function_or_method
get_version: _cython_3_2_5.cython_function_or_method
getrf: _cython_3_2_5.cython_function_or_method
getrf_buffer_size: _cython_3_2_5.cython_function_or_method
getrs: _cython_3_2_5.cython_function_or_method
getrs_buffer_size: _cython_3_2_5.cython_function_or_method
laset: _cython_3_2_5.cython_function_or_method
logger_force_disable: _cython_3_2_5.cython_function_or_method
logger_open_file: _cython_3_2_5.cython_function_or_method
logger_set_file: _cython_3_2_5.cython_function_or_method
logger_set_level: _cython_3_2_5.cython_function_or_method
logger_set_mask: _cython_3_2_5.cython_function_or_method
matrix_gather_d2h: _cython_3_2_5.cython_function_or_method
matrix_scatter_h2d: _cython_3_2_5.cython_function_or_method
newton_schulz: _cython_3_2_5.cython_function_or_method
newton_schulz_buffer_size: _cython_3_2_5.cython_function_or_method
newton_schulz_descriptor_create: _cython_3_2_5.cython_function_or_method
newton_schulz_descriptor_destroy: _cython_3_2_5.cython_function_or_method
newton_schulz_descriptor_get_attribute: _cython_3_2_5.cython_function_or_method
newton_schulz_descriptor_set_attribute: _cython_3_2_5.cython_function_or_method
numroc: _cython_3_2_5.cython_function_or_method
orgqr: _cython_3_2_5.cython_function_or_method
orgqr_buffer_size: _cython_3_2_5.cython_function_or_method
ormqr: _cython_3_2_5.cython_function_or_method
ormqr_buffer_size: _cython_3_2_5.cython_function_or_method
ormtr: _cython_3_2_5.cython_function_or_method
ormtr_buffer_size: _cython_3_2_5.cython_function_or_method
potrf: _cython_3_2_5.cython_function_or_method
potrf_buffer_size: _cython_3_2_5.cython_function_or_method
potrs: _cython_3_2_5.cython_function_or_method
potrs_buffer_size: _cython_3_2_5.cython_function_or_method
set_emulation_strategy: _cython_3_2_5.cython_function_or_method
set_math_mode: _cython_3_2_5.cython_function_or_method
set_stream: _cython_3_2_5.cython_function_or_method
stedc: _cython_3_2_5.cython_function_or_method
stedc_buffer_size: _cython_3_2_5.cython_function_or_method
syevd: _cython_3_2_5.cython_function_or_method
syevd_buffer_size: _cython_3_2_5.cython_function_or_method
sygst: _cython_3_2_5.cython_function_or_method
sygst_buffer_size: _cython_3_2_5.cython_function_or_method
sygvd: _cython_3_2_5.cython_function_or_method
sygvd_buffer_size: _cython_3_2_5.cython_function_or_method
sytrd: _cython_3_2_5.cython_function_or_method
sytrd_buffer_size: _cython_3_2_5.cython_function_or_method

class GridMapping(enum.IntEnum):
    """
    See `cusolverMpGridMapping_t`.
    """
    __new__: ClassVar[Callable] = ...
    COL_MAJOR: ClassVar[GridMapping] = ...
    ROW_MAJOR: ClassVar[GridMapping] = ...
    _generate_next_value_: ClassVar[Callable] = ...
    _hashable_values_: ClassVar[list] = ...
    _member_map_: ClassVar[dict] = ...
    _member_names_: ClassVar[list] = ...
    _member_type_: ClassVar[type[int]] = ...
    _unhashable_values_: ClassVar[list] = ...
    _unhashable_values_map_: ClassVar[dict] = ...
    _use_args_: ClassVar[bool] = ...
    _value2member_map_: ClassVar[dict] = ...
    def __format__(self, *args, **kwargs) -> str:
        """Convert to a string according to format_spec."""

class NewtonSchulzDescriptorAttribute(enum.IntEnum):
    """
    See `cusolverMpNewtonSchulzDescriptorAttribute_t`.
    """
    __new__: ClassVar[Callable] = ...
    NORMALIZE: ClassVar[NewtonSchulzDescriptorAttribute] = ...
    REDUCE_VIA_COMPUTE_TYPE: ClassVar[NewtonSchulzDescriptorAttribute] = ...
    _generate_next_value_: ClassVar[Callable] = ...
    _hashable_values_: ClassVar[list] = ...
    _member_map_: ClassVar[dict] = ...
    _member_names_: ClassVar[list] = ...
    _member_type_: ClassVar[type[int]] = ...
    _unhashable_values_: ClassVar[list] = ...
    _unhashable_values_map_: ClassVar[dict] = ...
    _use_args_: ClassVar[bool] = ...
    _value2member_map_: ClassVar[dict] = ...
    def __format__(self, *args, **kwargs) -> str:
        """Convert to a string according to format_spec."""

class cuSOLVERMpError(Exception):
    def __init__(self, status) -> Any:
        """cuSOLVERMpError.__init__(self, status)"""
    def __reduce__(self) -> Any:
        """cuSOLVERMpError.__reduce__(self)"""
