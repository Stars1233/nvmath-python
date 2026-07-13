# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from collections.abc import Callable
from typing import NamedTuple, NoReturn

from numba_cuda_mlir import cuda
from numba_cuda_mlir.compiler import declare_device
from numba_cuda_mlir.extending import lowering_registry, overload_attribute, overload_method, typing_registry
from numba_cuda_mlir.lowering_utilities.type_conversions import to_numba_type
from numba_cuda_mlir.numba_cuda import types
from numba_cuda_mlir.numba_cuda.cudadrv.linkable_code import LTOIR, Fatbin

from nvmath.device.common_cuda import get_default_code_type
from nvmath.device.cusolverdx import Solver, compile_solver_execute
from nvmath.device.cusolverdx_backend import get_universal_fatbin

from .common_numba_cuda_mlir import (
    HostDescriptorBase,
    get_array_pointer,
    int_to_uint32_ptr,
    passthrough,
    register_dummy_type,
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


class SolverNumbaType(HostDescriptorBase):
    def __init__(self, solver: Solver) -> None:
        super().__init__(solver, _SOLVER_DEFINITION_ARGS, "Solver")


register_dummy_type(SolverNumbaType, Solver, _SOLVER_DEFINITION_ARGS + _SOLVER_PROPS)


# ==========================
# Overloads: Type conversions
# ==========================


def _numba_solver_value_type_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(to_numba_type(solver_type.host_descriptor.value_type))


def _numba_solver_precision_type_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(to_numba_type(solver_type.host_descriptor.precision))


def _numba_solver_integer_value(solver_type: SolverNumbaType) -> types.Type:
    return types.Integer


def _numba_solver_int32_ptr(solver_type: SolverNumbaType) -> types.Type:
    return types.CPointer(types.int32)


_TO_IR_TYPE_MAP = {
    _ArgType.value_type_ptr: _numba_solver_value_type_ptr,
    _ArgType.precision_type_ptr: _numba_solver_precision_type_ptr,
    _ArgType.integer_value: _numba_solver_integer_value,
    _ArgType.int32_ptr: _numba_solver_int32_ptr,
}


def _convert_to_ir_type(arg_type: _ArgType, solver_type: SolverNumbaType) -> types.Type:
    factory = _TO_IR_TYPE_MAP[arg_type]
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
    """Converts a type to its user-friendly representation for error messages."""
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

    signatures = _get_function_signatures(solver_type.host_descriptor.function)
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
    code, symbol = compile_solver_execute(
        solver_type.host_descriptor,
        code_type=get_default_code_type(),
        execution_api=signature.api,
    )

    fatbin = Fatbin(get_universal_fatbin().data)

    numba_args = [_get_libmathdx_type(_convert_to_ir_type(arg_spec.arg_type, solver_type)) for arg_spec in signature.args]
    sig = types.void(*numba_args)

    return declare_device(symbol, sig, link=[LTOIR(code.data), fatbin], abi="c")


def _format_signature(solver_type: SolverNumbaType, sig: _Signature) -> str:
    arg_list = ", ".join(
        f"{arg_spec.name}: {_get_error_message_type(_convert_to_ir_type(arg_spec.arg_type, solver_type))}"
        for arg_spec in sig.args
    )
    return f"({arg_list}) -> None"


def _raise_overload_resolution_error(solver_type: SolverNumbaType, args: list[types.Type]) -> NoReturn:
    """Raises a detailed TypeError when no matching function signature is found."""
    signatures = _get_function_signatures(solver_type.host_descriptor.function)
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


@overload_method(SolverNumbaType, "execute", strict=False, inline="always", typing_registry=typing_registry)
def _overload_execute(solver_type: SolverNumbaType, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
    if not isinstance(solver_type, SolverNumbaType):
        return

    args = [arg0, arg1, arg2, arg3, arg4, arg5]
    overload = _find_overload(args, solver_type)

    if overload is None:
        _raise_overload_resolution_error(solver_type, args)

    device_func = _compile_device_function(solver_type, overload)

    def prepare_arg_intrinsic(arg):
        if isinstance(arg, types.Integer):
            return int_to_uint32_ptr
        elif isinstance(arg, types.Array):
            return get_array_pointer
        else:
            return passthrough

    intrinsic0 = prepare_arg_intrinsic(arg0)
    intrinsic1 = prepare_arg_intrinsic(arg1)
    intrinsic2 = prepare_arg_intrinsic(arg2)
    intrinsic3 = prepare_arg_intrinsic(arg3)
    intrinsic4 = prepare_arg_intrinsic(arg4)
    intrinsic5 = prepare_arg_intrinsic(arg5)

    num_args = len(overload.args)

    # TODO: no lowering for tuple slicing
    if num_args == 2:

        def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
            device_func(intrinsic0(arg0), intrinsic1(arg1))

    elif num_args == 3:

        def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
            device_func(intrinsic0(arg0), intrinsic1(arg1), intrinsic2(arg2))

    elif num_args == 4:

        def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
            device_func(intrinsic0(arg0), intrinsic1(arg1), intrinsic2(arg2), intrinsic3(arg3))

    elif num_args == 5:

        def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
            device_func(
                intrinsic0(arg0),
                intrinsic1(arg1),
                intrinsic2(arg2),
                intrinsic3(arg3),
                intrinsic4(arg4),
            )

    elif num_args == 6:

        def execute_impl(_, arg0, arg1, arg2=None, arg3=None, arg4=None, arg5=None):
            device_func(
                intrinsic0(arg0),
                intrinsic1(arg1),
                intrinsic2(arg2),
                intrinsic3(arg3),
                intrinsic4(arg4),
                intrinsic5(arg5),
            )

    else:
        raise AssertionError(f"unsupported cusolverdx execute arity: num_args={num_args}")

    return execute_impl


# ==========================
# User API helpers
# ==========================


@cuda.jit(device=True, forceinline=True)
def _calculate_strides(shape: tuple[int, int], ld: int, is_col_major: bool) -> tuple[int, int, int]:
    if is_col_major:
        return (ld * shape[1], 1, ld)
    return (ld * shape[0], ld, 1)


def _validate_ld_type(ld, name):
    if ld not in {None, types.Omitted(None), types.none} and not isinstance(ld, types.Integer):
        raise RuntimeError(f"{name} must be an Integer!")


def _ensure_no_positional_arguments(arg0, function):
    if arg0 not in {None, types.Omitted(None), types.none}:
        raise RuntimeError(f"Function {function} does not accept positional arguments")


# ==========================
# Stride and size device-method impls
# ==========================


class _MethodImpls(NamedTuple):
    plain: Callable
    with_ld: Callable
    ld_kwarg_name: str


# TODO(numba-cuda-mlir) extremely long compilation times when using string comparison


def _a_strides_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.a_shape[1], solver.a_shape[2]),
        solver.lda,
        solver._a_is_col_major,
    )


def _a_strides_impl_with_lda(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.a_shape[1], solver.a_shape[2]),
        lda,
        solver._a_is_col_major,
    )


def _b_strides_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.b_shape[1], solver.b_shape[2]),
        solver.ldb,
        solver._b_is_col_major,
    )


def _b_strides_impl_with_ldb(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.b_shape[1], solver.b_shape[2]),
        ldb,
        solver._b_is_col_major,
    )


def _c_strides_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.c_shape[1], solver.c_shape[2]),
        solver.ldb,
        solver._b_is_col_major,
    )


def _c_strides_impl_with_ldc(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (solver.c_shape[1], solver.c_shape[2]),
        ldc,
        solver._b_is_col_major,
    )


def _bx_strides_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (max(solver.m, solver.n), solver.k),
        solver.ldb,
        solver._b_is_col_major,
    )


def _bx_strides_impl_with_ldb(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return _calculate_strides(
        (max(solver.m, solver.n), solver.k),
        ldb,
        solver._b_is_col_major,
    )


def _a_size_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.a_strides()[0] * solver.a_shape[0]


def _a_size_impl_with_lda(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.a_strides(lda=lda)[0] * solver.a_shape[0]


def _b_size_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.b_strides()[0] * solver.b_shape[0]


def _b_size_impl_with_ldb(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.b_strides(ldb=ldb)[0] * solver.b_shape[0]


def _c_size_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.c_strides()[0] * solver.c_shape[0]


def _c_size_impl_with_ldc(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.c_strides(ldc=ldc)[0] * solver.c_shape[0]


def _bx_size_impl_plain(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
    return solver.bx_strides()[0] * solver.batches_per_block


def _bx_size_impl_with_ldb(solver, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
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
    _UserApiDeviceMethod.a_strides:  _MethodImpls(plain=_a_strides_impl_plain,
                                                  with_ld=_a_strides_impl_with_lda,  ld_kwarg_name="lda"),
    _UserApiDeviceMethod.b_strides:  _MethodImpls(plain=_b_strides_impl_plain,
                                                  with_ld=_b_strides_impl_with_ldb,  ld_kwarg_name="ldb"),
    _UserApiDeviceMethod.c_strides:  _MethodImpls(plain=_c_strides_impl_plain,
                                                  with_ld=_c_strides_impl_with_ldc,  ld_kwarg_name="ldc"),
    _UserApiDeviceMethod.bx_strides: _MethodImpls(plain=_bx_strides_impl_plain,
                                                  with_ld=_bx_strides_impl_with_ldb, ld_kwarg_name="ldb"),
    _UserApiDeviceMethod.a_size:     _MethodImpls(plain=_a_size_impl_plain,
                                                  with_ld=_a_size_impl_with_lda,     ld_kwarg_name="lda"),
    _UserApiDeviceMethod.b_size:     _MethodImpls(plain=_b_size_impl_plain,
                                                  with_ld=_b_size_impl_with_ldb,     ld_kwarg_name="ldb"),
    _UserApiDeviceMethod.c_size:     _MethodImpls(plain=_c_size_impl_plain,
                                                  with_ld=_c_size_impl_with_ldc,     ld_kwarg_name="ldc"),
    _UserApiDeviceMethod.bx_size:    _MethodImpls(plain=_bx_size_impl_plain,
                                                  with_ld=_bx_size_impl_with_ldb,    ld_kwarg_name="ldb"),
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
# Dispatch overload registration
# ==========================


def _create_solver_dispatch_overload(numba_type, method, solver_attr, call_shape: _CallShape, expected_lds):
    @overload_method(numba_type, method, strict=False, inline="always", typing_registry=typing_registry)
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

        solver = getattr(user_api.host_descriptor, solver_attr)
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
    impls = _DEVICE_METHODS_IMPL[method]

    @overload_method(numba_type, method.value, strict=False, inline="always", typing_registry=typing_registry)
    def overload_user_api_method(user_api, arg0=None, arg1=None, arg2=None, lda=None, ldb=None, ldc=None):
        assert isinstance(user_api, numba_type)

        _ensure_no_positional_arguments(arg0, method.value)
        _validate_ld_type(lda, "lda")
        _validate_ld_type(ldb, "ldb")
        _validate_ld_type(ldc, "ldc")

        ld_value = {"lda": lda, "ldb": ldb, "ldc": ldc}[impls.ld_kwarg_name]
        use_ld = ld_value not in {None, types.Omitted(None), types.none}

        return impls.with_ld if use_ld else impls.plain

    return overload_user_api_method


# TODO(numba-cuda-mlir) extremely long compilation times when using string comparison
def _overload_is_col_major(numba_type, attribute: str, arrangement_attr: str) -> None:
    @overload_attribute(
        numba_type, attribute, inline="always", typing_registry=typing_registry, lowering_registry=lowering_registry
    )
    def ol_is_col_major(user_api):
        is_col_major = getattr(user_api.host_descriptor, arrangement_attr) == "col_major"
        return lambda user_api: is_col_major


def _register_user_api_dispatch(user_api_spec: _UserApiSpec):
    class UserApiNumbaType(HostDescriptorBase):
        def __init__(self, solver) -> None:
            super().__init__(solver, user_api_spec.definition_args, user_api_spec.user_api_class.__name__)

    register_dummy_type(
        UserApiNumbaType,
        user_api_spec.user_api_class,
        user_api_spec.definition_args + user_api_spec.helpers_prop,
    )

    _overload_is_col_major(UserApiNumbaType, "_a_is_col_major", "a_arrangement")
    _overload_is_col_major(UserApiNumbaType, "_b_is_col_major", "b_arrangement")

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
