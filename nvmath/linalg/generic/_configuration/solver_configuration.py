# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = ["DirectSolverOptions"]

import dataclasses

from nvmath._internal.templates import StatefulAPIOptions


@dataclasses.dataclass(frozen=True, slots=True, kw_only=True)
class DirectSolverOptions(StatefulAPIOptions):
    """A data class for providing options to :func:`~nvmath.linalg.direct_solver` and
    :class:`DirectSolver`.

    Attributes:
        handle: If ``None`` (the default), the required library handle will be created
            automatically for the computation. If users wish to manage the library
            handle themselves, they may provide a **cuSOLVER** handle, which will be
            used unless the execution is dispatched to cuBLAS, e.g, for linear
            equation solver on batched operands.
            In this case, a cuBLAS handle will be created.

        blocking: A flag specifying the behavior of the stream-ordered functions and
            methods. When ``blocking`` is `True`, the stream-ordered methods do not return
            until the operation is complete. When ``blocking`` is ``"auto"``, the methods
            may execute asynchronously when the inputs are on the GPU, depending on the
            problem specification and runtime conditions. The stream-ordered methods always
            block when the operands are on the CPU to ensure that the user doesn't
            inadvertently use the result before it becomes available. The default is
            ``"auto"``.

        allocator: An object that supports the :class:`BaseCUDAMemoryManager` protocol, used
            to draw device memory. If an allocator is not provided, a memory allocator from
            the library package will be used (:func:`torch.cuda.caching_allocator_alloc` for
            PyTorch operands, :func:`cupy.cuda.alloc` otherwise).

        logger: Python Logger object. The root logger will be used if a
            logger object is not provided.

        inplace_a: Whether LU factorization overwrites the input left-hand side
            matrix ``a`` with the factors L, D, and U. The default is ``False``.

            .. experimental:: attribute

        inplace_b: Whether the solve overwrites the input right-hand side ``b``
            with the solution ``x``. The default is ``False``.

            .. experimental:: attribute

    .. seealso::
        :func:`~nvmath.linalg.direct_solver`, :class:`~nvmath.linalg.DirectSolver`.

    """

    handle: int | None = None
    inplace_a: bool = False
    inplace_b: bool = False
