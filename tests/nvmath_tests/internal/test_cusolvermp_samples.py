# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import glob
import os
import sys

import cuda.pathfinder
import pytest

try:
    cuda.pathfinder.load_nvidia_dynamic_lib("cusolverMp")
    import cupy  # noqa: F401
    import mpi4py  # noqa: F401
    import nccl  # noqa: F401
except (cuda.pathfinder.DynamicLibNotFoundError, ImportError):
    pytest.skip(allow_module_level=True, reason="required dependencies not found")

# Must precede this directory on sys.path (see ``internal/test_utils.py`` vs example_tests).
_example_tests = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "example_tests"))
sys.path.insert(0, _example_tests)
from test_utils import run_sample  # noqa: E402

samples_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "internal", "examples", "_bindings", "cusolverMp")


def get_sample_files():
    return glob.glob(os.path.join(samples_path, "**", "*.py"), recursive=True)


class TestCusolverMpSamples:
    @pytest.mark.parametrize("sample", get_sample_files())
    def test_sample(self, sample):
        run_sample(samples_path, os.path.basename(sample), use_mpi=True, use_subprocess=True)
