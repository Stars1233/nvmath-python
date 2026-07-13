# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Lifecycle tests for :class:`DirectSolver`.

Pins the method-ordering gates (plan -> factorize -> solve), the
release/reset transitions, and the idempotence of plan/free/context-exit.
All cases use CPU/numpy trivial inputs on Slab.X since numerical correctness
is out of scope here (see test_correctness.py).
"""

from __future__ import annotations

import pytest

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolver, DirectSolverOptions, InvalidDirectSolverState

from ....helpers import assert_reset_to_none_behavior
from .operand_factories import constant_b, nonsingular_a
from .params import GLOBAL_N, NRHS, skip_if_no_cupy

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------


def _device_id(memory_space):
    return nvmath.distributed.get_context().device_id if memory_space == "cuda" else None


def _nonsingular_a(memory_space="cpu"):
    ctx = nvmath.distributed.get_context()
    nranks = ctx.process_group.nranks
    return nonsingular_a(
        GLOBAL_N // nranks,
        GLOBAL_N,
        ctx.process_group.rank,
        package="cupy" if memory_space == "cuda" else "numpy",
        memory_space=memory_space,
        device_id=_device_id(memory_space),
    )


def _ones_b(memory_space="cpu"):
    nranks = nvmath.distributed.get_context().process_group.nranks
    return constant_b(
        GLOBAL_N // nranks,
        NRHS,
        package="cupy" if memory_space == "cuda" else "numpy",
        memory_space=memory_space,
        device_id=_device_id(memory_space),
    )


def _make_solver(memory_space="cpu"):
    a = _nonsingular_a(memory_space)
    b = _ones_b(memory_space)
    return DirectSolver(a, b, distributions=[Slab.X, Slab.X])


# ---------------------------------------------------------------------------
# Setup helpers used by the method-ordering tests
# ---------------------------------------------------------------------------


def _setup_constructed(solver):
    pass


def _setup_planned(solver):
    solver.plan()


def _setup_released(solver):
    solver.plan()
    solver.factorize()
    solver.release_operands()


def _setup_freed(solver):
    solver.free()


def _call_plan(solver):
    solver.plan()


def _call_factorize(solver):
    solver.factorize()


def _call_solve(solver):
    solver.solve()


@pytest.mark.parametrize(
    "setup,call,exc,match",
    [
        (_setup_constructed, _call_factorize, RuntimeError, r"before plan\(\) has been called"),
        (_setup_constructed, _call_solve, RuntimeError, r"before plan\(\) has been called"),
        (_setup_planned, _call_solve, RuntimeError, r"before factorize\(\) has been called"),
        (_setup_released, _call_plan, RuntimeError, r"after the operands have been released"),
        (_setup_released, _call_factorize, RuntimeError, r"after the operands have been released"),
        (_setup_released, _call_solve, RuntimeError, r"after the operands have been released"),
        (_setup_freed, _call_factorize, InvalidDirectSolverState, r"cannot be used after resources are free"),
    ],
    ids=[
        "factorize_before_plan",
        "solve_before_plan",
        "solve_before_factorize",
        "plan_after_release",
        "factorize_after_release",
        "solve_after_release",
        "factorize_after_free",
    ],
)
def test_method_call_gates(nvmath_distributed, setup, call, exc, match):
    solver = _make_solver()
    try:
        setup(solver)
        with pytest.raises(exc, match=match):
            call(solver)
    finally:
        solver.free()


def test_repeat_factorize_allowed(nvmath_distributed):
    """``factorize()`` may be called repeatedly"""
    with _make_solver() as solver:
        solver.plan()
        solver.factorize()
        # Second factorize on the same A succeeds (numerically wasteful but
        # not rejected). solve() against the freshly-rebuilt LU still works.
        solver.factorize()
        solver.solve()


def test_solve_after_reset_operands_a_still_requires_factorize(nvmath_distributed):
    """After ``reset_operands(a=...)`` the next ``solve()`` must raise until
    ``factorize()`` runs again -- a fresh A invalidates the cached LU and
    the precondition gate stays armed."""
    with _make_solver() as solver:
        solver.plan()
        solver.factorize()
        solver.solve()

        solver.reset_operands(a=_nonsingular_a())

        with pytest.raises(RuntimeError, match=r"before factorize\(\) has been called"):
            solver.solve()

        # Re-factorize and re-solve both succeed.
        solver.factorize()
        solver.solve()


def test_release_then_reset_round_trip(nvmath_distributed):
    with _make_solver() as solver:
        solver.plan()
        solver.factorize()
        solver.solve()

        solver.release_operands()

        # Only one of a/b supplied after release -> ValueError.
        with pytest.raises(ValueError, match=r"both 'a' and 'b' must be provided"):
            solver.reset_operands(a=_nonsingular_a())

        # Refresh both operands. plan() is intentionally NOT re-called; the
        # successful factorize() below proves _solver_planned is preserved.
        solver.reset_operands(a=_nonsingular_a(), b=_ones_b())
        solver.factorize()
        solver.solve()

        # Second release_operands() is a no-op (no exception).
        solver.release_operands()
        solver.release_operands()


@pytest.mark.parametrize("with_release", [False, True])
def test_reset_operands_all_none(with_release, nvmath_distributed):
    """reset_operands() with all-None always raises ValueError.
    See assert_reset_to_none_behavior."""
    with DirectSolver(_nonsingular_a(), _ones_b(), distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        solver.factorize()
        assert_reset_to_none_behavior(
            with_release=with_release,
            single_operand=False,
            obj=solver,
        )


@skip_if_no_cupy
def test_reset_updates_user_handles_so_next_release_clears_latest_wrappers(nvmath_distributed):
    """``reset_operands`` must rebind ``_{lhs,rhs}_user`` to the new user
    wrappers. Otherwise a subsequent ``release_operands`` clears stale
    wrappers and silently fails to drop the solver-side reference
    to the most recent user inputs.

    Uses GPU operands with ``inplace_a=False`` / ``inplace_b=False``: that
    forces compute mirrors (``_{lhs,rhs}_user`` are populated only on the mirror
    path), and those handles wrap the user's actual *device* input buffers --
    distinct from the mirrors -- so release nulling them genuinely drops the
    solver's reference to the user's GPU tensors. (On a CPU operand
    ``_{lhs,rhs}_user`` are only host-array wrappers; on GPU + ``inplace=True``
    there is no mirror, so the handles don't exist at all.)
    """
    a = _nonsingular_a("cuda")
    b = _ones_b("cuda")
    options = DirectSolverOptions(inplace_a=False, inplace_b=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        solver.solve()

        # Release nulls _{lhs,rhs}_user.tensor on the initial-construction
        # wrappers; reset must then rebind both user handles to the new
        # wrappers.
        solver.release_operands()
        solver.reset_operands(a=_nonsingular_a("cuda"), b=_ones_b("cuda"))

        latest_a_wrapper = solver._lhs_user
        latest_b_wrapper = solver._rhs_user
        assert latest_a_wrapper is not None and latest_a_wrapper.tensor is not None, (
            "reset_operands(a=...) must rebind _lhs_user to the new wrapper"
        )
        assert latest_b_wrapper is not None and latest_b_wrapper.tensor is not None, (
            "reset_operands(b=...) must rebind _rhs_user to the new wrapper"
        )

        # And a subsequent release must clear the latest wrappers
        solver.release_operands()
        assert latest_a_wrapper.tensor is None
        assert latest_b_wrapper.tensor is None


# ---------------------------------------------------------------------------
# idempotence of plan / free / context manager exit
# ---------------------------------------------------------------------------


def test_plan_twice_idempotent(nvmath_distributed):
    solver = _make_solver()
    try:
        solver.plan()
        solver.plan()
    finally:
        solver.free()


def test_free_twice_idempotent(nvmath_distributed):
    solver = _make_solver()
    solver.free()
    solver.free()


def test_context_exit_then_free_idempotent(nvmath_distributed):
    with _make_solver() as solver:
        pass
    solver.free()
