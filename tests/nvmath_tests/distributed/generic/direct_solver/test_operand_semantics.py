# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Operand / in-place contract for :class:`DirectSolver`, over ``memory_space``.

The whole contract is one matrix in ``(memory_space, inplace_a, inplace_b)``.
A compute mirror sits between a user tensor and cuSOLVERMp whenever the operand
isn't already a writable device buffer -- i.e. for any CPU operand, or for a GPU
operand whose ``inplace_*`` is ``False``. The observable per cell:

- factorize() and the user's A:
  - ``inplace_a=True``  -> no mirror (GPU) or D2H copy-back (CPU); user A is
    overwritten with the LU factors.
  - ``inplace_a=False`` -> mirror absorbs getrf; user A is preserved.
- solve() and the user's b:
  - ``inplace_b=True``  -> returns the same Python object as ``b``; ``b`` is
    overwritten with ``x``.
  - ``inplace_b=False`` -> returns a freshly-allocated tensor; ``b`` is preserved.
- rhs (b) refresh: ``solve()`` re-reads the user's ``b`` into the rhs mirror on
  every call (matching the non-distributed DirectSolver), so an in-place edit to
  ``b`` is picked up by the next ``solve()`` without an intervening
  ``reset_operands(...)``. When no rhs mirror exists (GPU + ``inplace_b=True``),
  the user tensor IS the live buffer, so the edit is likewise visible.
- lhs (A) refresh: when A is mirrored, ``factorize()`` re-reads the user's
  current A into the mirror on every call (symmetric with the b refresh), so an
  in-place edit to a mirrored A is picked up by the next ``factorize()`` without
  an intervening ``reset_operands(a=...)``. When no lhs mirror exists (GPU +
  ``inplace_a=True``), the user tensor IS the live buffer, so the edit is
  likewise visible on the next ``factorize()``.

Tests below use ``A = scale * I`` with ``scale != 1`` so the closed-form
``x = b / scale`` is distinct from ``b``. Comprehensive numerical
coverage lives in test_correctness.py.
"""

from __future__ import annotations

import numpy as np
import pytest

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolver, DirectSolverOptions

from ....linalg.utils import to_numpy
from .operand_factories import constant_b, nonsingular_a
from .params import GLOBAL_N, NRHS, skip_if_no_cupy

try:
    import cupy as cp
except ImportError:
    cp = None  # type: ignore[assignment]

# memory_space axis; the cuda leg is skipped when cupy is unavailable.
MEMSPACES = [
    "cpu",
    pytest.param("cuda", marks=skip_if_no_cupy),
]


def _device_id(memory_space):
    return nvmath.distributed.get_context().device_id if memory_space == "cuda" else None


def _local_dim():
    return GLOBAL_N // nvmath.distributed.get_context().process_group.nranks


def _build_a(memory_space, *, scale, strict_lower=False):
    ctx = nvmath.distributed.get_context()
    return nonsingular_a(
        _local_dim(),
        GLOBAL_N,
        ctx.process_group.rank,
        scale=scale,
        strict_lower=strict_lower,
        package="cupy" if memory_space == "cuda" else "numpy",
        memory_space=memory_space,
        device_id=_device_id(memory_space),
    )


def _build_b(memory_space, *, value):
    return constant_b(
        _local_dim(),
        NRHS,
        value=value,
        package="cupy" if memory_space == "cuda" else "numpy",
        memory_space=memory_space,
        device_id=_device_id(memory_space),
    )


def _fill(arr, value, memory_space):
    """In-place ``arr[:] = value`` honoring cupy's current-device requirement."""
    if memory_space == "cuda":
        with arr.device:
            arr[:] = value
    else:
        arr[:] = value


@pytest.mark.parametrize("memory_space", MEMSPACES)
def test_inplace_a_false_preserves_user_a(nvmath_distributed, memory_space):
    """``inplace_a=False``: the lhs mirror absorbs getrf; the user's A is
    bitwise-unchanged. The trailing solve() (x = b/scale = 2) anchors the
    test to "factorize actually produced a usable LU in the mirror"."""
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=4.0)
    a_baseline = to_numpy(a).copy()
    options = DirectSolverOptions(inplace_a=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        np.testing.assert_array_equal(to_numpy(a), a_baseline)
        x = solver.solve()
        np.testing.assert_allclose(to_numpy(x), 2.0)


@pytest.mark.parametrize("memory_space", MEMSPACES)
def test_inplace_a_true_overwrites_user_a(nvmath_distributed, memory_space):
    """``inplace_a=True``: getrf writes the LU into the user's A (in place on
    GPU, via D2H copy-back on CPU). ``strict_lower`` makes ``LU != A`` so the
    overwrite is detectable -- a plain diagonal A would pass trivially."""
    a = _build_a(memory_space, scale=3.0, strict_lower=True)
    b = _build_b(memory_space, value=1.0)
    a_baseline = to_numpy(a).copy()
    options = DirectSolverOptions(inplace_a=True)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        assert not np.array_equal(to_numpy(a), a_baseline)


@pytest.mark.parametrize("memory_space", MEMSPACES)
def test_inplace_b_true_overwrites_b_and_returns_it(nvmath_distributed, memory_space):
    """``inplace_b=True``: solve() returns the same Python object as ``b`` and
    overwrites it with ``x`` (2I * x = 8 => x = 4)."""
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=8.0)
    options = DirectSolverOptions(inplace_b=True)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x = solver.solve()
        assert x is b
        np.testing.assert_allclose(to_numpy(b), 4.0)


@pytest.mark.parametrize("memory_space", MEMSPACES)
def test_inplace_b_false_returns_fresh_and_preserves_b(nvmath_distributed, memory_space):
    """``inplace_b=False``: solve() returns a freshly-allocated tensor (NOT
    ``b``); the user's ``b`` stays unchanged. The returned ``x`` still
    satisfies ``2I * x = 4 => x = 2``."""
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=4.0)
    b_baseline = to_numpy(b).copy()
    options = DirectSolverOptions(inplace_b=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x = solver.solve()
        assert x is not b
        np.testing.assert_array_equal(to_numpy(b), b_baseline)
        np.testing.assert_allclose(to_numpy(x), 2.0)


@pytest.mark.parametrize("memory_space", MEMSPACES)
def test_both_inplace_false_preserves_both(nvmath_distributed, memory_space):
    """``inplace_a=False`` AND ``inplace_b=False``: both user tensors stay
    intact and solve() returns a fresh tensor."""
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=4.0)
    a_baseline = to_numpy(a).copy()
    b_baseline = to_numpy(b).copy()
    options = DirectSolverOptions(inplace_a=False, inplace_b=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x = solver.solve()
        assert x is not b
        np.testing.assert_array_equal(to_numpy(a), a_baseline)
        np.testing.assert_array_equal(to_numpy(b), b_baseline)
        np.testing.assert_allclose(to_numpy(x), 2.0)


_WITH_B_MIRROR = [
    "cpu",
    pytest.param("cuda", marks=skip_if_no_cupy),
]


@pytest.mark.parametrize("memory_space", _WITH_B_MIRROR)
def test_mirror_autorefreshes_from_user_b(nvmath_distributed, memory_space):
    """When ``b`` is mirrored, ``solve()`` re-reads the user's current ``b`` into
    the mirror on every solve call, so an in-place edit to ``b`` is picked
    up without an intervening ``reset_operands(b=...)``.
    With ``A = 2I`` (so ``x = b / 2``):

    1. b = 4,        solve1 -> x0 = 2
    2. user edits b = 10 (in place)
    3. solve2        -> x1 = 5   (mirror auto-refreshed from b=10; no reset)
    4. reset_operands(b=b) is still valid and yields the same x

    inplace_b=False so x flows into a fresh tensor and the user's b is preserved.
    """
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=4.0)
    options = DirectSolverOptions(inplace_b=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x0 = solver.solve()
        np.testing.assert_allclose(to_numpy(x0), 2.0)

        _fill(b, 10.0, memory_space)

        # In-place edit is auto-propagated: solve() refreshes the mirror from b.
        x1 = solver.solve()
        np.testing.assert_allclose(to_numpy(x1), 5.0)

        # reset_operands remains valid and consistent with the auto-refresh.
        solver.reset_operands(b=b)
        x_fresh = solver.solve()
        np.testing.assert_allclose(to_numpy(x_fresh), 5.0)


@pytest.mark.parametrize("memory_space", _WITH_B_MIRROR)
def test_mirror_autorefreshes_from_user_a(nvmath_distributed, memory_space):
    """When A is mirrored (``inplace_a=False``), ``factorize()`` re-reads the
    user's current A into the mirror on every call, so an in-place edit to A is
    picked up without an intervening ``reset_operands(a=...)``.
    With ``b = 12`` fixed and ``A = scale * I`` (so ``x = b / scale``):

    1. A = 2I, factorize+solve1 -> x0 = 6
    2. user edits A = 3I (in place)
    3. factorize()+solve2       -> x1 = 4   (mirror auto-refreshed from 3I; no reset)
    4. reset_operands(a=a) is still valid and yields the same x

    inplace_b=False so x flows into a fresh tensor and the user's b is preserved.
    """
    a = _build_a(memory_space, scale=2.0)
    b = _build_b(memory_space, value=12.0)
    options = DirectSolverOptions(inplace_a=False, inplace_b=False)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x0 = solver.solve()
        np.testing.assert_allclose(to_numpy(x0), 6.0)

        # In-place edit A: 2I -> 3I (element-wise copy honoring cupy's device).
        new_a = _build_a(memory_space, scale=3.0)
        if memory_space == "cuda":
            with cp.cuda.Device(a.device.id):
                a[:] = new_a
        else:
            a[:] = new_a

        # In-place edit is auto-propagated: factorize() refreshes the mirror from A.
        solver.factorize()
        x1 = solver.solve()
        np.testing.assert_allclose(to_numpy(x1), 4.0)

        # reset_operands remains valid and consistent with the auto-refresh.
        solver.reset_operands(a=a)
        solver.factorize()
        x_fresh = solver.solve()
        np.testing.assert_allclose(to_numpy(x_fresh), 4.0)


@skip_if_no_cupy
def test_inplace_a_mutation_visible_without_reset_gpu(nvmath_distributed):
    """GPU + ``inplace_a=True`` (default, no lhs mirror): ``a[:] = new_a;
    factorize(); solve()`` returns the correct solution without an intervening
    ``reset_operands(a=...)`` -- the user's A is the live solver buffer."""
    a = _build_a("cuda", scale=2.0)
    b = _build_b("cuda", value=4.0)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        solver.factorize()
        x0 = solver.solve()  # 2I x = 4 => x = 2
        np.testing.assert_allclose(to_numpy(x0), 2.0)

        # Mutate A in place to 3I and refresh b in place; both writes and the
        # subsequent factorize()/solve() enqueue on cupy's current stream
        # (cuSOLVERMp picks it up), so no explicit sync is needed.
        with cp.cuda.Device(a.device.id):
            a[:] = _build_a("cuda", scale=3.0)
        _fill(b, 12.0, "cuda")

        solver.factorize()
        x1 = solver.solve()  # 3I x = 12 => x = 4
        np.testing.assert_allclose(to_numpy(x1), 4.0)


@skip_if_no_cupy
def test_inplace_b_mutation_visible_without_reset_gpu(nvmath_distributed):
    """GPU + ``inplace_b=True`` (default, no rhs mirror) with a cached LU:
    ``b[:] = new_b; solve()`` returns the correct solution without an
    intervening ``reset_operands(b=...)``."""
    a = _build_a("cuda", scale=2.0)
    b = _build_b("cuda", value=4.0)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X]) as solver:
        solver.plan()
        solver.factorize()
        x0 = solver.solve()  # 2I x = 4 => x = 2
        np.testing.assert_allclose(to_numpy(x0), 2.0)

        # New RHS, same LU. Mutate b in place; no reset_operands needed.
        _fill(b, 10.0, "cuda")
        x1 = solver.solve()  # 2I x = 10 => x = 5
        np.testing.assert_allclose(to_numpy(x1), 5.0)
