# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This set of tests checks reset_operands
"""

import re

import pytest

import nvmath

from ....helpers import assert_reset_to_none_behavior
from .params import ALL_FRAMEWORKS, BATCH_FORMAT_COMBINATIONS
from .solver_utils import create_solver_operand_pair, create_solver_operands, verify_solution


def _solver_after_solve(a, b):
    """
    Build a ``DirectSolver``, run plan → factorize → solve once, and return the instance.

    Callers should use ``with _solver_after_solve(...) as solver:`` so ``DirectSolver``
    cleanup runs on exit. The first solve is checked with ``verify_solution``.
    """
    solver = nvmath.linalg.DirectSolver(a, b)
    solver.plan()
    solver.factorize()
    x = solver.solve()
    verify_solution(a, b, x)
    return solver


# Happy path: reset and second solve with compatible operands


@ALL_FRAMEWORKS
@pytest.mark.parametrize("dtype", ("float32",))
@pytest.mark.parametrize("nrhs", (None, 1, 3))
@BATCH_FORMAT_COMBINATIONS
@pytest.mark.parametrize(
    "reset_a, reset_b",
    [
        (True, True),
        (True, False),
        (False, True),
    ],
    ids=["all", "a", "b"],
)
@pytest.mark.parametrize("unchecked_reset", (True, False))
@pytest.mark.parametrize("release_operands", (True, False))
def test_reset(
    framework,
    use_cuda,
    dtype,
    nrhs,
    batch_shape,
    lhs_batch_format,
    rhs_batch_format,
    reset_a,
    reset_b,
    unchecked_reset,
    release_operands,
):
    """
    Tests resetting particular operands
    """
    all_operands_reset = reset_a and reset_b

    n = 4

    (a0, b0), (a1, b1) = create_solver_operand_pair(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )

    reset_kwargs = {}
    if reset_a:
        reset_kwargs["a"] = a1
    if reset_b:
        reset_kwargs["b"] = b1

    with _solver_after_solve(a0, b0) as solver:
        if release_operands:
            solver.release_operands()

        reset_method = solver.reset_operands_unchecked if unchecked_reset else solver.reset_operands

        if release_operands and not all_operands_reset:
            reset_name = "reset_operands_unchecked" if unchecked_reset else "reset_operands"
            message = f"After release_operands(), both 'a' and 'b' must be provided to {reset_name}()."
            with pytest.raises(ValueError, match=re.escape(message)):
                reset_method(**reset_kwargs)
        else:
            reset_method(**reset_kwargs)

            if reset_a:
                # New factorization only when the system matrix changed.
                solver.factorize()

            x1 = solver.solve()

            verify_solution(a1 if reset_a else a0, b1 if reset_b else b0, x1)


# Negative tests: incompatible operands for reset_operands()


@pytest.mark.parametrize("mismatch_operand", ("lhs", "rhs"))
def test_reset_operands_rejects_package_mismatch(mismatch_operand):
    """``numpy`` solver: replacement ``a``/``b`` from ``torch`` is rejected."""
    a, b = create_solver_operands("numpy", "float32", 4, 2, use_cuda=False)
    a_bad, b_bad = create_solver_operands("torch", "float32", 4, 2, use_cuda=False)
    with _solver_after_solve(a, b) as solver, pytest.raises(ValueError, match="package for"):
        if mismatch_operand == "lhs":
            solver.reset_operands(a=a_bad)
        else:
            solver.reset_operands(b=b_bad)


@pytest.mark.parametrize("mismatch_operand", ("lhs", "rhs"))
def test_reset_operands_rejects_dtype_mismatch(mismatch_operand):
    """Replacement operand dtype must match the solver's (e.g. float32 throughout)."""
    a, b = create_solver_operands("numpy", "float32", 4, 2, use_cuda=False)
    a_bad, b_bad = create_solver_operands("numpy", "float64", 4, 2, use_cuda=False)
    with _solver_after_solve(a, b) as solver, pytest.raises(ValueError, match="dtype for"):
        if mismatch_operand == "lhs":
            solver.reset_operands(a=a_bad)
        else:
            solver.reset_operands(b=b_bad)


@pytest.mark.parametrize("mismatch_operand", ("lhs", "rhs"))
def test_reset_operands_rejects_device_mismatch(mismatch_operand):
    """Device id of replacement operands must match the original (Torch CPU vs CUDA)."""
    a, b = create_solver_operands("torch", "float32", 4, 2, use_cuda=True)
    a_bad, b_bad = create_solver_operands("torch", "float32", 4, 2, use_cuda=False)
    with _solver_after_solve(a, b) as solver, pytest.raises(ValueError, match="device id for"):
        if mismatch_operand == "lhs":
            solver.reset_operands(a=a_bad)
        else:
            solver.reset_operands(b=b_bad)


@pytest.mark.parametrize("mismatch_operand", ("lhs", "rhs"))
def test_reset_operands_rejects_batching_metadata_mismatch(mismatch_operand):
    """Explicit vs implicit batching must stay consistent across reset_operands."""
    batch_shape = (2,)
    a, b = create_solver_operands(
        "numpy",
        "float32",
        4,
        2,
        use_cuda=False,
        batch_shape=batch_shape,
        lhs_batch_format="implicit",
        rhs_batch_format="implicit",
    )
    # Same batch count, but explicit batching for the operand we pass to reset_operands.
    a_bad, b_bad = create_solver_operands(
        "numpy",
        "float32",
        4,
        2,
        use_cuda=False,
        batch_shape=batch_shape,
        lhs_batch_format="explicit",
        rhs_batch_format="explicit",
    )
    with _solver_after_solve(a, b) as solver:
        if mismatch_operand == "lhs":
            with pytest.raises(ValueError, match="batching metadata for 'a'"):
                solver.reset_operands(a=a_bad)
        else:
            with pytest.raises(ValueError, match="batching metadata for 'b'"):
                solver.reset_operands(b=b_bad)


@pytest.mark.parametrize("mismatch_operand", ("lhs", "rhs"))
def test_reset_operands_rejects_matrix_order_mismatch(mismatch_operand):
    """System size n and row count must stay aligned with the solver."""
    a, b = create_solver_operands("numpy", "float32", 4, 2, use_cuda=False)
    a_bad, b_bad = create_solver_operands("numpy", "float32", 5, 2, use_cuda=False)
    with _solver_after_solve(a, b) as solver:
        if mismatch_operand == "lhs":
            with pytest.raises(ValueError, match=r"number of columns for 'a'"):
                solver.reset_operands(a=a_bad)
        else:
            with pytest.raises(ValueError, match=r"number of columns for 'b'"):
                solver.reset_operands(b=b_bad)


def test_reset_operands_rejects_nrhs_mismatch():
    """Replacement RHS must keep the same nrhs as the original problem."""
    a, b = create_solver_operands("numpy", "float32", 4, 3, use_cuda=False)
    _, b_bad = create_solver_operands("numpy", "float32", 4, 1, use_cuda=False)
    with _solver_after_solve(a, b) as solver, pytest.raises(ValueError, match="number of right-hand sides"):
        solver.reset_operands(b=b_bad)


@pytest.mark.parametrize("with_release", [False, True])
def test_reset_operands_all_none(with_release):
    """reset_operands() with all-None always raises ValueError.
    See assert_reset_to_none_behavior."""
    a, b = create_solver_operands("numpy/cupy", "float32", 4, None, use_cuda=True)

    with nvmath.linalg.DirectSolver(a, b) as solver:
        solver.plan()
        solver.factorize()
        assert_reset_to_none_behavior(
            with_release=with_release,
            single_operand=False,
            obj=solver,
        )
