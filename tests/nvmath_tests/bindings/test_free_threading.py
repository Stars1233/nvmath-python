# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import subprocess
import sys
from pathlib import Path

import pytest
from cuda.core import Device

COMPUTE_CAPABILITY = Device().compute_capability

ALL_COMPONENTS = (
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
    "cublasMp",
    "curand",
    "cusolver",
    "mathdx",
    "nvpl.blas",
    "nvpl.fft",
    "cusolverMp",
)


@pytest.mark.parametrize("component", ALL_COMPONENTS)
def test_binding_keeps_gil_disabled(component):
    # cuTENSOR >= 2.3.1 dropped support for compute capability <= 7.0.
    if component == "cutensor" and COMPUTE_CAPABILITY <= (7, 0):
        pytest.skip("cuTensor 2.3.1+ requires compute capability > 7.0")

    checker = Path(__file__).with_name("check_free_threading.py")
    try:
        # Use one subprocess per component because an incompatible extension can
        # re-enable the GIL process-wide, and that state cannot be reset.
        # Do not pass "-X gil=0": this test verifies that importing and using
        # each binding keeps the GIL disabled without the runtime override.
        proc = subprocess.run(
            [sys.executable, checker, component],
            check=False,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired as exc:
        pytest.fail(f"subprocess timed out while testing {component}\nstdout:\n{exc.stdout}\nstderr:\n{exc.stderr}")
    assert proc.returncode == 0, f"stdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
