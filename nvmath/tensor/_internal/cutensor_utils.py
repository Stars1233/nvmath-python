# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import math
import weakref
from collections.abc import Sequence

from nvmath.bindings import cutensor
from nvmath.internal.tensor_ifc import TensorHolder
from nvmath.internal.typemaps import NAME_TO_DATA_TYPE

__all__ = [
    "compute_pointer_alignment",
    "compute_strides",
    "TensorDescriptor",
]

DEFAULT_ALIGNMENT_REQUIREMENT = 256


def compute_pointer_alignment(ptr: int) -> int:
    """
    Compute the pointer alignment for the given pointer.

    Args:
        ptr: Pointer address as integer

    Returns:
        The alignment value (256, 128, 64, 32, 16, 8, 4, 2, or 1)
    """
    return 256 if ptr == 0 else min(ptr & -ptr, 256)


def compute_strides(shape: Sequence[int], order: str = "C") -> Sequence[int]:
    """
    Compute the strides for the given shape and order.

    Args:
        shape: Shape of the tensor

    Returns:
        The strides
    """
    assert order in {"C", "F"}, f"Invalid order: {order}"
    strides = [0] * len(shape)
    stride = 1
    if order == "C":
        for axis in range(len(shape) - 1, -1, -1):
            strides[axis] = stride
            stride *= shape[axis]
    elif order == "F":
        for axis in range(len(shape)):
            strides[axis] = stride
            stride *= shape[axis]
    else:
        raise ValueError(f"Invalid order: {order}")
    return strides


def get_optimized_strides(
    input_modes: Sequence[Sequence[str]],
    output_modes: Sequence[str],
    output_shape: Sequence[int],
) -> Sequence[int]:
    """
    Get the optimized strides for a **binary** contraction output.

    Output modes are split into three groups:
        - hypermodes in both operands,
        - un-contracted modes from operand A,
        - un-contracted modes from operand B.

    In the optimized/canonical output layout, the hyper modes are
    placed at the beginning, followed by the group of modes with larger
    combined size, then the other group of modes.

    For example, "Pijab,Pabcd->Picjd" labels hypermode "P", A-only modes "i,j",
    and B-only modes "c,d". The canonical mode order is either "Pijcd" or "Pcdij",
    depending on which group has the larger combined size.

    Args:
        input_modes: Two sequences of mode labels (typically characters), one per operand.
        output_modes: Output subscript aligned with ``output_shape``.
        output_shape: Extent along each output mode.

    Returns:
        Strides in elements matching the memory order implied by ``output_modes``.
    """
    if len(input_modes) != 2:
        raise ValueError("Only binary contraction is supported for optimized strides")
    a_modes, b_modes = input_modes

    size_dict = dict(zip(output_modes, output_shape, strict=True))

    output_set = set(output_modes)
    b_set = set(b_modes)

    hyper_modes = [m for m in a_modes if m in output_set and m in b_set]
    a_remaining_modes = [m for m in a_modes if m in output_set and m not in b_set]
    b_remaining_modes = [m for m in b_modes if m in output_set and m not in hyper_modes]

    combined_size_a = math.prod(size_dict[mode] for mode in a_remaining_modes)
    combined_size_b = math.prod(size_dict[mode] for mode in b_remaining_modes)

    if combined_size_a >= combined_size_b:
        canonical_output_modes = hyper_modes + a_remaining_modes + b_remaining_modes
    else:
        canonical_output_modes = hyper_modes + b_remaining_modes + a_remaining_modes

    canonical_output_shape = [size_dict[mode] for mode in canonical_output_modes]
    canonical_strides = compute_strides(canonical_output_shape, order="C")

    stride_map = dict(zip(canonical_output_modes, canonical_strides, strict=True))

    # Permute strides back to the caller's output mode order.
    optimized_strides = [stride_map[mode] for mode in output_modes]
    return optimized_strides


class TensorDescriptor:
    """
    A managed wrapper for cuTensor tensor descriptors with automatic resource cleanup.

    This class wraps a cuTensor tensor descriptor (``cutensorTensorDescriptor_t``) and
    automatically manages its lifetime. The underlying C descriptor is created on
    initialization and automatically destroyed when this object is garbage collected.

    Args:
        handle: The cuTensor library handle.
        extents: The extents (shape) of each mode of the tensor. Must have the same
            length as ``strides``.
        strides: The stride for each mode of the tensor, in elements of the base type.
            Must have the same length as ``extents``.
        dtype: The data type of the tensor as a string.
        alignment: The alignment requirement in bytes for the base pointer that will
            be used with this descriptor.

    """

    def __init__(
        self,
        handle: int,
        extents: Sequence[int],
        strides: Sequence[int],
        dtype: str,
        alignment: int,
    ):
        self._extents = extents
        self._strides = strides
        self._dtype = dtype
        self._alignment = alignment
        num_modes = len(extents)
        assert num_modes == len(strides), "The number of modes and strides must be the same"
        self._tensor_desc = cutensor.create_tensor_descriptor(
            handle, num_modes, extents, strides, NAME_TO_DATA_TYPE[dtype], alignment
        )
        self._finalizer = weakref.finalize(self, cutensor.destroy_tensor_descriptor, self._tensor_desc)

    @property
    def ptr(self) -> int:
        return self._tensor_desc

    @property
    def shape(self) -> Sequence[int]:
        return self._extents

    @property
    def dtype(self) -> str:
        return self._dtype

    @property
    def alignment(self) -> int:
        return self._alignment

    @property
    def strides(self) -> Sequence[int]:
        return self._strides

    @classmethod
    def from_tensor_holder(cls, handle: int, tensor: TensorHolder) -> "TensorDescriptor":
        """
        Create a TensorDescriptor from a TensorHolder.

        Args:
            handle: The cuTensor library handle.
            tensor: The TensorHolder to create the descriptor from.

        Returns:
            A TensorDescriptor with properties derived from the TensorHolder.
        """
        return cls(
            handle=handle,
            extents=tensor.shape,
            strides=tensor.strides,
            dtype=tensor.dtype,
            alignment=compute_pointer_alignment(tensor.data_ptr),
        )

    @classmethod
    def from_metadata(
        cls,
        handle: int,
        shape: Sequence[int],
        dtype: str,
        strides: Sequence[int] | None = None,
        alignment: int = DEFAULT_ALIGNMENT_REQUIREMENT,
    ) -> "TensorDescriptor":
        """
        Create a TensorDescriptor for the given shape, data type, strides, and alignment.

        Args:
            handle: The cuTensor library handle.
            shape: The shape (extents) of the tensor.
            dtype: The data type of the tensor as a string.
            strides: The strides of the tensor. Defaults to C order strides.
            alignment: The alignment requirement in bytes. Defaults to 256.

        Returns:
            A TensorDescriptor with the specified properties.
        """
        if strides is None:
            strides = compute_strides(shape, order="C")
        return cls(
            handle=handle,
            extents=shape,
            strides=strides,
            dtype=dtype,
            alignment=alignment,
        )
