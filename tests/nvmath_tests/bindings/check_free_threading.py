# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Smoke check one nvmath binding module under a free-threaded Python build.

Run this script with exactly one component at a time, preferably from a fresh
subprocess for each component:

    python -X gil=0 tests/nvmath_tests/bindings/check_free_threading.py cublas

Using one component per process keeps failures isolated. If a C extension import
re-enables the GIL, that state is process-global and cannot be reset for the next
component in the same process.

The script also runs on regular CPython builds. In that case the GIL is expected
to be enabled, so the free-threading-specific GIL checks are skipped and the
script behaves as a lightweight binding smoke test.
"""

import argparse
import importlib
import sys
import sysconfig

from cuda.pathfinder import DynamicLibNotFoundError

from nvmath.bindings._internal.utils import FunctionNotFoundError, NotSupportedError


def check_gil_disabled_if_free_threaded(where: str):
    """Verify the GIL stays disabled, only on free-threaded CPython builds.

    Regular CPython builds always have the GIL enabled, so this check is skipped
    unless the interpreter was built with ``Py_GIL_DISABLED`` support.
    """
    if not sysconfig.get_config_var("Py_GIL_DISABLED"):
        return
    if sys._is_gil_enabled():
        raise RuntimeError(f"GIL was enabled {where}")


# Components whose public bindings have a cheap zero-argument lifecycle check.
# This exercises import, lazy symbol loading, handle creation, and destruction.
CREATE_DESTROY_COMPONENTS = (
    "cublas",
    "cublasLt",
    "cudss",
    "cufft",
    "cufftMp",
    "cusolverDn",
    "cusolverSp",
    "cusparse",
    "cusparseLt",
    "cutensor",
)

# Components with no simple zero-argument create/destroy path. A version query is
# still useful because it imports the extension and calls through the binding.
VERSION_ONLY_COMPONENTS = ("cublasMp", "curand", "cusolver", "mathdx", "nvpl.blas", "nvpl.fft")

# Components that need additional runtime/distributed setup for a valid
# lifecycle/version call. Importing still verifies that the extension itself does
# not re-enable the GIL.
IMPORT_ONLY_COMPONENTS = ("cusolverMp",)

# These get_version() wrappers require a library handle. Other version wrappers
# are process-level functions and take no arguments.
VERSION_REQUIRES_HANDLE = {"cublas", "cusparse", "cusparseLt"}
ALL_COMPONENTS = CREATE_DESTROY_COMPONENTS + VERSION_ONLY_COMPONENTS + IMPORT_ONLY_COMPONENTS


def get_binding_module(component: str):
    """Import a public binding module by component name."""
    return importlib.import_module(f"nvmath.bindings.{component}")


def check_create_destroy(component: str):
    """Run the strongest cheap smoke check for components with lifecycle APIs."""
    module = get_binding_module(component)
    check_gil_disabled_if_free_threaded(f"after importing {component}")
    handle = None
    try:
        # cuSPARSELt names its handle constructor init() instead of create().
        if component == "cusparseLt":
            handle = module.init()
        else:
            handle = module.create()
        check_gil_disabled_if_free_threaded(f"after {component} create/init handle")
        if hasattr(module, "get_version"):
            module.get_version(handle) if component in VERSION_REQUIRES_HANDLE else module.get_version()
            check_gil_disabled_if_free_threaded(f"after {component}.get_version()")
    finally:
        if handle is not None:
            module.destroy(handle)
            check_gil_disabled_if_free_threaded(f"after {component}.destroy()")


def check_version(component: str):
    """Run a version query for components without a cheap lifecycle check."""
    module = get_binding_module(component)
    check_gil_disabled_if_free_threaded(f"after importing {component}")
    version = module.get_version()
    check_gil_disabled_if_free_threaded(f"after {component}.get_version()")
    print(f"{component} version: {version}")


def check_import(component: str):
    """Import a component without creating handles or loading optional libraries."""
    get_binding_module(component)
    check_gil_disabled_if_free_threaded(f"after importing {component}")


def is_nvpl_library_not_available(component: str, exc: RuntimeError) -> bool:
    """Check for the NVPL loader's expected missing-CPU-backend messages."""
    if component not in {"nvpl.blas", "nvpl.fft"}:
        return False
    return str(exc).startswith(
        (
            "Failed to dlopen all of the following libraries:",
            "Failed to dlopen either of the following libraries:",
        )
    )


def run_binding_test(component: str):
    """Run the binding smoke path selected for one component."""
    try:
        check_gil_disabled_if_free_threaded(f"before using {component}")
        if component in CREATE_DESTROY_COMPONENTS:
            check_create_destroy(component)
        elif component in VERSION_ONLY_COMPONENTS:
            check_version(component)
        elif component in IMPORT_ONLY_COMPONENTS:
            check_import(component)
        else:
            raise ValueError(f"Unsupported component: {component}")
    except (DynamicLibNotFoundError, FunctionNotFoundError, NotSupportedError) as exc:
        # Missing optional library symbols are reported, but do not mean the
        # free-threading declaration for the extension is wrong.
        print(f"Module {component} not available: {exc}")
    except RuntimeError as exc:
        if not is_nvpl_library_not_available(component, exc):
            raise
        print(f"Module {component} not available: {exc}")
    check_gil_disabled_if_free_threaded(f"after using {component}")
    print(f"{component} free-threading smoke check passed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Smoke check nvmath bindings on free-threaded Python builds.")
    parser.add_argument("component", choices=ALL_COMPONENTS)
    args = parser.parse_args()
    print(f"free-threaded build: {bool(sysconfig.get_config_var('Py_GIL_DISABLED'))}")
    run_binding_test(args.component)
