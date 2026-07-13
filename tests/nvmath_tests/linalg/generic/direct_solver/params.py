# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import pytest

from ....helpers import requires_cupy, requires_torch

# Shared framework cases for tests parameterized by framework and memory space.
# "numpy/cupy" lets sample_matrix choose NumPy or CuPy based on use_cuda.
GPU_FRAMEWORK_CASES = (
    pytest.param("numpy/cupy", True, marks=requires_cupy, id="cupy"),
    pytest.param("torch", True, marks=requires_torch, id="torch-gpu"),
)

CPU_FRAMEWORK_CASES = (
    pytest.param("numpy/cupy", False, id="numpy"),
    pytest.param("torch", False, marks=requires_torch, id="torch-cpu"),
)

GPU_FRAMEWORKS = pytest.mark.parametrize("framework, use_cuda", GPU_FRAMEWORK_CASES)
CPU_FRAMEWORKS = pytest.mark.parametrize("framework, use_cuda", CPU_FRAMEWORK_CASES)
ALL_FRAMEWORK_CASES = CPU_FRAMEWORK_CASES + GPU_FRAMEWORK_CASES
ALL_FRAMEWORKS = pytest.mark.parametrize("framework, use_cuda", ALL_FRAMEWORK_CASES)

BATCH_FORMAT_COMBINATIONS = pytest.mark.parametrize(
    "batch_shape, lhs_batch_format, rhs_batch_format",
    [
        pytest.param(None, None, None, id="none"),
        pytest.param((4,), "explicit", "explicit", id="explicit-explicit"),
        pytest.param((4,), "explicit", "implicit", id="explicit-implicit-b4"),
        pytest.param((2, 3), "explicit", "implicit", id="explicit-implicit-2x3"),
        pytest.param((3, 2), "implicit", "explicit", id="implicit-explicit"),
        pytest.param((2, 2), "implicit", "implicit", id="implicit-implicit"),
    ],
)

BATCH_FORMATS = pytest.mark.parametrize(
    "batch_shape, batch_format",
    [
        pytest.param(None, None, id="non-batched"),
        pytest.param((2,), "explicit", id="explicit"),
        pytest.param((2, 3), "implicit", id="implicit"),
    ],
)

ALL_DTYPES = pytest.mark.parametrize("dtype", ("float32", "float64", "complex64", "complex128"))
