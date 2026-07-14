# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import pytest

from .params import ALL_DTYPES, ALL_FRAMEWORKS
from .solver_utils import create_solver_operand_pair, run_stateful_test

# Breadth / smoke: small n and fixed small problems, many parameter combinations.
# Each case runs the full stateful workflow and checks A @ x ≈ b (see run_stateful_test):
#   - n and nrhs (non-batched, NumPy CPU);
#   - batch_shape and LHS/RHS batch formats (CuPy GPU);
#   - framework, device, and dtype (non-batched and batched with fixed batch_shape).


@pytest.mark.parametrize("n", (1, 5))
@pytest.mark.parametrize("nrhs", (None, 1, 3))
def test_non_batched_matrix_and_rhs_sizes(n, nrhs):
    framework, use_cuda = "numpy", False
    dtype = "float32"
    (a, b), (a1, b1) = create_solver_operand_pair(framework, dtype, n, nrhs, use_cuda)
    run_stateful_test(a, b, a1=a1, b1=b1)


@pytest.mark.parametrize("n", (1, 5))
@pytest.mark.parametrize("nrhs", (None, 1, 3))
@pytest.mark.parametrize("batch_shape", [(1,), (1, 2), (3, 4), (2, 4, 3)])
@pytest.mark.parametrize("lhs_batch_format", ("explicit", "implicit"))
@pytest.mark.parametrize("rhs_batch_format", ("explicit", "implicit"))
def test_batched_matrix_and_rhs_sizes(n, nrhs, batch_shape, lhs_batch_format, rhs_batch_format):
    framework, use_cuda = "cupy", True
    dtype = "float32"
    (a, b), (a1, b1) = create_solver_operand_pair(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )
    run_stateful_test(a, b, a1=a1, b1=b1)


@ALL_FRAMEWORKS
@ALL_DTYPES
def test_non_batched_frameworks_and_dtypes(framework, use_cuda, dtype):
    n, nrhs = 4, 2
    (a, b), (a1, b1) = create_solver_operand_pair(framework, dtype, n, nrhs, use_cuda)
    run_stateful_test(a, b, a1=a1, b1=b1)


@ALL_FRAMEWORKS
@ALL_DTYPES
def test_batched_frameworks_and_dtypes(framework, use_cuda, dtype):
    n, nrhs = 4, 2
    batch_shape = (1, 4)
    lhs_batch_format = "explicit"
    rhs_batch_format = "implicit"
    (a, b), (a1, b1) = create_solver_operand_pair(
        framework,
        dtype,
        n,
        nrhs,
        use_cuda,
        batch_shape=batch_shape,
        lhs_batch_format=lhs_batch_format,
        rhs_batch_format=rhs_batch_format,
    )
    run_stateful_test(a, b, a1=a1, b1=b1)


# Depth: larger n, nrhs, and batch shapes — same A @ x ≈ b checks as above, stressing
# conditioning and batched paths (implicit LHS, explicit RHS for the batched case).


@ALL_FRAMEWORKS
@ALL_DTYPES
class TestCorrectness:
    @pytest.mark.parametrize("n, nrhs", [(4, 3), (64, 12), (512, 32)])
    def test_non_batched(self, framework, use_cuda, n, nrhs, dtype):
        (a0, b0), (a1, b1) = create_solver_operand_pair(framework, dtype, n, nrhs, use_cuda)
        run_stateful_test(a0, b0, a1=a1, b1=b1)

    @pytest.mark.parametrize(
        "n, nrhs, batch_shape",
        [
            (4, 3, (32, 4)),
            (64, 12, (7, 2)),
            (128, 32, (5,)),
        ],
    )
    def test_batched(self, framework, use_cuda, n, nrhs, dtype, batch_shape):
        lhs_batch_format = "implicit"
        rhs_batch_format = "explicit"
        (a0, b0), (a1, b1) = create_solver_operand_pair(
            framework,
            dtype,
            n,
            nrhs,
            use_cuda,
            batch_shape=batch_shape,
            lhs_batch_format=lhs_batch_format,
            rhs_batch_format=rhs_batch_format,
        )

        run_stateful_test(a0, b0, a1=a1, b1=b1)
