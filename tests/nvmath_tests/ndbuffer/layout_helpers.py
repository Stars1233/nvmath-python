# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import itertools
import math

import numpy as np

from nvmath.internal._layout import StridedLayout

from .helpers import inv, permuted

_S = np.s_


def dtype_from_itemsize(itemsize):
    if itemsize <= 8:
        return np.dtype(f"int{itemsize * 8}")
    elif itemsize == 16:
        return np.dtype("complex128")
    else:
        raise ValueError(f"Unsupported itemsize: {itemsize}")


class LayoutSpec:
    """
    Pretty printable specification of a layout in a test case.
    """

    def __init__(self, shape, itemsize, stride_order="C"):
        self.shape = shape
        self.itemsize = itemsize
        self.stride_order = stride_order
        self.layout = StridedLayout.dense(shape, itemsize, stride_order)
        self._np_ref = None

    def pretty_name(self):
        desc = [
            f"ndim.{len(self.shape)}",
            f"shape.{self.shape}",
            f"itemsize.{self.itemsize}",
        ]
        if isinstance(self.stride_order, tuple):
            assert len(self.stride_order) == len(self.shape)
            desc.append(f"stride_order.{self.stride_order}")
        else:
            assert isinstance(self.stride_order, str) and self.stride_order in "CF"
            desc.append(f"stride_order.{self.stride_order}")
        return "-".join(desc)

    @property
    def np_ref(self):
        if self._np_ref is None:
            dtype = dtype_from_itemsize(self.itemsize)
            np_ref = np.arange(math.prod(self.shape), dtype=dtype)
            if isinstance(self.stride_order, tuple):
                np_ref = np_ref.reshape(permuted(self.shape, self.stride_order))
                np_ref = np_ref.transpose(inv(self.stride_order))
            else:
                assert isinstance(self.stride_order, str) and self.stride_order in "CF"
                np_ref = np_ref.reshape(self.shape, order=self.stride_order)
            self._np_ref = np_ref
        return self._np_ref


def unit_extents_mask(shape):
    mask = 0
    for i in range(len(shape)):
        if shape[i] == 1:
            mask |= 1 << i
    return mask


def is_contiguous_c(shape, strides):
    expected_stride = 1
    for i in range(len(shape) - 1, -1, -1):
        if shape[i] == 1:
            continue
        if strides[i] != expected_stride:
            return False
        expected_stride *= shape[i]
    return True


def is_leading_dense(arr):
    if arr.size == 0:
        return True
    arr_strides = arr.squeeze().strides
    if len(arr_strides) == 0:
        return True
    min_stride = min(abs(s) for s in arr_strides)
    min_stride //= arr.itemsize
    if min_stride == 0:
        return False
    shape = arr.shape
    strides = tuple(s // arr.itemsize for s in arr.strides)
    shape += (min_stride,)
    strides += (1,)
    return is_contiguous_c(shape, strides)


def ref_flags(layout: StridedLayout, arr: np.ndarray):
    stride_order = layout.stride_order
    flags = {}
    flags["is_contiguous_c"] = arr.flags["C_CONTIGUOUS"]
    flags["is_contiguous_f"] = arr.flags["F_CONTIGUOUS"]
    flags["is_contiguous_any"] = (
        flags["is_contiguous_c"] or flags["is_contiguous_f"] or arr.transpose(stride_order).flags["C_CONTIGUOUS"]
    )
    slices = tuple(_S[:] if stride >= 0 else _S[::-1] for stride in arr.strides)
    arr_abs = arr[slices]
    flags["is_abs_dense_c"] = arr_abs.flags["C_CONTIGUOUS"]
    flags["is_abs_dense_f"] = arr_abs.flags["F_CONTIGUOUS"]
    flags["is_abs_dense_any"] = (
        flags["is_abs_dense_c"] or flags["is_abs_dense_f"] or arr_abs.transpose(stride_order).flags["C_CONTIGUOUS"]
    )
    flags["is_leading_dense_c"] = is_leading_dense(arr)
    flags["is_leading_dense_f"] = is_leading_dense(arr.transpose(tuple(reversed(range(len(arr.shape))))))
    flags["is_leading_dense_any"] = (
        flags["is_leading_dense_c"] or flags["is_leading_dense_f"] or is_leading_dense(arr.transpose(stride_order))
    )
    flags["is_abs_leading_dense_c"] = is_leading_dense(arr_abs)
    flags["is_abs_leading_dense_f"] = is_leading_dense(arr_abs.transpose(tuple(reversed(range(len(arr_abs.shape))))))
    flags["is_abs_leading_dense_any"] = (
        flags["is_abs_leading_dense_c"] or flags["is_abs_leading_dense_f"] or is_leading_dense(arr_abs.transpose(stride_order))
    )
    flags["has_no_negative_stride"] = all(
        extent == 1 or stride >= 0 for extent, stride in zip(arr.shape, arr.strides, strict=True)
    )
    return flags


_is_dense_fn = {
    "is_abs_dense_c": lambda layout: layout.is_dense(stride_order="C", allow_negative_strides=True),
    "is_abs_dense_f": lambda layout: layout.is_dense(stride_order="F", allow_negative_strides=True),
    "is_abs_dense_any": lambda layout: layout.is_dense(stride_order="K", allow_negative_strides=True),
    "is_leading_dense_c": lambda layout: layout.is_dense(stride_order="C", allow_leading_dim_stride=True),
    "is_leading_dense_f": lambda layout: layout.is_dense(stride_order="F", allow_leading_dim_stride=True),
    "is_leading_dense_any": lambda layout: layout.is_dense(stride_order="K", allow_leading_dim_stride=True),
    "is_abs_leading_dense_c": lambda layout: layout.is_dense(
        stride_order="C", allow_negative_strides=True, allow_leading_dim_stride=True
    ),
    "is_abs_leading_dense_f": lambda layout: layout.is_dense(
        stride_order="F", allow_negative_strides=True, allow_leading_dim_stride=True
    ),
    "is_abs_leading_dense_any": lambda layout: layout.is_dense(
        stride_order="K", allow_negative_strides=True, allow_leading_dim_stride=True
    ),
}


def check_dense_props(layout: StridedLayout, arr: np.ndarray):
    expected_flags = ref_flags(layout, arr)
    assert len(expected_flags) == 13
    for prop_name, expected_value in expected_flags.items():
        is_dense_fn = _is_dense_fn.get(prop_name)
        if is_dense_fn is None:
            value = getattr(layout, prop_name)
        else:
            value = is_dense_fn(layout)
        assert value == expected_value, f"{prop_name}: {value} != {expected_value}"


def check_memory_range_size(layout: StridedLayout, arr: np.ndarray):
    if arr.size == 0:
        memory_range_size_in_bytes = 0
    elif arr.size == 1:
        memory_range_size_in_bytes = arr.itemsize
    else:
        min_offset = 0
        max_offset = 0
        for extent, stride in zip(arr.shape, arr.strides, strict=True):
            if extent == 1:
                continue
            if stride > 0:
                max_offset += stride * (extent - 1)
            else:
                min_offset += stride * (extent - 1)
        memory_range_size_in_bytes = max_offset - min_offset + arr.itemsize
    assert layout.memory_range_size * layout.itemsize == memory_range_size_in_bytes
    assert layout.memory_range_size_in_bytes == memory_range_size_in_bytes


def cmp_layout_and_array(layout: StridedLayout, arr: np.ndarray):
    """
    Compare StridedLayout and numpy.ndarray.
    """
    ndim = arr.ndim
    assert layout.ndim == arr.ndim
    assert layout.shape == arr.shape
    volume = math.prod(arr.shape)
    assert layout.volume == volume
    assert layout.itemsize == arr.itemsize
    check_dense_props(layout, arr)
    if volume == 0:
        zero_strides = tuple(0 for _ in range(ndim))
        assert layout.strides_in_bytes == zero_strides, f"{layout.strides_in_bytes} != {zero_strides}"
        assert layout.strides == zero_strides, f"{layout.strides} != {zero_strides}"
    else:
        assert layout.strides_in_bytes == arr.strides, f"{layout.strides_in_bytes} != {arr.strides}"

    arr_layout = StridedLayout(arr.shape, arr.strides, arr.itemsize, divide_strides=True)
    if volume != 0:
        assert arr_layout == layout, f"{arr_layout} != {layout}"
        assert arr_layout.strides == layout.strides, f"{arr_layout.strides} != {layout.strides}"
    assert arr_layout.shape == layout.shape, f"{arr_layout.shape} != {layout.shape}"
    assert arr_layout.strides_in_bytes == arr.strides, f"{arr_layout.strides_in_bytes} != {arr.strides}"
    check_memory_range_size(layout, arr)


def flatten_mask2str(mask, ndim):
    return "".join("1" if mask & (1 << i) else "0" for i in range(ndim))


def all_subsets(n):
    return itertools.chain.from_iterable(itertools.combinations(range(n), r) for r in range(n + 1))
