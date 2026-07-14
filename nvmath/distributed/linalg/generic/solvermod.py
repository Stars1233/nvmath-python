# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

__all__ = ["DirectSolver", "InvalidDirectSolverState", "direct_solver"]

import logging
from collections.abc import Sequence
from typing import Any

from nvmath._internal.workspace import Workspace
from nvmath.bindings import (
    cublas,  # type: ignore[attr-defined]
    cusolverMp,  # type: ignore[attr-defined]
)
from nvmath.distributed._internal import tensor_wrapper
from nvmath.distributed.distribution import Distribution
from nvmath.internal import utils
from nvmath.internal.tensor_ifc import AnyTensor, TensorHolder
from nvmath.linalg._internal.solver_utils import compute_f_strides

from ._configuration import DirectSolverOptions
from ._factorization import _FactorizationState
from ._initialization import _resolve_runtime_context, _ResolvedProblemSpec, _RuntimeContext, initialize_direct_solver

# cuSOLVERMp workflow -> code map
# (https://docs.nvidia.com/cuda/cusolvermp/getting_started/index.html#workflow)
#
#   1. NCCL initialization
#        _resolve_runtime_context() (_initialization.py) -- verifies the NCCL
#        comm (the comm itself is created externally by
#        nvmath.distributed.initialize); called from __init__.
#   2. cusolverMpCreate (library handle)
#        initialize_direct_solver() (_initialization.py) -- via get_handle()
#        (cached) or a user-supplied options.handle.
#   3. cusolverMpCreateDeviceGrid
#        _create_device_grids() (_initialization.py).
#   4. cusolverMpCreateMatrixDesc
#        _create_descriptors() (_initialization.py).
#   5. query host/device buffer sizes
#        method: plan() -- getrf_buffer_size / getrs_buffer_size.
#   6. allocate host/device workspace
#        method: factorize() / solve() -- via Workspace.allocate_perhaps.
#        The Workspace objects are created during construction via
#        _create_factorization_state_and_workspaces() (_initialization.py)
#        and sized in plan().
#   7. execute the routine
#        method: factorize() (cusolverMpGetrf) / solve() (cusolverMpGetrs).
#   8. synchronize the local stream
#        method: factorize() (sync_and_check_factorize_info) / solve()
#        (stream sync before returning the result).
#   9. deallocate host/device workspace
#        method: factorize() / solve() (Workspace context-manager exit) and
#        free() -> _release_internal_resources().
#   teardown: cusolverMp{DestroyMatrixDesc, DestroyGrid, Destroy}
#        method: free() -> _release_internal_resources() (the handle
#        is owned by the handle cache, so the instance never destroys it).


# Shared doc fragments for the distributed dense direct linear solver public API.
GENERIC_DIRECT_SOLVER_DOCUMENTATION: dict = utils.COMMON_SHARED_DOC_MAP.copy()
GENERIC_DIRECT_SOLVER_DOCUMENTATION.update(
    {
        "a": """\
A distributed tensor representing the left-hand side operand :math:`a` of the linear system
:math:`a @ x = b` (see `Semantics`_). The currently
supported types are :class:`numpy.ndarray`, :class:`cupy.ndarray`, and
:class:`torch.Tensor`.""".replace("\n", " "),
        #
        "b": """\
A distributed tensor representing the right-hand side :math:`b` of the linear system
:math:`a @ x = b` (see `Semantics`_). The currently
supported types are :class:`numpy.ndarray`, :class:`cupy.ndarray`, and
:class:`torch.Tensor`.""".replace("\n", " "),
        #
        "distributions": """\
A sequence ``[distribution_for_a, distribution_for_b]`` specifying how :math:`a` and
:math:`b` are partitioned across processes. See `Semantics`_ and `Requirements`_ for the
supported distribution types and the constraints they must satisfy (in particular, the
row block size of :math:`b` must match that of :math:`a`).""".replace("\n", " "),
        #
        "options": """\
Specify options for the direct solver as a :class:`DirectSolverOptions` object.
Alternatively, a `dict` containing the parameters for the ``DirectSolverOptions``
constructor can also be provided. If not specified, the value will be set to the
default-constructed ``DirectSolverOptions`` object.""".replace("\n", " "),
        #
        "result": """\
A distributed tensor representing the solution :math:`x` of the linear system
:math:`a @ x = b`
(see `Semantics`_). It has the same distribution,
local shape, device, and package as the right-hand side ``b``. When the
:attr:`~nvmath.distributed.linalg.DirectSolverOptions.inplace_b` attribute of
:class:`DirectSolverOptions` is ``True`` (the default), :math:`x` is written into
``b`` in place and the returned object is ``b`` itself.""".replace("\n", " "),
        #
        "semantics": """\
        .. _Semantics:

        The distributed direct solver solves the dense linear system :math:`a @ x = b` for
        :math:`x`, where :math:`a` is a square ``(n, n)`` matrix and :math:`b` has shape
        ``(n, nrhs)`` or ``(n,)``, where ``nrhs`` is the number of RHS vectors.
        It performs an LU factorization with partial
        pivoting (:meth:`DirectSolver.factorize`) followed by triangular solves
        (:meth:`DirectSolver.solve`).
        The computation always runs on the GPU; CPU operands are copied to the device
        and back automatically.

        On each process, ``a`` and ``b`` hold only the portions of the global
        matrices :math:`a` and :math:`b` that are assigned to that process. The
        corresponding entries of ``distributions`` describe how :math:`a` and
        :math:`b` are partitioned across processes.

        The solution :math:`x` has the same local shape, memory space, and package
        as ``b`` and follows ``b``'s distribution. By default,
        :meth:`DirectSolver.factorize` overwrites ``a`` with its LU factors and
        :meth:`DirectSolver.solve` overwrites ``b`` with :math:`x` and returns
        ``b``; this in-place behavior is controlled by the
        :attr:`~nvmath.distributed.linalg.DirectSolverOptions.inplace_a` and
        :attr:`~nvmath.distributed.linalg.DirectSolverOptions.inplace_b` attributes of
        :class:`DirectSolverOptions` (both ``True`` by default). If :math:`a` is singular,
        :meth:`DirectSolver.factorize` raises.
""".strip(),
        #
        "requirements": """\
        .. _Requirements:

        **Operands.**

        - The global number of columns of ``a`` must match the global number of rows of
          ``b`` (both equal :math:`n`, the order of the square system).
        - ``a`` and ``b`` must belong to the same package and have the same dtype, one of
          ``float32``, ``float64``, ``complex64``, or ``complex128``.
        - ``a`` and ``b`` must reside in the same memory space on each process, and
          GPU operands must be on the device bound to the distributed runtime on
          that process.
        - The local arrays must be column-major; a padded leading dimension
          (a column-major slice of a larger buffer) is allowed.

        **Distributions.**

        ``distributions`` must contain exactly two entries,
        ``[distribution_for_a, distribution_for_b]``, respectively describing how ``a``
        and ``b`` are partitioned across processes.

        The simplest, but not most performant, choice is to give
        both ``a`` and ``b`` the same row-wise
        :class:`~nvmath.distributed.distribution.Slab` distribution (``Slab.X``),
        so that each process owns an equal, contiguous block of rows of the
        global operands. The only requirement here is that the global number of
        rows be divisible by the number of processes (a ``Slab`` with unequal
        partition sizes is not supported, because it cannot be expressed as a
        block-cyclic distribution); ``a`` and ``b`` are then partitioned
        consistently and all the other requirements below are satisfied
        automatically, so none of them need to be considered.

        In general, each distribution entry may be a
        :class:`~nvmath.distributed.distribution.Slab` (with uniform partition sizes),
        :class:`~nvmath.distributed.distribution.BlockNonCyclic`, or
        :class:`~nvmath.distributed.distribution.BlockCyclic` distribution,
        and ``a`` and ``b`` may use different distributions.
        This flexibility comes with stricter requirements:

        - The process grid must place its first process at ``(0, 0)`` and
          use a ``COL_MAJOR`` or ``ROW_MAJOR`` layout.
        - The row block size of ``b`` must equal that of ``a``, while column block sizes
          are independent.
        - A 1-D ``b`` requires ``b``'s distribution to be 1-D (row-only): a 2-D distribution
          is rejected, because the single column cannot be split across process columns.
        - For a 2-D ``b``, ``b``'s distribution may be either 1-D (row-only) or
          2-D, partitioning both rows and columns.
""".strip(),
        #
        # Re-generate these two with ``version_added=None``: the ``COMMON_SHARED_DOC_MAP``
        # defaults stamp ".. versionadded:: 0.9.0", which does not apply to the (newer)
        # distributed direct solver.
        "release_operands": utils._release_operand_docstring(True, execution_methods=("factorize", "solve")),
        "reset_operands_unchecked": utils._reset_operand_unchecked_docstring(True),
    }
)


class InvalidDirectSolverState(Exception):
    """Raised when a public method is called after :meth:`DirectSolver.free`."""


@utils.docstring_decorator(GENERIC_DIRECT_SOLVER_DOCUMENTATION, skip_missing=False)
class DirectSolver:
    """
    Create a stateful object that encapsulates the specified distributed direct solver
    computation for the dense linear system :math:`a @ x = b` and the required resources to
    perform it.

    A stateful object can be used to amortize the cost of preparation (planning and
    factorization) across multiple solves with different right-hand sides, or with updated
    operands of the same problem specification (see :meth:`reset_operands`).
    The function-form API :func:`direct_solver` is a convenient alternative for single
    use (the user needs to perform just one solve, for example), in which case there
    is no possibility of amortizing preparatory costs.

    Using the stateful object typically involves the following steps:

    1. **Problem Specification**: Initialize the object with the operands, their
       distributions, and options.
    2. **Preparation**: Use :meth:`plan` to query and size the solver workspaces for this
       specific problem.
    3. **Execution**: :meth:`factorize` the matrix and :meth:`solve` the system.
    4. **Resource Management**: Ensure all resources are released either by explicitly
       calling :meth:`free` or by managing the stateful object within a context manager.

    Detailed information on what is happening in the various phases described above can be
    obtained by passing in a :class:`logging.Logger` object to :class:`DirectSolverOptions`
    or by setting the appropriate options in the root logger object, which is used by
    default:

        >>> import logging
        >>> logging.basicConfig(
        ...     level=logging.INFO,
        ...     format="%(asctime)s %(levelname)-8s %(message)s",
        ...     datefmt="%m-%d %H:%M:%S",
        ... )

    Args:
        a: {a}

        b: {b}

        distributions: {distributions}

        options: {options}

        stream: {stream}

    Semantics:
        {semantics}

    Requirements:
        {requirements}

    .. seealso::
        :meth:`plan`, :meth:`factorize`, :meth:`solve`, :meth:`reset_operands`,
        :meth:`reset_operands_unchecked`, :meth:`release_operands`, :meth:`free`,
        :class:`DirectSolverOptions`, :func:`direct_solver`.

    Examples:

        >>> import numpy as np
        >>> import nvmath.distributed
        >>> from nvmath.distributed.distribution import Slab
        >>> from nvmath.distributed.linalg import DirectSolver

        Get the process group used to initialize nvmath.distributed (for information on
        initializing ``nvmath.distributed``, you can refer to the documentation or to the
        direct solver examples in `nvmath/examples/distributed/linalg/generic/direct_solver
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/linalg/
        generic/direct_solver>`_):

        >>> process_group = nvmath.distributed.get_context().process_group

        Get my process rank and the total number of processes:

        >>> rank = process_group.rank
        >>> nranks = process_group.nranks

        We will solve the dense square system :math:`a @ x = b`, where :math:`a` has shape
        ``(n, n)`` and :math:`b` has shape ``(n, nrhs)``. Both operands use a
        :class:`~nvmath.distributed.distribution.Slab` distribution, so each process owns a
        contiguous block of rows of the global matrices.

        .. note::
            The :class:`~nvmath.distributed.distribution.Slab` distribution is used here
            for convenience of exposition and is not necessarily the most performant
            choice. For :math:`a`, a
            :class:`~nvmath.distributed.distribution.BlockCyclic` distribution is
            generally preferred, as it improves load balancing across processes.

        Create the local row slabs on the CPU (cuSOLVERMp requires column-major):

        >>> n, nrhs = 256, 8
        >>> local_n = n // nranks  # assume n is divisible by the process count
        >>> rng = np.random.default_rng(rank)
        >>> a = rng.random((local_n, n)).astype(np.float64, order="F")
        >>> b = rng.random((local_n, nrhs)).astype(np.float64, order="F")

        Make the global :math:`a` diagonally dominant so the system is well-conditioned.
        The diagonal entry ``a[i, i]`` of this rank's row band is at local position
        ``[k, rank * local_n + k]``:

        >>> idx = np.arange(local_n)
        >>> a[idx, rank * local_n + idx] += n

        Create a DirectSolver object encapsulating the problem specification above:

        >>> distributions = [Slab.X, Slab.X]
        >>> solver = DirectSolver(a, b, distributions=distributions)

        Options can be provided above to control the behavior of the operation using the
        `options` argument (see :class:`DirectSolverOptions`).

        Next, plan the operation:

        >>> solver.plan()

        Factorize the matrix, then solve the system.
        By default, the solution :math:`x` overwrites ``b`` and is returned:

        >>> solver.factorize()
        >>> x = solver.solve()

        Finally, free the object's resources. To avoid having to explicitly make this call,
        it's recommended to use the DirectSolver object as a context manager as shown below,
        if possible.

        >>> solver.free()

        A benefit of the stateful API is that an expensive factorization can
        be reused across multiple right-hand sides: factorize once, then solve
        repeatedly, resetting only ``b`` between solves.

        Further examples can be found in the
        `nvmath/examples/distributed/linalg/generic/direct_solver
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/linalg/
        generic/direct_solver>`_
        directory.
    """

    __slots__ = (
        # Immutable, cross-rank-consistent derived spec
        # see _ResolvedProblemSpec in _initialization.py
        "_spec",
        # Runtime / distributed context.
        "_runtime",
        # Lifecycle flags.
        "_valid_state",
        "_solver_planned",
        "_solver_factorized",
        "_operands_released",
        # cuSOLVERMp resources (flat here for now, but can
        # be refactored into a separate object in the future).
        "_cusolvermp_handle",
        "_cusolvermp_version",
        "_cusolvermp_grid_a",
        "_cusolvermp_grid_b",
        "_desc_a",
        "_desc_b",
        "_factorization_state",
        "_device_workspace",
        "_host_workspace",
        "_last_compute_event",
        "_local_ld_a",
        "_local_ld_b",
        # Operands' state (flat here for now, but can
        # be refactored into a separate object in the future).
        "_lhs_compute",
        "_rhs_compute",
        "_lhs_user",
        "_rhs_user",
        "_lhs_synced",
        "_rhs_synced",
        # Misc.
        "_options",
        "_logger",
    )

    # Type annotations for attributes assigned by the construction free
    # functions in ``_initialization.py``. mypy can't infer their types from a
    # call it can't see into, so we declare them here. (Attributes assigned
    # in-class by ``_init_defaults`` / ``__init__`` are inferred and omitted.)
    # The derived problem facts now live behind ``_spec``; only the runtime,
    # resource, and operand-state attributes set by free functions remain.
    _spec: _ResolvedProblemSpec
    _runtime: _RuntimeContext
    # Active operand buffers handed to getrf/getrs as ``data_ptr``, bound in
    # ``_resolve_active_operand_buffers`` from the wrapped user operands held in
    # ``_lhs_user`` / ``_rhs_user``: a device mirror when a mirror is needed, or
    # the user's GPU tensor itself on the cuda + inplace path. They don't exist
    # before that step. So ``_lhs_compute`` always refers to a real compute-space
    # buffer -- never a transient CPU operand.
    _lhs_compute: TensorHolder
    _rhs_compute: TensorHolder
    _local_ld_a: int
    _local_ld_b: int

    def _init_defaults(self) -> None:
        """
        Pre-initialize every slot that ``_release_internal_resources`` guards
        with ``if X is not None``.

        ``__init__``'s rollback path calls ``self._release_internal_resources``
        on any partial-construction failure, which then walks the resource
        slots below. The ``None`` defaults here are what makes that walk safe:
        without them the rollback itself would raise ``AttributeError`` due
        to ``__slots__``.

        Lifecycle flags also live here so the rollback path can read them
        (``_valid_state`` is set to ``True`` only at the end of ``__init__``,
        which is what makes ``free()`` idempotent across double-frees while
        still letting the rollback bypass the guard via the private helper).

        Note: this is placed *before* __init__ because mypy sees it first;
        subsequent assignments in ``__init__`` / workflow methods narrow each
        union to a concrete value.
        """
        # Lifecycle flags. _valid_state stays False until __init__ completes.
        self._valid_state: bool = False
        self._solver_planned: bool = False
        self._solver_factorized: bool = False
        self._operands_released: bool = False

        self._cusolvermp_handle: int | None = None
        # cuSOLVERMp library version set during __init__
        self._cusolvermp_version: int | None = None
        self._cusolvermp_grid_a: int | None = None
        self._cusolvermp_grid_b: int | None = None
        self._desc_a: int | None = None
        self._desc_b: int | None = None

        # Persistent device state (pivot vector + per-call info flags).
        self._factorization_state: _FactorizationState | None = None

        self._device_workspace: Workspace | None = None
        self._host_workspace: Workspace | None = None

        self._last_compute_event = None

        # User-side wrappers. ``_collective_problem_spec`` binds the wrapped user
        # operands here during construction; ``_resolve_active_operand_buffers``
        # then either keeps them (mirror case, where ``_lhs_compute`` /
        # ``_rhs_compute`` point at a mirror and the user wrapper is held here for
        # copy-back / ``release_operands``) or, for an operand that needs no
        # mirror (cuda + inplace), moves the wrapper into ``_lhs_compute`` /
        # ``_rhs_compute`` and resets the slot to None. So in steady state these
        # are non-None iff ``_spec.need_lhs_mirror`` / ``_spec.need_rhs_mirror``.
        # The None default also keeps the partial-init rollback safe.
        self._lhs_user: TensorHolder | None = None
        self._rhs_user: TensorHolder | None = None

        # Whether the rhs compute mirror currently holds a faithful copy of the
        # user's b (i.e. no refresh needed before getrs). True after the initial
        # staging copy and after reset_operands(b=...); set False once getrs
        # overwrites the mirror with x. Mirrors the non-distributed solver's
        # ``rhs_synced`` and lets solve() skip the H2D/D2D copy when the mirror
        # is already in sync (e.g. the first solve after construction/reset).
        self._rhs_synced: bool = True

        # Whether the lhs compute mirror currently holds a faithful copy of the
        # user's A (i.e. no refresh needed before getrf). True after the initial
        # staging copy and after reset_operands(a=...); set False once getrf
        # overwrites the mirror with the LU factors. Symmetric with
        # ``_rhs_synced``: lets factorize() skip the H2D/D2D copy when the mirror
        # is already in sync, and makes a repeated factorize() re-read the
        # pristine A rather than factorizing the previous LU.
        self._lhs_synced: bool = True

    def __init__(
        self,
        a: AnyTensor,
        b: AnyTensor,
        /,
        *,
        distributions: Sequence[Distribution],
        options: DirectSolverOptions | dict[str, Any] | None = None,
        stream: utils.AnyStream | int | None = None,
    ) -> None:
        # __init__ covers cuSOLVERMp workflow steps 1-4 (runtime/handle/grids/
        # descriptors) and creates the workspaces without allocating their
        # memory. The step implementations live in _initialization.py; see the
        # "cuSOLVERMp workflow -> code map" comment at module scope for how
        # every step maps onto this class and that module.

        # Default-initialize every slot so the rollback cleanup can work safely.
        self._init_defaults()

        self._options: DirectSolverOptions = utils.check_or_create_options(  # type: ignore[assignment]
            DirectSolverOptions, options, "Distributed direct solver options"
        )
        self._logger = self._options.logger if self._options.logger is not None else logging.getLogger()
        self._logger.info("= SPECIFICATION PHASE =")

        # ``options.blocking`` is accepted, but it is currently ignored:
        # factorize()/solve() always block.
        # This is the correct behavior anyway when blocking is True; when blocking
        # is "auto" (the default), always blocking is still a valid choice and
        # leaves room for forward compatibility once we implement non-blocking
        # execution for GPU operands.
        # TODO: use options.blocking and enable asynchronous execution.

        # Resolve the runtime context (verify the NCCL communicator and capture
        # rank/device). Kept OUTSIDE the try below because the rollback reads
        # _runtime.device_id.
        self._runtime = _resolve_runtime_context()

        try:
            # Run the cuSOLVERMp construction workflow.
            initialize_direct_solver(self, a, b, distributions=distributions, stream=stream)
        except BaseException:
            # Construction failed partway through; release whatever was already
            # built. We call _release_internal_resources() directly rather than
            # free() because _valid_state is still False, so free() would
            # short-circuit to a no-op. _release_internal_resources() tolerates
            # partial init: each resource is guarded by an is-not-None check.
            try:
                self._release_internal_resources()
            except Exception:
                self._logger.exception("DirectSolver: error during partial-init rollback")
            raise

        self._valid_state = True
        self._logger.info("The DirectSolver instance has been created.")

    def _create_compute_mirror(self, src: TensorHolder, stream_holder) -> TensorHolder:
        # Allocate a fresh execution-space mirror for ``src`` and copy its
        # data in. Two implementations behind a single signature:

        # * Cross-space (cpu operand, cuda execution): ``TensorHolder.to``
        #   handles the allocation and the H2D copy in one call.
        # * Same-space (cuda operand, cuda execution): we need a fresh
        #   same-device buffer with the same shape/dtype. Cannot reuse
        #   ``.to(self._runtime.device_id)`` here because
        #   ``CudaTensor.to(same_device)`` is a no-op that returns ``self``
        #   (see ``nvmath/internal/tensor_ifc_numpy.py``) -- it would
        #   alias the user's tensor instead of cloning it. Allocate via
        #   ``TensorHolder.empty`` and then ``copy_`` D2D.

        if self._spec.operands_memory_space == self._spec.execution_space:
            # Lay the mirror out densely in column-major order (LLD == local
            # rows) rather than mirroring ``src.strides``. The source may be a
            # slice of a larger buffer with a *padded* leading dimension
            # (strides[1] > shape[0]); such strides are not dense, and
            # ``TensorHolder.empty`` sizes its allocation for a dense layout
            # only -- handing it padded strides yields an undersized buffer
            # that cuSOLVERMp then overruns. cuSOLVERMp accepts any LLD >= the
            # local row count, so a tight mirror is both valid and sufficient;
            # ``copy_`` is a strided copy, so it reads the padded source
            # correctly regardless.
            dst = src.__class__.empty(
                shape=src.shape,
                device_id=self._runtime.device_id,
                dtype=src.dtype,
                strides=compute_f_strides(tuple(src.shape)),
                stream_holder=stream_holder,
            )
            dst.copy_(src, stream_holder=stream_holder)
            return dst
        return src.to(self._runtime.device_id, stream_holder)

    def _check_valid_solver(self, *args, **kwargs):
        if not self._valid_state:
            raise InvalidDirectSolverState("The DirectSolver object cannot be used after resources are freed")

    def _check_planned(self, *args, **kwargs):
        what = kwargs["what"]
        if not self._solver_planned:
            raise RuntimeError(f"{what} cannot be performed before plan() has been called.")

    def _check_factorized(self, *args, **kwargs):
        what = kwargs["what"]
        if not self._solver_factorized:
            raise RuntimeError(f"{what} cannot be performed before factorize() has been called.")

    def _check_valid_operands(self, *args, **kwargs):
        what = kwargs["what"]
        if self._operands_released:
            raise RuntimeError(
                f"{what} cannot be performed after the operands have been released. "
                f"Use reset_operands() to provide new operands before performing the {what.lower()}."
            )

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_valid_operands, "Planning")
    def plan(self, *, stream: utils.AnyStream | int | None = None) -> None:
        """
        Plan the distributed direct solver. This queries cuSOLVERMp for the host and device
        workspace sizes needed by the factorization and the solve, and sizes the solver's
        internal workspaces accordingly. Planning is idempotent, so calling it again after a
        successful plan is a no-op.

        Args:
            stream: {stream}

        .. seealso::
            :meth:`factorize`, :meth:`solve`.
        """
        # plan() is idempotent: re-entry after a successful plan is a
        # logged no-op so callers can stack plan() inside a setup helper
        # without tracking whether it has run before.
        if self._solver_planned:
            self._logger.info("Skipping planning since it has already been performed in a previous call.")
            return

        self._logger.info("= PLANNING PHASE =")

        stream_holder = utils.get_or_create_stream(self._runtime.device_id, stream, self._spec.stream_package)
        self._logger.info(f"The specified stream for DirectSolver.plan is {stream_holder.obj}.")

        # Device pointers to this rank's local tile of A, b, and the pivot
        a_data_ptr = self._lhs_compute.data_ptr
        b_data_ptr = self._rhs_compute.data_ptr
        ipiv_ptr = self._factorization_state.ipiv_device_ptr  # type: ignore[union-attr]

        with utils.device_ctx(self._runtime.device_id):
            # *_buffer_size queries launch no kernels, so the stream is unused
            # here; set for consistency with factorize()/solve().
            cusolverMp.set_stream(self._cusolvermp_handle, stream_holder.ptr)

            # https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpgetrf-buffersize
            getrf_device_bytes, getrf_host_bytes = cusolverMp.getrf_buffer_size(
                self._cusolvermp_handle,
                self._spec.global_m,
                self._spec.global_n,
                a_data_ptr,
                self._spec.ia,
                self._spec.ja,
                self._desc_a,
                ipiv_ptr,
                self._spec.solver_cuda_dtype,
            )

            # trans=N: cuSOLVERMp's getrs only supports non-transposed solves
            # against the LU factorization produced by getrf (in-place on A).
            # https://docs.nvidia.com/cuda/cusolvermp/usage/functions.html#cusolvermpgetrs-buffersize
            getrs_device_bytes, getrs_host_bytes = cusolverMp.getrs_buffer_size(
                self._cusolvermp_handle,
                cublas.Operation.N,
                self._spec.global_m,
                self._spec.nrhs,
                a_data_ptr,
                self._spec.ia,
                self._spec.ja,
                self._desc_a,
                ipiv_ptr,
                b_data_ptr,
                self._spec.ib,
                self._spec.jb,
                self._desc_b,
                self._spec.solver_cuda_dtype,
            )

        device_bytes = max(getrf_device_bytes, getrs_device_bytes)
        host_bytes = max(getrf_host_bytes, getrs_host_bytes)
        assert self._device_workspace is not None and self._host_workspace is not None, (
            "Workspace objects must be created before plan()."
        )
        self._device_workspace.set_size(device_bytes)
        self._host_workspace.set_size(host_bytes)

        self._logger.info(
            "Planned cuSOLVERMp workspaces: device=%d B, host=%d B "
            "(getrf needed device=%d/host=%d, getrs needed device=%d/host=%d).",
            device_bytes,
            host_bytes,
            getrf_device_bytes,
            getrf_host_bytes,
            getrs_device_bytes,
            getrs_host_bytes,
        )
        self._solver_planned = True

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_valid_operands, "Factorization")
    @utils.precondition(_check_planned, "Factorization")
    def factorize(self, *, stream: utils.AnyStream | int | None = None) -> None:
        """
        Factorize the matrix :math:`a` (LU factorization with partial pivoting).

        Each call factorizes the left-hand side ``a`` currently held by the solver.
        To change the left-hand side values between calls, call :meth:`reset_operands`
        (or :meth:`reset_operands_unchecked`) with the new ``a``. Alternatively, when
        ``inplace_a=True`` and ``a`` is accessible from the execution space, users
        may directly modify ``a`` in place, for example with ``a[:] = a_new``.
        In that case, users are responsible for ensuring that ``a`` contains the intended
        left-hand side values before each call, since :meth:`factorize` overwrites
        that operand with its LU factors.

        Args:
            stream: {stream}

        .. seealso::
            :meth:`plan`, :meth:`solve`, :meth:`reset_operands`.
        """

        self._logger.info("= FACTORIZATION PHASE =")

        stream_holder = utils.get_or_create_stream(self._runtime.device_id, stream, self._spec.stream_package)
        self._logger.info(f"The specified stream for DirectSolver.factorize is {stream_holder.obj}.")

        # Refresh the LHS compute mirror from the user's current A when it is no
        # longer in sync: getrf is destructive on the mirror, so once a prior
        # factorize has overwritten it with the LU we must re-read A before
        # factorizing again (this is also what makes an in-place edit to a mirrored
        # A visible to the next factorize() without an intervening reset_operands,
        # and keeps factorize(); factorize() re-factorizing the original A rather
        # than the previous LU). ``_lhs_synced`` lets us skip the copy when the
        # mirror is already current (e.g. the first factorize after
        # construction/reset). When there is no lhs mirror (gpu + inplace_a=True)
        # the user's A IS the live buffer and needs no refresh; need_lhs_mirror is
        # False there (and _lhs_user is None), so this block is skipped.
        if self._spec.need_lhs_mirror and not self._lhs_synced:
            assert self._lhs_user is not None, "lhs mirror expected but no user handle is held"
            if self._lhs_compute.tensor is None:
                self._lhs_compute = self._create_compute_mirror(self._lhs_user, stream_holder)
            else:
                self._lhs_compute.copy_(self._lhs_user, stream_holder=stream_holder)
            self._lhs_synced = True

        # narrow for mypy
        factorization_state = self._factorization_state
        device_workspace, host_workspace = self._device_workspace, self._host_workspace
        assert factorization_state is not None
        assert device_workspace is not None and host_workspace is not None

        # ``options.blocking`` is intentionally ignored here: getrf is
        # launched non-blocking and captures _last_compute_event for
        # stream ordering, then sync_and_check_factorize_info() below does
        # an unconditional blocking sync. factorize() therefore always
        # blocks regardless of options.blocking (see __init__ for context).
        # The non-blocking launch + event capture is kept for forward
        # compatibility: once we support non-blocking execution, honoring
        # options.blocking here becomes almost a matter of skipping that final sync.
        with (
            device_workspace.allocate_perhaps(
                stream_holder,
                get_last_event=lambda: self._last_compute_event,
            ) as device_wsp,
            host_workspace.allocate_perhaps(
                stream_holder,
                get_last_event=lambda: self._last_compute_event,
            ) as host_wsp,
            utils.cuda_call_ctx(stream_holder, blocking=False, timing=False) as (
                self._last_compute_event,
                _,
            ),
        ):
            cusolverMp.set_stream(self._cusolvermp_handle, stream_holder.ptr)

            cusolverMp.getrf(
                self._cusolvermp_handle,
                self._spec.global_m,
                self._spec.global_n,
                self._lhs_compute.data_ptr,
                self._spec.ia,
                self._spec.ja,
                self._desc_a,
                factorization_state.ipiv_device_ptr,
                self._spec.solver_cuda_dtype,
                device_wsp.raw_ptr,
                device_wsp.size,
                host_wsp.raw_ptr,
                host_wsp.size,
                factorization_state.info_getrf_device_ptr,
            )

        # getrf overwrote the compute buffer with the LU factors. Under a mirror
        # the buffer no longer matches the user's A, so mark it stale: the next
        # factorize() will refresh from _lhs_user first (matching solve()'s rhs
        # handling at the getrs site). With no mirror (gpu + inplace_a=True) the
        # user's A IS the buffer and freshness is user-managed, so it stays synced.
        self._lhs_synced = not self._spec.need_lhs_mirror

        # Unconditional, blocking sync + cross-rank info check; raises on
        # singular / illegal-argument.
        factorization_state.sync_and_check_factorize_info(
            stream_holder,
            nccl_comm=self._runtime.distributed_ctx.nccl_comm,
        )

        # inplace_a on a CPU operand: getrf ran on the GPU mirror, so copy the LU
        # back into the user's buffer. Done after the info check above so a
        # failed (e.g. singular) factorization leaves the user's A intact rather
        # than overwriting it with a partial LU.
        if self._spec.need_lhs_mirror and self._options.inplace_a:
            assert self._lhs_user is not None
            self._lhs_user.copy_(self._lhs_compute, stream_holder=stream_holder)

        self._solver_factorized = True
        self._logger.info("Factorization has been completed on rank %d.", self._runtime.rank)

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_valid_operands, "Solver Execution")
    @utils.precondition(_check_planned, "Solver Execution")
    @utils.precondition(_check_factorized, "Solver Execution")
    def solve(self, *, stream: utils.AnyStream | int | None = None) -> Any:
        """
        Solve the factorized system :math:`a @ x = b` for :math:`x` using the factors
        from the most recent :meth:`factorize` and the current right-hand side ``b``.

        Each call uses the right-hand side ``b`` currently held by the solver.
        To change the right-hand side values between calls, call :meth:`reset_operands`
        (or :meth:`reset_operands_unchecked`) with the new ``b``. Alternatively, when
        ``inplace_b=True`` and ``b`` is accessible from the execution space, users
        may directly modify ``b`` in place, for example with ``b[:] = b_new``.
        In that case, users are responsible for ensuring that ``b`` contains the
        intended right-hand side values before each call, since :meth:`solve`
        overwrites that operand with the solution.

        Args:
            stream: {stream}

        Returns:
            {result}

        .. seealso::
            :meth:`plan`, :meth:`factorize`, :meth:`reset_operands`.
        """
        self._logger.info("= SOLVER EXECUTION PHASE =")

        stream_holder = utils.get_or_create_stream(self._runtime.device_id, stream, self._spec.stream_package)
        self._logger.info(f"The specified stream for DirectSolver.solve is {stream_holder.obj}.")

        # Refresh the RHS compute mirror from the user's current b when it is no
        # longer in sync: getrs is destructive on the mirror, so once a prior
        # solve has dirtied it we must
        # re-read b before solving again (this is also what makes an in-place
        # edit to b visible to the next solve without an intervening
        # reset_operands). ``_rhs_synced`` lets us skip the copy when the mirror
        # is already current (e.g. the first solve after construction/reset).
        # Two sub-cases when a refresh is due:
        #   * tensor is None: the previous solve was cuda + inplace_b=False and
        #     handed the mirror buffer (holding x) to the caller, so allocate a
        #     fresh mirror from b. (release_operands() also nulls the slot, but
        #     _check_valid_operands has already rejected that path before here.)
        #   * tensor is live: copy b into the existing mirror (H2D for a cpu
        #     operand, D2D for a gpu operand).
        # When there is no rhs mirror (gpu + inplace_b=True) the user's b IS the
        # live buffer and needs no refresh; need_rhs_mirror is False there (and
        # _rhs_user is None), so this block is skipped.
        if self._spec.need_rhs_mirror and not self._rhs_synced:
            assert self._rhs_user is not None, "rhs mirror expected but no user handle is held"
            if self._rhs_compute.tensor is None:
                self._rhs_compute = self._create_compute_mirror(self._rhs_user, stream_holder)
            else:
                self._rhs_compute.copy_(self._rhs_user, stream_holder=stream_holder)
            self._rhs_synced = True

        # narrow for mypy
        factorization_state = self._factorization_state
        device_workspace, host_workspace = self._device_workspace, self._host_workspace
        assert factorization_state is not None
        assert device_workspace is not None and host_workspace is not None

        # ``blocking=False`` is intentional: solve() still always blocks now,
        # but the sync happens in the return-path dispatch below (see that
        # comment for the per-branch sync behavior). Blocking here too would
        # just force a redundant sync.
        with (
            device_workspace.allocate_perhaps(
                stream_holder,
                get_last_event=lambda: self._last_compute_event,
            ) as device_wsp,
            host_workspace.allocate_perhaps(
                stream_holder,
                get_last_event=lambda: self._last_compute_event,
            ) as host_wsp,
            utils.cuda_call_ctx(stream_holder, blocking=False, timing=False) as (
                self._last_compute_event,
                _,
            ),
        ):
            cusolverMp.set_stream(self._cusolvermp_handle, stream_holder.ptr)

            # cuSOLVERMp 0.8.0 does not internally zero
            # ``d_info`` at getrs entry: a successful call leaves
            # the buffer holding whatever it had on entry, while
            # only invalid-argument paths actually write a
            # negative info. Zero it ourselves so the post-call
            # value is deterministic (any future reader of getrs
            # info sees 0 on success). Newer versions are correct.
            if self._cusolvermp_version == 800:
                factorization_state.reset_info_getrs_device(stream_holder)

            cusolverMp.getrs(
                self._cusolvermp_handle,
                # trans=N: getrs only supports non-transposed
                cublas.Operation.N,
                self._spec.global_n,
                self._spec.nrhs,
                self._lhs_compute.data_ptr,
                self._spec.ia,
                self._spec.ja,
                self._desc_a,
                factorization_state.ipiv_device_ptr,
                self._rhs_compute.data_ptr,
                self._spec.ib,
                self._spec.jb,
                self._desc_b,
                self._spec.solver_cuda_dtype,
                device_wsp.raw_ptr,
                device_wsp.size,
                host_wsp.raw_ptr,
                host_wsp.size,
                factorization_state.info_getrs_device_ptr,
            )

        # getrs info is intentionally not checked: cuSOLVERMp's getrs only writes
        # info on an invalid argument (info < 0), which would indicate a bug
        # in the parameters we pass -- not a user error -- and would almost
        # certainly have been caught by getrf, whose arguments are mostly the same.
        # There is no info > 0 (singular) case for a triangular solve.

        # getrs just overwrote the rhs mirror with x (or, in the no-mirror
        # gpu + inplace_b=True case, the user's b in place). Mark the mirror
        # dirty so the next solve re-reads b first. The no-mirror case never
        # refreshes (guarded on need_rhs_mirror), so leaving it "synced" there
        # is harmless.
        self._rhs_synced = not self._spec.need_rhs_mirror

        # Return-path dispatch, outer branch on operand memory
        # space, inner branch on ``inplace_b``. The cpu arms always
        # stream-sync (D->H via ``ndbuffer.copy_into``); the cuda
        # arms leave the stream pending and sync at the end of their
        # branch (solve() always blocks).
        if self._spec.operands_memory_space == "cpu":
            # cpu: getrs wrote x into the solver's GPU mirror, so a
            # D->H copy is unavoidable on the way out. Both
            # sub-branches go through ``ndbuffer.copy_into``'s D->H
            # path, which stream-syncs internally -- the result is
            # host-visible by the time the call returns.
            assert self._rhs_user is not None
            if self._options.inplace_b:
                # Copy x back into the user's CPU b.
                self._rhs_user.copy_(self._rhs_compute, stream_holder=stream_holder)
                out = self._rhs_user.tensor
            else:
                # D2H into a fresh CPU tensor; keep the mirror as
                # solver-owned scratch for the next solve.
                out = self._rhs_compute.to("cpu", stream_holder).tensor
        else:
            # cuda: x already lives on the GPU; no D->H involved, so both
            # sub-branches leave stream work pending and we sync explicitly
            # (solve() always blocks). The cpu branch above needs no such
            # sync -- its D->H copy already blocks the host.
            if self._options.inplace_b:
                # No mirror was allocated -- ``_rhs_compute`` is
                # the user's b, getrs wrote x into it in place.
                # Hand it back as-is.
                out = self._rhs_compute.tensor
            else:
                # Hand the mirror buffer (now holding x) directly to the
                # caller, then null the slot so the solver no longer references it.
                # A subsequent solve()/reset_operands reallocates a fresh mirror.
                out = self._rhs_compute.tensor
                self._rhs_compute.tensor = None
            stream_holder.obj.sync()

        self._logger.info("Solver execution has been completed on rank %d.", self._runtime.rank)

        return out

    @utils.precondition(_check_valid_solver)
    def release_operands(self) -> None:
        """
        {release_operands}
        """
        if self._operands_released:
            self._logger.info("Operands have already been released; nothing to do.")
            return

        # Drop the active-buffer references. Under no-mirror operands
        # ``_lhs_compute`` / ``_rhs_compute`` alias the user's GPU
        # tensor; under any "has mirror" case they point at the internal
        # mirror. The slots themselves are guaranteed non-None here:
        # ``_resolve_active_operand_buffers`` sets them in ``__init__``, and
        # ``_check_valid_solver`` gates entry to this method on
        # ``_valid_state == True`` (set only at end-of-``__init__``).
        self._lhs_compute.tensor = None
        self._rhs_compute.tensor = None

        # Per-operand user-handle cleanup. ``_lhs_user`` / ``_rhs_user``
        # hold the user's tensor wrapper for the mirror case; null its
        # ``.tensor``. Each handle is non-None whenever the matching
        # ``_need_*_mirror`` is True (set when the mirror is allocated and
        # refreshed on reset_operands), so the asserts below always hold.
        if self._spec.need_lhs_mirror:
            assert self._lhs_user is not None
            self._lhs_user.tensor = None
        if self._spec.need_rhs_mirror:
            assert self._rhs_user is not None
            self._rhs_user.tensor = None

        self._operands_released = True
        self._logger.info("User-provided operands have been released.")

    def _reset_operands_impl(
        self,
        *,
        a_wrapped: TensorHolder | None,
        b_wrapped: TensorHolder | None,
        stream: utils.AnyStream | int | None,
    ) -> None:
        if not self._spec.need_lhs_mirror and not self._spec.need_rhs_mirror:
            # no mirror on either operand (cuda operands with
            # ``inplace_a=True`` and ``inplace_b=True``)
            if a_wrapped is not None:
                self._lhs_compute.tensor = a_wrapped.tensor
            if b_wrapped is not None:
                self._rhs_compute.tensor = b_wrapped.tensor

        elif self._spec.operands_memory_space == self._spec.execution_space:
            # At least one side has a mirror, but both live on the
            # execution device -- no H2D is needed
            self._reset_operands_same_space(a_wrapped=a_wrapped, b_wrapped=b_wrapped, stream=stream)

        else:
            # Cross-space (e.g. cpu operands, cuda execution): both
            # sides always have mirrors, the stream is always required
            # for the H2D copy.
            self._reset_operands_cross_space(a_wrapped=a_wrapped, b_wrapped=b_wrapped, stream=stream)

        if a_wrapped is not None:
            # New A means the cached LU is stale; force factorize() to
            # run before the next solve().
            self._solver_factorized = False

            # The mirror (or the live buffer, no-mirror case) now holds the
            # freshly pushed A, so the next factorize can skip the refresh copy.
            self._lhs_synced = True

        if b_wrapped is not None:
            # The mirror (or the live buffer, no-mirror case) now holds the
            # freshly pushed b, so the next solve can skip the refresh copy.
            self._rhs_synced = True

        self._operands_released = False

    def _reset_operands_same_space(
        self,
        *,
        a_wrapped: TensorHolder | None,
        b_wrapped: TensorHolder | None,
        stream: utils.AnyStream | int | None,
    ) -> None:
        # In this case, a side either has a same-device mirror (D2D copy needed)
        # or is pure-aliased. The stream is therefore
        # acquired lazily on the first mirror side we encounter.
        stream_holder = None
        for src, need_mirror, slot, user_slot_name in (
            (a_wrapped, self._spec.need_lhs_mirror, self._lhs_compute, "_lhs_user"),
            (b_wrapped, self._spec.need_rhs_mirror, self._rhs_compute, "_rhs_user"),
        ):
            if src is None:
                continue
            if not need_mirror:
                # cuda + inplace=True: alias the user's GPU tensor.
                slot.tensor = src.tensor
                continue
            if stream_holder is None:
                stream_holder = utils.get_or_create_stream(self._runtime.device_id, stream, self._spec.stream_package)
            if self._operands_released or slot.tensor is None:
                # No live mirror to copy into: either release_operands()
                # freed it, or a previous solve handed it to the user
                # (cuda + inplace_b=False). Allocate a fresh same-device
                # buffer and copy in.
                slot.tensor = self._create_compute_mirror(src, stream_holder).tensor
            else:
                slot.copy_(src, stream_holder=stream_holder)
            setattr(self, user_slot_name, src)

    def _reset_operands_cross_space(
        self,
        *,
        a_wrapped: TensorHolder | None,
        b_wrapped: TensorHolder | None,
        stream: utils.AnyStream | int | None,
    ) -> None:
        # Both sides always have a mirror (the user's bytes have to be
        # staged across address spaces), and the stream is unconditionally
        # needed for the H2D copy.

        stream_holder = utils.get_or_create_stream(self._runtime.device_id, stream, self._spec.stream_package)
        needs_fresh_mirror = self._operands_released
        if a_wrapped is not None:
            if needs_fresh_mirror:
                # release_operands() freed the previous mirror; allocate
                # a fresh execution-space buffer and H2D into it.
                self._lhs_compute = self._create_compute_mirror(a_wrapped, stream_holder)
            else:
                self._lhs_compute.copy_(a_wrapped, stream_holder=stream_holder)
            self._lhs_user = a_wrapped
        if b_wrapped is not None:
            if needs_fresh_mirror:
                self._rhs_compute = self._create_compute_mirror(b_wrapped, stream_holder)
            else:
                self._rhs_compute.copy_(b_wrapped, stream_holder=stream_holder)
            self._rhs_user = b_wrapped

    def reset_operands_unchecked(
        self,
        *,
        a: Any = None,
        b: Any = None,
        stream: utils.AnyStream | int | None = None,
    ) -> None:
        """
        {reset_operands_unchecked}
        """
        self._reset_operands_impl(
            a_wrapped=tensor_wrapper.wrap_operand(a) if a is not None else None,
            b_wrapped=tensor_wrapper.wrap_operand(b) if b is not None else None,
            stream=stream,
        )

    @utils.precondition(_check_valid_solver)
    def reset_operands(
        self,
        *,
        a: Any = None,
        b: Any = None,
        stream: utils.AnyStream | int | None = None,
    ) -> None:
        """
        Reset one or both operands held by this :class:`DirectSolver` instance.

        Args:
            a: New left-hand side, or ``None`` to keep the previous left-hand side.

            b: New right-hand side, or ``None`` to keep the previous right-hand side.

            stream: {stream}

        Semantics:
            - At least one operand is required (all of them after
              :meth:`release_operands`), otherwise a :class:`ValueError` is raised.

            - This method will perform various checks on the new operands to make sure:

              - The local shapes, strides, and datatypes match those of the old ones.
              - The packages that the operands belong to match those of the old ones.
              - The device must match that of the old ones.

            - The distribution of each operand is fixed at construction and cannot be
              changed by :meth:`reset_operands`; the new local shapes and strides need
              to be consistent with that distribution.

            - Resetting ``a`` invalidates the current factorization, so :meth:`factorize`
              must be called again before the next :meth:`solve`.

        .. seealso::
            :meth:`reset_operands_unchecked`, :meth:`release_operands`.
        """
        # if the operands have been released, both 'a' and 'b' must be provided
        if self._operands_released:
            if a is None or b is None:
                raise ValueError("After release_operands(), both 'a' and 'b' must be provided to reset_operands().")
        elif a is None and b is None:
            # All arguments are None: there is nothing to update, so reject the call.
            raise ValueError("reset_operands() requires at least one operand to be provided.")

        a_wrapped = tensor_wrapper.wrap_operand(a) if a is not None else None
        b_wrapped = tensor_wrapper.wrap_operand(b) if b is not None else None

        if a_wrapped is not None:
            self._spec.lhs_reset_invariants.check(a_wrapped)
        if b_wrapped is not None:
            self._spec.rhs_reset_invariants.check(b_wrapped)

        self._reset_operands_impl(a_wrapped=a_wrapped, b_wrapped=b_wrapped, stream=stream)

        if a_wrapped is not None:
            self._logger.info("User-provided lhs/a has been reset on rank %d.", self._runtime.rank)
        if b_wrapped is not None:
            self._logger.info("User-provided rhs/b has been reset on rank %d.", self._runtime.rank)

    def _release_internal_resources(self) -> None:
        """
        (private) Resource cleanup. Safe on partial init and on
        repeat calls; the user-facing :meth:`free` wraps this with the
        ``_valid_state`` short-circuit.

        NCCL communicator teardown is intentionally NOT done
        here because the comm is owned by ``nvmath.distributed`` and
        outlives individual solver instances.
        """
        if self._device_workspace is not None:
            self._device_workspace.release(self._last_compute_event)
            self._device_workspace = None
        if self._host_workspace is not None:
            self._host_workspace.release(self._last_compute_event)
            self._host_workspace = None

        # Release the persistent factorization buffers, ordering their
        # stream-ordered free after the last compute event (mirrors the
        # workspace release above) so teardown stays safe even if execution
        # ever goes non-blocking. Done before nulling _last_compute_event.
        if self._factorization_state is not None:
            self._factorization_state.free(self._last_compute_event)
            self._factorization_state = None

        self._last_compute_event = None

        # Matrix descriptors then grids then handles. ``_runtime`` is set before
        # the construction try, so it's present on any rollback; getattr keeps
        # this defensive if cleanup ever runs before it was assigned.
        runtime = getattr(self, "_runtime", None)
        if runtime is not None:
            with utils.device_ctx(runtime.device_id):
                if self._desc_b is not None:
                    cusolverMp.destroy_matrix_desc(self._desc_b)
                    self._desc_b = None
                if self._desc_a is not None:
                    cusolverMp.destroy_matrix_desc(self._desc_a)
                    self._desc_a = None
                if self._cusolvermp_grid_b is not None:
                    cusolverMp.destroy_grid(self._cusolvermp_grid_b)
                    self._cusolvermp_grid_b = None
                if self._cusolvermp_grid_a is not None:
                    cusolverMp.destroy_grid(self._cusolvermp_grid_a)
                    self._cusolvermp_grid_a = None
                # Handle is either user-supplied (user-owned) or cached
                # (owned by ``_caching`` and cleared in ``finalize()``).
                # The instance never destroys it.
                self._cusolvermp_handle = None

        # Drop refs to every remaining slot. Skip ``_logger`` so the
        # "released" log line in free() still works; skip the lifecycle
        # flags (_valid_state and the _check_* gates: _solver_planned,
        # _solver_factorized, _operands_released) so post-free
        # preconditions still see the right values.
        _keep = {
            "_logger",
            "_valid_state",
            "_solver_planned",
            "_solver_factorized",
            "_operands_released",
        }
        for attr in self.__slots__:
            if attr not in _keep:
                setattr(self, attr, None)

    def free(self) -> None:
        """
        Free the :class:`DirectSolver` resources.

        It is recommended that the :class:`DirectSolver` object be used within a context
        manager, but if that is not possible this method must be called explicitly to ensure
        the solver's resources are properly cleaned up.
        """
        # Idempotent
        if not self._valid_state:
            return

        try:
            self._release_internal_resources()
        except Exception:
            self._logger.critical(
                "Internal error: only part of the DirectSolver object's resources have been released.",
            )
            raise
        finally:
            self._valid_state = False

        self._logger.info("The DirectSolver object's resources have been released.")

    def __enter__(self) -> DirectSolver:
        """Enter the context manager, returning this :class:`DirectSolver` instance."""
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        """Exit the context manager, releasing the solver's resources via :meth:`free`."""
        self.free()


@utils.docstring_decorator(GENERIC_DIRECT_SOLVER_DOCUMENTATION, skip_missing=False)
def direct_solver(
    a: AnyTensor,
    b: AnyTensor,
    /,
    *,
    distributions: Sequence[Distribution],
    options: DirectSolverOptions | dict[str, Any] | None = None,
    stream: utils.AnyStream | int | None = None,
) -> Any:
    """
    Solve the distributed dense linear system :math:`a @ x = b` for :math:`x`. This
    function-form API is a convenience wrapper around the stateful :class:`DirectSolver`
    object and is meant for *single* use (the user needs to perform just one solve, for
    example).

    Args:
        a: {a}

        b: {b}

        distributions: {distributions}

        options: {options}

        stream: {stream}

    Returns:
        {result}

    Semantics:
        {semantics}

    Requirements:
        {requirements}

    .. seealso::
        :class:`DirectSolver`, :class:`DirectSolverOptions`.

    Examples:

        >>> import numpy as np
        >>> import nvmath.distributed
        >>> from nvmath.distributed.distribution import Slab
        >>> from nvmath.distributed.linalg import direct_solver

        Get the process group used to initialize nvmath.distributed (for information on
        initializing ``nvmath.distributed``, you can refer to the documentation or to the
        direct solver examples in `nvmath/examples/distributed/linalg/generic/direct_solver
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/linalg/
        generic/direct_solver>`_):

        >>> process_group = nvmath.distributed.get_context().process_group

        Get my process rank and the total number of processes:

        >>> rank = process_group.rank
        >>> nranks = process_group.nranks

        We will solve the dense square system :math:`a @ x = b`, where :math:`a` has shape
        ``(n, n)`` and :math:`b` has shape ``(n, nrhs)``. Both operands use a
        :class:`~nvmath.distributed.distribution.Slab` distribution, so each process owns a
        contiguous block of rows of the global matrices (chosen here for convenience of
        exposition; a :class:`~nvmath.distributed.distribution.BlockCyclic` distribution is
        generally preferred for :math:`a`, as it improves load balancing across processes).

        Create the local row slabs on the CPU (cuSOLVERMp requires column-major), and make
        the global :math:`a` diagonally dominant so the system is well-conditioned. The
        diagonal entry ``a[i, i]`` of this rank's row band is at local position
        ``[k, rank * local_n + k]``:

        >>> n, nrhs = 256, 8
        >>> local_n = n // nranks  # assume n is divisible by the process count
        >>> rng = np.random.default_rng(rank)
        >>> a = rng.random((local_n, n)).astype(np.float64, order="F")
        >>> b = rng.random((local_n, nrhs)).astype(np.float64, order="F")
        >>> idx = np.arange(local_n)
        >>> a[idx, rank * local_n + idx] += n

        Solve the system with a single call to :func:`direct_solver`. By default the
        solution :math:`x` overwrites ``b`` in place and is returned, so ``x`` is a NumPy
        ndarray with the same distribution and local shape as ``b``:

        >>> distributions = [Slab.X, Slab.X]
        >>> x = direct_solver(a, b, distributions=distributions)
        >>> assert x is b

        Options can be provided to control the behavior of the operation using the
        ``options`` argument (see :class:`DirectSolverOptions`).

    Notes:
        - This function is a convenience wrapper around :class:`DirectSolver` and is
          specifically meant for *single* use. To amortize the cost of the factorization
          across multiple right-hand sides, use the stateful :class:`DirectSolver` API.

    Further examples can be found in the
    `nvmath/examples/distributed/linalg/generic/direct_solver
    <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/linalg/
    generic/direct_solver>`_
    directory.
    """
    with DirectSolver(a, b, distributions=distributions, options=options, stream=stream) as solver:
        solver.plan(stream=stream)
        solver.factorize(stream=stream)
        return solver.solve(stream=stream)
