# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
``DirectSolver`` construction workflow: free functions that build a solver
instance in place, plus the derived problem spec they produce.
:func:`initialize_direct_solver` orchestrates the full workflow and is called
from ``DirectSolver.__init__``; see the "cuSOLVERMp workflow -> code map"
comment in ``solvermod.py`` for how each step maps onto this module.
"""

from __future__ import annotations

import logging
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Literal

import numpy as np

import nvmath.distributed
from nvmath import memory
from nvmath._internal.workspace import NumpyMemoryResource, Workspace
from nvmath.bindings import cusolverMp  # type: ignore[attr-defined]
from nvmath.distributed._internal import tensor_wrapper
from nvmath.distributed.distribution import BlockCyclic, BlockNonCyclic, Distribution, ProcessGrid
from nvmath.internal import typemaps, utils
from nvmath.internal.tensor_ifc import TensorHolder

from ...process_group import ReductionOp
from ._caching import get_handle
from ._factorization import _FactorizationState
from ._problem_spec import _direct_solver_problem_spec_reducer, _DirectSolverProblemSpec, _grid_coords

# Minimum supported cuSOLVERMp version (800 == 0.8.0).
_MIN_CUSOLVERMP_VERSION = 800


def _validate_cusolvermp_version(*, handle, logger: logging.Logger) -> int:
    """
    Validate the local cuSOLVERMp library version against the minimum.
    This is a purely local check.
    """
    assert handle is not None, "_validate_cusolvermp_version requires a cuSOLVERMp handle"
    version = int(cusolverMp.get_version(handle))

    if version < _MIN_CUSOLVERMP_VERSION:
        raise RuntimeError(f"cuSOLVERMp version {version} is below the required minimum {_MIN_CUSOLVERMP_VERSION}.")

    logger.info("cuSOLVERMp version %d validated.", version)
    return version


# (dtype(A), dtype(b)) -> cuSOLVERMp ``computeType`` for getrf / getrs.
#
# Sourced from the "supported combinations" tables published under
#   https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpgetrf
#   https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpgetrs
# Each documented row is same-type all the way across ("Data Type of A" ==
# computeType == "Output Data Type"), and "Data Type of B" is not separately
# enumerated; the only documented-safe path is dtype(B) == dtype(A) ==
# computeType. The descriptor API itself is looser -- cusolverMpCreateMatrixDesc
# takes one cudaDataType per descriptor, so descA / descB *could* in principle
# disagree -- but the supported-combinations tables don't list any such row.

_GETRF_GETRS_COMPUTE_TYPE_TABLE: dict[tuple[str, str], str] = {
    ("float32", "float32"): "float32",
    ("float64", "float64"): "float64",
    ("complex64", "complex64"): "complex64",
    ("complex128", "complex128"): "complex128",
}


def _resolve_compute_dtype(dtype_a: str, dtype_b: str) -> str:
    """
    Map the user's ``(dtype(A), dtype(b))`` pair to the single ``computeType``
    cusolverMpGetrf / cusolverMpGetrs will accept.
    """
    try:
        return _GETRF_GETRS_COMPUTE_TYPE_TABLE[(dtype_a, dtype_b)]
    except KeyError:
        supported = ", ".join(f"({a}, {b})" for (a, b) in _GETRF_GETRS_COMPUTE_TYPE_TABLE)
        raise TypeError(
            f"DirectSolver: cuSOLVERMp's getrf/getrs supported-combinations "
            f"tables do not list a (dtype(A), dtype(b)) = ({dtype_a}, {dtype_b}) "
            f"row; documented combinations are {supported}."
        ) from None


def _local_shape_fits(
    operand: TensorHolder,
    local_rows_expected: int,
    local_cols_expected: int,
) -> bool:
    """Return whether the user's local buffer has at least the numroc-prescribed extents.

    Pure per-rank predicate (no raise): the prescribed extents are
    merged-spec-derived (symmetric) but the operand shape is this rank's local
    shape, so the verdict is per-rank. :meth:`_ResolvedProblemSpec.from_merged_spec`
    records it on the spec and :func:`_check_local_shapes_collective` reduces it
    across ranks so a too-small buffer fails construction on every rank.
    """
    rows = operand.shape[0]
    cols = operand.shape[1] if len(operand.shape) >= 2 else 1
    return rows >= local_rows_expected and cols >= local_cols_expected


def _operand_lld(o: TensorHolder, fallback_local_rows: int) -> int:
    """
    Compute the cuSOLVERMp descriptor ``lld`` (in elements) for ``o``.
    """
    if any(d == 0 for d in o.shape):
        return max(fallback_local_rows, 1)
    if len(o.shape) == 1:
        return int(o.shape[0])
    # for cols <= 1 the column stride is degenerate
    # (often 1 element on cupy/numpy because the size-1 axis allows any
    # stride). The cuSOLVERMp descriptor still requires lld >= local rows;
    # since there's no padding possible with a single column, lld == rows.
    if o.shape[1] <= 1:
        return int(o.shape[0])
    return int(o.strides[1])


def _is_col_major(o: TensorHolder) -> bool:
    """Return True if ``o``'s local layout is column-major (Fortran).

    Generalised F-order check with padded leading-dim allowance, of any
    ndim. For 2-D this matches cuSOLVERMp's matrix-descriptor constraint:
    unit stride down a column (``strides[0] == 1``) and a
    column-to-column stride at least ``shape[0]`` (the descriptor's
    ``lld``, which lets the user pass a slice of a larger allocation,
    e.g. ``A_buf[:, :n]`` from an ``(m, N)`` buffer with ``N > n``).

    Empty operands (any zero-sized dim) have degenerate strides on
    NumPy / CuPy -- we short-circuit to True so ranks that legitimately
    own no data (e.g. ``b``'s column slab on ``mypcol > 0``) don't fail
    the check.
    """
    # TODO: maybe there is a better way to do this, revisit later.

    # NOTE: ``o.strides`` is in elements (not bytes); see TensorHolder.strides.
    if any(d == 0 for d in o.shape):
        return True
    # Innermost meaningful axis must have stride 1; each subsequent
    # meaningful axis must have stride >= shape * stride of the previous
    # one (padded LLD allowance). Axes with extent <= 1 are skipped.
    expected = 1
    first = True
    for k in range(len(o.shape)):
        if o.shape[k] <= 1:
            continue
        if first:
            if o.strides[k] != 1:
                return False
            first = False
        elif o.strides[k] < expected:
            return False
        expected = o.shape[k] * o.strides[k]
    return True


@dataclass(frozen=True, slots=True)
class _OperandResetInvariants:
    """
    Per-rank operand properties captured at __init__ time that must
    remain invariant across any subsequent :meth:`DirectSolver.reset_operands`
    call.
    """

    label: str
    dtype_name: str
    local_shape: tuple[int, ...]
    local_strides: tuple[int, ...]
    package: str
    device_id: int | Literal["cpu"]

    def check(self, wrapped: TensorHolder) -> None:
        if wrapped.name != self.package:
            raise ValueError(f"The package for {self.label} ({wrapped.name}) must match the original one ({self.package}).")
        if wrapped.device_id != self.device_id:
            raise ValueError(
                f"The device id for {self.label} ({wrapped.device_id}) must match the original one "
                f"({self.device_id}), which is also where the distributed runtime is bound on this rank."
            )
        if wrapped.dtype != self.dtype_name:
            raise ValueError(f"The dtype for {self.label} ({wrapped.dtype}) must match the original one ({self.dtype_name}).")

        utils.check_attribute_match(self.local_shape, tuple(wrapped.shape), f"local shape of operand {self.label}")
        utils.check_attribute_match(self.local_strides, tuple(wrapped.strides), f"local strides of operand {self.label}")


@dataclass(frozen=True, slots=True)
class _ResolvedProblemSpec:
    """
    Immutable, cross-rank-consistent description of the problem, derived once
    from the reduced :class:`_DirectSolverProblemSpec`.

    Every field is a pure function of the reduced spec, so it is identical on
    every rank by construction. Holds only the *derived* facts -- the runtime /
    distributed context and all acquired resources stay flat on the solver.

    ``local_ld_{a,b}`` is intentionally absent: it depends on the *active*
    operand buffer (mirror vs user alias), which isn't known until after operand
    staging, so it's resolved later and kept flat with the other resources.
    """

    # package / memory spaces
    package: str
    stream_package: str
    operands_memory_space: Literal["cuda", "cpu"]
    # cuSOLVERMp executes on GPU; this field is a constant for now, kept for
    # symmetry with ``operands_memory_space`` and to make the cross-space
    # mirror logic in :meth:`from_merged_spec` self-documenting.
    execution_space: Literal["cuda"]
    # mirror policy
    need_lhs_mirror: bool
    need_rhs_mirror: bool
    # dtypes
    cuda_dtype_a: Any
    cuda_dtype_b: Any
    solver_cuda_dtype: Any
    solver_dtype_name: str
    # global problem dims
    global_m: int
    global_n: int
    nrhs: int
    # cuSOLVERMp (ia, ja) / (ib, jb) Fortran 1-based offsets of the operated-on
    # submatrix within the global A / b.
    ia: int
    ja: int
    ib: int
    jb: int
    # distributions / process grids
    distribution_a: Distribution
    distribution_b: Distribution
    process_grid_a: ProcessGrid
    process_grid_b: ProcessGrid
    nprow_a: int
    npcol_a: int
    nprow_b: int
    npcol_b: int
    myprow_a: int
    mypcol_a: int
    myprow_b: int
    mypcol_b: int
    # blocking factors
    mb_a: int
    nb_a: int
    mb_b: int
    nb_b: int
    # per-rank local row counts (numroc); reused for the lld fallback
    local_rows_a: int
    local_rows_b: int
    # operand-reset invariants snapshotted from the user's pre-mirror operands
    lhs_reset_invariants: _OperandResetInvariants
    rhs_reset_invariants: _OperandResetInvariants

    @classmethod
    def from_merged_spec(cls, solver, merged_spec: _DirectSolverProblemSpec) -> _ResolvedProblemSpec:
        """
        Derive the resolved spec from the post-reducer ``merged_spec``.

        Reads runtime facts (``_runtime.rank``, ``_runtime.device_id``) and the
        wrapped *user* operands (``_lhs_user`` / ``_rhs_user``, which hold the
        user's tensors at this point in the workflow) off ``solver``, but does
        not mutate it -- the caller assigns the returned spec to
        ``solver._spec``.

        After the collective validation of the problem spec, all fields of the
        merged spec are guaranteed identical on all ranks, so every derivation
        below that is a pure function of ``merged_spec`` raises symmetrically
        across ranks (no collective-safety wrapping needed, unlike in
        :func:`_collective_problem_spec`).
        """
        package = merged_spec.packages[0]
        stream_package = "cuda" if package == "numpy" else package

        # Memory space of the user operands; execution space is always cuda.
        operands_memory_space = merged_spec.memory_spaces[0]
        execution_space: Literal["cuda"] = "cuda"

        # Per-operand "needs a compute mirror" decision. A mirror is required
        # when the operand's memory space differs from the execution space (data
        # has to be staged across address spaces anyway) or when the user opted
        # out of in-place mutation (cuSOLVERMp's getrf / getrs are destructive
        # in-place on A / b, so a separate buffer is needed to absorb the write).
        cross_space = operands_memory_space != execution_space
        need_lhs_mirror = cross_space or not solver._options.inplace_a
        need_rhs_mirror = cross_space or not solver._options.inplace_b

        # Per-operand matrix dtypes (used by cusolverMpCreateMatrixDesc, whose
        # cudaDataType parameter describes that matrix's element type).
        cuda_dtype_a = typemaps.NAME_TO_DATA_TYPE[merged_spec.operands_dtypes[0]]
        cuda_dtype_b = typemaps.NAME_TO_DATA_TYPE[merged_spec.operands_dtypes[1]]

        # Resolve the cuSOLVERMp ``computeType`` (passed to getrf / getrs) from
        # the (dtype(A), dtype(b)) pair via the documented supported-combinations
        # table.
        solver_dtype_name = _resolve_compute_dtype(merged_spec.operands_dtypes[0], merged_spec.operands_dtypes[1])
        solver_cuda_dtype = typemaps.NAME_TO_DATA_TYPE[solver_dtype_name]

        # The merged spec contains the global shape.
        global_a = tuple(merged_spec.shapes[0])
        global_b = tuple(merged_spec.shapes[1])
        if len(global_a) != 2 or global_a[0] != global_a[1]:
            raise ValueError(f"DirectSolver requires A to be a square matrix; got global shape {global_a}.")
        global_m = int(global_a[0])
        global_n = int(global_a[1])

        if len(global_b) != 2 or global_b[0] != global_m or global_b[1] < 1:
            raise ValueError(f"Global shape of b must be ({global_m}, NRHS) with NRHS >= 1; got {global_b}.")
        nrhs = int(global_b[1])

        distribution_a, distribution_b = merged_spec.distributions
        process_grid_a = distribution_a.process_grid
        process_grid_b = distribution_b.process_grid
        nprow_a, npcol_a = process_grid_a.shape
        nprow_b, npcol_b = process_grid_b.shape
        myprow_a, mypcol_a = _grid_coords(process_grid_a, solver._runtime.rank)
        myprow_b, mypcol_b = _grid_coords(process_grid_b, solver._runtime.rank)

        # Finalize the copied distribution objects with the global shape the
        # reducer just recovered from local-shape sums: if unbound, bind it;
        # otherwise, if their pre-bound global shape disagrees with what the data
        # actually implies, fail.
        for d, expected, name in (
            (distribution_a, (global_m, global_n), "A"),
            (distribution_b, (global_m, nrhs), "b"),
        ):
            if d._bound:
                if tuple(d._data_global_shape) != expected:
                    raise ValueError(
                        f"distribution for {name} was already bound to global_shape="
                        f"{d._data_global_shape}, but the global shape recovered from "
                        f"local operand shapes is {expected}. Pass an unbound distribution, "
                        f"or bind it to the correct global shape."
                    )
            else:
                d._bind(expected)

        mb_a, nb_a, mb_b, nb_b = _resolve_blocking_factors(distribution_a, distribution_b, global_m, solver._logger)

        # Per-rank local extents for the diagnostic log below; the row counts
        # are also stored on the spec (reused for the lld fallback). The
        # buffer-fit check is not done here, it is enforced
        # in _check_local_shapes_collective.
        #
        # ``distribution.shape(rank)`` must stay after _resolve_blocking_factors,
        # which may rewrite the distributions' block sizes in place.
        assert solver._lhs_user is not None and solver._rhs_user is not None
        local_rows_a, local_cols_a = distribution_a.shape(solver._runtime.rank)
        local_rows_b, local_cols_b = distribution_b.shape(solver._runtime.rank)

        solver._logger.info(
            "DirectSolver: rank=%d; A on (%dx%d) grid coord (%d,%d); "
            "b on (%dx%d) grid coord (%d,%d); m=%d n=%d; "
            "local A=(%d,%d); local b=(%d,%d)",
            solver._runtime.rank,
            nprow_a,
            npcol_a,
            myprow_a,
            mypcol_a,
            nprow_b,
            npcol_b,
            myprow_b,
            mypcol_b,
            global_m,
            global_n,
            local_rows_a,
            local_cols_a,
            local_rows_b,
            local_cols_b,
        )

        # Snapshot user-side operand traits for reset_operands from the user
        # wrappers in ``_lhs_user`` / ``_rhs_user``. Taken here (before
        # _resolve_active_operand_buffers derives the compute buffers) so it
        # captures the user wrappers' traits -- which is what reset_operands will
        # receive again from the user later -- regardless of which operands end
        # up mirrored.
        #
        # User-side device id: "cpu" under cpu operands (NumPy / torch CPU tensors
        # carry .device_id == "cpu"); the runtime GPU id under cuda operands.
        # Matches what TensorHolder.device_id returns for any operand the user
        # later passes to reset_operands.
        user_device_id: int | Literal["cpu"] = "cpu" if operands_memory_space == "cpu" else solver._runtime.device_id
        lhs_reset_invariants = _OperandResetInvariants(
            label="A",
            dtype_name=solver._lhs_user.dtype,
            local_shape=tuple(solver._lhs_user.shape),
            local_strides=tuple(solver._lhs_user.strides),
            package=package,
            device_id=user_device_id,
        )
        rhs_reset_invariants = _OperandResetInvariants(
            label="b",
            dtype_name=solver._rhs_user.dtype,
            local_shape=tuple(solver._rhs_user.shape),
            local_strides=tuple(solver._rhs_user.strides),
            package=package,
            device_id=user_device_id,
        )

        return cls(
            package=package,
            stream_package=stream_package,
            operands_memory_space=operands_memory_space,
            execution_space=execution_space,
            need_lhs_mirror=need_lhs_mirror,
            need_rhs_mirror=need_rhs_mirror,
            cuda_dtype_a=cuda_dtype_a,
            cuda_dtype_b=cuda_dtype_b,
            solver_cuda_dtype=solver_cuda_dtype,
            solver_dtype_name=solver_dtype_name,
            global_m=global_m,
            global_n=global_n,
            nrhs=nrhs,
            # Pin the submatrix offsets to 1 (Fortran 1-based) because we always operate
            # on the full user-supplied A / b for now.
            ia=1,
            ja=1,
            ib=1,
            jb=1,
            distribution_a=distribution_a,
            distribution_b=distribution_b,
            process_grid_a=process_grid_a,
            process_grid_b=process_grid_b,
            nprow_a=nprow_a,
            npcol_a=npcol_a,
            nprow_b=nprow_b,
            npcol_b=npcol_b,
            myprow_a=myprow_a,
            mypcol_a=mypcol_a,
            myprow_b=myprow_b,
            mypcol_b=mypcol_b,
            mb_a=mb_a,
            nb_a=nb_a,
            mb_b=mb_b,
            nb_b=nb_b,
            local_rows_a=local_rows_a,
            local_rows_b=local_rows_b,
            lhs_reset_invariants=lhs_reset_invariants,
            rhs_reset_invariants=rhs_reset_invariants,
        )


def _resolve_blocking_factors(
    distribution_a: BlockCyclic,
    distribution_b: BlockCyclic,
    global_m: int,
    logger: logging.Logger,
) -> tuple[int, int, int, int]:
    """Resolve ``(mb, nb)`` for A and b from their bound distributions.

    ``nb_b`` is intentionally not constrained against A's ``nb``: it controls how
    b's NRHS columns are dealt across b's process columns (via
    ``numroc(nrhs, nb_b, ...)`` downstream) and is independent of A's column
    blocking.

    Mirrors :meth:`Matmul._infer_blocking_sizes` in matmulmod.py. The in-place
    row-block rewrite is safe because the distributions are copies
    (:func:`_direct_solver_problem_spec_reducer` converts user-supplied
    distributions with ``copy=True``).
    """
    mb_a, nb_a = distribution_a.block_sizes
    mb_b, nb_b = distribution_b.block_sizes

    both_safe_to_realign = all(
        isinstance(d, BlockNonCyclic) and d._is_1d_distribution() for d in (distribution_a, distribution_b)
    )
    if both_safe_to_realign and mb_a != mb_b:
        # both_safe_to_realign guarantees both are 1-D BlockNonCyclic, so each
        # mb was inferred by _infer_block_sizes as a uniform partition of
        # global_m and is one of {global_m, global_m // nranks}. They differ
        # only when one operand leaves its row dim un-partitioned (mb ==
        # global_m): there a single block is interchangeable with nranks
        # contiguous blocks of global_m // nranks, so shrinking that mb relabels
        # block boundaries without moving any data.
        # Picking min() lands on the partitioned operand's mb (global_m //
        # nranks). It is still a divisor of global_m -- so the result remains a
        # valid uniform block and needs no divisibility re-check -- and it now
        # matches on both sides, satisfying cusolverMpTrsm's A.MB == X.MB rule.
        aligned = min(mb_a, mb_b)
        logger.info(
            "Aligning BlockNonCyclic row block sizes for cuSOLVERMp getrs: "
            "A.mb=%d, b.mb=%d -> %d (un-partitioned row dim admits any "
            "block size that divides global_m=%d).",
            mb_a,
            mb_b,
            aligned,
            global_m,
        )
        distribution_a._block_sizes = (aligned, nb_a)
        distribution_b._block_sizes = (aligned, nb_b)
        mb_a = mb_b = aligned

    # mb_b must match mb_a, or cusolverMpTrsm (inside getrs) fails with:
    # [cusolverMpTrsm_bufferSize] A.MB != X.MB: <mb_a> != <mb_b>
    if mb_b != mb_a:
        raise ValueError(
            f"b's row block size must match A's row block size (A's mb={mb_a}, "
            f"got b's mb={mb_b}); enforced by cusolverMpTrsm inside getrs."
        )
    return mb_a, nb_a, mb_b, nb_b


@dataclass(frozen=True, slots=True)
class _RuntimeContext:
    """The distributed-runtime facts the rest of construction depends on.

    Unlike :class:`_ResolvedProblemSpec`, these are *per-rank* (``rank`` and
    ``device_id`` differ across processes), so they are grouped on the solver
    as ``solver._runtime`` rather than folded into the cross-rank-consistent
    spec. Resolved before the construction try/rollback scope because the
    rollback path reads ``device_id``.

    ``distributed_ctx`` is the single source of truth; ``rank``, ``nranks``,
    and ``device_id`` are convenience accessors that delegate to it (kept as
    short names because construction reads them on many lines).
    """

    distributed_ctx: nvmath.distributed.DistributedContext

    @property
    def rank(self) -> int:
        return self.distributed_ctx.process_group.rank

    @property
    def nranks(self) -> int:
        return self.distributed_ctx.process_group.nranks

    @property
    def device_id(self) -> int:
        return self.distributed_ctx.device_id


def _resolve_runtime_context() -> _RuntimeContext:
    """Verify the NCCL communicator and snapshot the distributed context.

    Cheap and side-effect-free (no resource acquisition), so ``__init__`` runs
    it before entering the build/rollback scope and assigns the result to
    ``solver._runtime``.
    """
    distributed_ctx = nvmath.distributed.get_context()
    if distributed_ctx is None:
        raise RuntimeError("nvmath.distributed runtime is not initialized; call nvmath.distributed.initialize(...) first.")
    if distributed_ctx.nccl_comm is None:
        raise RuntimeError(
            "DirectSolver requires the NCCL backend to be active on the "
            "distributed runtime; re-initialize nvmath.distributed with NCCL."
        )

    return _RuntimeContext(distributed_ctx=distributed_ctx)


# ============================================================================
# Construction workflow -- module-level free functions operating on a solver.
# ``solver`` is intentionally untyped so these helpers don't depend on the
# DirectSolver type. Derived facts are read via ``solver._spec``, runtime facts
# via ``solver._runtime``; resources and operand state stay flat on ``solver``.
# ============================================================================


def _collective_problem_spec(
    solver,
    a: Any,
    b: Any,
    distributions: Sequence[Distribution],
) -> _DirectSolverProblemSpec:
    """
    Build the per-rank spec from user inputs and reduce it across ranks.
    """

    # This try block is needed to keep the allreduce_object collective
    # below deadlock-free: the failable user-input steps must turn any raise into an
    # Exception rather than an uncaught exception.
    # The reducer accepts Exceptions and propagates them
    # through the reduction. Without the catch, failing ranks would
    # exit before the collective and the surviving ranks would hang
    # in the allreduce. _DirectSolverProblemSpec construction
    # lives in the `else` branch because it's a plain @dataclass holder
    # that only stores fields semantic validation is deferred to
    # the reducer's _leaf_* helpers, which run inside the collective.
    local_spec: _DirectSolverProblemSpec | Exception
    try:
        operands = (
            tensor_wrapper.wrap_operand(a),
            tensor_wrapper.wrap_operand(b),
        )
        distributions = list(distributions)
    except Exception as e:
        local_spec = e
    else:
        # Hold the wrapped user operands (which may be CPU tensors) on the
        # user-side slots. ``_resolve_active_operand_buffers`` later derives the
        # actual compute buffers ``_lhs_compute`` / ``_rhs_compute`` from these.
        # Stored only on the success path; the exception path short-circuits
        # before any code reads these.
        solver._lhs_user, solver._rhs_user = operands

        local_spec = _DirectSolverProblemSpec(
            shapes=[list(o.shape) for o in operands],
            is_F=[_is_col_major(o) for o in operands],
            operands_dtypes=[o.dtype for o in operands],
            packages=[o.name for o in operands],
            memory_spaces=[o.device for o in operands],
            distributions=distributions,
            options=_DirectSolverProblemSpec.Options(solver._options),
            device_ids=[o.device_id for o in operands],
            runtime_device_id=solver._runtime.device_id,
            nranks=solver._runtime.nranks,
            rank=solver._runtime.rank,
        )

    if solver._runtime.nranks > 1:
        process_group = solver._runtime.distributed_ctx.process_group
        merged_or_exception = process_group.allreduce_object(local_spec, op=_direct_solver_problem_spec_reducer)
    else:
        # nranks==1: still feed the spec through the reducer once so its
        # leaf-only checks (per-rank preconditions) run -- and so a local
        # Exception is unwrapped uniformly with the multi-rank path.
        merged_or_exception = _direct_solver_problem_spec_reducer(local_spec, local_spec)

    if isinstance(merged_or_exception, Exception):
        raise merged_or_exception
    return merged_or_exception


def _check_local_shapes_collective(solver) -> None:
    """
    Check the per-rank local buffer-fit verdicts and enforce them collectively.

    Whether this rank's local A / b buffers meet the numroc-prescribed extents
    is a per-rank verdict (the prescribed extents are merged-spec-derived and
    symmetric, but the actual operand shape is local), so raising on it directly
    would be asymmetric. We compute it here from the bound distributions and the
    user wrappers, then OR the "too small" flags across ranks so every rank
    reaches the same verdict and raises together.

    Must run before :func:`_resolve_active_operand_buffers`, which may clear the
    ``_lhs_user`` / ``_rhs_user`` wrappers this reads.

    The reduced message names the offending operand(s) but not the specific
    rank(s); each rank still logs its own local detail below for debugging.
    """
    spec = solver._spec
    rank = solver._runtime.rank
    assert solver._lhs_user is not None and solver._rhs_user is not None
    local_rows_a, local_cols_a = spec.distribution_a.shape(rank)
    local_rows_b, local_cols_b = spec.distribution_b.shape(rank)
    lhs_fits = _local_shape_fits(solver._lhs_user, local_rows_a, local_cols_a)
    rhs_fits = _local_shape_fits(solver._rhs_user, local_rows_b, local_cols_b)

    # 1 == "this rank's buffer is too small"; reduced with MAX so the flag is
    # set on every rank if *any* rank's buffer is too small.
    flags = np.array(
        [0 if lhs_fits else 1, 0 if rhs_fits else 1],
        dtype=np.int32,
    )

    if not lhs_fits or not rhs_fits:
        solver._logger.error(
            "DirectSolver: rank=%d local operand buffer too small for the "
            "BlockCyclic distribution (A fits=%s, b fits=%s); cuSOLVERMp would "
            "read past the buffer.",
            rank,
            lhs_fits,
            rhs_fits,
        )

    if solver._runtime.nranks > 1:
        process_group = solver._runtime.distributed_ctx.process_group
        process_group.allreduce_buffer(flags, op=ReductionOp.MAX)

    lhs_too_small = bool(flags[0])
    rhs_too_small = bool(flags[1])
    if lhs_too_small or rhs_too_small:
        bad = [name for name, too_small in (("A", lhs_too_small), ("b", rhs_too_small)) if too_small]
        raise ValueError(
            f"DirectSolver: local operand buffer(s) {bad} are smaller than the "
            f"BlockCyclic distribution prescribes on at least one rank. "
            f"Pass local operands sized consistently with the distribution."
        )


def _resolve_active_operand_buffers(solver, stream_holder) -> None:
    """
    Resolve what ``solver._lhs_compute`` / ``solver._rhs_compute`` refer to for
    the actual computation, per-operand.

    For each of A / b:

    * If no mirror is needed, the user's tensor *is* the compute buffer:
      move it into ``_lhs_compute`` / ``_rhs_compute`` and clear the user slot.
    * Otherwise allocate a compute-space mirror via
      :meth:`DirectSolver._create_compute_mirror`, keeping the user's wrapper in
      ``_lhs_user`` / ``_rhs_user`` for the copy-back path and for
      ``release_operands``.

    After this call ``_lhs_compute`` / ``_rhs_compute`` are populated for the
    first time (they don't exist before it).
    """
    # ``_create_compute_mirror`` returns the abstract ``TensorHolder``;
    # at runtime it's the same concrete subclass as ``src`` (via
    # ``src.__class__.empty`` / ``src.to``). (No type: ignore needed here:
    # ``solver`` is untyped, so the assignment isn't narrowed by mypy.)
    assert solver._lhs_user is not None and solver._rhs_user is not None
    if solver._spec.need_lhs_mirror:
        solver._lhs_compute = solver._create_compute_mirror(solver._lhs_user, stream_holder)
    else:
        solver._lhs_compute = solver._lhs_user
        solver._lhs_user = None
    if solver._spec.need_rhs_mirror:
        solver._rhs_compute = solver._create_compute_mirror(solver._rhs_user, stream_holder)
    else:
        solver._rhs_compute = solver._rhs_user
        solver._rhs_user = None
    if solver._spec.need_lhs_mirror or solver._spec.need_rhs_mirror:
        solver._logger.info(
            "DirectSolver: rank=%d; copied operands to a separate buffer on device %d "
            "(A copied=%s, b copied=%s, operand_memspace=%s, execution_space=%s).",
            solver._runtime.rank,
            solver._runtime.device_id,
            solver._spec.need_lhs_mirror,
            solver._spec.need_rhs_mirror,
            solver._spec.operands_memory_space,
            solver._spec.execution_space,
        )


def _resolve_active_local_ld(solver) -> None:
    """
    Set :attr:`_local_ld_a` / :attr:`_local_ld_b` (flat resources) from the
    active :attr:`_lhs_compute` / :attr:`_rhs_compute` strides. Must run after
    :func:`_resolve_active_operand_buffers` (which decides what the active buffer
    is) and before :func:`_create_descriptors` (which bakes the LLD into the
    cuSOLVERMp descriptor).

    Kept flat (not in ``_spec``) because the LLD reflects the *active* buffer
    -- the mirror under CPU operands, the user wrapper under GPU operands --
    which isn't known until the mirror swap above has run.
    """
    solver._local_ld_a = _operand_lld(solver._lhs_compute, solver._spec.local_rows_a)
    solver._local_ld_b = _operand_lld(solver._rhs_compute, solver._spec.local_rows_b)
    solver._logger.info(
        "DirectSolver: rank=%d; lld(A)=%d lld(b)=%d (operands_memory_space=%s)",
        solver._runtime.rank,
        solver._local_ld_a,
        solver._local_ld_b,
        solver._spec.operands_memory_space,
    )


def _create_device_grids(solver) -> None:
    # Called only from the build workflow, which has already bound the
    # resource-allocation stream to ``solver._cusolvermp_handle``.
    # No ``set_stream`` is needed here.

    assert solver._cusolvermp_handle is not None, "_create_grids requires the cuSOLVERMp handle"

    # NCCL comm presence is guaranteed by _resolve_runtime_context
    nccl_comm = solver._runtime.distributed_ctx.nccl_comm
    assert nccl_comm is not None  # for mypy; enforced upstream

    # one device grid per descriptor
    def _grid_mapping(grid: ProcessGrid) -> cusolverMp.GridMapping:
        return (
            cusolverMp.GridMapping.COL_MAJOR
            if grid.layout == ProcessGrid.Layout.COL_MAJOR
            else cusolverMp.GridMapping.ROW_MAJOR
        )

    solver._cusolvermp_grid_a = cusolverMp.create_device_grid(
        solver._cusolvermp_handle,
        nccl_comm.ptr,
        solver._spec.nprow_a,
        solver._spec.npcol_a,
        _grid_mapping(solver._spec.process_grid_a),
    )
    solver._cusolvermp_grid_b = cusolverMp.create_device_grid(
        solver._cusolvermp_handle,
        nccl_comm.ptr,
        solver._spec.nprow_b,
        solver._spec.npcol_b,
        _grid_mapping(solver._spec.process_grid_b),
    )
    solver._logger.debug(
        "cuSOLVERMp grids created: gridA=%d gridB=%d",
        solver._cusolvermp_grid_a,
        solver._cusolvermp_grid_b,
    )


def _create_descriptors(solver) -> None:
    # Called only from the build workflow, after ``_create_device_grids``. The
    # handle's stream was already bound at ``cusolverMp.create`` time, so
    # no ``set_stream`` is needed.

    # Each descriptor's cudaDataType is *that matrix's* element type:
    # descA → dtype(A), descB → dtype(b). cuSOLVERMp's getrf/getrs
    # supported-combinations tables (see _GETRF_GETRS_COMPUTE_TYPE_TABLE)
    # force dtype(A) == dtype(b).
    # rsrc and csrc are zero: cuSOLVERMp only supports a (0, 0) first_process,
    # which _check_block_cyclic_requirements already enforced (with a message in
    # nvmath's own vocabulary) before we get here.
    # https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpcreatematrixdesc
    rsrc = 0
    csrc = 0

    solver._desc_a = cusolverMp.create_matrix_desc(
        solver._cusolvermp_grid_a,
        solver._spec.cuda_dtype_a,
        solver._spec.global_m,
        solver._spec.global_n,
        solver._spec.mb_a,
        solver._spec.nb_a,
        rsrc,
        csrc,
        solver._local_ld_a,
    )
    solver._desc_b = cusolverMp.create_matrix_desc(
        solver._cusolvermp_grid_b,
        solver._spec.cuda_dtype_b,
        solver._spec.global_m,
        solver._spec.nrhs,
        solver._spec.mb_b,
        solver._spec.nb_b,
        rsrc,
        csrc,
        solver._local_ld_b,
    )
    solver._logger.debug(
        "Matrix descriptors created: descA=%d descB=%d",
        solver._desc_a,
        solver._desc_b,
    )


def _create_factorization_state_and_workspaces(solver, stream_holder) -> None:
    assert solver._cusolvermp_grid_a is not None and solver._cusolvermp_grid_b is not None, (
        "grids must be created before allocating workspaces"
    )

    # ipiv holds one int64 pivot per local column cuSOLVERMp actually
    # factorises. That count is the distribution's prescribed local column
    # extent (``distribution.shape(rank)`` is numroc under the hood), *not* the
    # user's ``lhs.shape[1]``. The user's shape may carry trailing column
    # padding (see _local_shape_fits) that cuSOLVERMp never reads or writes;
    # sizing ipiv to it would waste memory without producing any extra pivots.
    _, local_cols_a = solver._spec.distribution_a.shape(solver._runtime.rank)
    solver._factorization_state = _FactorizationState(
        local_cols_a=local_cols_a,
        device_id=solver._runtime.device_id,
        stream_holder=stream_holder,
    )

    # Draw device scratch from the operand package's pool.
    # No user allocator option: this will likely move to NCCL
    # symmetric memory, for which we will own the allocation.
    device_allocator = memory._MEMORY_MANAGER[solver._spec.stream_package](solver._runtime.device_id, solver._logger)
    solver._device_workspace = Workspace(
        device_allocator,
        solver._logger,
        label="cuSOLVERMp device workspace",
    )

    # Host workspace allocator: pageable host memory for now.
    # We deliberately do not use pinned host memory here:
    #
    # - There's no benefit for now: ``factorize`` and ``solve`` are always
    #   host-blocking on the user's compute stream, so there's no async H2D/D2H
    #   overlap for pinned memory to accelerate, and the workspace lifetime is
    #   bounded by a host-side sync before the next call. ``factorize`` is
    #   host-blocking both because we impose it (the unconditional
    #   ``sync_and_check_factorize_info`` on the user stream after ``getrf``) and
    #   because cuSOLVERMp's ``getrf`` itself currently does an internal stream
    #   sync before returning; ``solve`` blocks via its blocking return-path
    #   dispatch.
    #
    # - It sidesteps a cuSOLVERMp 0.8.0 bug that produces wrong solver output
    #   whenever the host workspace uses pinned memory allocated via
    #   ``cudaMallocHost`` / ``cudaHostRegister`` (i.e.
    #   ``cudaPointerAttributes::devicePointer != NULL``). Pageable host memory
    #   avoids it entirely.
    host_resource = NumpyMemoryResource()

    solver._host_workspace = Workspace(
        host_resource,
        solver._logger,
        device_id=solver._runtime.device_id,
        label="cuSOLVERMp host workspace",
    )


def initialize_direct_solver(solver, a, b, *, distributions, stream) -> None:
    """
    Run the cuSOLVERMp construction workflow.
    The caller (:meth:`DirectSolver.__init__`) owns the partial-init rollback,
    so this function does not catch construction failures.

    IMPORTANT: the order below matters; don't reorder without re-reading
    the workflow and understanding the dependencies.
    """
    # Set context once so that every helper below uses it.
    with utils.device_ctx(solver._runtime.device_id):
        # collective validation and normalization of problem spec
        merged_spec = _collective_problem_spec(solver, a, b, distributions)

        # Derive the immutable, cross-rank-consistent spec and store it once.
        # from_merged_spec also snapshots the operand-reset invariants from the
        # user wrappers (_lhs_user / _rhs_user), which is why it must run BEFORE
        # _resolve_active_operand_buffers, which may clear those user slots (the
        # no-mirror path moves the user tensor into _lhs_compute / _rhs_compute
        # and nulls _lhs_user / _rhs_user).
        solver._spec = _ResolvedProblemSpec.from_merged_spec(solver, merged_spec)

        # Enforce the per-rank buffer-fit verdicts recorded on the spec. This is
        # a collective: it reduces the verdicts so a too-small local buffer on
        # any rank fails construction on every rank (symmetric raise), avoiding a
        # later deadlock in getrf/getrs. Must run while all ranks are still in
        # lockstep, i.e. before any per-rank-failable resource allocation below.
        _check_local_shapes_collective(solver)

        # everything below depends on the resolved problem spec

        # resolve the stream
        stream_holder = utils.get_or_create_stream(solver._runtime.device_id, stream, solver._spec.stream_package)
        solver._logger.info("Resource allocation stream: %s", stream_holder.obj)

        # resolve the handle
        if solver._options.handle is not None:
            solver._cusolvermp_handle = solver._options.handle
        else:
            solver._cusolvermp_handle = get_handle(solver._runtime.device_id, stream_holder.ptr)

        # Local cuSOLVERMp version check: each rank
        # validates its own handle's version against the minimum.
        solver._cusolvermp_version = _validate_cusolvermp_version(
            handle=solver._cusolvermp_handle,
            logger=solver._logger,
        )

        # Per-operand, bind the active compute buffer from the user wrapper:
        # - If :attr:`need_lhs_mirror` / :attr:`need_rhs_mirror` is True,
        #   allocate a compute mirror and stage the copy.
        # - Otherwise the user's tensor itself becomes the compute buffer.
        # Must run before any cuSOLVERMp resource creation that depends on the
        # active buffer layout.
        _resolve_active_operand_buffers(solver, stream_holder)

        # Finalize solver._local_ld_{a,b} from the strides of the
        # currently-active solver._lhs_compute / solver._rhs_compute (either an
        # alias of the user's tensor or the mirror just allocated above). Must
        # run before _create_descriptors so the descriptor's LLD reflects the
        # buffer cuSOLVERMp will read from.
        _resolve_active_local_ld(solver)

        _create_device_grids(solver)
        _create_descriptors(solver)

        # allocate the persistent _FactorizationState
        # (ipiv + info flags) and instantiate the device/host Workspace
        # objects *without* allocating the workspace memory.
        _create_factorization_state_and_workspaces(solver, stream_holder)
