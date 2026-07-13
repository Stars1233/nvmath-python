# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import os
import threading
cimport cython
from libc.stdint cimport int64_t, intptr_t
from libcpp.memory cimport unique_ptr
from libcpp.functional cimport function

from .._layout._layout cimport (
    axis_t, axis_vec_t, axes_mask_t, STRIDED_LAYOUT_MAX_NDIM,
    _axis2mask, c_abs,
    flattening_axes_mask_from_range,
)
from ._jit cimport get_kernel
from .._bindings cimport launch_kernel

ctypedef unique_ptr[void, function[void(void*)]] args_t


cdef extern from "limits.h":
    cdef int INT_MAX
    cdef int INT_MIN


cdef extern from *:
    """
    #include <cmath>
    #include <memory>
    #include <type_traits>
    #include "copy_kernel/args.h"
    template <int N>
    void _get_kernel_args_ndim(std::unique_ptr<void, std::function<void(void*)>>& args, void *dst_ptr, const void *src_ptr, int dst_ndim, int src_ndim, int64_t* dst_shape, int64_t* src_shape, int64_t* dst_strides, int64_t* src_strides, int64_t grid_arg){
        auto deleter = [](void *p) {
            delete (static_cast<nvmath::KernelArgs<N>*>(p));
        };
        std::unique_ptr<nvmath::KernelArgs<N>, std::function<void(void*)>> ptr{new nvmath::KernelArgs<N>, std::move(deleter)};
        ptr->dst_ptr = dst_ptr;
        ptr->src_ptr = src_ptr;
        for (int i = 0; i < dst_ndim; i++) {
            ptr->dst_shape[i] = dst_shape[i];
            ptr->dst_strides[i] = dst_strides[i];
        }
        for (int i = 0; i < src_ndim; i++) {
            ptr->src_shape[i] = src_shape[i];
            ptr->src_strides[i] = src_strides[i];
        }
        ptr->grid_arg = grid_arg;
        args = std::move(ptr);
    }
    template <typename F, int i = 1, int max_ndim = STRIDED_LAYOUT_MAX_NDIM>
    void with_ndim(int ndim, F&& f) {
        if constexpr (i <= max_ndim) {
            if (i == ndim) {
                f(std::integral_constant<int, i>());
            } else {
                with_ndim<F, i + 1, max_ndim>(ndim, std::forward<F>(f));
            }
        } else if constexpr (i > max_ndim) {
            throw std::runtime_error("unsupported ndim");
        }
    }
    void _get_kernel_args(std::unique_ptr<void, std::function<void(void*)>>& args, void *dst_ptr, const void *src_ptr, int dst_ndim, int src_ndim, int64_t* dst_shape, int64_t* src_shape, int64_t* dst_strides, int64_t* src_strides, int64_t grid_arg) {
        int ndim = dst_ndim > src_ndim ? dst_ndim : src_ndim;
        with_ndim(ndim, [&](auto static_ndim_holder) {
            constexpr int static_ndim = decltype(static_ndim_holder)::value;
            _get_kernel_args_ndim<static_ndim>(args, dst_ptr, src_ptr, dst_ndim, src_ndim, dst_shape, src_shape, dst_strides, src_strides, grid_arg);
        });
    }
    """
    void _get_kernel_args(args_t& args, void *dst_ptr, const void *src_ptr, int dst_ndim, int src_ndim, int64_t* dst_shape, int64_t* src_shape, int64_t* dst_strides, int64_t* src_strides, int64_t grid_arg) except + nogil


thread_local = threading.local()


cpdef str get_include_path(object logger):
    """
    Finds and caches the absolute path for the strided copy includes.
    """
    # TODO(ktokarski) Once Program API supports passing includes as strings and names,
    # read all the headers once and cache them.
    try:
        return thread_local.strided_copy_include_dir
    except AttributeError:
        pass
    cdef str current_dir = os.path.dirname(os.path.abspath(__file__))
    cdef str copy_kernel_dir = os.path.normpath(os.path.join(current_dir, "copy_kernel"))
    thread_local.strided_copy_include_dir = copy_kernel_dir
    if logger is not None:
        logger.debug(f"Cached strided copy include dir: {copy_kernel_dir}")
    return copy_kernel_dir


cdef int get_kernel_args(args_t& args, StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int64_t grid_arg) except-1 nogil:
    _get_kernel_args(args, <void*>dst_ptr, <const void*>src_ptr, dst_layout.base.ndim, src_layout.base.ndim, dst_layout.base.shape, src_layout.base.shape, dst_layout.base.strides, src_layout.base.strides, grid_arg)
    return 0


cdef inline int _logging_helper(object logger, str msg, fst=None, snd=None, third=None) except -1 nogil:
    with cython.gil:
        logger.debug(msg.format(fst=fst, snd=snd, third=third))
    return 0


cdef inline int _logging_log_axis_order(object logger, str msg, axis_vec_t& fst) except -1 nogil:
    with cython.gil:
        logger.debug(msg.format(fst=fst))
    return 0


cdef inline int _logging_log_int(object logger, str msg, int fst=0, int snd=0, int third=0) except -1 nogil:
    with cython.gil:
        logger.debug(msg.format(fst=fst, snd=snd, third=third))
    return 0


cdef inline int64_t _div_ceil(int64_t a, int64_t b) except?-1 nogil:
    return (a + (b - 1)) // b


cdef bint _needs_wide_strides(int64_t grid_volume, StridedLayout dst_layout, StridedLayout src_layout) except?-1 nogil:
    # grid_volume, i.e the block_size * num_blocks
    if grid_volume > INT_MAX:
        return True
    cdef int64_t min_offset = 0
    cdef int64_t max_offset = 0
    dst_layout.get_offset_bounds(min_offset, max_offset)
    cdef int64_t src_min_offset = 0
    cdef int64_t src_max_offset = 0
    src_layout.get_offset_bounds(src_min_offset, src_max_offset)
    min_offset = min(min_offset, src_min_offset)
    max_offset = max(max_offset, src_max_offset)
    # forbid INT_MIN too for:
    # 1. abs() to be safe
    # 2. it us used as out_of_bounds_sentinel in the transpose copy kernel
    if min_offset <= INT_MIN or max_offset > INT_MAX:
        return True
    return False


cdef bint _needs_grid_stride_loop(int64_t &cuda_num_blocks, int64_t num_blocks) except?-1 nogil:
    if num_blocks <= INT_MAX:
        cuda_num_blocks = num_blocks
        return False
    else:
        cuda_num_blocks = INT_MAX
        return True


cdef bint _get_transpose_num_blocks(int64_t &num_blocks, int64_t &cuda_num_blocks, int64_t block_size, int block_height, int transposed_dim, StridedLayout layout) except?-1 nogil:
    cdef int ndim = layout.base.ndim
    cdef int64_t volume = 1
    for i in range(transposed_dim + 1):
        volume *= layout.base.shape[i]
    volume = _div_ceil(volume, block_height) * block_height
    for i in range(transposed_dim + 1, ndim):
        volume *= layout.base.shape[i]
    num_blocks = _div_ceil(volume, block_size)
    if num_blocks <= INT_MAX:
        cuda_num_blocks = num_blocks
        return False
    else:
        cuda_num_blocks = INT_MAX
        return True


cdef str _emit_transpose_kernel_code(StridedLayout dst_layout, StridedLayout src_layout, bint needs_wide_strides, bint needs_grid_stride_loop, int block_height, int block_width, char reading_order, int transposed_dim):
    if dst_layout.ndim != src_layout.ndim:
        raise ValueError("dst_ndim and src_ndim must be equal")
    cdef str stride_t_str = "int64_t" if needs_wide_strides else "int32_t"
    cdef str needs_grid_stride_loop_str = "true" if needs_grid_stride_loop else "false"
    kernel_code = f"""
    #include <transposed.h>
    TRANSPOSE_KERNEL({stride_t_str}, {dst_layout.base.ndim}, {dst_layout.base.itemsize}, {needs_grid_stride_loop_str}, {transposed_dim}, {block_height}, {block_width}, '{chr(reading_order)}')
    """
    return kernel_code


cdef intptr_t _get_transpose_copy_kernel(StridedLayout dst_layout, StridedLayout src_layout, bint needs_wide_strides, bint needs_grid_stride_loop, int block_height, int block_width, char reading_order, int transposed_dim, int device_id, object logger) except? 0:
    cdef str kernel_code = _emit_transpose_kernel_code(dst_layout, src_layout, needs_wide_strides, needs_grid_stride_loop, block_height, block_width, reading_order, transposed_dim)
    cdef str include_path = get_include_path(logger)
    return get_kernel(kernel_code, "transpose_copy", device_id, include_path, logger)


cdef str _emit_elementwise_kernel_code(StridedLayout dst_layout, StridedLayout src_layout, bint needs_wide_strides, bint needs_grid_stride_loop):
    cdef str stride_t_str = "int64_t" if needs_wide_strides else "int32_t"
    cdef str needs_grid_stride_loop_str = "true" if needs_grid_stride_loop else "false"
    kernel_code = f"""
    #include <elementwise.h>
    ELEMENTWISE_KERNEL({stride_t_str}, {dst_layout.base.ndim}, {src_layout.base.ndim}, {dst_layout.base.itemsize}, {needs_grid_stride_loop_str})
    """
    return kernel_code


cdef intptr_t _get_elementwise_copy_kernel(StridedLayout dst_layout, StridedLayout src_layout, bint needs_wide_strides, bint needs_grid_stride_loop, int device_id, object logger) except? 0:
    cdef str kernel_code = _emit_elementwise_kernel_code(dst_layout, src_layout, needs_wide_strides, needs_grid_stride_loop)
    cdef str include_path = get_include_path(logger)
    return get_kernel(kernel_code, "elementwise_copy", device_id, include_path, logger)


cdef int _launch_transpose_copy(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int block_height, int block_width, char reading_order, int transposed_dim, int device_id, intptr_t stream_ptr, object logger) except -1 nogil:
    cdef int64_t block_size = block_height * block_width
    cdef int64_t num_blocks = 0
    cdef int64_t cuda_num_blocks = 0
    cdef bint needs_grid_stride_loop = _get_transpose_num_blocks(num_blocks, cuda_num_blocks, block_size, block_height, transposed_dim, dst_layout)
    cdef bint needs_wide_strides = _needs_wide_strides(num_blocks * block_size, dst_layout, src_layout)
    cdef args_t args
    get_kernel_args(args, dst_layout, src_layout, dst_ptr, src_ptr, num_blocks)
    cdef void* args_ptr = args.get()
    cdef intptr_t kernel_fn_ptr
    with cython.gil:
        kernel_fn_ptr = _get_transpose_copy_kernel(dst_layout, src_layout, needs_wide_strides, needs_grid_stride_loop, block_height, block_width, reading_order, transposed_dim, device_id, logger)
        if logger is not None:
            logger.debug(f"Launching transpose copy kernel {kernel_fn_ptr} with grid {cuda_num_blocks} and block {block_size}.")
        launch_kernel(kernel_fn_ptr, <intptr_t>&args_ptr, cuda_num_blocks, 1, 1, block_size, 1, 1, 0, stream_ptr)
    return 0


cdef int _launch_elementwise_copy(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int block_size, int device_id, intptr_t stream_ptr, object logger) except -1 nogil:
    cdef int64_t volume = dst_layout.get_volume()
    cdef int64_t num_blocks = _div_ceil(volume, block_size)
    cdef int64_t cuda_num_blocks = 0
    cdef bint needs_grid_stride_loop = _needs_grid_stride_loop(cuda_num_blocks, num_blocks)
    cdef bint needs_wide_strides = _needs_wide_strides(num_blocks * block_size, dst_layout, src_layout)
    cdef args_t args
    get_kernel_args(args, dst_layout, src_layout, dst_ptr, src_ptr, volume)
    cdef void* args_ptr = args.get()
    cdef intptr_t kernel_fn_ptr
    with cython.gil:
        kernel_fn_ptr = _get_elementwise_copy_kernel(dst_layout, src_layout, needs_wide_strides, needs_grid_stride_loop, device_id, logger)
        if logger is not None:
            logger.debug(f"Launching elementwise copy kernel {kernel_fn_ptr} with grid {cuda_num_blocks} and block {block_size}.")
        launch_kernel(kernel_fn_ptr, <intptr_t>&args_ptr, cuda_num_blocks, 1, 1, block_size, 1, 1, 0, stream_ptr)
    return 0


cdef int _get_transpose_copy_order(axis_vec_t& copy_order, int ndim, int transposed_dim, axes_mask_t src_axes_mask, axis_vec_t &src_order) except -1 nogil:
    copy_order.clear()
    copy_order.reserve(ndim)
    cdef axis_t axis
    cdef axes_mask_t axis_flag
    cdef int i = 0
    # the dims that come before the reading dim (and are not part of reading tile)
    # remain in their original order
    while i < transposed_dim:
        axis_flag = _axis2mask(i)
        if not (src_axes_mask & axis_flag):
            copy_order.push_back(i)
        i += 1
    # put the reading dims together, in the order of src_order
    i = 0
    while i < ndim:
        axis = src_order[i]
        axis_flag = _axis2mask(axis)
        if src_axes_mask & axis_flag:
            copy_order.push_back(axis)
        i += 1
    # resume putting remaining dims in their original order
    i = transposed_dim
    while i < ndim:
        axis_flag = _axis2mask(i)
        if not (src_axes_mask & axis_flag):
            copy_order.push_back(i)
        i += 1
    return 0


cdef int _permute_layouts_for_transpose_copy(StridedLayout dst_layout, StridedLayout src_layout, int ndim, axis_t transposed_dim, axes_mask_t src_axes_mask, axis_vec_t &src_order, object logger) except -1 nogil:
    cdef axis_vec_t copy_order
    _get_transpose_copy_order(copy_order, ndim, transposed_dim, src_axes_mask, src_order)
    dst_layout.permute_into(dst_layout, copy_order)
    src_layout.permute_into(src_layout, copy_order)
    if logger is not None:
        _logging_log_axis_order(logger, "The layouts are permuted to place the read dims together: {fst}", copy_order)
        _logging_helper(logger, "Permuted dst_layout: {fst}, src_layout: {snd}", dst_layout, src_layout)
    return 0


cdef axes_mask_t get_contiguous_axes_up_to_vol(int64_t &suffix_vol, axes_mask_t forbidden_axes, int64_t max_volume, StridedLayout layout, axis_t* axis_order=NULL) except? -1 nogil:
    cdef int i = layout.base.ndim - 1
    suffix_vol = 1
    cdef axes_mask_t axes_mask = 0
    cdef axes_mask_t axis_flag
    cdef int axis
    while i >= 0 and suffix_vol < max_volume:
        if axis_order:
            axis = axis_order[i]
        else:
            axis = i
        axis_flag = _axis2mask(axis)
        if forbidden_axes & axis_flag:
            break
        if c_abs(layout.base.strides[axis]) > suffix_vol:
            break
        axes_mask |= axis_flag
        suffix_vol *= layout.base.shape[axis]
        i -= 1
    return axes_mask



cdef int _adjust_layouts_for_transpose_copy(char &reading_order, int &transposed_dim, int &block_height, int &block_width, StridedLayout dst_layout, StridedLayout src_layout, object logger) except -1 nogil:
    # logical tile extents: 16 threads in the column read together
    # and 32 threads in the row write together
    reading_order = b'F'
    block_height = 16
    block_width = 32
    cdef int ndim = dst_layout.base.ndim
    cdef int n_read_dims = 0
    if ndim < 2 or dst_layout.get_volume() < block_height * block_width:
        return 0
    cdef int64_t suffix_dst_vol = 1, suffix_src_vol = 1
    # we assume the dst_layout strides are already sorted (increasing right-to-left)
    cdef axes_mask_t dst_axes_mask = get_contiguous_axes_up_to_vol(suffix_dst_vol, 0, block_width, dst_layout)
    # not enough contiguous dims in dst_layout
    if suffix_dst_vol < block_width:
        return 0
    # for src_layout extents, we need to find the axes order to check if there are
    # enough contiguous dims
    cdef axis_vec_t src_order
    src_layout.get_stride_order(src_order)
    # get first contiguous dims in the src_layout order, stopping as soon as we
    # have at least block_height elements or we encounter extent
    # that is needed for contiguous writes to the dst_layout.
    cdef axes_mask_t src_axes_mask = get_contiguous_axes_up_to_vol(suffix_src_vol, dst_axes_mask, block_height, src_layout, src_order.data())
    # not enough contiguous dims in src_layout
    if suffix_src_vol < block_height:
        return 0
    if logger is not None:
        _logging_log_axis_order(logger, "Src order: {fst}", src_order)
        _logging_log_int(logger, "Dst axes mask: {fst}, src_layout axes mask: {snd}", dst_axes_mask, src_axes_mask)
    # we have enough contiguous elements for tiled reading and writing
    # to simplify the kernel (and recompile less) we want to place extents
    # from src_axes_mask together
    cdef int i = 0
    # Find the max of all axes in src_axes_mask.
    # As dst_layout layout is sorted, this will be the innermost/rightmost
    # extent of all src_axes_mask in the dst_layout layout
    while i < ndim:
        if src_axes_mask & _axis2mask(i):
            transposed_dim = i
            n_read_dims += 1
        i += 1
    if logger is not None:
        _logging_log_int(logger, "There are {fst} dims needed for big enough coalesced reads, transposed dim: {snd}", n_read_dims, transposed_dim)
    # if there is one, large enough extent to read from, there's no need
    # to permute the layouts
    if n_read_dims <= 1:
        return n_read_dims
    # otherwise, we permute the layouts to place the read dims together
    _permute_layouts_for_transpose_copy(dst_layout, src_layout, ndim, transposed_dim, src_axes_mask, src_order, logger)
    return n_read_dims


cdef bint _adjust_layouts_for_elementwise_copy(StridedLayout dst_layout, StridedLayout src_layout, object logger) except -1 nogil:
    cdef axes_mask_t dst_flat_mask = dst_layout.get_flattened_axis_mask()
    cdef axes_mask_t src_flat_mask = src_layout.get_flattened_axis_mask()
    cdef axes_mask_t flatten_all_mask = flattening_axes_mask_from_range(dst_layout.base.ndim, 0, -1)
    # There is a faster kernel specialized if either of the layouts squeezed to 1D.
    # Note, if either layout was squeezed "a bit", but neither of them down to 1D,
    # we prefer keeping the original layouts, as we know the original shapes are equal
    # so the kernel can unravel flat element index once for both layouts.
    if dst_flat_mask == flatten_all_mask:
        dst_layout.flatten_into(dst_layout, flatten_all_mask)
        if logger is not None:
            _logging_helper(logger, "Squeezed the dst to 1D {fst}", dst_layout)
    if src_flat_mask == flatten_all_mask:
        src_layout.flatten_into(src_layout, flatten_all_mask)
        if logger is not None:
            _logging_helper(logger, "Squeezed the src to 1D {fst}", src_layout)
    return True


cdef bint _use_tranpose_copy_maybe(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int device_id, intptr_t stream_ptr, object logger=None) except -1 nogil:
    # Dimension of the tile
    cdef int block_height = 0
    cdef int block_width = 0
    # Dimension in the src/dst tensor that splits the shape in two parts
    # [0, transposed_dim] and [transposed_dim + 1, ndim - 1]
    # for the purpose of traversing it with the 2D tile.
    cdef int transposed_dim = 0
    cdef char reading_order = b'F'
    cdef int n_read_dims = _adjust_layouts_for_transpose_copy(reading_order, transposed_dim, block_height, block_width, dst_layout, src_layout, logger)
    if n_read_dims <= 0:
        return False
    _launch_transpose_copy(dst_layout, src_layout, dst_ptr, src_ptr, block_height, block_width, reading_order, transposed_dim, device_id, stream_ptr, logger)
    return True


cdef int _use_elementwise_copy(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int device_id, intptr_t stream_ptr, object logger=None) except -1 nogil:
    cdef int block_size = 128
    _adjust_layouts_for_elementwise_copy(dst_layout, src_layout, logger)
    _launch_elementwise_copy(dst_layout, src_layout, dst_ptr, src_ptr, block_size, device_id, stream_ptr, logger)
    return 0


cdef int _simplify_layouts(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, object logger) except -1 nogil:
    cdef axis_vec_t dst_stride_order
    dst_layout.get_stride_order(dst_stride_order)
    dst_layout.permute_into(dst_layout, dst_stride_order)
    src_layout.permute_into(src_layout, dst_stride_order)

    cdef axes_mask_t flat_mask = dst_layout.get_flattened_axis_mask()
    flat_mask &= src_layout.get_flattened_axis_mask()
    dst_layout.flatten_into(dst_layout, flat_mask)
    src_layout.flatten_into(src_layout, flat_mask)

    if logger is not None:
        _logging_log_axis_order(logger, "The dst_order is {fst}", dst_stride_order)
        _logging_helper(logger, "Permuted, squeezed, and flattened strides: dst {fst}, src_layout {snd}", dst_layout, src_layout)

    cdef int itemsize = dst_layout.base.itemsize
    cdef int new_itemsize = 8
    if itemsize < new_itemsize:
        new_itemsize = dst_layout.get_max_compatible_itemsize(new_itemsize, dst_ptr, axis=-1)
    if itemsize < new_itemsize:
        new_itemsize = src_layout.get_max_compatible_itemsize(new_itemsize, src_ptr, axis=-1)
    if itemsize < new_itemsize:
        dst_layout.pack_into(dst_layout, new_itemsize, dst_ptr, axis=-1, keep_dim=False)
        src_layout.pack_into(src_layout, new_itemsize, src_ptr, axis=-1, keep_dim=False)
        itemsize = new_itemsize
        if logger is not None:
            _logging_helper(logger, "Copy will use bigger/vectorized itemsize: vectorized_dst: {fst}, vectorized_src: {snd}", dst_layout, src_layout)
    return 0


cdef int launch_copy_kernel(StridedLayout dst_layout, StridedLayout src_layout, intptr_t dst_ptr, intptr_t src_ptr, int device_id, intptr_t stream_ptr, object logger) except -1:
    """
    Launches transposed or elementwise copy kernel. Assumes that both src and dst layouts
    have equal shapes and itemsizes, dst_layout is unique, and both pointers
    point to data of the same dtype.
    """
    cdef StridedLayout dst_norm = StridedLayout.__new__(StridedLayout)
    cdef StridedLayout src_norm = StridedLayout.__new__(StridedLayout)
    dst_layout.squeeze_into(dst_norm)
    src_layout.squeeze_into(src_norm)
    _simplify_layouts(dst_norm, src_norm, dst_ptr, src_ptr, logger)

    if _use_tranpose_copy_maybe(dst_norm, src_norm, dst_ptr, src_ptr, device_id, stream_ptr, logger):
        return 0
    _use_elementwise_copy(dst_norm, src_norm, dst_ptr, src_ptr, device_id, stream_ptr, logger)
    return 0
