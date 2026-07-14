# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import importlib
import math
from collections.abc import Sequence

import nvmath
from nvmath.internal import tensor_wrapper
from nvmath.internal.utils import infer_object_package

from ....helpers import sequence_aware
from ...utils import assert_tensors_equal, sample_matrix


@sequence_aware()
def check_rhs_solution_consistency(x, y):
    x_wrapped = tensor_wrapper.wrap_operand(x)
    y_wrapped = tensor_wrapper.wrap_operand(y)

    assert x_wrapped.name == y_wrapped.name, "The packages of the operands must be the same"
    assert x_wrapped.device_id == y_wrapped.device_id, "The device ids of the operands must be the same"
    assert x_wrapped.dtype == y_wrapped.dtype, "The dtypes of the operands must be the same"
    assert x_wrapped.shape == y_wrapped.shape, "The shapes of the operands must be the same"


def verify_solution(A, B, x, atol=None, rtol=None):
    # Make sure the solution x always has the same format as the RHS B
    check_rhs_solution_consistency(B, x)

    if isinstance(A, Sequence):
        # A is explicitly batched
        if isinstance(B, Sequence):
            assert isinstance(x, Sequence), "When B is explicitly batched, the result must be explicitly batched"
            for a, b, xi in zip(A, B, x, strict=True):
                assert_tensors_equal(a @ xi, b, atol=atol, rtol=rtol)
        else:
            # B is implicitly batched
            assert B.ndim >= 3, "When B is implicitly batched, it must be at least 3D"
            B = B.reshape(-1, B.shape[-2], B.shape[-1])
            x = x.reshape(-1, x.shape[-2], x.shape[-1])
            assert len(A) == len(B) == len(x), "The batch sizes must match"
            for a, b, xi in zip(A, B, x, strict=True):
                assert_tensors_equal(a @ xi, b, atol=atol, rtol=rtol)
    else:
        if A.ndim == 2:
            # Non-batched A
            assert_tensors_equal(A @ x, B, atol=atol, rtol=rtol)
        else:
            # Implicitly batched A
            if isinstance(B, Sequence):
                # B is explicitly batched
                A = A.reshape(-1, A.shape[-2], A.shape[-1])
                assert len(A) == len(B) == len(x), "The batch sizes must match"
                for a, b, xi in zip(A, B, x, strict=True):
                    assert_tensors_equal(a @ xi, b, atol=atol, rtol=rtol)
            else:
                # B is implicitly batched
                assert_tensors_equal(A @ x, B, atol=atol, rtol=rtol)


def make_well_conditioned_matrix(framework, dtype, n, use_cuda, cond=10):
    qs = []
    for _ in range(2):
        a = sample_matrix(framework, dtype, (n, n), use_cuda)
        if "complex" in dtype:
            a += 1.0j * sample_matrix(framework, dtype, (n, n), use_cuda)
        xp = importlib.import_module(infer_object_package(a))
        q, _ = xp.linalg.qr(a)
        qs.append(q)

    if framework == "torch":
        s = xp.linspace(1.0, 1.0 / cond, n, device=a.device, dtype=a.dtype)
    else:
        s = xp.linspace(1.0, 1.0 / cond, n, dtype=dtype)
    mat = qs[0] @ xp.diag(s) @ qs[1].T.conj()
    return mat


def create_lhs(framework, dtype, n, use_cuda, batch_shape=None, batch_format=None):
    if batch_format == "explicit":
        batch_count = math.prod(batch_shape)
        return [make_well_conditioned_matrix(framework, dtype, n, use_cuda) for _ in range(batch_count)]

    if batch_format is None:
        assert batch_shape is None, "If batch_format is None, batch_shape must be None"
        return make_well_conditioned_matrix(framework, dtype, n, use_cuda)
    elif batch_format == "implicit":
        assert batch_shape is not None
        shape = (*batch_shape, n, n)
        n_batch = math.prod(batch_shape)
        a_empty = sample_matrix(framework, dtype, (n_batch, n, n), use_cuda)
        for i in range(n_batch):
            a_empty[i] = make_well_conditioned_matrix(framework, dtype, n, use_cuda)
        return a_empty.reshape(shape)
    else:
        raise ValueError(f"Invalid batch format: {batch_format}")


def create_rhs(framework, dtype, n, nrhs, use_cuda, batch_shape=None, batch_format=None):
    if batch_format == "explicit":
        assert batch_shape is not None
        batch_count = math.prod(batch_shape)
        return [create_rhs(framework, dtype, n, nrhs, use_cuda) for _ in range(batch_count)]

    if batch_format is None:
        assert batch_shape is None, "If batch_format is None, batch_shape must be None"
        if nrhs is None:
            shape = (n,)
        else:
            shape = (n, nrhs)
    elif batch_format == "implicit":
        assert batch_shape is not None
        if nrhs is None:
            nrhs = 1
        shape = (*batch_shape, n, nrhs)
    else:
        raise ValueError(f"Invalid batch format: {batch_format}")
    b = sample_matrix(framework, dtype, shape, use_cuda)
    if "complex" in dtype:
        b += 1.0j * sample_matrix(framework, dtype, shape, use_cuda) * 0.1
    return b


def create_solver_operands(framework, dtype, n, nrhs, use_cuda, batch_shape=None, lhs_batch_format=None, rhs_batch_format=None):
    a = create_lhs(framework, dtype, n, use_cuda, batch_shape=batch_shape, batch_format=lhs_batch_format)
    b = create_rhs(framework, dtype, n, nrhs, use_cuda, batch_shape=batch_shape, batch_format=rhs_batch_format)
    return a, b


def create_solver_operand_pair(
    framework,
    dtype,
    n,
    nrhs,
    use_cuda,
    *,
    batch_shape=None,
    lhs_batch_format=None,
    rhs_batch_format=None,
):
    """Create two compatible operand sets for reset and stateful solver tests."""
    operands0 = create_solver_operands(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )
    operands1 = create_solver_operands(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )
    return operands0, operands1


def run_stateful_test(a, b, *, a1=None, b1=None):
    with nvmath.linalg.generic.DirectSolver(a, b) as solver:
        solver.plan()
        solver.factorize()
        x = solver.solve()
        verify_solution(a, b, x)

        if a1 is None:
            if b1 is not None:
                solver.reset_operands(b=b1)
                x1 = solver.solve()
                verify_solution(a, b1, x1)
        else:
            if b1 is not None:
                solver.reset_operands(a=a1, b=b1)
                solver.factorize()
                x1 = solver.solve()
                verify_solution(a1, b1, x1)
            else:
                solver.reset_operands(a=a1)
                solver.factorize()
                x1 = solver.solve()
                verify_solution(a1, b, x1)
