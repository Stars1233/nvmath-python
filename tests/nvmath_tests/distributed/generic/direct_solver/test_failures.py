# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Runtime failure reporting for distributed :class:`DirectSolver`.

``factorize()`` is always blocking and checks the cross-rank ``info`` before
returning, so a singular system surfaces as a ``RuntimeError`` at the
``factorize()`` call site (rather than silently producing garbage or deferring
to ``solve()``). A non-singular system returns ``None`` and lets ``solve()``
proceed.
"""

from __future__ import annotations

import pytest

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolver

from .operand_factories import constant_b, nonsingular_a, singular_a
from .params import GLOBAL_N, HAS_CUPY, NRANKS

_NRHS = 4

# CPU always available; GPU only when cupy is installed.
_PLACEMENTS: list[tuple[str, str]] = [("numpy", "cpu")]
if HAS_CUPY:
    _PLACEMENTS.append(("cupy", "cuda"))


def _make_operands(kind: str, package: str, memory_space: str):
    """Build a row-partitioned (Slab.X) ``(a, b)`` pair. ``kind`` is
    ``"singular"`` (all-zeros A) or ``"nonsingular"`` (identity slab)."""
    ctx = nvmath.distributed.get_context()
    nranks = ctx.process_group.nranks
    rank = ctx.process_group.rank
    device_id = ctx.device_id if memory_space == "cuda" else None
    local = GLOBAL_N // nranks
    if kind == "singular":
        a = singular_a(local, GLOBAL_N, package=package, memory_space=memory_space, device_id=device_id)
    else:
        a = nonsingular_a(local, GLOBAL_N, rank, package=package, memory_space=memory_space, device_id=device_id)
    b = constant_b(local, _NRHS, package=package, memory_space=memory_space, device_id=device_id)
    return a, b


@pytest.mark.parametrize("package,memory_space", _PLACEMENTS, ids=[m for _, m in _PLACEMENTS])
def test_nonsingular_factorize_returns_none(package, memory_space, nvmath_distributed):
    """A non-singular A factorizes successfully; factorize() returns None
    (no result handle) and a subsequent solve() runs."""
    a, b = _make_operands("nonsingular", package, memory_space)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        assert solver.factorize() is None
        # The factorization is valid, so solve() proceeds without raising.
        solver.solve()


@pytest.mark.skipif(NRANKS < 2, reason="getrf reports singularity only for nranks >= 2")
@pytest.mark.parametrize("package,memory_space", _PLACEMENTS, ids=[m for _, m in _PLACEMENTS])
def test_singular_factorize_raises(package, memory_space, nvmath_distributed):
    """A singular A makes factorize() raise RuntimeError (it is always
    blocking and checks the cross-rank info before returning)."""
    a, b = _make_operands("singular", package, memory_space)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        with pytest.raises(RuntimeError, match="singular"):
            solver.factorize()


@pytest.mark.skipif(NRANKS < 2, reason="getrf reports singularity only for nranks >= 2")
def test_factorize_after_reset_to_singular_raises(nvmath_distributed):
    """After reset_operands(a=...) to a singular A, the next factorize()
    raises -- the stale (non-singular) factorization is not reused."""
    a_nonsing, b = _make_operands("nonsingular", "numpy", "cpu")
    with DirectSolver(a_nonsing, b, distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        assert solver.factorize() is None

        # Switch to a singular A (same shape/dtype/strides -> passes the
        # reset-operands invariant check). reset_operands invalidates the
        # cached LU so the next factorize() runs against the new A.
        a_sing, _ = _make_operands("singular", "numpy", "cpu")
        solver.reset_operands(a=a_sing)

        with pytest.raises(RuntimeError, match="singular"):
            solver.factorize()
