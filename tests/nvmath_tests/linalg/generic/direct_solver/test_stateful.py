# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import sys
from collections.abc import Sequence

import pytest

from nvmath.linalg.generic import DirectSolver

from ....helpers import check_freed_after
from .params import ALL_FRAMEWORKS, BATCH_FORMAT_COMBINATIONS
from .solver_utils import create_solver_operands, verify_solution


def _small_numpy_cpu_operands(
    *,
    batch_shape=None,
    lhs_batch_format=None,
    rhs_batch_format=None,
):
    """Small fixed-size CPU problem for fast precondition tests."""
    return create_solver_operands(
        "numpy",
        "float32",
        4,
        2,
        use_cuda=False,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )


class TestDirectSolverStatefulAPI:
    """Ordering and operand-lifecycle rules (numpy CPU, small systems)."""

    def test_factorize_rejected_before_plan(self):
        """factorize() is rejected before plan()."""
        a, b = _small_numpy_cpu_operands()
        with (
            DirectSolver(a, b) as solver,
            pytest.raises(
                RuntimeError,
                match=r"Factorization cannot be performed before plan\(\) has been called\.",
            ),
        ):
            solver.factorize()

    def test_solve_rejected_before_factorize(self):
        """solve() is rejected before factorize()."""
        a, b = _small_numpy_cpu_operands()
        with DirectSolver(a, b) as solver:
            solver.plan()
            with pytest.raises(
                RuntimeError,
                match=r"Solver Execution cannot be performed before factorize\(\) has been called\.",
            ):
                solver.solve()

    @pytest.mark.parametrize("method", ("plan", "factorize", "solve"))
    def test_release_operands_then_execute_fails(self, method):
        """
        plan / factorize / solve cannot run after release_operands() until
        reset_operands().
        """
        a, b = _small_numpy_cpu_operands()
        with DirectSolver(a, b) as solver:
            solver.plan()
            solver.factorize()
            solver.solve()
            solver.release_operands()
            with pytest.raises(
                RuntimeError,
                match="cannot be performed after the operands have been released",
            ):
                getattr(solver, method)()

    @pytest.mark.parametrize("which", ("a", "b"))
    def test_release_operands_reset_requires_both_operands(self, which):
        """
        After release_operands(), reset_operands must receive both ``a`` and ``b``.
        """
        a0, b0 = _small_numpy_cpu_operands()
        a1, b1 = _small_numpy_cpu_operands()
        with DirectSolver(a0, b0) as solver:
            solver.plan()
            solver.factorize()
            solver.solve()
            solver.release_operands()
            with pytest.raises(
                ValueError,
                match="both 'a' and 'b' must be provided to reset_operands",
            ):
                if which == "a":
                    solver.reset_operands(a=a1)
                else:
                    solver.reset_operands(b=b1)

    @BATCH_FORMAT_COMBINATIONS
    def test_reset_lhs_invalidates_factorization(self, batch_shape, lhs_batch_format, rhs_batch_format):
        """After reset_operands(a=...), solve() requires factorize() again."""
        a0, b0 = _small_numpy_cpu_operands(
            batch_shape=batch_shape,
            lhs_batch_format=lhs_batch_format,
            rhs_batch_format=rhs_batch_format,
        )
        a1, _ = _small_numpy_cpu_operands(
            batch_shape=batch_shape,
            lhs_batch_format=lhs_batch_format,
            rhs_batch_format=rhs_batch_format,
        )
        with DirectSolver(a0, b0) as solver:
            solver.plan()
            solver.factorize()
            solver.solve()
            solver.reset_operands(a=a1)
            with pytest.raises(
                RuntimeError,
                match=r"cannot be performed before factorize\(\) has been called\.",
            ):
                solver.solve()


@ALL_FRAMEWORKS
@BATCH_FORMAT_COMBINATIONS
class TestDirectSolverReferenceCount:
    """Refcount checks across frameworks and batching layouts."""

    def test_reference_count(self, framework, use_cuda, batch_shape, lhs_batch_format, rhs_batch_format):
        """
        After the context exits, user tensors ``a`` and ``b`` refcount matches
        pre-solver.
        """
        dtype = "float32"
        a, b = create_solver_operands(
            framework,
            dtype,
            4,
            2,
            use_cuda,
            batch_shape=batch_shape,
            lhs_batch_format=lhs_batch_format,
            rhs_batch_format=rhs_batch_format,
        )
        initial_refcount_a = sys.getrefcount(a)
        initial_refcount_b = sys.getrefcount(b)
        with DirectSolver(a, b) as solver:
            solver.plan()
            solver.factorize()
            x = solver.solve()
            verify_solution(a, b, x)
            if not isinstance(x, Sequence):
                # check_freed_after does not work for Sequence types
                with check_freed_after(x, "post op: x should have sole ownership"):
                    del x

        assert sys.getrefcount(a) == initial_refcount_a, "post op: a refcount changed"
        assert sys.getrefcount(b) == initial_refcount_b, "post op: b refcount changed"

        if lhs_batch_format != "explicit":
            with check_freed_after(a, "post op: a should have sole ownership"):
                del a
        if rhs_batch_format != "explicit":
            with check_freed_after(b, "post op: b should have sole ownership"):
                del b

    def test_release_operands_ref_count(self, framework, use_cuda, batch_shape, lhs_batch_format, rhs_batch_format):
        dtype = "float32"
        a, b = create_solver_operands(
            framework,
            dtype,
            4,
            2,
            use_cuda,
            batch_shape=batch_shape,
            lhs_batch_format=lhs_batch_format,
            rhs_batch_format=rhs_batch_format,
        )
        initial_refcount_a = sys.getrefcount(a)
        initial_refcount_b = sys.getrefcount(b)
        with DirectSolver(a, b) as solver:
            solver.plan()
            solver.factorize()
            solver.solve()
            solver.release_operands()
            assert sys.getrefcount(a) == initial_refcount_a, "post op: a refcount changed"
            assert sys.getrefcount(b) == initial_refcount_b, "post op: b refcount changed"

            if lhs_batch_format != "explicit":
                with check_freed_after(a, "post op: a should have sole ownership"):
                    del a
            if rhs_batch_format != "explicit":
                with check_freed_after(b, "post op: b should have sole ownership"):
                    del b
