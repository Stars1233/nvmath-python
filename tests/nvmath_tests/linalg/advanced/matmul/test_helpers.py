# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Tests for helper functions.
"""

import pytest

from .fp4_utils import HAS_TORCH_2_9

if not HAS_TORCH_2_9:
    pytest.skip("Torch >= 2.9 required for float8_e4m3fn support", allow_module_level=True)

import torch

from nvmath.linalg.advanced.helpers.matmul import BlockScalingFormat, to_block_scale


def _make_scale(shape, dtype=torch.uint8, device="cpu"):
    n = 1
    for s in shape:
        n *= s
    return torch.arange(n, dtype=dtype, device=device).reshape(shape)


@pytest.mark.parametrize(
    "operand_shape, scale_shape, fmt, axis",
    [
        # 2D
        ((128, 64), (128, 4), BlockScalingFormat.NVFP4, -1),
        # single batch dim
        ((2, 128, 64), (2, 128, 4), BlockScalingFormat.NVFP4, -1),
        # two batch dims
        ((2, 3, 128, 64), (2, 3, 128, 4), BlockScalingFormat.NVFP4, -1),
    ],
)
def test_to_block_scale_valid_shapes(operand_shape, scale_shape, fmt, axis):
    """to_block_scale should succeed and return a 1D tensor for valid inputs."""
    scale = _make_scale(scale_shape)
    out = to_block_scale(scale, operand_shape, fmt, axis=axis)
    assert out.ndim == 1
    assert out.numel() == scale.numel()
    assert out.dtype == scale.dtype


@pytest.mark.parametrize(
    "operand_shape, wrong_scale_shape, fmt, axis",
    [
        # wrong matrix dim
        ((128, 64), (128, 8), BlockScalingFormat.NVFP4, -1),
        # wrong batch dim size
        ((2, 128, 64), (3, 128, 4), BlockScalingFormat.NVFP4, -1),
        # missing batch dim
        ((2, 3, 128, 64), (2, 128, 4), BlockScalingFormat.NVFP4, -1),
        # two batch dims swapped
        ((2, 3, 128, 64), (3, 2, 128, 4), BlockScalingFormat.NVFP4, -1),
    ],
)
def test_to_block_scale_invalid_shapes_raise(operand_shape, wrong_scale_shape, fmt, axis):
    """to_block_scale must raise ValueError for any shape mismatch."""
    scale = _make_scale(wrong_scale_shape)
    with pytest.raises(ValueError, match="shape"):
        to_block_scale(scale, operand_shape, fmt, axis=axis)
