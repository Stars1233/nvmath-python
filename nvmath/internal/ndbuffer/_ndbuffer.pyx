# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

cimport cython
from cpython.buffer cimport PyBuffer_FillInfo, Py_buffer
from libc.stdint cimport int64_t, intptr_t
from .._layout._layout cimport (
    axis_vec_t, stride_t, OrderFlag,
)
from ..memory cimport (
    get_default_stream, get_device_memory_resource,
    get_pinned_async_memory_resource, allocate_from_mr,
)
from .._bindings cimport memcpy_async, memset_async, stream_sync
from ._copy_kernel cimport launch_copy_kernel

import threading

import numpy as _numpy

from cuda.core import Stream


cdef extern from "../include/_nd_consts.hpp":
    cdef const int NDBUFFER_CPU_DEVICE_ID


thread_local = threading.local()


@cython.final
cdef class NDBuffer:
    """
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
        argument to the memory resource's ``mr.allocate(size, stream=stream)`` method and returns
        the new allocation to the caller via :attr:`NDBuffer.data`.

        In all cases, NDBuffer assumes that (currently or for the sake of future compatibility):

        * Allocations with non-None stream ``mr.allocate(size, stream=stream)`` are scheduled
          on the provided stream and, by default, deallocation is scheduled on the same stream
          (if not overridden with ``allocation.close(other_stream)``)
        * Allocations with None stream ``mr.allocate(size, stream=None)`` are host-synchronous
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

          - The stream passed to ``mr.allocate(size, stream=stream)``
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
        The layout of the NDBuffer.
    """

    @classmethod
    def from_data(cls, StridedLayout layout, data, intptr_t data_ptr, dtype : str | _numpy.dtype, device_id : Literal["cpu"] | int):
        """
        Creates a new NDBuffer instance that views the ``data`` as tensor with the given ``layout`` and ``dtype``.

        The ``data_ptr`` must point to valid address in memory held by the ``data`` buffer that is
        aligned to the dtype (itemsize) and is accessible from the specified device.
        Logically, it is the address of element at index ``(0, ) * ndim``.

        .. warning::
            There are no checks performed whether the data is compatible with the layout or the dtype.
        """
        cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
        cdef str dtype_name = _get_dtype_name(dtype)
        _check_dtype_itemsize_compatibility(dtype_name, layout.base.itemsize)
        out.init_from_data(layout, data, data_ptr, dtype_name, _get_device_id(device_id))
        return out

    @classmethod
    def from_numpy(cls, object array) -> NDBuffer:
        """
        Creates a new NDBuffer instance that is a view of the numpy array
        (shares the same data allocation and infers meta-data (shape, strides, dtype) from the array).
        """
        return view_of_numpy(array)

    @classmethod
    def from_cupy(cls, object array) -> NDBuffer:
        """
        Creates a new NDBuffer instance that is a view of the cupy array
        (shares the same data allocation and infers meta-data (shape, strides, dtype) from the array).
        """
        return view_of_cupy(array)

    @classmethod
    def empty(cls, layout : StridedLayout | tuple[int] | int, dtype : str | _numpy.dtype, device_id : Literal["cpu"] | int, *, object stream=None, object memory_resource=None, object logger=None) -> NDBuffer:
        """
        Allocates memory on the specified device based on the given ``layout`` and ``dtype``.
        Returns a new NDBuffer that views the allocated memory.

        If, instead of the StridedLayout, a tuple is provided as ``layout``, it is
        interpreted as a shape and the resulting layout is C-contiguous, with the given
        shape and itemsize inferred from the dtype.

        .. note::
            If dtype is not supported by numpy, it must be specified as a string
            and layout must be a StridedLayout, specifying the dtype's itemsize.

        .. note::
            The layout is converted to contiguous (keeping the stride order) if not already contiguous.
        """
        cdef str dtype_name = _get_dtype_name(dtype)
        cdef StridedLayout layout_obj
        if type(layout) is StridedLayout:
            layout_obj = (<StridedLayout>layout).get_to_dense(OrderFlag.ORDER_NONE, NULL)
        else:
            layout_obj = StridedLayout.dense(layout, _name_to_dtype(dtype_name).itemsize)
        return allocate_empty(layout_obj, _get_dtype_name(dtype), _get_device_id(device_id), stream, memory_resource, logger)

    @classmethod
    def empty_like(cls, NDBuffer other, device_id : Literal["cpu"] | int | None = None, *, object stream=None, object memory_resource=None, object logger=None, stride_order : Literal["C", "F", "K"] | tuple[int] | None = "K") -> NDBuffer:
        """
        Allocates memory on the specified device based on the other NDBuffer's layout and dtype.
        If not provided, the device id is the same as the other NDBuffer's device id.

        .. note::
            The layout is converted to contiguous (with stride order specified by the ``stride_order`` argument)
            if not already contiguous (in the specified order).
        """
        cdef StridedLayout layout = other.layout.to_dense(stride_order=stride_order)
        cdef int data_device_id = _get_device_id(device_id) if device_id is not None else other.data_device_id
        return allocate_empty(layout, other.dtype_name, data_device_id, stream, memory_resource, logger)

    def __init__(self, *args, **kwargs):
        """
        Don't instantiate NDBuffer directly. Use the following class methods instead:

        * To create a view over existing data, use :meth:`~NDBuffer.from_data`, :meth:`~NDBuffer.from_numpy` or :meth:`~NDBuffer.from_cupy` instead.
        * To allocate new memory, use :meth:`~NDBuffer.empty`, :meth:`~NDBuffer.empty_like`.
        """
        raise NotImplementedError("Don't instantiate NDBuffer directly, use from_data, from_numpy or empty instead")

    def __repr__(self):
        cdef intptr_t data_ptr = self.data_ptr
        cdef intptr_t base_ptr = _base_ptr(self.data_ptr, self.layout)
        cdef str ptr
        if data_ptr == base_ptr:
            ptr = f"ptr={data_ptr}"
        else:
            ptr = f"ptr={data_ptr}, base_ptr={base_ptr}"
        return (
            f"NDBuffer({ptr}, dtype_name={self.dtype_name}, device_id={self.device_id}, layout={self.layout})"
        )

    def __eq__(self, other):
        """
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
            comparing the values stored in the tensor, we cannot have hashing.

        """
        raise NotImplementedError

    def __len__(self):
        return self.layout.get_len()

    def __getitem__(self, slices : int | slice | tuple[int | slice]) -> NDBuffer:
        return get_sliced_view(self, slices)

    def __setitem__(self, slices : int | slice | tuple[int | slice], value):
        """
        Assigns the value to (possibly a slice of) the tensor.

        .. warning::
            Both the NDBuffer being assigned to and the assigned value
            must reside on the host. Note, there's no "default stream" for
            NDBuffers, so any device memory accesses require an explicit
            cuda stream, which is not supported with the assignment syntax.
            For those cases, please use the copy_ or fill_ methods.
        """
        cdef NDBuffer dst = get_sliced_view(self, slices)
        if type(value) is NDBuffer:
            copy_into(dst, value, None, None, None, None, None)
        else:
            dst.fill_(value)

    def copy_(self, NDBuffer src, *, object stream=None, object host_memory_resource=None, object device_memory_resource=None, object logger=None, blocking: bool | None=None):
        """
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
            write to immediately after the `copy_` call returns.

        """
        copy_into(self, src, stream, blocking, host_memory_resource, device_memory_resource, logger)


    def fill_(self, value, *, object stream=None, object logger=None, blocking: bool | None=None):
        """
        Fills the current NDBuffer with the given value (scalar, list, numpy array, etc.).

        The ``value`` must be convertible to a numpy array of the same dtype as the current
        NDBuffer's dtype, and broadcastable to the current NDBuffer's shape.

        .. note::
            The NDBuffer's dtype must be supported by numpy in order to use this method.
            For unsupported dtypes, use the :meth:`~NDBuffer.copy_` method instead.

        """
        cdef NDBuffer other = NDBuffer.from_numpy(_numpy.array(value, dtype=_name_to_dtype(self.dtype_name)))
        copy_into(self, other, stream, blocking, None, None, logger)

    @property
    def dtype(self) -> str:
        """
        Alias for dtype_name string.
        """
        return self.dtype_name

    @property
    def numpy_dtype(self) -> _numpy.dtype:
        """
        The numpy dtype of the NDBuffer's data. Raises TypeError if the dtype is not supported by numpy.
        """
        return _name_to_dtype(self.dtype_name)

    @property
    def itemsize(self):
        """
        The itemsize of the NDBuffer's dtype.
        """
        return self.layout.base.itemsize

    @property
    def ndim(self):
        """
        The number of dimensions of the NDBuffer's shape.
        """
        return self.layout.base.ndim

    @property
    def device(self):
        """
        The device kind of the allocated memory: "cpu" or "cuda".
        """
        if self.prop_device is None:
            self.prop_device = "cpu" if self.data_device_id == NDBUFFER_CPU_DEVICE_ID else "cuda"
        return self.prop_device

    @property
    def device_id(self):
        """
        The device id of the allocated memory: "cpu" or non-negative integer.
        """
        if self.prop_device_id is None:
            self.prop_device_id = "cpu" if self.data_device_id == NDBUFFER_CPU_DEVICE_ID else self.data_device_id
        return self.prop_device_id

    @property
    def strides(self):
        """
        The strides of the NDBuffer's layout (in counts, not bytes).
        """
        return self.layout.get_strides_tuple()

    @property
    def strides_in_bytes(self):
        """
        The strides of the NDBuffer's layout (in bytes).
        """
        return self.layout.get_strides_in_bytes_tuple()

    @property
    def shape(self):
        """
        The shape of the NDBuffer's layout.
        """
        return self.layout.get_shape_tuple()

    @property
    def size(self):
        """
        The volume of the NDBuffer's layout.
        """
        return self.layout.get_volume()

    @property
    def raw_memory_range_info(self):
        """
        Returns a triple of (base_ptr, size_in_bytes, offset_in_bytes), such that
        all elements of the NDBuffer are within the memory range
        ``[base_ptr, base_ptr + size_in_bytes - 1]`` and the address of
        the element at index ``(0, ) * ndim`` is ``base_ptr + offset_in_bytes``.
        """
        cdef intptr_t base_ptr = 0
        cdef int64_t size_in_bytes = 0
        cdef int64_t offset = 0
        _memory_range(base_ptr, size_in_bytes, offset, self.data_ptr, self.layout)
        return base_ptr, size_in_bytes, offset

    def as_numpy(self):
        """
        Returns a numpy array view of the NDBuffer's data, with the same
        shape, strides, and dtype as the NDBuffer.
        """
        return view_as_numpy(self)

    def item(self, *, object stream=None):
        """
        For a tensor of volume 1, returns the scalar value as Python object.
        If the tensor is in device memory, a stream must be provided - there
        will be a blocking copy to the host scheduled on that stream.

        .. note::
            The NDBuffer's dtype must be supported by numpy in order to use this method.

        """
        return get_item(self, stream)

    def as_strided(self, StridedLayout layout = None, dtype : str | _numpy.dtype | None = None, offset_in_bytes : int = 0, check_bounds : bool = True) -> NDBuffer:
        """
        Returns a NDBuffer that views the same memory/data, but with a new layout
        and dtype, similar to `numpy.lib.stride_tricks.as_strided`, or `torch.as_strided`.

        If specified, ``offset_in_bytes`` is the number of bytes to offset the current data pointer by.

        If the ``check_bounds`` flag is set to True, the method will compare memory range
        of the new layout with the memory range of the current instance's base
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

            # This won't work with check_bounds true because NDBuffer doesn't know about
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
            assert NDBuffer.from_numpy(a[1:]).layout == wider_view.layout

        """
        return get_as_strided_view(self, layout, _get_dtype_name(dtype), offset_in_bytes, check_bounds)

    def view(self, object shape_or_dtype, itemsize : int | None = None) -> NDBuffer:
        """
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


        See also: :meth:`~NDBuffer.reshape` and :meth:`~NDBuffer.repack`.
        """
        if isinstance(shape_or_dtype, int | tuple | list):
            if itemsize is not None:
                raise ValueError("The itemsize argument is not supported for reshaping")
            return self.reshape(shape_or_dtype)
        else:
            return self.repack(shape_or_dtype, itemsize)

    def reshape(self, shape : tuple[int] | int | StridedLayout) -> NDBuffer:
        """
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


        See also: :meth:`StridedLayout.reshaped`.
        """
        return get_or_create_view(self, self.layout.reshaped(shape))

    def repack(self, dtype : str | _numpy.dtype, itemsize : int | None = None, int axis=-1) -> NDBuffer:
        """
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


        See also: :meth:`StridedLayout.packed` and :meth:`StridedLayout.unpacked`.
        """
        cdef str dtype_name = _get_dtype_name(dtype)
        if itemsize is None:
            itemsize = _name_to_dtype(dtype_name).itemsize
        else:
            itemsize = int(itemsize)

        cdef int current_itemsize = self.layout.base.itemsize
        if itemsize == current_itemsize:
            if dtype_name == self.dtype_name:
                return self
            return create_view(self, self.layout, dtype_name)

        cdef StridedLayout new_layout
        if itemsize > current_itemsize:
            new_layout = self.layout.get_packed(itemsize, self.data_ptr, axis)
        else:
            new_layout = self.layout.get_unpacked(itemsize, axis)
        return create_view(self, new_layout, dtype_name)

    def broadcast_to(self, layout : tuple[int] | int | StridedLayout) -> NDBuffer:
        """
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


        See also: :meth:`StridedLayout.broadcast_to`.
        """
        return get_or_create_view(self, self.layout.broadcast_to(layout))

    def permute(self, permutation : tuple[int], inverse : bool = False) -> NDBuffer:
        """
        Returns an NDBuffer that is a view of the same data, but with the shape and
        strides permuted according to ``permutation``.

        Parameters
        ----------
        permutation : tuple[int]
            The permutation of axes to apply.
        inverse : bool
            If True, the inverse permutation is applied (equivalently, permuting the
            result by ``permutation`` yields the original layout). Defaults to False.


        See also: :meth:`StridedLayout.permuted`.
        """
        return get_or_create_view(self, self.layout.permuted(permutation, inverse))

    def transpose(self, axis_a : int, axis_b : int) -> NDBuffer:
        """
        Returns an NDBuffer that is a view of the same data, but with the two specified
        axes swapped.

        Parameters
        ----------
        axis_a, axis_b : int
            The two axes to swap.


        See also: :meth:`StridedLayout.transposed`.
        """
        return get_or_create_view(self, self.layout.transposed(axis_a, axis_b))

    def squeeze(self, axis : int | tuple[int] | None = None, mask : int | None = None) -> NDBuffer:
        """
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


        See also: :meth:`StridedLayout.squeezed`.
        """
        return get_or_create_view(self, self.layout.squeezed(axis, mask))

    def unsqueeze(self, axis : int | tuple[int] | None = None, mask : int = 0) -> NDBuffer:
        """
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


        See also: :meth:`StridedLayout.unsqueezed`.
        """
        return get_or_create_view(self, self.layout.unsqueezed(axis, mask))


cdef class _NDBufferAsBufferProxy:
    """
    Proxy class that exposes the underlying host allocation as flat (1D) Python buffer.

    .. note::
        Defining the __getbuffer__ implicitly makes the created buffer object
        reference the exporting object (the one that defines the __getbuffer__),
        If the __getbuffer__ was defined on the NDBuffer itself, we'd end up
        with a circular dependency:
        NDBuffer -> NDBuffer.numpy_view -> buffer object -> NDBuffer
    """
    cdef intptr_t base_ptr
    cdef int64_t length
    cdef object data

    def __getbuffer__(self, Py_buffer *view, int flags):
        """
        Exposes the underlying host allocation as flat (1D) Python buffer.

        .. hint::
            To get a numpy array view, use the :meth:`~NDBuffer.as_numpy` method instead.
        """
        PyBuffer_FillInfo(view, self.data, <void*>self.base_ptr, self.length, 0, flags)


cdef object _view_as_numpy(NDBuffer ndbuf):
    """
    Creates a numpy view over the NDBuffer's data.

    The created view is cached as internal NDBuffer attribute.
    This function falls back to any dtype with matching itemsize
    if the dtype name is not supported by numpy. If the view is meant
    for external use (returned to the user), use view_as_numpy instead.
    """
    cdef numpy_view = ndbuf.numpy_view
    if numpy_view is not None:
        return numpy_view
    if ndbuf.data_device_id != NDBUFFER_CPU_DEVICE_ID:
        raise ValueError("Cannot create a numpy view of a device tensor.")
    cdef StridedLayout layout = ndbuf.layout
    cdef dtype = _get_dtype_if_supported(ndbuf.dtype_name)
    cdef bint has_supported_dtype = True
    if dtype is None:
        # If the dtype name is not supported by numpy, use any dtype
        # of the same itemsize - for internal use it may be ok,
        # just mark this fact so that we don't return this view to the user
        dtype = _get_default_dtype(layout.base.itemsize)
        has_supported_dtype = False
    cdef int64_t offset = 0
    cdef _NDBufferAsBufferProxy buffer_proxy = _NDBufferAsBufferProxy.__new__(_NDBufferAsBufferProxy)
    _memory_range(buffer_proxy.base_ptr, buffer_proxy.length, offset, ndbuf.data_ptr, ndbuf.layout)
    buffer_proxy.data = ndbuf.data
    numpy_view = _numpy.ndarray(layout.shape, dtype, buffer_proxy, offset, layout.strides_in_bytes)
    ndbuf.numpy_view = numpy_view
    ndbuf.has_supported_dtype = has_supported_dtype
    return numpy_view


cdef object view_as_numpy(NDBuffer ndbuf):
    """
    A wrapper around _view_as_numpy for public use - it raises TypeError
    if the dtype is not supported by numpy.
    """
    cdef object numpy_view = _view_as_numpy(ndbuf)
    if not ndbuf.has_supported_dtype:
        raise TypeError(f"Unsupported dtype: {ndbuf.dtype_name}.")
    return numpy_view


cdef NDBuffer view_of_numpy(object array):
    cdef StridedLayout layout = StridedLayout.__new__(StridedLayout)
    layout.init_from_tuple(array.itemsize, array.shape, array.strides, divide_strides=True)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    out.init_from_data(layout, array, array.ctypes.data, _dtype_to_name(array.dtype), NDBUFFER_CPU_DEVICE_ID)
    out.numpy_view = array
    out.has_supported_dtype = True
    return out


cdef NDBuffer view_of_cupy(object array):
    cdef StridedLayout layout = StridedLayout.__new__(StridedLayout)
    layout.init_from_tuple(array.itemsize, array.shape, array.strides, divide_strides=True)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    out.init_from_data(layout, array, array.data.ptr, _dtype_to_name(array.dtype), array.device.id)
    return out


cdef NDBuffer allocate_empty(StridedLayout layout, str dtype_name, int device_id, object stream=None, object memory_resource=None, object logger=None):
    """
    Allocates new memory and creates a NDBuffer instance that views it,
    matching the provided layout and dtype.

    In contrast to public methods such as :meth:`~NDBuffer.empty`, this function
    does not convert the provided layout to enforce it being dense.
    Instead, it checks weaker condition (no gaps in the layout) and errors
    out if the layout is not exhaustive. This allows to allocate "compact"
    tensors (such as having broadcast layouts) as internal temporary buffers.
    """
    if not layout.get_is_exhaustive():
        raise ValueError(f"Cannot allocate an empty tensor with non-exhaustive layout: {layout}")
    _check_dtype_itemsize_compatibility(dtype_name, layout.base.itemsize)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    cdef int64_t size = layout.get_memory_range_size_in_bytes()
    cdef intptr_t base_ptr = 0
    cdef object data = _allocate_data(base_ptr, device_id, size, memory_resource, stream, logger)
    out.init_from_data(layout, data, _data_ptr(base_ptr, layout), dtype_name, device_id)
    if logger is not None:
        logger.debug(f"Allocated empty tensor of size {size} bytes: {out}")
    return out


cdef NDBuffer create_view(NDBuffer ndbuf, StridedLayout layout=None, str dtype_name=None):
    """
    Create a new view of the data in the ``ndbuf``, making sure the new view
    keeps reference to original base NDBuffer.
    """
    if layout is None:
        layout = ndbuf.layout
    if dtype_name is None:
        dtype_name = ndbuf.dtype_name
    _check_dtype_itemsize_compatibility(dtype_name, layout.base.itemsize)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    out.init_from_data(layout, ndbuf.data, ndbuf.data_ptr, dtype_name, ndbuf.data_device_id)
    out.base = ndbuf if ndbuf.base is None else ndbuf.base
    return out


cdef NDBuffer get_or_create_view(NDBuffer ndbuf, StridedLayout layout=None, str dtype_name=None):
    """
    If the layout or dtype is different from the original NDBuffer, create a new view.
    Otherwise, return the original NDBuffer.
    """
    if layout is None:
        layout = ndbuf.layout
    if dtype_name is None:
        dtype_name = ndbuf.dtype_name
    if layout is ndbuf.layout and dtype_name == ndbuf.dtype_name:
        return ndbuf
    _check_dtype_itemsize_compatibility(dtype_name, layout.base.itemsize)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    out.init_from_data(layout, ndbuf.data, ndbuf.data_ptr, dtype_name, ndbuf.data_device_id)
    out.base = ndbuf if ndbuf.base is None else ndbuf.base
    return out


cdef NDBuffer get_as_strided_view(NDBuffer ndbuf, StridedLayout layout, str dtype_name, int64_t offset_in_bytes, bint check_bounds):
    """
    Implements the .as_strided() method for NDBuffers.
    """
    if layout is None:
        layout = ndbuf.layout
    if dtype_name is None:
        dtype_name = ndbuf.dtype_name
    if offset_in_bytes == 0 and layout is ndbuf.layout and dtype_name == ndbuf.dtype_name:
        return ndbuf
    _check_dtype_itemsize_compatibility(dtype_name, layout.base.itemsize)
    if check_bounds:
        _as_strided_check_bounds(ndbuf, layout, offset_in_bytes)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    out.init_from_data(layout, ndbuf.data, ndbuf.data_ptr + offset_in_bytes, dtype_name, ndbuf.data_device_id)
    out.base = ndbuf if ndbuf.base is None else ndbuf.base
    return out


cdef NDBuffer get_sliced_view(NDBuffer ndbuf, object slices):
    """
    Implements the [] operator for NDBuffers.
    """
    cdef stride_t slice_offset = 0
    cdef StridedLayout sliced = ndbuf.layout.get_sliced(slice_offset, slices)
    if slice_offset == 0:
        return get_or_create_view(ndbuf, sliced)
    cdef NDBuffer out = NDBuffer.__new__(NDBuffer)
    cdef int itemsize = ndbuf.layout.base.itemsize
    cdef intptr_t new_data_ptr = ndbuf.data_ptr + slice_offset * itemsize
    out.init_from_data(sliced, ndbuf.data, new_data_ptr, ndbuf.dtype_name, ndbuf.data_device_id)
    out.base = ndbuf if ndbuf.base is None else ndbuf.base
    return out


cdef object get_item(NDBuffer ndbuf, object stream=None):
    """
    Implements the .item() method for NDBuffers.
    """
    if ndbuf.data_device_id == NDBUFFER_CPU_DEVICE_ID:
        return view_as_numpy(ndbuf).item()
    if stream is None:
        raise ValueError("A stream must be provided for device tensor item access.")
    stream = _get_stream_obj(stream)
    cdef intptr_t stream_ptr = int(stream.handle)
    cdef StridedLayout layout = ndbuf.layout
    if layout.get_volume() != 1:
        raise ValueError("Only tensors of volume 1 can be converted to a Python scalar.")
    cdef np_scalar = _numpy.empty((), dtype=_name_to_dtype(ndbuf.dtype_name))
    memcpy_async(np_scalar.ctypes.data, ndbuf.data_ptr, layout.base.itemsize, stream_ptr)
    stream_sync(stream_ptr)
    return np_scalar.item()


cdef int _copy_into_d2d(NDBuffer dst, NDBuffer src, object stream, bint blocking, object logger=None) except -1:
    """
    Launches a D2D copy between two NDBuffers.
    Checks if the copy can be done with a simple memcopy, otherwise dispatches
    a copy kernel.
    """
    if stream is None:
        raise ValueError("A stream must be provided for D2D copy.")
    cdef intptr_t stream_ptr = int(stream.handle)

    cdef StridedLayout dst_layout = dst.layout
    cdef StridedLayout src_layout = src.layout
    cdef intptr_t dst_data_ptr = dst.data_ptr
    cdef intptr_t src_data_ptr = src.data_ptr

    cdef int64_t size
    if dst_layout.get_is_exhaustive() and dst_layout.is_almost_equal(src_layout):
        size = dst_layout.get_memory_range_size_in_bytes()
        if logger is not None:
            logger.debug(
                f"The dst and src layouts match and are exhaustive. "
                f"Launching direct D2D memcpy.\n"
                f"Memcpy of {size} bytes on stream {stream_ptr}: dst: {dst} <- src: {src}"
            )
        memcpy_async(_base_ptr(dst_data_ptr, dst_layout), _base_ptr(src_data_ptr, src_layout), size, stream_ptr)
    else:
        launch_copy_kernel(dst_layout, src_layout, dst_data_ptr, src_data_ptr, dst.data_device_id, stream_ptr, logger)
    if blocking:
        if logger is not None:
            logger.debug(f"Sync stream {stream_ptr} after D2D memcpy.")
        stream_sync(stream_ptr)
    return 0


cdef int _copy_into_d2h(NDBuffer dst, NDBuffer src, object stream, bint blocking, object host_memory_resource, object device_memory_resource, object logger) except -1:
    """
    Launches a D2H copy from device NDBuffer into host NDBuffer.

    The `host_memory_resource` and `device_memory_resource` are used to allocate temporary
    intermediate buffers if those are needed. If not provided, default memory resources
    are used.
    """
    if stream is None:
        raise ValueError("A stream must be provided for D2H copy.")
    cdef intptr_t stream_ptr = int(stream.handle)

    # We may need up to two extra intermediate copies.
    # The plan is:
    # 1. (optional) device -> device - if we need to coalesce the
    #    src layout before memcpy, or transpose the strides order
    #    to match dst
    # 2. (always) memcopy device -> host
    # 3. (optional) host -> host - if the result of the memcopy still
    #    doesn't match the dst layout - the data needs to be scattered
    cdef NDBuffer tmp

    cdef StridedLayout dst_layout = dst.layout
    cdef StridedLayout src_layout = src.layout
    cdef axis_vec_t dst_stride_order
    dst_layout.get_stride_order(dst_stride_order)

    # We launch extra device-to-device copy if:
    # - we need to coalesce the src (it's non-exhaustive, i.e. it has gaps), or
    # - the src has a different stride order than the dst
    #   here, we assume that the transposing copy while generally expensive
    #   should perform better as D2D than H2H, so we launch it while data is still on the device.
    #   Note, we only do so if the src is unique, otherwise converting src to dense layout
    #   would materialize temporary device tensor larger than the src (we try to
    #   to optimize the broadcast-src case, but layout can be non-unique in other
    #   ways, like sliding-overlapping window).
    if not src_layout.get_is_exhaustive() or (
        src_layout.get_is_unique() and
        not src_layout.get_has_stride_order(OrderFlag.ORDER_PERM, &dst_stride_order)
    ):
        # Optimization for broadcast layouts - replace broadcast extents with unit extents,
        # to keep the temporary copy "compact".
        src = get_or_create_view(src, src_layout.get_unbroadcast())
        src_layout = src.layout
        tmp = allocate_empty(src_layout.get_to_dense(OrderFlag.ORDER_PERM, &dst_stride_order), src.dtype_name, src.data_device_id, stream, device_memory_resource, logger)
        if logger is not None:
            logger.debug(
                f"Src is not exhaustive or has a different strides order, "
                f"performing a coalescing/transposing copy into temporary buffer.\n"
                f"tmp: {tmp} <- src: {src}"
            )
        _copy_into_d2d(tmp, src, stream, False, logger)
        src = get_or_create_view(tmp, tmp.layout.get_broadcast(dst_layout.base))
        src_layout = src.layout

    cdef int64_t size = src_layout.get_memory_range_size_in_bytes()

    if dst_layout.is_almost_equal(src_layout):
        if logger is not None:
            logger.debug(
                f"The dst and src layouts match. Launching direct D2H memcpy.\n"
                f"Memcpy of {size} bytes on stream {stream_ptr}: dst: {dst} <- src: {src}"
            )
        memcpy_async(_base_ptr(dst.data_ptr, dst_layout), _base_ptr(src.data_ptr, src_layout), size, stream_ptr)
        if blocking:
            if logger is not None:
                logger.debug(f"Sync stream {stream_ptr} after memcpy.")
            stream_sync(stream_ptr)
        return 0

    if not blocking:
        blocking = True
        if logger is not None:
            logger.debug(
                "Note, the non-blocking flag is ignored, because dst's layout "
                "requires a scatter H2H copy at the end."
            )
    tmp = allocate_empty(src_layout, src.dtype_name, NDBUFFER_CPU_DEVICE_ID, None, host_memory_resource, logger)
    if logger is not None:
        logger.debug(
            f"The dst and src layouts differ. Launching D2H memcopy into "
            f"a temporary host buffer, followed by a H2H copy.\n"
            f"Memcpy of {size} bytes on stream {stream_ptr}: tmp: {tmp} <- src: {src}, followed by\n"
            f"H2H copy: dst: {dst} <- tmp: {tmp}"
        )
    memcpy_async(_base_ptr(tmp.data_ptr, tmp.layout), _base_ptr(src.data_ptr, src_layout), size, stream_ptr)
    if logger is not None:
        logger.debug(f"Sync stream {stream_ptr} after memcpy.")
    stream_sync(stream_ptr)
    _numpy.copyto(_view_as_numpy(dst), _view_as_numpy(tmp))
    return 0


cdef int _copy_into_h2d(NDBuffer dst, NDBuffer src, object stream, bint blocking, object host_memory_resource, object device_memory_resource, object logger) except -1:
    """
    Launches a H2D copy from host NDBuffer into device NDBuffer.

    The `host_memory_resource` and `device_memory_resource` are used to allocate temporary
    intermediate buffers if those are needed. If not provided, default memory resources
    are used.
    """

    if stream is None:
        raise ValueError("A stream must be provided for H2D copy.")
    cdef intptr_t stream_ptr = int(stream.handle)

    cdef StridedLayout dst_layout = dst.layout
    cdef StridedLayout src_layout = src.layout
    cdef int itemsize = src_layout.base.itemsize

    # Fast path for single scalar src, using memset.
    if _memset_compatible_itemsize(itemsize) and src_layout.get_memory_range_size() == 1 and dst_layout.get_is_exhaustive():
        # If src_layout is 1. the itemsize is supported by memset,
        # 2. just a single scalar (possibly broadcast), 3. the dst is exhaustive (no gaps)
        # we can use memset to set the entire dst to the scalar value.
        if logger is not None:
            logger.debug(
                f"The src is a single scalar, dispatching to cuMemsetD{itemsize * 8}.\n"
                f"Memset {dst_layout.get_memory_range_size()} elements on stream {stream_ptr}: dst: {dst} <- src: {src}"
            )
        memset_async(itemsize, _base_ptr(dst.data_ptr, dst_layout), _base_ptr(src.data_ptr, src_layout), dst_layout.get_memory_range_size(), stream_ptr)
        if blocking:
            if logger is not None:
                logger.debug(f"Sync stream {stream_ptr} after memset.")
            stream_sync(stream_ptr)
        return 0

    # We may need up to two extra intermediate copies.
    # The plan is:
    # 1. (optional) host -> host - if
    #    a. we need to coalesce the src layout before memcpy, or
    #    b. want async copy.
    #    We add the extra h2h copy irrespective of layout for non-blocking copy,
    #    to avoid issues with the caller overwriting the host buffer
    #    after the copy_ returns while memcpy is still in progress.
    # 2. (always) memcopy host -> device
    # 3. (optional) device -> device - if the result of the memcopy still
    #    doesn't match the dst layout - the data needs to be scattered
    #    or transposed
    cdef NDBuffer host_tmp = None
    cdef StridedLayout host_tmp_layout = None
    cdef NDBuffer device_tmp = None
    # If we need to allocate host temp buffer in non-blocking case,
    # we allocate it on a default stream and sync with it,
    # so that it is usable from the host, but deallocate on the
    # user-provided stream, so that the memory is not freeded until
    # the copy is complete.
    cdef object host_alloc_stream = None
    cdef int64_t src_size

    if not blocking and host_memory_resource is None:
        host_memory_resource = get_pinned_async_memory_resource(dst.data_device_id)
        if host_memory_resource is None:
            blocking = True
            if logger is not None:
                logger.debug(
                    "Note, the non-blocking flag is ignored, "
                    "because no host stream-oriented memory resource is available"
                )

    try:
        if not blocking or not src_layout.get_is_exhaustive():
            # Optimization for broadcast layouts - replace broadcast extents
            # with unit extents to try to keep the temporary copy "compact".
            src = get_or_create_view(src, src_layout.get_unbroadcast())
            src_layout = src.layout
            if src_layout.get_is_exhaustive():
                host_tmp_layout = src_layout
            else:
                # If the src is not exhaustive (has gaps), we want to coalesce it
                # but trying to keep the original stride order (ORDER_NONE)
                # (h2h transpose may be disproportionally slow compared to
                # doing it as D2D later).
                host_tmp_layout = src_layout.get_to_dense(OrderFlag.ORDER_NONE, NULL)
            if blocking:
                host_tmp = allocate_empty(
                    host_tmp_layout, src.dtype_name, src.data_device_id,
                    None, host_memory_resource, logger
                )
            else:
                host_alloc_stream = get_default_stream(dst.data_device_id)
                host_tmp = allocate_empty(
                    host_tmp_layout, src.dtype_name, src.data_device_id,
                    host_alloc_stream, host_memory_resource, logger
                )
                host_alloc_stream.sync()
            _numpy.copyto(_view_as_numpy(host_tmp), _view_as_numpy(src))
            if logger is not None:
                logger.debug(
                    f"Performing {'coalescing' if not src_layout.get_is_exhaustive() else 'staging'} "
                    f"H2H copy into temporary buffer.\nhost_tmp: {host_tmp} <- src: {src}"
                )
            src = get_or_create_view(host_tmp, host_tmp.layout.get_broadcast(dst_layout.base))
            src_layout = src.layout

        src_size = src_layout.get_memory_range_size_in_bytes()

        if dst_layout.is_almost_equal(src_layout):
            if logger is not None:
                logger.debug(
                    f"The dst and src layouts match. Launching direct H2D memcpy.\n"
                    f"Memcpy of {src_size} bytes on stream {stream_ptr}: dst: {dst} <- src: {src}"
                )
            memcpy_async(_base_ptr(dst.data_ptr, dst_layout), _base_ptr(src.data_ptr, src_layout), src_size, stream_ptr)
        else:
            device_tmp = allocate_empty(src_layout, src.dtype_name, dst.data_device_id, stream, device_memory_resource, logger)
            if logger is not None:
                logger.debug(
                    f"The dst and src layouts differ. Launching H2D memcopy into "
                    f"a temporary device buffer, followed by a D2D copy.\n"
                    f"Memcpy of {src_size} bytes on stream {stream_ptr}: device_tmp: {device_tmp} <- src: {src}, followed by\n"
                    f"D2D copy: dst: {dst} <- device_tmp: {device_tmp}"
                )
            memcpy_async(_base_ptr(device_tmp.data_ptr, device_tmp.layout), _base_ptr(src.data_ptr, src_layout), src_size, stream_ptr)
            _copy_into_d2d(dst, device_tmp, stream, False, logger)

    finally:
        if device_tmp is not None:
            device_tmp.data.close(stream)
        # check that we allocated host memory on a stream first
        # (don't try to "deallocate", e.g. a numpy array)
        if host_alloc_stream is not None and host_tmp is not None:
            host_tmp.data.close(stream)

        if blocking:
            if logger is not None:
                logger.debug(f"Sync stream {stream_ptr} at the end of H2D copy.")
            stream_sync(stream_ptr)
    return 0


cdef int copy_into(NDBuffer dst, NDBuffer src, object stream, blocking: bool | None, object host_memory_resource, object device_memory_resource, object logger) except -1:
    """
    Copies data from src to dst.

    By default, the D2D copies are non-blocking and D2H/H2D copies are blocking.
    This can be overridden with the ``blocking`` argument.
    Copying from host to host is always blocking, the ``blocking`` argument is ignored.
    """

    _check_dtype(dst, src)
    # Broadcast src to the dst:
    # * this validates if the shapes are compatible
    # * from now on, src and dst have equal shapes
    src = get_or_create_view(src, src.layout.get_broadcast(dst.layout.base))
    cdef StridedLayout dst_layout = dst.layout
    if not dst_layout.get_is_unique():
        raise ValueError(
            f"Copying into a non-unique tensor is not supported. "
            f"The destination tensor has a non-unique layout, i.e. "
            f"different tensor elements may be mapped to the same memory "
            f"location: {dst_layout}. "
        )
    # memory range size is zero iff the layout volume is zero.
    if dst_layout.get_memory_range_size_in_bytes() == 0:
        return 0

    if dst.data_device_id == NDBUFFER_CPU_DEVICE_ID and src.data_device_id == NDBUFFER_CPU_DEVICE_ID:
        _numpy.copyto(_view_as_numpy(dst), _view_as_numpy(src))
        return 0

    stream = _get_stream_obj(stream)
    cdef bint blocking_
    if dst.data_device_id == NDBUFFER_CPU_DEVICE_ID:
        blocking_ = blocking or blocking is None
        return _copy_into_d2h(dst, src, stream, blocking_, host_memory_resource, device_memory_resource, logger)
    elif src.data_device_id == NDBUFFER_CPU_DEVICE_ID:
        blocking_ = blocking or blocking is None
        return _copy_into_h2d(dst, src, stream, blocking_, host_memory_resource, device_memory_resource, logger)
    else:
        if src.data_device_id != dst.data_device_id:
            raise ValueError("The source and destination devices must be the same")
        blocking_ = blocking
        return _copy_into_d2d(dst, src, stream, blocking_, logger)



# ===============================
# Numpy utilities
# ===============================


cdef str _dtype_to_name(object dtype):
    """
    Cached mapping of ``numpy_dtype -> numpy_dtype.name``.
    Accessing numpy dtype's name is surprisingly slow,
    hence we cache the result.
    """
    # note, we're relying on the fact that
    # np.dtype is cp.dtype
    cdef dict dtype_to_name_cache
    try:
        dtype_to_name_cache = thread_local.dtype_to_name_cache
    except AttributeError:
        dtype_to_name_cache = {}
        thread_local.dtype_to_name_cache = dtype_to_name_cache

    cdef str dtype_name = dtype_to_name_cache.get(dtype)
    if dtype_name is None:
        dtype_name = _numpy.dtype(dtype).name
        dtype_to_name_cache[dtype] = dtype_name
    return dtype_name


cdef object _name_to_dtype(str dtype_name):
    """
    Cached mapping of ``numpy_dtype.name -> numpy.dtype(numpy_dtype.name)``.
    """
    cdef dict name_to_dtype_cache
    try:
        name_to_dtype_cache = thread_local.name_to_dtype_cache
    except AttributeError:
        name_to_dtype_cache = {}
        thread_local.name_to_dtype_cache = name_to_dtype_cache

    cdef object dtype = name_to_dtype_cache.get(dtype_name)
    if dtype is None:
        dtype = _numpy.dtype(dtype_name)
        name_to_dtype_cache[dtype_name] = dtype
    return dtype


cdef str _get_dtype_name(object dtype):
    if dtype is None or type(dtype) is str:
        return dtype
    return _dtype_to_name(dtype)


cdef int _check_dtype_itemsize_compatibility(str dtype_name, int itemsize) except -1:
    cdef object dtype = _get_dtype_if_supported(dtype_name)
    if dtype is not None and dtype.itemsize != itemsize:
        raise ValueError(
            f"The itemsize of the dtype and the layout must match. "
            f"Got dtype itemsize:{dtype.itemsize} and layout itemsize:{itemsize}"
        )
    return 0


cdef object _get_default_dtype(int itemsize):
    # Currently, StridedLayout enforces itemsize to be power of two
    # in 1..16 range. Adjust if that changes.
    if itemsize == 1:
        return _numpy.dtype("uint8")
    elif itemsize == 2:
        return _numpy.dtype("uint16")
    elif itemsize == 4:
        return _numpy.dtype("uint32")
    elif itemsize == 8:
        return _numpy.dtype("uint64")
    elif itemsize == 16:
        return _numpy.dtype("complex128")
    raise ValueError(f"Unsupported itemsize: {itemsize}")


cdef object _get_dtype_if_supported(str dtype_name):
    """
    Get numpy.dtype corresponding to the dtype_name string or None
    if it is not supported by numpy.
    """
    cdef dict supported_dtype_cache
    try:
        supported_dtype_cache = thread_local.supported_dtype_cache
    except AttributeError:
        supported_dtype_cache = {}
        thread_local.supported_dtype_cache = supported_dtype_cache

    cdef object dtype = supported_dtype_cache.get(dtype_name, False)
    if dtype is False:
        try:
            dtype = _numpy.dtype(dtype_name)
        except TypeError:
            dtype = None
        supported_dtype_cache[dtype_name] = dtype
    return dtype


cdef _empty_numpy_data(int64_t size):
    """
    Uses numpy empty array to allocate host buffer, this way we can rely on numpy's
    platform independent memory management and memory initialization.
    Using raw allocation, e.g. malloc with no initialization or no pooling
    degrades performance of pagable D2H copies.
    """
    cdef int64_t num_elements = (size + 15) // 16
    cdef object out = _numpy.empty(num_elements, dtype=_numpy.complex128)
    return out


# ===============================
# Other utilities
# ===============================


cdef inline _get_stream_obj(stream):
    if stream is None:
        return None
    elif type(stream) is Stream:
        return stream
    else:
        return stream.obj  # assume StreamHolder


cdef inline int _get_device_id(device_id : Literal["cpu"] | int):
    if device_id == "cpu":
        return NDBUFFER_CPU_DEVICE_ID
    elif device_id >= -1:
        return device_id
    else:
        raise ValueError(f"Invalid device id: {device_id}")


cdef object _allocate_data(intptr_t &out_data_ptr, int device_id, int64_t size, object memory_resource=None, object stream=None, object logger=None):
    """
    Allocate memory on the specified device from the provided
    memory resource or, if no resource is provided, from a
    device-dependent default memory resource.
    """
    if size == 0:
        out_data_ptr = 0
        return None
    cdef object data
    if memory_resource is None:
        if device_id == NDBUFFER_CPU_DEVICE_ID:
            data = _empty_numpy_data(size)
            out_data_ptr = data.ctypes.data
            return data
        memory_resource = get_device_memory_resource(device_id)
    data = allocate_from_mr(memory_resource, size, _get_stream_obj(stream), device_id, logger)
    out_data_ptr = int(data.handle)
    return data


cdef bint _memset_compatible_itemsize(int itemsize) except? -1 nogil:
    """
    Must be power of two and <= 4.
    """
    return itemsize <= 4 and (not (itemsize & (itemsize - 1)))


cdef intptr_t _data_ptr(intptr_t base_ptr, StridedLayout layout) except? -1 nogil:
    """
    For base_ptr (the start of the memory range accessible with the given tensor),
    return the address of the element at index (0, ) * ndim.
    """
    return base_ptr - layout.get_min_offset_in_bytes()


cdef intptr_t _base_ptr(intptr_t data_ptr, StridedLayout layout) except? -1 nogil:
    """
    For data_ptr (address of the element at index (0, ) * ndim),
    return the address to a beginning of the memory range that is
    accessible with the given layout.
    """
    return data_ptr + layout.get_min_offset_in_bytes()


cdef int _memory_range(intptr_t &base_ptr, int64_t &size_in_bytes, int64_t &offset, intptr_t data_ptr, StridedLayout layout) except -1 nogil:
    """
    Returns the description of the memory range accessible with the given tensor:
    ``[base_ptr, ..., base_ptr + size_in_bytes - 1]``, such that:

    * base_ptr: the start of the memory range
    * size_in_bytes: the size of the memory range in bytes
    * offset: a non-negative offset of the element at index ``(0, ) * ndim``
      from the start of the memory range
    """
    cdef int64_t min_offset = layout.get_min_offset_in_bytes()
    base_ptr = data_ptr + min_offset
    offset = -min_offset
    size_in_bytes = layout.get_memory_range_size_in_bytes()
    return 0


cdef int _as_strided_check_bounds(NDBuffer ndbuf, StridedLayout layout, int64_t offset_in_bytes) except -1:
    """
    Check that the ``[min_offset, max_offset]`` range defined by the new layout (and data ptr offset)
    is contained in the memory range of the base NDBuffer.
    """
    cdef NDBuffer base = ndbuf.base if ndbuf.base is not None else ndbuf
    cdef intptr_t old_range_start = _base_ptr(base.data_ptr, base.layout)
    cdef intptr_t old_range_end = old_range_start + base.layout.get_memory_range_size_in_bytes()
    cdef intptr_t new_data_ptr = ndbuf.data_ptr + offset_in_bytes
    if new_data_ptr % layout.base.itemsize != 0:
        raise ValueError(
            f"Incorrect offset: new data pointer {new_data_ptr} must be aligned "
            f"to the itemsize {layout.base.itemsize}."
        )
    cdef intptr_t new_range_start = _base_ptr(new_data_ptr, layout)
    cdef intptr_t new_range_end = new_range_start + layout.get_memory_range_size_in_bytes()
    if new_range_start < old_range_start or new_range_end > old_range_end:
        raise ValueError(
            f"The new layout is incompatible with the NDBuffer instance. "
            f"The memory range of the new layout [{new_range_start}, {new_range_end}) "
            f"must be a subset of the memory range of the NDBuffer's base "
            f"[{old_range_start}, {old_range_end})."
        )
    return 0


cdef int _check_dtype(NDBuffer dst, NDBuffer src) except -1 nogil:
    if dst.dtype_name != src.dtype_name:
        raise ValueError(
            f"The data types of the source and destination buffers must match. "
            f"Got dst dtype:{dst.dtype_name} and src dtype:{src.dtype_name}"
        )
    if src.layout.base.itemsize != dst.layout.base.itemsize:
        raise ValueError(
            f"The itemsize of the source and destination buffers must match. "
            f"Got dst itemsize:{dst.layout.base.itemsize} and src itemsize:{src.layout.base.itemsize}"
        )
    return 0
