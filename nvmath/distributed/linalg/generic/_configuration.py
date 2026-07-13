# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = ["DirectSolverOptions"]

import dataclasses
import logging
from logging import Logger
from typing import Literal


@dataclasses.dataclass(frozen=True, slots=True, kw_only=True)
class DirectSolverOptions:
    """A data class for providing options to
    :func:`~nvmath.distributed.linalg.direct_solver` and
    :class:`~nvmath.distributed.linalg.DirectSolver`.

    Attributes:
        logger: Python Logger object. The root logger will be used if a
            logger object is not provided.

        blocking: A flag specifying the behavior of the stream-ordered functions and
            methods. When ``blocking`` is ``True``, the stream-ordered methods do not
            return until the operation is complete. When ``blocking`` is ``"auto"``, the
            methods may execute asynchronously when the inputs are on the GPU, depending
            on the problem specification and runtime conditions. The stream-ordered methods
            always block when the operands are on the CPU to ensure that the user doesn't
            inadvertently use the result before it becomes available. The default is
            ``"auto"``.

        inplace_a: Whether the LU factorization overwrites the input left-hand side
            matrix ``a`` with the LU factors. The default is ``True``.

            .. experimental:: attribute

        inplace_b: Whether the solve overwrites the input right-hand side ``b``
            with the solution ``x``. The default is ``True``.

            .. experimental:: attribute

        handle: If ``None`` (the default), the required cuSOLVERMp library handle will be
            created automatically for the computation. If users wish to manage the library
            handle themselves, they may provide a cuSOLVERMp handle. The presence of a
            handle must be consistent across processes: either every process provides its
            own handle, or none do.

    .. seealso::
        :func:`~nvmath.distributed.linalg.direct_solver`,
        :class:`~nvmath.distributed.linalg.DirectSolver`.
    """

    logger: Logger = dataclasses.field(default_factory=logging.getLogger)
    blocking: Literal[True, "auto"] = "auto"
    inplace_a: bool = True
    inplace_b: bool = True
    handle: int | None = None

    def __post_init__(self):
        if self.blocking not in (True, "auto"):
            raise ValueError("The value specified for blocking must be either True or 'auto'.")
