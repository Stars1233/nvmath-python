# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import contextlib
import logging

import pytest

from nvmath.bindings import cusolverDn
from nvmath.internal.tensor_wrapper import maybe_register_package
from nvmath.linalg.generic import DirectSolver, DirectSolverOptions, ExecutionCUDA, direct_solver

from ....helpers import requires_cupy, requires_torch
from .operand_utils import (
    copy_operand,
    create_inplace_operands,
    inplace_update_operand,
    make_batch_with_overlapping_storage,
    make_explicit_batch_with_mismatched_strides,
    make_unsupported_lhs_layout,
    make_unsupported_rhs_layout,
    operand_was_overwritten,
    operands_alias,
)
from .params import BATCH_FORMATS
from .solver_utils import create_solver_operands, verify_solution


def check_solver_with_configuration(
    framework,
    n,
    nrhs,
    *,
    options=None,
    execution=None,
    batch_shape=None,
    dtype="float32",
    atol=None,
    rtol=None,
):
    use_cuda = framework in {"cupy", "torch"}
    if batch_shape is not None:
        lhs_batch_format = rhs_batch_format = "implicit"
    else:
        lhs_batch_format = rhs_batch_format = None
    a, b = create_solver_operands(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )

    result = direct_solver(a, b, options=options, execution=execution)
    verify_solution(a, b, result, atol=atol, rtol=rtol)
    return result


class TestDirectSolverOptions:
    """
    This set of tests checks DirectSolver's options.
    """

    def test_logger(self):
        """
        Tests if specifying a custom logger works as expected.
        """
        import logging
        from io import StringIO

        log_stream = StringIO()
        logger = logging.Logger("test_logger", level=logging.DEBUG)
        logger.addHandler(logging.StreamHandler(log_stream))
        options = DirectSolverOptions(logger=logger)
        check_solver_with_configuration("numpy", 4, 3, options=options)
        assert len(log_stream.getvalue()) > 0

    @requires_torch
    def test_cusolver_handle(self):
        """
        Tests if specifying a custom cusolver handle works as expected.
        """
        # cusolver is used when input operands are not batched
        try:
            handle = cusolverDn.create()
            options = DirectSolverOptions(handle=handle)
            check_solver_with_configuration("torch", 4, 3, options=options)
        finally:
            cusolverDn.destroy(handle)

    @requires_cupy
    @pytest.mark.parametrize("blocking", [True, "auto"])
    def test_blocking(self, blocking):
        """
        Tests if specifying a custom blocking option works as expected.
        """
        options = DirectSolverOptions(blocking=blocking)
        check_solver_with_configuration("cupy", 4, 3, options=options)

    def test_invalid_blocking(self):
        """
        Tests if specifying an invalid blocking option raises an error
        """
        with pytest.raises(ValueError, match="The value specified for blocking must be either True or 'auto'."):
            DirectSolverOptions(blocking="invalid")

    @requires_torch
    def test_allocator(self):
        """
        Tests if manually specifying an allocator works
        """
        maybe_register_package("torch")
        from nvmath.memory import _MEMORY_MANAGER

        allocator = _MEMORY_MANAGER["torch"](0, logging.getLogger())
        options = DirectSolverOptions(allocator=allocator)
        check_solver_with_configuration("torch", 10, 1, options=options)

    @requires_torch
    @requires_cupy
    def test_different_allocator(self):
        """
        Tests if ``direct_solver`` with torch tensors can be performed with cupy allocator
        """
        maybe_register_package("cupy")
        from nvmath.memory import _MEMORY_MANAGER

        allocator = _MEMORY_MANAGER["cupy"](0, logging.getLogger())
        options = DirectSolverOptions(allocator=allocator)
        check_solver_with_configuration("torch", 4, 3, options=options, batch_shape=(2, 3))

    @requires_torch
    def test_custom_allocator(self):
        """
        Checks if custom allocator is actually used
        """
        maybe_register_package("torch")
        from nvmath.memory import _MEMORY_MANAGER

        class MockAllocator(_MEMORY_MANAGER["torch"]):
            def __init__(self, device_id, logger):
                super().__init__(device_id, logger)
                self.counter = 0

            def memalloc_async(self, size, stream, *args, **kwargs):
                self.counter += 1
                return super().memalloc_async(size, stream, *args, **kwargs)

        allocator = MockAllocator(0, logging.getLogger())
        options = DirectSolverOptions(allocator=allocator)
        check_solver_with_configuration("torch", 6, 2, options=options)
        assert allocator.counter > 0

    def test_invalid_allocator(self):
        """
        Tests if reasonable error is produced when an invalid allocator is specified
        """
        with pytest.raises(TypeError):
            DirectSolverOptions(allocator="Hello, I'm a real allocator!")

    @requires_torch
    def test_uninstantiated_allocator(self):
        """
        Tests if reasonable error is produced when an allocator class is provided
        instead of an instance
        """
        maybe_register_package("torch")
        from nvmath.memory import _MEMORY_MANAGER

        with pytest.raises(TypeError):
            options = DirectSolverOptions(allocator=_MEMORY_MANAGER["torch"])
            check_solver_with_configuration("torch", 10, 1, options=options)

    @requires_torch
    @BATCH_FORMATS
    @pytest.mark.parametrize("use_cuda", (True, False))
    @pytest.mark.parametrize("inplace_operand", ("a", "b"))
    def test_inplace_layout_requirements(self, use_cuda, batch_shape, batch_format, inplace_operand):
        """
        Tests that inplace layout restrictions apply only to GPU inputs.
        """
        a, b = create_solver_operands(
            "torch",
            "float32",
            4,
            2,
            use_cuda=use_cuda,
            batch_shape=batch_shape,
            lhs_batch_format=batch_format,
            rhs_batch_format=batch_format,
        )
        if inplace_operand == "a":
            options = {"inplace_a": True}
            a = make_unsupported_lhs_layout(a)
            message = "must have either column-major or row-major layout"
        else:
            options = {"inplace_b": True}
            b = make_unsupported_rhs_layout(b)
            message = "RHS operands must have column-major layout"

        # GPU inplace aliases the user operand directly, so layout must be
        # solver-compatible. CPU inplace copies through an internal GPU buffer.
        if use_cuda:
            context = pytest.raises(ValueError, match=message)
        else:
            context = contextlib.nullcontext()

        with context:
            direct_solver(a, b, options=options)

    @requires_torch
    @pytest.mark.parametrize("use_cuda", (True, False))
    @pytest.mark.parametrize("inplace_operand", ("a", "b"))
    def test_inplace_explicit_batch_layout_consistency(self, use_cuda, inplace_operand):
        """
        Tests that explicit-batch layout consistency is required only for GPU inputs.
        """
        a, b = create_solver_operands(
            "torch",
            "float32",
            4,
            2,
            use_cuda=use_cuda,
            batch_shape=(2,),
            lhs_batch_format="explicit",
            rhs_batch_format="explicit",
        )
        if inplace_operand == "a":
            options = {"inplace_a": True}
            a = make_explicit_batch_with_mismatched_strides(a)
            message = "strides of the LHS must be the same for all batches"
        else:
            options = {"inplace_b": True}
            b = make_explicit_batch_with_mismatched_strides(b)
            message = "strides of the RHS must be the same for all batches"

        # CPU inputs are copied to internal GPU buffers, so per-batch input
        # layouts may differ. GPU inplace uses the input batches directly.
        if use_cuda:
            context = pytest.raises(ValueError, match=message)
        else:
            context = contextlib.nullcontext()

        with context:
            direct_solver(a, b, options=options)

    @requires_torch
    @pytest.mark.parametrize("use_cuda", (True, False))
    @pytest.mark.parametrize("batch_format", ("explicit", "implicit"))
    @pytest.mark.parametrize("inplace_operand", ("a", "b"))
    def test_inplace_rejects_batches_with_overlapping_storage(self, use_cuda, batch_format, inplace_operand):
        """
        Tests that inplace rejects batched operands whose entries alias storage.
        """
        a, b = create_solver_operands(
            "torch",
            "float32",
            4,
            2,
            use_cuda=use_cuda,
            batch_shape=(2,),
            lhs_batch_format=batch_format,
            rhs_batch_format=batch_format,
        )
        if inplace_operand == "a":
            options = {"inplace_a": True}
            a = make_batch_with_overlapping_storage(a)
            message = "each batch in LHS must not share overlapping memory"
        else:
            options = {"inplace_b": True}
            b = make_batch_with_overlapping_storage(b)
            message = "each batch in RHS must not share overlapping memory"

        with pytest.raises(ValueError, match=message):
            direct_solver(a, b, options=options)

    @requires_torch
    @pytest.mark.parametrize("inplace_a", (True, False))
    @pytest.mark.parametrize("inplace_b", (True, False))
    @pytest.mark.parametrize("reset_method", ("checked", "unchecked"))
    @pytest.mark.parametrize("use_cuda", (True, False))
    @BATCH_FORMATS
    def test_inplace_reset_semantics(self, inplace_a, inplace_b, reset_method, use_cuda, batch_shape, batch_format):
        """
        Tests representative reset semantics for inplace options.
        """
        if not inplace_a and not inplace_b:
            pytest.skip("No inplace option was requested.")

        a0, b0 = create_inplace_operands(
            "torch",
            batch_shape,
            batch_format,
            batch_format,
            use_cuda=use_cuda,
            lhs_layout="padded-C",
            rhs_layout="padded-F",
        )
        # When inplace is CPU-only, the operands to be reset can have any layout.
        a1, b1 = create_inplace_operands(
            "torch",
            batch_shape,
            batch_format,
            batch_format,
            use_cuda=use_cuda,
            lhs_layout="padded-C" if use_cuda else "C",
            rhs_layout="padded-F" if use_cuda else "F",
        )
        a0_ref = copy_operand(a0)
        a1_ref = copy_operand(a1)
        b0_ref = copy_operand(b0)
        b1_ref = copy_operand(b1)

        options = DirectSolverOptions(inplace_a=inplace_a, inplace_b=inplace_b)

        with DirectSolver(a0, b0, options=options) as solver:
            solver.plan()
            solver.factorize()
            x0 = solver.solve()
            verify_solution(a0_ref, b0_ref, x0)

            assert operand_was_overwritten(a0, a0_ref) == inplace_a
            assert operand_was_overwritten(b0, b0_ref) == inplace_b
            assert operands_alias(x0, b0) == inplace_b

            solver.release_operands()
            if reset_method == "checked":
                solver.reset_operands(a=a1, b=b1)
            else:
                solver.reset_operands_unchecked(a=a1, b=b1)

            solver.factorize()
            x1 = solver.solve()

            verify_solution(a1_ref, b1_ref, x1)
            assert operand_was_overwritten(a1, a1_ref) == inplace_a
            assert operand_was_overwritten(b1, b1_ref) == inplace_b
            assert operands_alias(x1, b1) == inplace_b

    @requires_torch
    @BATCH_FORMATS
    @pytest.mark.parametrize("use_cuda", (True, False))
    @pytest.mark.parametrize("inplace_a", (True, False))
    def test_direct_update_lhs(self, use_cuda, inplace_a, batch_shape, batch_format):
        """
        Tests that direct updates of LHS operands work as expected.
        """
        a0, b0 = create_inplace_operands("torch", batch_shape, batch_format, batch_format, use_cuda=use_cuda)
        a1, _ = create_inplace_operands("torch", batch_shape, batch_format, batch_format, use_cuda=use_cuda)

        a0_ref = copy_operand(a0)
        a1_ref = copy_operand(a1)
        b0_ref = copy_operand(b0)

        with DirectSolver(a0, b0, options={"inplace_a": inplace_a}) as solver:
            solver.plan()
            inplace_update_operand(a0, a1)
            solver.factorize()
            x = solver.solve()

            if inplace_a and use_cuda:
                verify_solution(a1_ref, b0_ref, x)
            else:
                # When the execution buffer is not the input operand,
                # the solver object still sees a0 for the first factorize call.
                # Therefore we can verify the solution using the original a0 operand
                verify_solution(a0_ref, b0_ref, x)

                # After the first factorize call, the solver object sees the execution
                # buffer as outdated and a new factorize call will perform a new copy
                # of the input operand to the execution buffer. Therefore if we update
                # the input operand after the first factorize call and then factorize
                # again, we will see the updated values in the solution.
                inplace_update_operand(a0, a1)
                solver.factorize()
                x = solver.solve()
                verify_solution(a1_ref, b0_ref, x)

    @requires_torch
    @BATCH_FORMATS
    @pytest.mark.parametrize("use_cuda", (True, False))
    @pytest.mark.parametrize("inplace_b", (True, False))
    def test_direct_update_rhs(self, use_cuda, inplace_b, batch_shape, batch_format):
        """
        Tests that direct updates of RHS operands work as expected.
        """
        a0, b0 = create_inplace_operands("torch", batch_shape, batch_format, batch_format, use_cuda=use_cuda)
        _, b1 = create_inplace_operands("torch", batch_shape, batch_format, batch_format, use_cuda=use_cuda)

        a0_ref = copy_operand(a0)
        b0_ref = copy_operand(b0)
        b1_ref = copy_operand(b1)

        with DirectSolver(a0, b0, options={"inplace_b": inplace_b}) as solver:
            solver.plan()
            solver.factorize()
            inplace_update_operand(b0, b1)
            x = solver.solve()
            if inplace_b and use_cuda:
                verify_solution(a0_ref, b1_ref, x)
            else:
                # When the execution buffer is not the input operand,
                # the solver object still sees b0 for the first factorize call.
                # Therefore we can verify the solution using the original b0 operand
                verify_solution(a0_ref, b0_ref, x)

                # After the first solve call, the solver object sees the execution
                # buffer as outdated and a new solve call will perform a new copy
                # of the input operand to the execution buffer. Therefore if we update
                # the input operand after the first solve call and then solve again,
                # we will see the updated values in the solution.
                inplace_update_operand(b0, b1)
                x = solver.solve()
                verify_solution(a0_ref, b1_ref, x)


class TestExecution:
    """
    This set of tests checks DirectSolver's execution options.
    """

    def test_device_id(self):
        """
        Tests if specifying a device id works as expected.
        """
        options = ExecutionCUDA(device_id=0)
        check_solver_with_configuration("numpy", 10, 1, execution=options)

    def test_invalid_device_id(self):
        """
        Tests if specifying a negative execution device id raises an error for CPU operands.
        """
        options = ExecutionCUDA(device_id=-1)
        with pytest.raises(ValueError, match="device_id must be >= 0, got -1"):
            check_solver_with_configuration("numpy", 4, 3, execution=options)
