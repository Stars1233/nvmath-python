# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
import math
import typing

import numpy as np
from hypothesis.extra.numpy import arrays
from hypothesis.strategies import SearchStrategy, composite, integers, just, lists, permutations, sampled_from

from nvmath.linalg._internal.utils import calculate_strides

problem_size_mnk = integers(min_value=1, max_value=256)


@composite
def matmul_problem_size(draw):
    """Generates shapes for a matrix multiplication problem."""
    m = draw(problem_size_mnk)
    n = draw(problem_size_mnk)
    k = draw(problem_size_mnk)
    return m, n, k


def numpy_dtype_to_torch(dtype: np.dtype):
    import torch

    _map = {
        np.float16: torch.float16,
        np.float32: torch.float32,
        np.float64: torch.float64,
        np.complex64: torch.complex64,
        np.complex128: torch.complex128,
        np.int8: torch.int8,
        np.int16: torch.int16,
        np.int32: torch.int32,
        np.int64: torch.int64,
    }
    return _map[dtype.type]


# Generate data in range [0, 5] to match sample_matrix() from utils
# Only non-negative reals to avoid catastrophic cancellation
element_properties: dict[str, typing.Any] = {
    "allow_infinity": False,
    "allow_nan": False,
    "allow_subnormal": False,
    "max_magnitude": np.sqrt(50),
    "min_magnitude": 0,
    "max_value": 5,
    "min_value": 0,
}


@composite
def matrix(draw, *, shape: typing.Sequence[int], dtype: np.dtype, axis_order: tuple[int, ...], framework: str):
    """Generates a matrix of given shape, dtype, memory layout, and framework.

    axis_order is a permutation of range(len(shape)) where axis_order[0] is the
    fastest axis (smallest stride). Consistent with calculate_strides() convention.
    """
    # NOTE: It is unfeasible for hypothesis to explore a parameter space where
    # all elements of the input arrays are unique, so most of the time, arrays
    # contain just a few unique values
    dtype = np.dtype(dtype)
    data = draw(arrays(dtype=dtype, shape=tuple(shape), elements=element_properties))

    # Element strides (not byte strides); calculate_strides gives contiguous layout
    strides = calculate_strides(shape, axis_order)
    total = math.prod(shape)

    match framework:
        case "numpy":
            buf = np.empty(total, dtype=dtype)
            result = np.lib.stride_tricks.as_strided(buf, shape=tuple(shape), strides=[s * dtype.itemsize for s in strides])
            result[...] = data
            return result
        case "cupy":
            import cupy as cp

            buf = cp.empty(total, dtype=dtype)
            result = cp.lib.stride_tricks.as_strided(buf, shape=tuple(shape), strides=[s * dtype.itemsize for s in strides])
            result[...] = cp.asarray(data)
            return result
        case "torch-cpu":
            import torch

            buf = torch.empty(total, dtype=numpy_dtype_to_torch(dtype))
            result = buf.as_strided(tuple(shape), strides)
            result.copy_(torch.as_tensor(data))
            return result
        case "torch-gpu":
            import torch

            buf = torch.empty(total, dtype=numpy_dtype_to_torch(dtype), device="cuda")
            result = buf.as_strided(tuple(shape), strides)
            result.copy_(torch.as_tensor(data))
            return result
        case _:
            raise ValueError(f"Unknown framework: {framework}")


@composite
def broadcast_compatible_shape(draw, *, shape: typing.Sequence[int], same_length: bool = False) -> tuple[int]:
    """Converts shape into another shape that is broadcast compatible."""
    ndim0 = len(shape)
    ndim1 = len(shape) if same_length else draw(integers(min_value=0, max_value=ndim0))
    diff = ndim0 - ndim1
    new_shape = []
    for i in range(ndim1):
        new_shape.append(draw(sampled_from((shape[i + diff], 1))))
    result = tuple(new_shape)
    assert (same_length and len(result) == len(shape)) or len(result) <= len(shape)
    for i in range(len(result)):
        assert result[i] == shape[i + diff] or result[i] == 1
    return result


@composite
def tilable_matrix(
    draw,
    *,
    batch_shape: typing.Sequence[int],
    shape: typing.Sequence[int],
    dtype: np.dtype,
    matrix_axis_order: tuple[int, ...],
    framework: str,
):
    """Generates a matrix of given shape and dtype that is tilable.

    The trailing matrix dimensions are contiguous in matrix_axis_order order
    (axis_order[0] is fastest). The leading batch dimensions are in arbitrary
    (random) memory order, all slower than the matrix dimensions.
    """
    n_batch = len(batch_shape)
    n_shape = len(shape)

    batch_perm: list[int] = draw(permutations(range(n_batch)))

    # Full axis_order for shape (*batch_shape, *shape):
    # - Matrix dims (positions n_batch..n_batch+n_shape-1) in matrix_axis_order order
    # (fastest)
    # - Batch dims (positions 0..n_batch-1) in batch_perm order (slower)
    full_axis_order = tuple([n_batch + matrix_axis_order[i] for i in range(n_shape)] + [batch_perm[j] for j in range(n_batch)])

    return draw(
        matrix(
            shape=(*batch_shape, *shape),
            dtype=dtype,
            axis_order=full_axis_order,
            framework=framework,
        )
    )


@composite
def implicitly_batched_matmul_matrices(
    draw,
    *,
    axis_order_strategy: SearchStrategy,
    framework_strategy: SearchStrategy,
    dtype: np.dtype,
    min_batch: int = 0,
    max_batch: int = 4,
    with_broadcasting: bool = True,
):
    """Generate three implicitly batched 2D+ matrices for matrix multiplication.

    Two types of broadcasting are implemented:
     - batch dimension broadcast
     - broadcasting of c matrix non-batch dimensions

    """
    batch_shape: tuple[int] = tuple(
        draw(
            lists(
                integers(min_value=1, max_value=4),
                min_size=min_batch,
                max_size=max_batch,
            )
        )
    )

    m, n, k = draw(matmul_problem_size())

    if with_broadcasting:
        a_batch_shape = draw(broadcast_compatible_shape(shape=batch_shape, same_length=False))
        b_batch_shape = draw(broadcast_compatible_shape(shape=batch_shape, same_length=False))
        c_batch_shape = draw(broadcast_compatible_shape(shape=batch_shape, same_length=False))
        c_shape = draw(broadcast_compatible_shape(shape=(m, n), same_length=True))
    else:
        a_batch_shape = batch_shape
        b_batch_shape = batch_shape
        c_batch_shape = batch_shape
        c_shape = (m, n)

    framework = draw(framework_strategy)

    a = draw(
        tilable_matrix(
            batch_shape=a_batch_shape,
            shape=(m, k),
            dtype=dtype,
            matrix_axis_order=draw(axis_order_strategy),
            framework=framework,
        )
    )
    b = draw(
        tilable_matrix(
            batch_shape=b_batch_shape,
            shape=(k, n),
            dtype=dtype,
            matrix_axis_order=draw(axis_order_strategy),
            framework=framework,
        )
    )
    c = draw(
        tilable_matrix(
            batch_shape=c_batch_shape,
            shape=c_shape,
            dtype=dtype,
            matrix_axis_order=draw(axis_order_strategy),
            framework=framework,
        )
    )
    return a, b, c


@composite
def explicitly_batched_matmul_matrices(
    draw,
    *,
    implicit: dict[str, typing.Any],
    min_batch: int = 0,
    max_batch: int = 16,
    framework_strategy: SearchStrategy,
):
    """Generate three explicitly batched 2D+ matrices for matrix multiplication.

    The matrices are generated as implicitly batched and then stacked into lists.
    """
    framework = draw(framework_strategy)
    a_list = []
    b_list = []
    c_list = []
    for _ in range(draw(integers(min_value=min_batch, max_value=max_batch))):
        a, b, c = draw(
            implicitly_batched_matmul_matrices(
                **implicit,
                framework_strategy=just(framework),
            )
        )
        a_list.append(a)
        b_list.append(b)
        c_list.append(c)
    return a_list, b_list, c_list
