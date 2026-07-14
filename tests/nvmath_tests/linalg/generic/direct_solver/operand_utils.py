# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import importlib
from collections.abc import Sequence

from nvmath.internal.utils import infer_object_package

from ....helpers import sequence_aware
from ...utils import compare_tensors
from .solver_utils import create_solver_operands


def _parse_operand_package(operand):
    package = infer_object_package(operand)
    return package, importlib.import_module(package)


@sequence_aware()
def copy_operand(operand):
    """Copy an operand or explicit operand batch while preserving its package."""
    package, _ = _parse_operand_package(operand)
    if package == "torch":
        return operand.clone()
    return operand.copy()


@sequence_aware(reducer=all)
def operand_was_overwritten(operand, reference):
    """Return whether an operand or explicit operand batch differs from its copy."""
    return not compare_tensors(operand, reference)


def inplace_update_operand(dst, src):
    """Update an operand or explicit operand batch in place."""
    if isinstance(dst, Sequence):
        for dst_i, src_i in zip(dst, src, strict=True):
            dst_i[:] = src_i
    else:
        dst[:] = src


def _as_per_matrix_layout(operand, order):
    """
    Return an operand whose matrix view has C- or F-like layout.

    For implicit batching this applies to each matrix slice in the last two
    dimensions, not necessarily to the full batched tensor.
    """
    package, module = _parse_operand_package(operand)

    if order == "C":
        if package == "torch":
            return operand.contiguous()
        if package == "cupy":
            return module.ascontiguousarray(operand)
        return operand.copy(order="C")

    assert order == "F", "Internal Error."
    if package == "torch":
        return operand.mT.contiguous().mT
    if package == "cupy":
        if operand.ndim == 2:
            return module.asfortranarray(operand)
        return module.ascontiguousarray(operand.swapaxes(-1, -2)).swapaxes(-1, -2)
    if operand.ndim == 2:
        return operand.copy(order="F")
    return operand.swapaxes(-1, -2).copy(order="C").swapaxes(-1, -2)


def _empty_like_with_shape(operand, shape):
    package, module = _parse_operand_package(operand)
    if package == "torch":
        return module.empty(shape, dtype=operand.dtype, device=operand.device)
    return module.empty(shape, dtype=operand.dtype)


def _as_padded_layout(operand, order):
    shape = operand.shape
    if order == "C":
        padded = _empty_like_with_shape(operand, (*shape[:-1], shape[-1] + 2))
        result = padded[..., 1 : 1 + shape[-1]]
    else:
        assert order == "F", "Internal Error."
        padded = _empty_like_with_shape(operand, (*shape[:-2], shape[-2] + 2, shape[-1]))
        padded = _as_per_matrix_layout(padded, "F")
        result = padded[..., 1 : 1 + shape[-2], :]
    result[...] = operand
    return result


@sequence_aware()
def with_lhs_layout(operand, layout):
    """Return an LHS operand or explicit batch with the requested test layout."""
    if layout in {"C", "F"}:
        return _as_per_matrix_layout(operand, layout)
    if layout in {"padded-C", "padded-F"}:
        return _as_padded_layout(operand, layout.removeprefix("padded-"))
    raise ValueError(f"Unknown LHS layout: {layout}")


@sequence_aware()
def with_rhs_layout(operand, layout):
    """Return an RHS operand or explicit batch with the requested test layout."""
    if layout == "vector":
        assert operand.ndim == 1
        return _as_per_matrix_layout(operand, "C")
    if layout == "F":
        return _as_per_matrix_layout(operand, "F")
    if layout == "padded-F":
        return _as_padded_layout(operand, "F")
    raise ValueError(f"Unknown RHS layout: {layout}")


@sequence_aware()
def make_unsupported_lhs_layout(operand):
    """Return an LHS operand or explicit batch with unsupported matrix strides."""
    package, module = _parse_operand_package(operand)
    padded_shape = (*operand.shape[:-2], operand.shape[-2] * 2, operand.shape[-1] * 2)
    if package == "torch":
        padded = module.empty(padded_shape, dtype=operand.dtype, device=operand.device)
    else:
        padded = module.empty(padded_shape, dtype=operand.dtype)

    result = padded[..., ::2, ::2]
    result[...] = operand
    return result


@sequence_aware()
def make_unsupported_rhs_layout(operand):
    """Return an RHS operand or explicit batch with unsupported row strides."""
    package, module = _parse_operand_package(operand)
    if operand.ndim == 1:
        padded_shape = (operand.shape[-1] * 2,)
        if package == "torch":
            padded = module.empty(padded_shape, dtype=operand.dtype, device=operand.device)
        else:
            padded = module.empty(padded_shape, dtype=operand.dtype)
        result = padded[::2]
    else:
        padded_shape = (*operand.shape[:-2], operand.shape[-2] * 2, operand.shape[-1])
        if package == "torch":
            padded = module.empty(padded_shape, dtype=operand.dtype, device=operand.device)
        else:
            padded = module.empty(padded_shape, dtype=operand.dtype)
        result = padded[..., ::2, :]
    result[...] = operand
    return result


def make_explicit_batch_with_mismatched_strides(operand):
    """Return an explicit batch whose members alternate between stride layouts."""
    assert isinstance(operand, Sequence)
    assert len(operand) > 1
    return [_as_per_matrix_layout(op, "F") if i % 2 == 0 else _as_padded_layout(op, "C") for i, op in enumerate(operand)]


def make_batch_with_overlapping_storage(operand):
    """Return a batched operand whose batch entries share storage."""
    if isinstance(operand, Sequence):
        return [operand[0], operand[0]]
    package, module = _parse_operand_package(operand)
    base = operand[(0,) * (operand.ndim - 2)]
    if package == "torch":
        return base.expand(operand.shape)
    return module.broadcast_to(base, operand.shape)


def operands_alias(lhs, rhs):
    """Return whether two operands or explicit operand batches share Python objects."""
    if isinstance(lhs, Sequence):
        assert isinstance(rhs, Sequence)
        return all(lhs_i is rhs_i for lhs_i, rhs_i in zip(lhs, rhs, strict=True))
    return lhs is rhs


def create_inplace_operands(
    framework,
    batch_shape,
    lhs_batch_format,
    rhs_batch_format,
    use_cuda=True,
    lhs_layout="C",
    rhs_layout="F",
):
    """Create small direct-solver operands compatible with inplace options."""
    nrhs = None if rhs_layout == "vector" else 2
    a, b = create_solver_operands(
        framework,
        "float32",
        4,
        nrhs,
        use_cuda=use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )
    return with_lhs_layout(a, lhs_layout), with_rhs_layout(b, rhs_layout)
