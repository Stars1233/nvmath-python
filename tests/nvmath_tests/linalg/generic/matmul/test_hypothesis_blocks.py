# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
import numpy as np
from hypothesis import given
from hypothesis.strategies import sampled_from

from .hypothesis_blocks import (
    explicitly_batched_matmul_matrices,
    implicitly_batched_matmul_matrices,
)


@given(
    implicitly_batched_matrices=implicitly_batched_matmul_matrices(
        dtype=np.float32,
        axis_order_strategy=sampled_from([(1, 0), (0, 1)]),
        framework_strategy=sampled_from(["numpy"]),
    ),
)
def test_implicitly_batched_matmul_matrices(implicitly_batched_matrices):
    a, b, c = implicitly_batched_matrices
    print(a.shape, b.shape, c.shape)
    assert a.shape[-1] == b.shape[-2]
    assert c.shape[-2] in (1, a.shape[-2])
    assert c.shape[-1] in (1, b.shape[-1])
    assert min(len(a.shape), len(b.shape), len(c.shape)) >= 2
    max_dim = max(len(a.shape), len(b.shape), len(c.shape))
    for i in range(3, max_dim):
        a_shape = a.shape[-i] if i <= len(a.shape) else 1
        b_shape = b.shape[-i] if i <= len(b.shape) else 1
        c_shape = c.shape[-i] if i <= len(c.shape) else 1
        max_shape = max(a_shape, b_shape, c_shape)
        assert a_shape == max_shape or a_shape == 1
        assert b_shape == max_shape or b_shape == 1
        assert c_shape == max_shape or c_shape == 1


@given(
    explicitly_batched_matrices=explicitly_batched_matmul_matrices(
        implicit={
            "dtype": np.float32,
            "axis_order_strategy": sampled_from([(1, 0), (0, 1)]),
        },
        framework_strategy=sampled_from(["numpy"]),
    ),
)
def test_explicitly_batched_matmul_matrices(explicitly_batched_matrices):
    a_list, b_list, c_list = explicitly_batched_matrices
    print(len(a_list), len(b_list), len(c_list))
    assert len(a_list) == len(b_list) == len(c_list)
