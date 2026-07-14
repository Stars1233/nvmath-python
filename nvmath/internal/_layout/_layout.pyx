# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

cimport cython
from cython.operator cimport dereference as deref

from libc.stdint cimport int64_t, intptr_t

from cpython.object cimport PyObject


cdef extern from "Python.h":
    int _PySlice_Unpack "PySlice_Unpack" (PyObject *slice, Py_ssize_t *start, Py_ssize_t *stop, Py_ssize_t *step) except -1
    Py_ssize_t _PySlice_AdjustIndices "PySlice_AdjustIndices" (Py_ssize_t length, Py_ssize_t *start, Py_ssize_t *stop, Py_ssize_t step) noexcept nogil


@cython.final
cdef class StridedLayout:
    """
    A class describing the layout of a multi-dimensional tensor
    with a shape, strides and itemsize.

    In Python, the StridedLayout is immutable, all transforming methods
    (e.g. :meth:`reshaped`, :meth:`permuted`, etc.)
    return a new instance or unchanged self. The latter may happen
    if the operation would be a no-op (like reshaping to the same shape).

    .. warning::
        This API is experimental and may change at any time.
    """

    def __init__(
        self : StridedLayout,
        shape : tuple[int] | list[int] | int,
        strides : tuple[int] | list[int] | int | None,
        itemsize : int,
        divide_strides : bool = False
    ) -> None:
        """
        Parameters
        ----------
        shape : tuple
            A tuple of non-negative integers.
        strides : tuple or None
            If a tuple, it must be a tuple of integers of the same length as ``shape``.
            If None, the strides are assumed to be C-contiguous.
        itemsize : int
            The number of bytes per single element (dtype size). Must be a power of two.
        divide_strides : bool, optional
            If True, the provided :attr:`strides` will be divided by the :attr:`itemsize`.


        See also :meth:`dense`.
        """
        self.init_from_tuple(itemsize, as_tuple(shape), as_tuple(strides), divide_strides)

    @classmethod
    def dense(
        cls,
        shape : tuple[int] | list[int] | int,
        itemsize : int,
        stride_order : str | tuple[int] | list[int] = 'C'
    ) -> StridedLayout:
        """
        Creates a new StridedLayout instance with dense strides.

        Parameters
        ----------
        shape : tuple
            A tuple of non-negative integers.
        itemsize : int
            The number of bytes per single element of the tensor.
        stride_order : str or tuple, optional
            The order of the strides:
                * 'C' (default) - the strides are computed in C-order (increasing from the right to the left)
                * 'F' - the strides are computed in F-order (increasing from the left to the right)
                * A tuple - it must be a permutation of ``tuple(range(len(shape)))``.
                  The last element of the tuple is the axis with stride 1.

            See also :attr:`stride_order`.


        .. highlight:: python
        .. code-block:: python

            assert StridedLayout.dense((5, 3, 7), 1, "C") == StridedLayout((5, 3, 7), (21, 7, 1), 1)
            assert StridedLayout.dense((5, 3, 7), 1, "F") == StridedLayout((5, 3, 7), (1, 5, 15), 1)
            assert StridedLayout.dense((5, 3, 7), 1, (2, 0, 1)) == StridedLayout((5, 3, 7), (3, 1, 15), 1)

        """
        cdef StridedLayout new_layout = StridedLayout.__new__(cls)
        new_layout.init_dense_from_tuple(itemsize, as_tuple(shape), stride_order)
        return new_layout

    @classmethod
    def dense_like(
        cls,
        other : StridedLayout,
        stride_order : str | tuple[int] | list[int] = "K"
    ) -> StridedLayout:
        """
        Creates a StridedLayout with the same :attr:`shape` and :attr:`itemsize` as the other layout,
        but with contiguous strides in the specified order.

        .. note::
            The returned layout is guaranteed to be contiguous, i.e. :attr:`is_contiguous_any` is True.
            Layout can be dense in a less strict sense (e.g. having negative strides but still bijective),
            such layouts are still converted to meet the strict definition of contiguous layout.

        See also :attr:`is_contiguous_any`, :meth:`is_dense`.

        Parameters
        ----------
        other : StridedLayout
            The StridedLayout to copy the :attr:`shape` and :attr:`itemsize` from.
        stride_order : str or tuple, optional
            The order of the strides:
                * 'K' (default) - keeps the order of the strides as in the ``other`` layout.
                * 'C' - the strides are computed in C-order (increasing from the right to the left)
                * 'F' - the strides are computed in F-order (increasing from the left to the right)
                * A tuple - it must be a permutation of ``tuple(range(len(shape)))``.
                  The last element of the tuple is the axis with stride 1.

            See also :attr:`stride_order`.


        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 7), 1).permuted((2, 0, 1))
            assert layout == StridedLayout((7, 5, 3), (1, 21, 7), 1)

            # dense_like with the default "K" stride_order
            # keeps the same order of strides as in the original layout
            assert StridedLayout.dense_like(layout) == layout
            # "C", "F" recompute the strides accordingly
            assert StridedLayout.dense_like(layout, "C") == StridedLayout((7, 5, 3), (15, 3, 1), 1)
            assert StridedLayout.dense_like(layout, "F") == StridedLayout((7, 5, 3), (1, 7, 35), 1)
        """
        if stride_order == "K":
            return other.get_to_dense(ORDER_NONE)

        cdef OrderFlag order_flag
        cdef axis_vec_t stride_order_vec
        order_flag = _stride_order2vec(stride_order_vec, stride_order)

        if order_flag == ORDER_NONE:
            raise ValueError(
                f"The stride_order must be 'K', 'C', 'F', "
                f"or a permutation tuple. Got: {stride_order}"
            )
        return other.get_to_dense(order_flag, &stride_order_vec)

    def __repr__(self : StridedLayout) -> str:
        return (
            f"StridedLayout(shape={self.shape}, strides={self.strides}, itemsize={self.base.itemsize})"
        )

    def __eq__(self : StridedLayout, other : StridedLayout) -> bool:
        return self.get_is_equal(other)

    def __add__(self : StridedLayout, other : StridedLayout) -> StridedLayout:
        return self.get_concat(other)

    def is_almost_equal(self : StridedLayout, other : StridedLayout) -> bool:
        """
        Equality, but with relaxed checks for strides, i.e:
        strides for unit extents are not compared

        .. highlight:: python
        .. code-block:: python

            l1 = StridedLayout.dense((3, 1), 1, stride_order="C")
            l2 = StridedLayout.dense((3, 1), 1, stride_order="F")
            assert l1.shape == l2.shape
            assert l1.strides == (1, 1)
            assert l2.strides == (1, 3)
            assert l1 != l2
            assert l1.is_almost_equal(l2)
        """
        return self.get_is_almost_equal(other)

    @property
    def ndim(self : StridedLayout) -> int:
        """
        The number of dimensions (length of the shape tuple).

        :type: int
        """
        return self.base.ndim

    @property
    def itemsize(self : StridedLayout) -> int:
        """
        The number of bytes per single element (dtype size). Must be a power of two.

        :type: int
        """
        return self.base.itemsize

    @property
    def shape(self : StridedLayout) -> tuple[int]:
        """
        Shape of the tensor.

        :type: tuple[int]
        """
        return self.get_shape_tuple()

    @property
    def strides(self : StridedLayout) -> tuple[int]:
        """
        Strides of the tensor (in **counts**, not bytes).

        :type: tuple[int]
        """
        return self.get_strides_tuple()

    @property
    def strides_in_bytes(self : StridedLayout) -> tuple[int]:
        """
        Strides of the tensor (in bytes).

        :type: tuple[int]
        """
        return self.get_strides_in_bytes_tuple()

    @property
    def stride_order(self : StridedLayout) -> tuple[int]:
        """
        A permutation of ``tuple(range(ndim))`` describing the
        relative order of the strides, such that
        ``strides[stride_order[i]] >= strides[stride_order[i+1]]``.

        Note, for any layout, ``layout.permuted(layout.stride_order).has_stride_order("C")`` is True.

        .. highlight:: python
        .. code-block:: python

            # C-contiguous layout
            assert StridedLayout.dense((5, 3, 7), 1).stride_order == (0, 1, 2)
            # F-contiguous layout
            assert StridedLayout.dense((5, 3, 7), 1, stride_order="F").stride_order == (2, 1, 0)
            # Permuted layout
            assert StridedLayout.dense((5, 3, 7), 1, stride_order=(2, 0, 1)).stride_order == (2, 0, 1)

        :type: tuple[int]
        """
        return self.get_stride_order_tuple()

    def has_stride_order(self : StridedLayout, stride_order: Literal["C", "F"] | tuple[int]) -> bool:
        """
        Checks if the layout has the specified stride order, i.e.
        the absolute values of the strides are (non-strictly) monotonic in the specified order.

        Please note, there's a subtle difference between
        ``layout.stride_order == some_permutation`` and ``layout.has_stride_order(some_permutation)``.
        If the layout has unit extents, its stride is irrelevant and so
        the ``layout.stride_order`` is not unique, so the former may be False,
        while the latter is True.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 7), 1, "C")
            assert layout.has_stride_order("C")
            assert not layout.has_stride_order("F")
            assert layout.has_stride_order((0, 1, 2))
            assert not layout.has_stride_order((2, 1, 0))

            # now, if we slice the layout so that it has unit extents
            # and permute it
            sliced = layout[..., -1:].layout.permuted((0, 2, 1))
            # both (0, 1, 2) and (0, 2, 1) are valid stride orders
            # but stride_order will return only one of them
            assert sliced.stride_order != (0, 1, 2)
            # while has_stride_order will return True for both
            assert sliced.has_stride_order((0, 2, 1))
            assert sliced.has_stride_order((2, 1, 0))
            # and also just "C"
            assert sliced.has_stride_order("C")
        """
        cdef OrderFlag order_flag
        cdef axis_vec_t stride_order_vec
        order_flag = _stride_order2vec(stride_order_vec, stride_order)
        if order_flag == ORDER_NONE:
            raise ValueError(f"The stride_order must be 'C', 'F', or a permutation tuple. Got: {stride_order}")
        return self.get_has_stride_order(order_flag, &stride_order_vec)

    @property
    def volume(self : StridedLayout) -> int:
        """
        The number of elements in the tensor, i.e. the product of the shape tuple.

        :type: int
        """
        return self.get_volume()

    @property
    def is_unique(self : StridedLayout) -> bool:
        """
        If True, each index is mapped to a unique element offset
        in the range ``[min_offset, max_offset]`` (the mapping is injective).

        For a unique layout, :attr:`memory_range_size_in_bytes`
        ``>=`` :attr:`volume` ``*`` :attr:`itemsize`.

        .. hint ::
            Tensors with non-unique layouts can be read from, but it is in
            general unsafe to write to them in parallel (as different indices
            could map to the same memory location).

        All dense layouts are unique and so are layouts that can be created
        by permuting, slicing, flattening, squeezing, packing, unpacking,
        or reshaping a dense layout.
        Conversely, broadcast layouts (layouts with a 0 stride
        for some extent greater than 1) are not unique.

        For some layouts resulting from manual stride manipulations
        (such as with ``numpy.lib.stride_tricks``), the check
        may inaccurately report False, as the exact uniqueness
        check may be expensive.

        .. hint ::
            Layout is abs-dense (``is_abs_dense_any()``) iff
            :attr:`is_unique` and :attr:`is_exhaustive` are True.

        :type: bool
        """
        return self.get_is_unique()

    @property
    def is_exhaustive(self : StridedLayout) -> bool:
        """
        If True, there exists an index for every element offset
        in the range  ``[min_offset, max_offset]``, i.e. the mapping
        from indices to element offsets is onto/surjective.
        A tensor with exhaustive layout doesn't have "gaps" in
        the elements offset range.

        For an exhaustive layout, :attr:`memory_range_size_in_bytes`
        ``<=`` :attr:`volume` ``*`` :attr:`itemsize`.

        .. hint ::
            Allocating memory based on :attr:`volume` and :attr:`itemsize`
            for a tensor with a non-exhaustive layout is
            almost always a bug that can easily lead to out-of-bounds accesses.
            See :attr:`memory_range_size_in_bytes`.

        All contiguous or abs-dense layouts are exhaustive,
        as well as layouts that can be created by broadcasting,
        permuting, flattening, squeezing, packing, unpacking,
        or reshaping a contiguous or abs-dense layout.
        Conversely, slicing a layout can easily introduce gaps in the
        offsets range, making the layout non-exhaustive.

        For some layouts resulting from manual stride manipulations
        (such as with ``numpy.lib.stride_tricks``), the check
        may inaccurately report False, as the exact exhaustiveness
        check may be expensive.

        .. hint ::
            Layout is abs-dense (``is_abs_dense_any()``) iff
            :attr:`is_unique` and :attr:`is_exhaustive` are True.

        :type: bool
        """
        return self.get_is_exhaustive()

    @property
    def is_contiguous_c(self : StridedLayout) -> bool:
        """
        True iff the layout is contiguous in C-order, i.e.
        the rightmost stride is 1 and each subsequent
        stride to the left is the product of the
        extent and the stride to the right.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((2, 5, 3), 1, "C")
            assert layout == StridedLayout((2, 5, 3), (15, 3, 1), 1)
            assert layout.is_contiguous_c

        See also :attr:`is_contiguous_any`.
        See also :meth:`is_dense`.

        :type: bool
        """
        return self.get_is_contiguous_c()

    @property
    def is_contiguous_f(self : StridedLayout) -> bool:
        """
        True iff the layout is contiguous in F-order, i.e.
        the leftmost stride is 1 and each subsequent
        stride to the right is the product of the
        stride and extent to the left.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((2, 5, 3), 1, "F")
            assert layout == StridedLayout((2, 5, 3), (1, 2, 10), 1)
            assert layout.is_contiguous_f

        See also :attr:`is_contiguous_any`.
        See also :meth:`is_dense`.

        :type: bool
        """
        return self.get_is_contiguous_f()

    @property
    def is_contiguous_any(self : StridedLayout) -> bool:
        """
        True iff the layout is contiguous in some axis order, i.e.
        there exists a permutation of axes such that the layout
        is C-contiguous.

        In a contiguous layout:
            * indices are mapped to ``[0, volume - 1]`` element offset range
            * the mapping is bijective (:attr:`is_unique` and :attr:`is_exhaustive` are True)
            * all strides are non-negative
            * iterating over indices in the stride order always gives +1 element offset increment
            * strides can be reconstructed from the shape and stride order only

        .. highlight:: python
        .. code-block:: python

            # dense defaults to C-contiguous
            layout = StridedLayout.dense((5, 3, 7), 1)
            assert layout.is_contiguous_c and not layout.is_contiguous_f
            assert layout.is_contiguous_any

            # reversing the order of axes gives F-contiguous layout
            permuted = layout.permuted((2, 1, 0))
            assert not permuted.is_contiguous_c and permuted.is_contiguous_f
            assert permuted.is_contiguous_any

            # neither C- nor F-order but still contiguous
            permuted = layout.permuted((2, 0, 1))
            assert not permuted.is_contiguous_c and not permuted.is_contiguous_f
            assert permuted.is_contiguous_any

            # slicing the right-most extent creates a gap in the
            # offset_bounds range that is not reachable with any
            # index valid for the sliced layout
            sliced = layout[:, :, :-1].layout
            assert not sliced.is_contiguous_c and not sliced.is_contiguous_f
            assert not sliced.is_contiguous_any

        See also :meth:`is_dense`.

        :type: bool
        """
        return self.get_is_contiguous_any()

    @property
    def is_abs_dense_c(self : StridedLayout) -> bool:
        """
        Like :attr:`is_contiguous_c`, but allows negative strides,
        i.e. the check is performed on the absolute values of the strides.

        Equivalent to ``is_dense(allow_negative_strides=True, stride_order="C")``.

        See also :meth:`is_dense`, :attr:`is_contiguous_c`.

        :type: bool
        """
        return self.get_is_abs_dense_c()

    @property
    def is_abs_dense_f(self : StridedLayout) -> bool:
        """
        Like :attr:`is_contiguous_f`, but allows negative strides,
        i.e. the check is performed on the absolute values of the strides.

        Equivalent to ``is_dense(allow_negative_strides=True, stride_order="F")``.

        See also :meth:`is_dense`, :attr:`is_contiguous_f`.

        :type: bool
        """
        return self.get_is_abs_dense_f()

    @property
    def is_abs_dense_any(self : StridedLayout) -> bool:
        """
        Like :attr:`is_contiguous_any`, but allows negative strides,
        i.e. the check is performed on the absolute values of the strides.

        Equivalent to ``is_dense(allow_negative_strides=True, stride_order="K")``.
        True iff both :attr:`is_unique` and :attr:`is_exhaustive` are True.

        See also :meth:`is_dense`, :attr:`is_contiguous_any`.

        :type: bool
        """
        return self.get_is_abs_dense_any()


    def is_dense(self : StridedLayout, stride_order: Literal["C", "F", "K"] | tuple[int] = "C", allow_negative_strides: bool = False, allow_leading_dim_stride : bool = False) -> bool:
        """
        With the default settings (no negative strides, no padding),
        it is equivalent to :attr:`is_contiguous_any` / :attr:`is_contiguous_c` / :attr:`is_contiguous_f`
        (with stride order "K" / "C" / "F").

        stride_order : str or tuple, optional
            The order of the strides:

            * 'C' - is the layout dense in C-order (from the right to the left)
            * 'F' - is the layout dense in F-order (from the left to the right)
            * 'K' - is there any ``stride_order`` such that layout dense
              (eqiv. is the layout dense in :attr:`stride_order` order)
            * A tuple - it must be a permutation of ``tuple(range(len(shape)))``.
              Is the layout dense in the specified order (e.g. for a 3D layout,
              ``(0, 1, 2)`` is equivalent to C-order and ``(2, 1, 0)`` is equivalent to F-order)

        The default notion of "contiguity" (as in :attr:`is_contiguous_any`, :attr:`is_contiguous_c`,
        :attr:`is_contiguous_f`) is rather strict. It enforces that:

        * the strides can be computed from the shape and stride order only, in particular:

          - the strides are non-negative
          - the leading dimension stride is 1
        * iterating over indices in the stride order always gives +1 element offset increment
        * the mapping from indices to element offsets is bijective, in particular:

          - the element offsets range is ``[0, volume - 1]``
          - the mapping is 1-to-1, i.e. the layout is unique (as in :attr:`is_unique`)
          - the mapping is onto, i.e. the layout is exhaustive (as in :attr:`is_exhaustive`)

        Thanks to the strictness of the definition, layouts reported as C or F have a lot of
        nice properties, and thus should be generally safe to use with other libraries that
        expect contiguous layouts.
        However, there are cases where this notion may be too restrictive.

        allow_negative_strides : bool, optional, default=False
            If True, it computes the contiguity check on the absolute values of the strides.
            As a result, properties 1. (strides as a function of shape) and 2. (+1 increments)
            no longer hold. However, the mapping from indices to element offsets is still bijective,
            only the element offsets range may now be shifted
            (not ``[0, volume - 1]``, but ``[min_offset, max_offset]``,
            such that max_offset - min_offset + 1 == volume).
            This can still be a useful property - for example, if we want to perform elementwise operation
            on tensors with equal strides that are abs-dense, we can just process them as if they
            were flat arrays containing all elements in the range ``[min_offset, max_offset]``

            Note, the is_dense("K", allow_negative_strides=True) is True iff
            both :attr:`is_unique` and :attr:`is_exhaustive` are True.

        allow_leading_dim_stride : bool, optional, default=False
            If True, it allows the leading dimension stride (the stride with smallest abs value)
            to be greater than 1.
            As a result, properties 1. (strides as a function of shape) and 2. (+1 increments)
            no longer hold. However, the mapping from indices to element offsets is still bijective,
            only the element offsets range is now "strided" with the step equal to the leading dimension stride.
            (``[k * ldim_stride for k in range(min_offset // ldim_stride, max_offset // ldim_stride + 1)]``).
            As an example, consider the leading dimension to represent a batch. With this check, we ensure
            that a single sample occupies unique memory offsets and does not introduce any more gaps
            (than the leading dim "step"). If we can combine ``ldim_stride`` consecutive samples,
            we end up with regular contiguous layout.
        """
        cdef axis_vec_t stride_order_vec
        cdef OrderFlag order_flag = _stride_order2vec(stride_order_vec, stride_order)
        if order_flag == ORDER_NONE and stride_order != "K":
            raise ValueError(f"Invalid stride_order: {stride_order}, it must be 'C', 'F', 'K', or a permutation tuple.")

        return self.get_is_dense(order_flag, &stride_order_vec, allow_negative_strides, allow_leading_dim_stride)

    @property
    def has_no_negative_stride(self : StridedLayout) -> bool:
        """
        True iff all relevant (for non-unit extents) strides are positive or zero.

        :type: bool
        """
        return self.get_has_no_negative_stride()

    @property
    def offset_bounds(self : StridedLayout) -> tuple[int, int]:
        """
        The element offsets range ``[min_offset, max_offset]`` (counting elements, not bytes)
        that elements of a tensor with this layout are mapped to.

        If the layout is empty (i.e. ``volume == 0``), the returned tuple is ``(0, -1)``.
        Otherwise, ``min_offset <= max_offset`` and all elements of the tensor with
        this layout are mapped within the ``[min_offset, max_offset]`` range.

        See also :attr:`min_offset`, :attr:`max_offset`, :attr:`memory_range_size_in_bytes`.

        .. highlight:: python
        .. code-block:: python

            # Possible implementation of the offset_bounds
            def offset_bounds(layout : StridedLayout):
                if layout.volume == 0:
                    return 0, -1
                ndim = layout.ndim
                shape = layout.shape
                strides = layout.strides
                idx_min = [shape[i] - 1 if strides[i] < 0 else 0 for i in range(ndim)]
                idx_max = [shape[i] - 1 if strides[i] > 0 else 0 for i in range(ndim)]
                min_offset = sum(strides[i] * idx_min[i] for i in range(ndim))
                max_offset = sum(strides[i] * idx_max[i] for i in range(ndim))
                return min_offset, max_offset

        :type: tuple[int, int]
        """
        cdef stride_t min_offset = 0
        cdef stride_t max_offset = 0
        self.get_offset_bounds(min_offset, max_offset)
        return min_offset, max_offset

    @property
    def _flags(self : StridedLayout) -> dict[str, bool]:
        """
        A dictionary of all boolean properties known (already computed)
        for this layout.
        """
        return get_boolean_flags(self)

    @property
    def min_offset(self : StridedLayout) -> int:
        """
        See :attr:`offset_bounds` for details.

        :type: int
        """
        return self.get_min_offset()

    @property
    def max_offset(self : StridedLayout) -> int:
        """
        See :attr:`offset_bounds` for details.

        :type: int
        """
        return self.get_max_offset()

    @property
    def min_stride(self : StridedLayout) -> int:
        """
        Returns stride that is:
        * the smallest wrt to **absolute value**, i.e. from -1, 2, -3, the minimal is -1.
        * only non-unit extents are considered.

        If the squeezed layout is empty (volume == 0) or effectively a scalar (volume == 1),
        the returned stride is 1.

        Please note, min(strides) may be a wrong choice for getting
        stride of a leading dimension:

        * if all strides are negative, min(strides) is actually the one
          causing largest jump in memory.
        * unit extents can introduce some misleading strides (e.g. it could be 0)

        .. highlight:: python
        .. code-block:: python

            operand_layout = StridedLayout.dense((5, 4, 3, 2), 4)
            assert operand_layout.strides == (24, 6, 2, 1)
            batch_layout = operand_layout.sub(0, 1)
            assert batch_layout.strides == (24, 6)
            assert batch_layout.min_stride == 6 == min(batch_layout.strides)
            assert batch_layout.max_stride == 24 == max(batch_layout.strides)

            operand_layout = operand_layout[::-1, ::-1, ::-1, ::-1].layout
            assert operand_layout.strides == (-24, -6, -2, -1)
            batch_layout = operand_layout.sub(0, 1)
            assert batch_layout.strides == (-24, -6)
            assert batch_layout.min_stride == -6 != min(batch_layout.strides)
            assert batch_layout.max_stride == -24 != max(batch_layout.strides)

        """
        return self.get_min_stride()

    @property
    def max_stride(self : StridedLayout) -> int:
        """
        Returns stride that is:
        * the largest wrt to **absolute value**, i.e. from -1, 2, -3, the maximal is -3.
        * only non-unit extents are considered.

        Unit extents are ignored.
        If the squeezed layout is empty (volume == 0) or effectively a scalar (volume == 1),
        the returned stride is 1.
        """
        return self.get_max_stride()

    @property
    def memory_range_size(self : StridedLayout) -> int:
        """
        Size of the memory range ``[min_offset, max_offset]`` (counting elements, not bytes).
        Returns ``max_offset - min_offset + 1``.

        See also :attr:`min_offset`, :attr:`max_offset`, :attr:`memory_range_size_in_bytes`.
        """
        return self.get_memory_range_size()

    @property
    def memory_range_size_in_bytes(self : StridedLayout) -> int:
        """
        Size of the memory range ``[min_offset, max_offset]`` (in bytes).
        Returns ``(max_offset - min_offset + 1) * itemsize``.

        See also :attr:`min_offset`, :attr:`max_offset`, :attr:`memory_range_size`.

        .. hint::
            For contiguous layouts (:attr:`is_contiguous_any`),
            the memory range size is equal to the ``volume * itemsize``, i.e.
            ``(max_offset - min_offset + 1) = volume``.

        .. warning::
            Beware of the dragons when allocating memory for arbitrary layout.
            It is strongly recommended to call :meth:`to_dense` method first, to
            ensure the layout is contiguous (if it already is, it is a no-op).
            Otherwise, things can go awry:

            * The required memory range may be way larger than ``volume * itemsize``
                if the layout is not exhaustive, causing overallocation.
            * The required memory range may be smaller than ``volume * itemsize``
                if the layout is not unique, resulting in a tensor where setting
                elements at different indices results in a race when writing to the
                same memory location.
            * The min_offset may be negative, meaning that the base pointer of the
                allocated memory should be first adjusted by ``-min_offset * itemsize`` bytes.
        """
        return self.get_memory_range_size_in_bytes()

    def flattened_axis_mask(self : StridedLayout) -> axes_mask_t:
        """
        A mask describing which axes of this layout are mergeable
        using the :meth:`flattened` method.
        """
        return self.get_flattened_axis_mask()

    def unit_extents_mask(self : StridedLayout) -> axes_mask_t:
        """
        A mask of axes that have extent equal to 1.
        I.e. ``layout.unit_extents & (1 << axis) iff layout.shape[axis] == 1``,
        in particular ``layout.unit_extents == 0`` iff there are no unit extents.

        :type: axes_mask_t
        """
        return self.get_unit_extents_mask()

    def to_dense(self : StridedLayout, object stride_order="K") -> StridedLayout:
        """
        Returns a contiguous layout with the same shape and itemsize,
        but with contiguous strides in the specified order.

        .. note::
            The returned layout is guaranteed to be contiguous, i.e. :attr:`is_contiguous_any` is True.
            Layout can be dense in a less strict sense (e.g. having negative strides but still bijective),
            such layouts are still converted to meet the strict definition of contiguous layout.

        See :meth:`dense_like` method documentation for details.

        See also :meth:`is_contiguous_any`.
        See also :meth:`is_dense`.
        """
        return StridedLayout.dense_like(self, stride_order)

    def reshaped(self : StridedLayout, shape : tuple[int] | StridedLayout | int) -> StridedLayout:
        """
        Returns a layout with the new shape, if the new shape is compatible
        with the current layout.

        The new shape is compatible if:
            * the new and old shapes have the same volume
            * the old strides can be split or flattened to match the new shape,
              assuming indices are iterated in C-order

        A single extent in the ``shape`` tuple can be set to -1 to indicate
        it should be inferred from the old volume and the other extents.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 4), 1)
            assert layout.reshaped((20, 3)) == StridedLayout.dense((20, 3), 1)
            assert layout.reshaped((4, -1)) == StridedLayout.dense((4, 15), 1)
            assert layout.permuted((2, 0, 1)).reshaped((4, 15,)) == StridedLayout((4, 15), (1, 4), 1)
            # layout.permuted((2, 0, 1)).reshaped((20, 3)) -> error
        """
        if type(shape) is StridedLayout:
            return self.get_reshaped((<StridedLayout>shape).base)
        cdef BaseLayout new_shape
        # can't use init_base_layout_from_tuple because it validates
        # the extents are non-negative, and we allow -1
        shape = as_tuple(shape)
        cdef int new_ndim = len(shape)
        init_base_layout(new_shape, new_ndim, self.base.itemsize)
        for i in range(new_ndim):
            new_shape.shape[i] = shape[i]
        return self.get_reshaped(new_shape)

    def permuted(self : StridedLayout, axis_order : tuple[int], inverse : bool = False) -> StridedLayout:
        """
        Returns a layout where the shape and strides tuples are permuted
        according to the specified permutation of axes.
        If inverse is set to True, the output layout is permuted by the inverse
        permutation (or, equivalently, permuting the output layout by the specified
        permutation gives the input layout).

        .. highlight:: python
        .. code-block:: python

            shape = (3, 4, 5)
            layout = StridedLayout.dense(shape, 1)
            perm = (1, 2, 0)
            inv_perm = (2, 0, 1)

            layout_perm = layout.permuted(perm)
            assert layout_perm.shape == tuple(shape[p] for p in perm)

            layout_inv_perm = layout.permuted(perm, inverse=True)
            assert tuple(layout_inv_perm.shape[p] for p in perm) == shape
            assert layout_inv_perm.shape == tuple(shape[p] for p in inv_perm)
            assert layout_inv_perm == layout.permuted(inv_perm)

            assert layout.permuted(perm).permuted(perm, inverse=True) == layout

        """
        cdef axis_vec_t axis_order_vec
        _tuple2axis_vec(axis_order_vec, axis_order)
        return self.get_permuted(axis_order_vec, inverse)

    def reversed(self : StridedLayout) -> StridedLayout:
        """
        Returns ``StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)``.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 4), 1)
            assert layout == StridedLayout((5, 3, 4), (12, 4, 1), 1)
            assert layout.reversed() == StridedLayout((4, 3, 5), (1, 4, 12), 1)
            assert layout.reversed() == StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)

        """
        return self.get_reversed()

    def transposed(self : StridedLayout, axis_a : int, axis_b : int) -> StridedLayout:
        """
        Returns a layout where the two specified axes are swapped.
        """
        return self.get_transposed(axis_a, axis_b)

    def flattened(self : StridedLayout, start_axis : int = 0, end_axis : int = -1, mask : int | None = None) -> StridedLayout:
        """
        Returns a layout where consecutive extents, if possible,
        are merged into a single extent (equal to the product of merged extents).
        Extents are mergeable if the corresponding sub-layout is c-leading-dense,
        i.e. the corresponding strides can be replaced with a single
        (the rightmost, and the smallest) stride.
        Iterating over the indices of the the original and the flattened layout
        in C-order (the rightmost axis incremented first) is equivalent.

        Note, flattening a scalar turns the layout into 1D array.

        .. highlight:: python
        .. code-block:: python

            # the two extents can be merged into a single extent
            # because layout.strides[0] == layout.strides[1] * layout.shape[1]
            layout = StridedLayout((3, 2), (2, 1), 1)
            assert layout.flattened() == StridedLayout((6,), (1,), 1)

            # the two extents cannot be merged into a single extent
            # because layout.strides[0] != layout.strides[1] * layout.shape[1]
            layout = StridedLayout((3, 2), (1, 3), 1)
            assert layout.flattened() == layout

        If ``start_axis`` and ``end_axis`` are provided, only the axes in the
        inclusive range ``[start_axis, end_axis]`` are considered for flattening.

        Alternatively, a mask specifying which axes to consider can be provided.
        A mask of mergeable extents can be obtained using the :meth:`flattened_axis_mask` method.
        Masks for layouts with the same number of dimensions can be combined
        using the logical ``&`` (bitwise AND) operator.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((4, 5, 3), 4)
            layout2 = StridedLayout((4, 5, 3), (1, 12, 4), 4)
            # Even though the two layouts have the same shape initially,
            # their shapes differ after flattening.
            assert layout.flattened() == StridedLayout((60,), (1,), 4)
            assert layout2.flattened() == StridedLayout((4, 15), (1, 4), 4)
            # With the mask, only extents that are mergeable in both layouts are flattened
            # and the resulting shape is the same for both layouts.
            mask = layout.flattened_axis_mask() & layout2.flattened_axis_mask()
            assert layout.flattened(mask=mask) == StridedLayout((4, 15), (15, 1), 4)
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)
        """
        cdef axes_mask_t axis_mask
        if mask is None:
            axis_mask = flattening_axes_mask_from_range(self.ndim, start_axis, end_axis)
        else:
            axis_mask = mask
        return self.get_flattened(axis_mask)

    def extended(self : StridedLayout, other : StridedLayout, axis : int=-1) -> StridedLayout:
        """
        Returns a layout as if the ``other`` layout was inserted before the
        specified ``axis`` into the current layout. The valid range of ``axis`` is
        (inclusive) range ``[0, self.ndim]``.
        """
        return self.get_concat(other, axis)

    def sub(self : StridedLayout, start_axis : int = 0, end_axis : int = -1, axes : tuple[int] | None = None) -> StridedLayout:
        """
        Returns a sub-layout consisting of the specified axes.

        The axes to copy can be specified by:
            * The ``axes`` tuple of integers in range ``[0, ndim]``.
              The order of ``axes`` in the tuple determines the order of axes in the sub-layout.
            * If the ``axes`` tuple is not provided, the inclusive range ``[start_axis, end_axis]``
              is copied.

        """

        if axes is None:
            return self.get_sub(start_axis, end_axis)

        cdef axis_vec_t axis_vec
        _tuple2axis_vec(axis_vec, axes)
        return self.get_sub(0, -1, &axis_vec)

    def squeezed(self : StridedLayout, axis : int | tuple[int] | None = None, mask : int | None = None) -> StridedLayout:
        """
        Returns a layout where all the unit dimensions (extents equal to 1)
        are removed.

        To limit which axes are considered for squeezing, either the ``axis`` parameter
        or the ``mask`` parameter can be used.

        * If ``axis`` is provided, it must be an integer or a tuple of unique integers
          in range ``[0, ndim)``, only those axes are considered for squeezing.
        * Otherwise, if ``mask`` is provided, only the axes specified by the mask are considered
          (shape[axis] is removed iff ``shape[axis] == 1 and (mask & (1 << axis))``).
        """
        cdef axes_mask_t axis_mask
        if axis is not None:
            axis_mask = _tuple2axis_mask(self.ndim, axis)
        elif mask is not None:
            axis_mask = mask
        else:
            axis_mask = axes_mask_from_range(self.ndim, 0, -1)
        return self.get_squeezed(axis_mask)

    def squeezed_range(self : StridedLayout, start_axis : int = 0, end_axis : int = -1) -> StridedLayout:
        """
        Returns a layout where all the unit dimensions (extents equal to 1)
        in inclusive range ``[start_axis, end_axis]`` are removed.
        """
        return self.get_squeezed(axes_mask_from_range(self.ndim, start_axis, end_axis))

    def unsqueezed(self : StridedLayout, axis : int | tuple[int] | None = None, mask : int = 0) -> StridedLayout:
        """
        Returns a layout where the specified axis or axes are added as unit extents.
        The ``axis`` can be either a single integer in range ``[0, ndim]``
        or a tuple of unique integers in range ``[0, ndim + len(axis) - 1]``.
        Alternatively, the axes can be specified as a mask with bits set
        for the axes to be added.

        Note, squeezing and unsqueezing a layout can be used as a way to normalize
        the strides of unit dimensions.

        .. highlight:: python
        .. code-block:: python

            # The three layouts are equvialent, they have the same shape and
            # differ only in the strides of unit dimensions.
            l1 = StridedLayout.dense((5, 4, 3), 1)[-1:, :,  :1].layout
            l2 = StridedLayout.dense((5, 4, 3), 1)[::5, :, ::3].layout
            l3 = StridedLayout.dense((5, 4, 3), 1)[::-1, :, ::-1][-1:, :, :1].layout

            assert l1.shape == l2.shape == l3.shape == (1, 4, 1)
            assert l1.strides == (12, 3, 1)
            assert l2.strides == (60, 3, 3)
            assert l3.strides == (-12, 3, -1)

            l1 = l1.squeezed().unsqueezed(mask=l1.unit_extents_mask())
            l2 = l2.squeezed().unsqueezed(mask=l2.unit_extents_mask())
            l3 = l3.squeezed().unsqueezed(mask=l3.unit_extents_mask())

            assert l1.shape == l2.shape == l3.shape == (1, 4, 1)
            assert l1.strides == l2.strides == l3.strides == (12, 3, 3)

        """
        cdef axes_mask_t axis_mask
        cdef int num_new_axes
        if axis is not None:
            if isinstance(axis, int):
                num_new_axes = 1
            else:
                num_new_axes = len(axis)
            axis_mask = _tuple2axis_mask(self.ndim + num_new_axes, axis)
        else:
            axis_mask = mask
        return self.get_unsqueezed(axis_mask)

    def unsqueezed_to_ndim(self : StridedLayout, ndim: int, axis: int = 0) -> StridedLayout:
        """
        Returns a layout with the specified number of dimensions, by adding unit extents
        starting from the specified axis.

        The valid range of ``axis`` is (inclusive) range ``[0, ndim]``.
        """
        return self.unsqueezed(mask=unsqueeze_to_ndim_mask(self.ndim, ndim, axis))

    def broadcast_to(self : StridedLayout, shape : int | tuple[int] | list[int] | StridedLayout) -> StridedLayout:
        """
        Returns a layout with the new shape, if the old shape can be
        broadcast to the new one.

        The shapes are compatible if:
            * the new shape has the same or greater number of dimensions
            * starting from the right, each extent in the old shape must be 1 or
              equal to the corresponding extent in the new shape.

        Strides of the added or modified extents are set to 0, the remaining ones are unchanged.
        If the shapes are not compatible, a ValueError is raised.

        Parameters
        ----------
        shape : int | tuple[int] | list[int] | StridedLayout
            The new shape to broadcast to. If a :class:`StridedLayout` is passed,
            the shape is taken from the provided layout.

        Returns
        -------
        StridedLayout
            The broadcasted layout.
        """
        if type(shape) is StridedLayout:
            return self.get_broadcast((<StridedLayout>shape).base)
        cdef BaseLayout broadcast
        init_base_layout_from_tuple(broadcast, self.base.itemsize, as_tuple(shape), None)
        return self.get_broadcast(broadcast)

    def unbroadcast(self : StridedLayout) -> StridedLayout:
        """
        Returns a layout where extents with stride 0 are replaced
        with unit extents (extent = 1, stride = 0).
        """
        return self.get_unbroadcast()

    def packed(self : StridedLayout, itemsize : int, data_ptr : intptr_t = 0, axis : int = -1, keep_dim : bool = True) -> StridedLayout:
        """
        Converts the layout to the specified itemsize.
        The new itemsize must be greater or equal to the old itemsize.
        Consecutive ``new_itemsize // old_itemsize`` elements in the ``axis`` dimension
        are **packed** into a single element, i.e. the extent at ``axis`` is divided by
        ``new_itemsize // old_itemsize``.
        In particular, the volume of the new layout decreases, but
        the ``volume * itemsize`` remains the same.

        The conversion is subject to the following constraints:
            * The old and new itemsizes must be powers of two.
            * The ``shape[axis]`` must be a positive integer divisible
              by ``new_itemsize // old_itemsize``.
            * The ``strides[axis]`` must be 1.
            * All other ``strides`` must be divisible by ``new_itemsize // old_itemsize``.
            * If ``data_ptr`` is provided, it must be aligned to (divisible by) the new itemsize.

        A maximum itemsize that satisfies all the above constraints
        can be obtained using the :meth:`max_compatible_itemsize` method.

        If the ``keep_dim`` is False and the extent at ``axis`` would be reduced to 1,
        it is omitted from the returned layout.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 4), 4)
            assert layout.packed(4) is layout
            assert layout.packed(8) == StridedLayout.dense((5, 2), 8)
            assert layout.packed(16) == StridedLayout.dense((5, 1), 16)
            assert layout.packed(16, keep_dim=False) == StridedLayout.dense((5,), 16)


        .. highlight:: python
        .. code-block:: python

            # Viewing (5, 6) float array as (5, 3) complex64 array.
            a_real = numpy.arange(30, dtype=numpy.float32).reshape((5, 6))
            a_complex = a_real.view(numpy.complex64)

            real_layout = StridedLayout(a_real.shape, a_real.strides, a_real.itemsize, divide_strides=True)
            assert real_layout.shape == a_real.shape == (5, 6)
            assert real_layout.strides_in_bytes == a_real.strides
            assert real_layout.itemsize == a_real.itemsize == 4
            complex_layout = real_layout.packed(8)
            assert complex_layout.shape == a_complex.shape == (5, 3)
            assert complex_layout.strides_in_bytes == a_complex.strides
            assert complex_layout.itemsize == 8
        """
        return self.get_packed(itemsize, data_ptr, axis, keep_dim)

    def unpacked(self : StridedLayout, itemsize : int, axis : int = -1, add_dim : bool = False) -> StridedLayout:
        """
        Converts the layout to match the specified itemsize.
        The new itemsize must be less than or equal to the old itemsize.
        Every element in the tensor is **unpacked** into ``old_itemsize // new_itemsize`` elements,
        along the ``axis`` dimension.
        In particular, the volume of the new layout increases, but
        the ``volume * itemsize`` remains the same.

        If the ``add_dim`` is False, the extent at ``axis`` is multiplied by ``old_itemsize // new_itemsize``.
        Otherwise a new dimension of size ``old_itemsize // new_itemsize`` (and stride 1) is added
        before the ``axis`` dimension.

        The conversion is subject to the following constraints:
            * The old and new itemsizes must be powers of two.
        If ``add_dim`` is False:
            * The extent at ``axis`` must be a positive integer.
            * The stride at ``axis`` must be 1.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 4), 4)
            assert layout.unpacked(4) is layout
            assert layout.unpacked(2) == StridedLayout.dense((5, 8), 2)
            assert layout.unpacked(2, add_dim=True) == StridedLayout.dense((5, 4, 2), 2)
            assert layout.unpacked(1) == StridedLayout.dense((5, 16), 1)
            assert layout.unpacked(1, add_dim=True) == StridedLayout.dense((5, 4, 4), 1)


        .. highlight:: python
        .. code-block:: python

            # Prepare 5x3 complex64 (itemsize = 8) array
            ac = numpy.zeros((5, 3), dtype=numpy.complex64)
            ac.real += numpy.arange(15, dtype=numpy.float32).reshape((5, 3))
            ac.imag -= numpy.arange(15, dtype=numpy.float32).reshape((5, 3))
            complex_l = StridedLayout(ac.shape, ac.strides, ac.itemsize, divide_strides=True)

            # unpack into 5x6 float32 (itemsize = 4) array
            real_l = complex_l.unpacked(4)
            assert real_l == StridedLayout((5, 6), (6, 1), 4)
            ar = ac.view(numpy.float32)
            assert real_l.shape == ar.shape == (5, 6)
            assert real_l.strides_in_bytes == ar.strides
            assert real_l.itemsize == ar.itemsize == 4

            # unpack into batch of two float32 5x3 matrices
            real_l_batch = complex_l.unpacked(4, axis=0, add_dim=True)
            assert real_l_batch == StridedLayout((2, 5, 3), (1, 6, 2), 4)
            ar_batch = numpy.lib.stride_tricks.as_strided(
                ar,
                shape=real_l_batch.shape,
                strides=real_l_batch.strides_in_bytes
            )
            numpy.testing.assert_array_equal(ar_batch[0], ac.real)
            numpy.testing.assert_array_equal(ar_batch[1], ac.imag)

        """
        return self.get_unpacked(itemsize, axis, add_dim)

    def max_compatible_itemsize(self : StridedLayout, max_itemsize : int = 16, data_ptr : intptr_t = 0, axis : int = -1) -> int:
        """
        Returns the maximum itemsize (but no greater than ``max_itemsize``) that can be used
        with the :meth:`packed` method for the current layout.
        """
        return self.get_max_compatible_itemsize(max_itemsize, data_ptr, axis)

    def __getitem__(self : StridedLayout, slices : int | slice | tuple[int | slice]) -> SlicedLayout:
        # It slightly repeats the logic of SlicedLayout.sliced,
        # we could first create a SlicedLayout from the StridedLayout
        # and then call the SlicedLayout.sliced method,
        # but this would add extra overhead of creating a temp
        # SlicedLayout instance.
        if type(slices) is not tuple:
            slices = (slices,)
        cdef SlicedLayout sliced_layout = SlicedLayout.__new__(SlicedLayout)
        cdef BaseLayout sliced
        cdef stride_t slice_offset = 0
        if base_layout_slice(sliced, slice_offset, self.base, slices):
            sliced_layout.init_from_base(sliced, slice_offset, self)
        else:
            sliced_layout.init_from_base(sliced, slice_offset)
        return sliced_layout

    def __len__(self : StridedLayout) -> int:
        return self.get_len()

    cdef axes_mask_t get_flattened_axis_mask(StridedLayout self) except? -1 nogil:
        cdef axes_mask_t out_mask = 0
        cdef axes_mask_t all_mask = flattening_axes_mask_from_range(self.base.ndim, 0, -1)
        base_layout_flatten_in_c_order(out_mask, self.base, self.get_volume(), all_mask)
        return out_mask

    cdef int get_max_compatible_itemsize(StridedLayout self, int max_itemsize, intptr_t data_ptr, int axis=-1) except -1 nogil:
        return max_compatible_itemsize(self.base, max_itemsize, data_ptr, axis)

    cdef StridedLayout get_sliced(StridedLayout self, stride_t &slice_offset, object slices):
        if type(slices) is not tuple:
            slices = (slices,)
        cdef BaseLayout sliced
        if base_layout_slice(sliced, slice_offset, self.base, slices):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(sliced)
        return new_layout

    cdef StridedLayout get_concat(StridedLayout self, StridedLayout other, axis_t axis=-1):
        if self.base.ndim == 0:
            base_layout_concat_validate(self.base, other.base, axis)
            return other
        elif other.ndim == 0:
            base_layout_concat_validate(self.base, other.base, axis)
            return self

        cdef BaseLayout cat
        base_layout_concat(cat, self.base, other.base, axis)

        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(cat)
        return new_layout

    cdef int concat_into(StridedLayout self, StridedLayout out_layout, const BaseLayout& other, axis_t axis=-1) except -1 nogil:
        if out_layout is self and other.ndim == 0:
            base_layout_concat_validate(self.base, other, axis)
            return 0

        cdef BaseLayout cat
        base_layout_concat(cat, self.base, other, axis)

        out_layout.reset_base(cat)
        return 0

    cdef StridedLayout get_sub(StridedLayout self, axis_t start_axis=0, axis_t end_axis=-1, axis_vec_t* axes=NULL):
        cdef BaseLayout sub
        if base_layout_sub(sub, self.base, start_axis, end_axis, axes):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(sub)
        return new_layout

    cdef int sub_into(StridedLayout self, StridedLayout out_layout, axis_t start_axis=0, axis_t end_axis=-1, axis_vec_t* axes=NULL) except -1 nogil:
        cdef BaseLayout sub
        if base_layout_sub(sub, self.base, start_axis, end_axis, axes) and out_layout is self:
            return 0
        out_layout.reset_base(sub)
        return 0

    cdef StridedLayout get_reshaped(StridedLayout self, BaseLayout& like):
        cdef BaseLayout reshaped
        base_layout_reshape(reshaped, self.get_volume(), self.base, like)
        if base_layout_equal(reshaped, self.base):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(reshaped)
        return new_layout

    cdef int reshape_into(StridedLayout self, StridedLayout out_layout, BaseLayout& like) except -1 nogil:
        cdef BaseLayout reshaped
        base_layout_reshape(reshaped, self.get_volume(), self.base, like)
        if out_layout is self and base_layout_equal(reshaped, self.base):
            return 0
        out_layout.reset_base(reshaped)
        return 0

    cdef StridedLayout get_permuted(StridedLayout self, axis_vec_t& axis_order, bint inverse=False):
        cdef BaseLayout permuted
        if base_layout_permute(permuted, self.base, ORDER_PERM, &axis_order, inverse):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(permuted)
        return new_layout

    cdef int permute_into(StridedLayout self, StridedLayout out_layout, axis_vec_t& axis_order, bint inverse=False) except -1 nogil:
        cdef BaseLayout permuted
        if base_layout_permute(permuted, self.base, ORDER_PERM, &axis_order, inverse) and out_layout is self:
            return 0
        out_layout.reset_base(permuted)
        return 0

    cdef StridedLayout get_reversed(StridedLayout self):
        cdef BaseLayout rev
        if base_layout_permute(rev, self.base, ORDER_F, NULL, False):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(rev)
        return new_layout

    cdef int reverse_into(StridedLayout self, StridedLayout out_layout) except -1 nogil:
        cdef BaseLayout rev
        if base_layout_permute(rev, self.base, ORDER_F, NULL, False) and out_layout is self:
            return 0
        out_layout.reset_base(rev)
        return 0

    cdef StridedLayout get_transposed(StridedLayout self, axis_t axis_a, axis_t axis_b):
        if axis_a == axis_b:
            base_layout_transpose_validate(self.base, axis_a, axis_b)
            return self

        cdef BaseLayout transposed
        base_layout_transpose(transposed, self.base, axis_a, axis_b)
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(transposed)
        return new_layout

    cdef int transpose_into(StridedLayout self, StridedLayout out_layout, axis_t axis_a, axis_t axis_b) except -1 nogil:
        if axis_a == axis_b and out_layout is self:
            base_layout_transpose_validate(self.base, axis_a, axis_b)
            return 0

        cdef BaseLayout transposed
        base_layout_transpose(transposed, self.base, axis_a, axis_b)
        out_layout.reset_base(transposed)
        return 0

    cdef StridedLayout get_flattened(StridedLayout self, axes_mask_t axis_mask):
        if axis_mask == 0 and self.base.ndim != 0:
            return self

        cdef BaseLayout flattened
        cdef int ndim = base_layout_flatten_in_c_order(flattened, self.base, self.get_volume(), axis_mask)
        if ndim == self.base.ndim:
            return self

        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(flattened)
        return new_layout

    cdef int flatten_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask) except -1 nogil:
        if out_layout is self and axis_mask == 0 and self.base.ndim != 0:
            return 0

        cdef BaseLayout flattened
        cdef int ndim = base_layout_flatten_in_c_order(flattened, self.base, self.get_volume(), axis_mask)

        if out_layout is self and ndim == self.base.ndim:
            return 0

        out_layout.reset_base(flattened)
        return 0

    cdef StridedLayout get_squeezed(StridedLayout self, axes_mask_t axis_mask=STRIDED_LAYOUT_AXES_MASK_ALL):
        cdef BaseLayout squeezed
        cdef int out_ndim = base_layout_squeeze(squeezed, self.base, axis_mask)
        if out_ndim == self.base.ndim:
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(squeezed)
        return new_layout

    cdef int squeeze_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask=STRIDED_LAYOUT_AXES_MASK_ALL) except -1 nogil:
        cdef BaseLayout squeezed
        cdef int out_ndim = base_layout_squeeze(squeezed, self.base, axis_mask)
        if self is out_layout and out_ndim == self.base.ndim:
            return 0
        out_layout.reset_base(squeezed)
        return 0

    cdef StridedLayout get_unsqueezed(StridedLayout self, axes_mask_t axis_mask):
        if not axis_mask:
            return self

        cdef BaseLayout unsqueezed
        base_layout_unsqueeze(unsqueezed, self.base, axis_mask)
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(unsqueezed)
        return new_layout

    cdef int unsqueeze_into(StridedLayout self, StridedLayout out_layout, axes_mask_t axis_mask) except -1 nogil:
        if not axis_mask and self is out_layout:
            return 0

        cdef BaseLayout unsqueezed
        base_layout_unsqueeze(unsqueezed, self.base, axis_mask)
        out_layout.reset_base(unsqueezed)
        return 0

    cdef StridedLayout get_broadcast(StridedLayout self, BaseLayout& like):
        cdef BaseLayout broadcast
        if base_layout_broadcast(broadcast, self.base, like):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(broadcast)
        return new_layout

    cdef int broadcast_into(StridedLayout self, StridedLayout out_layout, BaseLayout& like) except -1 nogil:
        cdef BaseLayout broadcast
        if base_layout_broadcast(broadcast, self.base, like) and out_layout is self:
            return 0
        out_layout.reset_base(broadcast)
        return 0

    cdef StridedLayout get_unbroadcast(StridedLayout self):
        cdef BaseLayout unbroadcast
        if base_layout_unbroadcast(unbroadcast, self.base):
            return self
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(unbroadcast)
        return new_layout

    cdef int unbroadcast_into(StridedLayout self, StridedLayout out_layout) except -1 nogil:
        cdef BaseLayout unbroadcast
        if base_layout_unbroadcast(unbroadcast, self.base) and out_layout is self:
            return 0
        out_layout.reset_base(unbroadcast)
        return 0

    cdef StridedLayout get_packed(StridedLayout self, int itemsize, intptr_t data_ptr, int axis=-1, bint keep_dim=True):
        if itemsize == self.base.itemsize:
            return self

        cdef BaseLayout packed
        base_layout_pack(packed, self.base, itemsize, data_ptr, axis, keep_dim)
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(packed)
        return new_layout

    cdef int pack_into(StridedLayout self, StridedLayout out_layout, int itemsize, intptr_t data_ptr, int axis=-1, bint keep_dim=True) except -1 nogil:
        if out_layout is self and itemsize == self.base.itemsize:
            return 0

        cdef BaseLayout packed
        cdef int vec_size = base_layout_pack(packed, self.base, itemsize, data_ptr, axis, keep_dim)
        out_layout.reset_base(packed)
        return vec_size

    cdef StridedLayout get_unpacked(StridedLayout self, int itemsize, int axis=-1, bint add_dim=False):
        if itemsize == self.base.itemsize:
            return self

        cdef BaseLayout unpacked
        base_layout_unpack(unpacked, self.base, itemsize, axis, add_dim)
        cdef StridedLayout new_layout = StridedLayout.__new__(StridedLayout)
        new_layout.reset_base(unpacked)
        return new_layout

    cdef int unpack_into(StridedLayout self, StridedLayout out_layout, int itemsize, int axis=-1, bint add_dim=False) except -1 nogil:
        if out_layout is self and itemsize == self.base.itemsize:
            return 0

        cdef BaseLayout unpacked
        cdef int vec_size = base_layout_unpack(unpacked, self.base, itemsize, axis, add_dim)
        out_layout.reset_base(unpacked)
        return vec_size


cdef class SlicedLayout:
    """
    Result of slicing a :py:class:`StridedLayout`.
    Logically, :class:`SlicedLayout` instance is a :class:`StridedLayout` instance +
    :attr:`slice_offset`, i.e. an offset of the element at index ``(0,) * ndim``.

    Using algebraic analogy:

    * :class:`StridedLayout` defines a *linear mapping* from indices to element offsets
    * :class:`SlicedLayout` adds an extra constant term, making the mapping *affine*.

    Some properties that are clear for linear case, become ambiguous or break
    with the non-zero :attr:`slice_offset`. For example:

    * Is the layout contiguous/dense/exhaustive if it has a non-zero :attr:`slice_offset`?
    * Should :attr:`~StridedLayout.min_offset` or :attr:`~StridedLayout.max_offset`
      take into account the :attr:`slice_offset`?

    The answers depend on the use case (and whether the :attr:`slice_offset` is accounted for
    in the data pointer). For this reason, :class:`StridedLayout` and :class:`SlicedLayout` are separate classes,
    and :class:`StridedLayout` is unaware of the :attr:`slice_offset`. It is up to the user to
    make sure the data pointer is adjusted to account for the :attr:`slice_offset`.
    """

    def __init__(self : SlicedLayout):
        raise TypeError(
            "Do not create SlicedLayout instances directly. "
            "Slice a StridedLayout instance (``layout[...]``) instead."
        )

    @property
    def layout(self : SlicedLayout) -> StridedLayout:
        return self.get_layout()

    @property
    def slice_offset_in_bytes(self : SlicedLayout) -> int:
        """
        The memory offset (as a number of bytes) of the element at index ``(0,) * ndim``.
        Equal to :attr:`layout.itemsize` ``*`` :attr:`slice_offset`.
        """
        return self.get_slice_offset_in_bytes()

    def __repr__(self : SlicedLayout) -> str:
        return (
            f"SlicedLayout(layout={self.get_layout()}, slice_offset={self.slice_offset})"
        )

    def __eq__(self : SlicedLayout, other : SlicedLayout) -> bool:
        return self.slice_offset == other.slice_offset and base_layout_equal(self.base, other.base)

    def __getitem__(self : SlicedLayout, slices : int | slice | tuple[int | slice]) -> SlicedLayout:
        return self.get_sliced(slices)

    cdef StridedLayout get_layout(SlicedLayout self):
        if self._layout is not None:
            return self._layout
        cdef StridedLayout layout = StridedLayout.__new__(StridedLayout)
        layout.init_from_ptr(self.base.ndim, self.base.itemsize, self.base.shape, self.base.strides)
        self._layout = layout
        return layout

    cdef SlicedLayout get_sliced(SlicedLayout self, object slices):
        if type(slices) is not tuple:
            slices = (slices,)
        cdef BaseLayout sliced
        cdef stride_t slice_offset = 0
        if base_layout_slice(sliced, slice_offset, self.base, slices):
            return self
        cdef SlicedLayout sliced_layout = SlicedLayout.__new__(SlicedLayout)
        sliced_layout.init_from_base(sliced, _overflow_checked_sum(self.slice_offset, slice_offset))
        return sliced_layout


ctypedef fused FlattenOutputType:
    BaseLayout
    axes_mask_t


cdef inline int base_layout_flatten_in_c_order(FlattenOutputType& out_layout, BaseLayout& in_layout, int64_t volume, axes_mask_t axis_mask) except -1 nogil:
    cdef int ndim = in_layout.ndim
    cdef int itemsize = in_layout.itemsize
    if FlattenOutputType is axes_mask_t:
        out_layout = 0
    else:
        assert FlattenOutputType is BaseLayout
        if ndim == 0:
            init_base_layout(out_layout, 1, itemsize)
            out_layout.shape[0] = 1
            out_layout.strides[0] = 1
            return 1
        init_base_layout(out_layout, ndim, itemsize)
    cdef int group_start = 0
    cdef int group_end = 0
    cdef int64_t group_vol
    cdef int64_t group_stride
    cdef int out_i = 0
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef extent_t extent
    cdef stride_t stride
    # each iteration merges [group_start, group_end) extents
    # inv: group_start extent cannot be merged with its left neighbor
    while group_start < ndim:
        # initialize group consisting of a single extent
        group_vol = in_shape[group_start]
        if volume == 0:
            # set all strides to 0 if volume is 0, just compute volumes
            # of the groups according to the axis_mask
            group_stride = 0
        elif group_vol == 1:
            # as long as group_vol is 1 (meaning there are only unit extents
            # in the group) we don't use the strides from the group
            group_stride = 1
        else:
            group_stride = in_strides[group_start]
        group_end = group_start + 1
        while group_end < ndim and (axis_mask & _axis2mask(group_end)):
            extent = in_shape[group_end]
            stride = in_strides[group_end]
            if volume != 0 and extent != 1:
                # only compare group_stride with stride if both correspond
                # to non-unit extents (we checked extent != 1 above, and group_vol != 1 here)
                if group_vol != 1 and group_stride != _overflow_checked_mul(stride, extent):
                    break
                group_stride = stride
            group_vol = _overflow_checked_mul(group_vol, extent)
            if FlattenOutputType is axes_mask_t:
                out_layout |= _axis2mask(group_end)
            group_end += 1
        if FlattenOutputType is BaseLayout:
            out_layout.shape[out_i] = group_vol
            out_layout.strides[out_i] = group_stride
        out_i += 1
        group_start = group_end
    if FlattenOutputType is BaseLayout and out_i != ndim:
        trim_base_layout(out_layout, out_i)
    return out_i


cdef inline bint split_strides_in_c_index_order(BaseLayout& out_layout, BaseLayout& in_layout) except -1 nogil:
    cdef int i = in_layout.ndim - 1
    cdef int new_i = out_layout.ndim - 1
    cdef extent_t extent
    cdef extent_t new_extent
    cdef extent_t group_vol
    cdef stride_t group_stride
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    while i >= 0:
        extent = in_shape[i]
        group_stride = in_strides[i]
        group_vol = 1
        while new_i >= 0:
            new_extent = out_layout.shape[new_i]
            if new_extent == 0:
                return False
            if new_extent == 1 or group_vol < extent:
                out_layout.strides[new_i] = group_stride
                group_stride = _overflow_checked_mul(group_stride, new_extent)
                group_vol = _overflow_checked_mul(group_vol, new_extent)
                new_i -= 1
            else:
                break
        if group_vol != extent:
            return False
        i -= 1
    return True


cdef inline int base_layout_concat_validate(const BaseLayout& left_layout, const BaseLayout& right_layout, axis_t axis) except -1 nogil:
    cdef int left_ndim = left_layout.ndim
    if not _normalize_axis(axis, left_ndim + 1):
        raise ValueError(f"Invalid axis: {axis}. Valid axes are in (inclusive) range [0, {left_ndim}]")
    cdef int itemsize = left_layout.itemsize
    if itemsize != right_layout.itemsize:
        raise ValueError(f"Itemsize mismatch: {itemsize} != {right_layout.itemsize}")
    return 0


cdef inline int base_layout_concat(BaseLayout& out_layout, const BaseLayout& left_layout, const BaseLayout& right_layout, axis_t axis) except -1 nogil:
    cdef int left_ndim = left_layout.ndim
    cdef int itemsize = left_layout.itemsize
    base_layout_concat_validate(left_layout, right_layout, axis)

    cdef int right_ndim = right_layout.ndim
    cdef int out_ndim = left_ndim + right_ndim
    init_base_layout(out_layout, out_ndim, itemsize)
    cdef const extent_t* left_shape = left_layout.shape
    cdef const extent_t* right_shape = right_layout.shape
    cdef const stride_t* left_strides = left_layout.strides
    cdef const stride_t* right_strides = right_layout.strides
    cdef int out_i = 0
    for i in range(axis):
        out_layout.shape[out_i] = left_shape[i]
        out_layout.strides[out_i] = left_strides[i]
        out_i += 1
    for i in range(right_ndim):
        out_layout.shape[out_i] = right_shape[i]
        out_layout.strides[out_i] = right_strides[i]
        out_i += 1
    for i in range(axis, left_ndim):
        out_layout.shape[out_i] = left_shape[i]
        out_layout.strides[out_i] = left_strides[i]
        out_i += 1
    return 0


cdef inline bint base_layout_sub(BaseLayout& out_layout, BaseLayout& in_layout, axis_t start_axis=0, axis_t end_axis=-1, axis_vec_t* axes=NULL) except -1 nogil:
    cdef int in_ndim = in_layout.ndim
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides

    cdef int out_ndim
    cdef int out_i = 0

    if axes != NULL:
        return base_layout_sub_with_axes(out_layout, in_layout, deref(axes))

    if not _normalize_axis(start_axis, in_ndim):
        raise ValueError(f"Invalid start axis: {start_axis} out of range for {in_ndim}D tensor")
    if not _normalize_axis(end_axis, in_ndim):
        raise ValueError(f"Invalid end axis: {end_axis} out of range for {in_ndim}D tensor")
    out_ndim = max(end_axis - start_axis + 1, 0)
    init_base_layout(out_layout, out_ndim, in_layout.itemsize)
    for i in range(start_axis, end_axis + 1):
        out_layout.shape[out_i] = in_shape[i]
        out_layout.strides[out_i] = in_strides[i]
        out_i += 1
    return start_axis == 0 and out_ndim == in_ndim


cdef inline bint base_layout_sub_with_axes(BaseLayout& out_layout, BaseLayout& in_layout, axis_vec_t& axes) except -1 nogil:
    cdef int out_ndim = axes.size()
    init_base_layout(out_layout, out_ndim, in_layout.itemsize)

    cdef int in_ndim = in_layout.ndim
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef int out_i = 0
    cdef axis_t axis
    cdef bint is_id = out_ndim == in_ndim

    for i in range(out_ndim):
        axis = axes[i]
        if not _normalize_axis(axis, in_ndim):
            raise ValueError(f"Invalid axis: {axis} out of range for {in_ndim}D tensor")
        if axis != i:
            is_id = False
        out_layout.shape[out_i] = in_shape[axis]
        out_layout.strides[out_i] = in_strides[axis]
        out_i += 1
    return is_id


cdef inline int base_layout_reshape(BaseLayout& out_layout, int64_t old_volume, BaseLayout& in_layout, BaseLayout& like) except -1 nogil:
    init_base_layout(out_layout, like.ndim, in_layout.itemsize)
    base_layout_validate_reshaped_shape(out_layout, old_volume, like)
    zero_out_base_strides(out_layout)

    cdef BaseLayout flattened
    if old_volume != 0:
        base_layout_flatten_in_c_order(flattened, in_layout, old_volume, STRIDED_LAYOUT_AXES_MASK_ALL)
        if not split_strides_in_c_index_order(out_layout, flattened):
            raise ValueError("Layout strides are incompatible with the new shape")


cdef inline int base_layout_validate_reshaped_shape(BaseLayout& out_layout, int64_t old_volume, BaseLayout& like) except -1 nogil:
    cdef int ndim = like.ndim
    cdef int axis = -1
    cdef extent_t extent
    for i in range(ndim):
        extent = like.shape[i]
        if extent < -1:
            raise ValueError("Extents must be non-negative")
        elif extent == -1:
            if axis == -1:
                axis = i
            else:
                raise ValueError("There can be at most one -1 extent in a shape")
        else:
            out_layout.shape[i] = extent
    cdef int64_t new_volume = c_abs(base_volume(like))
    if axis == -1:
        if new_volume != old_volume:
            raise ValueError(f"The original volume {old_volume} and the new volume {new_volume} must be equal.")
    else:
        if new_volume == 0:
            raise ValueError("The -1 extent is ambiguous when the specified sub-volume is 0")
        extent = old_volume // new_volume
        if extent * new_volume != old_volume:
            raise ValueError(f"The original volume {old_volume} must be divisible by the specified sub-volume {new_volume}.")
        out_layout.shape[axis] = extent
    return 0


cdef inline bint _base_layout_permute(BaseLayout& out_layout, BaseLayout& in_layout, IterAxisType& axis_iter, bint inverse) except -1 nogil:
    cdef int ndim = in_layout.ndim
    init_base_layout(out_layout, ndim, in_layout.itemsize)
    cdef axis_t axis
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef bint is_id = True

    for i in range(ndim):
        axis = _get_axis(axis_iter, i)
        if axis != i:
            is_id = False
        if inverse:
            out_layout.shape[axis] = in_shape[i]
            out_layout.strides[axis] = in_strides[i]
        else:
            out_layout.shape[i] = in_shape[axis]
            out_layout.strides[i] = in_strides[axis]
    return is_id


cdef inline bint base_layout_permute(BaseLayout& out_layout, BaseLayout& in_layout, OrderFlag order_flag, axis_vec_t* axis_order, bint inverse) except -1 nogil:
    cdef IterAxisHelper axis_iter
    _setup_axis_iter(axis_iter, in_layout.ndim, order_flag, axis_order)
    if order_flag == ORDER_C:
        return _base_layout_permute(out_layout, in_layout, axis_iter.c, inverse)
    elif order_flag == ORDER_F:
        return _base_layout_permute(out_layout, in_layout, axis_iter.f, inverse)
    elif order_flag == ORDER_PERM:
        return _base_layout_permute(out_layout, in_layout, axis_iter.perm, inverse)
    else:
        raise ValueError(f"Invalid order flag: {order_flag}")


cdef inline int base_layout_transpose_validate(BaseLayout& in_layout, axis_t& axis_a, axis_t& axis_b) except -1 nogil:
    cdef int ndim = in_layout.ndim
    if not _normalize_axis(axis_a, ndim):
        raise ValueError(f"Invalid axis: {axis_a} out of range for {ndim}D tensor")
    if not _normalize_axis(axis_b, ndim):
        raise ValueError(f"Invalid axis: {axis_b} out of range for {ndim}D tensor")
    return 0


cdef inline int base_layout_transpose(BaseLayout& out_layout, BaseLayout& in_layout, axis_t axis_a, axis_t axis_b) except -1 nogil:
    cdef int ndim = in_layout.ndim
    base_layout_transpose_validate(in_layout, axis_a, axis_b)
    init_base_layout_from_ptr(out_layout, in_layout.ndim, in_layout.itemsize, in_layout.shape, in_layout.strides)
    _swap(out_layout.shape[axis_a], out_layout.shape[axis_b])
    _swap(out_layout.strides[axis_a], out_layout.strides[axis_b])
    return 0


cdef inline int base_layout_squeeze(BaseLayout& out_layout, BaseLayout& in_layout, axes_mask_t axis_mask) except -1 nogil:
    cdef int ndim = in_layout.ndim
    init_base_layout(out_layout, ndim, in_layout.itemsize)
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef int out_i = 0
    cdef extent_t extent
    for i in range(ndim):
        extent = in_shape[i]
        if extent != 1 or not (axis_mask & _axis2mask(i)):
            out_layout.shape[out_i] = extent
            out_layout.strides[out_i] = in_strides[i]
            out_i += 1
    if out_i != ndim:
        trim_base_layout(out_layout, out_i)
    return out_i


cdef inline int axes_out_of_range_error(axes_mask_t axes_out_of_range, int out_ndim) except -1:
    cdef tuple axes_tuple = _axes_mask2tuple(axes_out_of_range)
    raise ValueError(
        f"Axes {axes_tuple} are out of [0, {out_ndim - 1}] range"
    )


cdef inline int base_layout_unsqueeze(BaseLayout& out_layout, BaseLayout& in_layout, axes_mask_t axis_mask) except -1 nogil:
    cdef int ndim = in_layout.ndim
    cdef int num_new_axes = _popcount(axis_mask)
    cdef int out_ndim = ndim + num_new_axes
    # init_base_layout validates out_ndim
    init_base_layout(out_layout, out_ndim, in_layout.itemsize)
    cdef axes_mask_t axes_out_of_range = axis_mask & (~all_axes_mask(out_ndim))
    if axes_out_of_range:
        with cython.gil:
            return axes_out_of_range_error(axes_out_of_range, out_ndim)
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef int in_i = ndim - 1
    cdef stride_t last_stride = in_strides[in_i] if in_i >= 0 else 1
    cdef extent_t last_extent = 1
    for i in range(out_ndim - 1, -1, -1):
        if axis_mask & _axis2mask(i):
            out_layout.shape[i] = 1
            out_layout.strides[i] = _overflow_checked_mul(last_stride, last_extent)
        else:
            last_stride = in_strides[in_i]
            last_extent = in_shape[in_i]
            out_layout.shape[i] = last_extent
            out_layout.strides[i] = last_stride
            in_i -= 1
    assert in_i == -1
    return 0


cdef inline bint base_layout_broadcast(BaseLayout& out_layout, BaseLayout& in_layout, BaseLayout& like) except -1 nogil:
    init_base_layout_from_ptr(out_layout, like.ndim, in_layout.itemsize, like.shape, NULL)
    zero_out_base_strides(out_layout)
    if out_layout.ndim < in_layout.ndim:
        raise ValueError(
            f"Shapes cannot be broadcast together: "
            f"the broadcast shape ndim ({out_layout.ndim}) must be "
            f"greater than or equal to the original shape "
            f"ndim ({in_layout.ndim})."
        )
    cdef int ndim_diff = out_layout.ndim - in_layout.ndim
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef extent_t* broadcast_shape = out_layout.shape + ndim_diff
    cdef stride_t* broadcast_strides = out_layout.strides + ndim_diff
    cdef bint is_noop = ndim_diff == 0
    for i in range(in_layout.ndim):
        if in_shape[i] == broadcast_shape[i]:
            broadcast_strides[i] = in_strides[i]
        elif in_shape[i] != 1:
            raise ValueError(
                f"Shapes cannot be broadcast together: "
                f"the original extent must be 1 or be equal to broadcast extent, "
                f"got {in_shape[i]} and {broadcast_shape[i]} for axis {i}."
            )
        else:
            is_noop = False
            # in_extent == 1, the zero stride for broadcast extent is already set
    return is_noop


cdef inline bint base_layout_unbroadcast(BaseLayout& out_layout, BaseLayout& in_layout) except -1 nogil:
    cdef int ndim = in_layout.ndim
    init_base_layout(out_layout, ndim, in_layout.itemsize)
    cdef stride_t stride
    cdef bint is_id = True
    for i in range(ndim):
        stride = in_layout.strides[i]
        if stride != 0:
            out_layout.shape[i] = in_layout.shape[i]
            out_layout.strides[i] = stride
        else:
            is_id = is_id and (in_layout.shape[i] == 1)
            out_layout.shape[i] = 1
            out_layout.strides[i] = 0
    return is_id


cdef inline int64_t gcd(int64_t a, int64_t b) except? -1 nogil:
    while b != 0:
        a, b = b, a % b
    return a


cdef inline int base_layout_pack(BaseLayout& out_layout, BaseLayout& in_layout, int new_itemsize, intptr_t data_ptr, int axis, bint keep_dim) except -1 nogil:
    cdef int ndim = in_layout.ndim
    cdef int itemsize = in_layout.itemsize
    if new_itemsize <= 0 or new_itemsize & (new_itemsize - 1):
        raise ValueError(f"The new itemsize must be a power of two, got {new_itemsize}.")
    if itemsize <= 0 or itemsize & (itemsize - 1):
        raise ValueError(f"The itemsize must be a power of two, got {itemsize}.")
    if new_itemsize <= itemsize:
        raise ValueError(f"The new itemsize ({new_itemsize}) must be greater than the original itemsize ({itemsize}).")
    if not _normalize_axis(axis, ndim):
        raise ValueError(f"Invalid axis: {axis} out of range for {ndim}D tensor")
    if data_ptr % new_itemsize != 0:
        raise ValueError(f"The data pointer ({data_ptr}) must be aligned to the packed itemsize ({new_itemsize}).")

    cdef extent_t* shape = in_layout.shape
    cdef stride_t* strides = in_layout.strides
    if strides[axis] != 1:
        raise ValueError(f"The strides[{axis}] must be 1.")

    cdef int vec_size = new_itemsize // itemsize
    cdef extent_t packed_extent = shape[axis]
    if packed_extent == 0:
        raise ValueError(f"The shape[{axis}] must be non-zero.")
    packed_extent //= vec_size
    if packed_extent * vec_size != shape[axis]:
        raise ValueError(f"The shape[{axis}] must be divisible by {vec_size}.")

    init_base_layout(out_layout, ndim, new_itemsize)
    cdef stride_t packed_stride
    cdef int out_i = 0
    for i in range(ndim):
        if i == axis:
            if keep_dim or packed_extent != 1:  # omit the packed axis if it is reduced to 1
                out_layout.shape[out_i] = packed_extent
                out_layout.strides[out_i] = 1
                out_i += 1
        else:
            packed_stride = strides[i] // vec_size
            if packed_stride * vec_size != strides[i]:
                raise ValueError(f"The strides[{i}] must be divisible by {vec_size}.")
            out_layout.shape[out_i] = shape[i]
            out_layout.strides[out_i] = packed_stride
            out_i += 1
    if out_i != ndim:
        trim_base_layout(out_layout, out_i)
    return vec_size


cdef inline int base_layout_unpack(BaseLayout &out_layout, BaseLayout &in_layout, int new_itemsize, int axis, bint add_dim) except -1 nogil:
    cdef int itemsize = in_layout.itemsize
    if new_itemsize >= itemsize:
        raise ValueError(f"The new itemsize ({new_itemsize}) must be less than the original itemsize ({itemsize}).")
    if new_itemsize <= 0 or new_itemsize & (new_itemsize - 1):
        raise ValueError(f"The new itemsize must be a power of two, got {new_itemsize}.")
    if itemsize <= 0 or itemsize & (itemsize - 1):
        raise ValueError(f"The original itemsize must be a power of two, got {itemsize}.")

    cdef int in_ndim = in_layout.ndim
    cdef int out_ndim = in_ndim + 1 if add_dim else in_ndim
    if not _normalize_axis(axis, out_ndim):
        raise ValueError(f"Invalid axis: {axis}. It must be in the range [0, {out_ndim}).")

    cdef extent_t* shape = in_layout.shape
    cdef stride_t* strides = in_layout.strides
    cdef int vec_size = itemsize // new_itemsize
    init_base_layout(out_layout, out_ndim, new_itemsize)

    out_layout.strides[axis] = 1
    if add_dim:
        out_layout.shape[axis] = vec_size
    else:
        if shape[axis] == 0:
            raise ValueError(f"When add_dim is False, the shape[{axis}] must be non-zero, got {shape[axis]}.")
        if strides[axis] != 1:
            raise ValueError(f"When add_dim is False, the strides[{axis}] must be 1, got {strides[axis]}.")
        out_layout.shape[axis] = _overflow_checked_mul(shape[axis], vec_size)

    cdef int out_i = 0
    for i in range(in_ndim):
        if i == axis:
            # we set out_i axis before the loop
            out_i += 1
            if not add_dim:
                continue
        out_layout.shape[out_i] = shape[i]
        out_layout.strides[out_i] = _overflow_checked_mul(strides[i], vec_size)
        out_i += 1
    return vec_size


cdef inline int max_compatible_itemsize(BaseLayout& layout, int max_itemsize, intptr_t data_ptr, int axis) except? -1 nogil:
    cdef int ndim = layout.ndim
    cdef int itemsize = layout.itemsize
    if max_itemsize <= 0 or max_itemsize & (max_itemsize - 1):
        raise ValueError(f"The max_itemsize must be a power of two, got {max_itemsize}.")
    if itemsize <= 0 or itemsize & (itemsize - 1):
        raise ValueError(f"The original itemsize must be a power of two, got {itemsize}.")
    if not _normalize_axis(axis, ndim):
        raise ValueError(f"Invalid axis: {axis} out of range for {ndim}D tensor")
    if max_itemsize < itemsize:
        raise ValueError(f"The max_itemsize ({max_itemsize}) cannot be less than the original itemsize ({itemsize}).")
    max_itemsize = gcd(max_itemsize, c_abs(data_ptr))
    cdef extent_t* shape = layout.shape
    cdef stride_t* strides = layout.strides
    if ndim < 1 or strides[axis] != 1 or shape[axis] == 0:
        return itemsize
    max_itemsize = gcd(max_itemsize, _overflow_checked_mul(shape[axis], itemsize))
    for i in range(ndim):
        if i == axis:
            continue
        max_itemsize = gcd(max_itemsize, _overflow_checked_mul(c_abs(strides[i]), itemsize))
    return max_itemsize


cdef inline int get_ellipsis_idx(tuple slices) except -2:
    cdef int ellipsis_idx = -1
    cdef int num_slices = len(slices)
    for i in range(num_slices):
        if slices[i] is Ellipsis:
            if ellipsis_idx >= 0:
                raise ValueError("At most one ellipsis (...) is allowed.")
            ellipsis_idx = i
    return ellipsis_idx


cdef inline bint base_layout_slice(BaseLayout& out_layout, stride_t& out_slice_offset, BaseLayout& in_layout, tuple slices) except -1:
    cdef int ndim = in_layout.ndim
    init_base_layout(out_layout, ndim, in_layout.itemsize)
    out_slice_offset = 0
    cdef extent_t* in_shape = in_layout.shape
    cdef stride_t* in_strides = in_layout.strides
    cdef Py_ssize_t start
    cdef Py_ssize_t stop
    cdef Py_ssize_t step
    cdef extent_t new_extent
    cdef extent_t in_extent
    cdef object py_slice
    cdef bint zero_slice = False
    cdef int out_i = 0
    cdef int in_i = 0
    cdef int ellipsis_idx = get_ellipsis_idx(slices)  # [-1, len(slices) - 1]
    cdef bint has_ellipsis = ellipsis_idx >= 0
    cdef int slices_len = len(slices)
    cdef int num_slices = slices_len - has_ellipsis
    if num_slices > ndim:
        raise ValueError(f"The number of slices ({num_slices}) is greater than the number of dimensions ({ndim}).")
    cdef int num_dims_to_skip = ndim - num_slices  # non-negative
    cdef bint is_id = True
    for slice_i in range(slices_len):
        if slice_i == ellipsis_idx:
            for i in range(num_dims_to_skip):
                out_layout.shape[out_i] = in_shape[in_i]
                out_layout.strides[out_i] = in_strides[in_i]
                in_i += 1
                out_i += 1
            continue
        py_slice = slices[slice_i]
        if isinstance(py_slice, int):
            start = py_slice
            if not _normalize_axis(start, in_shape[in_i]):
                # it's important to raise IndexError here, Python makes the type
                # iterable if it has a __getitem__ method that accepts integers
                # the IndexError is a way to stop the iteration
                raise IndexError(f"Invalid index: {start} out of range for axis {in_i} with extent {in_shape[in_i]}")
            # single element index removes extent from the shape,
            # so don't increment out_i
            out_slice_offset = _overflow_checked_sum(out_slice_offset, _overflow_checked_mul(start, in_strides[in_i]))
            in_i += 1
            is_id = False
        elif type(py_slice) is slice:
            in_extent = in_shape[in_i]
            _PySlice_Unpack(<PyObject *>py_slice, &start, &stop, &step)
            new_extent = _PySlice_AdjustIndices(in_extent, &start, &stop, step)
            if new_extent == in_extent and step == 1:
                out_layout.shape[out_i] = in_extent
                out_layout.strides[out_i] = in_strides[in_i]
            else:
                is_id = False
                out_layout.shape[out_i] = new_extent
                out_layout.strides[out_i] = _overflow_checked_mul(in_strides[in_i], step)
                if new_extent == 0:
                    zero_slice = True
                else:
                    out_slice_offset = _overflow_checked_sum(out_slice_offset, _overflow_checked_mul(start, in_strides[in_i]))
            in_i += 1
            out_i += 1
        else:
            raise TypeError(f"Invalid slice: {py_slice}. Expected slice instance, integer, or Ellipsis (...).")
    if not has_ellipsis:
        for i in range(num_slices, ndim):
            out_layout.shape[out_i] = in_shape[i]
            out_layout.strides[out_i] = in_strides[i]
            out_i += 1
    if out_i != ndim:
        trim_base_layout(out_layout, out_i)
    if zero_slice:
        zero_out_base_strides(out_layout)
    return is_id
