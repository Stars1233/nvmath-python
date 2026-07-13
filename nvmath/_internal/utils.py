# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import logging
import typing
from collections.abc import Sequence

import numpy as np

LoggerLike: typing.TypeAlias = logging.Logger | logging.LoggerAdapter


def get_addresses_of_elements(
    shape: Sequence[int],
    stride: Sequence[int],
    address: int,
    itemsize: int,
) -> np.ndarray:
    """Return the byte address of each element in a strided memory block.

    Elements are enumerated in C order (last dimension varies fastest). The traversal
    order is canonical and independent of the tensor's memory layout, so multiple calls
    with different tensors always produce consistently ordered pointer arrays suitable
    for use as batched-GEMM pointer arrays.

    Args:
        shape: the number of elements along each dimension of the memory block
        stride: the stride along each dimension, in number of elements
        address: the base byte address of the memory block (address of the element at
            the all-zero index)
        itemsize: the number of bytes per element

    Returns:
        A 1-D numpy array of byte addresses (dtype np.intp), one per element, in C order.
    """
    assert len(stride) == len(shape), f"stride length {len(stride)} must match shape length {len(shape)}"
    assert itemsize >= 0, f"itemsize must be non-negative, got {itemsize}"
    assert address >= 0, f"address must be non-negative, got {address}"
    if not shape:
        return np.array([address], dtype=np.intp)
    offset_vecs = [np.arange(shape[a], dtype=np.intp) * (itemsize * stride[a]) for a in range(len(shape))]
    return address + sum(np.ix_(*offset_vecs)).ravel()  # type: ignore[union-attr]
