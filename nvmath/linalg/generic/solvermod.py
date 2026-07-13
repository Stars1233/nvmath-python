# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0


__all__ = ("DirectSolver", "direct_solver", "InvalidDirectSolverState", "DirectSolverOptions")


import itertools
import logging
from collections.abc import Callable, Sequence
from typing import Any, TypeAlias

import numpy as np

from nvmath import memory
from nvmath._internal.workspace import Workspace, get_pinned_memory_resource
from nvmath.bindings import cublas, cusolverDn
from nvmath.internal import tensor_wrapper, typemaps, utils
from nvmath.internal.tensor_ifc_numpy import NumpyTensor
from nvmath.linalg._internal import solver_utils
from nvmath.linalg._internal.solver_utils import SolverBackend
from nvmath.linalg._internal.utils import get_handle
from nvmath.linalg.generic import ExecutionCUDA
from nvmath.linalg.generic._configuration.solver_configuration import DirectSolverOptions

AnyTensor: TypeAlias = tensor_wrapper.AnyTensor


# Shared doc fragments for the dense direct linear solver public API.
GENERIC_DIRECT_SOLVER_DOCUMENTATION: dict = utils.COMMON_SHARED_DOC_MAP.copy()
GENERIC_DIRECT_SOLVER_DOCUMENTATION.update(
    {
        "a": r"""\
The dense operand (or sequence of operands) representing the left-hand side (LHS) of the system
of equations: a square matrix ``a`` (or batch of square ``(n, n)`` matrices) for ``a @ x = b``.
The LHS may be a (sequence of) :class:`numpy.ndarray`, :class:`cupy.ndarray`, and
:class:`torch.Tensor`. For *batched* input, ``a`` can also be a single tensor of shape
``(*batch_shape, n, n)`` (implicit batching) or a :class:`list` or :class:`tuple` of matrices of
the *same* shape. Refer to the **Semantics** section for details.\
""".replace("\n", " "),
        "b": r"""\
The ndarray/tensor or (sequence of ndarray/tensors) representing the dense right-hand side (RHS) of
the system of equations. The RHS operand may be a (sequence of) :class:`numpy.ndarray`,
:class:`cupy.ndarray`, and :class:`torch.Tensor`. Unbatched shapes are ``(n,)`` or ``(n, nrhs)``;
with batching parallel to ``a``, use a :class:`list` / :class:`tuple` of 1D/2D arrays (explicit) or a
single tensor ``(*batch_shape, n, nrhs)`` (implicit). The package and device must match ``a``. Refer
to the **Semantics** section for details.\
""".replace("\n", " "),
        "options": r"""\
Specify options for the direct linear solver as a :class:`DirectSolverOptions` object. Alternatively, a
`dict` containing the parameters for the ``DirectSolverOptions`` constructor can also be
provided. If not specified, the value will be set to the default-constructed ``DirectSolverOptions``
object.\
""".replace("\n", " "),
        "execution": r"""\
Specify execution space options for the direct solver as an :class:`ExecutionCUDA` object. Alternatively, a
string (``"cuda"``) or a ``dict`` with a ``"name"`` of ``"cuda"`` and optional
``device_id`` relevant to the given execution space. The default execution space is ``"cuda"`` and the
corresponding :class:`ExecutionCUDA` will be default-constructed on device 0. CPU operands are executed
on the selected CUDA device as needed.\
""".replace("\n", " "),
        "result": r"""\
The result of the specified direct linear solve, ``x``, which has the same batching structure
as the RHS ``b`` (a single array/tensor, or a sequence of ndarray/tensors, each the same shape as
the corresponding tensor in ``b``), a dtype matching ``a`` and ``b``, and device and package
placement consistent with the chosen execution and operands.\
""".replace("\n", " "),
        "semantics": r"""\
        The dense direct linear solver solves :math:`a @ x = b` for ``x`` given the left-hand side
        (LHS) ``a`` and the right-hand side (RHS) ``b`` (square dense :math:`a`, dense ``b``), using
        an LU factorization and triangular solves on the target device.

        * **Non-batched:** ``a`` is a square ``(n, n)`` matrix; ``b`` is a vector
          ``(n,)`` or a matrix ``(n, nrhs)`` (one or more right-hand sides). The
          solve runs on the selected CUDA device using **cuSOLVER**.

        * **Batched** (explicit or implicit): the solve uses **cuBLAS** batched
          APIs, so in one call every batch entry shares the *same* system
          size :math:`n` (all ``(n, n)`` ``a``). For ``b``, explicit batching
          uses per-item shapes ``(n,)`` or ``(n, m)``; implicit batching
          uses ``(*batch_shape, n, nrhs)``. If ``a`` and ``b`` are implicitly batched, they
          must share the same leading ``batch_shape`` where applicable. The LHS
          and RHS batching forms may differ (for example, a sequence of ``a``
          with an implicitly batched ``b``, or the reverse) as long as the number
          of batch entries is the same for ``a`` and ``b``.

        .. seealso:: :class:`nvmath.sparse.advanced.DirectSolver` for
           :math:`a` as a **sparse** CSR matrix (a different feature set and
           backend).
""".strip(),
        "direct_solver_note": r""".. note::

        - Currently supported dtypes are: ``float32``, ``float64``, ``complex64``,
          ``complex128`` for both ``a`` and ``b``.
        - If users provide ``options.handle``, it is used only for non-batched
          execution (cuSOLVER path). In batched execution (cuBLAS path), the
          provided handle is ignored and an internal cached cuBLAS handle is used.
        - When ``inplace_a=True`` or ``inplace_b=True`` for batched execution,
          users are responsible for ensuring that the LHS and RHS batch entries do
          not overlap in memory.
""",
        "reset_operands_inplace_note": r""".. note::

            When ``inplace_a=True`` or ``inplace_b=True`` and the input operands
            reside on the GPU, replacement operands must have the same layout as the
            original operands. CPU operands are copied through internal GPU buffers, so
            this layout restriction does not apply to CPU inputs.""",
    }
)
GENERIC_DIRECT_SOLVER_DOCUMENTATION["release_operands"] = utils._release_operand_docstring(
    True, version_added=None, execution_methods=("factorize", "solve")
)


class InvalidDirectSolverState(Exception):
    """
    Raised when a :class:`DirectSolver` instance (or a method on it) is used after
    :meth:`DirectSolver.free` has run and resources are invalid.
    """


@utils.docstring_decorator(GENERIC_DIRECT_SOLVER_DOCUMENTATION, skip_missing=False)
class DirectSolver:
    r"""
    Create a stateful object that encapsulates the specified dense direct linear solver
    computations and required resources. This object ensures the validity of resources during
    use and releases them when they are no longer needed to prevent misuse.

    This object encompasses all functionality of the function-form API
    :func:`~nvmath.linalg.direct_solver`, which is a
    convenience wrapper around it. The stateful object also allows amortization of preparatory
    costs (for example :meth:`plan` and an LU :meth:`factorize`) when the same size and layout
    are reused, including after :meth:`reset_operands` to update ``a``/``b``.

    Using the stateful object typically involves the following steps:

    1. **Problem specification**: Initialize the object with ``a``, ``b``, and optional
       ``options`` / ``execution`` / ``stream``.
    2. **Preparation**: :meth:`plan` in preparation for factorization (see **Semantics**).
    3. **Execution**: :meth:`factorize`, then :meth:`solve` to obtain ``x`` (or :meth:`solve`
       again with the same ``a`` and an updated ``b`` after :meth:`reset_operands` when the
       matrix or RHS values change without recreating the solver).
    4. **Resource management**: Release resources with :meth:`free` or by using a ``with`` block.

    More detail on what each phase is doing (planning, factorization, and solve) can be
    seen in the logs by passing a :class:`logging.Logger` in :class:`DirectSolverOptions`,
    or by configuring the root logger that :class:`DirectSolverOptions` uses by default, for
    example:

    >>> import logging
    >>> logging.basicConfig(
    ...     level=logging.INFO,
    ...     format="%(asctime)s %(levelname)-8s %(message)s",
    ...     datefmt="%m-%d %H:%M:%S",
    ... )

    Args:
        a: {a}
        b: {b}
        options: {options}
        execution: {execution}
        stream: {stream}

    Semantics:
        {semantics}

    {direct_solver_note}

    .. seealso:: :func:`~nvmath.linalg.direct_solver`, :class:`DirectSolverOptions`, :class:`ExecutionCUDA`, and
        :class:`nvmath.sparse.advanced.DirectSolver` (sparse ``a``).

    Examples:

        Non-batched :class:`numpy.ndarray` operands: build a well-conditioned
        :math:`n \times n` system and solve with :meth:`plan`, :meth:`factorize`, and
        :meth:`solve` inside a context manager so that :meth:`free` is called
        automatically:

        >>> import numpy as np
        >>> import nvmath.linalg as la
        >>>
        >>> n = 4
        >>> rng = np.random.default_rng(0)
        >>> a = rng.standard_normal((n, n), dtype=np.float64)
        >>> a = a + n * np.eye(n, dtype=np.float64)
        >>> b = np.ones(n, dtype=np.float64)
        >>>
        >>> with la.DirectSolver(a, b) as solver:
        ...     solver.plan()
        ...     solver.factorize()
        ...     x = solver.solve()
        >>> x.shape
        (4,)

        The same call pattern applies to :class:`cupy.ndarray` and
        :class:`torch.Tensor` on the default CUDA device when the operands
        already live on the GPU, and to batching; see **Semantics** and the
        example-tree link below. Further worked examples (implicit batching,
        :meth:`reset_operands`, streams) are in
        `generic direct solver examples
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/linalg/generic/direct_solver>`_
        on GitHub.

    """  # noqa: W505

    def __init__(
        self,
        a: AnyTensor,
        b: AnyTensor,
        options: DirectSolverOptions | dict[str, Any] | None = None,
        execution: ExecutionCUDA | str | dict[str, Any] | None = None,
        stream: utils.AnyStream | int | None = None,
    ):
        # Process options.
        self.options: DirectSolverOptions = utils.check_or_create_options(
            DirectSolverOptions, options, "direct linear solver options"
        )  # type: ignore[assignment]
        self.inplace_a = self.options.inplace_a
        self.inplace_b = self.options.inplace_b

        # Process execution options. The default execution space is CUDA.
        self.execution_options = utils.check_or_create_one_of_options(
            (ExecutionCUDA,), execution, "execution options", default_name="cuda"
        )

        self.logger = self.options.logger if self.options.logger is not None else logging.getLogger()
        self.logger.info("= SPECIFICATION PHASE =")

        # Wrap operands, check dtypes/devices, and validate LHS/RHS batching consistency.
        (
            self.lhs_backup,
            self.lhs_batch_info,
            self.rhs_backup,
            self.rhs_batch_info,
            self.n,
            self.nrhs,
            self.package,
            self.input_device_id,
            self.dtype_name,
            lhs_layout,
            rhs_layout,
        ) = solver_utils.parse_solver_operands(
            a,
            b,
            check_inplace_a_layout=self.inplace_a,
            check_inplace_b_layout=self.inplace_b,
        )
        # LHS/RHS batching consistency is already validated in parse_solver_operands.
        # Use LHS metadata for batched flag and batch_count.
        self.batched = self.lhs_batch_info.explicitly_batched or self.lhs_batch_info.implicitly_batched
        self.batch_count = self.lhs_batch_info.batch_count
        self.cuda_dtype = typemaps.NAME_TO_DATA_TYPE[self.dtype_name]

        # Backend:
        #   non-batched → cuSOLVER:
        #     - lhs/a: (n, n); rhs/b: (n,) or (n, nrhs)
        #   batched → cuBLAS *Batched APIs
        #     - Explicit batching:
        #         - lhs/a: list/tuple of (n, n);
        #           rhs/b: list/tuple of (n,) or (n, nrhs)
        #     - Implicit batching:
        #         - lhs/a: (*batch_shape, n, n);
        #           rhs/b: (*batch_shape, n, nrhs)
        if not self.batched:
            self.backend = SolverBackend.CUSOLVER
            self.logger.info("For non-batched input, execution will be performed using cusolver library.")
        else:
            self.backend = SolverBackend.CUBLAS
            self.logger.info("For batched input, execution will be performed using cublas library.")

        # Determine the stream package for the execution space.
        self.stream_package = "cuda" if self.package == "numpy" else self.package

        self.memory_space = solver_utils.get_single_or_sequence_attr(self.lhs_backup, "device")
        if self.memory_space == "cuda":
            # When the operands are on device,
            # we respect the device id of the operands over execution options.
            self.execution_device = solver_utils.get_single_or_sequence_attr(self.lhs_backup, "device_id")
            self.copy_across_memspace = False
        else:
            # When the operands are on CPU,
            # we use the device id from execution options.
            self.execution_device = self.execution_options.device_id
            self.copy_across_memspace = True
        self.input_operand_class = solver_utils.get_single_or_sequence_attr(self.lhs_backup, "__class__")
        if self.copy_across_memspace and self.package == "numpy":
            self.internal_operand_class = self.input_operand_class.device_tensor_class
        else:
            self.internal_operand_class = self.input_operand_class

        # Get the wrapped input shapes:
        #   - For explicit batching, this represents the per-batch shapes.
        #   - For implicit batching or non-batched, this represents the full tensor shape.
        self.lhs_shape = solver_utils.get_single_or_sequence_attr(self.lhs_backup, "shape")  # type: ignore[assignment]
        self.rhs_shape = solver_utils.get_single_or_sequence_attr(self.rhs_backup, "shape")  # type: ignore[assignment]

        if self.logger.isEnabledFor(logging.INFO):
            if self.batched:
                self.logger.info("Batched problem specification:")
                self.logger.info(f"  dtype: {self.dtype_name}")
                self.logger.info(f"  lhs shape(s): {self.lhs_shape!r}")
                self.logger.info(f"  rhs shape(s): {self.rhs_shape!r}")
                self.logger.info(f"  lhs batching: {self.lhs_batch_info}")
                self.logger.info(f"  rhs batching: {self.rhs_batch_info}")
            else:
                self.logger.info("Non-batched problem specification:")
                self.logger.info(f"  dtype: {self.dtype_name}")
                self.logger.info(f"  lhs shape(s): {self.lhs_shape!r}")
                self.logger.info(f"  rhs shape(s): {self.rhs_shape!r}")

        # lhs_backup/rhs_backup wrap the user operands and keep them available for
        # reset/retry flows when their inplace option is False.
        # lhs/rhs are internal execution buffers otherwise.
        stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)

        # Keep track of the lhs/rhs allocation streams to ensure
        # proper ordering in free() and release_operands().
        self.input_lhs_layout = lhs_layout
        self.input_rhs_layout = rhs_layout

        if self.inplace_a and not self.copy_across_memspace:
            if lhs_layout is None:
                raise RuntimeError("Internal error: inplace_a LHS layout was not computed.")
            self.lhs = self.lhs_backup
            self.lhs_backup = None
            self.lhs_mirror_stream = None
            self.lhs_layout = lhs_layout
        else:
            self.lhs = self._create_empty_lhs(stream_holder)
            solver_utils.copy_operands(self.lhs, self.lhs_backup, stream_holder)
            self.lhs_layout = solver_utils.LHSLayout("F", self.n)
            self.logger.debug("lhs/a has been copied to the execution space for the linear solver...")
        # GETRF always factorizes the column-major view of lhs. For C-order input
        # that view is A.T, so GETRS uses op=T to solve against the original A.
        self.getrs_operation = cublas.Operation.N if self.lhs_layout.order == "F" else cublas.Operation.T
        # Whether the execution LHS buffer contains the same values as the source LHS.
        # For device-resident inplace_a, these are the same allocation, so this remains True
        # and freshness is user-managed.
        self.lhs_synced = True

        if self.inplace_b and not self.copy_across_memspace:
            if rhs_layout is None:
                raise RuntimeError("Internal error: inplace_b RHS layout was not computed.")
            self.rhs = self.rhs_backup
            self.rhs_backup = None
            self.rhs_mirror_stream = None
            self.rhs_layout = rhs_layout
        else:
            self.rhs = self._create_empty_rhs(stream_holder)
            solver_utils.copy_operands(self.rhs, self.rhs_backup, stream_holder)
            self.rhs_layout = solver_utils.get_rhs_layout(self.rhs, self.nrhs, check_inplace_compatible_strides=False)
        # Whether the execution RHS buffer contains the same values as the source RHS.
        # For device-resident inplace_b, these are the same allocation, so this remains True
        # and freshness is user-managed.
        self.rhs_synced = True
        self.logger.debug("rhs/b has been copied to the execution space for the linear solver...")

        # Solver library resources (non-batched → cuSOLVER; batched → cuBLAS batched).
        # Typical buffer shapes (batch_count is 1 for non-batched):
        #
        #   Resource       | cuSOLVER                 | cuBLAS
        #   ---------------+--------------------------+----------------------------------
        #   handle         | yes if not provided      | yes (cached) if not provided
        #   params         | yes                      | no
        #   getrf_info     | (1,) int32               | (batch_count,) int32
        #   getrs_info     | (1,) int32               | no
        #   pivot buffer   | (n,) int64               | (batch_count, n) int32
        #   lhs_pointers   | no                       | (batch_count,) uint64
        #   rhs_pointers   | no                       | (batch_count,) uint64
        #

        # getrf_info_host.tensor must be an ndarray where we can inspect the info values.
        self.getrf_info_host = utils.create_empty_tensor(NumpyTensor, (self.batch_count,), "int32", "cpu", None, False)
        self.getrf_info_device = self.getrf_info_host.to(self.execution_device, stream_holder)
        self.logger.debug("Allocating info in the execution space for the linear solver factorization...")

        if self.backend == SolverBackend.CUSOLVER:
            if self.options.handle is None:
                with utils.device_ctx(self.execution_device):
                    self.handle = cusolverDn.create()
                    self.own_handle = True
                    self.logger.info("A cusolverDn handle has been created.")
            else:
                self.handle = self.options.handle
                self.own_handle = False
            self.params = cusolverDn.create_params()
            self.logger.info("A cusolverDn params object has been created.")

            self.pivot = self._create_internal_operand((self.n,), "int64", stream_holder)
            self.lhs_pointers = None
            self.rhs_pointers = None
        else:
            # When execution is dispatched to cuBLAS, the provided handle is ignored
            # and a cuBLAS handle will be created.
            if self.options.handle is not None:
                self.logger.info("Execution will be performed with cuBLAS, the provided handle is ignored.")

            # get the cached cublas handle
            self.handle = get_handle(self.execution_device, binding="cublas")
            self.logger.info("A cublas handle has been created.")

            # cublas does not require params
            self.params = None
            self.own_handle = False

            self.pivot = self._create_internal_operand((self.batch_count, self.n), "int32", stream_holder)

            # Per-batch device pointers for cuBLAS *Batched: explicit batching gathers
            # data_ptr from each wrapped tensor; implicit batching uses batch_indices on
            # one strided tensor.
            if self.lhs_batch_info.implicitly_batched:
                self.lhs_batch_indices = tuple(itertools.product(*list(map(range, self.lhs_batch_info.batch_shape))))  # type: ignore[assignment]
            else:
                self.lhs_batch_indices = None  # type: ignore[assignment]
            self.lhs_pointers = solver_utils.get_operands_ptr_array(self.lhs, self.lhs_batch_indices).to(
                device_id=self.execution_device, stream_holder=stream_holder
            )
            if self.rhs_batch_info.implicitly_batched:
                self.rhs_batch_indices = tuple(itertools.product(*list(map(range, self.rhs_batch_info.batch_shape))))  # type: ignore[assignment]
            else:
                self.rhs_batch_indices = None  # type: ignore[assignment]
            self.rhs_pointers = solver_utils.get_operands_ptr_array(self.rhs, self.rhs_batch_indices).to(
                device_id=self.execution_device, stream_holder=stream_holder
            )

        # Stream used when allocating handles/pointers above; free() may wait on it.
        self.resource_alloc_stream = stream_holder.obj

        self.solver_planned = False
        self.solver_factorized = False
        # Last GPU event from factorize/solve; free() waits so teardown cannot race kernels.
        self.last_compute_event = None

        self._operands_released = False

        # DirectSolver always synchronizes so factorization info can be inspected safely.
        # TODO: enable asynchronous execution
        self.blocking = True
        self.call_prologue = "This call is blocking and will return only after the operation is complete."

        # Set memory allocator.
        self.allocator = (
            self.options.allocator
            if self.options.allocator is not None
            else memory._MEMORY_MANAGER[self.stream_package](self.execution_device, self.logger)
        )

        # resolution deferred until plan() is called
        self._getrf_func: Callable | None = None
        self._getrs_func: Callable | None = None

        # Workspace lifecycle is managed by `Workspace` (allocate-on-demand,
        # reuse, exception cleanup, stream-ordered free).
        self.device_workspace = Workspace(
            self.allocator,
            self.logger,
            label="device workspace",
            device_id=self.execution_device,
        )
        # cuSOLVER getrf may use host workspace during factorization. Use pinned
        # host memory so Workspace can order its lifetime on the compute stream.
        # Prefer PinnedMemoryResource when runtime support is available; otherwise
        # fall back to synchronous LegacyPinnedMemoryResource.
        host_mr = get_pinned_memory_resource(self.execution_device)
        self.host_workspace = Workspace(host_mr, device_id=self.execution_device, logger=self.logger, label="host workspace")

        self.valid_state = True
        self.logger.info("The DirectSolver operation has been created.")

    def _check_valid_solver(self, *args, **kwargs):
        """
        Check if the DirectSolver object is alive and well.
        """
        if not self.valid_state:
            raise InvalidDirectSolverState("The DirectSolver object cannot be used after resources are free'd")

    def _check_planned(self, *args, **kwargs):
        what = kwargs["what"]
        if not self.solver_planned:
            raise RuntimeError(f"{what} cannot be performed before plan() has been called.")

    def _check_factorized(self, *args, **kwargs):
        what = kwargs["what"]
        if not self.solver_factorized:
            raise RuntimeError(f"{what} cannot be performed before factorize() has been called.")

    def _check_valid_operands(self, *args, **kwargs):
        """
        Check if the operands are available for the operation.
        """
        what = kwargs["what"]
        if self._operands_released:
            raise RuntimeError(
                f"{what} cannot be performed after the operands have been released. "
                f"Use reset_operands() to provide new operands before performing the {what.lower()}."
            )

    def _check_lhs_layout(self, lhs_layout):
        expected_layout = self.input_lhs_layout if self.copy_across_memspace and self.inplace_a else self.lhs_layout
        if lhs_layout != expected_layout:
            raise ValueError(
                f"The layout of 'a' ({lhs_layout}) must match the original layout ({expected_layout}) when inplace_a is True."
            )

    def _check_rhs_layout(self, rhs_layout):
        expected_layout = self.input_rhs_layout if self.copy_across_memspace and self.inplace_b else self.rhs_layout
        if rhs_layout != expected_layout:
            raise ValueError(
                f"The layout of 'b' ({rhs_layout}) must match the original layout ({expected_layout}) when inplace_b is True."
            )

    @utils.precondition(_check_valid_solver)
    def release_operands(self):
        """
        {release_operands}
        """
        if self._operands_released:
            self.logger.info("Operands have already been released; nothing to do.")
            return

        if self.lhs_mirror_stream is not None:
            self.lhs_mirror_stream.wait(self.last_compute_event)
            self.lhs_mirror_stream = None
        if self.rhs_mirror_stream is not None:
            self.rhs_mirror_stream.wait(self.last_compute_event)
            self.rhs_mirror_stream = None

        def release_wrapped_reference(wrapped_ops):
            if isinstance(wrapped_ops, Sequence):
                for op in wrapped_ops:
                    op.tensor = None
            else:
                wrapped_ops.tensor = None

        # When possible, we keep the TensorHolder wrappers alive and only release the
        # internal tensor reference so that reset_operands_unchecked can reuse them
        # without re-wrapping.
        # When inplace_a is True on device operands, the user operand is self.lhs
        # directly. CPU inplace keeps the user operand in self.lhs_backup.
        if self.inplace_a and not self.copy_across_memspace:
            release_wrapped_reference(self.lhs)
        else:
            release_wrapped_reference(self.lhs_backup)
            self.lhs = None

        # When inplace_b is True on device operands, the user operand is self.rhs
        # directly. CPU inplace keeps the user operand in self.rhs_backup.
        if self.inplace_b and not self.copy_across_memspace:
            release_wrapped_reference(self.rhs)
        elif self.rhs_backup is not None:
            release_wrapped_reference(self.rhs_backup)
            self.rhs = None

        self._operands_released = True
        self.logger.info("User-provided operands have been released.")

    @utils.precondition(_check_valid_solver)
    def reset_operands(self, *, a=None, b=None, stream: utils.AnyStream | int | None = None):
        """
        Replace ``a`` and/or ``b`` with operands that match the *same* problem shape,
        batching, device, package, and dtype as the original.

        Args:
            a: New left-hand side, or ``None`` to keep the previous left-hand side.
            b: New right-hand side, or ``None`` to keep the previous right-hand side.
            stream: {stream}

        Semantics:
            - Only the operands explicitly passed are updated. At least one operand
              is required (all of them after :meth:`release_operands`), otherwise
              a :class:`ValueError` is raised.

            - Supplying a new ``a`` invalidates the current factorization; call
              :meth:`factorize` again before the next :meth:`solve`.

        {reset_operands_inplace_note}
        """
        # if the operands have been released, both 'a' and 'b' must be provided
        if self._operands_released:
            if a is None or b is None:
                raise ValueError("After release_operands(), both 'a' and 'b' must be provided to reset_operands().")
        elif a is None and b is None:
            # All arguments are None: there is nothing to update, so reject the call.
            raise ValueError("reset_operands() requires at least one operand to be provided.")

        stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)

        def _check_operands_space(operand, operand_name):
            package = solver_utils.get_single_or_sequence_attr(operand, "name")
            device_id = solver_utils.get_single_or_sequence_attr(operand, "device_id")
            dtype_name = solver_utils.get_single_or_sequence_attr(operand, "dtype")
            if package != self.package:
                raise ValueError(f"The package for {operand_name} ({package}) must match the original one ({self.package}).")
            if device_id != self.input_device_id:
                raise ValueError(
                    f"The device id for {operand_name} ({device_id}) must match the original one ({self.input_device_id})."
                )
            if dtype_name != self.dtype_name:
                raise ValueError(
                    f"The dtype for {operand_name} ({dtype_name}) must match the original one ({self.dtype_name})."
                )

        if a is not None:
            lhs, lhs_batch_info, n, lhs_layout = solver_utils.wrap_check_solver_lhs(a, check_inplace_a_layout=self.inplace_a)
            if lhs_batch_info != self.lhs_batch_info:
                raise ValueError(
                    f"The batching metadata for 'a' ({lhs_batch_info!r}) must match the original ({self.lhs_batch_info!r})."
                )
            if n != self.n:
                raise ValueError(f"The number of columns for 'a' ({n}) must match the original one ({self.n}).")
            _check_operands_space(lhs, "a")
            if self.inplace_a and not self.copy_across_memspace:
                self._check_lhs_layout(lhs_layout)
                self.lhs = lhs
            else:
                self.lhs_backup = lhs
                if self.lhs is None:
                    self.lhs = self._create_empty_lhs(stream_holder)
                solver_utils.copy_operands(self.lhs, self.lhs_backup, stream_holder)
            if self.backend == SolverBackend.CUBLAS:
                solver_utils.update_operands_ptr_array(
                    self.lhs_pointers,  # type: ignore[arg-type]
                    self.lhs,
                    stream_holder,
                    self.lhs_batch_indices,
                )
            self.lhs_synced = True
            self.solver_factorized = False
            self.logger.info("User-provided lhs/a has been reset.")
        if b is not None:
            rhs, rhs_batch_info, n, nrhs, rhs_layout = solver_utils.wrap_check_solver_rhs(
                b, check_inplace_b_layout=self.inplace_b
            )
            if rhs_batch_info != self.rhs_batch_info:
                raise ValueError(
                    f"The batching metadata for 'b' ({rhs_batch_info!r}) must match the original ({self.rhs_batch_info!r})."
                )
            if n != self.n:
                raise ValueError(f"The number of columns for 'b' ({n}) must match the original one ({self.n}).")
            if nrhs != self.nrhs:
                raise ValueError(f"The number of right-hand sides for 'b' ({nrhs}) must match the original one ({self.nrhs}).")
            _check_operands_space(rhs, "b")
            if self.inplace_b and not self.copy_across_memspace:
                self._check_rhs_layout(rhs_layout)
                self.rhs = rhs
            else:
                self.rhs_backup = rhs
                if self.rhs is None:
                    self.rhs = self._create_empty_rhs(stream_holder)
                solver_utils.copy_operands(self.rhs, self.rhs_backup, stream_holder)
            if self.backend == SolverBackend.CUBLAS:
                solver_utils.update_operands_ptr_array(
                    self.rhs_pointers,  # type: ignore[arg-type]
                    self.rhs,
                    stream_holder,
                    self.rhs_batch_indices,
                )
            self.rhs_synced = True
            self.logger.info("User-provided rhs/b has been reset.")

        self._operands_released = False

    @utils.precondition(_check_valid_solver)
    def reset_operands_unchecked(self, *, a=None, b=None, stream: utils.AnyStream | int | None = None):
        """
        .. experimental:: method

        This method is a performance-optimized alternative to :meth:`reset_operands` that
        eliminates validation and logging overhead, making it ideal for
        performance-critical loops where ``a``/``b`` compatibility is guaranteed by the
        caller.

        This method accepts the same parameters as :meth:`reset_operands`.

        Args:
            a: New left-hand side, or ``None`` to keep the previous one. The caller must
                guarantee the same invariants :meth:`reset_operands` would enforce; this
                method does not validate.
            b: New right-hand side, or ``None`` to keep the previous one. Same invariants
                as ``a`` where applicable.
            stream: {stream}

        Returns:
            None

        Semantics:
            The semantics are the same as in :meth:`reset_operands`, except that this
            method does not perform any validation
            (e.g. batching metadata, ``n``, ``n_rhs``, device, and dtype) or logging.

        When to Use:
            - Performance-critical loops with repeated :meth:`solve` or operand updates
              when compatibility is already guaranteed

            - After verifying correctness with :meth:`reset_operands` during development

            - When ``a``/``b`` compatibility is guaranteed by construction or invariant

        {reset_operands_inplace_note}

        .. seealso::
            :meth:`reset_operands`, :meth:`release_operands`
        """
        # If operands have been released, all required operands must be provided
        if self._operands_released and (a is None or b is None):
            raise ValueError("After release_operands(), both 'a' and 'b' must be provided to reset_operands_unchecked().")

        stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)
        if a is not None:
            if self.inplace_a and not self.copy_across_memspace:
                # inplace_a requires operands to be in the execution space,
                # therefore we can directly update self.lhs with the user-provided operands.
                if self.lhs_batch_info.explicitly_batched:
                    for lhs_wrapper, lhs_raw in zip(self.lhs, a, strict=True):
                        lhs_wrapper.tensor = lhs_raw
                else:
                    self.lhs.tensor = a
            else:
                if self.lhs is None:
                    self.lhs = self._create_empty_lhs(stream_holder)
                # update the internal tensor references held by the wrappers
                # for the user-provided operands.
                if self.lhs_batch_info.explicitly_batched:
                    for lhs_wrapper, lhs_raw in zip(self.lhs_backup, a, strict=True):
                        lhs_wrapper.tensor = lhs_raw
                else:
                    self.lhs_backup.tensor = a
                solver_utils.copy_operands(self.lhs, self.lhs_backup, stream_holder)
            if self.backend == SolverBackend.CUBLAS:
                solver_utils.update_operands_ptr_array(
                    self.lhs_pointers,  # type: ignore[arg-type]
                    self.lhs,
                    stream_holder,
                    self.lhs_batch_indices,
                )
            self.lhs_synced = True
            self.solver_factorized = False
        if b is not None:
            if self.inplace_b and not self.copy_across_memspace:
                # inplace_b requires operands to be in the execution space,
                # therefore we can directly update self.rhs with the user-provided operands.
                if self.rhs_batch_info.explicitly_batched:
                    for rhs_wrapper, rhs_raw in zip(self.rhs, b, strict=True):
                        rhs_wrapper.tensor = rhs_raw
                else:
                    self.rhs.tensor = b
            else:
                if self.rhs is None:
                    self.rhs = self._create_empty_rhs(stream_holder)
                # update the internal tensor references held by the wrappers
                # for the user-provided operands.
                if self.rhs_batch_info.explicitly_batched:
                    for rhs_wrapper, rhs_raw in zip(self.rhs_backup, b, strict=True):
                        rhs_wrapper.tensor = rhs_raw
                else:
                    self.rhs_backup.tensor = b
                solver_utils.copy_operands(self.rhs, self.rhs_backup, stream_holder)
            if self.backend == SolverBackend.CUBLAS:
                solver_utils.update_operands_ptr_array(
                    self.rhs_pointers,  # type: ignore[arg-type]
                    self.rhs,
                    stream_holder,
                    self.rhs_batch_indices,
                )
            self.rhs_synced = True
        self._operands_released = False

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_valid_operands, "Planning")
    def plan(self, stream: utils.AnyStream | int | None = None):
        """
        Plan the dense direct solve. This is the **preparation** step before numerical
        factorization (any sizing or setup required for the current operands on the
        selected device). After planning, the object is ready for :meth:`factorize`.

        In the class-based workflow, call :meth:`plan` once before calling
        :meth:`factorize` and :meth:`solve`.

        Args:
            stream: {stream}

        .. seealso::
            :meth:`factorize`, :meth:`solve`.
        """
        self.logger.info("= PLANNING PHASE =")
        if self.solver_planned:
            self.logger.info("Skipping planning since it has already been performed in a previous call.")
            return

        if self.backend == SolverBackend.CUBLAS:
            # cublas does not require workspace memory for cublasXgetrf/getrsBatched
            self.logger.info("For batched input, workspace memory allocation is not required for cublasXgetrf/getrsBatched.")
            self.device_workspace.set_size(0)
            self.host_workspace.set_size(0)
            # resolve the function pointers for the batched getrf/getrs functions
            match self.dtype_name:
                case "float32":
                    self._getrf_func = cublas.sgetrf_batched
                    self._getrs_func = cublas.sgetrs_batched
                case "float64":
                    self._getrf_func = cublas.dgetrf_batched
                    self._getrs_func = cublas.dgetrs_batched
                case "complex64":
                    self._getrf_func = cublas.cgetrf_batched
                    self._getrs_func = cublas.cgetrs_batched
                case "complex128":
                    self._getrf_func = cublas.zgetrf_batched
                    self._getrs_func = cublas.zgetrs_batched
                case _:
                    raise NotImplementedError(f"The dtype {self.dtype_name} is not supported yet.")
        else:
            # resolve the function pointers for the Non-batched getrf/getrs functions
            self._getrf_func = cusolverDn.xgetrf
            self._getrs_func = cusolverDn.xgetrs
            stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)
            with utils.cuda_call_ctx(stream_holder, self.blocking) as (self.last_compute_event, elapsed):
                cusolverDn.set_stream(self.handle, stream_holder.ptr)
                workspace_size_device, workspace_size_host = cusolverDn.xgetrf_buffer_size(
                    self.handle,
                    self.params,
                    self.n,
                    self.n,
                    self.cuda_dtype,
                    self.lhs.data_ptr,
                    self.lhs_layout.lda,
                    self.cuda_dtype,
                )  # type: ignore[assignment]
                self.device_workspace.set_size(workspace_size_device)
                self.host_workspace.set_size(workspace_size_host)
            if elapsed.data is not None:
                self.logger.info(f"Planning took {elapsed.data:.3f} ms to complete.")
            else:
                self.logger.info("Planning has been completed.")
        self.solver_planned = True

    def _create_internal_operand(self, shape, dtype, stream_holder, strides=None):
        return utils.create_empty_tensor(
            self.internal_operand_class,
            shape,
            dtype,
            self.execution_device,
            stream_holder,
            verify_strides=False,
            strides=strides,
        )

    def _create_empty_lhs(self, stream_holder: utils.StreamHolder):
        # TODO: currently lhs is created with F order, matching the generally
        # expected input for cusolver/cublas. In principle we could optimize it such that:
        # 1. If input is in C order, lhs also gets created in C order and
        #    makes use of cublas.Operation.T to perform the equivalent operation.
        # 2. If input is not in C order, lhs also gets created in F order and
        #    makes use of cublas.Operation.N to perform the equivalent operation.
        # 3. This would help speedup the d2d copy process when the input is in C order.
        if not self.batched:
            lhs = self._create_internal_operand(self.lhs_shape, self.dtype_name, stream_holder, (1, self.n))
        elif self.lhs_batch_info.explicitly_batched:
            lhs = [
                self._create_internal_operand(self.lhs_shape, self.dtype_name, stream_holder, (1, self.n))
                for _ in range(self.batch_count)
            ]
        else:
            assert self.lhs_batch_info.implicitly_batched, "Internal Error."
            # For execution, store lhs as shape (m, m, *batch_shape) in F order.
            opt_shape = (self.n, self.n) + self.lhs_shape[:-2]
            opt_strides = solver_utils.compute_f_strides(opt_shape)
            # revert the the original view to get the correct strides
            shape = self.lhs_shape
            strides = opt_strides[2:] + opt_strides[:2]
            lhs = self._create_internal_operand(shape, self.dtype_name, stream_holder, strides)
        # Update the allocation stream for proper ordering in free() and release_operands()
        self.lhs_mirror_stream = stream_holder.obj
        self.logger.debug("Allocating lhs/a in the execution space for the linear solver...")
        return lhs

    def _create_empty_rhs(self, stream_holder: utils.StreamHolder):
        if not self.batched:
            rhs = self._create_internal_operand(
                self.rhs_shape, self.dtype_name, stream_holder, solver_utils.compute_f_strides(self.rhs_shape)
            )
        elif self.rhs_batch_info.explicitly_batched:
            strides = solver_utils.compute_f_strides(self.rhs_shape)
            rhs = [
                self._create_internal_operand(self.rhs_shape, self.dtype_name, stream_holder, strides)
                for _ in range(self.batch_count)
            ]
        else:
            assert self.rhs_batch_info.implicitly_batched, "Internal Error."
            b_dim = len(self.rhs_shape)
            batch_dim = len(self.rhs_batch_info.batch_shape)

            if b_dim == batch_dim + 1:
                # m, nrhs
                opt_shape = (self.n,) + self.rhs_batch_info.batch_shape
                opt_strides = solver_utils.compute_f_strides(opt_shape)
                strides = opt_strides[1:] + opt_strides[:1]
            else:
                assert b_dim == batch_dim + 2, "Internal Error."
                opt_shape = (self.n, self.nrhs) + self.rhs_batch_info.batch_shape
                opt_strides = solver_utils.compute_f_strides(opt_shape)
                strides = opt_strides[2:] + opt_strides[:2]
            rhs = self._create_internal_operand(self.rhs_shape, self.dtype_name, stream_holder, strides)
        # Update the allocation stream for proper ordering in free() and release_operands()
        self.rhs_mirror_stream = stream_holder.obj
        self.logger.debug("Allocating rhs/b in the execution space for the linear solver...")
        return rhs

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_planned, "Factorization")
    @utils.precondition(_check_valid_operands, "Factorization")
    def factorize(self, *, stream: utils.AnyStream | int | None = None):
        """
        Factorize the system of equations. This performs a numerical **LU** decomposition
        of the left-hand side ``a`` for the current problem. Call :meth:`plan` first.

        Each call factorizes the LHS ``a`` currently held by the solver. To
        change the LHS values between calls, call :meth:`reset_operands` (or
        :meth:`reset_operands_unchecked`) with the new ``a``. Alternatively,
        when ``inplace_a=True`` and ``a`` is accessible from the execution
        space, users may directly modify ``a`` in place, for example with
        ``a[:] = a_new``. In that case, users are responsible for ensuring
        that ``a`` contains the intended LHS values before each call, since
        :meth:`factorize` overwrites that operand with its LU factors.

        Args:
            stream: {stream}

        .. seealso::
            :meth:`plan`, :meth:`solve`, :meth:`reset_operands`.
        """

        self.logger.info("= FACTORIZATION PHASE =")
        self.logger.info(self.call_prologue)
        self.solver_factorized = False

        stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)

        if not self.lhs_synced:
            solver_utils.copy_operands(self.lhs, self.lhs_backup, stream_holder)
            self.lhs_synced = True

        elapsed = None
        getrf = self._getrf_func
        assert getrf is not None, "Internal error"

        if self.backend == SolverBackend.CUBLAS:
            with utils.cuda_call_ctx(stream_holder, self.blocking) as (self.last_compute_event, elapsed):
                cublas.set_stream(self.handle, stream_holder.ptr)
                getrf(
                    self.handle,
                    self.n,
                    self.lhs_pointers.data_ptr,  # type: ignore[union-attr]
                    self.lhs_layout.lda,
                    self.pivot.data_ptr,
                    self.getrf_info_device.data_ptr,
                    self.batch_count,
                )
        else:
            with (
                self.device_workspace.allocate_perhaps(
                    stream_holder, get_last_event=lambda: self.last_compute_event
                ) as device_ws,
                self.host_workspace.allocate_perhaps(stream_holder, get_last_event=lambda: self.last_compute_event) as host_ws,
                utils.cuda_call_ctx(stream_holder, self.blocking) as (self.last_compute_event, elapsed),
            ):
                cusolverDn.set_stream(self.handle, stream_holder.ptr)
                getrf(
                    self.handle,
                    self.params,
                    self.n,
                    self.n,
                    self.cuda_dtype,
                    self.lhs.data_ptr,
                    self.lhs_layout.lda,
                    self.pivot.data_ptr,
                    self.cuda_dtype,  # compute type
                    device_ws.raw_ptr,
                    device_ws.size,
                    host_ws.raw_ptr,
                    host_ws.size,
                    self.getrf_info_device.data_ptr,
                )
        # When inplace_a=True and the LHS operand lives on the execution space,
        # lhs_synced always remains True. Otherwise, GETRF overwrites the internal
        # execution buffer with LU factors, so it no longer matches the source LHS.
        self.lhs_synced = self.inplace_a and not self.copy_across_memspace

        if elapsed.data is not None:
            self.logger.info(f"The factorization phase took {elapsed.data:.3f} ms to complete.")

        self.getrf_info_host.copy_(self.getrf_info_device, stream_holder)
        if self.backend == SolverBackend.CUSOLVER:
            info = self.getrf_info_host.tensor.item()
            if info != 0:
                if info > 0:
                    raise RuntimeError(f"Factorization failed with U[{info}, {info}] being 0.")
                else:
                    # The (-info)-th parameter to cusolverDnXgetrf is invalid.
                    raise AssertionError(
                        f"Internal error: cusolverDnXgetrf reported an invalid argument at position {-info} (info={info})."
                    )
        else:
            info = self.getrf_info_host.tensor
            if not np.all(info == 0):
                failed_batch_indices = np.where(info > 0)[0]
                if len(failed_batch_indices) > 0:
                    raise RuntimeError(f"Factorization failed for the following batch indices: {failed_batch_indices}.")
                # The (-info)-th parameter to cublasXgetrfBatched is invalid.
                info = info.item(0)
                raise AssertionError(
                    f"Internal error: cublasXgetrfBatched reported an invalid argument at position {-info} (info={info})."
                )

        if self.inplace_a and self.copy_across_memspace:
            solver_utils.copy_operands(self.lhs_backup, self.lhs, stream_holder)
        self.logger.info("Factorization has been completed.")
        self.solver_factorized = True
        return

    @utils.precondition(_check_valid_solver)
    @utils.precondition(_check_valid_operands, "Solver Execution")
    @utils.precondition(_check_planned, "Solver Execution")
    @utils.precondition(_check_factorized, "Solver Execution")
    def solve(self, *, stream: utils.AnyStream | int | None = None):
        """
        Solve the factorized system of equations, producing the solution ``x`` for
        :math:`a @ x = b` using the factor from the most recent :meth:`factorize` and
        the current right-hand side ``b``.

        Each call uses the RHS ``b`` currently held by the solver. To change
        the RHS values between calls, call :meth:`reset_operands` (or
        :meth:`reset_operands_unchecked`) with the new ``b``. Alternatively,
        when ``inplace_b=True`` and ``b`` is accessible from the execution
        space, users may directly modify ``b`` in place, for example with
        ``b[:] = b_new``. In that case, users are responsible for ensuring
        that ``b`` contains the intended RHS values before each call, since
        :meth:`solve` overwrites that operand with the solution.

        Args:
            stream: {stream}

        Returns:
            {result}

        .. seealso::
            :meth:`plan`, :meth:`factorize`, :meth:`reset_operands`.
        """

        self.logger.info("= SOLVER EXECUTION PHASE =")
        self.logger.info(self.call_prologue)

        stream_holder = utils.get_or_create_stream(self.execution_device, stream, self.stream_package)

        if self.rhs is None:
            if self.inplace_b:
                raise RuntimeError("Internal error: inplace_b=True requires an active RHS operand.")
            self.rhs = self._create_empty_rhs(stream_holder)
            if self.backend == SolverBackend.CUBLAS:
                solver_utils.update_operands_ptr_array(
                    self.rhs_pointers,  # type: ignore[arg-type]
                    self.rhs,
                    stream_holder,
                    self.rhs_batch_indices,
                )
        if not self.rhs_synced:
            # The execution RHS was overwritten by a previous solve. Refresh it
            # from the source RHS before the next solve. reset_operands(..., b=...)
            # also repopulates rhs and sets rhs_synced True.
            #
            # Example: same rhs, new lhs — only the lhs must be updated:
            #
            #   with DirectSolver(a0, b) as solver:
            #       solver.plan()
            #       solver.factorize()
            #       x0 = solver.solve()
            #       solver.reset_operands(a=a1)
            #       solver.factorize()
            #       x1 = solver.solve()
            solver_utils.copy_operands(self.rhs, self.rhs_backup, stream_holder)
            self.rhs_synced = True

        getrs = self._getrs_func
        assert getrs is not None, "Internal error"

        with utils.cuda_call_ctx(stream_holder, self.blocking) as (self.last_compute_event, elapsed):
            if self.backend == SolverBackend.CUSOLVER:
                # From cusolverDn, regardless of whether b is a vector or a matrix,
                # b is viewed as an F ordered matrix with shape (m, nrhs) with ldb = m
                # When b is a vector, nrhs = 1
                ldb = self.rhs_layout.ldb
                cusolverDn.set_stream(self.handle, stream_holder.ptr)
                # here getrf_info_device is reused for getrs_info
                # we can skip the check for getrs_info as it only checks for invalid args
                getrs(
                    self.handle,
                    self.params,
                    self.getrs_operation,
                    self.n,
                    self.nrhs,
                    self.cuda_dtype,
                    self.lhs.data_ptr,
                    self.lhs_layout.lda,
                    self.pivot.data_ptr,
                    self.cuda_dtype,
                    self.rhs.data_ptr,
                    ldb,
                    self.getrf_info_device.data_ptr,
                )
                self.getrf_info_host.copy_(self.getrf_info_device, stream_holder)
                info = self.getrf_info_host.tensor.item()
                assert info == 0, (
                    f"Internal error: cusolverDnXgetrs reported an invalid argument at position {-info} (info={info})."
                )
            else:
                assert self.backend == SolverBackend.CUBLAS, "Internal Error."
                ldb = self.rhs_layout.ldb
                info = np.empty(1, dtype=np.int32)
                cublas.set_stream(self.handle, stream_holder.ptr)
                getrs(
                    self.handle,
                    self.getrs_operation,
                    self.n,
                    self.nrhs,
                    self.lhs_pointers.data_ptr,  # type: ignore[union-attr]
                    self.lhs_layout.lda,
                    self.pivot.data_ptr,
                    self.rhs_pointers.data_ptr,  # type: ignore[union-attr]
                    ldb,
                    info.ctypes.data,
                    self.batch_count,
                )
                assert np.all(info == 0), f"Internal error: cublasXgetrsBatched reported an invalid argument (info={info})."

        if elapsed.data is not None:
            self.logger.info(f"The solver execution took {elapsed.data:.3f} ms to complete.")

        self.logger.info("Solver execution has been completed.")

        # GETRS overwrites rhs with the solution. For device-resident inplace_b,
        # rhs is also the source allocation, so execution/source still match and
        # users are responsible for restoring intended RHS values. Otherwise,
        # the execution RHS no longer matches source until refreshed.
        self.rhs_synced = self.inplace_b and not self.copy_across_memspace

        if self.inplace_b:
            if self.copy_across_memspace:
                solver_utils.copy_operands(self.rhs_backup, self.rhs, stream_holder)
                rhs_return = self.rhs_backup
            else:
                rhs_return = self.rhs
            if isinstance(rhs_return, Sequence):
                return [o.tensor for o in rhs_return]
            return rhs_return.tensor
        elif self.copy_across_memspace:
            self.logger.debug("Copying the result to the input device id...")
            # return the result on the input device id
            if isinstance(self.rhs, Sequence):
                return [o.to(self.input_device_id, stream_holder=stream_holder).tensor for o in self.rhs]
            else:
                return self.rhs.to(self.input_device_id, stream_holder=stream_holder).tensor
        else:
            # return the ownership of the result to the caller
            if isinstance(self.rhs, Sequence):
                out = [o.tensor for o in self.rhs]
            else:
                out = self.rhs.tensor
            self.rhs = None
            return out

    def free(self):
        """Free :class:`DirectSolver` resources.

        It is recommended that the object be used as a context manager; if that is
        not possible, call this method explicitly when the object is no longer needed.
        """
        if not self.valid_state:
            return

        try:
            self.device_workspace.release(self.last_compute_event)
            self.host_workspace.release(self.last_compute_event)
            if self.last_compute_event is not None:
                streams = {
                    self.lhs_mirror_stream,
                    self.rhs_mirror_stream,
                    self.resource_alloc_stream,
                }

                for stream in streams:
                    if stream is not None:
                        stream.wait(self.last_compute_event)

                self.lhs_mirror_stream = None
                self.rhs_mirror_stream = None
                self.resource_alloc_stream = None
                self.last_compute_event = None

            # Free cusolverDn params if it exists.
            if self.params is not None:
                cusolverDn.destroy_params(self.params)
                self.params = None

            # Free handle if we own it.
            if self.handle is not None and self.own_handle:
                cusolverDn.destroy(self.handle)
                self.handle, self.own_handle = None, False

            # Set all attributes to None except for logger and valid_state
            _keep = {"logger", "valid_state"}
            for attr in list(vars(self)):
                if attr not in _keep:
                    setattr(self, attr, None)

        except Exception as e:
            self.logger.critical("Internal error: only part of the DirectSolver object's resources have been released.")
            self.logger.critical(str(e))
            raise e
        finally:
            self.valid_state = False

        self.logger.info("The DirectSolver object's resources have been released.")

    def __enter__(self):
        """
        Return ``self`` for a ``with`` block; the matching :meth:`__exit__` calls
        :meth:`free` so resources are always released.
        """
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """
        Call :meth:`free` (context manager ``__exit__`` protocol).
        """
        self.free()


@utils.docstring_decorator(GENERIC_DIRECT_SOLVER_DOCUMENTATION, skip_missing=False)
def direct_solver(
    a: AnyTensor,
    b: AnyTensor,
    *,
    options: DirectSolverOptions | dict[str, Any] | None = None,
    execution: ExecutionCUDA | str | dict[str, Any] | None = None,
    stream: utils.AnyStream | int | None = None,
):
    r"""
    Solve :math:`a @ x = b` for :math:`x`. This function-form API is a wrapper around the
    stateful :class:`DirectSolver` object APIs and is meant for *single* use (for example,
    when the user needs to perform just one dense direct linear solve), in which case
    there is no possibility of amortizing preparatory costs (such as :meth:`DirectSolver.plan`
    and :meth:`DirectSolver.factorize` before :meth:`DirectSolver.solve`).

    Use :class:`DirectSolver` when reusing a factorization or performing many solves for the
    same problem size and layout, or when using :class:`DirectSolverOptions` in a long-lived
    way (for example a logger or a custom handle).

    Args:
        a: {a}
        b: {b}
        options: {options}
        execution: {execution}
        stream: {stream}

    Returns:
        {result}

    Semantics:
        {semantics}

    {direct_solver_note}

    Examples:

        A single :func:`~nvmath.linalg.direct_solver` call (equivalent to :meth:`DirectSolver.plan` followed
        by :meth:`DirectSolver.factorize` and :meth:`DirectSolver.solve` on a stateful
        object) with NumPy CPU operands, which the implementation executes on the
        default CUDA device:

        >>> import numpy as np
        >>> import nvmath.linalg as la
        >>>
        >>> n = 4
        >>> rng = np.random.default_rng(0)
        >>> a = rng.standard_normal((n, n), dtype=np.float64) + n * np.eye(n, dtype=np.float64)
        >>> b = np.ones(n, dtype=np.float64)
        >>>
        >>> x = la.direct_solver(a, b)
        >>> x.shape
        (4,)

        For ``options``, ``stream``, and batching, see the **Semantics** section. More
        examples (batching, :meth:`~DirectSolver.reset_operands`, streams) are in
        `generic direct solver examples
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/linalg/generic/direct_solver>`_
        on GitHub.
    """  # noqa: W505
    with DirectSolver(a, b, options=options, execution=execution, stream=stream) as solver:
        solver.plan(stream=stream)
        solver.factorize(stream=stream)
        return solver.solve(stream=stream)
