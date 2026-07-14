# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Per-rank problem spec and cross-rank reducer for ``DirectSolver``."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal

from nvmath.distributed.distribution import BlockCyclic, ProcessGrid

from ._configuration import DirectSolverOptions

_SUPPORTED_DTYPES = ("float32", "float64", "complex64", "complex128")


# Operand-index → display label, used in error messages emitted by the
# leaf checks and the reducer.
_OPERAND_NAMES = ("A", "b")


def _grid_coords(grid: ProcessGrid, rank: int) -> tuple[int, int]:
    """Return ``(myprow, mypcol)`` of ``rank`` inside a 2-D ``ProcessGrid``.

    Mirrors :meth:`BlockCyclic._calc_local_shape`:
      - COL_MAJOR: ``(r % nprow, r // nprow)``
      - ROW_MAJOR: ``(r // npcol, r % npcol)``

    Custom ``process_array`` grids are not handled.
    """
    nprow, npcol = grid.shape
    if grid.layout == ProcessGrid.Layout.COL_MAJOR:
        return rank % nprow, rank // nprow
    return rank // npcol, rank % npcol


@dataclass(slots=True)
class _DirectSolverProblemSpec:
    @dataclass(slots=True)
    class Options:
        """Serialisable subset of :class:`DirectSolverOptions` for the spec
        reduction. ``logger`` is intentionally excluded.
        The custom ``__init__`` overrides dataclass-generated init so
        we can construct from a :class:`DirectSolverOptions`; ``__eq__`` /
        ``__repr__`` are still auto-generated from the field annotations.
        """

        def __init__(self, options: DirectSolverOptions):
            self.inplace_a = options.inplace_a
            self.inplace_b = options.inplace_b
            self.blocking = options.blocking
            # Every rank supplies its own handle or none do,
            # so the handle-creation path is taken uniformly.
            self.handle_is_none = options.handle is None

        inplace_a: bool = True
        inplace_b: bool = True
        blocking: Literal[True, "auto"] = "auto"
        handle_is_none: bool = True

    # ---- cross-rank-meaningful field ----

    # local shapes of [A, b] as supplied by the caller
    shapes: list[list[int]]

    # dtype name of [A, b] as supplied by the caller
    operands_dtypes: list[str]

    packages: list[str]
    memory_spaces: list[Literal["cuda", "cpu"]]

    # We type this as ``list[Any]`` because the element type changes mid-life
    # and neither end of the range works as a single static annotation.
    # At construction each element is an arbitrary ``Distribution``; the
    # converter then reassigns the list in place to ``list[BlockCyclic]``
    # (and the finalizer subsequently does ``distributions[1] = promoted``
    # when 1-D b is promoted to 2-D), after which downstream code reads
    # ``BlockCyclic``-only attributes off the elements.
    # ``Distribution`` is too loose for those read sites,
    # ``BlockCyclic`` is too tight for the construction site, and mypy
    # can't track the in-place narrowing, so we use ``Any`` to avoid
    # scattering ``cast(BlockCyclic, ...)`` at every post-converter read.
    # ``list`` (rather than ``Sequence``) so indexed-assignment paths in
    # the finalizer typecheck. The runtime invariant is enforced by an
    # ``isinstance(d, BlockCyclic)`` assert in the converter.
    distributions: list[Any]

    options: Options

    nranks: int

    # is_leaf=True means this _ProblemSpec hasn't yet been merged with another.
    is_leaf: bool = True

    # ---- leaf-only fields only meaningful while is_leaf=True; the
    # reducer does not preserve any cross-rank meaning for them ----

    # column-major flags of [A, b]
    is_F: list[bool] = field(default_factory=list)

    # int device id per operand (or "cpu")
    device_ids: list[int | str] = field(default_factory=list)

    # distributed runtime's device on this rank
    runtime_device_id: int = -1

    rank: int = -1


def _leaf_check_operands_ndim(p: _DirectSolverProblemSpec) -> None:
    """
    Validate operand dimensionality: A is 2-D; b is 1-D (single RHS) or
    2-D (one or more RHS). Per-axis extents are not checked here -- concrete
    extent constraints (e.g. ``A.cols == b.rows``) need the post-allreduce
    global shape and are validated in
    :meth:`_ResolvedProblemSpec.from_merged_spec`.
    """
    assert p.is_leaf, "p.is_leaf must be True"

    A_shape, b_shape = p.shapes
    if len(A_shape) != 2:
        raise ValueError(f"Operand A on rank {p.rank} must be 2-D (got {len(A_shape)}-D).")
    if len(b_shape) not in (1, 2):
        raise ValueError(f"Operand b on rank {p.rank} must be 1-D or 2-D (got {len(b_shape)}-D).")


def _leaf_check_operands_dtypes_and_layout(p: _DirectSolverProblemSpec) -> None:
    """
    Validate per-operand dtype is supported and the storage is column-major
    (optionally padded along the leading dimension).
    """
    assert p.is_leaf, "p.is_leaf must be True"

    for i, dtype in enumerate(p.operands_dtypes):
        if dtype not in _SUPPORTED_DTYPES:
            raise ValueError(
                f"Unsupported dtype {dtype} for operand {_OPERAND_NAMES[i]} on rank {p.rank}; "
                f"supported dtypes are {_SUPPORTED_DTYPES}."
            )

    for i, is_F in enumerate(p.is_F):
        if not is_F:
            raise ValueError(
                f"Operand {_OPERAND_NAMES[i]} on rank {p.rank} must be column-major "
                f"(unit row stride; leading dimension >= local rows)."
            )


def _leaf_check_operands_placement(p: _DirectSolverProblemSpec) -> None:
    """
    Validate package/memory/device consistency and that the
    operands sit on the same device as the distributed runtime on this rank.
    """
    assert p.is_leaf, "p.is_leaf must be True"

    if len(set(p.packages)) != 1:
        raise ValueError(
            f"The package for {_OPERAND_NAMES[0]} ({p.packages[0]}) and {_OPERAND_NAMES[1]} "
            f"({p.packages[1]}) on process {p.rank} must be the same."
        )
    if len(set(p.memory_spaces)) != 1:
        raise ValueError(
            f"The operands on process {p.rank} are not in the same memory space: got operand memory spaces {p.memory_spaces}"
        )

    if len(set(p.device_ids)) != 1:
        raise ValueError(
            f"The device id for {_OPERAND_NAMES[0]} ({p.device_ids[0]}) and {_OPERAND_NAMES[1]} "
            f"({p.device_ids[1]}) on process {p.rank} must be the same."
        )

    # When operands are on GPU, they must be on the same device as the
    # runtime. All operands share one device id (checked just above), so
    # one comparison covers both.
    if p.memory_spaces[0] != "cpu" and p.device_ids[0] != p.runtime_device_id:
        raise RuntimeError(
            f"The operands are not on the same device as the one assigned to the "
            f"distributed runtime on process {p.rank}: operand device ID is "
            f"{p.device_ids[0]} and the runtime device ID is {p.runtime_device_id}"
        )


def _check_block_cyclic_requirements(label: str, dist: BlockCyclic, rank: int) -> None:
    # cusolverMpCreateMatrixDesc itself requires the descriptor's
    # first-process pair (RSRC_A / CSRC_A) to be (0, 0) -- the docs
    # state "Only the value of 0 is currently supported" for both:
    # https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpcreatematrixdesc
    if dist.first_process != (0, 0):
        raise ValueError(
            f"first_process for {label} on rank {rank} must be (0, 0); got {dist.first_process}. "
            f"This most likely means you set a non-origin first_process when building the "
            f"distribution (the first_process= argument of BlockCyclic / BlockNonCyclic). "
            f"Note a 1-D distribution is promoted to 2-D, so a 1-D first_process like (1,) "
            f"shows up here as (1, 0). Check the first_process you passed."
        )

    assert dist.ndim == 2, f"distribution for {label} on rank {rank} should be 2-D; got ndim={dist.ndim}"

    # cusolverMpCreateDeviceGrid only accepts a COL_MAJOR or ROW_MAJOR
    # mapping enum,
    # see https://docs.nvidia.com/cuda/cusolvermp/usage/types.html#cusolvermpgridmapping-t
    if dist.process_grid.layout not in (ProcessGrid.Layout.COL_MAJOR, ProcessGrid.Layout.ROW_MAJOR):
        raise ValueError(
            f"DirectSolver requires a COL_MAJOR or ROW_MAJOR process grid for {label} "
            f"on rank {rank} (got layout {dist.process_grid.layout})."
        )


# ----------------------------------------------------------------------
# Distribution contract
# ----------------------------------------------------------------------
#
# DirectSolver accepts ``(distribution_for_A, distribution_for_b)``.
# cuSOLVERMp wants 2-D block-cyclic layout
# (https://docs.nvidia.com/cuda/cusolvermp/getting_started/index.html#introduction),
# so whichever user-facing type the caller picked, ``Slab``,
# ``BlockNonCyclic``, or ``BlockCyclic``, we convert it to ``BlockCyclic``
# and used the converted distribution objects for cuSOLVERMp.
# "Convert" here transforms the distribution *object's type*.
#
# Once a distribution is 2-D, `_check_block_cyclic_requirements` runs to enforce
# the cuSOLVERMp-specific requirements: ``first_process == (0, 0)``
# (RSRC_A / CSRC_A must be 0, see
# https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpcreatematrixdesc)
# and a ``COL_MAJOR`` / ``ROW_MAJOR`` process-grid layout.
#
# Legend:
#   shape ndim -- ndim of the local operand array the caller passed.
#   dist ndim  -- ndim declared by the distribution (``None`` for ``Slab``,
#                 which then adopts the operand's ndim).
#   convert    -- re-express the distribution object as a 2-D ``BlockCyclic``
#                 (no operand reshape).
#
#   Operand   shape ndim   dist ndim   distribution handling
#   ------    ----------   ---------   -----------------------------------------
#   A         2            2           convert to BlockCyclic
#   A         2            1           convert to BlockCyclic (1-D dist promoted
#                                      to 2-D; no operand reshape)
#   b         2            2           convert to BlockCyclic
#   b         1            1           convert to BlockCyclic, then promote to 2-D
#   b         1            2           reject in :func:`_leaf_convert_distributions`
#   b         2            1           convert to BlockCyclic (1-D dist promoted
#                                      to 2-D ``(nprow, 1)``; no operand reshape)
#
# The table only lists explicitly-dimensioned distributions. A ``Slab`` has
# ``dist ndim = None``: it adopts the operand's shape ndim, so it always behaves
# like the row whose ``dist ndim`` equals ``shape ndim``.
#
# A distribution with ``ndim`` outside the supported set ``{1, 2}`` (for both
# A and b) -- e.g. a ``BlockCyclic`` over a 3-D ``ProcessGrid`` -- is also
# rejected by the supported-ndim guard in :func:`_leaf_convert_distributions`.
#
# The pipeline is split across the leaf/cross-rank stages because the 1-D b
# promotion can only run *after* :func:`_cross_check_operands_ndim` confirms
# that every rank agrees b is 1-D (otherwise a 1-D b on one rank and a 2-D b
# on another would be silently equalized to the same 2-D shape):
#
#   1. :func:`_leaf_convert_distributions`
#   2. :func:`_leaf_check_a_distribution_requirements`
#   3. cross-rank checks
#   4. :func:`_leaf_finalize_b_distribution`


def _leaf_convert_distributions(p: _DirectSolverProblemSpec) -> None:
    """Convert each distribution to ``BlockCyclic`` with ndim matching the
    operand's shape.

    Pure mutation: no BlockCyclic-requirements check. Two pre-checks run
    ahead of ``.to()`` so the user sees ``DirectSolver``-aware messages
    instead of the generic ``"ndim argument (X) doesn't match..."`` from
    :meth:`Distribution._to_checks`:

    1. **Supported-ndim guard** (per operand): both A and b accept a 1-D or
       2-D distribution. ``ndim is None`` (e.g. ``Slab``) is always allowed --
       ``.to()`` picks up our ``ndim=`` argument.
    2. **1-D b + 2-D dist guard**: a 1-D b paired with a 2-D distribution is
       rejected here (``npcol > 1`` would split the single RHS column across
       process-columns) with a remediation-tailored message. The reverse, a
       2-D b with a 1-D dist, is allowed: ``.to()`` promotes the 1-D dist to
       its 2-D ``(nprow, 1)`` analog with no operand reshape.
    """
    assert p.is_leaf, "p.is_leaf must be True"

    # Cardinality check has to happen before any unpacking below so a user
    # who passes a single distribution gets the friendly message instead of
    # "not enough values to unpack".
    if len(p.distributions) != 2:
        msg = f"DirectSolver expects 2 distributions (for A, b) on rank {p.rank}; got {len(p.distributions)}."
        raise ValueError(msg)

    # Both A and b accept a 1-D or 2-D distribution: a 1-D distribution is a
    # row-/column-only partition that is promoted to its 2-D analog. (b may
    # itself be 1-D, the single-RHS shorthand; A is always 2-D.)
    supported_dist_ndims = (1, 2)

    new_dists: list[Any] = []
    for i, d in enumerate(p.distributions):
        shape_ndim = len(p.shapes[i])
        if d.ndim is not None:
            if d.ndim not in supported_dist_ndims:
                raise ValueError(
                    f"Distribution for {_OPERAND_NAMES[i]} on rank {p.rank} is {d.ndim}-D. "
                    f"DirectSolver requires a 1-D or 2-D distribution for {_OPERAND_NAMES[i]}."
                )

            # The following ``if`` rejects 1-D b with a 2-D distribution.
            # Only b can reach it: :func:`_leaf_check_operands_ndim` runs earlier
            # in the pipeline and rejects any A that isn't 2-D, so A's
            # ``shape_ndim`` is always 2 and never satisfies ``shape_ndim == 1``.
            # But, a 2-D b with a 1-D dist is intentionally allowed:
            # a 1-D dist describes a row-only partition of a (possibly multi-RHS) b,
            # and ``.to(BlockCyclic, ndim=2)`` below promotes it to the equivalent
            # ``(nprow, 1)`` 2-D dist with no operand reshape.
            if shape_ndim == 1 and d.ndim == 2:
                raise ValueError(
                    f"Distribution for b on rank {p.rank} is 2-D, but b is 1-D. Either pass b "
                    f"as a 2-D (rows, 1) array (and keep the 2-D distribution), or use a 1-D "
                    f"distribution (the 1-D-b shorthand for single-RHS solves)."
                )
        new_dists.append(d.to(BlockCyclic, ndim=shape_ndim, copy=True))
    p.distributions = new_dists
    for d in p.distributions:
        assert isinstance(d, BlockCyclic)  # only for type checker


def _leaf_check_a_distribution_requirements(p: _DirectSolverProblemSpec) -> None:
    """A's 2-D ``BlockCyclic`` requirements. Runs pre-cross-rank because A is
    always 2-D after :func:`_leaf_convert_distributions` -- there's nothing
    for it to wait on. b's requirements are checked post-cross-rank in
    :func:`_leaf_finalize_b_distribution` because they may need the 1-D -> 2-D
    promotion to have run first.
    """
    assert p.is_leaf, "p.is_leaf must be True"
    _check_block_cyclic_requirements("A", p.distributions[0], p.rank)


def _cross_check_operands_ndim(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    """
    Raise if any operand's number of dimensions disagrees across ranks.
    Must run before :func:`_leaf_finalize_b_distribution` so a 1-D b
    on one rank and a 2-D b on another surfaces as an explicit ndim
    mismatch instead of being silently normalized to the same 2-D shape.
    """
    for i in range(2):
        if len(p1.shapes[i]) != len(p2.shapes[i]):
            raise ValueError(
                f"The number of dimensions of the operand {_OPERAND_NAMES[i]} is inconsistent "
                f"across processes: {len(p1.shapes[i])} != {len(p2.shapes[i])}"
            )


def _cross_check_operands_dtypes(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    for i in range(2):
        if p1.operands_dtypes[i] != p2.operands_dtypes[i]:
            raise ValueError(
                f"Operand {_OPERAND_NAMES[i]} dtype does not match across processes: "
                f"{p1.operands_dtypes[i]} != {p2.operands_dtypes[i]}"
            )


def _cross_check_operands_placement(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    if p1.packages[0] != p2.packages[0]:
        raise ValueError(f"Operands do not belong to the same package on all processes: {p1.packages[0]} != {p2.packages[0]}")
    if p1.memory_spaces[0] != p2.memory_spaces[0]:
        raise ValueError(
            f'Operands are not in the same memory space ("cpu", "cuda") on all processes: '
            f"{p1.memory_spaces[0]} != {p2.memory_spaces[0]}"
        )


def _cross_check_options(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    for attr in ("inplace_a", "inplace_b", "blocking"):
        v1 = getattr(p1.options, attr)
        v2 = getattr(p2.options, attr)
        if v1 != v2:
            raise ValueError(f"DirectSolverOptions.{attr} is inconsistent across processes: {v1!r} != {v2!r}")

    # A handle's pointer value is per-rank, so only its presence is compared:
    # either every rank supplies its own handle or none do.
    if p1.options.handle_is_none != p2.options.handle_is_none:
        raise ValueError(
            "DirectSolverOptions.handle presence is inconsistent across processes: "
            "some ranks supplied a handle while others did not; either pass a handle "
            "on every rank or on none."
        )


def _cross_check_distributions(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    for i, (d1, d2) in enumerate(zip(p1.distributions, p2.distributions, strict=False)):
        if d1 != d2:
            raise ValueError(f"Distribution for {_OPERAND_NAMES[i]} doesn't match across processes: {d1} != {d2}")


def _leaf_finalize_b_distribution(p: _DirectSolverProblemSpec) -> None:
    """Post-cross-rank b-distribution handling.

    Two responsibilities:

    1. **Promote 1-D b to 2-D if needed.** Users may pass b as a 1-D array of
       length ``rows`` (paired with a 1-D distribution) as shorthand for a
       single-RHS solve (NRHS=1). We convert the 1-D distribution to
       the 2-D analog of the distribution.

    2. **Check b's 2-D ``BlockCyclic`` requirements.** Runs unconditionally on
       the (now always 2-D) ``p.distributions[1]``.

    Why post-cross-rank: step 1 must wait for :func:`_cross_check_operands_ndim`
    to confirm every rank agrees b is 1-D, otherwise a 1-D b on one rank and
    a 2-D b on another would be silently normalized to the same 2-D shape.

    Precondition: :func:`_leaf_convert_distributions` has run, so
    ``p.distributions[1]`` is a ``BlockCyclic`` whose ndim matches
    ``len(p.shapes[1])``.
    """
    assert p.is_leaf, "p.is_leaf must be True"

    b_shape = p.shapes[1]
    if len(b_shape) == 1:
        dist_b = p.distributions[1]
        assert dist_b.ndim == 1, "1-D b shape paired with non-1-D dist should have been rejected by the converter"
        assert not dist_b._bound, "user-supplied distributions should be not bound"
        # Promote the 1-D (nprow,) distribution to its 2-D (nprow, 1) analog.
        # The promoted grid's layout is irrelevant since one axis is size 1.
        p.distributions[1] = dist_b.to(BlockCyclic, ndim=2)
        # The promoted dist has process grid (nprow, 1), so every rank owns
        # the single global RHS column → local b is (rows, 1).
        p.shapes[1] = [b_shape[0], 1]

    _check_block_cyclic_requirements("b", p.distributions[1], p.rank)


def _leaf_mask_local_shapes(p: _DirectSolverProblemSpec) -> None:
    """
    Mirrors ``matmulmod._problem_spec_reducer``.
    """
    assert p.is_leaf, "p.is_leaf must be True"

    for i in range(2):
        d = p.distributions[i]
        if d._is_1d_distribution():
            continue
        myprow, mypcol = _grid_coords(d.process_grid, p.rank)
        if myprow != 0:
            p.shapes[i][1] = 0
        if mypcol != 0:
            p.shapes[i][0] = 0


def _accumulate_partitioned_dims(p1: _DirectSolverProblemSpec, p2: _DirectSolverProblemSpec) -> None:
    """
    Mirrors ``matmulmod._problem_spec_reducer``.
    """
    for i in range(2):
        d = p1.distributions[i]
        partitioned_dims = (0,) if d._is_row_wise() else (1,) if d._is_col_wise() else (0, 1)
        if len(partitioned_dims) == 1 and any(p1.shapes[i][j] != p2.shapes[i][j] for j in (0, 1) if j != partitioned_dims[0]):
            raise ValueError(
                f"The {_OPERAND_NAMES[i]} non-partitioned shape is inconsistent across "
                f"processes: {p1.shapes[i]} != {p2.shapes[i]}"
            )
        if p1 is not p2:  # nranks==1 fast path passes p1 is p2
            for dim in partitioned_dims:
                p1.shapes[i][dim] += p2.shapes[i][dim]


def _direct_solver_problem_spec_reducer(p1, p2) -> _DirectSolverProblemSpec | Exception:
    """
    Pairwise reduction op for ``allreduce_object`` over the problem spec.

    Running inside this reducer means every check above happens during the
    ``allreduce_object`` collective: a failure on any rank becomes an
    ``Exception``, so every rank raises the same error.
    """
    # IMPORTANT: the order below matters since some checks depend on others
    # do not change it before understanding the dependencies.

    try:
        # Early exit on an ``Exception`` from an earlier merge or local build.
        if isinstance(p1, Exception):
            return p1
        if isinstance(p2, Exception):
            return p2

        for p in (p1, p2):
            if p.is_leaf:
                _leaf_check_operands_ndim(p)
                _leaf_check_operands_dtypes_and_layout(p)
                _leaf_check_operands_placement(p)
                _leaf_convert_distributions(p)
                _leaf_check_a_distribution_requirements(p)

        _cross_check_operands_ndim(p1, p2)
        _cross_check_operands_dtypes(p1, p2)
        _cross_check_operands_placement(p1, p2)
        _cross_check_options(p1, p2)
        _cross_check_distributions(p1, p2)

        for p in (p1, p2):
            if p.is_leaf:
                _leaf_finalize_b_distribution(p)
                _leaf_mask_local_shapes(p)

        _accumulate_partitioned_dims(p1, p2)

    except Exception as e:
        return e

    p1.is_leaf = False
    return p1
