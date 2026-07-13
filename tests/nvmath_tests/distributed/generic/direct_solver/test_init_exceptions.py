# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Exception-path tests for :class:`DirectSolver`'s constructor."""

from __future__ import annotations

import numpy as np
import pytest

import nvmath.distributed
from nvmath.distributed.distribution import BlockCyclic, ProcessGrid, Slab
from nvmath.distributed.linalg import DirectSolver, DirectSolverOptions

from .operand_factories import constant_b, nonsingular_a

# nranks gating (_skip_if_invalid_nranks autouse) and the require_multi_rank
# fixture are provided by conftest.py. These tests pin their own global_n=16
# rather than params.GLOBAL_N: the shape/grid/block-size literals below are
# tightly coupled to that value.


def _valid_numpy_inputs(*, global_n: int = 16, nrhs: int = 4):
    """Return ``(a, b, distributions)`` for a valid CPU/numpy setup.

    Slab.X partitions ``a`` and ``b`` across ranks by rows, so the per-rank
    local row count is ``global_n // nranks``. ``global_n=16`` is chosen so
    it divides evenly for every value in :data:`params.VALID_NRANKS`.

    ``options`` is intentionally not returned: the default
    :class:`DirectSolverOptions` is what ``DirectSolver`` uses when omitted, so
    callers that need a non-default option build it inline.
    """
    pg = nvmath.distributed.get_context().process_group
    local_rows = global_n // pg.nranks
    a = nonsingular_a(local_rows, global_n, pg.rank)
    b = constant_b(local_rows, nrhs)
    distributions = [Slab.X, Slab.X]
    return a, b, distributions


# ===========================================================================
# Rank-agnostic exceptions
# ===========================================================================


def test_operand_a_not_2d(nvmath_distributed):
    a, b, distributions = _valid_numpy_inputs()
    a = np.asfortranarray(np.ones(8, dtype=np.float64))
    with pytest.raises(ValueError, match=r"Operand A on rank .* must be 2-D"):
        DirectSolver(a, b, distributions=distributions)


def test_operand_b_too_many_dims(nvmath_distributed):
    a, b, distributions = _valid_numpy_inputs()
    b = np.asfortranarray(np.ones((4, 4, 2), dtype=np.float64))
    with pytest.raises(ValueError, match=r"Operand b on rank .* must be 1-D or 2-D"):
        DirectSolver(a, b, distributions=distributions)


def test_operand_unsupported_dtype(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    a = np.asfortranarray(np.ones((local_rows, 16), dtype=np.int64))
    with pytest.raises(ValueError, match=r"Unsupported dtype"):
        DirectSolver(a, b, distributions=distributions)


def test_operand_not_column_major(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    # default numpy order is C (row-major); skip np.asfortranarray
    a = np.ones((local_rows, 16), dtype=np.float64)
    with pytest.raises(ValueError, match=r"must be column-major"):
        DirectSolver(a, b, distributions=distributions)


def test_wrong_number_of_distributions(nvmath_distributed):
    a, b, _ = _valid_numpy_inputs()
    distributions = [Slab.X]
    with pytest.raises(ValueError, match=r"expects 2 distributions"):
        DirectSolver(a, b, distributions=distributions)


def test_process_grid_unsupported_layout(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, _ = _valid_numpy_inputs()
    # process_array form leaves ProcessGrid.layout == None (i.e. neither
    # COL_MAJOR nor ROW_MAJOR).
    process_array = np.arange(nranks).reshape((nranks, 1))
    pg = ProcessGrid(process_array=process_array)
    bad_dist = BlockCyclic(pg, block_sizes=(16 // nranks, 16))
    distributions = [bad_dist, bad_dist]
    with pytest.raises(ValueError, match=r"requires a COL_MAJOR or ROW_MAJOR process grid"):
        DirectSolver(a, b, distributions=distributions)


def test_dtype_combo_unsupported(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    # float32 + float64 is not a documented (dtype(A), dtype(b)) row in
    # cuSOLVERMp's getrf/getrs compute table.
    a = np.asfortranarray(np.eye(local_rows, 16, dtype=np.float32))
    b = np.asfortranarray(np.ones((local_rows, 4), dtype=np.float64))
    with pytest.raises(TypeError, match=r"supported-combinations tables do not list"):
        DirectSolver(a, b, distributions=distributions)


def test_a_not_square(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    # Local rows still gather to global_m=16, but A grows to 17 columns so
    # the recovered global shape (16, 17) is non-square.
    a = np.asfortranarray(np.ones((local_rows, 17), dtype=np.float64))
    with pytest.raises(ValueError, match=r"requires A to be a square matrix"):
        DirectSolver(a, b, distributions=distributions)


def test_b_rows_mismatch(nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    # A stays a square (16, 16). b gets one extra local row per rank, so the
    # gathered global rows become 16 + nranks, mismatching global_m=16.
    b = np.asfortranarray(np.ones((local_rows + 1, 4), dtype=np.float64))
    with pytest.raises(ValueError, match=r"Global shape of b must be"):
        DirectSolver(a, b, distributions=distributions)


def test_blocking_factors_mismatch(nvmath_distributed):
    """A and b each use an explicit BlockCyclic with incompatible row block sizes.

    The 1-D-Slab auto-realignment in DirectSolver only triggers when *both*
    distributions are 1-D Slabs, so explicit BlockCyclic on both A and b
    forces the row-block-size invariant check (enforced by cusolverMpTrsm)
    to fire.
    """
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, _ = _valid_numpy_inputs()
    pg = ProcessGrid(shape=(nranks, 1))
    # mb=4 vs mb=2: numroc(16, 4, *, 0, nranks) and numroc(16, 2, *, 0, nranks)
    # both yield uniform local rows matching the (16 // nranks)-row baseline
    # built by _valid_numpy_inputs (8 for nranks=2, 4 for nranks=4).
    dist_a = BlockCyclic(pg, block_sizes=(4, 16))
    dist_b = BlockCyclic(pg, block_sizes=(2, 4))
    distributions = [dist_a, dist_b]
    with pytest.raises(ValueError, match=r"b's row block size must match A's row block size"):
        DirectSolver(a, b, distributions=distributions)


# ===========================================================================
# Multi-rank-only exceptions
#
# These need nranks >= 2: they rely on cross-rank divergence (rank 0 differing
# from its peers) or a multi-column process grid, neither of which exists on a
# single process. Each is guarded by the ``require_multi_rank`` fixture, which
# skips it cleanly at nranks=1.
# ===========================================================================


def test_first_process_not_origin(nvmath_distributed, require_multi_rank):
    nranks = nvmath.distributed.get_context().process_group.nranks
    a, b, _ = _valid_numpy_inputs()
    # 2-D process grid with multiple rows lets us set first_process=(1, 0).
    pg = ProcessGrid(shape=(nranks, 1))
    bad_dist = BlockCyclic(pg, block_sizes=(16 // nranks, 16), first_process=(1, 0))
    distributions = [bad_dist, bad_dist]
    with pytest.raises(ValueError, match=r"first_process for .* must be \(0, 0\)"):
        DirectSolver(a, b, distributions=distributions)


def test_1d_b_with_column_partitioned_dist(nvmath_distributed, require_multi_rank):
    """A 1-D b paired with a column-partitioning distribution is rejected.

    ``Slab.Y`` partitions on axis 1, but a 1-D b has no axis 1. The
    converter requests ``Slab.Y.to(BlockCyclic, ndim=1)`` (matching b's
    1-D shape) and ``Slab.to`` rejects it with "ndim must be greater
    than the partition dimension". This pins the contract that 1-D b is
    only a single-RHS-vector shorthand and can't be paired with a
    column-partitioning distribution.
    """
    nranks = nvmath.distributed.get_context().process_group.nranks
    local_rows = 16 // nranks
    a = np.asfortranarray(np.eye(local_rows, 16, dtype=np.float64))
    b = np.asfortranarray(np.ones(16, dtype=np.float64))  # 1-D
    distributions = [Slab.Y, Slab.Y]
    with pytest.raises(ValueError, match=r"must be greater than the partition dimension"):
        DirectSolver(a, b, distributions=distributions)


def test_cross_operands_ndim_b_mismatch(nvmath_distributed, require_multi_rank):
    """b is 1-D on rank 0, 2-D elsewhere.

    Only b is testable here: per-rank validation forces A to be 2-D on every
    rank, so an A ndim mismatch is rejected on the originating rank before
    the cross-rank check can run. b is allowed to be 1-D or 2-D per rank, so
    a cross-rank disagreement survives long enough to reach the cross-check.
    """
    nranks = nvmath.distributed.get_context().process_group.nranks
    rank = nvmath.distributed.get_context().process_group.rank
    a, _, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    if rank == 0:
        b = np.asfortranarray(np.ones(local_rows, dtype=np.float64))
    else:
        b = np.asfortranarray(np.ones((local_rows, 4), dtype=np.float64))
    with pytest.raises(ValueError, match=r"number of dimensions of the operand b is inconsistent"):
        DirectSolver(a, b, distributions=distributions)


@pytest.mark.parametrize("operand_idx, operand_label", [(0, "A"), (1, "b")])
def test_cross_operands_dtypes_mismatch(nvmath_distributed, require_multi_rank, operand_idx, operand_label):
    """Rank 0's parametrized operand is float32 instead of float64.

    Each rank's own ``(A, b)`` dtype pair does not need to be in the
    cuSOLVERMp compute table here -- the cross-rank dtype check fires
    before the compute-table lookup runs.
    """
    nranks = nvmath.distributed.get_context().process_group.nranks
    rank = nvmath.distributed.get_context().process_group.rank
    _, _, distributions = _valid_numpy_inputs()
    local_rows = 16 // nranks
    a_dtype, b_dtype = np.float64, np.float64
    if rank == 0:
        if operand_idx == 0:
            a_dtype = np.float32
        else:
            b_dtype = np.float32
    a = np.asfortranarray(np.eye(local_rows, 16, dtype=a_dtype))
    b = np.asfortranarray(np.ones((local_rows, 4), dtype=b_dtype))
    with pytest.raises(ValueError, match=rf"Operand {operand_label} dtype does not match across processes"):
        DirectSolver(a, b, distributions=distributions)


@pytest.mark.parametrize("operand_idx, operand_label", [(0, "A"), (1, "b")])
def test_cross_distributions_mismatch(nvmath_distributed, require_multi_rank, operand_idx, operand_label):
    """Rank 0 swaps the parametrized operand's Slab to Slab.Y.

    After normalization to a 2-D BlockCyclic, Slab.X lands on a process
    grid of shape ``(nranks, 1)`` while Slab.Y lands on ``(1, nranks)``, so
    the two distributions compare unequal across ranks for the parametrized
    operand. The local operand shapes are deliberately Slab.X-shaped on
    every rank: a post-reducer local-extent check would notice that later,
    but the cross-rank check fires first.
    """
    rank = nvmath.distributed.get_context().process_group.rank
    a, b, _ = _valid_numpy_inputs()
    distributions = [Slab.X, Slab.X]
    if rank != 0:
        distributions[operand_idx] = Slab.Y
    with pytest.raises(ValueError, match=rf"Distribution for {operand_label} doesn't match across processes"):
        DirectSolver(a, b, distributions=distributions)


@pytest.mark.parametrize("field", ["inplace_a", "inplace_b"])
def test_cross_inplace_option_mismatch(nvmath_distributed, require_multi_rank, field):
    """
    Mismatched per-operand ``DirectSolverOptions.inplace_a`` or
    ``inplace_b`` across ranks is rejected at construction; both fields
    must agree so every rank either allocates a mirror for that operand
    or aliases the user's tensor.
    """
    rank = nvmath.distributed.get_context().process_group.rank
    a, b, distributions = _valid_numpy_inputs()
    options = DirectSolverOptions(**{field: False}) if rank == 0 else DirectSolverOptions()
    with pytest.raises(ValueError, match=rf"DirectSolverOptions\.{field} is inconsistent across processes"):
        DirectSolver(a, b, distributions=distributions, options=options)
