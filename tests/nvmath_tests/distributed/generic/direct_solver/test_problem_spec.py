# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Unit tests for the leaf-only distribution helpers in ``_problem_spec``.

:class:`TestDistributionContract` covers the contract documented in
``_problem_spec``'s "Distribution contract" comment block: every
``(operand_shape_ndim, distribution_ndim)`` combination listed there
has a matching test below. Keep them aligned -- if the contract
changes, update the matching test here (and vice versa).
"""

from __future__ import annotations

import pytest

import nvmath.distributed
from nvmath.distributed.distribution import BlockCyclic, ProcessGrid, Slab
from nvmath.distributed.linalg.generic import DirectSolverOptions
from nvmath.distributed.linalg.generic._problem_spec import (
    _DirectSolverProblemSpec,
    _leaf_check_a_distribution_requirements,
    _leaf_convert_distributions,
    _leaf_finalize_b_distribution,
)

_GLOBAL_N = 16


def _make_spec(*, a_shape, b_shape, dist_a, dist_b, rank=0, nranks=1):
    """Construct a leaf ``_DirectSolverProblemSpec`` carrying just enough
    state for the two helpers under test. Other leaf checks
    (dtypes, layout, placement) read disjoint fields and aren't exercised
    here, so we fill them with valid placeholders.
    """
    return _DirectSolverProblemSpec(
        shapes=[list(a_shape), list(b_shape)],
        operands_dtypes=["float64", "float64"],
        packages=["numpy", "numpy"],
        memory_spaces=["cpu", "cpu"],
        distributions=[dist_a, dist_b],
        options=_DirectSolverProblemSpec.Options(DirectSolverOptions()),
        nranks=nranks,
        is_leaf=True,
        is_F=[True, True],
        device_ids=["cpu", "cpu"],
        runtime_device_id=-1,
        rank=rank,
    )


def _blockcyclic2d(nprow, npcol, *, mb=4, nb=4, layout=ProcessGrid.Layout.COL_MAJOR, first_process=(0, 0)):
    pg = ProcessGrid(shape=(nprow, npcol), layout=layout)
    return BlockCyclic(pg, block_sizes=(mb, nb), first_process=first_process)


def _blockcyclic1d(nprow, *, mb=4, first_process=(0,)):
    pg = ProcessGrid(shape=(nprow,))
    return BlockCyclic(pg, block_sizes=(mb,), first_process=first_process)


class TestDistributionContract:
    """
    Covers the contract documented in ``_problem_spec``'s
    "Distribution contract" comment block.
    """

    def test_a_2d_shape_2d_dist_converts(self, nvmath_distributed):
        """A 2-D shape + 2-D dist → converts to 2-D ``BlockCyclic``,
        2-D BC requirements pass."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=Slab.X,
            dist_b=Slab.X,
            nranks=nranks,
        )
        _leaf_convert_distributions(spec)
        _leaf_check_a_distribution_requirements(spec)
        _leaf_finalize_b_distribution(spec)
        dist_a = spec.distributions[0]
        assert isinstance(dist_a, BlockCyclic)
        assert dist_a.ndim == 2

    def test_a_2d_shape_1d_dist_promotes(self, nvmath_distributed):
        """A 2-D shape + 1-D dist → the 1-D dist is a row-only partition and
        is promoted to its 2-D ``(nprow, 1)`` analog (same as ``Slab.X``)."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=_blockcyclic1d(nranks, mb=local_rows),
            dist_b=Slab.X,
            nranks=nranks,
        )
        _leaf_convert_distributions(spec)
        _leaf_check_a_distribution_requirements(spec)
        assert spec.shapes[0] == [local_rows, _GLOBAL_N]
        dist_a = spec.distributions[0]
        assert isinstance(dist_a, BlockCyclic)
        assert dist_a.ndim == 2
        assert dist_a.process_grid.shape == (nranks, 1)
        assert dist_a.first_process == (0, 0)

    def test_a_2d_shape_slab_y_promotes(self, nvmath_distributed):
        """A 2-D shape + ``Slab.Y`` → promoted to its
        2-D ``(1, npcol)`` analog."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        n_part = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(_GLOBAL_N, n_part),
            b_shape=(n_part, 4),
            dist_a=Slab.Y,
            dist_b=Slab.X,
            nranks=nranks,
        )
        _leaf_convert_distributions(spec)
        _leaf_check_a_distribution_requirements(spec)
        assert spec.shapes[0] == [_GLOBAL_N, n_part]
        dist_a = spec.distributions[0]
        assert isinstance(dist_a, BlockCyclic)
        assert dist_a.ndim == 2
        assert dist_a.process_grid.shape == (1, nranks)
        assert dist_a.first_process == (0, 0)

    def test_b_2d_shape_2d_dist_converts(self, nvmath_distributed):
        """b 2-D shape + 2-D dist → converts to 2-D ``BlockCyclic``;
        finalizer leaves shape and dist untouched and only runs the 2-D
        BC requirements check."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=Slab.X,
            dist_b=Slab.X,
            nranks=nranks,
        )
        _leaf_convert_distributions(spec)
        _leaf_check_a_distribution_requirements(spec)
        before_shape = list(spec.shapes[1])
        before_dist = spec.distributions[1]
        _leaf_finalize_b_distribution(spec)
        assert spec.shapes[1] == before_shape
        assert spec.distributions[1] is before_dist
        assert spec.distributions[1].ndim == 2

    def test_b_1d_shape_1d_dist_converts_and_promotes(self, nvmath_distributed):
        """b 1-D shape + 1-D dist → converter leaves b 1-D, then
        the finalizer promotes both the local shape (``[rows]`` →
        ``[rows, 1]``) and the distribution (1-D over ``(nprow,)`` →
        2-D ``BlockCyclic`` over ``(nprow, 1)``)."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows,),
            dist_a=_blockcyclic2d(nranks, 1, mb=local_rows, nb=_GLOBAL_N),
            dist_b=_blockcyclic1d(nranks, mb=local_rows),
            nranks=nranks,
        )
        # Converter leaves b 1-D; promotion is the finalizer's job.
        _leaf_convert_distributions(spec)
        assert spec.distributions[1].ndim == 1
        _leaf_check_a_distribution_requirements(spec)
        _leaf_finalize_b_distribution(spec)
        assert spec.shapes[1] == [local_rows, 1]
        dist_b = spec.distributions[1]
        assert isinstance(dist_b, BlockCyclic)
        assert dist_b.ndim == 2
        assert dist_b.process_grid.shape == (nranks, 1)
        assert dist_b.block_sizes == (local_rows, 1)
        assert dist_b.first_process == (0, 0)

    def test_b_1d_shape_slab_converts_and_promotes(self, nvmath_distributed):
        """b 1-D shape + ``Slab.X`` (ndim=None) → Slab adopts b's 1-D ndim, the
        converter leaves b 1-D, then the finalizer promotes the shape to
        ``[rows, 1]`` and the distribution to 2-D ``(nprow, 1)``. Same outcome
        as the explicit-1-D-dist case but via the ``ndim=None`` Slab path."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows,),
            dist_a=Slab.X,
            dist_b=Slab.X,
            nranks=nranks,
        )
        # Converter leaves b 1-D; promotion is the finalizer's job.
        _leaf_convert_distributions(spec)
        assert spec.distributions[1].ndim == 1
        _leaf_check_a_distribution_requirements(spec)
        _leaf_finalize_b_distribution(spec)
        assert spec.shapes[1] == [local_rows, 1]
        dist_b = spec.distributions[1]
        assert isinstance(dist_b, BlockCyclic)
        assert dist_b.ndim == 2
        assert dist_b.process_grid.shape == (nranks, 1)
        assert dist_b.first_process == (0, 0)

    def test_b_1d_shape_2d_dist_rejects(self, nvmath_distributed):
        """b 1-D shape + 2-D dist → DirectSolver-aware ndim mismatch
        pointing at the two valid forms (2-D b + 2-D dist, or 1-D b + 1-D dist)."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows,),
            dist_a=_blockcyclic2d(nranks, 1, mb=local_rows, nb=_GLOBAL_N),
            dist_b=_blockcyclic2d(nranks, 1, mb=local_rows, nb=1),
            nranks=nranks,
        )
        with pytest.raises(
            ValueError,
            match=r"Distribution for b.*is 2-D, but b is 1-D.*pass b as a 2-D.*or use a 1-D distribution",
        ):
            _leaf_convert_distributions(spec)

    def test_b_2d_shape_1d_dist_promotes(self, nvmath_distributed):
        """b 2-D (multi-RHS) shape + 1-D dist → the 1-D dist describes a
        row-only partition and is promoted to its 2-D ``(nprow, 1)`` analog.
        The operand is *not* reshaped (it is already 2-D)."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=Slab.X,
            dist_b=_blockcyclic1d(nranks, mb=local_rows),
            nranks=nranks,
        )
        _leaf_convert_distributions(spec)
        # Operand shape is untouched: a 1-D dist on a 2-D b is a pure
        # distribution promotion, not an operand reshape.
        assert spec.shapes[1] == [local_rows, 4]
        dist_b = spec.distributions[1]
        assert isinstance(dist_b, BlockCyclic)
        assert dist_b.ndim == 2
        assert dist_b.process_grid.shape == (nranks, 1)
        assert dist_b.first_process == (0, 0)

    def test_a_3d_dist_rejects(self, nvmath_distributed):
        """A with ``dist_ndim`` outside the supported set ``{1, 2}`` (here 3-D)
        is rejected by the supported-ndim guard, independent of A's shape."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        pg = ProcessGrid(shape=(nranks, 1, 1))
        bad_dist = BlockCyclic(pg, block_sizes=(local_rows, 1, 1))
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=bad_dist,
            dist_b=Slab.X,
            nranks=nranks,
        )
        with pytest.raises(
            ValueError,
            match=r"Distribution for A.*is 3-D\. DirectSolver requires a 1-D or 2-D distribution for A",
        ):
            _leaf_convert_distributions(spec)

    def test_b_3d_dist_rejects(self, nvmath_distributed):
        """b with ``dist_ndim`` outside the supported set ``{1, 2}`` (here 3-D)
        is rejected by the supported-ndim guard, independent of b's shape."""
        nranks = nvmath.distributed.get_context().process_group.nranks
        local_rows = _GLOBAL_N // nranks
        pg = ProcessGrid(shape=(nranks, 1, 1))
        bad_dist = BlockCyclic(pg, block_sizes=(local_rows, 1, 1))
        spec = _make_spec(
            a_shape=(local_rows, _GLOBAL_N),
            b_shape=(local_rows, 4),
            dist_a=Slab.X,
            dist_b=bad_dist,
            nranks=nranks,
        )
        with pytest.raises(
            ValueError,
            match=r"Distribution for b.*is 3-D\. DirectSolver requires a 1-D or 2-D distribution for b",
        ):
            _leaf_convert_distributions(spec)
