# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Utilities.
"""

__all__ = [
    "axis_order_in_memory",
    "calculate_strides",
    "check_batch_tileable",
    "get_handle",
    "pointer_aligned_to",
]

import typing

from nvmath._internal import threadsafe
from nvmath.bindings import cublas
from nvmath.bindings import cublasLt as cublaslt
from nvmath.internal import utils
from nvmath.internal._layout import StridedLayout


def create_cublas_handle(device_id: int) -> int:
    """
    Currently for internal use only.
    """
    with utils.device_ctx(device_id):
        return cublas.create()


def create_cublaslt_handle(device_id: int) -> int:
    """
    Currently for internal use only.
    """
    with utils.device_ctx(device_id):
        return cublaslt.create()


# One per-thread cache per binding. Keying by `device_id` alone (rather than a
# shared `(binding, device_id)` dict) keeps the two bindings' handles in
# separate caches, which avoids any chance of a binding-string typo aliasing
# the wrong handle. cuBLAS handles must not be shared across threads
# (https://docs.nvidia.com/cuda/cublas/#thread-safety); cuBLASLt handles could
# be shared, but per-thread caching is a safe superset and keeps both paths
# uniform.
_CUBLAS_CACHE = threadsafe.HandleCache[int](
    create=create_cublas_handle,
    destroy=cublas.destroy,
)
_CUBLASLT_CACHE = threadsafe.HandleCache[int](
    create=create_cublaslt_handle,
    destroy=cublaslt.destroy,
)


def get_handle(device_id: int, binding="cublaslt") -> int:
    """
    Retrieve the cuBLAS[lt] library handle for the specified device. If one doesn't exist,
    create, cache, and return the handle.

    Handles are cached per thread in a separate cache per binding, so a single
    thread can hold distinct handles for ``"cublas"`` and ``"cublaslt"`` on the
    same device. Cached handles are released automatically when the owning
    thread exits.
    """
    if binding == "cublas":
        cache = _CUBLAS_CACHE
    elif binding == "cublaslt":
        cache = _CUBLASLT_CACHE
    else:
        raise ValueError(f"{binding} is not a valid library name.")
    return cache.get(device_id)


def pointer_aligned_to(address):
    """
    Return the number of bytes the address is aligned to.
    """
    return address & ~(address - 1)


def axis_order_in_memory(strides):
    """
    Compute the order in which the axes appear in memory.
    """
    if len(strides) == 0:
        return ()

    _, axis_order = zip(*sorted(zip(strides, range(len(strides)), strict=True)), strict=True)

    return axis_order


def calculate_strides(shape: typing.Sequence[int], axis_order: typing.Sequence[int], min_stride: int = 1):
    """
    Calculate the strides for the provided shape and axis order.
    """
    assert len(axis_order) == len(shape), f"axis_order length ({len(axis_order)}) must equal shape length ({len(shape)})"
    assert len(set(axis_order)) == len(axis_order), f"axis_order must not contain duplicates: {axis_order}"
    assert set(axis_order) == set(range(len(shape))), f"axis_order must be permutation of range({len(shape)}): {axis_order}"

    strides: list[None | int] = [None] * len(shape)

    stride = min_stride
    for axis in axis_order:
        strides[axis] = stride
        stride *= shape[axis]

    return strides


def check_batch_tileable(batch_shape, batch_strides):
    """
    Whether the batch layout can be expressed the way cuBLAS strided-batched
    expects: a single ``batch_count`` and a single stride ``S`` per operand,
    so that tile ``k`` lives at ``base + k * S`` for ``k = 0, ..., N - 1``.

    Two scenarios -- and only these two -- satisfy that form:

    (a) Regular grid of distinct tiles (``S > 0``): tiles sit at evenly
        spaced offsets along *some* axis order, with the gap between
        consecutive tiles allowed to be larger than the tile itself (i.e.
        padded/gapped batches are fine).

    (b) Replicated tile (``S == 0``): every batch index lands on the same
        tile, i.e. *every* non-singleton batch dim has stride 0. Typical
        source: ``torch.expand`` (or equivalent) applied so that the
        operand has no real batch axis -- e.g. ``A.unsqueeze(0).expand(N,
        M, K)``.

    A broadcast on *some* batch axis combined with a real (stride > 0)
    batch axis of size > 1 does **not** qualify for (b) -- it isn't
    tileable in the form above and is rejected. E.g.
    ``X.unsqueeze(0).expand(N1, P, M, K)`` with both ``N1 > 1`` *and*
    ``P > 1`` has batch strides ``(0, M*K)`` and is not tileable.
    """
    # Empty / all-size-1 batch: degenerate intersection of (a) and (b),
    # trivially tileable.
    if all(n == 1 for n in batch_shape):
        return True

    layout = StridedLayout(batch_shape, batch_strides, itemsize=1)

    # Scenario (a): tiles on a regular grid in some axis order.
    # `"K"` lets the grid be in any order (C, F, or a permutation), and
    # `allow_leading_dim_stride=True` lets the smallest stride exceed 1.
    if layout.is_dense("K", allow_leading_dim_stride=True):
        return True

    # Scenario (b): pure broadcast. Flatten collapses to a single 1-D dim
    # with stride 0 iff every non-size-1 batch stride is 0; mixed
    # broadcast + non-broadcast dims don't collapse and get rejected.
    flat = layout.flattened()
    return flat.ndim == 1 and flat.strides[0] == 0
