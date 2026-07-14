# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import numpy as np
import pytest

from nvmath._internal.utils import get_addresses_of_elements

# ---------------------------------------------------------------------------
# Helpers shared by get_addresses_of_elements tests
# ---------------------------------------------------------------------------


def _native_element_addresses(array: np.ndarray) -> tuple:
    """Reference: enumerate elements in C order and collect their byte addresses."""
    import itertools

    addresses = []
    for idx in itertools.product(*[range(s) for s in array.shape]):
        # Use a 1-element slice to get an array view (scalar indexing returns a
        # numpy scalar which has no .ctypes attribute)
        addresses.append(array[tuple(slice(c, c + 1) for c in idx)].ctypes.data)
    return tuple(addresses)


def _addresses_via_get(array: np.ndarray) -> tuple:
    """Wrapper: call get_addresses_of_elements with a numpy array."""
    itemsize = array.itemsize
    base_ptr = array.ctypes.data
    element_strides = tuple(s // itemsize for s in array.strides)
    return tuple(get_addresses_of_elements(array.shape, element_strides, base_ptr, itemsize).tolist())


# ---------------------------------------------------------------------------
# Correctness tests: get_addresses_of_elements vs native indexing
# ---------------------------------------------------------------------------

_DTYPES = [np.float32, np.float64, np.complex64]


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_1d(dtype):
    array = np.arange(8, dtype=dtype)
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_2d_c_order(dtype):
    # C-contiguous: last axis is fastest in memory
    array = np.arange(12, dtype=dtype).reshape(3, 4)
    assert array.flags["C_CONTIGUOUS"]
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_2d_fortran_order(dtype):
    # Fortran-contiguous: first axis is fastest in memory; traversal is still C order
    array = np.asfortranarray(np.arange(12, dtype=dtype).reshape(3, 4))
    assert array.flags["F_CONTIGUOUS"]
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_2d_non_contiguous_slice(dtype):
    # Every other column via slicing: stride[1] doubles
    base = np.arange(24, dtype=dtype).reshape(3, 8)
    array = base[:, ::2]  # shape (3, 4), non-contiguous
    assert not array.flags["C_CONTIGUOUS"]
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_2d_transposed(dtype):
    # Transpose swaps axes and strides; traversal is still C order over (4, 3) shape
    base = np.arange(12, dtype=dtype).reshape(3, 4)
    array = base.T  # shape (4, 3)
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_3d(dtype):
    array = np.arange(24, dtype=dtype).reshape(2, 3, 4)
    assert _addresses_via_get(array) == _native_element_addresses(array)


@pytest.mark.parametrize("dtype", _DTYPES)
def test_get_addresses_consistent_across_layouts(dtype):
    # Two tensors with the same logical content but different memory layouts must
    # produce pointer arrays in the same logical order (C order), enabling consistent
    # batched-GEMM pointer pairing.
    a_c = np.arange(12, dtype=dtype).reshape(3, 4)  # C-contiguous
    a_f = np.asfortranarray(a_c)  # Fortran-contiguous, same logical content
    addrs_c = _addresses_via_get(a_c)
    addrs_f = _addresses_via_get(a_f)
    # Logical element [i,j] appears at position i*4+j in C-order traversal for both
    for flat_idx, (addr_c, addr_f) in enumerate(zip(addrs_c, addrs_f, strict=False)):
        i, j = divmod(flat_idx, 4)
        assert addr_c == a_c[i : i + 1, j : j + 1].ctypes.data
        assert addr_f == a_f[i : i + 1, j : j + 1].ctypes.data


# ---------------------------------------------------------------------------
# Traversal order test: consecutive addresses step by the fastest-axis stride
# ---------------------------------------------------------------------------


def test_traversal_order_1d():
    # For a 1D contiguous array the addresses must be evenly spaced by itemsize.
    dtype = np.float32
    array = np.arange(6, dtype=dtype)
    addrs = _addresses_via_get(array)
    diffs = [addrs[i + 1] - addrs[i] for i in range(len(addrs) - 1)]
    assert all(d == array.itemsize for d in diffs)


def test_traversal_order_2d_last_axis_fastest():
    # For a 2D C-contiguous array, traversal is C order: last axis (columns) varies
    # fastest. Consecutive pairs within the same row differ by itemsize * col_stride.
    dtype = np.float32
    nrows, ncols = 3, 5
    array = np.arange(nrows * ncols, dtype=dtype).reshape(nrows, ncols)
    col_elem_stride = array.strides[1] // array.itemsize

    addrs = _addresses_via_get(array)
    expected_step = array.itemsize * col_elem_stride
    for row in range(nrows):
        for col in range(ncols - 1):
            idx = row * ncols + col
            assert addrs[idx + 1] - addrs[idx] == expected_step
