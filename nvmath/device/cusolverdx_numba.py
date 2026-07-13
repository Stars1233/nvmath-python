# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from collections.abc import Callable
from typing import NamedTuple, NoReturn

from numba import cuda
from numba.core import typing
from numba.extending import intrinsic, overload_method, types

from nvmath.device import (
    Solver,
    compile_solver_execute,
)
from nvmath.device.common_cuda import get_default_code_type
from nvmath.device.cusolverdx_backend import get_universal_fatbin

from .common_numba import (
    NUMBA_FE_TYPES_TO_NUMBA_IR,
    declare_cabi_device,
    get_array_ptr,
    get_uint32_value_ptr,
    register_dummy_numba_type,
)
from .cusolverdx_overload_backend import (
    _SOLVER_DEFINITION_ARGS,
    _SOLVER_PROPS,
    _USER_API_DISPATCH_SPECS,
    _Arg,
    _ArgType,
    _get_function_signatures,
    _Signature,
    _UserApiDeviceMethod,
    _UserApiDispatchFactory,
    _UserApiSpec,
)

# ==========================
# Numba type
# ==========================


class SolverNumbaType(types.Type):
    def __init__(self, solver: Solver) -> None:
        self._solver = solver

        attributes = [f"{attr}={getattr(solver, attr)}" for attr in _SOLVER_DEFINITION_ARGS if getattr(solver, attr)]
        attributes.sort()
        attr_str = ", ".join(attributes)

        super().__init__(name=f"Solver({attr_str})")

    @property
    def solver(self) -> Solver:
        return self._solver


register_dummy_numba_type(
    SolverNumbaType,
    Solver,
    "solver",
    _SOLVER_DEFINITION_ARGS + _SOLVER_PROPS,
)


# ==========================
# Intrinsics
# ==========================


@intrinsic
def _link_fatbin(typingctx: typing.Context):
    sig = types.void()

    fatbin = get_universal_fatbin()

    def codegen(context, builder, sig, args):
        context.active_code_library.add_linking_file(fatbin)

    return sig, codegen


@intrinsic
def _do_nothing(typingctx: typing.Context, value: types.Type):
    sig = value(value)

    def codegen(context, builder, sig, args):
        return args[0]

    return sig, codegen


# ==========================
# Overloads: Type conversions
# ==========================


def _numba_solver_value_type_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(NUMBA_FE_TYPES_TO_NUMBA_IR[solver_type.solver.value_type])


def _numba_solver_precision_type_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(NUMBA_FE_TYPES_TO_NUMBA_IR[solver_type.solver.precision])


def _numba_solver_integer_value(solver_type: SolverNumbaType) -> types.Type:
    return types.Integer


def _numba_solver_int32_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(types.int32)


def _convert_to_ir_type(arg_type: _ArgType, solver_type: SolverNumbaType) -> types.Type:
    TO_IR_TYPE_MAP = {
        _ArgType.value_type_ptr: _numba_solver_value_type_ptr,
        _ArgType.precision_type_ptr: _numba_solver_precision_type_ptr,
        _ArgType.integer_value: _numba_solver_integer_value,
        _ArgType.int32_ptr: _numba_solver_int32_ptr,
    }

    factory = TO_IR_TYPE_MAP[arg_type]
    return factory(solver_type)


# ==========================
# Overloads: Method Dispatch Implementation
# ==========================


def _validate_arg_type(user_type: types.Type, expected_type: types.Type) -> bool:
    if expected_type == types.Integer:
        return isinstance(user_type, types.Integer)

    assert isinstance(expected_type, types.CPointer)
    dtype, _ = expected_type.key

    return isinstance(user_type, types.Array) and user_type.dtype == dtype


def _get_libmathdx_type(expected_type: types.Type) -> types.Type:
    if expected_type == types.Integer:
        return types.CPointer(types.uint32)
    return expected_type


def _get_error_message_type(numba_type: types.Type) -> types.Type | str:
    """
    Converts a type to its user-friendly representation for error messages.
    """
    if numba_type == types.Integer:
        return numba_type.__name__
    return numba_type


def _check_all_none(args: list[types.Type]) -> bool:
    """Checks if all elements are None"""
    return all(unwanted_arg in {None, types.Omitted(None), types.none} for unwanted_arg in args)


def _validate_arg_types(solver_type: SolverNumbaType, arg_types: list[_Arg], args_fit: list[types.Type]) -> bool:
    """Validates whether provided arguments match the expected types for a signature."""
    return all(
        _validate_arg_type(arg, _convert_to_ir_type(arg_spec.arg_type, solver_type))
        for arg_spec, arg in zip(arg_types, args_fit, strict=True)
    )


def _find_overload(args: list[types.Type], solver_type: SolverNumbaType) -> _Signature | None:
    """
    Iterates through all available signatures for the solver's function and finds
    the first one where:
    1. The number of arguments matches (no extra arguments provided)
    2. All argument types are valid for the signature
    """

    signatures = _get_function_signatures(solver_type.solver.function)
    assert signatures is not None

    for sig in signatures:
        expected_args_num = len(sig.args)

        args_fit = args[:expected_args_num]
        if not _check_all_none(args[expected_args_num:]):
            continue

        if not _validate_arg_types(solver_type, sig.args, args_fit):
            continue

        return sig

    return None


def _compile_device_function(solver_type: SolverNumbaType, signature: _Signature) -> Callable:
    """
    Compile cusolverdx execute device function and wrap it into numba device function.
    """

    # Call libmathdx to jit the function
    code, symbol = compile_solver_execute(
        solver_type.solver,
        code_type=get_default_code_type(),
        execution_api=signature.api,
    )
    lto = cuda.LTOIR(code.data)

    numba_args = [_get_libmathdx_type(_convert_to_ir_type(arg_spec.arg_type, solver_type)) for arg_spec in signature.args]
    sig = types.void(*numba_args)

    # Convert to cabi from numba abi
    return declare_cabi_device(symbol, sig, link=lto)


def _format_signature(solver_type: SolverNumbaType, sig: _Signature) -> str:
    arg_list = ", ".join(
        f"{arg_spec.name}: {_get_error_message_type(_convert_to_ir_type(arg_spec.arg_type, solver_type))}"
        for arg_spec in sig.args
    )
    return f"({arg_list}) -> None"


def _raise_overload_resolution_error(solver_type: SolverNumbaType, args: list[types.Type]) -> NoReturn:
    """
    Raises a detailed TypeError when no matching function signature is found.

    Constructs an informative error message showing:
    - The signature that was provided by the user
    - All available signatures for the solver function
    """
    signatures = _get_function_signatures(solver_type.solver.function)
    assert signatures is not None

    available_sigs = ", ".join(_format_signature(solver_type, sig) for sig in signatures)
    provided_args = [
        types.CPointer(arg.dtype) if isinstance(arg, types.Array) else arg
        for arg in args
        if arg not in {None, types.Omitted(None), types.none}
    ]
    provided_sig = types.void(*provided_args)

    raise TypeError(
        'Failed to find matching overload of "SOLVER.execute()" function.'
        f" Provided signature: {provided_sig}, but only these are available: {available_sigs}"
    )


@overload_method(SolverNumbaType, "execute", target="cuda", jit_options={"forceinline": True}, strict=False)
def _overload_execute(solver_type: SolverNumbaType, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
    """Numba overload for Solver.execute(), resolves signature and compiles function."""
    assert isinstance(solver_type, SolverNumbaType)

    # Find matching signature for the provided arguments
    args = [arg0, arg1, arg2, arg3, arg4, arg5]
    overload = _find_overload(args, solver_type)

    if overload is None:
        _raise_overload_resolution_error(solver_type, args)

    # Compile the device function for the matched signature
    device_func = _compile_device_function(solver_type, overload)

    # Generate the implementation wrapper
    def prepare_arg_intrinsic(arg):
        if isinstance(arg, types.Integer):
            return get_uint32_value_ptr
        elif isinstance(arg, types.Array):
            return get_array_ptr
        else:
            return _do_nothing

    intrinsic0 = prepare_arg_intrinsic(arg0)
    intrinsic1 = prepare_arg_intrinsic(arg1)
    intrinsic2 = prepare_arg_intrinsic(arg2)
    intrinsic3 = prepare_arg_intrinsic(arg3)
    intrinsic4 = prepare_arg_intrinsic(arg4)
    intrinsic5 = prepare_arg_intrinsic(arg5)

    num_args = len(overload.args)

    def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
        _link_fatbin()
        converted_args = (
            intrinsic0(arg0),
            intrinsic1(arg1),
            intrinsic2(arg2),
            intrinsic3(arg3),
            intrinsic4(arg4),
            intrinsic5(arg5),
        )
        device_func(*converted_args[:num_args])

    return execute_impl


# ==========================
# User API helpers
# =========================


@cuda.jit(device=True, forceinline=True)
def _calculate_strides(shape: tuple[int, int], ld: int, is_col_major: bool) -> tuple[int, int, int]:
    return (ld * shape[1], 1, ld) if is_col_major else (ld * shape[0], ld, 1)


def _validate_ld_type(ld, name):
    if ld not in {None, types.Omitted(None), types.none} and not isinstance(ld, types.Integer):
        raise RuntimeError(f"{name} must be an Integer!")


def _ensure_no_positional_arguments(arg0, function):
    if arg0 not in {None, types.Omitted(None), types.none}:
        raise RuntimeError(f"Function {function} does not accept positional arguments")


# ==========================
# Stride and size device-method impls
# ==========================


def _a_strides_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.a_shape[1], solver.a_shape[2]),
        lda if lda is not None else solver.lda,
        solver.a_arrangement == "col_major",
    )


def _b_strides_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.b_shape[1], solver.b_shape[2]),
        ldb if ldb is not None else solver.ldb,
        solver.b_arrangement == "col_major",
    )


def _c_strides_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.c_shape[1], solver.c_shape[2]),
        ldc if ldc is not None else solver.ldb,
        solver.b_arrangement == "col_major",
    )


def _bx_strides_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (max(solver.m, solver.n), solver.k),
        ldb if ldb is not None else solver.ldb,
        solver.b_arrangement == "col_major",
    )


def _a_size_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.a_strides(lda=lda)[0] * solver.a_shape[0]


def _b_size_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.b_strides(ldb=ldb)[0] * solver.b_shape[0]


def _c_size_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.c_strides(ldc=ldc)[0] * solver.c_shape[0]


def _bx_size_impl(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.bx_strides(ldb=ldb)[0] * solver.batches_per_block


# ==========================
# Execute() call-shape builders
# ==========================


def _impl_a0_a1(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, arg1)

    return impl


def _impl_a0_a1_a2(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, arg1, arg2)

    return impl


def _impl_a0_lda_a1(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, lda, arg1)

    return impl


def _impl_a0_lda_a1_ldb(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, lda, arg1, ldb)

    return impl


def _impl_a0_lda_a1_a2(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, lda, arg1, arg2)

    return impl


def _impl_a0_lda_a1_a2_ldb(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, lda, arg1, arg2, ldb)

    return impl


def _impl_a0_lda_a1_a2_ldc(solver: Solver) -> Callable:
    def impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None):
        solver.execute(arg0, lda, arg1, arg2, ldc)

    return impl


class _CallShape(NamedTuple):
    plain: Callable  # impl builder for the no-leading-dims path
    lds: Callable  # impl builder for the runtime-leading-dims path
    requires_square: bool = False  # solve operations: solver is None when the matrix isn't square


# ==========================
# Mappings
# ==========================

_DEVICE_METHODS_IMPL = {
    _UserApiDeviceMethod.a_strides: _a_strides_impl,
    _UserApiDeviceMethod.b_strides: _b_strides_impl,
    _UserApiDeviceMethod.c_strides: _c_strides_impl,
    _UserApiDeviceMethod.bx_strides: _bx_strides_impl,
    _UserApiDeviceMethod.a_size: _a_size_impl,
    _UserApiDeviceMethod.b_size: _b_size_impl,
    _UserApiDeviceMethod.c_size: _c_size_impl,
    _UserApiDeviceMethod.bx_size: _bx_size_impl,
}  # fmt: skip
assert set(_DEVICE_METHODS_IMPL) == set(_UserApiDeviceMethod)

_CALL_SHAPES = {
    _UserApiDispatchFactory.factorize_factory:           _CallShape(_impl_a0_a1,    _impl_a0_lda_a1),
    _UserApiDispatchFactory.solve_factory:               _CallShape(_impl_a0_a1,    _impl_a0_lda_a1_ldb,
                                                                    requires_square=True),
    _UserApiDispatchFactory.triangular_solve_factory:    _CallShape(_impl_a0_a1,    _impl_a0_lda_a1_ldb),
    _UserApiDispatchFactory.factorize_pivot_factory:     _CallShape(_impl_a0_a1_a2, _impl_a0_lda_a1_a2),
    _UserApiDispatchFactory.solve_pivot_factory:         _CallShape(_impl_a0_a1_a2, _impl_a0_lda_a1_a2_ldb,
                                                                    requires_square=True),
    _UserApiDispatchFactory.orthogonal_multiply_factory: _CallShape(_impl_a0_a1_a2, _impl_a0_lda_a1_a2_ldc),
    _UserApiDispatchFactory.least_squares_solve_factory: _CallShape(_impl_a0_a1_a2, _impl_a0_lda_a1_a2_ldb),
}  # fmt: skip
assert set(_CALL_SHAPES) == set(_UserApiDispatchFactory)


# ==========================
# Dispatch Methods Factories
# ==========================


def _create_solver_dispatch_overload(numba_type, method, solver_attr, call_shape: _CallShape, expected_lds):
    @overload_method(numba_type, method, target="cuda", jit_options={"forceinline": True}, strict=False)
    def overload_user_api_method(
        user_api, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None, lda=None, ldb=None, ldc=None
    ):
        assert isinstance(user_api, numba_type)

        def expected_ensure_provided(ld, name, expected):
            if expected == name and ld is None:
                raise RuntimeError(f"{name} must be provided to use runtime leading dimensions")

        _validate_ld_type(lda, "lda")
        _validate_ld_type(ldb, "ldb")
        _validate_ld_type(ldc, "ldc")

        use_lds = (
            lda not in {None, types.Omitted(None), types.none}
            or ldb not in {None, types.Omitted(None), types.none}
            or ldc not in {None, types.Omitted(None), types.none}
        )
        if use_lds:
            for expected_ld in expected_lds:
                expected_ensure_provided(lda, "lda", expected_ld)
                expected_ensure_provided(ldb, "ldb", expected_ld)
                expected_ensure_provided(ldc, "ldc", expected_ld)

        solver = getattr(user_api.solver, solver_attr)
        if call_shape.requires_square:
            if solver is None:
                raise RuntimeError(
                    "Device function: solve is not available with this configuration: "
                    "Operation is permitted only for square matrices"
                )
            assert solver.m == solver.n
        else:
            assert solver is not None
        return (call_shape.lds if use_lds else call_shape.plain)(solver)

    return overload_user_api_method


def _create_device_method_overload(numba_type, method: _UserApiDeviceMethod):
    impl = _DEVICE_METHODS_IMPL[method]

    @overload_method(numba_type, method.value, target="cuda", jit_options={"forceinline": True}, strict=False)
    def overload_user_api_method(user_api, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
        assert isinstance(user_api, numba_type)

        _ensure_no_positional_arguments(arg0, method.value)
        _validate_ld_type(lda, "lda")
        _validate_ld_type(ldb, "ldb")
        _validate_ld_type(ldc, "ldc")

        return impl

    return overload_user_api_method


def _register_user_api_dispatch(user_api_spec: _UserApiSpec):
    """
    Registers new numba type for a user API class and overloads the device methods.

    Assumes the API object has hidden fields containing Solver objects.
    Uses device_methods_attrs (which maps method names to solver fields)
    to forward execution to the execute() method of the corresponding solver.
    """

    class UserApiNumbaType(types.Type):
        def __init__(self, solver) -> None:
            self._solver = solver

            attributes = [f"{attr}={getattr(solver, attr)}" for attr in user_api_spec.definition_args if getattr(solver, attr)]
            attributes.sort()
            attr_str = ", ".join(attributes)

            super().__init__(name=f"{user_api_spec.user_api_class.__name__}({attr_str})")

        @property
        def solver(self):
            return self._solver

    register_dummy_numba_type(
        UserApiNumbaType,
        user_api_spec.user_api_class,
        "solver",
        user_api_spec.definition_args + user_api_spec.helpers_prop,
    )

    for solver_dispath_method in user_api_spec.solver_dispath_methods:
        _create_solver_dispatch_overload(
            UserApiNumbaType,
            solver_dispath_method.method,
            solver_dispath_method.solver_attr,
            _CALL_SHAPES[solver_dispath_method.factory],
            solver_dispath_method.expected_lds,
        )

    for device_method in user_api_spec.device_methods:
        _create_device_method_overload(UserApiNumbaType, device_method)


for user_api_spec in _USER_API_DISPATCH_SPECS:
    _register_user_api_dispatch(user_api_spec)
