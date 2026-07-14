# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import glob
import os
import sys

import pytest

from nvmath_tests.helpers import requires_cusparselt

# Must precede this directory on sys.path (see ``internal/test_utils.py`` vs example_tests).
_example_tests = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "example_tests"))
sys.path.insert(0, _example_tests)
from test_utils import run_sample  # noqa: E402

samples_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "internal", "examples", "_bindings", "cusparseLt")
sample_files = glob.glob(os.path.join(samples_path, "**", "*.py"), recursive=True)


@requires_cusparselt
@pytest.mark.parametrize("sample", sample_files)
class TestCusparseLtSamples:
    def test_sample(self, sample):
        run_sample(samples_path, os.path.basename(sample), {"__name__": "__main__"})
