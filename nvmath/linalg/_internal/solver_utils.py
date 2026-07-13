# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = (
    "BatchInfo",
    "compute_f_strides",
    "LHSLayout",
    "RHSLayout",
    "get_lhs_layout",
    "get_rhs_layout",
    "wrap_solver_operands",
    "wrap_check_solver_lhs",
    "wrap_check_solver_rhs",
    "parse_solver_operands",
    "copy_operands",
    "SolverBackend",
)

import enum
import math
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Literal, TypeAlias, TypeGuard, cast

import numpy as np

from nvmath.internal import tensor_wrapper, utils
from nvmath.internal.package_ifc import StreamHolder
from nvmath.internal.tensor_ifc import Tensor, TensorHolder

SUPPORTED_DTYPE_NAMES = {"float32", "float64", "complex64", "complex128"}
WrappedOperand: TypeAlias = TensorHolder | Sequence[TensorHolder]


class SolverBackend(enum.IntEnum):
    CUSOLVER = 0
    CUBLAS = 1


def compute_f_strides(shape: tuple[int, ...]) -> tuple[int, ...]:
    """Column-major (Fortran / LAPACK) strides: first axis is stride 1."""
    strides = [1] * len(shape)
    stride = 1
    for i in range(len(shape)):
        strides[i] = stride
        stride *= shape[i]
    return tuple(strides)


@dataclass(frozen=True, slots=True)
class LHSLayout:
    # cuSOLVER/cuBLAS interpret matrix operands as column-major. An F-order LHS
    # can be used as-is with op=N. A C-order LHS has the same memory layout as
    # the column-major representation of A.T, so solve uses op=T to recover A @ x = b.
    order: Literal["F", "C"]
    lda: int


@dataclass(frozen=True, slots=True)
class RHSLayout:
    ldb: int


@dataclass(frozen=True, slots=True, kw_only=True)
class BatchInfo:
    explicitly_batched: bool
    implicitly_batched: bool
    batch_shape: tuple[int, ...] | None
    batch_count: int

    def __post_init__(self):
        if self.explicitly_batched:
            if self.implicitly_batched:
                raise ValueError("The operand cannot be both explicitly and implicitly batched.")
            if self.batch_shape is not None:
                raise ValueError("The explicitly batched operand cannot have a batch shape.")
        elif self.implicitly_batched:
            if self.batch_shape is None:
                raise ValueError("The implicitly batched operand must have a batch shape.")
        else:
            if self.batch_shape is not None:
                raise ValueError("The non-batched operand cannot have a batch shape.")
            if self.batch_count != 1:
                raise ValueError("The non-batched operand must have a batch count of 1.")

    def __str__(self) -> str:
        if not self.explicitly_batched and not self.implicitly_batched:
            return "non-batched"
        if self.explicitly_batched:
            return f"explicit batching (batch_count={self.batch_count})"
        return f"implicit batching (batch_shape={self.batch_shape}, batch_count={self.batch_count})"


def _is_operand_sequence(operand: WrappedOperand) -> TypeGuard[Sequence[TensorHolder]]:
    return isinstance(operand, Sequence)


def get_lhs_layout(lhs: WrappedOperand, check_inplace_compatible_strides: bool = True) -> LHSLayout:
    if _is_operand_sequence(lhs):
        unique_strides = {tuple(operand.strides) for operand in lhs}
        if check_inplace_compatible_strides and len(unique_strides) != 1:
            raise ValueError(
                f"When inplace_a is True, the strides of the LHS must be the same for all batches, but got {unique_strides}."
            )
        strides = unique_strides.pop()
    else:
        lhs = cast(TensorHolder, lhs)
        strides = tuple(lhs.strides)

    # Store the leading dimension for the column-major view seen by GETRF/GETRS.
    if strides[-2] == 1:
        return LHSLayout("F", strides[-1])
    if strides[-1] == 1:
        return LHSLayout("C", strides[-2])

    if check_inplace_compatible_strides:
        raise ValueError(
            f"When inplace_a is True, the LHS must have either column-major or row-major layout, but got strides {strides}."
        )
    raise AssertionError(f"Internal error: unable to determine LHS layout from strides {strides}.")


def get_rhs_layout(rhs: WrappedOperand, nrhs: int, check_inplace_compatible_strides: bool = True) -> RHSLayout:
    if _is_operand_sequence(rhs):
        unique_strides = {tuple(operand.strides) for operand in rhs}
        if check_inplace_compatible_strides and len(unique_strides) != 1:
            raise ValueError(
                f"When inplace_b is True, the strides of the RHS must be the same for all batches, but got {unique_strides}."
            )
        strides = unique_strides.pop()
        shape = tuple(rhs[0].shape)
    else:
        rhs = cast(TensorHolder, rhs)
        strides = tuple(rhs.strides)
        shape = tuple(rhs.shape)

    if len(strides) == 1:
        if check_inplace_compatible_strides and strides[-1] != 1:
            raise ValueError(f"When inplace_b is True, vector RHS operands must have unit stride, but got strides {strides}.")
        return RHSLayout(shape[-1])

    if check_inplace_compatible_strides and strides[-2] != 1:
        raise ValueError(
            f"When inplace_b is True, matrix RHS operands must have column-major layout, but got strides {strides}."
        )

    return RHSLayout(strides[-1] if nrhs > 1 else shape[-2])


def check_inplace_lhs_storage(lhs: WrappedOperand, batch_info: BatchInfo) -> None:
    if batch_info.explicitly_batched:
        lhs = cast(Sequence[TensorHolder], lhs)
        # Full non-overlap validation is hard for arbitrary views, so
        # cheaply guard the most obvious dangerous explicit-batch case:
        # repeated views of the same matrix.
        data_ptrs = {o.data_ptr for o in lhs}
        if len(data_ptrs) != batch_info.batch_count:
            raise ValueError(
                f"When inplace_a is True, each batch in LHS must not share overlapping memory, "
                f"but only got {len(data_ptrs)} unique data pointers for {batch_info.batch_count} batches."
            )
        return

    lhs_holder = cast(TensorHolder, lhs)
    if batch_info.implicitly_batched and 0 in lhs_holder.strides[:-2]:
        # Full non-overlap validation is hard for arbitrary strided views,
        # so cheaply guard the most obvious dangerous implicit-batch case:
        # broadcasted batches (for example torch.expand) with zero batch
        # strides, where multiple batch items share one matrix.
        raise ValueError(
            f"When inplace_a is True, each batch in LHS must not share overlapping memory, "
            f"but found the implicitly batched LHS with strides {lhs_holder.strides}."
        )


def check_inplace_rhs_storage(rhs: WrappedOperand, batch_info: BatchInfo) -> None:
    if batch_info.explicitly_batched:
        rhs = cast(Sequence[TensorHolder], rhs)
        # Full non-overlap validation is hard for arbitrary views, so
        # cheaply guard the most obvious dangerous explicit-batch case:
        # repeated views of the same RHS operand.
        data_ptrs = {o.data_ptr for o in rhs}
        if len(data_ptrs) != batch_info.batch_count:
            raise ValueError(
                f"When inplace_b is True, each batch in RHS must not share overlapping memory, "
                f"but only got {len(data_ptrs)} unique data pointers for {batch_info.batch_count} batches."
            )
        return

    rhs_holder = cast(TensorHolder, rhs)
    if batch_info.implicitly_batched and 0 in rhs_holder.strides[:-2]:
        # Full non-overlap validation is hard for arbitrary strided views,
        # so cheaply guard the most obvious dangerous implicit-batch case:
        # broadcasted batches (for example torch.expand) with zero batch
        # strides, where multiple batch items share one RHS operand.
        raise ValueError(
            f"When inplace_b is True, each batch in RHS must not share overlapping memory, "
            f"but found the implicitly batched RHS with strides {rhs_holder.strides}."
        )


def get_single_or_sequence_attr(obj, attribute_name: str, check_consistency: bool = False):
    if isinstance(obj, Sequence):
        result = obj[0].__getattribute__(attribute_name)
        if check_consistency:
            for i, o in enumerate(obj, start=1):
                if get_single_or_sequence_attr(o, attribute_name) != result:
                    raise ValueError(
                        f"The {attribute_name} of the {i}th object ({o}) in the sequence "
                        f"({obj}) is different from the first object ({obj[0]})."
                    )
        return result
    else:
        return obj.__getattribute__(attribute_name)


def wrap_solver_operands(operands: Tensor | Sequence[Tensor], check_consistency: bool = True):
    explicitly_batched = isinstance(operands, Sequence)
    if isinstance(operands, Sequence):
        results = tensor_wrapper.wrap_operands(operands)  # type: ignore
        if check_consistency:
            # Check the consistency of the operands
            utils.get_operands_dtype(results)
            utils.get_operands_device_id(results)
            shapes = [o.shape for o in results]
            for i, shape in enumerate(shapes, start=1):
                if shape != shapes[0]:
                    raise ValueError(
                        f"The shape of the {i}th operand ({shape}) is not the same as the first operand ({shapes[0]})."
                    )
    else:
        results = tensor_wrapper.wrap_operand(operands)  # type: ignore
    return results, explicitly_batched


def wrap_check_solver_lhs(a: Tensor | Sequence[Tensor], check_inplace_a_layout: bool = False):
    lhs, explicitly_batched = wrap_solver_operands(a, check_consistency=True)
    implicitly_batched = False
    lhs_layout = None
    if explicitly_batched:
        # shape consistency is checked in wrap_solver_operands
        shape = lhs[0].shape
        batch_count = len(lhs)
        n0, n1 = shape
        if n0 != n1:
            raise ValueError(f"For explicitly batched LHS, the shape of each batch must be square, but got {shape}.")
        n = n0
        batch_shape = None
    else:
        shape = lhs.shape
        ndim = len(shape)
        if ndim == 2:
            batch_shape = None
            n0, n1 = shape
            batch_count = 1
        else:
            implicitly_batched = True
            *batch_shape, n0, n1 = shape
            batch_shape = tuple(batch_shape)
            batch_count = math.prod(batch_shape)
        if n0 != n1:
            raise ValueError(f"The last two dimensions of the LHS must be the same, but got {n0} and {n1}.")
        n = n0

    batch_info = BatchInfo(
        explicitly_batched=explicitly_batched,
        implicitly_batched=implicitly_batched,
        batch_shape=batch_shape,
        batch_count=batch_count,
    )
    if check_inplace_a_layout:
        check_inplace_lhs_storage(lhs, batch_info)
        # CPU inputs are copied to internal GPU buffers, so their layout does not
        # need to satisfy in-place solver requirements.
        if get_single_or_sequence_attr(lhs, "device") == "cuda":
            lhs_layout = get_lhs_layout(lhs)

    return lhs, batch_info, n, lhs_layout


def wrap_check_solver_rhs(b: Tensor | Sequence[Tensor], check_inplace_b_layout: bool = False):
    rhs, explicitly_batched = wrap_solver_operands(b, check_consistency=True)
    implicitly_batched = False
    rhs_layout = None
    if explicitly_batched:
        # shape consistency is checked in wrap_solver_operands
        shape = rhs[0].shape
        batch_count = len(rhs)
        ndim = len(shape)
        if ndim == 1:
            n, nrhs = shape[0], 1
        elif ndim == 2:
            n, nrhs = shape
        else:
            raise ValueError(f"For explicitly batched RHS, the shape of each batch must be 1D or 2D, but got {ndim}D.")
        batch_shape = None
    else:
        shape = rhs.shape
        ndim = len(shape)
        if ndim >= 3:
            implicitly_batched = True
            *batch_shape, n, nrhs = shape
            batch_shape = tuple(batch_shape)
            batch_count = math.prod(batch_shape)
        else:
            batch_shape = None
            batch_count = 1
            if ndim == 1:
                n, nrhs = shape[0], 1
            else:
                n, nrhs = shape

    batch_info = BatchInfo(
        explicitly_batched=explicitly_batched,
        implicitly_batched=implicitly_batched,
        batch_shape=batch_shape,
        batch_count=batch_count,
    )
    if check_inplace_b_layout:
        check_inplace_rhs_storage(rhs, batch_info)
        # CPU inputs are copied to internal GPU buffers, so their layout does not
        # need to satisfy in-place solver requirements.
        if get_single_or_sequence_attr(rhs, "device") == "cuda":
            rhs_layout = get_rhs_layout(rhs, nrhs)

    return rhs, batch_info, n, nrhs, rhs_layout


def parse_solver_operands(
    a: Tensor | Sequence[Tensor],
    b: Tensor | Sequence[Tensor],
    check_inplace_a_layout: bool = False,
    check_inplace_b_layout: bool = False,
):
    lhs, lhs_batch_info, n_lhs, lhs_layout = wrap_check_solver_lhs(a, check_inplace_a_layout=check_inplace_a_layout)
    rhs, rhs_batch_info, n_rhs, nrhs, rhs_layout = wrap_check_solver_rhs(b, check_inplace_b_layout=check_inplace_b_layout)
    if lhs_batch_info.batch_count != rhs_batch_info.batch_count:
        raise ValueError(
            f"The number of batches in the LHS and RHS must be the same, but "
            f"got {lhs_batch_info.batch_count} for the LHS and {rhs_batch_info.batch_count} for the RHS."
        )
    if (
        lhs_batch_info.batch_shape is not None
        and rhs_batch_info.batch_shape is not None
        and lhs_batch_info.batch_shape != rhs_batch_info.batch_shape
    ):
        raise ValueError(
            f"For implicitly batched LHS & RHS, the batch shapes must be the same, but "
            f"got {lhs_batch_info.batch_shape} for the LHS and {rhs_batch_info.batch_shape} for the RHS."
        )
    if n_lhs != n_rhs:
        raise ValueError(f"The number of columns in the LHS ({n_lhs}) and RHS ({n_rhs}) must be the same.")

    # Consistency within LHS or RHS has been checked in wrap_check_solver_lhs/rhs
    # Here we only need to check the consistency between LHS and RHS.
    package_lhs = get_single_or_sequence_attr(lhs, "name")
    device_id_lhs = get_single_or_sequence_attr(lhs, "device_id")
    dtype_name_lhs = get_single_or_sequence_attr(lhs, "dtype")

    # We have managed to wrap the operands so we can skip checking the package consistency
    package_rhs = get_single_or_sequence_attr(rhs, "name")
    device_id_rhs = get_single_or_sequence_attr(rhs, "device_id")
    dtype_name_rhs = get_single_or_sequence_attr(rhs, "dtype")

    if package_lhs != package_rhs:
        raise ValueError(f"The package for the LHS ({package_lhs}) and RHS ({package_rhs}) must be the same.")
    if device_id_lhs != device_id_rhs:
        raise ValueError(f"The device id for the LHS ({device_id_lhs}) and RHS ({device_id_rhs}) must be the same.")
    if dtype_name_lhs != dtype_name_rhs:
        raise ValueError(f"The dtype for the LHS ({dtype_name_lhs}) and RHS ({dtype_name_rhs}) must be the same.")

    return (
        lhs,
        lhs_batch_info,
        rhs,
        rhs_batch_info,
        n_lhs,
        nrhs,
        package_lhs,
        device_id_lhs,
        dtype_name_lhs,
        lhs_layout,
        rhs_layout,
    )


def copy_operands(
    dst: WrappedOperand,
    src: WrappedOperand,
    stream_holder: StreamHolder,
):
    if _is_operand_sequence(dst):
        if not _is_operand_sequence(src):
            raise AssertionError("The source must be a sequence if the destination is a sequence.")
        for d, s in zip(dst, src, strict=True):
            d.copy_(s, stream_holder=stream_holder)
    else:
        if _is_operand_sequence(src):
            raise AssertionError("The source must be a single operand if the destination is a single operand.")
        dst = cast(TensorHolder, dst)
        src = cast(TensorHolder, src)
        dst.copy_(src, stream_holder=stream_holder)


def get_operands_ptr_array(
    wrapped_operands: WrappedOperand,
    batch_indices: tuple[tuple[int, ...], ...] | None = None,
) -> TensorHolder:
    if _is_operand_sequence(wrapped_operands):
        device_ptrs = [o.data_ptr for o in wrapped_operands]
    else:
        wrapped_operands = cast(TensorHolder, wrapped_operands)
        assert batch_indices is not None, "Internal Error."
        starting_ptr = wrapped_operands.data_ptr
        offsets = wrapped_operands.strides[: len(batch_indices[0])]  # type: ignore
        device_ptrs = []
        for index in batch_indices:
            device_ptrs.append(
                starting_ptr + wrapped_operands.itemsize * sum(o * i for o, i in zip(offsets, index, strict=True))
            )
    return tensor_wrapper.wrap_operand(np.array(device_ptrs, dtype=np.uint64))


def update_operands_ptr_array(
    ptr_operand: TensorHolder,
    wrapped_operands: WrappedOperand,
    stream_holder: StreamHolder,
    batch_indices: tuple[tuple[int, ...], ...] | None = None,
):
    device_ptrs = get_operands_ptr_array(wrapped_operands, batch_indices)
    ptr_operand.copy_(device_ptrs, stream_holder=stream_holder)
