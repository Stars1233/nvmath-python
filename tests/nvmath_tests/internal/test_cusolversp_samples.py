# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import glob
import os
import sys

import pytest

# Must precede this directory on sys.path: a distinct ``internal/test_utils.py`` exists
# here for other tests; ``run_sample`` lives under ``tests/example_tests/test_utils.py``.
_example_tests = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "example_tests"))
sys.path.insert(0, _example_tests)
from test_utils import run_sample  # noqa: E402

samples_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "internal", "examples", "_bindings", "cusolverSp")
sample_files = glob.glob(os.path.join(samples_path, "**", "*.py"), recursive=True)


@pytest.mark.parametrize("sample", sample_files)
class TestCusolverSpSamples:
    def test_sample(self, sample):
        run_sample(samples_path, os.path.basename(sample), {"__name__": "__main__"})
