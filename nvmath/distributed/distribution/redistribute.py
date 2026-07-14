# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = ["Redistribute", "redistribute"]

import logging
import math
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Final, Literal, cast

import nvmath.distributed
from nvmath.bindings import (
    cufftMp,  # type: ignore
    nvshmem,  # type: ignore
)
from nvmath.distributed._internal import tensor_wrapper
from nvmath.distributed._internal.nvshmem import NvshmemMemoryManager
from nvmath.distributed._internal.tensor_ifc import DistributedTensor
from nvmath.distributed.distribution import Box, ConvertDistributionError, Distribution
from nvmath.internal import formatters, utils
from nvmath.internal.package_wrapper import AnyStream, StreamHolder

from ._configuration import RedistributeOptions


@dataclass
class TensorLayout:
    """An internal data class for capturing the tensor layout."""

    shape: Sequence[int]
    strides: Sequence[int]


@dataclass
class _ProblemSpec:
    """This is used in a custom reduction to check that the Redistribute problem
    specification is consistent across processes, and to infer global information
    (e.g shape and memory layout)."""

    @dataclass
    class Options:
        """
        This is used for _ProblemSpec instead of ._configuration.RedistributeOptions
        because it's going to be serialized as part of the custom reduction of the
        _ProblemSpec, and we want to control which fields are included (for example
        we don't need the logger).
        """

        def __init__(self, options: RedistributeOptions):
            self.blocking = options.blocking

        blocking: Literal[True, "auto"]

    shape: tuple[int, ...]  # operand local shape
    is_F: bool  # Is Fortran memory layout
    is_C: bool  # Is C memory layout
    operand_dtype: str  # str because TensorHolder.dtype returns str
    package: Literal["numpy", "cupy", "torch"]  # operand package
    memory_space: Literal["cuda", "cpu"]  # operand memory space
    input_distribution: Distribution
    output_distribution: Distribution
    options: Options  # Redistribute options
    rank: int  # only valid if is_leaf=True

    # Global number of elements in the operand (calculated as part of the reduction).
    global_size: int = 0
    # is_leaf=True means that this is the _ProblemSpec of a process before reducing
    # with that of another process.
    is_leaf: bool = True


SHARED_REDISTRIBUTE_DOCUMENTATION = utils.COMMON_SHARED_DOC_MAP.copy()
SHARED_REDISTRIBUTE_DOCUMENTATION.update(
    {
        "operand": SHARED_REDISTRIBUTE_DOCUMENTATION["operand"],
        #
        "operand_admonitions": """
            .. important::
                GPU operands must be on the symmetric heap (for example, allocated with
                ``nvmath.distributed.allocate_symmetric_memory()``).
""",
        #
        "options": """\
Specify options for Redistribute as a :class:`RedistributeOptions` object. Alternatively, a `dict`
containing the parameters for the ``RedistributeOptions`` constructor can also be provided. If not
specified, the value will be set to the default-constructed ``RedistributeOptions`` object.""".replace("\n", " "),
        #
        "input_distribution": """\
The distribution of the input operand across processes, determining which portion of
the global array each process holds.""".replace("\n", " "),
        #
        "output_distribution": """\
The desired distribution of the result across processes, where each process
specifies which portion of the global array it will hold after reshaping.""".replace("\n", " "),
        #
        "sync_symmetric_memory": """\
Indicates whether to issue a symmetric memory synchronization operation on the execute stream
before the redistribute operation. Note that before Redistribute starts executing, it is
required that the source operand be ready on all processes. A symmetric memory synchronization
ensures completion and visibility by all processes of previously issued local stores to
symmetric memory. Advanced users who choose to manage the synchronization on their own using
the appropriate NVSHMEM API, or who know that GPUs are already synchronized on the source
operand, can set this to False.""".replace("\n", " "),
        #
        "function_signature": """\
operand,
input_distribution: Distribution,
output_distribution: Distribution,
sync_symmetric_memory: bool = True,
options: RedistributeOptions | dict[str, Any] | None = None,
stream: AnyStream | None = None
""".replace("\n", " "),
        #
        "reset_operand_unchecked": utils._reset_operand_unchecked_docstring(
            False, validation_examples="package match, data type match, shape/strides match", experimental=False
        ),
    }
)


def _calculate_strides(shape, axis_order):
    """
    Calculate the strides for the provided shape and axis order.
    """
    strides = [None] * len(shape)

    stride = 1
    for axis in axis_order:
        strides[axis] = stride
        stride *= shape[axis]

    return strides


def _alloc_and_copy_to_exespace_mirror_or_identity(
    user_operand: DistributedTensor,
    stream_holder,
    execution_space,
    memory_space,
    device_id: int | Literal["cpu"],
) -> tuple[DistributedTensor, DistributedTensor | None]:
    """
    Allocate the exespace mirror for the given execution/memory space, or
    return the user operand as-is (identity) when no mirror is needed.

    Returns ``(operand, operand_backup)`` where:
      - Same-space: ``operand`` is the user operand itself, ``operand_backup``
        is ``None`` (no mirror needed).
      - Cross-space: ``operand`` is the newly allocated device-side mirror,
        ``operand_backup`` is the original user operand (for result copy-back).
    """
    if execution_space == memory_space:
        return user_operand, None
    assert execution_space == "cuda"
    mirror = user_operand.to(device_id, stream_holder, symmetric_memory="nvshmem")
    return mirror, user_operand


def _problem_spec_reducer(p1: _ProblemSpec, p2: _ProblemSpec):
    try:
        if isinstance(p1, Exception):
            return p1  # propagate exception

        if isinstance(p2, Exception):
            return p2  # propagate exception

        if len(p1.shape) != len(p2.shape):
            return ValueError("The number of dimensions of the input operand is inconsistent across processes")

        if len(p1.shape) <= 0 or len(p1.shape) > 3:
            return ValueError(
                "Redistribute currently only supports 1-D, 2-D and 3-D tensors."
                f" The number of dimensions of the operand is {len(p1.shape)}."
            )

        if p1.operand_dtype != p2.operand_dtype:
            return ValueError("The operand dtype is inconsistent across processes")

        if p1.package != p2.package:
            return ValueError("operand doesn't belong to the same package on all processes")

        if p1.memory_space != p2.memory_space:
            return ValueError('operand is not on the same memory space ("cpu", "cuda") on all processes')

        if p1.options != p2.options:
            return ValueError(f"options are inconsistent across processes: {p1.options} != {p2.options}")

        # Determine the memory layout shared by all processes. Note that it's possible for
        # a process to have both C and F layout (e.g. (2, 1) input shape).
        p1.is_C &= p2.is_C
        p1.is_F &= p2.is_F
        if not p1.is_F and not p1.is_C:
            return ValueError("The input memory layout is not C or Fortran, or is inconsistent across processes")

        if type(p1.input_distribution) is not type(p2.input_distribution):
            return ValueError(
                f"input distribution types are inconsistent across processes: "
                f"{type(p1.input_distribution)} != {type(p2.input_distribution)}"
            )

        if type(p1.output_distribution) is not type(p2.output_distribution):
            return ValueError(
                f"output distribution types are inconsistent across processes: "
                f"{type(p1.output_distribution)} != {type(p2.output_distribution)}"
            )

        for p_spec in (p1, p2):
            if p_spec.is_leaf:
                p_spec.input_distribution._global_shape_reduction_prologue(p_spec.rank, p_spec.shape)
                if isinstance(p_spec.output_distribution, Box):
                    # This allows checking (after the reduction) that the output boxes
                    # are valid.
                    p_spec.output_distribution._global_shape_reduction_prologue(
                        p_spec.rank, p_spec.output_distribution.box_shape
                    )

        p1.input_distribution._global_shape_reduction(p2.input_distribution)
        if isinstance(p1.output_distribution, Box):
            p1.output_distribution._global_shape_reduction(p2.output_distribution)
        elif p1.output_distribution != p2.output_distribution:
            return ValueError(
                f"output distribution types are inconsistent across processes: "
                f"{p1.output_distribution} != {p2.output_distribution}"
            )

        if p1 is not p2:  # with nranks=1 p1 is p2
            p1.global_size += p2.global_size

    except Exception as e:
        return e
    p1.is_leaf = False
    return p1


class InvalidRedistributeState(Exception):
    pass


@utils.docstring_decorator(SHARED_REDISTRIBUTE_DOCUMENTATION, skip_missing=False)
class Redistribute:
    """
    Create a stateful object that encapsulates the specified Redistribute operation
    and required resources. This object ensures the validity of resources during use and
    releases them when they are no longer needed to prevent misuse.

    This object encompasses all functionalities of the function-form API
    :func:`redistribute`, which is a convenience wrapper around it. The stateful object
    also allows for the amortization of preparatory costs when the same Redistribute
    operation is to be performed on multiple operands with the same problem specification
    (see :meth:`reset_operand` for more details).

    Using the stateful object typically involves the following steps:

    1. **Problem Specification**: Initialize the object with a defined operation and
       options.
    2. **Preparation**: Use :meth:`plan` to determine the best distributed algorithmic
       implementation for this specific Redistribute operation.
    3. **Execution**: Perform the redistribution with :meth:`execute`.
    4. **Resource Management**: Ensure all resources are released either by explicitly
       calling :meth:`free` or by managing the stateful object within a context manager.

    Detailed information on each step described above can be obtained by passing in a
    :class:`logging.Logger` object to :class:`RedistributeOptions` or by setting the
    appropriate options in the root logger object, which is used by default:

        >>> import logging
        >>> logging.basicConfig(
        ...     level=logging.INFO,
        ...     format="%(asctime)s %(levelname)-8s %(message)s",
        ...     datefmt="%m-%d %H:%M:%S",
        ... )

    .. versionchanged:: 1.0
         This class was previously ``nvmath.distributed.reshape.Reshape``.

    Args:
        operand: {operand}
            {operand_admonitions}

        input_distribution: {input_distribution}

        output_distribution: {output_distribution}

        options: {options}

        stream: {stream}

    .. seealso::
        :meth:`plan`, :meth:`reset_operand`, :meth:`execute`,
        :meth:`release_operand`

    Examples:

        >>> import cupy as cp
        >>> import nvmath.distributed

        Get process group used to initialize nvmath.distributed (for information on
        initializing nvmath.distributed, you can refer to the documentation or to the
        Redistribute examples in `nvmath/examples/distributed/redistribute
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute>`_):

        >>> process_group = nvmath.distributed.get_context().process_group
        >>> rank = process_group.rank

        Let's create a 3D floating-point ndarray on GPU, distributed across a certain number
        of processes, according to the Slab distribution with partitioning on the X axis.

        >>> shape = Slab.X.shape(rank, (global_shape))

        Redistribute uses the NVSHMEM PGAS model, which requires GPU operands to be on the
        symmetric heap:

        >>> a = nvmath.distributed.allocate_symmetric_memory(shape, cp)
        >>> a[:] = cp.random.rand(*shape)

        With Redistribute, we will change how the ndarray is distributed, by specifying
        the input distribution and the desired output distribution. In this example,
        we redistribute from Slab.X to Slab.Y.

        Create a Redistribute object encapsulating the problem specification above:

        >>> r = nvmath.distributed.distribution.Redistribute(a, Slab.X, Slab.Y)

        Options can be provided above to control the behavior of the operation using the
        `options` argument (see :class:`RedistributeOptions`).

        Next, plan the Redistribute:

        >>> r.plan()

        Now execute the Redistribute, and obtain the result `b` as a CuPy ndarray.
        Redistribute always performs the distributed operation on the GPU.

        >>> b = r.execute()

        Finally, free the Redistribute object's resources. To avoid this explicit call, it's
        recommended to use the Redistribute object as a context manager as shown below, if
        possible.

        >>> r.free()

        Any symmetric memory that is owned by the user must be deleted explicitly (this is
        a collective call and must be called by all processes):

        >>> nvmath.distributed.free_symmetric_memory(a, b)

        Note that all :class:`Redistribute` methods execute on the current stream by
        default. Alternatively, the `stream` argument can be used to run a method on
        a specified stream.

        Let's now look at the same problem with NumPy ndarrays on the CPU.

        >>> import numpy as np
        >>> a = np.random.rand(*shape)  # each process holds a different section

        Create a Redistribute object encapsulating the problem specification described
        earlier and use it as a context manager.

        >>> with nvmath.distributed.distribution.Redistribute(a, Slab.X, Slab.Y) as r:
        ...     r.plan()
        ...
        ...     # Execute the Redistribute to redistribute the ndarray.
        ...     b = r.execute()

        All the resources used by the object are released at the end of the block.

        Redistribute always executes on the GPU. In this case, because ``a`` resides in host
        memory, the NumPy array is temporarily copied to device memory (on the symmetric
        memory heap), re-distributed on the GPU, and the result is copied to host memory
        as a NumPy array.

        Further examples can be found in the `nvmath/examples/distributed/redistribute
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute>`_
        directory.
    """

    def _free_internal_sheap(self, exception: Exception | None = None) -> bool:
        # This is a fail-safe to free NVSHMEM internal memory in case of invalid
        # state (Redistribute constructor fails). Since we might call nvshmem_free here,
        # we're assuming that all processes equally failed in the ctor, which might not
        # be true, but if it weren't true they would end up in deadlock most likely anyway.
        if (
            hasattr(self, "memory_space")
            and self.memory_space == "cpu"
            and self.operand is not None
            and self.operand.device == "cuda"
        ):
            with utils.device_ctx(self.device_id):
                self.operand.free_symmetric()
        return True

    @utils.atomic(_free_internal_sheap, method=True)
    def __init__(
        self,
        operand,
        /,
        input_distribution: Distribution,
        output_distribution: Distribution,
        *,
        options: RedistributeOptions | dict[str, Any] | None = None,
        stream: AnyStream | None = None,
    ):
        distributed_ctx = nvmath.distributed.get_context()
        if distributed_ctx is None:
            raise RuntimeError(
                "nvmath.distributed has not been initialized. Refer to "
                "https://docs.nvidia.com/cuda/nvmath-python/latest/distributed-apis/runtime.html"
                " for more information."
            )
        if not distributed_ctx.nvshmem_available:
            raise RuntimeError("nvmath.distributed wasn't initialized with NVSHMEM backend")
        self.process_group = distributed_ctx.process_group
        rank = self.process_group.rank
        nranks = self.process_group.nranks

        self.operand = operand = tensor_wrapper.wrap_operand(operand)
        self.options = options = cast(
            RedistributeOptions, utils.check_or_create_options(RedistributeOptions, options, "Redistribute options")
        )
        self.package = operand.name

        is_C = sorted(operand.strides, reverse=True) == list(operand.strides)
        is_F = sorted(operand.strides) == list(operand.strides)

        input_distribution = input_distribution.copy()
        output_distribution = output_distribution.copy()

        # Merge the problem specification across processes to make sure that there are no
        # inconsistencies and to calculate the global shape. Importantly, this also does
        # collective error checking of the Redistribute input parameters, to ensure that all
        # processes fail on error of any one process, thus preventing deadlock.
        problem_spec = _ProblemSpec(
            input_distribution=input_distribution,
            output_distribution=output_distribution,
            shape=tuple(operand.shape),
            operand_dtype=operand.dtype,
            options=_ProblemSpec.Options(options),
            package=self.package,
            memory_space=operand.device,
            global_size=math.prod(operand.shape),
            is_C=is_C,
            is_F=is_F,
            rank=rank,
        )
        if nranks > 1:
            problem_spec = self.process_group.allreduce_object(problem_spec, op=_problem_spec_reducer)
        else:
            # Ensure we error-check with one rank.
            problem_spec = _problem_spec_reducer(problem_spec, problem_spec)
        if isinstance(problem_spec, Exception):
            # There is an error or inconsistency in the problem spec across processes.
            # Note that since this comes from an allreduce, all processes will have
            # received the same exception.
            raise problem_spec

        if problem_spec.is_C:
            self.layout: Final = "C"
        else:
            assert problem_spec.is_F, "Internal Error."  # The reducer is supposed to have detected this
            self.layout: Final = "F"  # type: ignore

        self.operand_dim = len(operand.shape)

        self.logger = options.logger if options.logger is not None else logging.getLogger()

        # Infer the global shape from the input distribution.
        global_shape = problem_spec.input_distribution._global_shape_reduction_epilogue()
        self.logger.info(f"The global shape of the operand is {global_shape}.")

        # Bind can't throw error since the local operand shape was already checked
        # against the distribution in the ProblemSpec reducer.
        input_distribution._bind(global_shape, shape=operand.shape)
        try:
            input_box = cast(Box, input_distribution.to(Box))
        except ConvertDistributionError as e:
            raise TypeError("Redistribute requires distributions compatible with Box distribution") from e

        # Bind output distribution to the global shape and convert to Box if
        # needed (for cuFFTMp).
        # Note that cuFFTMp reshape doesn't support changing the global shape
        # (the output will have the same global shape).
        if isinstance(output_distribution, Box):
            global_shape_out = problem_spec.output_distribution._global_shape_reduction_epilogue()
            # The merged (global) output box must have the same shape as the
            # global input operand.
            if global_shape != global_shape_out:
                raise ValueError(
                    "The global shape derived from the input and output distributions doesn't match: "
                    f"{global_shape} != {global_shape_out}"
                )
        try:
            output_box = cast(Box, output_distribution._bind(global_shape).to(Box))
        except ConvertDistributionError as e:
            raise TypeError("Redistribute requires distributions compatible with Box distribution") from e

        # The global number of elements must be compatible with the global shape.
        if problem_spec.global_size != math.prod(global_shape):
            raise ValueError(f"The global number of elements is incompatible with the inferred global shape {global_shape}")

        # Store the local input and output box.
        self.input_box: Box = input_box
        self.output_box: Box = output_box

        self.operand_data_type = operand.dtype
        # TODO: change to `operand.dtype.itemsize` once operand is StridedMemoryView.
        itemsize = operand.itemsize
        if itemsize not in (4, 8, 16):
            raise ValueError(
                f"Redistribute only supports element sizes in (4, 8, 16) bytes. The operand's element size is {itemsize}"
            )

        self.logger.info(f"The Redistribute data type is {self.operand_data_type}.")

        # Infer execution and memory space.
        execution_device_id: int = distributed_ctx.device_id
        if operand.device_id != "cpu":  # exec space matches the mem space
            self.memory_space = "cuda"
            self.device_id = operand.device_id
            assert operand.device_id == execution_device_id
        else:  # we need to move inputs cpu -> gpu and outputs gpu -> cpu
            self.memory_space = "cpu"
            self.device_id = execution_device_id
        self.execution_space = "cuda"
        self.operand_device_id = operand.device_id
        self.internal_op_package = self._internal_operand_package(self.package)
        stream_holder: StreamHolder = utils.get_or_create_stream(self.device_id, stream, self.internal_op_package)

        if self.memory_space == "cuda" and not operand.is_symmetric_memory:
            raise TypeError("Redistribute requires GPU operand to be on symmetric memory")

        self.logger.info(
            f"The input tensor's memory space is {self.memory_space}, and the execution space "
            f"is {self.execution_space}, with device {self.device_id}."
        )

        self.logger.info(f"The specified stream for the Redistribute ctor is {stream_holder and stream_holder.obj}")

        # Copy the operand to execution_space's device if needed.
        self.operand, self.operand_backup = _alloc_and_copy_to_exespace_mirror_or_identity(
            operand,
            stream_holder,
            self.execution_space,
            self.memory_space,
            self.device_id,
        )
        operand = self.operand
        # Capture operand layout for consistency checks when resetting operands.
        self.operand_layout = TensorLayout(shape=operand.shape, strides=operand.strides)

        self.result_layout: TensorLayout | None = None
        # We'll infer the result layout at plan time.
        self.result_class: DistributedTensor = operand.__class__
        self.result_data_type = operand.dtype

        # Set blocking or non-blocking behavior.
        self.blocking = self.options.blocking is True or self.memory_space == "cpu"
        if self.blocking:
            self.call_prologue = "This call is blocking and will return only after the operation is complete."
        else:
            self.call_prologue = (
                "This call is non-blocking and will return immediately after the operation is launched on the device."
            )

        # Set memory allocator.
        self.allocator = NvshmemMemoryManager(self.device_id, self.logger)

        # Create handle.
        with utils.device_ctx(self.device_id):
            self.handle = cufftMp.create_reshape()

        self.redistribute_planned = False

        # Workspace attributes.
        self.workspace_ptr, self.workspace_size = None, None
        self._workspace_allocated_here = False

        # Attributes to establish stream ordering.
        self.workspace_stream = None
        self.last_compute_event = None

        # Track whether the user has called release_operand(). This flag is
        # checked in _check_valid_operand to prevent execution after the user
        # has released their operand. It is cleared by reset_operand().
        self._operand_released = False

        self.valid_state = True
        self.logger.info("The Redistribute operation has been created.")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.free()

    def _check_valid_redistribute(self, *args, **kwargs):
        """
        Check if Redistribute object is alive and well.
        """
        if not self.valid_state:
            raise InvalidRedistributeState("The Redistribute object cannot be used after resources are free'd")

    def _free_plan_resources(self, exception: Exception | None = None) -> bool:
        """
        Free resources allocated in planning.
        """
        self.redistribute_planned = False
        return True

    def _internal_operand_package(self, package_name):
        return package_name if package_name != "numpy" else "cuda"

    def _allocate_result_operand(self, exec_stream_holder, log_debug):
        if log_debug:
            self.logger.debug("Beginning output (empty) tensor creation...")
            self.logger.debug(
                f"The output tensor shape = {self.result_layout.shape} with strides = "
                f"{self.result_layout.strides} and data type '{self.result_data_type}'."
            )
        result = utils.create_empty_tensor(
            self.result_class,
            self.result_layout.shape,
            self.result_data_type,
            self.device_id,
            exec_stream_holder,
            verify_strides=False,
            strides=self.result_layout.strides,
            symmetric_memory="nvshmem",
            make_symmetric=True,
            logger=self.logger,
        )
        if log_debug:
            self.logger.debug("The output (empty) tensor has been created.")
        return result

    @utils.precondition(_check_valid_redistribute)
    @utils.atomic(_free_plan_resources, method=True)
    def plan(self, stream: AnyStream | None = None):
        """Plan the Redistribute.

        Args:
            stream: {stream}
        """
        log_info = self.logger.isEnabledFor(logging.INFO)

        if self.redistribute_planned:
            self.logger.debug("The Redistribute has already been planned, and redoing the plan is not supported.")
            return

        stream_holder = utils.get_or_create_stream(self.device_id, stream, self.internal_op_package)
        self.workspace_stream = stream_holder.obj

        if log_info:
            self.logger.info("Starting Redistribute planning...")

        lower_input, upper_input = self.input_box
        lower_output, upper_output = self.output_box

        def calculate_redistribute_params(lower, upper, operand, order: Literal["C", "F"]):
            """Calculate shape and strides for input or output of Redistribute."""
            local_shape = tuple(upper[i] - lower[i] for i in range(self.operand_dim))
            if operand is not None:
                # Take the strides from the operand.
                strides = operand.strides
            elif order == "F":
                # This is out=None with F layout.
                strides = _calculate_strides(local_shape, range(self.operand_dim))
            else:
                # This is out=None with C layout.
                strides = _calculate_strides(local_shape, reversed(range(self.operand_dim)))
            return local_shape, strides

        input_local_shape, strides_input = calculate_redistribute_params(lower_input, upper_input, self.operand, self.layout)
        output_local_shape, strides_output = calculate_redistribute_params(lower_output, upper_output, None, self.layout)
        self.result_layout = TensorLayout(shape=output_local_shape, strides=strides_output)

        if self.operand_dim < 3:
            # cufftMp.make_reshape only supports 3D, so we broadcast the local operands.
            N = 3 - self.operand_dim
            lower_input = tuple(lower_input) + (0,) * N
            upper_input = tuple(upper_input) + (1,) * N
            lower_output = tuple(lower_output) + (0,) * N
            upper_output = tuple(upper_output) + (1,) * N

            strides_input = self.operand.reshape(input_local_shape + (1,) * N, copy=False).strides
            if self.layout == "F":
                strides_output = _calculate_strides(output_local_shape + (1,) * N, (0, 1, 2))
            else:
                strides_output = _calculate_strides(output_local_shape + (1,) * N, (2, 1, 0))

        # cuFFTMp only supports decreasing strides. To support increasing strides, we'll
        # pass the required metadata to cuFFTMp with axes transposed (but won't touch
        # the data).
        if self.layout == "F":
            lower_input = tuple(reversed(lower_input))
            upper_input = tuple(reversed(upper_input))
            strides_input = tuple(reversed(strides_input))
            lower_output = tuple(reversed(lower_output))
            upper_output = tuple(reversed(upper_output))
            strides_output = tuple(reversed(strides_output))

        with utils.host_call_ctx(timing=log_info) as elapsed, utils.device_ctx(self.device_id):
            nullptr = 0
            cufftMp.make_reshape(
                self.handle,
                # TODO: change to `operand.dtype.itemsize` once operand is StridedMemoryView
                self.operand.itemsize,
                3,
                lower_input,
                upper_input,
                strides_input,
                lower_output,
                upper_output,
                strides_output,
                nullptr,
                cufftMp.MpCommType.COMM_NONE,
            )
            self.workspace_size = cufftMp.get_reshape_size(self.handle)

        self.redistribute_planned = True

        if log_info and elapsed.data is not None:
            self.logger.info(f"The Redistribute planning phase took {elapsed.data:.3f} ms to complete.")

    def _validate_reset_operand(self, operand) -> DistributedTensor:
        """
        (private) Validate operand for reset_operand performing
        all precondition checks without any side effects.

        This method does **not** mutate any instance state.
        """
        # First wrap operand.
        wrapped = tensor_wrapper.wrap_operand(operand)

        # Check package match.
        package = utils.infer_object_package(wrapped.tensor)
        if self.package != package:
            message = f"Library package mismatch: '{self.package}' => '{package}'"
            raise TypeError(message)

        # Check the dtype.
        utils.check_attribute_match(self.operand_data_type, wrapped.dtype, "data type")

        # In principle, we could support memory_space change,
        # but to handle it properly we need to update self.memory_space and
        # some dependent properties, like self.blocking, which may be error-prone
        # from the user perspective. It would prevent inplace optimizations as well.
        operand_device_id = wrapped.device_id
        if operand_device_id != self.operand_device_id:

            def device_str(device_id: int | Literal["cpu"]) -> str:
                return f"cuda:{device_id}" if isinstance(device_id, int) else f"{device_id}"

            raise ValueError(
                f"The new operand must be on the same device as the original one. "
                f"The new operand's device is {device_str(operand_device_id)}, "
                f"the original device is {device_str(self.operand_device_id)}"
            )

        if self.memory_space == "cuda" and not wrapped.is_symmetric_memory:
            raise TypeError("Redistribute requires GPU operand to be on symmetric memory")

        # The plan was made for a specific input box and strides, so the new operand must
        # match.
        if wrapped.shape != self.operand_layout.shape:
            raise ValueError(
                f"The shape of the new operand ({wrapped.shape}) does not match "
                f"the original shape ({self.operand_layout.shape})."
            )
        if wrapped.strides != self.operand_layout.strides:
            raise ValueError(
                f"The strides of the new operand ({wrapped.strides}) do not match "
                f"the original strides ({self.operand_layout.strides})."
            )
        return wrapped

    def _apply_reset_operand(self, operand, stream: AnyStream | None, operand_wrapped: DistributedTensor | None = None):
        """
        (private) Perform the actual operand swap.

        Receives the raw (unwrapped) user operand. For the cross-space
        (CPU) path the operand is wrapped if not already provided via
        *operand_wrapped*; for the same-space (GPU) path the raw tensor
        is stored directly.
        """
        if self.memory_space == "cpu":
            stream_holder = utils.get_or_create_stream(self.device_id, stream, self.internal_op_package)
            if operand_wrapped is None:
                operand_wrapped = tensor_wrapper.wrap_operand(operand)
            if self._operand_released:
                new_mirror = operand_wrapped.to(self.device_id, stream_holder, symmetric_memory="nvshmem")
                self.operand.tensor = new_mirror.tensor
            else:
                self.operand.copy_(operand_wrapped, stream_holder=stream_holder)
            self.operand_backup.tensor = operand_wrapped.tensor  # type: ignore[union-attr]
        else:
            self.operand.tensor = operand

        self._operand_released = False

    @utils.precondition(_check_valid_redistribute)
    def reset_operand(self, operand, *, stream: AnyStream | None = None):
        """
        Reset the operand held by this :class:`Redistribute` instance. This method is used
        to provide a new operand for execution.

        Args:
            operand: A tensor (ndarray-like object) compatible with the previous one.
                The new operand is considered compatible if all the following properties
                match with the previous one:

                - The operand distribution.
                - The package that the new operand belongs to.
                - The dtype of the new operand.
                - The shape and strides of the new operand.
                - The memory space of the new operand (CPU or GPU).
                - The device that new operand belongs to if it is on GPU.

            stream: {stream}

        .. seealso::
            :meth:`release_operand`

        Examples:

            >>> import cupy as cp
            >>> import nvmath.distributed

            Get process group used to initialize nvmath.distributed (for information on
            initializing nvmath.distributed, you can refer to the documentation or to the
            Redistribute examples in `nvmath/examples/distributed/redistribute
            <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute>`_):

            >>> process_group = nvmath.distributed.get_context().process_group
            >>> nranks = process_group.nranks

            Create a 3-D complex128 ndarray on GPU symmetric memory, initially partitioned
            on the X axis (the global shape is (128, 128, 128)):

            >>> shape = 128 // nranks, 128, 128
            >>> dtype = cp.complex128
            >>> a = nvmath.distributed.allocate_symmetric_memory(shape, cp, dtype=dtype)
            >>> a[:] = cp.random.rand(*shape) + 1j * cp.random.rand(*shape)

            Create a Redistribute object as a context manager

            >>> from nvmath.distributed.distribution import Redistribute
            >>> with Redistribute(a, in_distribution, out_distribution) as r:
            ...     # Plan the Redistribute
            ...     r.plan()
            ...
            ...     # Execute the Redistribute to get the first result.
            ...     result1 = r.execute()
            ...
            ...     # Reset the operand to a new CuPy ndarray.
            ...     b = nvmath.distributed.allocate_symmetric_memory(shape, cp, dtype=dtype)
            ...     b[:] = cp.random.rand(*shape) + 1j * cp.random.rand(*shape)
            ...     r.reset_operand(b)
            ...
            ...     # Execute to get the new result corresponding to the updated operand.
            ...     result2 = r.execute()

            With :meth:`reset_operand`, minimal overhead is achieved as problem
            specification and planning are only performed once.

            For the particular example above, explicitly calling :meth:`reset_operand` is
            equivalent to updating the operand in-place, i.e, replacing
            ``r.reset_operand(b)`` with ``a[:]=b``. Note that updating the operand in-place
            should be adopted with caution as it can only yield the expected result and
            incur no additional copies under the additional constraints below:

            - The operand's distribution is the same.

            For more details, please refer to `inplace update example
            <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute/example05_stateful_reset_inplace.py>`_.
        """
        self.logger.info("Resetting operand...")

        if operand is None:
            raise ValueError("reset_operand() requires a valid operand.")

        operand_wrapped = self._validate_reset_operand(operand)
        self._apply_reset_operand(operand, stream, operand_wrapped=operand_wrapped)
        self.logger.info(f"The reset operand shape = {self.operand_layout.shape}, and strides = {self.operand_layout.strides}.")
        self.logger.info("The operand has been reset to the specified operand.")

    def reset_operand_unchecked(self, operand, *, stream: AnyStream | None = None):
        """
        {reset_operand_unchecked}
        """
        self._apply_reset_operand(operand, stream)

    @utils.precondition(_check_valid_redistribute)
    def release_operand(self):
        """
        {release_operand}
        """
        if self._operand_released:
            self.logger.info("Operand has already been released; nothing to do.")
            return

        # Keep the DistributedTensor wrappers alive and only release the
        # internal tensor reference. This is useful when
        # resetting operands subsequently because it can reuse the
        # existing wrappers, saving overhead.
        if self.memory_space == self.execution_space:
            # Same-space (GPU input): self.operand is the user's tensor.
            self.operand.tensor = None
        else:
            # Cross-space (CPU input): self.operand_backup is the user's tensor,
            # self.operand is an internal nvshmem device mirror.
            # Release user reference and free the nvshmem mirror.
            # Cross-space execution is always blocking, so no synchronization
            # is needed before freeing.
            self.operand_backup.tensor = None
            with utils.device_ctx(self.device_id):
                self.operand.free_symmetric()
            self.operand.tensor = None

        self._operand_released = True
        self.logger.info("User-provided operand has been released.")

    def _check_planned(self, *args, **kwargs):
        """ """
        what = kwargs["what"]
        if not self.redistribute_planned:
            raise RuntimeError(f"{what} cannot be performed before plan() has been called.")

    def _check_valid_operand(self, *args, **kwargs):
        """ """
        what = kwargs["what"]
        if self._operand_released:
            raise RuntimeError(
                f"{what} cannot be performed after the operand has been released. Use reset_operand() to provide a new "
                f"operand before performing the {what.lower()}."
            )

    def _free_workspace_memory(self, exception: Exception | None = None) -> bool:
        """
        Free workspace by releasing the MemoryPointer object.
        """
        if self.workspace_ptr is None:
            return True

        with utils.device_ctx(self.device_id):
            # Calling nvshmem_free on memory that's still in use is not safe
            # (nvshmem_free is not stream-ordered), so we need to wait for the
            # computation to finish.
            if self.workspace_stream is not None:
                self.workspace_stream.sync()
            self.workspace_ptr.free()
        self.workspace_ptr = None
        self.logger.debug("[_free_workspace_memory] The workspace has been released.")

        return True

    @utils.precondition(_check_valid_redistribute)
    @utils.precondition(_check_planned, "Workspace memory allocation")
    @utils.atomic(_free_workspace_memory, method=True)
    def _allocate_workspace_memory(self, stream_holder):
        """
        Allocate workspace memory using the specified allocator.
        """

        assert self._workspace_allocated_here is False, "Internal Error."

        self.logger.debug("Allocating workspace for performing the Redistribute...")
        with utils.device_ctx(self.device_id), stream_holder.ctx:
            try:
                self.workspace_ptr = self.allocator.memalloc(self.workspace_size)
                self._workspace_allocated_here = True
            except TypeError as e:
                message = (
                    "The method 'memalloc' in the allocator object must conform to the interface in the "
                    "'BaseCUDAMemoryManager' protocol."
                )
                raise TypeError(message) from e

        self.workspace_stream = stream_holder.obj
        self.logger.debug(
            f"Finished allocating device workspace of size {formatters.MemoryStr(self.workspace_size)} in the context "
            f"of stream {self.workspace_stream}."
        )

    def _allocate_workspace_memory_perhaps(self, stream_holder):
        """
        Allocate workspace memory using the specified allocator, if it hasn't already been
        done.
        """
        if self.execution_space != "cuda" or self.workspace_ptr is not None:
            return

        return self._allocate_workspace_memory(stream_holder)

    @utils.precondition(_check_valid_redistribute)
    def _free_workspace_memory_perhaps(self, release_workspace):
        """
        Free workspace memory if if 'release_workspace' is True.
        """
        if not release_workspace:
            return

        # Establish ordering wrt the computation and free workspace if it's more than the
        # specified cache limit.
        if self.last_compute_event is not None:
            with utils.device_ctx(self.device_id):
                self.workspace_stream.wait(self.last_compute_event)
            self.logger.debug("Established ordering with respect to the computation before releasing the workspace.")
            self.last_compute_event = None

        self.logger.debug("[_free_workspace_memory_perhaps] The workspace memory will be released.")
        self._free_workspace_memory()

        return True

    def _release_workspace_memory_perhaps(self, exception: Exception | None = None) -> bool:
        """
        Free workspace memory if it was allocated in this call
        (self._workspace_allocated_here == True) when an exception occurs.
        """
        release_workspace = self._workspace_allocated_here
        self.logger.debug(
            f"[_release_workspace_memory_perhaps] The release_workspace flag is set to {release_workspace} based upon "
            "the value of 'workspace_allocated_here'."
        )
        self._free_workspace_memory_perhaps(release_workspace)
        self._workspace_allocated_here = False
        return True

    @utils.precondition(_check_valid_redistribute)
    @utils.precondition(_check_planned, "Execution")
    @utils.precondition(_check_valid_operand, "Execution")
    @utils.atomic(_release_workspace_memory_perhaps, method=True)
    def execute(self, stream: AnyStream | None = None, release_workspace: bool = False, sync_symmetric_memory: bool = True):
        """
        Execute the Redistribute operation.

        Args:
            stream: {stream}

            release_workspace: A value of `True` specifies that the Redistribute object
                should release workspace memory back to the symmetric memory pool on
                function return, while a value of `False` specifies that the object
                should retain the memory. This option may be set to `True` if the
                application performs other operations that consume a lot of memory between
                successive calls to the (same or different) :meth:`execute` API, but incurs
                an overhead due to obtaining and releasing workspace memory from and
                to the symmetric memory pool on every call. The default is `False`.
                **NOTE: All processes must use the same value or the application can
                deadlock.**

            sync_symmetric_memory: {sync_symmetric_memory}

        Returns:
            The redistributed operand, which remains on the same device and utilizes the
            same package as the input operand. For GPU operands, the result will be in
            symmetric memory and the user is responsible for explicitly deallocating it
            (for example, using ``nvmath.distributed.free_symmetric_memory(tensor)``).
        """

        log_info = self.logger.isEnabledFor(logging.INFO)
        log_debug = self.logger.isEnabledFor(logging.DEBUG)

        stream_holder: StreamHolder = utils.get_or_create_stream(self.device_id, stream, self.internal_op_package)

        # Allocate workspace if needed.
        self._allocate_workspace_memory_perhaps(stream_holder)

        # Allocate output operand.
        with utils.device_ctx(self.device_id):
            result = self._allocate_result_operand(stream_holder, log_debug)

        if log_info:
            self.logger.info("Starting Redistribute...")
            self.logger.info(f"{self.call_prologue}")

        with utils.cuda_call_ctx(stream_holder, self.blocking, timing=log_info) as (
            self.last_compute_event,
            elapsed,
        ):
            raw_workspace_ptr = utils.get_ptr_from_memory_pointer(self.workspace_ptr)
            if sync_symmetric_memory:
                nvshmem.sync_all_on_stream(stream_holder.ptr)
                if log_info:
                    self.logger.info(
                        "sync_symmetric_memory is enabled (this may incur redundant multi-GPU "
                        "synchronization, please refer to the documentation for more information)"
                    )
            elif log_info:
                self.logger.info("sync_symmetric_memory is disabled")
            cufftMp.exec_reshape_async(
                self.handle, result.data_ptr, self.operand.data_ptr, raw_workspace_ptr, stream_holder.ptr
            )

        if log_info and elapsed.data is not None:
            self.logger.info(f"The Redistribute took {elapsed.data:.3f} ms to complete.")

        # Establish ordering wrt the computation and free workspace if it's more than the
        # specified cache limit.
        self._free_workspace_memory_perhaps(release_workspace)

        # reset workspace allocation tracking to False at the end of the methods where
        # workspace memory is potentially allocated. This is necessary to prevent any
        # exceptions raised before method entry from using stale tracking values.
        self._workspace_allocated_here = False

        if self.memory_space == "cpu":
            out = result.to("cpu", stream_holder=stream_holder).tensor
            with utils.device_ctx(self.device_id):
                # Since the execution when user passes CPU operands is blocking, it's
                # safe to call nvshmem_free here without additional synchronization.
                result.free_symmetric()
        else:
            out = result.tensor

        return out

    def free(self):
        """Free Redistribute resources.

        It is recommended that the :class:`Redistribute` object be used within a context,
        but if it's not possible then this method must be called explicitly to ensure that
        the Redistribute resources (especially internal library objects) are properly
        cleaned up.
        """

        if not self.valid_state:
            return

        try:
            # Future operations on the workspace stream should be ordered after the
            # computation.
            if self.last_compute_event is not None and self.workspace_stream is not None:
                with utils.device_ctx(self.device_id):
                    self.workspace_stream.wait(self.last_compute_event)
                self.last_compute_event = None

            self._free_workspace_memory()

            with utils.device_ctx(self.device_id):
                if self.handle is not None:
                    cufftMp.destroy_reshape(self.handle)
                    self.handle = None

                if self.memory_space == "cpu" and not self._operand_released:
                    # In this case, self.operand is an internal GPU operand owned by
                    # Redistribute. Since the execution when user passes CPU operands is
                    # blocking, it's safe to call nvshmem_free here without additional
                    # synchronization.
                    self.operand.free_symmetric()

            # Set all attributes to None except for logger and valid_state
            _keep = {"logger", "valid_state"}
            for attr in list(vars(self)):
                if attr not in _keep:
                    setattr(self, attr, None)

        except Exception as e:
            self.logger.critical("Internal error: only part of the Redistribute object's resources have been released.")
            self.logger.critical(str(e))
            raise e
        finally:
            self.valid_state = False

        self.logger.info("The Redistribute object's resources have been released.")


@utils.docstring_decorator(SHARED_REDISTRIBUTE_DOCUMENTATION, skip_missing=False)
def redistribute(
    operand,
    /,
    input_distribution: Distribution,
    output_distribution: Distribution,
    *,
    sync_symmetric_memory: bool = True,
    options: RedistributeOptions | dict[str, Any] | None = None,
    stream: AnyStream | None = None,
):
    r"""
    redistribute({function_signature})

    Perform a redistribute operation on the provided operand to change its distribution
    across processes.

    .. versionchanged:: 1.0
         This function was previously ``nvmath.distributed.reshape.reshape``.

    Args:
        operand: {operand}
            {operand_admonitions}

        input_distribution: {input_distribution}

        output_distribution: {output_distribution}

        sync_symmetric_memory: {sync_symmetric_memory}

        options: {options}

        stream: {stream}

    Returns:
        A tensor that remains on the same device and belongs to the same package as
        the input operand, with shape according to output_box.

    .. seealso::
        :class:`Redistribute`.

    Examples:

        >>> import cupy as cp
        >>> import nvmath.distributed

        Get process group used to initialize nvmath.distributed (for information on
        initializing nvmath.distributed, you can refer to the documentation or to the
        Redistribute examples in `nvmath/examples/distributed/redistribute
        <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute>`_):

        >>> process_group = nvmath.distributed.get_context().process_group
        >>> rank = process_group.rank

        Let's create a 3D floating-point ndarray on GPU, distributed across a certain number
        of processes, according to the Slab distribution with partitioning on the X axis.

        >>> shape = Slab.X.shape(rank, (global_shape))

        Redistribute uses the NVSHMEM PGAS model, which requires GPU operands to be on the
        symmetric heap:

        >>> a = nvmath.distributed.allocate_symmetric_memory(shape, cp)
        >>> a[:] = cp.random.rand(*shape)

        With Redistribute, we will change how the ndarray is distributed, by specifying
        the input distribution and the desired output distribution. In this example,
        we redistribute from Slab.X to Slab.Y.

        Perform the redistribute operation using :func:`redistribute`:

        >>> r = nvmath.distributed.distribution.redistribute(a, Slab.X, Slab.Y)

        See :class:`RedistributeOptions` for the complete list of available options.

        The package current stream is used by default, but a stream can be explicitly
        provided to the Redistribute operation. This can be done if the Redistribute
        operand is computed on a different stream, for example:

        >>> s = cp.cuda.Stream()
        >>> with s:
        ...     a = nvmath.distributed.allocate_symmetric_memory(shape, cp)
        ...     a[:] = cp.random.rand(*shape)
        >>> r = nvmath.distributed.distribution.redistribute(a, Slab.X, Slab.Y, stream=s)

        The operation above runs on stream `s` and is ordered with respect to the input
        computation.

        Create a NumPy ndarray on the CPU.

        >>> import numpy as np
        >>> b = np.random.rand(*shape)

        Provide the NumPy ndarray to :func:`redistribute`, with the result also being
        a NumPy ndarray:

        >>> r = nvmath.distributed.distribution.redistribute(b, Slab.X, Slab.Y)

    Notes:
        - This function is a convenience wrapper around :class:`Redistribute` and is
          specifically meant for *single* use. The same computation can be performed
          with the stateful API.

    Further examples can be found in the `nvmath/examples/distributed/redistribute
    <https://github.com/NVIDIA/nvmath-python/tree/main/examples/distributed/redistribute>`_
    directory.
    """

    with Redistribute(operand, input_distribution, output_distribution, options=options, stream=stream) as redistribute_obj:
        # Plan the Redistribute.
        redistribute_obj.plan(stream=stream)

        # Execute the Redistribute.
        result = redistribute_obj.execute(sync_symmetric_memory=sync_symmetric_memory, stream=stream)

    return result
