# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = [
    "ContractionAlgo",
    "ContractionAutotuneMode",
    "ContractionJitMode",
    "ContractionCacheMode",
    "ContractionOptions",
    "ExecutionCUDA",
]


from dataclasses import dataclass
from logging import Logger
from typing import Literal

from nvmath._internal import templates
from nvmath.bindings import cutensor
from nvmath.memory import BaseCUDAMemoryManager

ContractionAlgo = cutensor.Algo
ContractionAutotuneMode = cutensor.AutotuneMode
ContractionJitMode = cutensor.JitMode
ContractionCacheMode = cutensor.CacheMode


@dataclass
class ContractionOptions:
    """
    A data class for providing options to the :class:`BinaryContraction` and
    :class:`TernaryContraction` objects, or the wrapper functions
    :func:`binary_contraction`and :func:`ternary_contraction`.

    Attributes:
        compute_type: The compute type to use for the contraction.
            See :class:`~nvmath.tensor.ComputeDesc` for available compute types.
        logger (logging.Logger): Python Logger object. The root logger will be used if a
            logger object is not provided.

        blocking: A flag specifying the behavior of the execution functions and methods,
            such as :func:`binary_contraction` and :meth:`TernaryContraction.execute`.
            When ``blocking`` is `True`, the execution methods do not return until the
            operation is complete. When
            ``blocking`` is ``"auto"``, the methods return immediately when the input tensor
            is on the GPU. The execution methods always block when the input tensor is
            on the CPU to ensure that the user doesn't inadvertently use the result
            before it becomes available. The default is ``"auto"``.

        handle: cuTensor library handle. A handle will be created if one is not provided.

        allocator: An object that supports the :class:`BaseCUDAMemoryManager` protocol, used
            to draw device memory. If an allocator is not provided, a memory allocator from
            the library package will be used (:func:`torch.cuda.caching_allocator_alloc` for
            PyTorch operands, :func:`cupy.cuda.alloc` otherwise).

        memory_limit: Maximum memory available to the contraction operation.
            It can be specified as a value (with optional suffix like K[iB], M[iB],
            G[iB]) or as a percentage. The default is 80% of the device memory.

        result_layout: The layout policy to use for the result: ``"auto"`` (default),
            ``"C"`` (row-major), ``"F"`` (column-major), or ``"optimized"``.
            With ``"auto"``, cuTENSOR execution requirements take precedence. When
            those requirements permit, an optimized layout is chosen for this
            contraction; otherwise, a compatible fallback layout is used. With
            ``"optimized"``, strides are chosen directly from the contraction
            expression and operand shapes to improve performance for this operation.
            The chosen layout is local to this contraction and may not be optimal for
            later operations that consume the result. This option is ignored if the
            output operand is explicitly provided.

    .. note::

        - optimized ``result_layout`` currently only supports binary contraction via
          :func:`binary_contraction` and :class:`BinaryContraction` when the addend
          ``c`` is not specified.
        - For both binary and ternary contractions, cuTENSOR may require the addend
          and output operands to have the same strides. When an addend operand is
          provided, explicitly specifying ``result_layout`` to ``"C"`` or ``"F"`` may
          therefore fail at runtime if that layout is incompatible with the addend.
          This constraint depends on the cuTENSOR library version.

    .. seealso::
        For supported compute types by data type, refer to the cuTENSOR documentation:

        * `Binary contraction <https://docs.nvidia.com/cuda/cutensor/latest/api/cutensor.html#cutensorcreatecontraction>`_
        * `Ternary contraction <https://docs.nvidia.com/cuda/cutensor/latest/api/cutensor.html#cutensorcreatecontractiontrinary>`_

    """

    compute_type: int | None = None
    logger: Logger | None = None
    blocking: Literal[True, "auto"] = "auto"
    handle: int | None = None
    allocator: BaseCUDAMemoryManager | None = None
    memory_limit: int | str | None = r"80%"
    result_layout: Literal["auto", "C", "F", "optimized"] = "auto"

    def __post_init__(self):
        if self.blocking not in (True, "auto"):
            raise ValueError("The value specified for 'blocking' must be either True or 'auto'.")
        if self.result_layout not in ("auto", "C", "F", "optimized"):
            raise ValueError("The value specified for 'result_layout' must be either 'auto', 'C', 'F', or 'optimized'.")


@dataclass(frozen=True, slots=True, kw_only=True)
class ExecutionCUDA(templates.ExecutionCUDA):
    """
    A data class for providing GPU execution options to the :class:`BinaryContraction` and
    :class:`TernaryContraction` objects, or the wrapper functions
    :func:`binary_contraction`and :func:`ternary_contraction`.

    Attributes:
        device_id: CUDA device ordinal (only used if the operand resides on the CPU). The
            default value is 0.

    """

    pass
