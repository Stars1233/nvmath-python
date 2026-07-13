# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
StridedLayout can be used from Python and Cython code.
In Python, it feels customary for layout meta-data (shape/strides) to be
immutable (tuples), so the StridedLayout is immutable too
(to avoid unexpected modifications of a shared layout).
All transforming methods (``reshaped``, ``permuted``, etc.)
return a new instance if the transform is not a no-op.

In Cython, to reduce Python overhead (class instantiation, gil acquisition),
StridedLayout has extra cdef-ed methods (``reshape_into``, ``permute_into``, etc.)
that accept an instance of StridedLayout to store the result, that
can be self (in which case it will be modified in place). It is Cython
user responsibility to make sure externally provided StridedLayout instances
are not modified in-place if they may be used elsewhere (e.g. by calling
copy() method at the Cython function entry point).
"""

cimport cpython
from cpython.object cimport PyObject

cimport cython
from cython.operator cimport dereference as deref

from libc.stdint cimport intptr_t, uint64_t, int64_t, int32_t
from libcpp cimport vector
from libcpp.cmath cimport abs as c_abs


ctypedef fused integer_t:
    int64_t
    int32_t


cdef extern from "../include/_layout.hpp" namespace "nvmath_strided_layout":

    ctypedef uint64_t axes_mask_t
    ctypedef int64_t extent_t
    ctypedef int64_t stride_t
    ctypedef int32_t axis_t
    ctypedef vector.vector[stride_t] extents_strides_mem_t
    ctypedef vector.vector[axis_t] axis_vec_t

    int _popcount(axes_mask_t x) nogil
    void _order_from_strides(axis_vec_t& indices, extent_t* extents, stride_t* strides, int ndim) except + nogil
    void _swap(extents_strides_mem_t &a, extents_strides_mem_t &b) noexcept nogil
    void _swap(int64_t*& a, int64_t*& b) noexcept nogil
    void _swap(extent_t& a, extent_t& b) noexcept nogil
    void _swap(int& a, int& b) noexcept nogil
    void _swap(axis_vec_t &a, axis_vec_t &b) noexcept nogil


cdef extern from "../include/_layout.hpp":
    cdef int STRIDED_LAYOUT_MAX_NDIM
    cdef axes_mask_t STRIDED_LAYOUT_AXES_MASK_ALL


cdef extern from "../include/_layout_properties.hpp" namespace "nvmath_strided_layout":
    ctypedef unsigned int property_mask_t

    cdef enum OrderFlag:
        ORDER_NONE
        ORDER_C
        ORDER_F
        ORDER_PERM

    enum BooleanProperty:
        IS_CONTIGUOUS_C
        IS_ABS_DENSE_C
        IS_LEADING_DENSE_C
        IS_ABS_LEADING_DENSE_C
        IS_CONTIGUOUS_F
        IS_ABS_DENSE_F
        IS_LEADING_DENSE_F
        IS_ABS_LEADING_DENSE_F
        IS_CONTIGUOUS_ANY
        IS_ABS_DENSE_ANY
        IS_LEADING_DENSE_ANY
        IS_ABS_LEADING_DENSE_ANY
        HAS_STRIDE_ORDER_C
        HAS_STRIDE_ORDER_F
        IS_UNIQUE
        IS_EXHAUSTIVE
        HAS_NO_NEGATIVE_STRIDE

    enum Property:
        OFFSET_BOUNDS
        MEMORY_RANGE_SIZE
        SHAPE
        STRIDES
        STRIDES_IN_BYTES
        STRIDE_ORDER
        UNIT_EXTENTS
        VOLUME
        MIN_MAX_STRIDE

    cdef bint _has_valid_property(property_mask_t has_props, int prop) noexcept nogil
    cdef void _mark_property_valid(property_mask_t& has_props, int prop) noexcept nogil
    cdef bint _boolean_property(property_mask_t bool_props, int prop) noexcept nogil
    cdef void _set_boolean_property(property_mask_t& has_props, property_mask_t& bool_props, int prop, bint value) noexcept nogil
    cdef int _dense_prop(OrderFlag order_flag, int allow_negative_strides, int allow_leading_dim_stride) noexcept nogil


cdef struct BaseLayout:
    # A struct holding the shape and strides for the layout.
    # The struct must be initialized before it is passed to any other APIs.
    # Use ``init_base_layout`` for minimal initialization of the layout,
    # it will set the ``shape`` and ``strides`` pointers to point to
    # ndim contiguous integer arrays. After that you are responsible
    # for filling out the ``ndim``, ``shape`` array and ``strides`` array.
    # Alternatively, use ``init_base_layout_from_tuple`` or ``init_base_layout_from_ptr``
    # (followed by zero_out_base_strides or set_base_dense_strides
    # if no explicit strides are provided) to initialize and validate the layout.

    # Note, extent_t and stride_t are both int64_t and we use a single _mem
    # allocation for both (there's some overhead to small allocations but even
    # more so, Cython adds overhead on handling very unlikely exceptions
    # around the vector instantiation).
    extents_strides_mem_t _mem
    extent_t* shape
    stride_t* strides
    int ndim
    int itemsize


@cython.final
cdef class StridedLayout:

    # Definition
    cdef:
        BaseLayout base

    # Lazy properties computed from the BaseLayout.
    cdef:
        # Set to 0 to invalidate all properties,
        # whenever a defining attribute is changed
        property_mask_t _prop_mask

        # C and Python properties
        property_mask_t _boolean_props
        int64_t _memory_range_size
        stride_t _min_offset
        stride_t _max_offset
        stride_t _min_stride
        stride_t _max_stride
        axes_mask_t _unit_extents_mask
        int64_t _volume

        # Python properties
        tuple _py_shape
        tuple _py_strides
        tuple _py_strides_in_bytes
        tuple _py_stride_order

    # ==============================
    # Initialization
    # ==============================

    cdef inline int init_from_ptr(StridedLayout self, int ndim, int itemsize, extent_t* shape, stride_t* strides, bint divide_strides=False) except -1 nogil:
        self._prop_mask = 0
        init_base_layout_from_ptr(self.base, ndim, itemsize, shape, strides, divide_strides)
        if strides == NULL:
            self._init_dense_strides(ORDER_C)
        return 0

    cdef inline int init_from_tuple(StridedLayout self, int itemsize, tuple shape, tuple strides, bint divide_strides=False) except -1:
        self._prop_mask = 0
        init_base_layout_from_tuple(self.base, itemsize, shape, strides, divide_strides)
        if strides is None:
            self._init_dense_strides(ORDER_C)
        elif divide_strides:
            self._py_strides_in_bytes = strides
            mark_property_valid(self, STRIDES_IN_BYTES)
        else:
            self._py_strides = strides
            mark_property_valid(self, STRIDES)
        self._py_shape = shape
        mark_property_valid(self, SHAPE)
        return 0

    cdef inline int init_dense_from_ptr(StridedLayout self, int ndim, int itemsize, extent_t* shape, OrderFlag order_flag, axis_vec_t* stride_order=NULL) except -1 nogil:
        self._prop_mask = 0
        init_base_layout_from_ptr(self.base, ndim, itemsize, shape, NULL)
        self._init_dense_strides(order_flag, stride_order)
        return 0

    cdef inline int init_dense_from_tuple(StridedLayout self, int itemsize, tuple shape, object stride_order) except -1:
        cdef axis_vec_t stride_order_vec
        cdef OrderFlag order_flag = _stride_order2vec(stride_order_vec, stride_order)

        if order_flag == ORDER_NONE:
            raise ValueError(f"The stride_order must be 'C', 'F', or a permutation tuple. Got: {stride_order}")

        self._prop_mask = 0
        init_base_layout_from_tuple(self.base, itemsize, shape, None)
        self._init_dense_strides(order_flag, &stride_order_vec)
        self._py_shape = shape
        mark_property_valid(self, SHAPE)
        return 0

    cdef inline int _init_dense_strides(StridedLayout self, OrderFlag order_flag, axis_vec_t* stride_order=NULL) except -1 nogil:
        cdef stride_t volume
        if order_flag == ORDER_C:
            set_boolean_property(self, IS_CONTIGUOUS_C, True)
        elif order_flag == ORDER_F:
            set_boolean_property(self, IS_CONTIGUOUS_F, True)
        elif order_flag == ORDER_PERM:
            if stride_order == NULL:
                raise ValueError("stride_order is required for ORDER_PERM")
            set_boolean_property(self, IS_CONTIGUOUS_ANY, True)
        else:
            raise ValueError("The stride_order must be 'C', 'F', or a permutation.")
        volume = set_base_dense_strides(self.base, order_flag, stride_order)
        # computing dense strides gives us the volume for free
        self._volume = volume
        mark_property_valid(self, VOLUME)
        return 0

    cdef inline int make_dense(StridedLayout self, OrderFlag order_flag, axis_vec_t* stride_order=NULL) except -1 nogil:
        if self.get_is_dense(order_flag, stride_order):
            return 0

        self._prop_mask = 0

        if order_flag != ORDER_NONE:
            self._init_dense_strides(order_flag, stride_order)
            return 0

        cdef axis_vec_t current_order_vec
        self.get_stride_order(current_order_vec)
        self._init_dense_strides(ORDER_PERM, &current_order_vec)
        return 0

    cdef inline StridedLayout copy(StridedLayout self):
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.init_from_ptr(self.base.ndim, self.base.itemsize, self.base.shape, self.base.strides)
        return new_layout

    cdef inline int reset_base(StridedLayout self, BaseLayout& base) except -1 nogil:
        # Reset all memoized properties
        self._prop_mask = 0

        # Set new base
        _swap_base_layout(self.base, base)
        return 0

    # ==============================
    # Properties
    # ==============================

    cdef inline tuple get_shape_tuple(StridedLayout self):
        if not has_valid_property(self, SHAPE):
            self._py_shape = _carray_integer_t_to_tuple(self.base.shape, self.base.ndim)
            mark_property_valid(self, SHAPE)
        return self._py_shape

    cdef inline tuple get_strides_tuple(StridedLayout self):
        if not has_valid_property(self, STRIDES):
            self._py_strides = _carray_integer_t_to_tuple(self.base.strides, self.base.ndim)
            mark_property_valid(self, STRIDES)
        return self._py_strides

    cdef inline int get_strides_in_bytes(StridedLayout self, extents_strides_mem_t& strides_in_bytes) except -1 nogil:
        cdef const stride_t* strides = self.base.strides
        strides_in_bytes.resize(self.base.ndim)
        for i in range(self.base.ndim):
            strides_in_bytes[i] = _overflow_checked_mul(strides[i], self.base.itemsize)
        return 0

    cdef inline tuple get_strides_in_bytes_tuple(StridedLayout self):
        if has_valid_property(self, STRIDES_IN_BYTES):
            return self._py_strides_in_bytes
        cdef extents_strides_mem_t strides_in_bytes
        self.get_strides_in_bytes(strides_in_bytes)
        self._py_strides_in_bytes = _carray_integer_t_to_tuple(strides_in_bytes.data(), strides_in_bytes.size())
        mark_property_valid(self, STRIDES_IN_BYTES)
        return self._py_strides_in_bytes

    cdef inline int64_t get_volume(StridedLayout self) except -1 nogil:
        if not has_valid_property(self, VOLUME):
            self._volume = base_volume(self.base)
            mark_property_valid(self, VOLUME)
        return self._volume

    cdef inline int64_t get_len(StridedLayout self) except -1 nogil:
        if self.base.ndim == 0:
            raise TypeError("The layout is a scalar, it has no length.")
        return self.base.shape[0]

    cdef inline int get_stride_order(StridedLayout self, axis_vec_t& stride_order) except -1 nogil:
        _order_from_strides(stride_order, self.base.shape, self.base.strides, self.base.ndim)
        return 0

    cdef inline tuple get_stride_order_tuple(StridedLayout self):
        if has_valid_property(self, STRIDE_ORDER):
            return self._py_stride_order
        cdef axis_vec_t stride_order
        self.get_stride_order(stride_order)
        self._py_stride_order = _carray_integer_t_to_tuple(stride_order.data(), stride_order.size())
        mark_property_valid(self, STRIDE_ORDER)
        return self._py_stride_order

    cdef inline bint get_is_unique(StridedLayout self) except -1 nogil:
        if has_valid_property(self, IS_UNIQUE):
            return boolean_property(self, IS_UNIQUE)
        cdef axis_vec_t stride_order
        self.get_stride_order(stride_order)
        cdef bint is_unique = set_boolean_property(self, IS_UNIQUE, base_is_unique(self.get_volume(), self.base, stride_order))
        if is_unique and peek_boolean_property(self, IS_EXHAUSTIVE):
            set_boolean_property(self, IS_ABS_DENSE_ANY, True)
        return is_unique

    cdef inline bint get_is_exhaustive(StridedLayout self) except -1 nogil:
        if has_valid_property(self, IS_EXHAUSTIVE):
            return boolean_property(self, IS_EXHAUSTIVE)
        cdef axis_vec_t stride_order
        self.get_stride_order(stride_order)
        cdef bint is_exhaustive = set_boolean_property(self, IS_EXHAUSTIVE, base_is_exhaustive(self.get_volume(), self.base, stride_order))
        if is_exhaustive and peek_boolean_property(self, IS_UNIQUE):
            set_boolean_property(self, IS_ABS_DENSE_ANY, True)
        return is_exhaustive

    cdef inline bint get_is_contiguous_c(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_C, NULL)

    cdef inline bint get_is_contiguous_f(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_F, NULL)

    cdef inline bint get_is_contiguous_any(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_NONE, NULL)

    cdef inline bint get_is_abs_dense_c(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_C, NULL, allow_negative_strides=True)

    cdef inline bint get_is_abs_dense_f(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_F, NULL, allow_negative_strides=True)

    cdef inline bint get_is_abs_dense_any(StridedLayout self) except -1 nogil:
        return self.get_is_dense(ORDER_NONE, NULL, allow_negative_strides=True)

    cdef inline bint get_is_dense(StridedLayout self, OrderFlag order_flag, axis_vec_t* stride_order_vec=NULL, bint allow_negative_strides=False, bint allow_leading_dim_stride=False) except -1 nogil:
        cdef int prop = dense_prop(order_flag, allow_negative_strides, allow_leading_dim_stride)

        # For arbitrary permutation, we can't use `c`, `f`, `any` cached flags, we need to compute it.
        # But, if the answer is True, we can mark `any` to True.
        if order_flag == ORDER_PERM:
            if base_is_dense(self.get_volume(), self.base, order_flag, stride_order_vec, allow_negative_strides, allow_leading_dim_stride):
                set_boolean_property(self, prop, True)
                return True
            return False

        if has_valid_property(self, prop):
            return boolean_property(self, prop)

        cdef axis_vec_t stride_order
        if order_flag == ORDER_NONE:
            self.get_stride_order(stride_order)
            order_flag = ORDER_PERM
        return set_boolean_property(self, prop, base_is_dense(self.get_volume(), self.base, order_flag, &stride_order, allow_negative_strides, allow_leading_dim_stride))

    cdef inline bint get_has_no_negative_stride(StridedLayout self) except -1 nogil:
        # HAS_NO_NEGATIVE_STRIDE unfortunately has the negation in the name, but
        # it's easier this way to capture implications (dense -> HAS_NO_NEGATIVE_STRIDE)
        # than the (dense -> not HAS_NEGATIVE_STRIDE)
        if has_valid_property(self, HAS_NO_NEGATIVE_STRIDE):
            return boolean_property(self, HAS_NO_NEGATIVE_STRIDE)
        return set_boolean_property(self, HAS_NO_NEGATIVE_STRIDE, base_has_no_negative_stride(self.get_volume(), self.base))

    cdef inline stride_t get_min_stride(StridedLayout self) except? -1 nogil:
        """
        Minimal stride is the smallest wrt to absolute value (i.e. from -1, 2, -3)
        the minimal is -1.
        """
        if has_valid_property(self, MIN_MAX_STRIDE):
            return self._min_stride
        base_layout_min_max_stride(self.get_volume(), self.base, self._min_stride, self._max_stride)
        mark_property_valid(self, MIN_MAX_STRIDE)
        return self._min_stride

    cdef inline stride_t get_max_stride(StridedLayout self) except? -1 nogil:
        """
        Maximal stride is the largest wrt to absolute value,
        from -1, 2, -3, the maximal is -3.
        """
        if has_valid_property(self, MIN_MAX_STRIDE):
            return self._max_stride
        base_layout_min_max_stride(self.get_volume(), self.base, self._min_stride, self._max_stride)
        mark_property_valid(self, MIN_MAX_STRIDE)
        return self._max_stride

    cdef inline axes_mask_t get_unit_extents_mask(StridedLayout self) except -1 nogil:
        if not has_valid_property(self, UNIT_EXTENTS):
            self._unit_extents_mask = base_unit_extents_mask(self.base)
            mark_property_valid(self, UNIT_EXTENTS)
        return self._unit_extents_mask

    cdef inline bint get_has_stride_order(StridedLayout self, OrderFlag order_flag, axis_vec_t* stride_order_vec=NULL) except -1 nogil:
        if order_flag == ORDER_PERM:
            return base_has_stride_order(self.get_volume(), self.base, ORDER_PERM, stride_order_vec)

        cdef int prop
        if order_flag == ORDER_C:
            prop = HAS_STRIDE_ORDER_C
        elif order_flag == ORDER_F:
            prop = HAS_STRIDE_ORDER_F
        else:
            raise ValueError("The stride_order must be 'C', 'F', or a permutation.")
        if has_valid_property(self, prop):
            return boolean_property(self, prop)
        return set_boolean_property(self, prop, base_has_stride_order(self.get_volume(), self.base, order_flag, NULL))

    cdef inline int get_offset_bounds(StridedLayout self, stride_t& min_offset, stride_t& max_offset) except -1 nogil:
        if has_valid_property(self, OFFSET_BOUNDS):
            min_offset = self._min_offset
            max_offset = self._max_offset
            return 0
        if self.get_volume() == 0:
            self._min_offset = min_offset = 0
            self._max_offset = max_offset = -1
            mark_property_valid(self, OFFSET_BOUNDS)
            return 0
        cdef int ndim = self.base.ndim
        cdef stride_t stride
        cdef extent_t extent
        min_offset = 0
        max_offset = 0
        for i in range(ndim):
            stride = self.base.strides[i]  # can be negative
            extent = self.base.shape[i]  # must be non-negative
            if stride <= 0:
                min_offset = _overflow_checked_sum(min_offset, _overflow_checked_mul(stride, (extent - 1)))
            else:
                max_offset = _overflow_checked_sum(max_offset, _overflow_checked_mul(stride, (extent - 1)))
        self._min_offset = min_offset
        self._max_offset = max_offset
        mark_property_valid(self, OFFSET_BOUNDS)
        return 0

    cdef inline stride_t get_min_offset(StridedLayout self) except? -1 nogil:
        if has_valid_property(self, OFFSET_BOUNDS):
            return self._min_offset
        cdef stride_t min_offset = 0
        cdef stride_t max_offset = 0
        self.get_offset_bounds(min_offset, max_offset)
        return min_offset

    cdef inline stride_t get_max_offset(StridedLayout self) except? -1 nogil:
        if has_valid_property(self, OFFSET_BOUNDS):
            return self._max_offset
        cdef stride_t min_offset = 0
        cdef stride_t max_offset = 0
        self.get_offset_bounds(min_offset, max_offset)
        return max_offset

    cdef inline stride_t get_min_offset_in_bytes(StridedLayout self) except? -1 nogil:
        return _overflow_checked_mul(self.get_min_offset(), self.base.itemsize)

    cdef inline stride_t get_max_offset_in_bytes(StridedLayout self) except? -1 nogil:
        return _overflow_checked_mul(self.get_max_offset(), self.base.itemsize)

    cdef inline int64_t get_memory_range_size(StridedLayout self) except? -1 nogil:
        if has_valid_property(self, MEMORY_RANGE_SIZE):
            return self._memory_range_size
        if peek_boolean_property(self, IS_ABS_DENSE_ANY):
            self._memory_range_size = self.get_volume()
            mark_property_valid(self, MEMORY_RANGE_SIZE)
            return self._memory_range_size
        cdef stride_t min_offset = 0
        cdef stride_t max_offset = 0
        self.get_offset_bounds(min_offset, max_offset)
        cdef int64_t memory_range_size = _overflow_checked_diff(max_offset, min_offset)
        self._memory_range_size = _overflow_checked_sum(memory_range_size, 1)
        mark_property_valid(self, MEMORY_RANGE_SIZE)
        return self._memory_range_size

    cdef inline int64_t get_memory_range_size_in_bytes(StridedLayout self) except? -1 nogil:
        return _overflow_checked_mul(self.get_memory_range_size(), self.base.itemsize)

    cdef axes_mask_t get_flattened_axis_mask(StridedLayout self) except? -1 nogil
    cdef int get_max_compatible_itemsize(StridedLayout self, int max_itemsize, intptr_t data_ptr, int axis=*) except -1 nogil

    cdef inline bint get_is_equal(StridedLayout self, StridedLayout other) except -1 nogil:
        if self is other:
            return True
        return base_layout_equal(self.base, other.base)

    cdef inline bint get_is_almost_equal(StridedLayout self, StridedLayout other) except -1 nogil:
        if self is other:
            return True
        return base_layout_almost_equal(self.base, other.base)

    # ==============================
    # Layout manipulation
    # ==============================

    cdef inline StridedLayout get_to_dense(StridedLayout self, OrderFlag order_flag, axis_vec_t* stride_order_vec=NULL):
        if self.get_is_dense(order_flag, stride_order_vec):
            return self

        cdef axis_vec_t current_order_vec
        if order_flag == ORDER_NONE:
            self.get_stride_order(current_order_vec)
            stride_order_vec = &current_order_vec
            order_flag = ORDER_PERM

        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.init_dense_from_ptr(
            self.base.ndim,
            self.base.itemsize,
            self.base.shape,
            order_flag,
            stride_order_vec
        )
        return new_layout

    cdef inline int to_dense_into(StridedLayout self, StridedLayout out_layout, OrderFlag order_flag, axis_vec_t* stride_order_vec=NULL) except -1 nogil:
        if self is out_layout:
            return self.make_dense(order_flag, stride_order_vec)

        cdef axis_vec_t current_order_vec
        if order_flag == ORDER_NONE:
            self.get_stride_order(current_order_vec)
            stride_order_vec = &current_order_vec
            order_flag = ORDER_PERM

        out_layout.init_dense_from_ptr(
            self.base.ndim,
            self.base.itemsize,
            self.base.shape,
            order_flag,
            stride_order_vec
        )
        return 0

    cdef StridedLayout get_sliced(StridedLayout self, stride_t &slice_offset, object slices)

    cdef StridedLayout get_concat(StridedLayout self, StridedLayout other, axis_t axis=*)
    cdef int concat_into(StridedLayout self, StridedLayout out_layout, const BaseLayout& other, axis_t axis=*) except -1 nogil
    cdef StridedLayout get_sub(StridedLayout self, axis_t start_axis=*, axis_t end_axis=*, axis_vec_t* axes=*)
    cdef int sub_into(StridedLayout self, StridedLayout out_layout, axis_t start_axis=*, axis_t end_axis=*, axis_vec_t* axes=*) except -1 nogil
    cdef StridedLayout get_reshaped(StridedLayout self, BaseLayout& like)
    cdef int reshape_into(StridedLayout self, StridedLayout out_layout, BaseLayout& like) except -1 nogil
    cdef StridedLayout get_permuted(StridedLayout self, axis_vec_t& axis_order, bint inverse=*)
    cdef int permute_into(StridedLayout self, StridedLayout out_layout, axis_vec_t& axis_order, bint inverse=*) except -1 nogil
    cdef StridedLayout get_reversed(StridedLayout self)
    cdef int reverse_into(StridedLayout self, StridedLayout out_layout) except -1 nogil
    cdef StridedLayout get_transposed(StridedLayout self, axis_t axis_a, axis_t axis_b)
    cdef int transpose_into(StridedLayout self, StridedLayout out_layout, axis_t axis_a, axis_t axis_b) except -1 nogil
    cdef StridedLayout get_flattened(StridedLayout self, axes_mask_t axis_mask)
    cdef int flatten_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask) except -1 nogil
    cdef StridedLayout get_squeezed(StridedLayout self, axes_mask_t axis_mask=*)
    cdef int squeeze_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask=*) except -1 nogil
    cdef StridedLayout get_unsqueezed(StridedLayout self, axes_mask_t axis_mask)
    cdef int unsqueeze_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask) except -1 nogil
    cdef StridedLayout get_broadcast(StridedLayout self, BaseLayout& like)
    cdef int broadcast_into(StridedLayout self, StridedLayout out_layout, BaseLayout& like) except -1 nogil
    cdef StridedLayout get_unbroadcast(StridedLayout self)
    cdef int unbroadcast_into(StridedLayout self, StridedLayout out_layout) except -1 nogil
    cdef StridedLayout get_packed(StridedLayout self, int itemsize, intptr_t data_ptr, int axis=*, bint keep_dim=*)
    cdef int pack_into(StridedLayout self, StridedLayout out_layout, int itemsize, intptr_t data_ptr, int axis=*, bint keep_dim=*) except -1 nogil
    cdef StridedLayout get_unpacked(StridedLayout self, int itemsize, int axis=*, bint add_dim=*)
    cdef int unpack_into(StridedLayout self, StridedLayout out_layout, int itemsize, int axis=*, bint add_dim=*) except -1 nogil


cdef class SlicedLayout:

    cdef:
        BaseLayout base

        readonly:
            stride_t slice_offset

    cdef:
        # Logically, SlicedLayout is StridedLayout + slice_offset,
        # but to keep SlicedLayout overhead minimal
        # (one vs two Python class instantiations for each [] operator call),
        # it is really defined in terms of BaseLayout + slice_offset, and the StridedLayout
        # is instantiated on demand.
        StridedLayout _layout

    cdef inline int init_from_base(SlicedLayout self, BaseLayout& base, stride_t slice_offset, StridedLayout layout=None) except -1:
        _swap_base_layout(self.base, base)
        self.slice_offset = slice_offset
        self._layout = layout
        return 0

    cdef inline stride_t get_slice_offset_in_bytes(SlicedLayout self) except? -1 nogil:
        return _overflow_checked_mul(self.slice_offset, self.base.itemsize)

    cdef StridedLayout get_layout(SlicedLayout self)
    cdef SlicedLayout get_sliced(SlicedLayout self, object slices)


# ==============================
# IterAxis helpers
# ==============================


cdef struct IterAxisInCOrder:
    int ndim


cdef struct IterAxisInFOrder:
    int ndim


cdef struct IterAxisInPermOrder:
    int ndim
    axis_t* axis_order


ctypedef fused IterAxisType:
    IterAxisInCOrder
    IterAxisInFOrder
    IterAxisInPermOrder


cdef union IterAxisHelper:
    IterAxisInCOrder c
    IterAxisInFOrder f
    IterAxisInPermOrder perm


cdef inline int _setup_axis_iter(IterAxisHelper& axis_helper, int ndim, OrderFlag order_flag, axis_vec_t* axis_order_vec) except -1 nogil:
    if order_flag == ORDER_C:
        axis_helper.c.ndim = ndim
        return 0
    elif order_flag == ORDER_F:
        axis_helper.f.ndim = ndim
        return 0
    if order_flag != ORDER_PERM:
        raise ValueError(f"Invalid order flag: {order_flag}")
    if axis_order_vec == NULL:
        raise ValueError("order is required for ORDER_PERM")
    cdef int axis_order_size = deref(axis_order_vec).size()
    if ndim != axis_order_size:
        raise ValueError(f"Permutation must have the same length as the number of dimensions, got {axis_order_size} for {ndim}D tensor.")
    cdef axis_t* axis_order = deref(axis_order_vec).data()
    cdef axes_mask_t visited_mask = 0
    cdef axis_t axis
    cdef axes_mask_t axis_mask_i
    for i in range(ndim):
        if not _normalize_axis(axis_order[i], ndim):
            raise ValueError(f"Axis {axis_order[i]} out of range for {ndim}D tensor")
        axis = axis_order[i]
        axis_mask_i = _axis2mask(axis)
        if visited_mask & axis_mask_i:
            raise ValueError(f"Expected a permutation. Axis {axis} appears multiple times.")
        visited_mask |= axis_mask_i
    axis_helper.perm.axis_order = axis_order
    axis_helper.perm.ndim = ndim
    return 0


cdef inline int _get_axis(IterAxisType& axis_helper, int i) except? -2 nogil:
    if IterAxisType is IterAxisInCOrder:
        return i
    elif IterAxisType is IterAxisInFOrder:
        return axis_helper.ndim - 1 - i

    assert IterAxisType is IterAxisInPermOrder
    return axis_helper.axis_order[i]


# ==============================
# Base layout helpers
# ==============================


cdef inline int _validate_itemsize(int itemsize) except -1 nogil:
    if itemsize <= 0:
        raise ValueError("The itemsize must be positive")
    if itemsize & (itemsize - 1):
        raise ValueError("The itemsize must be a power of two")
    return 0


cdef inline int init_base_layout(BaseLayout& layout, int ndim, int itemsize) except -1 nogil:
    if 0 > ndim or ndim > STRIDED_LAYOUT_MAX_NDIM:
        raise ValueError(f"Unsupported number of dimensions: {ndim}. Max supported ndim is {STRIDED_LAYOUT_MAX_NDIM}")
    _validate_itemsize(itemsize)
    layout._mem.resize(2 * ndim)
    layout.shape = layout._mem.data()
    layout.strides = layout._mem.data() + ndim
    layout.ndim = ndim
    layout.itemsize = itemsize
    return 0


cdef inline int trim_base_layout(BaseLayout& layout, int ndim) except -1 nogil:
    if ndim > layout.ndim:
        raise AssertionError(f"Cannot trim layout to {ndim} dimensions, it has {layout.ndim} dimensions")
    layout.ndim = ndim
    return 0


cdef inline int init_base_layout_from_tuple(BaseLayout& base, int itemsize, tuple shape, tuple strides, bint divide_strides=False) except -1:
    cdef int ndim = len(shape)
    init_base_layout(base, ndim, itemsize)
    for i in range(ndim):
        base.shape[i] = shape[i]
    validate_base_shape(base)

    if strides is not None:
        if len(strides) != ndim:
            raise ValueError(f"Strides, if provided, must have the same length as shape. Shape has {ndim} dimensions, but strides has {len(strides)} elements.")
        for i in range(ndim):
            base.strides[i] = strides[i]
        if divide_strides:
            divide_base_strides(base)
    return 0


cdef inline int init_base_layout_from_ptr(BaseLayout& base, int ndim, int itemsize, extent_t* shape, stride_t* strides, bint divide_strides=False) except -1 nogil:
    init_base_layout(base, ndim, itemsize)
    for i in range(ndim):
        base.shape[i] = shape[i]
    validate_base_shape(base)

    if strides != NULL:
        for i in range(ndim):
            base.strides[i] = strides[i]
        if divide_strides:
            divide_base_strides(base)
    return 0


cdef inline int validate_base_shape(BaseLayout& base) except -1 nogil:
    for i in range(base.ndim):
        if base.shape[i] < 0:
            raise ValueError("Extents must be non-negative")
    return 0


cdef inline void _swap_base_layout(BaseLayout& a, BaseLayout& b) noexcept nogil:
    if &a == &b:
        return
    _swap(a._mem, b._mem)
    _swap(a.shape, b.shape)
    _swap(a.strides, b.strides)
    _swap(a.ndim, b.ndim)
    _swap(a.itemsize, b.itemsize)


cdef inline bint base_equal_shapes(BaseLayout& a, BaseLayout& b) noexcept nogil:
    if a.ndim != b.ndim:
        return False
    for i in range(a.ndim):
        if a.shape[i] != b.shape[i]:
            return False
    return True


cdef inline bint _base_equal_strides(BaseLayout& a, BaseLayout& b) noexcept nogil:
    cdef stride_t* strides_a = a.strides
    cdef stride_t* strides_b = b.strides
    for i in range(a.ndim):
        if strides_a[i] != strides_b[i]:
            return False
    return True


cdef inline bint base_equal_strides(BaseLayout& a, BaseLayout& b) noexcept nogil:
    return a.ndim == b.ndim and _base_equal_strides(a, b)


cdef inline bint base_layout_equal(BaseLayout& a, BaseLayout& b) noexcept nogil:
    return a.itemsize == b.itemsize and base_equal_shapes(a, b) and _base_equal_strides(a, b)


cdef inline bint base_layout_almost_equal(BaseLayout& a, BaseLayout& b) noexcept nogil:
    if a.itemsize != b.itemsize:
        return False
    cdef int ndim = a.ndim
    if ndim != b.ndim:
        return False
    cdef stride_t* strides_a = a.strides
    cdef stride_t* strides_b = b.strides
    cdef extent_t extent
    for i in range(ndim):
        extent = a.shape[i]
        if b.shape[i] != extent:
            return False
        if extent != 1 and strides_a[i] != strides_b[i]:
            return False
    return True


@cython.overflowcheck(True)
cdef inline int64_t base_volume(BaseLayout& base) except? -1 nogil:
    cdef int64_t vol = 1
    for i in range(base.ndim):
        vol *= base.shape[i]
    return vol


cdef inline int divide_base_strides(BaseLayout& base) except -1 nogil:
    cdef stride_t stride
    cdef stride_t itemsize = base.itemsize
    for i in range(base.ndim):
        stride = base.strides[i] // itemsize
        if stride * itemsize != base.strides[i]:
            raise ValueError("strides must be divisible by itemsize")
        base.strides[i] = stride
    return 0


cdef inline void zero_out_base_strides(BaseLayout& base) noexcept nogil:
    for i in range(base.ndim):
        base.strides[i] = 0


cdef inline stride_t _set_base_dense_strides(IterAxisType& axis_iter, BaseLayout& base) except? -1 nogil:
    cdef stride_t stride = 1
    cdef int i = base.ndim - 1
    while i >= 0:
        axis = _get_axis(axis_iter, i)
        base.strides[axis] = stride
        stride = _overflow_checked_mul(stride, base.shape[axis])
        i -= 1
    if stride == 0:
        zero_out_base_strides(base)
    return stride


cdef inline stride_t set_base_dense_strides(BaseLayout& base, OrderFlag order_flag, axis_vec_t* stride_order) except? -1 nogil:
    cdef IterAxisHelper axis_iter
    _setup_axis_iter(axis_iter, base.ndim, order_flag, stride_order)
    if order_flag == ORDER_C:
        return _set_base_dense_strides(axis_iter.c, base)
    elif order_flag == ORDER_F:
        return _set_base_dense_strides(axis_iter.f, base)
    elif order_flag == ORDER_PERM:
        return _set_base_dense_strides(axis_iter.perm, base)
    else:
        raise ValueError(f"Invalid order flag: {order_flag}")


cdef inline bint _base_is_dense(IterAxisType& axis_iter, BaseLayout& base, bint allow_negative_strides, bint allow_leading_dim_stride) except -1 nogil:
    cdef int j = base.ndim - 1
    cdef stride_t expected_stride = 1
    cdef stride_t current_stride
    cdef extent_t extent
    cdef axis_t axis
    if allow_leading_dim_stride:
        # Find first non-unit extent
        while j >= 0:
            axis = _get_axis(axis_iter, j)
            if base.shape[axis] != 1:
                expected_stride = base.strides[axis]
                break
            j -= 1
        if expected_stride == 0:
            return False
        elif expected_stride < 0:
            if allow_negative_strides:
                expected_stride = -expected_stride
            else:
                return False
    while j >= 0:
        axis = _get_axis(axis_iter, j)
        extent = base.shape[axis]
        if extent != 1:
            current_stride = base.strides[axis]
            if allow_negative_strides:
                current_stride = c_abs(current_stride)
            if current_stride != expected_stride:
                return False
            expected_stride *= extent
        j -= 1
    return True


cdef inline bint base_is_dense(int64_t volume, BaseLayout& base, OrderFlag order_flag, axis_vec_t* stride_order, bint allow_negative_strides, bint allow_leading_dim_stride) except -1 nogil:
    cdef int ndim = base.ndim
    if volume == 0 or ndim < 1:
        return True
    cdef IterAxisHelper axis_iter
    _setup_axis_iter(axis_iter, ndim, order_flag, stride_order)
    if order_flag == ORDER_C:
        return _base_is_dense(axis_iter.c, base, allow_negative_strides, allow_leading_dim_stride)
    elif order_flag == ORDER_F:
        return _base_is_dense(axis_iter.f, base, allow_negative_strides, allow_leading_dim_stride)
    elif order_flag == ORDER_PERM:
        return _base_is_dense(axis_iter.perm, base, allow_negative_strides, allow_leading_dim_stride)
    else:
        raise ValueError(f"Invalid order flag: {order_flag}")


cdef inline bint base_has_no_negative_stride(int64_t volume, BaseLayout& base) except -1 nogil:
    if volume == 0:
        return True
    for i in range(base.ndim):
        if base.shape[i] != 1 and base.strides[i] < 0:
            return False
    return True


cdef inline int base_layout_min_max_stride(int64_t volume, BaseLayout& base, stride_t& min_stride, stride_t& max_stride) except -1 nogil:
    # There's no meaningful stride for empty or scalar layout.
    # 0 could hint at broadcasting while 1 hints at dense.
    # Chances are, some packages could complain about 0, so we pick 1.
    # For volume 0, maybe more importantly, as we treat it as dense, the
    # max_stride = 1 agrees with the offset_bounds = [0, -1]
    # -1 = max_offset = (volume - 1) * max_stride = (0 - 1) * 1
    min_stride = 1
    max_stride = 1
    if volume <= 1:  # empty or effectively a scalar
        return 0

    cdef int i = 0
    cdef extent_t extent
    cdef stride_t stride
    # find the first non-unit extent
    while i < base.ndim:
        extent = base.shape[i]
        if extent != 1:
            stride = base.strides[i]
            min_stride = stride
            max_stride = stride
            i += 1
            break
        i += 1

    # find the min and max stride
    while i < base.ndim:
        extent = base.shape[i]
        if extent != 1:
            stride = base.strides[i]
            if c_abs(stride) < c_abs(min_stride):
                min_stride = stride
            if c_abs(stride) > c_abs(max_stride):
                max_stride = stride
        i += 1
    return 0


cdef inline axes_mask_t base_unit_extents_mask(BaseLayout& base) except -1 nogil:
    cdef axes_mask_t unit_extents_mask = 0
    cdef int i = 0
    while i < base.ndim:
        if base.shape[i] == 1:
            unit_extents_mask |= _axis2mask(i)
        i += 1
    return unit_extents_mask


cdef inline bint _base_has_stride_order(IterAxisType& axis_iter, BaseLayout& base) except -1 nogil:
    cdef stride_t prev_stride = 0
    cdef extent_t extent
    cdef stride_t stride
    cdef int i = base.ndim - 1
    cdef axis_t axis
    while i >= 0:
        axis = _get_axis(axis_iter, i)
        extent = base.shape[axis]
        if extent != 1:
            stride = c_abs(base.strides[axis])
            if stride < prev_stride:
                return False
            prev_stride = stride
        i -= 1
    return True


cdef inline bint base_has_stride_order(int64_t volume, BaseLayout& base, OrderFlag order_flag, axis_vec_t* stride_order_vec) except -1 nogil:
    if volume == 0:
        return True
    cdef IterAxisHelper axis_iter
    _setup_axis_iter(axis_iter, base.ndim, order_flag, stride_order_vec)
    if order_flag == ORDER_C:
        return _base_has_stride_order(axis_iter.c, base)
    elif order_flag == ORDER_F:
        return _base_has_stride_order(axis_iter.f, base)
    elif order_flag == ORDER_PERM:
        return _base_has_stride_order(axis_iter.perm, base)
    else:
        raise ValueError(f"Invalid order flag: {order_flag}")


cdef inline bint base_is_unique(int64_t volume, BaseLayout& base, axis_vec_t& stride_order) except -1 nogil:
    """
    Check if every two valid indices map to different memory offsets in the
    range ``[min_offset, max_offset]``.
    Note, ``is_unique() and is_exhaustive() == is_abs_dense_any()``.

    What do we check here?
    Let's have o = stride_order and say we processed dims ``o[i], ..., o[ndim-1]``
    Indices limited to those dimensions (i.e. index[o[j]] = 0 for j < i)
    map indices uniquely (injective) to ``[cur_min_offset, cur_max_offset]``, where
    ``cur_min_offset = sum((extent[o[j]] - 1) * strides[o[j]] for j in range(i, ndim) if strides[o[j]] < 0)``
    ``cur_max_offset = sum((extent[o[j]] - 1) * strides[o[j]] for j in range(i, ndim) if strides[o[j]] >= 0)``
    Now, if we consider the next dimension (``o[i - 1]``) and its stride ``s_next``,
    we want to make sure that ``idx * s_next + [cur_min_offset, cur_max_offset]``
    and ``(idx + 1) * s_next + [cur_min_offset, cur_max_offset]`` do not overlap.
    We check that:
      * for ``s_next >= 0``, ``idx * s_next + cur_max_offset < (idx + 1) * s_next + cur_min_offset``
      * for ``s_next < 0``, ``(idx + 1) * s_next + cur_max_offset < idx * s_next + cur_min_offset``
    Those two are equivalent to abs(s_next) > cur_max_offset - cur_min_offset.
    Note, ``cur_max_offset - cur_min_offset = sum((extent[o[j]] - 1) * abs(strides[o[j]]) for j in range(i, ndim))``.
    """
    if volume == 0:
        return True
    cdef int64_t cur_range = 0
    cdef int i = base.ndim - 1
    cdef int64_t stride
    cdef axis_t axis
    cdef extent_t extent
    while i >= 0:
        axis = stride_order[i]
        extent = base.shape[axis]
        if extent != 1:
            stride = c_abs(base.strides[axis])
            if stride <= cur_range:
                return False
            cur_range = _overflow_checked_sum(cur_range, _overflow_checked_mul(stride, (extent - 1)))
        i -= 1
    return True


cdef inline bint base_is_exhaustive(int64_t volume, BaseLayout& base, axis_vec_t& stride_order) except -1 nogil:
    """
    Check if there exists an index for every element in the range
    ``[min_offset, max_offset]``, i.e. the mapping from indices
    to memory offsets is onto/surjective.
    Note, ``is_unique() and is_exhaustive() == is_abs_dense_any()``.

    What do we check here?
    Let's have o = stride_order and say we processed dims ``o[i], ..., o[ndim-1]``
    Indices limited to those dimensions (i.e. index[o[j]] = 0 for j < i)
    map indices exhaustively (onto/surjective) to ``[cur_min_offset, cur_max_offset]``, where
    ``cur_min_offset = sum((extent[o[j]] - 1) * strides[o[j]] for j in range(i, ndim) if strides[o[j]] < 0)``
    ``cur_max_offset = sum((extent[o[j]] - 1) * strides[o[j]] for j in range(i, ndim) if strides[o[j]] >= 0)``
    Now, if we consider the next dimension (``o[i - 1]``) and its stride ``s_next``,
    we want to make sure that ``idx * s_next + [cur_min_offset, cur_max_offset]``
    and ``(idx + 1) * s_next + [cur_min_offset, cur_max_offset]`` overlap or touch.
    We check that:
      * for ``s_next >= 0``, ``idx * s_next + cur_max_offset + 1 >= (idx + 1) * s_next + cur_min_offset``
      * for ``s_next < 0``, ``(idx + 1) * s_next + cur_max_offset + 1 >= idx * s_next + cur_min_offset``
    Those two are equivalent to abs(s_next) <= cur_max_offset - cur_min_offset + 1.
    Note, ``cur_max_offset - cur_min_offset = sum((extent[o[j]] - 1) * abs(strides[o[j]]) for j in range(i, ndim))``.
    """
    if volume == 0:
        return True
    cdef int64_t cur_range = 1
    cdef int i = base.ndim - 1
    cdef int64_t stride
    cdef axis_t axis
    cdef extent_t extent
    while i >= 0:
        axis = stride_order[i]
        extent = base.shape[axis]
        if extent != 1:
            stride = c_abs(base.strides[axis])
            if stride > cur_range:
                return False
            cur_range = _overflow_checked_sum(cur_range, _overflow_checked_mul(stride, (extent - 1)))
        i -= 1
    return True


# ==============================
# Strided layout helpers
# ==============================

cdef inline int dense_prop(OrderFlag order_flag, bint allow_negative_strides, bint allow_leading_dim_stride) except -1 nogil:
    cdef int prop = _dense_prop(order_flag, allow_negative_strides, allow_leading_dim_stride)
    if prop < 0:
        raise ValueError(f"Invalid order_flag: {order_flag}")
    return prop


cdef inline bint has_valid_property(StridedLayout self, int prop) except? -1 nogil:
    return _has_valid_property(self._prop_mask, prop)


cdef inline int mark_property_valid(StridedLayout self, int prop) except? -1 nogil:
    _mark_property_valid(self._prop_mask, prop)
    return 0


cdef inline bint boolean_property(StridedLayout self, int prop) except? -1 nogil:
    return _boolean_property(self._boolean_props, prop)


cdef inline bint set_boolean_property(StridedLayout self, int prop, bint value) except? -1 nogil:
    _set_boolean_property(self._prop_mask, self._boolean_props, prop, value)
    return value


cdef inline bint peek_boolean_property(StridedLayout self, int prop) except? -1 nogil:
    """
    True -> the property is True
    False -> the property is False or not set yet
    """
    return _has_valid_property(self._prop_mask, prop) and _boolean_property(self._boolean_props, prop)


cdef inline dict get_boolean_flags(StridedLayout self):
    cdef dict properties = {
        "IS_CONTIGUOUS_C": IS_CONTIGUOUS_C,
        "IS_ABS_DENSE_C": IS_ABS_DENSE_C,
        "IS_LEADING_DENSE_C": IS_LEADING_DENSE_C,
        "IS_ABS_LEADING_DENSE_C": IS_ABS_LEADING_DENSE_C,

        "IS_CONTIGUOUS_F": IS_CONTIGUOUS_F,
        "IS_ABS_DENSE_F": IS_ABS_DENSE_F,
        "IS_LEADING_DENSE_F": IS_LEADING_DENSE_F,
        "IS_ABS_LEADING_DENSE_F": IS_ABS_LEADING_DENSE_F,

        "IS_CONTIGUOUS_ANY": IS_CONTIGUOUS_ANY,
        "IS_ABS_DENSE_ANY": IS_ABS_DENSE_ANY,
        "IS_LEADING_DENSE_ANY": IS_LEADING_DENSE_ANY,
        "IS_ABS_LEADING_DENSE_ANY": IS_ABS_LEADING_DENSE_ANY,

        "HAS_STRIDE_ORDER_C": HAS_STRIDE_ORDER_C,
        "HAS_STRIDE_ORDER_F": HAS_STRIDE_ORDER_F,
        "IS_UNIQUE": IS_UNIQUE,
        "IS_EXHAUSTIVE": IS_EXHAUSTIVE,
        "HAS_NO_NEGATIVE_STRIDE": HAS_NO_NEGATIVE_STRIDE,
    }

    return {name: boolean_property(self, prop) for name, prop in properties.items() if has_valid_property(self, prop)}

# ==============================
# Conversion, validation and normalization helpers
# ==============================

cdef inline tuple as_tuple(object obj):
    if obj is None or type(obj) is tuple:
        return obj
    elif isinstance(obj, int):
        return (obj,)
    else:
        return tuple(obj)


cdef inline axes_mask_t _axis2mask(axis_t axis) noexcept nogil:
    return 1ULL << axis


cdef inline axes_mask_t all_axes_mask(int ndim) noexcept nogil:
    if ndim == 0:
        return 0
    elif ndim == STRIDED_LAYOUT_MAX_NDIM:
        return STRIDED_LAYOUT_AXES_MASK_ALL
    return (1ULL << ndim) - 1ULL


cdef inline OrderFlag _stride_order2vec(axis_vec_t& stride_order_vec, object stride_order) except? ORDER_NONE:
    if stride_order == 'C':
        return ORDER_C
    elif stride_order == 'F':
        return ORDER_F
    elif isinstance(stride_order, tuple | list):
        _tuple2axis_vec(stride_order_vec, stride_order)
        return ORDER_PERM
    return ORDER_NONE


cdef inline int _tuple2axis_vec(axis_vec_t& vec, object t) except -1:
    cdef int ndim = len(t)
    vec.resize(ndim)
    for i in range(ndim):
        vec[i] = t[i]
    return 0


cdef inline bint _normalize_axis(integer_t& axis, integer_t extent) except -1 nogil:
    if axis < -extent or axis >= extent:
        return False
    if axis < 0:
        axis += extent
    return True


cdef inline axes_mask_t _tuple2axis_mask(int32_t ndim, object t) except? -1:
    # Returns mask such that mask & _axis2mask(axis) is True iff axis is in t
    cdef axes_mask_t mask = 0
    cdef axis_t axis
    cdef axes_mask_t axis_mask = 0
    if isinstance(t, int):
        axis = t
        if not _normalize_axis(axis, ndim):
            raise ValueError(f"Invalid axis: {axis} out of range for {ndim}D tensor")
        return _axis2mask(axis)
    for e in t:
        axis = e
        if not _normalize_axis(axis, ndim):
            raise ValueError(f"Invalid axis: {axis} out of range for {ndim}D tensor")
        axis_mask = _axis2mask(axis)
        if mask & axis_mask:
            raise ValueError(f"Axis {axis} appears multiple times.")
        mask |= axis_mask
    return mask


cdef inline tuple _axes_mask2tuple(axes_mask_t mask):
    cdef int ndim = _popcount(mask)
    cdef axis_vec_t axes
    axes.resize(ndim)
    cdef int out_i = 0
    for i in range(STRIDED_LAYOUT_MAX_NDIM):
        if mask & _axis2mask(i):
            axes[out_i] = i
            out_i += 1
    return _carray_integer_t_to_tuple(axes.data(), ndim)


cdef inline axes_mask_t axes_mask_from_range(int32_t ndim, int32_t start_axis, int32_t end_axis) except? -1 nogil:
    # Returns mask such that mask & _axis2mask(axis) is True iff axis is
    # in inclusive range [start_axis, end_axis]
    if start_axis == 0 and end_axis == -1:
        return all_axes_mask(ndim)
    if not _normalize_axis(start_axis, ndim):
        raise ValueError(f"Invalid start axis: {start_axis} out of range for {ndim}D tensor")
    if not _normalize_axis(end_axis, ndim):
        raise ValueError(f"Invalid end axis: {end_axis} out of range for {ndim}D tensor")
    cdef axes_mask_t axes_mask = all_axes_mask(ndim)
    axes_mask &= (STRIDED_LAYOUT_AXES_MASK_ALL << start_axis)
    axes_mask &= (STRIDED_LAYOUT_AXES_MASK_ALL >> (STRIDED_LAYOUT_MAX_NDIM - end_axis - 1))
    return axes_mask


cdef inline axes_mask_t unsqueeze_to_ndim_mask(int32_t in_ndim, int32_t out_ndim, int32_t axis) except? -1 nogil:
    if in_ndim > out_ndim:
        raise ValueError(
            f"Invalid number of dimensions: {out_ndim}. It must be greater than or equal "
            f"to the current number of dimensions: {in_ndim}."
        )
    elif in_ndim == out_ndim:
        return 0
    elif out_ndim > STRIDED_LAYOUT_MAX_NDIM:
        raise ValueError(
            f"Invalid number of dimensions: {out_ndim}. It must be less than or equal "
            f"to {STRIDED_LAYOUT_MAX_NDIM}."
        )
    if not _normalize_axis(axis, in_ndim + 1):
        raise ValueError(f"Invalid axis: {axis} out of range for {in_ndim}D tensor")
    cdef int num_new_axes = out_ndim - in_ndim
    cdef axes_mask_t mask = all_axes_mask(axis + num_new_axes)
    cdef axes_mask_t left_mask = all_axes_mask(axis)
    return mask & (~left_mask)


cdef inline axes_mask_t flattening_axes_mask_from_range(int ndim, int start_axis, int end_axis) except? -1 nogil:
    # Returns mask such that mask & _axis2mask(axis) is True iff axis is
    # in inclusive range [start_axis + 1, end_axis]
    # (As for flattening, the mask & _axis2mask(axis) means the axis
    # can be flattened with axis - 1)
    if start_axis == 0 and end_axis == -1:
        return all_axes_mask(ndim) & (~_axis2mask(0))
    if not _normalize_axis(start_axis, ndim):
        raise ValueError(f"Invalid start axis: {start_axis} out of range for {ndim}D tensor")
    if not _normalize_axis(end_axis, ndim):
        raise ValueError(f"Invalid end axis: {end_axis} out of range for {ndim}D tensor")
    if start_axis == end_axis:
        return 0
    cdef axes_mask_t axes_mask = all_axes_mask(ndim)
    axes_mask &= (STRIDED_LAYOUT_AXES_MASK_ALL << (start_axis + 1))
    axes_mask &= (STRIDED_LAYOUT_AXES_MASK_ALL >> (STRIDED_LAYOUT_MAX_NDIM - end_axis - 1))
    return axes_mask


@cython.overflowcheck(True)
cdef inline int64_t _overflow_checked_mul(int64_t a, int64_t b) except? -1 nogil:
    return a * b


@cython.overflowcheck(True)
cdef inline int64_t _overflow_checked_diff(int64_t a, int64_t b) except? -1 nogil:
    return a - b


@cython.overflowcheck(True)
cdef inline int64_t _overflow_checked_sum(int64_t a, int64_t b) except? -1 nogil:
    return a + b


@cython.overflowcheck(True)
cdef inline int64_t _overflow_checked_div_ceil(int64_t a, int64_t b) except? -1 nogil:
    return (a + b - 1) // b


# https://github.com/NVIDIA/cuda-python/blob/main/cuda_core/cuda/core/_utils/cuda_utils.pxd

# Use Python C API directly instead of cython wrappers, as those end up incorrectly
# decrefing the temporary Python int object after it is set as tuple element (resulting
# in a double free when the tuple is garbage collected).
cdef extern from "Python.h":
    PyObject *_PyLong_FromLongLong "PyLong_FromLongLong" (long long val) except NULL
    void _PyTuple_SET_ITEM "PyTuple_SET_ITEM" (object p, Py_ssize_t pos, PyObject *o)


cdef inline tuple _carray_integer_t_to_tuple(const integer_t *ptr, int length):
    # Construct shape and strides tuples using the Python/C API for speed
    cdef tuple result = cpython.PyTuple_New(length)
    for i in range(length):
        _PyTuple_SET_ITEM(result, i, _PyLong_FromLongLong(ptr[i]))
    return result
