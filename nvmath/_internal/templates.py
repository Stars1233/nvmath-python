# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import dataclasses
import logging
from logging import Logger
from typing import ClassVar, Literal

from nvmath import memory
from nvmath.internal import utils


@dataclasses.dataclass(frozen=True, slots=True, kw_only=True)
class ExecutionCUDA:
    """
    A data class for providing GPU execution options.

    Attributes:
        device_id: CUDA device ordinal (only used if the operand resides on the CPU). The
            default value is 0.

    .. seealso::
       :class:`ExecutionCPU`
    """

    name: ClassVar[Literal["cuda"]] = "cuda"
    device_id: int = 0


@dataclasses.dataclass(frozen=True, slots=True, kw_only=True)
class ExecutionCPU:
    """
    A data class for providing CPU execution options.

    Attributes:
        num_threads: The number of CPU threads used to execute the operation.
                     If not specified, defaults to the number of CPU cores available to the
                     process.

    .. seealso::
       :class:`ExecutionCUDA`
    """

    name: ClassVar[Literal["cpu"]] = "cpu"
    num_threads: int | None = None


def copy_operand_perhaps(
    internal_operand: utils.TensorHolder | None,
    operand: utils.TensorHolder,
    stream_holder: utils.StreamHolder | None,
    execution_device_id: int | Literal["cpu"],
    operands_device_id: int | Literal["cpu"],
) -> tuple[utils.TensorHolder, utils.TensorHolder | None]:
    """Private implementation of memory space management for tensor operands.

    The `copy_operand_perhaps` function facilitates transitions of tensor operands between
    different memory spaces, ensuring compatibility with execution requirements. Its role is
    to determine whether a tensor operand needs to be copied to accommodate differing
    execution and operand memory spaces, while preserving the original operand for cases
    requiring in-place operations.

    Args:
        internal_operand: Represents an internal tensor for in-place
            memory operations, or `None` if not applicable.

        operand: Tensor to possibly copied to the execution memory space.

        stream_holder: Manages the CUDA stream for device operations.

        execution_device_id: Specifies the target execution space.

        operands_device_id: Specifies the current operand memory space.

    Returns:
        A tuple containing:
            - The operand copied to the execution space, or the original operand if
              no copy is necessary.
            - The original operand, or `None` if no copy occurred.

    """
    if execution_device_id == operands_device_id:
        return operand, None
    else:
        # Copy the `operand` to memory that matches the exec space
        # and keep the original `operand` to handle `options.inplace=True`
        if internal_operand is None:
            exec_space_copy = operand.to(execution_device_id, stream_holder)
            return exec_space_copy, operand
        else:
            # In-place copy to existing pointer
            internal_operand.copy_(src=operand, stream_holder=stream_holder)
            return internal_operand, operand


@dataclasses.dataclass(frozen=True, slots=True, kw_only=True)
class StatefulAPIOptions:
    """A dataclass for providing options to a stateful API object.

    Attributes:
        allocator: An object that supports the :class:`BaseCUDAMemoryManager` protocol, used
            to draw device memory. If an allocator is not provided, a memory allocator from
            the library package will be used (:func:`torch.cuda.caching_allocator_alloc` for
            PyTorch operands, :func:`cupy.cuda.alloc` otherwise).

        blocking: A flag specifying the behavior of the stream-ordered functions and
            methods. When ``blocking`` is `True`, the stream-ordered methods do not return
            until the operation is complete. When ``blocking`` is ``"auto"``, the methods
            return immediately when the inputs are on the GPU. The stream-ordered methods
            always block when the operands are on the CPU to ensure that the user doesn't
            inadvertently use the result before it becomes available. The default is
            ``"auto"``.

        logger: Python Logger object. The root logger will be used if a
            logger object is not provided.
    """

    allocator: memory.BaseCUDAMemoryManager | memory.BaseCUDAMemoryManagerAsync | None = None
    blocking: Literal[True, "auto"] = "auto"
    logger: Logger = dataclasses.field(default_factory=logging.getLogger)

    def __post_init__(self):
        if self.blocking not in (True, "auto"):
            raise ValueError("The value specified for blocking must be either True or 'auto'.")

        if self.allocator is not None and not isinstance(
            self.allocator, memory.BaseCUDAMemoryManager | memory.BaseCUDAMemoryManagerAsync
        ):
            raise TypeError("The allocator must be an object of type that fulfills the BaseCUDAMemoryManager protocol.")
