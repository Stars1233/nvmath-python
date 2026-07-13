# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from enum import Enum
from typing import Literal, NamedTuple

from nvmath.device import (
    CholeskySolver,
    LeastSquaresSolver,
    LQFactorize,
    LQMultiply,
    LUPivotSolver,
    LUSolver,
    QRFactorize,
    QRMultiply,
    TriangularSolver,
)
from nvmath.device.cusolverdx_backend import _ENABLE_CUSOLVERDX_0_3

# ==========================
# Data: Solver Configuration
# ==========================

_SOLVER_DEFINITION_ARGS = [
    "function",
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "transpose_mode",
    "side",
    "diag",
    "fill_mode",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
]

_SOLVER_PROPS = [
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "info_type",
    "ipiv_type",
    "tau_type",
    "block_size",
]

if _ENABLE_CUSOLVERDX_0_3:
    _SOLVER_PROPS.append("workspace_size")
    _SOLVER_DEFINITION_ARGS.append("job")

# ==========================
# Dispatch Data Structures
# ==========================


class _ArgType(str, Enum):
    value_type_ptr = "value_type_ptr"
    precision_type_ptr = "precision_type_ptr"
    integer_value = "integer_value"
    int32_ptr = "int32_ptr"


class _Arg(NamedTuple):
    arg_type: _ArgType
    name: str


class _Signature(NamedTuple):
    api: Literal["compiled_leading_dim"] | Literal["runtime_leading_dim"]  # libmathdx API variant
    args: list[_Arg]  # List of expected arguments for the function


class _FunctionSignatures(NamedTuple):
    function: str
    signatures: list[_Signature]


# ==========================
# Dispatch Data: Function Signatures Registry
# ==========================

"""
_DISPATCH_DATA contains the dispatch information for different solver functions.
"""
_DISPATCH_DATA = [
    _FunctionSignatures(
        function="potrs",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="getrs_no_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="gels",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="trsm",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="geqrf",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="gelqf",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="unmqr",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="c"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="c"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldc"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="unmlq",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="c"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="c"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldc"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="potrf",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="getrf_no_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="getrf_partial_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="getrs_partial_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="posv",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="gesv_no_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="gesv_partial_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="ipiv"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
]

_DISPATCH_DATA_CUSOLVERDX_0_3 = [
    _FunctionSignatures(
        function="gtsv_no_pivot",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="dl"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="d"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="du"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="dl"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="d"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="du"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="b"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldb"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="htev",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="d"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="e"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="d"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="e"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="V"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="d"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="e"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="V"),
                    _Arg(arg_type=_ArgType.integer_value, name="ldv"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="heev",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.precision_type_ptr, name="lambda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="workspace"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.precision_type_ptr, name="lambda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="workspace"),
                    _Arg(arg_type=_ArgType.int32_ptr, name="info"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="ungqr",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
        ],
    ),
    _FunctionSignatures(
        function="unglq",
        signatures=[
            _Signature(
                api="compiled_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
            _Signature(
                api="runtime_leading_dim",
                args=[
                    _Arg(arg_type=_ArgType.value_type_ptr, name="a"),
                    _Arg(arg_type=_ArgType.integer_value, name="lda"),
                    _Arg(arg_type=_ArgType.value_type_ptr, name="tau"),
                ],
            ),
        ],
    ),
]

if _ENABLE_CUSOLVERDX_0_3:
    _DISPATCH_DATA += _DISPATCH_DATA_CUSOLVERDX_0_3


def _get_function_signatures(function: str) -> list[_Signature] | None:
    """Looks up and returns the list of available signatures for a given function."""
    for func_signature in _DISPATCH_DATA:
        if func_signature.function == function:
            return func_signature.signatures

    return None


# ==========================
# User API dispatch
# =========================


class _UserApiDispatchFactory(str, Enum):
    solve_factory = "solve_factory"
    factorize_factory = "factorize_factory"
    triangular_solve_factory = "triangular_solve_factory"
    factorize_pivot_factory = "factorize_pivot_factory"
    solve_pivot_factory = "solve_pivot_factory"
    orthogonal_multiply_factory = "orthogonal_multiply_factory"
    least_squares_solve_factory = "least_squares_solve_factory"


class _UserApiSolverDispatch(NamedTuple):
    method: str  # name of the method to overload
    factory: _UserApiDispatchFactory
    solver_attr: str  # name of the solver attribute to forward execution to
    expected_lds: list[Literal["lda", "ldb", "ldc"]]  # list of expected leading dimensions


class _UserApiDeviceMethod(str, Enum):
    a_strides = "a_strides"
    b_strides = "b_strides"
    c_strides = "c_strides"
    bx_strides = "bx_strides"
    a_size = "a_size"
    b_size = "b_size"
    c_size = "c_size"
    bx_size = "bx_size"


class _UserApiSpec(NamedTuple):
    user_api_class: type
    definition_args: list[str]
    helpers_prop: list[str]
    solver_dispath_methods: list[_UserApiSolverDispatch]
    device_methods: list[_UserApiDeviceMethod]


# ==========================
# Common solve configs
# ==========================

_BASIC_SOLVER_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="factorize",
        solver_attr="_factorize",
        expected_lds=["lda"],
        factory=_UserApiDispatchFactory.factorize_factory,
    ),
    _UserApiSolverDispatch(
        method="solve",
        solver_attr="_solve",
        expected_lds=["lda", "ldb"],
        factory=_UserApiDispatchFactory.solve_factory,
    ),
]

_BASIC_SOLVER_DEVICE_METHODS = [
    _UserApiDeviceMethod.a_strides,
    _UserApiDeviceMethod.b_strides,
    _UserApiDeviceMethod.a_size,
    _UserApiDeviceMethod.b_size,
]


# ==========================
# Cholesky Solver
# ==========================

_CHOLESKY_SOLVER_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "fill_mode",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
]

_CHOLESKY_SOLVER_PROPS = [
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "block_size",
    "info_type",
    "info_shape",
    "info_strides",
    "a_shape",
    "b_shape",
]

_CHOLESKY_USER_API_SPEC = _UserApiSpec(
    CholeskySolver,
    _CHOLESKY_SOLVER_DEFINITION_ARGS,
    _CHOLESKY_SOLVER_PROPS,
    _BASIC_SOLVER_DISPATCH_METHODS,
    _BASIC_SOLVER_DEVICE_METHODS,
)

# ==========================
# LU Solver
# ==========================

_LU_SOLVER_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "transpose_mode",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
]

_LU_SOLVER_PROPS = [
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "block_size",
    "info_type",
    "info_shape",
    "info_strides",
    "a_shape",
    "b_shape",
]

_LU_USER_API_SPEC = _UserApiSpec(
    LUSolver,
    _LU_SOLVER_DEFINITION_ARGS,
    _LU_SOLVER_PROPS,
    _BASIC_SOLVER_DISPATCH_METHODS,
    _BASIC_SOLVER_DEVICE_METHODS,
)

# ==========================
# Triangular Solver
# ==========================

_TRIANGULAR_SOLVER_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "side",
    "fill_mode",
    "diag",
    "transpose_mode",
    "arrangement",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
]

_TRIANGULAR_SOLVER_PROPS = [
    "block_dim",
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "block_size",
    "a_shape",
    "b_shape",
]

_TRIANGULAR_SOLVER_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="solve",
        solver_attr="_solve",
        factory=_UserApiDispatchFactory.triangular_solve_factory,
        expected_lds=["lda", "ldb"],
    ),
]

_TRIANGULAR_SOLVER_USER_API_SPEC = _UserApiSpec(
    TriangularSolver,
    _TRIANGULAR_SOLVER_DEFINITION_ARGS,
    _TRIANGULAR_SOLVER_PROPS,
    _TRIANGULAR_SOLVER_DISPATCH_METHODS,
    _BASIC_SOLVER_DEVICE_METHODS,
)

# ==========================
# LU Pivot Solver
# ==========================

_LU_PIVOT_SOLVER_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "transpose_mode",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
]

_LU_PIVOT_SOLVER_PROPS = [
    "block_size",
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "info_type",
    "info_shape",
    "info_strides",
    "ipiv_type",
    "ipiv_size",
    "ipiv_shape",
    "ipiv_strides",
    "a_shape",
    "b_shape",
]

_LU_PIVOT_SOLVER_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="factorize",
        solver_attr="_factorize",
        factory=_UserApiDispatchFactory.factorize_pivot_factory,
        expected_lds=["lda"],
    ),
    _UserApiSolverDispatch(
        method="solve",
        solver_attr="_solve",
        factory=_UserApiDispatchFactory.solve_pivot_factory,
        expected_lds=["lda", "ldb"],
    ),
]

_LU_PIVOT_SOLVER_USER_API_SPEC = _UserApiSpec(
    LUPivotSolver,
    _LU_PIVOT_SOLVER_DEFINITION_ARGS,
    _LU_PIVOT_SOLVER_PROPS,
    _LU_PIVOT_SOLVER_DISPATCH_METHODS,
    _BASIC_SOLVER_DEVICE_METHODS,
)

# ==========================
# QRFactors
# ==========================

_QR_FACTORS_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "batches_per_block",
    "data_type",
    "block_dim",
    "a_arrangement",
    "lda",
]

_QR_FACTORS_PROPS = [
    "value_type",
    "m",
    "n",
    "block_size",
    "tau_type",
    "tau_size",
    "tau_shape",
    "tau_strides",
    "a_shape",
]

_QR_FACTORS_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="factorize",
        solver_attr="_factorize",
        factory=_UserApiDispatchFactory.factorize_factory,
        expected_lds=["lda"],
    ),
]

_QR_FACTORS_DEVICE_METHODS = [
    _UserApiDeviceMethod.a_strides,
    _UserApiDeviceMethod.a_size,
]

_QR_FACTORIZE_USER_API_SPEC = _UserApiSpec(
    QRFactorize,
    _QR_FACTORS_DEFINITION_ARGS,
    _QR_FACTORS_PROPS,
    _QR_FACTORS_DISPATCH_METHODS,
    _QR_FACTORS_DEVICE_METHODS,
)

_LQ_FACTORIZE_USER_API_SPEC = _UserApiSpec(
    LQFactorize,
    _QR_FACTORS_DEFINITION_ARGS,
    _QR_FACTORS_PROPS,
    _QR_FACTORS_DISPATCH_METHODS,
    _QR_FACTORS_DEVICE_METHODS,
)

# ==========================
# Orthogonal Multiply
# ==========================

_ORTHOGONAL_MULTIPLY_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
    "transpose_mode",
    "side",
]

_ORTHOGONAL_MULTIPLY_PROPS = [
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "block_size",
    "tau_type",
    "tau_size",
    "tau_shape",
    "tau_strides",
    "a_shape",
    "c_shape",
]

_QR_MULTIPLY_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="multiply",
        solver_attr="_multiply",
        factory=_UserApiDispatchFactory.orthogonal_multiply_factory,
        expected_lds=["lda", "ldc"],
    ),
]

_QR_MULTIPLY_DEVICE_METHODS = [
    _UserApiDeviceMethod.a_strides,
    _UserApiDeviceMethod.a_size,
    _UserApiDeviceMethod.c_strides,
    _UserApiDeviceMethod.c_size,
]

_QR_MULTIPLY_USER_API_SPEC = _UserApiSpec(
    QRMultiply,
    _ORTHOGONAL_MULTIPLY_DEFINITION_ARGS,
    _ORTHOGONAL_MULTIPLY_PROPS,
    _QR_MULTIPLY_DISPATCH_METHODS,
    _QR_MULTIPLY_DEVICE_METHODS,
)

_LQ_MULTIPLY_USER_API_SPEC = _UserApiSpec(
    LQMultiply,
    _ORTHOGONAL_MULTIPLY_DEFINITION_ARGS,
    _ORTHOGONAL_MULTIPLY_PROPS,
    _QR_MULTIPLY_DISPATCH_METHODS,
    _QR_MULTIPLY_DEVICE_METHODS,
)

# ==========================
# Least Squares Solver
# ==========================

_LEAST_SQUARES_SOLVER_DEFINITION_ARGS = [
    "size",
    "precision",
    "execution",
    "sm",
    "arrangement",
    "transpose_mode",
    "batches_per_block",
    "data_type",
    "leading_dimensions",
    "block_dim",
]

_LEAST_SQUARES_SOLVER_PROPS = [
    "value_type",
    "m",
    "n",
    "k",
    "a_arrangement",
    "b_arrangement",
    "lda",
    "ldb",
    "block_size",
    "tau_type",
    "tau_size",
    "tau_shape",
    "tau_strides",
    "a_shape",
    "b_shape",
    "x_shape",
]

_LEAST_SQUARES_SOLVER_DISPATCH_METHODS = [
    _UserApiSolverDispatch(
        method="solve",
        solver_attr="_solve",
        factory=_UserApiDispatchFactory.least_squares_solve_factory,
        expected_lds=["lda", "ldb"],
    ),
]

_LEAST_SQUARES_SOLVER_DEVICE_METHODS = [
    _UserApiDeviceMethod.a_strides,
    _UserApiDeviceMethod.a_size,
    _UserApiDeviceMethod.bx_strides,
    _UserApiDeviceMethod.bx_size,
]

_LEAST_SQUARES_SOLVER_SPEC = _UserApiSpec(
    LeastSquaresSolver,
    _LEAST_SQUARES_SOLVER_DEFINITION_ARGS,
    _LEAST_SQUARES_SOLVER_PROPS,
    _LEAST_SQUARES_SOLVER_DISPATCH_METHODS,
    _LEAST_SQUARES_SOLVER_DEVICE_METHODS,
)


# ==========================
# User API disptach list
# ==========================

_USER_API_DISPATCH_SPECS = [
    _CHOLESKY_USER_API_SPEC,
    _LU_USER_API_SPEC,
    _TRIANGULAR_SOLVER_USER_API_SPEC,
    _LU_PIVOT_SOLVER_USER_API_SPEC,
    _QR_FACTORIZE_USER_API_SPEC,
    _LQ_FACTORIZE_USER_API_SPEC,
    _QR_MULTIPLY_USER_API_SPEC,
    _LQ_MULTIPLY_USER_API_SPEC,
    _LEAST_SQUARES_SOLVER_SPEC,
]
