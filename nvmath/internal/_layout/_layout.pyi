# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import SlicedLayout
import StridedLayout
import _cython_3_2_5
from _typeshed import Incomplete
from typing import Any, ClassVar, Literal, overload

__reduce_cython__: _cython_3_2_5.cython_function_or_method
__setstate_cython__: _cython_3_2_5.cython_function_or_method
__test__: dict

class SlicedLayout:
    """SlicedLayout()

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
    make sure the data pointer is adjusted to account for the :attr:`slice_offset`."""
    __pyx_vtable__: ClassVar[PyCapsule] = ...
    layout: SlicedLayout.layout
    slice_offset: Incomplete
    slice_offset_in_bytes: SlicedLayout.slice_offset_in_bytes
    def __init__(self) -> Any:
        """Initialize self.  See help(type(self)) for accurate signature."""
    def __eq__(self, other: object) -> bool:
        """Return self==value."""
    def __ge__(self, other: object) -> bool:
        """Return self>=value."""
    def __getitem__(self, index):
        """Return self[key]."""
    def __gt__(self, other: object) -> bool:
        """Return self>value."""
    def __le__(self, other: object) -> bool:
        """Return self<=value."""
    def __lt__(self, other: object) -> bool:
        """Return self<value."""
    def __ne__(self, other: object) -> bool:
        """Return self!=value."""
    def __reduce__(self):
        """SlicedLayout.__reduce_cython__(self)"""

class StridedLayout:
    """StridedLayout(shape: tuple[int] | list[int] | int, strides: tuple[int] | list[int] | int | None, int itemsize: int, bool divide_strides: bool = False) -> None

    A class describing the layout of a multi-dimensional tensor
    with a shape, strides and itemsize.

    In Python, the StridedLayout is immutable, all transforming methods
    (e.g. :meth:`reshaped`, :meth:`permuted`, etc.)
    return a new instance or unchanged self. The latter may happen
    if the operation would be a no-op (like reshaping to the same shape).

    .. warning::
        This API is experimental and may change at any time."""
    dense: ClassVar[method] = ...
    dense_like: ClassVar[method] = ...
    __pyx_vtable__: ClassVar[PyCapsule] = ...
    has_no_negative_stride: StridedLayout.has_no_negative_stride
    is_abs_dense_any: StridedLayout.is_abs_dense_any
    is_abs_dense_c: StridedLayout.is_abs_dense_c
    is_abs_dense_f: StridedLayout.is_abs_dense_f
    is_contiguous_any: StridedLayout.is_contiguous_any
    is_contiguous_c: StridedLayout.is_contiguous_c
    is_contiguous_f: StridedLayout.is_contiguous_f
    is_exhaustive: StridedLayout.is_exhaustive
    is_unique: StridedLayout.is_unique
    itemsize: StridedLayout.itemsize
    max_offset: StridedLayout.max_offset
    max_stride: StridedLayout.max_stride
    memory_range_size: StridedLayout.memory_range_size
    memory_range_size_in_bytes: StridedLayout.memory_range_size_in_bytes
    min_offset: StridedLayout.min_offset
    min_stride: StridedLayout.min_stride
    ndim: StridedLayout.ndim
    offset_bounds: Any
    shape: StridedLayout.shape
    stride_order: StridedLayout.stride_order
    strides: StridedLayout.strides
    strides_in_bytes: StridedLayout.strides_in_bytes
    volume: StridedLayout.volume
    def __init__(self, shape: tuple[int] | list[int] | int, strides: tuple[int] | list[int] | int | None, intitemsize: int, booldivide_strides: bool = ...) -> None:
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
    def broadcast_to(self, shape: int | tuple[int] | list[int] | StridedLayout) -> StridedLayout:
        """StridedLayout.broadcast_to(self: StridedLayout, shape: int | tuple[int] | list[int] | StridedLayout) -> StridedLayout

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
            The broadcasted layout."""
    def extended(self, StridedLayoutother: StridedLayout, intaxis: int = ...) -> StridedLayout:
        """StridedLayout.extended(self: StridedLayout, StridedLayout other: StridedLayout, int axis: int = -1) -> StridedLayout

        Returns a layout as if the ``other`` layout was inserted before the
        specified ``axis`` into the current layout. The valid range of ``axis`` is
        (inclusive) range ``[0, self.ndim]``."""
    @overload
    def flattened(self, intstart_axis: int = ..., intend_axis: int = ..., intmask: int | None = ...) -> StridedLayout:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self, mask=...) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    @overload
    def flattened(self, mask=...) -> Any:
        """StridedLayout.flattened(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, int mask: int | None = None) -> StridedLayout

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
            assert layout2.flattened(mask=mask) == StridedLayout((4, 15), (1, 4), 4)"""
    def flattened_axis_mask(self) -> axes_mask_t:
        """StridedLayout.flattened_axis_mask(self: StridedLayout) -> axes_mask_t

        A mask describing which axes of this layout are mergeable
        using the :meth:`flattened` method."""
    @overload
    def has_stride_order(self, stride_order: Literal['C', 'F'] | tuple[int]) -> bool:
        '''StridedLayout.has_stride_order(self: StridedLayout, stride_order: Literal[\'C\', \'F\'] | tuple[int]) -> bool

        Checks if the layout has the specified stride order, i.e.
        the absolute values of the strides are (non-strictly) monotonic in the specified order.

        Please note, there\'s a subtle difference between
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
            assert sliced.has_stride_order("C")'''
    @overload
    def has_stride_order(self, some_permutation) -> Any:
        '''StridedLayout.has_stride_order(self: StridedLayout, stride_order: Literal[\'C\', \'F\'] | tuple[int]) -> bool

        Checks if the layout has the specified stride order, i.e.
        the absolute values of the strides are (non-strictly) monotonic in the specified order.

        Please note, there\'s a subtle difference between
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
            assert sliced.has_stride_order("C")'''
    @overload
    def is_almost_equal(self, StridedLayoutother: StridedLayout) -> bool:
        '''StridedLayout.is_almost_equal(self: StridedLayout, StridedLayout other: StridedLayout) -> bool

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
            assert l1.is_almost_equal(l2)'''
    @overload
    def is_almost_equal(self, l2) -> Any:
        '''StridedLayout.is_almost_equal(self: StridedLayout, StridedLayout other: StridedLayout) -> bool

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
            assert l1.is_almost_equal(l2)'''
    def is_dense(self, stride_order: Literal['C', 'F', 'K'] | tuple[int] = ..., boolallow_negative_strides: bool = ..., boolallow_leading_dim_stride: bool = ...) -> bool:
        '''StridedLayout.is_dense(self: StridedLayout, stride_order: Literal[\'C\', \'F\', \'K\'] | tuple[int] = \'C\', bool allow_negative_strides: bool = False, bool allow_leading_dim_stride: bool = False) -> bool

        With the default settings (no negative strides, no padding),
        it is equivalent to :attr:`is_contiguous_any` / :attr:`is_contiguous_c` / :attr:`is_contiguous_f`
        (with stride order "K" / "C" / "F").

        stride_order : str or tuple, optional
            The order of the strides:

            * \'C\' - is the layout dense in C-order (from the right to the left)
            * \'F\' - is the layout dense in F-order (from the left to the right)
            * \'K\' - is there any ``stride_order`` such that layout dense
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
            we end up with regular contiguous layout.'''
    def max_compatible_itemsize(self, intmax_itemsize: int = ..., intptr_tdata_ptr: intptr_t = ..., intaxis: int = ...) -> int:
        """StridedLayout.max_compatible_itemsize(self: StridedLayout, int max_itemsize: int = 16, intptr_t data_ptr: intptr_t = 0, int axis: int = -1) -> int

        Returns the maximum itemsize (but no greater than ``max_itemsize``) that can be used
        with the :meth:`packed` method for the current layout."""
    def packed(self, intitemsize: int, intptr_tdata_ptr: intptr_t = ..., intaxis: int = ..., boolkeep_dim: bool = ...) -> StridedLayout:
        """StridedLayout.packed(self: StridedLayout, int itemsize: int, intptr_t data_ptr: intptr_t = 0, int axis: int = -1, bool keep_dim: bool = True) -> StridedLayout

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
            assert complex_layout.itemsize == 8"""
    @overload
    def permuted(self, tupleaxis_order: tuple[int], boolinverse: bool = ...) -> StridedLayout:
        """StridedLayout.permuted(self: StridedLayout, tuple axis_order: tuple[int], bool inverse: bool = False) -> StridedLayout

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

            assert layout.permuted(perm).permuted(perm, inverse=True) == layout"""
    @overload
    def permuted(self, perm) -> Any:
        """StridedLayout.permuted(self: StridedLayout, tuple axis_order: tuple[int], bool inverse: bool = False) -> StridedLayout

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

            assert layout.permuted(perm).permuted(perm, inverse=True) == layout"""
    @overload
    def permuted(self, perm, inverse=...) -> Any:
        """StridedLayout.permuted(self: StridedLayout, tuple axis_order: tuple[int], bool inverse: bool = False) -> StridedLayout

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

            assert layout.permuted(perm).permuted(perm, inverse=True) == layout"""
    @overload
    def permuted(self, inv_perm) -> Any:
        """StridedLayout.permuted(self: StridedLayout, tuple axis_order: tuple[int], bool inverse: bool = False) -> StridedLayout

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

            assert layout.permuted(perm).permuted(perm, inverse=True) == layout"""
    def reshaped(self, shape: tuple[int] | StridedLayout | int) -> StridedLayout:
        """StridedLayout.reshaped(self: StridedLayout, shape: tuple[int] | StridedLayout | int) -> StridedLayout

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
            # layout.permuted((2, 0, 1)).reshaped((20, 3)) -> error"""
    @overload
    def reversed(self) -> StridedLayout:
        """StridedLayout.reversed(self: StridedLayout) -> StridedLayout

        Returns ``StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)``.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 4), 1)
            assert layout == StridedLayout((5, 3, 4), (12, 4, 1), 1)
            assert layout.reversed() == StridedLayout((4, 3, 5), (1, 4, 12), 1)
            assert layout.reversed() == StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)"""
    @overload
    def reversed(self) -> Any:
        """StridedLayout.reversed(self: StridedLayout) -> StridedLayout

        Returns ``StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)``.

        .. highlight:: python
        .. code-block:: python

            layout = StridedLayout.dense((5, 3, 4), 1)
            assert layout == StridedLayout((5, 3, 4), (12, 4, 1), 1)
            assert layout.reversed() == StridedLayout((4, 3, 5), (1, 4, 12), 1)
            assert layout.reversed() == StridedLayout(reversed(layout.shape), reversed(layout.strides), layout.itemsize)"""
    def squeezed(self, axis: int | tuple[int] | None = ..., intmask: int | None = ...) -> StridedLayout:
        """StridedLayout.squeezed(self: StridedLayout, axis: int | tuple[int] | None = None, int mask: int | None = None) -> StridedLayout

        Returns a layout where all the unit dimensions (extents equal to 1)
        are removed.

        To limit which axes are considered for squeezing, either the ``axis`` parameter
        or the ``mask`` parameter can be used.

        * If ``axis`` is provided, it must be an integer or a tuple of unique integers
          in range ``[0, ndim)``, only those axes are considered for squeezing.
        * Otherwise, if ``mask`` is provided, only the axes specified by the mask are considered
          (shape[axis] is removed iff ``shape[axis] == 1 and (mask & (1 << axis))``)."""
    def squeezed_range(self, intstart_axis: int = ..., intend_axis: int = ...) -> StridedLayout:
        """StridedLayout.squeezed_range(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1) -> StridedLayout

        Returns a layout where all the unit dimensions (extents equal to 1)
        in inclusive range ``[start_axis, end_axis]`` are removed."""
    def sub(self, intstart_axis: int = ..., intend_axis: int = ..., tupleaxes: tuple[int] | None = ...) -> StridedLayout:
        """StridedLayout.sub(self: StridedLayout, int start_axis: int = 0, int end_axis: int = -1, tuple axes: tuple[int] | None = None) -> StridedLayout

        Returns a sub-layout consisting of the specified axes.

        The axes to copy can be specified by:
            * The ``axes`` tuple of integers in range ``[0, ndim]``.
              The order of ``axes`` in the tuple determines the order of axes in the sub-layout.
            * If the ``axes`` tuple is not provided, the inclusive range ``[start_axis, end_axis]``
              is copied."""
    def to_dense(self, stride_order=...) -> StridedLayout:
        """StridedLayout.to_dense(self: StridedLayout, stride_order='K') -> StridedLayout

        Returns a contiguous layout with the same shape and itemsize,
        but with contiguous strides in the specified order.

        .. note::
            The returned layout is guaranteed to be contiguous, i.e. :attr:`is_contiguous_any` is True.
            Layout can be dense in a less strict sense (e.g. having negative strides but still bijective),
            such layouts are still converted to meet the strict definition of contiguous layout.

        See :meth:`dense_like` method documentation for details.

        See also :meth:`is_contiguous_any`.
        See also :meth:`is_dense`."""
    def transposed(self, intaxis_a: int, intaxis_b: int) -> StridedLayout:
        """StridedLayout.transposed(self: StridedLayout, int axis_a: int, int axis_b: int) -> StridedLayout

        Returns a layout where the two specified axes are swapped."""
    def unbroadcast(self) -> StridedLayout:
        """StridedLayout.unbroadcast(self: StridedLayout) -> StridedLayout

        Returns a layout where extents with stride 0 are replaced
        with unit extents (extent = 1, stride = 0)."""
    def unit_extents_mask(self) -> axes_mask_t:
        """StridedLayout.unit_extents_mask(self: StridedLayout) -> axes_mask_t

        A mask of axes that have extent equal to 1.
        I.e. ``layout.unit_extents & (1 << axis) iff layout.shape[axis] == 1``,
        in particular ``layout.unit_extents == 0`` iff there are no unit extents.

        :type: axes_mask_t"""
    def unpacked(self, intitemsize: int, intaxis: int = ..., booladd_dim: bool = ...) -> StridedLayout:
        """StridedLayout.unpacked(self: StridedLayout, int itemsize: int, int axis: int = -1, bool add_dim: bool = False) -> StridedLayout

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
            numpy.testing.assert_array_equal(ar_batch[1], ac.imag)"""
    @overload
    def unsqueezed(self, axis: int | tuple[int] | None = ..., intmask: int = ...) -> StridedLayout:
        """StridedLayout.unsqueezed(self: StridedLayout, axis: int | tuple[int] | None = None, int mask: int = 0) -> StridedLayout

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
            assert l1.strides == l2.strides == l3.strides == (12, 3, 3)"""
    @overload
    def unsqueezed(self, mask=...) -> Any:
        """StridedLayout.unsqueezed(self: StridedLayout, axis: int | tuple[int] | None = None, int mask: int = 0) -> StridedLayout

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
            assert l1.strides == l2.strides == l3.strides == (12, 3, 3)"""
    @overload
    def unsqueezed(self, mask=...) -> Any:
        """StridedLayout.unsqueezed(self: StridedLayout, axis: int | tuple[int] | None = None, int mask: int = 0) -> StridedLayout

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
            assert l1.strides == l2.strides == l3.strides == (12, 3, 3)"""
    @overload
    def unsqueezed(self, mask=...) -> Any:
        """StridedLayout.unsqueezed(self: StridedLayout, axis: int | tuple[int] | None = None, int mask: int = 0) -> StridedLayout

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
            assert l1.strides == l2.strides == l3.strides == (12, 3, 3)"""
    def unsqueezed_to_ndim(self, intndim: int, intaxis: int = ...) -> StridedLayout:
        """StridedLayout.unsqueezed_to_ndim(self: StridedLayout, int ndim: int, int axis: int = 0) -> StridedLayout

        Returns a layout with the specified number of dimensions, by adding unit extents
        starting from the specified axis.

        The valid range of ``axis`` is (inclusive) range ``[0, ndim]``."""
    def __add__(self, other): ...
    def __eq__(self, other: object) -> bool:
        """Return self==value."""
    def __ge__(self, other: object) -> bool:
        """Return self>=value."""
    def __getitem__(self, index):
        """Return self[key]."""
    def __gt__(self, other: object) -> bool:
        """Return self>value."""
    def __le__(self, other: object) -> bool:
        """Return self<=value."""
    def __len__(self) -> int:
        """Return len(self)."""
    def __lt__(self, other: object) -> bool:
        """Return self<value."""
    def __ne__(self, other: object) -> bool:
        """Return self!=value."""
    def __radd__(self, other):
        """Return value+self."""
    def __reduce__(self):
        """StridedLayout.__reduce_cython__(self)"""
