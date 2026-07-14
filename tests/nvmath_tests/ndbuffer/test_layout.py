# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import itertools
import math
import random
from enum import Enum

import numpy as np
import pytest
from packaging.version import Version

from nvmath.internal._layout import StridedLayout

from .helpers import Param, idfn, inv, long_shape, permuted, random_permutations
from .layout_helpers import (
    LayoutSpec,
    all_subsets,
    cmp_layout_and_array,
    dtype_from_itemsize,
    flatten_mask2str,
    unit_extents_mask,
)

_ITEMSIZES = [1, 2, 4, 8, 16]
_S = np.s_

py_rng = random.Random(42)


has_old_numpy = Version(np.__version__) < Version("2.0.0")
np_max_ndim = 32 if has_old_numpy else 64


def np_reshape(array, shape, expect_copy=False):
    # pre 2.0 numpy does not support reshape(shape, copy=False)
    if has_old_numpy:
        ret = array.reshape(shape)
        if expect_copy:
            assert ret.ctypes.data != array.ctypes.data
        else:
            assert ret.ctypes.data == array.ctypes.data
        return ret

    if not expect_copy:
        # will raise if not possible without a copy
        return array.reshape(shape, copy=False)

    ret = array.reshape(shape)
    assert ret.ctypes.data != array.ctypes.data
    return ret


def skip_unsupported_numpy(shape):
    if isinstance(shape, tuple) and len(shape) > np_max_ndim:
        pytest.skip(f"numpy does not support {len(shape)} dimensions")


@pytest.mark.parametrize(
    "layout_spec",
    [
        LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order)
        for shape in [(), (5,), (7, 9), (3, 2, 4), long_shape(py_rng, 64)]
        for stride_order in random_permutations(py_rng, len(shape))
    ],
    ids=idfn,
)
def test_dense_with_permutation_as_stride_order(layout_spec):
    """
    Test creating StridedLayout with stride_order=tuple(...).
    """
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    cmp_layout_and_array(layout, np_ref)
    unit_mask = unit_extents_mask(layout_spec.shape)
    assert layout.unit_extents_mask() == unit_mask
    if unit_mask == 0:
        assert layout.stride_order == layout_spec.stride_order
    assert layout.has_stride_order(layout_spec.stride_order)


@pytest.mark.parametrize(
    "layout_spec",
    [
        LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order)
        for shape in [(), (11,), (3, 5), (3, 2, 4), long_shape(py_rng, 64)]
        for stride_order in ["C", "F"]
    ],
    ids=idfn,
)
def test_dense_with_cf_order(layout_spec):
    """
    Test creating StridedLayout with "C" or "F" order.
    """
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    cmp_layout_and_array(layout, np_ref)
    unit_mask = unit_extents_mask(layout_spec.shape)
    assert layout.unit_extents_mask() == unit_mask
    stride_order_perm = range(len(layout_spec.shape))
    if layout_spec.stride_order == "F":
        stride_order_perm = reversed(stride_order_perm)
    else:
        assert layout_spec.stride_order == "C"
    stride_order_perm = tuple(stride_order_perm)
    if unit_mask == 0:
        assert layout.stride_order == stride_order_perm
    assert layout.has_stride_order(layout_spec.stride_order)
    assert layout.has_stride_order(stride_order_perm)


@pytest.mark.parametrize(
    "shape",
    [
        Param("shape", shape)
        for shape in [
            (),
            3,
            0,
            (7,),
            (1, 2),
            (3, 5, 4),
            (3, 0, 4, 5),
            long_shape(py_rng, 32),
            long_shape(py_rng, 64),
        ]
    ],
    ids=idfn,
)
def test_reversed(shape):
    shape = shape.value
    shape_tuple = shape if isinstance(shape, tuple) else (shape,)
    ndim = len(shape_tuple)
    layout = StridedLayout.dense(shape, 4)
    assert layout.is_contiguous_c
    rev = layout.reversed()
    if ndim <= 1:
        assert rev is layout
    else:
        assert rev == layout.permuted(tuple(reversed(layout.stride_order)))
        assert rev.shape == tuple(reversed(shape_tuple))
        assert rev.strides == tuple(reversed(layout.strides))
        assert rev.itemsize == layout.itemsize
        assert rev.is_contiguous_f


@pytest.mark.parametrize(
    ("layout_spec", "perm", "inverse", "neg_axes"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("perm", permutation),
            Param("inverse", inverse),
            Param("neg_axes", py_rng.choice([True, False])),
        )
        for shape in [
            (),
            (1,),
            (2, 3),
            (5, 6, 7),
            (5, 1, 7),
            (5, 2, 3, 4),
            long_shape(py_rng, 64),
        ]
        for permutation in random_permutations(py_rng, len(shape), sample_size=3)
        for stride_order in ["C", "F"]
        for inverse in [False, True]
    ],
    ids=idfn,
)
def test_permuted(layout_spec, perm, inverse, neg_axes):
    perm = perm.value
    neg_axes = neg_axes.value
    inv_perm = inv(perm)
    base_shape = layout_spec.shape
    base_layout = layout_spec.layout
    skip_unsupported_numpy(layout_spec.shape)
    np_ref = layout_spec.np_ref
    perm_arg = perm
    if neg_axes:
        perm_arg = tuple(i - len(layout_spec.shape) for i in perm)
    layout = base_layout.permuted(perm_arg, inverse=inverse)
    if inverse:
        np_ref = np_ref.transpose(inv_perm)
        perm_shape = permuted(base_shape, inv_perm)
    else:
        np_ref = np_ref.transpose(perm)
        perm_shape = permuted(base_shape, perm)
    unit_mask = unit_extents_mask(perm_shape)
    assert layout.unit_extents_mask() == unit_mask
    if perm == tuple(range(len(base_shape))):
        assert layout is base_layout
    cmp_layout_and_array(layout, np_ref)
    # for any layout, permuting it by its stride order gives
    # a layout with a C-order of strides, so:
    # (initial_order (: C|F) * perm) * expected_order == id
    # thus, expected_order == inv(perm) * inv(initial_order)
    # for C, the inv(initial) is id, for F it is reversed(id)
    expected_order = perm if inverse else inv_perm
    if layout_spec.stride_order == "F":
        expected_order = reversed(expected_order)
    expected_order = tuple(expected_order)
    if unit_mask == 0:
        assert layout.stride_order == expected_order
    assert layout.has_stride_order(expected_order)


class PermutedErr(Enum):
    REPEATED_AXIS = "Axis -?\\d+ appears multiple times"
    OUT_OF_RANGE = "Axis -?\\d+ out of range for"
    WRONG_LEN = "the same length as the number of dimensions"


@pytest.mark.parametrize(
    ("layout_spec", "perm", "error_msg"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("perm", permutation),
            error_msg,
        )
        for shape, permutation, error_msg in [
            ((), (5,), PermutedErr.WRONG_LEN),
            ((1,), (0, 0), PermutedErr.WRONG_LEN),
            ((2, 5, 3), (1, 0, 1), PermutedErr.REPEATED_AXIS),
            ((5, 6, 7), (1, 3, 0), PermutedErr.OUT_OF_RANGE),
            ((5, 6, 7), (1, -2000, 0), PermutedErr.OUT_OF_RANGE),
        ]
        for stride_order in ["C", "F"]
    ],
    ids=idfn,
)
def test_permuted_validation(layout_spec, perm, error_msg):
    layout = layout_spec.layout
    perm = perm.value
    with pytest.raises(ValueError, match=error_msg.value):
        layout.permuted(perm)


@pytest.mark.parametrize(
    (
        "layout_spec",
        "slices",
        "new_shape",
    ),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("slices", slices),
            Param("new_shape", new_shape),
        )
        for shape, slices, new_shape in [
            ((), None, ()),
            ((), None, (1,)),
            ((), None, (17, 1, 5)),
            ((1,), None, (5,)),
            ((1,), None, (3, 5, 2)),
            ((7,), None, (7,)),
            ((7,), None, (2, 7)),
            ((5, 11), _S[1:-1, ::-1], (3, 11)),
            ((5, 11), _S[1:-1, ::-1], (7, 3, 11)),
            ((5, 11), _S[::-1, 3:4], (5, 7)),
            ((5, 11), _S[::-1, 3:4], (5, 30)),
            ((5, 11), _S[::-1, 3:4], (4, 5, 12)),
            ((5, 11), _S[-1:,], (4, 13, 11)),
            ((2, 3, 3), _S[:, 1:2], (401, 3) + (1,) * 59 + (2, 4, 3)),
        ]
        for stride_order in ["C", "F"]
    ],
    ids=idfn,
)
def test_broadcast_layout(
    layout_spec,
    slices,
    new_shape,
):
    slices = slices.value
    new_shape = new_shape.value
    skip_unsupported_numpy(layout_spec.shape)
    skip_unsupported_numpy(new_shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]
    base_layout = layout
    base_shape = np_ref.shape
    layout = layout.broadcast_to(new_shape)
    np_ref = np.broadcast_to(np_ref, new_shape)
    ndim_diff = len(new_shape) - len(base_shape)
    expect_unique = all(new_shape[i] == 1 for i in range(ndim_diff))
    expect_unique = expect_unique and all(new_shape[i + ndim_diff] == base_shape[i] for i in range(len(base_shape)))
    expect_exhaustive = layout.memory_range_size <= np.prod(base_shape)
    cmp_layout_and_array(layout, np_ref)
    assert layout.is_unique == expect_unique
    assert layout.is_exhaustive == expect_exhaustive
    if base_shape == np_ref.shape:
        assert layout is base_layout
    unbroadcast = layout.unbroadcast()
    assert unbroadcast.volume == np.prod(base_shape)
    assert unbroadcast.is_almost_equal(base_layout.unsqueezed_to_ndim(len(new_shape)))
    assert unbroadcast.squeezed() == base_layout.squeezed()
    layout = StridedLayout(layout.shape, layout.strides, layout.itemsize)
    cmp_layout_and_array(layout, np_ref)
    assert layout.is_unique == expect_unique
    assert layout.is_exhaustive == expect_exhaustive


def test_broadcast_unbroadcast_noop():
    layout = StridedLayout.dense((1, 2, 3), 2)
    other = layout.broadcast_to((1, 1, 2, 3))
    assert other.shape == (1, 1, 2, 3)
    assert other.strides == (0, 6, 3, 1)
    assert other is not layout
    assert other.unbroadcast() is other
    assert other.unbroadcast().strides == (0, 6, 3, 1)
    assert layout.broadcast_to((1, 2, 3)) is layout
    assert layout.broadcast_to((1, 2, 3)).unbroadcast() is layout


class ReshapeErr(Enum):
    VOLUME_MISMATCH = "The original volume \\d+ and the new volume \\d+ must be equal."
    NEG_EXTENT = "Extents must be non-negative"
    MULTI_NEG_EXTENTS = "There can be at most one -1 extent in a shape"
    AMBIGUOUS_NEG_EXTENT = "The -1 extent is ambiguous when the specified sub-volume is 0"
    DIVISIBILITY_VIOLATION = "The original volume \\d+ must be divisible by the specified sub-volume \\d+"
    STRIDE = "Layout strides are incompatible with the new shape"
    TYPE_ERROR = None


@pytest.mark.parametrize(
    ("layout_spec", "perm", "slices", "new_shape", "error_msg"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES)),
            Param("perm", permutation),
            Param("slices", slices),
            Param("new_shape", new_shape),
            error_msg,
        )
        for shape, permutation, slices, new_shape, error_msg in [
            ((), None, None, (), None),
            ((), None, None, (1,), None),
            ((), None, None, (-1,), None),
            ((), None, None, (1, -1, 1), None),
            ((1,), None, None, (-1,), None),
            ((1,), None, None, (), None),
            ((12,), None, _S[:], (12,), None),
            ((12,), None, None, (11,), ReshapeErr.VOLUME_MISMATCH),
            ((12,), None, _S[1:], (11,), None),
            ((0,), None, None, (0,), None),
            ((0,), None, None, (1, 3), ReshapeErr.VOLUME_MISMATCH),
            ((3,), None, _S[3:], (3,), ReshapeErr.VOLUME_MISMATCH),
            ((18,), None, None, (0,), ReshapeErr.VOLUME_MISMATCH),
            ((3,), None, _S[2:-1], (0,), None),
            ((3,), None, _S[3:], (-1,), None),
            ((0,), None, None, (1, -1), None),
            ((0,), None, None, (0, -1), ReshapeErr.AMBIGUOUS_NEG_EXTENT),
            ((3, 0, 3), None, None, (2, 3, 4, 5, 6, 7, 0, 12), None),
            ((3, 0, 3), None, None, (0,), None),
            ((12,), None, None, (2, 3, 2), None),
            ((12,), None, None, (2, 6), None),
            ((12,), None, None, (4, 3), None),
            ((12,), None, None, (3, 4), None),
            ((7, 12), None, None, (7, 12), None),
            ((7, 12), None, None, (12, 7), None),
            ((12, 11), None, None, (2, 3, 2, 11), None),
            ((12, 11), None, None, (2, 3, 11, 2), None),
            ((12, 11), None, None, (2, 11, 3, 2), None),
            ((12, 11), None, None, (11, 2, 3, 2), None),
            ((12, 11), None, None, (2, 3, 2, -1), None),
            ((12, 11), None, None, (2, 3, -1, 2), None),
            ((12, 11), None, None, (2, -1, 3, 2), None),
            ((12, 11), None, None, (-1, 2, 3, 2), None),
            ((12, 11), None, None, (2, 3, -1, 11), None),
            ((12, 11), None, None, (2, 3, 11, -1), None),
            ((12, 11), None, None, (-1, 11, 3, 2), None),
            ((12, 11), None, None, (11, 2, -1, 2), None),
            ((5, 12), None, None, (2, 5, 6), None),
            ((2, 3, 2), None, None, (12,), None),
            ((2, 3, 2), None, None, (6, 2), None),
            ((2, 3, 2), None, None, (2, 3, 2), None),
            ((2, 3, 2), (1, 2, 0), None, (6, 2), None),
            ((2, 3, 2), (1, 2, 0), None, (2, 6), ReshapeErr.STRIDE),
            ((2, 3, 2), (1, 2, 0), None, (12,), ReshapeErr.STRIDE),
            ((2, 3, 2), (1, 0, 2), None, (3, 2, 2), None),
            ((2, 3, 2), (1, 0, 2), None, (3, 4), ReshapeErr.STRIDE),
            ((2, 3, 2), (1, 0, 2), None, (6, 2), ReshapeErr.STRIDE),
            ((2, 3, 2), (1, 0, 2), None, (12,), ReshapeErr.STRIDE),
            ((1, 3, 1, 4, 1, 5, 1), (1, 3, 5, 2, 0, 6, 4), None, -1, None),
            ((1, 3, 1, 4, 1, 5, 1), (6, 4, 0, 2, 1, 3, 5), None, (6, 10), None),
            ((1, 3, 1, 4, 1, 5, 1), (1, 0, 4, 3, 6, 2, 5), None, (10, 6), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (45,), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (3, 5, 3), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (45, 1), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (3, 5, 3, 1), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (1, 45, 1), None),
            ((1, 1, 5, 3, 6), (2, 3, 4, 0, 1), _S[:, :, ::2], (1, 3, 5, 3, 1), None),
            ((5, 3, 6, 1, 1), (3, 4, 0, 1, 2), _S[..., ::2], (1, 3, 5, 3, 1), None),
            ((10, 10, 10), None, _S[::-1, ::-1, :], (10, 10, 10), None),
            ((10, 10, 10), None, _S[::-1, ::-1, ::-1], (1000,), None),
            ((10, 10, 10), None, _S[::-1, ::-1, :], (100, 10), None),
            ((10, 10, 10), None, _S[::-1, ::-1, :], (10, 100), ReshapeErr.STRIDE),
            ((10, 10, 10), None, _S[..., ::-1], (100, 10), None),
            ((10, 10, 10), None, _S[..., ::-1], (10, 100), ReshapeErr.STRIDE),
            ((10, 10, 10), None, _S[::-1, :, ::-1], (1000,), ReshapeErr.STRIDE),
            ((10, 10, 10), (1, 0, 2), _S[::-1, ::-1], (100, 10), ReshapeErr.STRIDE),
            ((5, 3), None, _S[:-1, :], (12,), None),
            ((13, 3), None, _S[1:, :], (6, 6), None),
            ((12, 4), None, _S[:, :-1], (6, 6), ReshapeErr.STRIDE),
            ((12, 4), None, _S[:, :-1], (6, 2, 3), None),
            ((7, 6, 5), None, None, (70, -1), None),
            ((7, 6, 5), None, None, (-1, 70), None),
            ((7, 6, 5), None, None, (71, -1), ReshapeErr.DIVISIBILITY_VIOLATION),
            ((7, 6, 5), None, None, (-1, 71), ReshapeErr.DIVISIBILITY_VIOLATION),
            ((7, 6, 5), None, None, (71, -2), ReshapeErr.NEG_EXTENT),
            ((7, 6, 5), None, None, (-2, 71), ReshapeErr.NEG_EXTENT),
            ((7, 6, 5), None, None, (-1, 6, -1), ReshapeErr.MULTI_NEG_EXTENTS),
            ((7, 6, 5), None, None, (-2, -1, -1), ReshapeErr.NEG_EXTENT),
            ((7, 6, 5), None, None, (-2, -1, -2), ReshapeErr.NEG_EXTENT),
            ((7, 6, 5), None, None, (-7, 6, -5), ReshapeErr.NEG_EXTENT),
            ((7, 6, 5), None, None, (5, 0, -1), ReshapeErr.AMBIGUOUS_NEG_EXTENT),
            ((7, 0, 5), None, None, (5, 0, -1), ReshapeErr.AMBIGUOUS_NEG_EXTENT),
            ((7, 6, 5), None, None, map, ReshapeErr.TYPE_ERROR),
            # random 64-dim shape with 5 non-unit extents 2, 3, 4, 5, 6
            (long_shape(py_rng, 64, 5, 6), None, None, (60, 12), None),
        ]
    ],
    ids=idfn,
)
def test_reshape(layout_spec, perm, slices, new_shape, error_msg):
    perm = perm.value
    slices = slices.value
    new_shape = new_shape.value
    skip_unsupported_numpy(layout_spec.shape)
    skip_unsupported_numpy(new_shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if perm is not None:
        layout = layout.permuted(perm)
        np_ref = np_ref.transpose(perm)
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]
    base_shape = np_ref.shape
    if error_msg is None:
        reshaped = layout.reshaped(new_shape)
        reshaped_ref = np_reshape(np_ref, new_shape, expect_copy=False)
        cmp_layout_and_array(reshaped, reshaped_ref)
        if new_shape == base_shape:
            assert reshaped is layout
    else:
        # sanity check that numpy is not able to reshape without
        # a copy as well
        if error_msg == ReshapeErr.STRIDE:
            reshaped_ref = np_reshape(np_ref, new_shape, expect_copy=True)

        error_cls = TypeError if error_msg == ReshapeErr.TYPE_ERROR else ValueError
        msg = None if error_msg == ReshapeErr.TYPE_ERROR else error_msg.value
        with pytest.raises(error_cls, match=msg):
            layout.reshaped(new_shape)


@pytest.mark.parametrize(
    (
        "layout_spec",
        "perm",
        "slices",
        "expected_shape",
        "expected_strides",
        "expected_axis_mask",
        "axes_range",
    ),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES)),
            Param("perm", permutation),
            Param("slices", slices),
            Param("expected_shape", expected_shape),
            Param("expected_strides", expected_strides),
            Param("expected_axis_mask", expected_axis_mask),
            Param("axes_range", axes_range),
        )
        for shape, permutation, slices, expected_shape, expected_strides, expected_axis_mask, axes_range in [
            ((), None, None, (1,), (1,), "", None),
            ((12,), None, _S[:], (12,), (1,), "0", None),
            ((1, 2, 3, 4, 5), None, None, (120,), (1,), "01111", None),
            ((1, 2, 3, 0, 5), None, None, (0,), (0,), "01111", None),
            ((5, 1, 2, 4, 3), None, _S[:, :, :, :, ::-2], (40, 2), (3, -2), "01110", None),
            ((5, 1, 2, 4, 3), None, _S[:, :, :, :, ::-2], (10, 4, 2), (12, 3, -2), "01110", (0, 2)),
            (
                (5, 1, 2, 4, 3),
                None,
                _S[:, :, :, :, ::-2],
                (5, 2, 4, 2),
                (24, 12, 3, -2),
                "01110",
                (1, 2),
            ),
            ((5, 1, 2, 4, 3), None, _S[:, :, :, :, ::-2], (5, 8, 2), (24, 3, -2), "01110", (1, 3)),
            ((5, 1, 2, 4, 3), None, _S[:, :, :, :, ::-2], (5, 8, 2), (24, 3, -2), "01110", (1, 4)),
            ((5, 2, 4, 3), None, _S[:, ::-1, :, :], (5, 2, 12), (24, -12, 1), "0001", None),
            ((5, 7, 4, 3), None, _S[:, ::-1, ::-1], (5, 28, 3), (84, -3, 1), "0010", None),
            ((5, 4, 3, 7), (2, 3, 0, 1), _S[:], (21, 20), (1, 21), "0101", None),
            ((5, 4, 3, 7), (3, 2, 0, 1), None, (7, 3, 20), (1, 7, 21), "0001", None),
            ((5, 1, 4, 1, 7), (3, 1, 0, 2, 4), None, (140,), (1,), "01111", None),
            ((5, 1, 4, 1, 7), (0, 3, 1, 2, 4), None, (140,), (1,), "01111", None),
            ((5, 1, 4, 1, 7), (0, 2, 1, 3, 4), None, (140,), (1,), "01111", None),
            ((5, 1, 4, 1, 7), (0, 2, 4, 3, 1), None, (140,), (1,), "01111", None),
            ((1, 1, 5, 3, 2), (2, 3, 4, 0, 1), None, (30,), (1,), "01111", None),
            ((1, 1, 5, 3, 4), (2, 3, 4, 0, 1), _S[:, :, ::2], (30,), (2,), "01111", None),
            ((5, 3, 4, 1, 1), (3, 4, 0, 1, 2), _S[..., ::2], (30,), (2,), "01111", None),
            ((1, 1, 1, 1), None, None, (1,), (1,), "0111", None),
            ((4, 5, 6, 7), None, _S[1:3:2, 1:3:2, 1:3:2, 1:3:2], (1,), (1,), "0111", None),
            ((4, 5, 6, 7), (3, 2, 1, 0), _S[1:3:2, 1:3:2, 1:3:2, 1:3:2], (1,), (1,), "0111", None),
            ((4, 5, 6, 7), (1, 3, 0, 2), _S[1:3:2, 1:3:2, 1:3:2, 1:3:2], (1,), (1,), "0111", None),
            # random 64-dim shape with 4 non-unit extents 2, 3, 4, 5
            (long_shape(py_rng, 64, 4, 5), None, None, (120,), (1,), "0" + "1" * 63, None),
        ]
    ],
    ids=idfn,
)
def test_flatten(
    layout_spec,
    perm,
    slices,
    expected_shape,
    expected_strides,
    expected_axis_mask,
    axes_range,
):
    perm = perm.value
    slices = slices.value
    expected_shape = expected_shape.value
    expected_strides = expected_strides.value
    expected_axis_mask = expected_axis_mask.value
    axes_range = axes_range.value
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if perm is not None:
        layout = layout.permuted(perm)
        np_ref = np_ref.transpose(perm)
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]
    base_shape = np_ref.shape

    mask = layout.flattened_axis_mask()
    assert flatten_mask2str(mask, layout.ndim) == expected_axis_mask

    if axes_range is None:
        flattened = layout.flattened()
        assert layout.flattened(mask=mask) == flattened
        # cannot be flattened any further
        assert flattened.flattened_axis_mask() == 0
    else:
        flattened = layout.flattened(start_axis=axes_range[0], end_axis=axes_range[1])

    assert flattened.shape == expected_shape
    assert flattened.strides == expected_strides
    assert flattened.itemsize == layout_spec.itemsize

    if base_shape == flattened.shape:
        assert flattened is layout

    np_ref = np_reshape(np_ref, flattened.shape, expect_copy=False)
    cmp_layout_and_array(flattened, np_ref)


@pytest.mark.parametrize(
    (
        "layout_spec_0",
        "layout_spec_1",
        "expected_layout_spec_0",
        "expected_layout_spec_1",
    ),
    [
        (
            layout_spec_0,
            layout_spec_1,
            expected_layout_spec_0,
            expected_layout_spec_1,
        )
        for layout_spec_0, layout_spec_1, expected_layout_spec_0, expected_layout_spec_1 in [
            (
                LayoutSpec((), 2, "C"),
                LayoutSpec((), 4, "C"),
                LayoutSpec((1,), 2, "C"),
                LayoutSpec((1,), 4, "C"),
            ),
            (
                LayoutSpec((2, 7, 13, 5), 8, "C"),
                LayoutSpec((3, 5, 11, 1), 4, "C"),
                LayoutSpec((910,), 8, "C"),
                LayoutSpec((165,), 4, "C"),
            ),
            (
                LayoutSpec((1, 5, 1, 3, 1), 8, (1, 3, 4, 2, 0)),
                LayoutSpec((1, 2, 1, 7, 1), 4, (4, 2, 0, 1, 3)),
                LayoutSpec((15,), 8, "C"),
                LayoutSpec((14,), 4, "C"),
            ),
            (
                LayoutSpec((5, 1, 3), 8, "C"),
                LayoutSpec((2, 1, 7), 4, "F"),
                LayoutSpec((5, 3), 8, "C"),
                LayoutSpec((2, 7), 4, "F"),
            ),
            (
                LayoutSpec((7, 2, 0, 3, 4, 5), 8, "C"),
                LayoutSpec((7, 5, 3, 0, 11, 4), 4, "F"),
                LayoutSpec((0,), 8, "C"),
                LayoutSpec((0,), 4, "C"),
            ),
            (
                LayoutSpec((7, 2, 0, 3, 4, 5), 8, "C"),
                LayoutSpec((7, 5, 3, 2, 11, 4), 4, (3, 4, 5, 0, 1, 2)),
                LayoutSpec((0, 60), 8, "C"),
                LayoutSpec((105, 88), 4, "F"),
            ),
            (
                LayoutSpec((7, 2, 0, 3, 4, 5), 8, "F"),
                LayoutSpec((7, 5, 3, 2, 11, 4), 4, (3, 4, 5, 0, 1, 2)),
                LayoutSpec((0, 60), 8, "C"),
                LayoutSpec((105, 88), 4, "F"),
            ),
            (
                LayoutSpec((7, 3, 4, 5, 0), 8, "C"),
                LayoutSpec((2, 3, 4, 5, 6), 4, (4, 0, 1, 2, 3)),
                LayoutSpec((420, 0), 8, "C"),
                LayoutSpec((120, 6), 4, "F"),
            ),
            (
                LayoutSpec((5, 7, 13, 2), 4, (3, 1, 2, 0)),
                LayoutSpec((3, 5, 11, 1), 2, "C"),
                LayoutSpec((5, 91, 2), 4, (2, 1, 0)),
                LayoutSpec((3, 55, 1), 2, "C"),
            ),
            (
                LayoutSpec((2, 7, 13, 5), 16, "C"),
                LayoutSpec((11, 1, 3, 5), 1, (2, 3, 0, 1)),
                LayoutSpec((14, 65), 16, "C"),
                LayoutSpec((11, 15), 1, (1, 0)),
            ),
            (
                LayoutSpec(
                    (4, 5, 11, 2, 3, 7),
                    4,
                    (5, 3, 4, 0, 1, 2),
                ),
                LayoutSpec(
                    (3, 8, 5, 6, 7, 9),
                    4,
                    (0, 1, 3, 4, 5, 2),
                ),
                LayoutSpec((20, 11, 6, 7), 4, (3, 2, 0, 1)),
                LayoutSpec((24, 5, 42, 9), 4, (0, 2, 3, 1)),
            ),
        ]
    ],
    ids=idfn,
)
def test_flatten_together(
    layout_spec_0,
    layout_spec_1,
    expected_layout_spec_0,
    expected_layout_spec_1,
):
    layout_0 = layout_spec_0.layout
    np_ref_0 = layout_spec_0.np_ref
    layout_1 = layout_spec_1.layout
    np_ref_1 = layout_spec_1.np_ref
    expected_layout_0 = expected_layout_spec_0.layout
    expected_layout_1 = expected_layout_spec_1.layout
    mask_0 = layout_0.flattened_axis_mask()
    mask_1 = layout_1.flattened_axis_mask()
    mask = mask_0 & mask_1

    flattened_0 = layout_0.flattened(mask=mask)
    flattened_1 = layout_1.flattened(mask=mask)

    assert flattened_0 == expected_layout_0
    assert flattened_1 == expected_layout_1

    np_ref_0 = np_reshape(np_ref_0, flattened_0.shape, expect_copy=False)
    np_ref_1 = np_reshape(np_ref_1, flattened_1.shape, expect_copy=False)
    cmp_layout_and_array(flattened_0, np_ref_0)
    cmp_layout_and_array(flattened_1, np_ref_1)


@pytest.mark.parametrize(
    ("layout_spec", "perm", "slices"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("perm", permutation),
            Param("slices", slices),
        )
        for shape, permutation, slices in [
            ((), None, None),
            ((12,), None, None),
            ((1, 5, 4, 3), None, None),
            ((1, 5, 1, 4, 3), None, _S[:, -1:, :]),
            ((1, 5, 4, 3), None, _S[:, -1:, :1, 1:2]),
            ((7, 5, 3), (2, 0, 1), _S[::-1, 3:2:-1, :]),
            ((7, 5, 3), (2, 0, 1), _S[:, 3:2, :]),
            ((7, 5, 3), (2, 0, 1), _S[..., -1:]),
            (long_shape(py_rng, 64, 1), None, None),
            (long_shape(py_rng, 33, 3), None, None),
        ]
        for stride_order in ["C", "F"]
    ],
    ids=idfn,
)
def test_squeezed(layout_spec, perm, slices):
    perm = perm.value
    slices = slices.value
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if perm is not None:
        layout = layout.permuted(perm)
        np_ref = np_ref.transpose(perm)
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]
    base_shape = np_ref.shape

    unit_mask = unit_extents_mask(base_shape)
    assert layout.unit_extents_mask() == unit_mask

    squeezed = layout.squeezed()
    squeezed_ref = np_ref.squeeze()
    cmp_layout_and_array(squeezed, squeezed_ref)
    unit_mask = unit_extents_mask(squeezed_ref.shape)
    assert squeezed.unit_extents_mask() == unit_mask

    if base_shape == squeezed.shape:
        assert squeezed is layout

    unit_axes = [i for i in range(len(base_shape)) if base_shape[i] == 1]
    for omit_axis in unit_axes:
        sub_axes = tuple(unit_axes[:omit_axis] + unit_axes[omit_axis + 1 :])
        sub_mask = 0
        for axis in sub_axes:
            sub_mask |= 1 << axis
        if len(sub_axes) == 1:
            sub_axes = sub_axes[0]
        squeezed_with_axes = layout.squeezed(axis=sub_axes)
        squeezed_with_mask = layout.squeezed(mask=sub_mask)
        sub_ref = np_ref.squeeze(axis=sub_axes)
        cmp_layout_and_array(squeezed_with_axes, sub_ref)
        cmp_layout_and_array(squeezed_with_mask, sub_ref)
        unit_mask_with_axes = squeezed_with_axes.unit_extents_mask()
        unit_mask_with_mask = squeezed_with_mask.unit_extents_mask()
        sub_mask_ref = unit_extents_mask(sub_ref.shape)
        assert unit_mask_with_axes == sub_mask_ref
        assert unit_mask_with_mask == sub_mask_ref
        assert squeezed_with_axes.squeezed() == squeezed
        assert squeezed_with_mask.squeezed() == squeezed


@pytest.mark.parametrize(
    ("layout_spec", "start_axis", "end_axis"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("start_axis", start_axis),
            Param("end_axis", end_axis),
        )
        for shape in [(1, 3, 1, 2, 1)]
        for start_axis in range(len(shape))
        for end_axis in range(start_axis, len(shape))
        for stride_order in random_permutations(py_rng, len(shape), 1, sample_size=1)
    ],
    ids=idfn,
)
def test_squeezed_range(layout_spec, start_axis, end_axis):
    start_axis = start_axis.value
    end_axis = end_axis.value
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    squeezed = layout.squeezed_range(start_axis, end_axis)
    np_axes = tuple(i for i in range(start_axis, end_axis + 1) if np_ref.shape[i] == 1)
    squeezed_ref = np_ref.squeeze(axis=np_axes)
    cmp_layout_and_array(squeezed, squeezed_ref)
    assert squeezed.unit_extents_mask() == unit_extents_mask(squeezed_ref.shape)
    assert squeezed.squeezed() == layout.squeezed()


@pytest.mark.parametrize(
    (
        "layout_spec",
        "slices",
        "axes",
        "use_mask",
    ),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("slices", slices),
            Param("axes", axes),
            Param("use_mask", py_rng.choice([False, True])),
        )
        for shape, slices in [
            ((), None),
            ((7,), None),
            ((4, 2, 7, 11), _S[1:-1, ::-1, 2:-1, ::3]),
        ]
        for stride_order in ["C", "F"]
        for num_axes in range(3)
        for axes in itertools.combinations(list(range(len(shape) + num_axes)), num_axes)
    ],
    ids=idfn,
)
def test_unsqueezed(layout_spec, slices, axes, use_mask):
    slices = slices.value
    axes = tuple(axes.value)
    use_mask = use_mask.value

    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]
    base_shape = np_ref.shape

    if use_mask:
        mask = 0
        for axis in axes:
            mask |= 1 << axis
        unsqueezed = layout.unsqueezed(mask=mask)
    else:
        unsqueezed = layout.unsqueezed(axes)
    unsqueezed_ref = np.expand_dims(np_ref, axis=axes)
    cmp_layout_and_array(unsqueezed, unsqueezed_ref)

    if base_shape == unsqueezed.shape:
        assert unsqueezed is layout
    mask = unsqueezed.unit_extents_mask()
    assert mask == unit_extents_mask(unsqueezed_ref.shape)


@pytest.mark.parametrize(
    (
        "layout_spec",
        "perm",
        "slices",
        "axis",
        "expected_max_itemsize",
        "new_itemsize",
        "keep_dim",
    ),
    [
        (
            LayoutSpec(shape, itemsize, stride_order),
            Param("perm", permutation),
            Param("slices", slices),
            Param("axis", axis),
            Param("expected_max_itemsize", expected_max_itemsize),
            Param("new_itemsize", new_itemsize),
            Param("keep_dim", keep_dim),
        )
        for shape, permutation, slices, stride_order, itemsize, axis, expected_max_itemsize, new_itemsize in [
            ((12,), None, None, "C", 1, -1, 4, 1),
            ((12,), None, None, "F", 1, 0, 4, 1),
            ((12,), None, None, "C", 4, -1, 16, 8),
            ((12,), None, None, "F", 4, 0, 16, 8),
            ((16, 5, 4, 6), None, None, "C", 2, -1, 4, 4),
            ((16, 5, 4, 6), None, None, "F", 2, 0, 16, 4),
            ((11, 5, 9), None, _S[:, :, -1:], "C", 2, 2, 2, 2),
            ((11, 5, 9), None, _S[:, :, -1:], "F", 2, 0, 2, 2),
            ((12, 3, 24), (1, 2, 0), _S[::-1, 20:, 1:], "C", 2, 1, 8, 8),
            ((12, 3, 24), (1, 2, 0), _S[1:, ::-1, 10:], "F", 2, 2, 4, 4),
            ((1, 3) + (1,) * 61 + (4,), None, None, "C", 2, -1, 8, 8),
            ((4, 3) + (1,) * 61 + (3,), None, None, "F", 2, 0, 8, 4),
            ((4, 3) + (1,) * 61 + (3,), None, None, "F", 2, 0, 8, 8),
        ]
        for keep_dim in [True, False]
        if keep_dim or shape[axis] * itemsize // new_itemsize == 1
    ],
    ids=idfn,
)
def test_packed_unpacked(
    layout_spec,
    perm,
    slices,
    axis,
    expected_max_itemsize,
    new_itemsize,
    keep_dim,
):
    perm = perm.value
    slices = slices.value
    axis = axis.value
    expected_max_itemsize = expected_max_itemsize.value
    new_itemsize = new_itemsize.value
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if perm is not None:
        layout = layout.permuted(perm)
        np_ref = np_ref.transpose(perm)
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]

    assert layout.max_compatible_itemsize(axis=axis) == expected_max_itemsize
    packed = layout.packed(new_itemsize, axis=axis, keep_dim=keep_dim)
    if new_itemsize == layout_spec.itemsize:
        assert packed is layout
    # numpy does not allow specifying the axis to repack,
    # so we need to transpose the array
    packed_ref = (
        np_ref.transpose(layout.stride_order).view(dtype=dtype_from_itemsize(new_itemsize)).transpose(inv(layout.stride_order))
    )
    if not keep_dim and packed_ref.shape[axis] == 1:
        packed_ref = packed_ref.squeeze(axis)
    cmp_layout_and_array(packed, packed_ref)
    unpacked = packed.unpacked(layout_spec.itemsize, axis=axis, add_dim=not keep_dim)
    assert unpacked == layout
    cmp_layout_and_array(unpacked, np_ref)


@pytest.mark.parametrize(
    (
        "layout_spec",
        "perm",
        "slices",
        "new_stride_order",
    ),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("perm", permutation),
            Param("slices", slices),
            Param("new_stride_order", new_stride_order),
        )
        for shape, permutation, slices in [
            ((), None, None),
            ((1,), None, None),
            ((7,), None, None),
            ((7,), None, _S[3:6]),
            ((7,), None, _S[::-1]),
            ((5, 11), None, None),
            ((5, 11), None, _S[1:-1]),
            ((5, 11), None, _S[::-1, 3:10]),
            ((5, 11), None, _S[1:4, ::-1]),
            ((5, 11), None, _S[-1:,]),
            ((3, 5, 7), (1, 0, 2), None),
        ]
        for stride_order in ["C", "F"]
        for new_stride_order in ["C", "F", "K"] + random_permutations(py_rng, len(shape))
    ],
    ids=idfn,
)
def test_to_dense(layout_spec, perm, slices, new_stride_order):
    perm = perm.value
    slices = slices.value
    new_stride_order = new_stride_order.value

    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if perm is not None:
        layout = layout.permuted(perm)
        np_ref = np_ref.transpose(perm)
    if slices is not None:
        layout = layout[slices].layout
        np_ref = np_ref[slices]

    if isinstance(new_stride_order, str):
        dense = layout.to_dense(new_stride_order)
        dense_ref = np_ref.copy(order=new_stride_order)
    else:
        assert isinstance(new_stride_order, tuple)
        assert len(new_stride_order) == len(layout.shape)
        dense = layout.to_dense(new_stride_order)
        dense_ref = np_ref.transpose(new_stride_order).copy(order="C").transpose(inv(new_stride_order))

    if new_stride_order == "C":
        assert dense.is_contiguous_c
        stride_order = "C"
    elif new_stride_order == "F":
        assert dense.is_contiguous_f
        stride_order = "F"
    else:
        assert dense.is_contiguous_any
        stride_order = layout.stride_order if new_stride_order == "K" else new_stride_order
        assert dense.permuted(stride_order).is_contiguous_c
    assert dense.has_stride_order(stride_order)
    assert dense.offset_bounds == (0, np_ref.size - 1)
    dense = dense.squeezed()
    dense_ref = dense_ref.squeeze()
    cmp_layout_and_array(dense, dense_ref)


class SliceErr(Enum):
    ZERO_STEP = "slice step cannot be zer"
    TOO_MANY_SLICES = "is greater than the number of dimensions"
    OUT_OF_RANGE = "out of range for axis"
    TYPE_ERROR = "Expected slice instance, integer, or Ellipsis"


@pytest.mark.parametrize(
    ("layout_spec", "slices", "is_exhaustive", "error_msg"),
    [
        (
            LayoutSpec(shape, py_rng.choice(_ITEMSIZES), stride_order),
            Param("slices", slices),
            Param("is_exhaustive", is_exhaustive),
            error_msg,
        )
        for stride_order in ["C", "F"]
        for shape, slices, is_exhaustive, error_msg in [
            ((), (), True, None),
            ((12,), _S[:], True, None),
            ((13,), _S[::-1], True, None),
            ((13,), [_S[::-1], _S[::-1]], True, None),
            ((13,), [_S[::-1], _S[1:-1], _S[::-1]], True, None),
            ((13,), _S[2:-3], True, None),
            ((13,), _S[2:-3:2], False, None),
            ((13,), _S[-3:2:-2], False, None),
            ((13,), [_S[-3:2:-2], _S[1:3]], False, None),
            ((3, 5), [_S[:2], _S[:, 3:]], False, None),
            ((3, 5), _S[5:4], True, None),
            ((3, 5), (0,), stride_order == "C", None),
            ((3, 5), (..., -1), stride_order == "F", None),
            ((3, 5), _S[:, ::0], True, SliceErr.ZERO_STEP),
            ((3, 5), _S[:, :-1, :2], True, SliceErr.TOO_MANY_SLICES),
            ((11, 12, 3), _S[:, 0, :-1], False, None),
            ((11, 12, 3), _S[0, 1, :-1], stride_order == "C", None),
            ((11, 12, 3, 5), [0, 1], stride_order == "C", None),
            ((11, 12, 3, 5), (0, 1), stride_order == "C", None),
            ((11, 12, 3, 5), (..., 0, 1), stride_order == "F", None),
            ((11, 12, 3, 5), _S[:, 1, :-1], False, None),
            ((11, 12, 3, 5), _S[1:-1, ..., :-1], False, None),
            ((11, 12, 3), _S[0, 1, 2], True, None),
            ((11, 12, 3), _S[0, 1, 5], True, SliceErr.OUT_OF_RANGE),
            ((11, 12, 3), -2, stride_order == "C", None),
            ((11, 12, 3), -42, True, SliceErr.OUT_OF_RANGE),
            ((11, 12, 3), ["abc"], True, SliceErr.TYPE_ERROR),
            (long_shape(py_rng, 64), (slice(None, None, -1),) * 64, True, None),
        ]
    ],
    ids=idfn,
)
def test_slice(layout_spec, slices, is_exhaustive, error_msg):
    slices = slices.value
    is_exhaustive = is_exhaustive.value
    skip_unsupported_numpy(layout_spec.shape)
    layout = layout_spec.layout
    np_ref = layout_spec.np_ref
    if error_msg is None:
        sliced_layout = layout
        sliced_np = np_ref
        if not isinstance(slices, list):
            slices = [slices]
        for sl in slices:
            sliced_layout = sliced_layout[sl]
            sliced_np = sliced_np[sl]
        layout = sliced_layout.layout
        cmp_layout_and_array(layout, sliced_np)
        if sliced_np.ndim > 0:
            np_offset = sliced_np.ctypes.data - np_ref.ctypes.data
            layout_offset = sliced_layout.slice_offset_in_bytes
            assert layout_offset == np_offset
            assert sliced_layout.slice_offset * layout_spec.itemsize == layout_offset
        assert layout.is_unique
        assert layout.is_exhaustive == is_exhaustive
    else:
        if error_msg == SliceErr.TYPE_ERROR:
            error_cls = TypeError
        elif error_msg == SliceErr.OUT_OF_RANGE:
            error_cls = IndexError
        else:
            error_cls = ValueError
        with pytest.raises(error_cls, match=error_msg.value):
            layout[slices]


def test_layout_iter():
    layout = StridedLayout.dense([], itemsize=1)
    assert layout.shape == ()

    with pytest.raises(TypeError, match="The layout is a scalar, it has no length"):
        len(layout)

    with pytest.raises(ValueError, match="is greater than the number of dimensions"):
        list(layout)

    layout = StridedLayout.dense(5, itemsize=4)
    scalars = list(layout)
    assert len(scalars) == 5
    for i, scalar_slice in enumerate(scalars):
        assert scalar_slice.slice_offset == i
        scalar = scalar_slice.layout
        assert scalar.ndim == 0
        assert scalar.volume == 1
        assert scalar.shape == ()
        assert scalar.itemsize == 4
        assert scalar.strides == ()
        assert scalar.strides_in_bytes == ()

    for shape, strides, divide_strides in [
        ((i for i in [3, 5]), [1, 3], False),
        ([3, 5], [8, 24], True),
    ]:
        layout = StridedLayout(shape, strides, itemsize=8, divide_strides=divide_strides)
        assert layout.shape == (3, 5)
        assert layout.strides == (1, 3)
        for i, row_slice in enumerate(layout):
            assert row_slice.slice_offset == i
            row = row_slice.layout
            assert row.ndim == 1
            assert row.volume == 5
            assert row.shape == (5,)
            assert row.itemsize == 8
            assert row.strides == (3,)
            assert row.strides_in_bytes == (24,)


@pytest.mark.parametrize(
    ("stride_order", "neg_axes"),
    [
        (Param("stride_order", stride_order), Param("neg_axes", neg_axes))
        for neg_axes in all_subsets(4)
        for stride_order in ["C", "F"] + random_permutations(py_rng, 4, sample_size=1)
    ],
    ids=idfn,
)
def test_min_max_stride(stride_order, neg_axes):
    stride_order = stride_order.value
    neg_axes = neg_axes.value
    shape = (5, 4, 3, 2)
    layout = StridedLayout.dense(shape, itemsize=8, stride_order=stride_order)
    if len(neg_axes) > 0:
        slices = tuple(_S[::-1] if i in neg_axes else _S[:] for i in range(4))
        layout = layout[slices].layout
    expected_min_stride = 1
    if stride_order == "C":
        arg_min = len(shape) - 1
        arg_max = 0
        expected_max_stride = math.prod(shape[1:])
    elif stride_order == "F":
        arg_min = 0
        arg_max = len(shape) - 1
        expected_max_stride = math.prod(shape[:-1])
    else:
        arg_min = stride_order[-1]
        arg_max = stride_order[0]
        expected_max_stride = math.prod(shape[i] for i in stride_order[1:])

    if arg_min in neg_axes:
        expected_min_stride = -expected_min_stride
    if arg_max in neg_axes:
        expected_max_stride = -expected_max_stride

    assert layout.min_stride == expected_min_stride
    assert layout.max_stride == expected_max_stride


def test_min_max_stride_order_empty_or_singleton():
    layout = StridedLayout.dense((1, 1, 1), 2)
    assert layout.min_stride == 1
    assert layout.max_stride == 1

    layout = StridedLayout((1, 1, 1, 1, 1), (0, 0, 0, 0, 0), 4)
    assert layout.min_stride == 1
    assert layout.max_stride == 1

    layout = StridedLayout((500, 3, 0, 23, 1), (2, 3, -7, 4, 1), 2)
    assert layout.min_stride == 1
    assert layout.max_stride == 1
