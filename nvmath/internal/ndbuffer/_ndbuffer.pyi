# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import _numpy
from _typeshed import Incomplete
from typing import Any, ClassVar

__test__: dict

class NDBuffer:
    """NDBuffer(*args, **kwargs)

    NDBuffer is an n-dimensional view over a memory allocation.

    .. warning::
        This API is experimental and may change at any time.

    Stream-semantics
        In contrast to cupy, torch etc., there is no current stream notion at the NDBuffer level.
        For this reason, calls that operate on device memory require passing
        the stream explicitly.

    .. _Custom memory resources:

    Custom memory resources
        Any custom memory resource provided by the user (see for example :meth:`~NDBuffer.empty` or
        :meth:`~NDBuffer.copy_`), should adhere to the cuda.core.MemoryResource protocol.

        When allocating new tensors (:meth:`~NDBuffer.empty`, :meth:`~NDBuffer.empty_like`),
        NDBuffer simply forwards the user-provided ``stream``
        argument to the memory resource's ``mr.allocate(size, stream)`` method and returns
        the new allocation to the caller via :attr:`NDBuffer.data`.

        In all cases, NDBuffer assumes that (currently or for the sake of future compatibility):

        * Allocations with non-None stream ``mr.allocate(size, stream)`` are scheduled
          on the provided stream and, by default, deallocation is scheduled on the same stream
          (if not overridden with ``allocation.close(other_stream)``)
        * Allocations with None stream ``mr.allocate(size, None)`` are host-synchronous
          (safe to immediately access with host-blocking operations).
        * Device memory resources are always stream-oriented (schedule allocation
          and deallocation on the provided stream).
        * Host memory resources can be either stream-oriented or host-synchronous.

        Host-synchronous memory resource:
            For example, regular malloc/free, or numpy.empty. The memory can be safely
            accessed with host-blocking operations. If the memory is accessible
            from a device, it can be safely accessed as long as the device
            operations are synchronized with the host.

        Stream-oriented memory resource:
            Stream-oriented memory resource must ensure that operations
            scheduled on the ``stream`` after allocation but before
            deallocation call, can safely access the memory,
            even if they execute asynchronously (i.e. they
            may actually continue executing after the deallocation call).

            For example:

            * cuda asynchronous memory pool that schedules allocation on the provided ``stream``,
              and uses the same ``stream`` to schedule deallocation.
            * memory resources that enforce synchronization with the ``stream``
              or the respective device after each allocation and deallocation.

        In calls that may need to allocate workspace using the custom resources
        (e.g. :meth:`~NDBuffer.copy_`), NDBuffer puts additional requirements
        on the memory resources:

        * Host memory resource must be able to act both as stream-oriented
          (if it receives a stream) and host-synchronous (if it receives None).
        * The memory resources must be able to accept different
          streams for allocation and deallocation:

          - The stream passed to ``mr.allocate(size, stream)``
            may be different from the one passed by the user to NDBuffer call, and
          - It must be possible to override the default stream order
            for deallocation via ``allocation.close(stream)``.

    Attributes
    ----------
    base : NDBuffer | None
        The base NDBuffer. If not None, the current NDBuffer is a view created from
        the base NDBuffer.
    data : object
        The data/allocation/buffer to view.
    data_ptr : intptr_t
        The raw pointer to memory held by ``data``. It points to the address
        of element at index ``(0, ) * ndim``.

        .. warning::
            This pointer may not point to the beginning of the ``data`` buffer.
            Even when limited to the layout's memory range, the pointer may not point
            to the beginning of that range if the layout has negative strides.
    dtype_name : str
        The name of the dtype. The layout's itemsize must match the dtype's itemsize.
    layout : StridedLayout
        The layout of the NDBuffer."""
    empty: ClassVar[method] = ...
    empty_like: ClassVar[method] = ...
    from_cupy: ClassVar[method] = ...
    from_data: ClassVar[method] = ...
    from_numpy: ClassVar[method] = ...
    __pyx_vtable__: ClassVar[PyCapsule] = ...
    base: Incomplete
    data: Incomplete
    data_ptr: Incomplete
    device: Incomplete
    device_id: Incomplete
    dtype: NDBuffer.dtype
    dtype_name: Incomplete
    itemsize: Incomplete
    layout: Incomplete
    ndim: Incomplete
    numpy_dtype: NDBuffer.numpy_dtype
    raw_memory_range_info: Incomplete
    shape: Incomplete
    size: Incomplete
    strides: Incomplete
    strides_in_bytes: Incomplete
    def __init__(self, *args, **kwargs) -> Any:
        """
        Don't instantiate NDBuffer directly. Use the following class methods instead:

        * To create a view over existing data, use :meth:`~NDBuffer.from_data`, :meth:`~NDBuffer.from_numpy` or :meth:`~NDBuffer.from_cupy` instead.
        * To allocate new memory, use :meth:`~NDBuffer.empty`, :meth:`~NDBuffer.empty_like`.
        """
    def as_numpy(self) -> Any:
        """NDBuffer.as_numpy(self)

        Returns a numpy array view of the NDBuffer's data, with the same
        shape, strides, and dtype as the NDBuffer."""
    def as_strided(self, StridedLayoutlayout=..., dtype: str | _numpy.dtype | None = ..., intoffset_in_bytes: int = ..., boolcheck_bounds: bool = ...) -> NDBuffer:
        '''NDBuffer.as_strided(self, StridedLayout layout=None, dtype: str | _numpy.dtype | None = None, int offset_in_bytes: int = 0, bool check_bounds: bool = True) -> NDBuffer

        Returns a NDBuffer that views the same memory/data, but with a new layout
        and dtype, similar to `numpy.lib.stride_tricks.as_strided`, or `torch.as_strided`.

        If specified, ``offset_in_bytes`` is the number of bytes to offset the current data pointer by.

        If the ``check_bounds`` flag is set to True, the method will compare memory range
        of the new layout with the memory range of the current instance\'s base
        and raise a ValueError if the new range is not entirely contained within the old range.

        .. highlight:: python
        .. code-block:: python

            a = np.arange(5*8, dtype=np.float32)
            ndbuf = NDBuffer.from_numpy(a).reshape((5, 8))
            view = ndbuf.view(np.complex64)[..., -1:1:-1]
            np.testing.assert_array_equal(view.as_numpy(), a.reshape((5, 8)).view(np.complex64)[..., -1:1:-1])

            # Now, if we get the repacked sliced layout and want to set it manually:
            sliced_layout = StridedLayout.dense((5, 8), itemsize=4).packed(itemsize=8)[..., -1:1:-1]
            view2 = ndbuf.as_strided(layout=sliced_layout.layout, dtype=np.complex64, offset_in_bytes=sliced_layout.slice_offset_in_bytes)
            assert view.data_ptr == view2.data_ptr
            assert view.layout == view2.layout


        .. highlight:: python
        .. code-block:: python

            a = np.arange(7, dtype=np.float32)
            narrow_view = NDBuffer.from_numpy(a)[3:4]
            # We can get back a wider view over the same data
            wider_view = narrow_view.as_strided(StridedLayout.dense(6, itemsize=4), offset_in_bytes=-8)
            assert narrow_view.base[1:].data_ptr == wider_view.data_ptr
            assert narrow_view.base[1:].layout == wider_view.layout

            # This won\'t work with check_bounds true because NDBuffer doesn\'t know about
            # the base "wide" view.
            a = np.arange(7, dtype=np.float32)
            narrow_view = NDBuffer.from_numpy(a[3:4])
            try:
                wider_view = narrow_view.as_strided(StridedLayout.dense(6, itemsize=4), offset_in_bytes=-8)
            except ValueError as e:
                assert "layout is incompatible" in str(e)
            else:
                assert False, "Expected ValueError"
            wider_view = narrow_view.as_strided(StridedLayout.dense(6, itemsize=4), offset_in_bytes=-8, check_bounds=False)
            assert NDBuffer.from_numpy(a[1:]).data_ptr == wider_view.data_ptr
            assert NDBuffer.from_numpy(a[1:]).layout == wider_view.layout'''
    def broadcast_to(self, layout: tuple[int] | int | StridedLayout) -> NDBuffer:
        """NDBuffer.broadcast_to(self, layout: tuple[int] | int | StridedLayout) -> NDBuffer

        Returns an NDBuffer that is a view of the same data, but with a layout broadcast
        to match the provided shape.

        The shapes are compatible if:

        * the new shape has the same or greater number of dimensions,
        * starting from the right, each extent in the old shape is 1 or equal to the
            corresponding extent in the new shape.

        Strides of the added or modified extents are set to 0; the remaining ones are
        unchanged. Raises ``ValueError`` if the shapes are not compatible.

        Parameters
        ----------
        layout : tuple[int] | int | StridedLayout
            The new shape to broadcast to. If a :class:`StridedLayout` is passed, its
            shape is used.


        See also: :meth:`StridedLayout.broadcast_to`."""
    def copy_(self, NDBuffersrc, stream=..., host_memory_resource=..., device_memory_resource=..., logger=..., boolblocking: bool | None = ...) -> Any:
        """NDBuffer.copy_(self, NDBuffer src, *, stream=None, host_memory_resource=None, device_memory_resource=None, logger=None, bool blocking: bool | None = None)

        Copies the data from the src NDBuffer to the current NDBuffer.

        The src's shape must be equal or broadcastable to the current NDBuffer's shape.
        The itemsize and dtype must be exactly the same.

        By default, the D2D copies are non-blocking and D2H/H2D copies are blocking.
        This can be overridden with the ``blocking`` argument.
        H2H copies are always blocking and the ``blocking`` argument is ignored.

        .. note::
            Extra requirements apply to the provided memory resources
            (see :ref:`Custom memory resources` for details).

        .. note::
            In complex cases that require extra temporary copies, NDBuffer may ignore the
            non-blocking flag and decide to explicitly synchronize the stream.

        .. note::
            For H2D async copies, NDBuffer explicitly copies the src memory to
            temporary host buffer in order to ensure that the src memory is safe to
            write to immediately after the `copy_` call returns."""
    def fill_(self, value, stream=..., logger=..., boolblocking: bool | None = ...) -> Any:
        """NDBuffer.fill_(self, value, *, stream=None, logger=None, bool blocking: bool | None = None)

        Fills the current NDBuffer with the given value (scalar, list, numpy array, etc.).

        The ``value`` must be convertible to a numpy array of the same dtype as the current
        NDBuffer's dtype, and broadcastable to the current NDBuffer's shape.

        .. note::
            The NDBuffer's dtype must be supported by numpy in order to use this method.
            For unsupported dtypes, use the :meth:`~NDBuffer.copy_` method instead."""
    def item(self, stream=...) -> Any:
        """NDBuffer.item(self, *, stream=None)

        For a tensor of volume 1, returns the scalar value as Python object.
        If the tensor is in device memory, a stream must be provided - there
        will be a blocking copy to the host scheduled on that stream.

        .. note::
            The NDBuffer's dtype must be supported by numpy in order to use this method."""
    def permute(self, tuplepermutation: tuple[int], boolinverse: bool = ...) -> NDBuffer:
        """NDBuffer.permute(self, tuple permutation: tuple[int], bool inverse: bool = False) -> NDBuffer

        Returns an NDBuffer that is a view of the same data, but with the shape and
        strides permuted according to ``permutation``.

        Parameters
        ----------
        permutation : tuple[int]
            The permutation of axes to apply.
        inverse : bool
            If True, the inverse permutation is applied (equivalently, permuting the
            result by ``permutation`` yields the original layout). Defaults to False.


        See also: :meth:`StridedLayout.permuted`."""
    def repack(self, dtype: str | _numpy.dtype, intitemsize: int | None = ..., intaxis=...) -> NDBuffer:
        """NDBuffer.repack(self, dtype: str | _numpy.dtype, int itemsize: int | None = None, int axis=-1) -> NDBuffer

        Returns a NDBuffer that is a view of the same data, but with a new dtype and itemsize.
        The shape and strides are adjusted accordingly.
        Raises ValueError if the new dtype is not compatible with the current layout.

        Parameters
        ----------
        dtype : str | numpy.dtype
            The dtype of the returned view.
        itemsize : int | None
            A hint for the repacking case. If not provided, it is inferred from
            ``dtype`` (via numpy). Omitting it raises an error if the dtype is not supported
            by numpy.
        axis : int
            The axis along which elements are packed/unpacked. Defaults to the last axis.


        See also: :meth:`StridedLayout.packed` and :meth:`StridedLayout.unpacked`."""
    def reshape(self, shape: tuple[int] | int | StridedLayout) -> NDBuffer:
        """NDBuffer.reshape(self, shape: tuple[int] | int | StridedLayout) -> NDBuffer

        Returns a NDBuffer that is a view of the same data, but with a new shape.

        .. note::
            This method behaves similarly to numpy's ``reshape(..., copy=False)``, i.e.
            it never allocates or copies the data, it only creates a new
            view of the existing data. It will raise ValueError if the new shape
            is not compatible with the current layout.

        The new shape is compatible if:

        * the new and old shapes have the same volume,
        * the old strides can be split or flattened to match the new shape,
            assuming indices are iterated in C-order.

        A single extent in ``shape`` can be set to ``-1`` to indicate it should be
        inferred from the old volume and the other extents.

        Parameters
        ----------
        shape : tuple[int] | int | StridedLayout
            The new shape. If a :class:`StridedLayout` is passed, its shape is used.


        See also: :meth:`StridedLayout.reshaped`."""
    def squeeze(self, axis: int | tuple[int] | None = ..., intmask: int | None = ...) -> NDBuffer:
        """NDBuffer.squeeze(self, axis: int | tuple[int] | None = None, int mask: int | None = None) -> NDBuffer

        Returns an NDBuffer that is a view of the same data, but with the selected unit
        dimensions (extents equal to 1) removed.

        To limit which axes are considered for squeezing, use one of the ``axis`` or
        ``mask`` parameters. If neither is provided, all unit dimensions are removed.

        Parameters
        ----------
        axis : int | tuple[int] | None
            The axis or axes to consider for squeezing.
        mask : int | None
            Alternative to ``axis``: a bitmask selecting the axes to consider for squeezing.


        See also: :meth:`StridedLayout.squeezed`."""
    def transpose(self, intaxis_a: int, intaxis_b: int) -> NDBuffer:
        """NDBuffer.transpose(self, int axis_a: int, int axis_b: int) -> NDBuffer

        Returns an NDBuffer that is a view of the same data, but with the two specified
        axes swapped.

        Parameters
        ----------
        axis_a, axis_b : int
            The two axes to swap.


        See also: :meth:`StridedLayout.transposed`."""
    def unsqueeze(self, axis: int | tuple[int] | None = ..., intmask: int = ...) -> NDBuffer:
        """NDBuffer.unsqueeze(self, axis: int | tuple[int] | None = None, int mask: int = 0) -> NDBuffer

        Returns an NDBuffer that is a view of the same data, but with unit extents
        (extents equal to 1) added at the selected positions.

        Parameters
        ----------
        axis : int | tuple[int] | None
            The position(s) at which to insert the new unit extents. It can be either
            a single integer in range ``[0, ndim]`` or a tuple of
            unique integers in range ``[0, ndim + len(axis) - 1]``.
        mask : int
            Alternative to ``axis``: a bitmask selecting the positions
            of the new unit extents.


        See also: :meth:`StridedLayout.unsqueezed`."""
    def view(self, shape_or_dtype, intitemsize: int | None = ...) -> NDBuffer:
        """NDBuffer.view(self, shape_or_dtype, int itemsize: int | None = None) -> NDBuffer

        Convenience method aiming to match the numpy.ndarray/torch.view methods,
        it either reshapes or repacks the current NDBuffer to the new shape or dtype.

        Parameters
        ----------
        shape_or_dtype : tuple[int] | int | str | numpy.dtype
            The new shape or dtype. If a tuple, it is interpreted as a new shape and the
            call is equivalent to :meth:`~NDBuffer.reshape`.
            Otherwise, the argument must be a dtype name string or a numpy.dtype object
            and the call is equivalent to :meth:`~NDBuffer.repack`.
        itemsize : int | None
            A hint for the repacking case. If not provided, it is inferred from
            ``dtype`` (via numpy). Omitting it raises an error if the dtype is not supported
            by numpy.


        See also: :meth:`~NDBuffer.reshape` and :meth:`~NDBuffer.repack`."""
    def __delitem__(self, other) -> None:
        """Delete self[key]."""
    def __eq__(self, other) -> Any:
        """NDBuffer.__eq__(self, other)

        The default (equality is identity) comparison can be misleading.
        User may expect number of meanings here:
        * identity comparison
        * compare meta-data, allocation and layout
        * diapatch elementwise comparison (and possibly reduce the result for vol > 1).

        Until we decide if any of those meanings is useful and worth implementing,
        we return NotImplementedError to force Python to raise an error
        rather than fallback to identity or try ``__eq__`` method from ``other``

        .. note::
            As an example, take NDBuffer and ``ndbuffer[i] == 3`` expression.
            Clearly, one can expect that the expression compares data stored
            in the memory at index ``i``, while the default comparison would
            silently always evaluate to False. For now, to compare single
            element, one can use the :meth:`~NDBuffer.item` method
            (i.e. ``ndbuffer.item() == 3``).

        .. note::
            As we override the ``__eq__`` method, the object is not hashable.
            This is intentional and is unlikely to change even if we decide to implement
            comparison. Hashing requires immutability, so if equality involves
            comparing the values stored in the tensor, we cannot have hashing."""
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
    def __reduce__(self):
        """NDBuffer.__reduce_cython__(self)"""
    def __reduce_cython__(self) -> Any:
        """NDBuffer.__reduce_cython__(self)"""
    def __setitem__(self, slices: int | slice | tuple[int | slice], value) -> Any:
        '''NDBuffer.__setitem__(self, slices: int | slice | tuple[int | slice], value)

        Assigns the value to (possibly a slice of) the tensor.

        .. warning::
            Both the NDBuffer being assigned to and the assigned value
            must reside on the host. Note, there\'s no "default stream" for
            NDBuffers, so any device memory accesses require an explicit
            cuda stream, which is not supported with the assignment syntax.
            For those cases, please use the copy_ or fill_ methods.'''
    def __setstate_cython__(self, __pyx_state) -> Any:
        """NDBuffer.__setstate_cython__(self, __pyx_state)"""

class _NDBufferAsBufferProxy:
    """
    Proxy class that exposes the underlying host allocation as flat (1D) Python buffer.

    .. note::
        Defining the __getbuffer__ implicitly makes the created buffer object
        reference the exporting object (the one that defines the __getbuffer__),
        If the __getbuffer__ was defined on the NDBuffer itself, we'd end up
        with a circular dependency:
        NDBuffer -> NDBuffer.numpy_view -> buffer object -> NDBuffer
    """
    @classmethod
    def __init__(cls, *args, **kwargs) -> None:
        """Create and return a new object.  See help(type) for accurate signature."""
    def __buffer__(self, *args, **kwargs):
        """Return a buffer object that exposes the underlying memory of the object."""
    def __reduce__(self):
        """_NDBufferAsBufferProxy.__reduce_cython__(self)"""
    def __reduce_cython__(self) -> Any:
        """_NDBufferAsBufferProxy.__reduce_cython__(self)"""
    def __setstate_cython__(self, __pyx_state) -> Any:
        """_NDBufferAsBufferProxy.__setstate_cython__(self, __pyx_state)"""
