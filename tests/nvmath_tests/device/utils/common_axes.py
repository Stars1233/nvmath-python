# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import importlib.util
from enum import StrEnum

import numpy as np
import pytest


class Compiler(StrEnum):
    numba_cuda = "numba-cuda"
    numba_cuda_mlir = "numba-cuda-mlir"

    @property
    def is_available(self) -> bool:
        if self == Compiler.numba_cuda:
            return importlib.util.find_spec("numba.cuda") is not None
        if self == Compiler.numba_cuda_mlir:
            return importlib.util.find_spec("numba_cuda_mlir") is not None
        return False

    @classmethod
    def available(cls) -> list["Compiler"]:
        return [c for c in cls if c.is_available]

    @property
    def runtime(self):
        if self == Compiler.numba_cuda:
            from numba import cuda

            return cuda
        if self == Compiler.numba_cuda_mlir:
            from numba_cuda_mlir import cuda

            return cuda
        raise ValueError(f"Unknown compiler: {self}")

    @property
    def typing_error(self) -> type[Exception]:
        if self == Compiler.numba_cuda:
            from numba.core.errors import TypingError

            return TypingError
        if self == Compiler.numba_cuda_mlir:
            from numba_cuda_mlir.errors import TypingError

            return TypingError
        raise ValueError(f"Unknown compiler: {self}")


def skip_if_compiler_unavailable(compiler: Compiler) -> None:
    if not compiler.is_available:
        pytest.skip(f"{compiler.name} compiler not available")


def compiler_param(compiler: Compiler, xfail_reason: str | None = None):
    marks: tuple = ()
    if not compiler.is_available:
        marks = (pytest.mark.skip(reason=f"{compiler.name} compiler not available"),)
    elif xfail_reason is not None:
        marks = (pytest.mark.xfail(reason=xfail_reason, strict=False),)
    return pytest.param(compiler, id=compiler.name, marks=marks)


def all_compiler_params(xfail_reasons: dict[Compiler, str] | None = None) -> list:
    xfail_reasons = xfail_reasons or {}
    return [compiler_param(c, xfail_reason=xfail_reasons.get(c)) for c in Compiler]


# numba-cuda-mlir has a known LTO linking bug at the default optimization level
# that erases float16/bfloat16 stores and produces wrong results, so any fp16
# test is flaky with that compiler.
# BUG: https://github.com/NVIDIA/numba-cuda-mlir/pull/122
_MLIR_FP16_XFAIL_REASON = (
    "fp16 is flaky with the numba-cuda-mlir compiler (LTO store bug); see https://github.com/NVIDIA/numba-cuda-mlir/pull/122"
)


def _dtype_uses_fp16(item) -> bool:
    try:
        dt = np.dtype(item)
    except TypeError:
        return False
    if dt.fields:
        return any(_dtype_uses_fp16(field[0]) for field in dt.fields.values())
    return dt == np.dtype(np.float16)


def uses_fp16(*dtypes) -> bool:
    """Return True if any of the given precisions/dtypes uses float16.

    Handles plain numpy dtypes, tuples/lists of dtypes (e.g. mixed precision
    ``(float16, float16, float32)``), and nvmath device vector/complex types
    such as ``complex32``, ``half2`` and ``half4`` (whose host counterparts are
    structured float16 dtypes).
    """
    for dtype in dtypes:
        items = dtype if isinstance(dtype, (tuple, list)) else (dtype,)
        if any(_dtype_uses_fp16(item) for item in items):
            return True
    return False


def xfail_mlir_fp16(request, compiler: Compiler, *dtypes) -> None:
    """Mark the running test xfail when fp16 is used with numba-cuda-mlir.

    See :data:`_MLIR_FP16_XFAIL_REASON` for the underlying issue. The marker is
    non-strict so an unexpected pass (once the bug is fixed) does not fail the
    suite.
    """
    if compiler == Compiler.numba_cuda_mlir and uses_fp16(*dtypes):
        request.node.add_marker(pytest.mark.xfail(reason=_MLIR_FP16_XFAIL_REASON, strict=False))
