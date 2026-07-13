# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Shared parametrization data for the distributed :class:`DirectSolver` tests."""

from __future__ import annotations

import os

import pytest

from nvmath.distributed._internal.tensor_wrapper import maybe_register_package

# ``nranks`` must be known at import time so ``uncollect_if`` (which runs before
# fixtures) can prune nranks-dependent combos, and so module-level skip marks can
# be built. Mirrors ``test_matmul.py``: read ``WORLD_SIZE`` under torchrun (where
# importing mpi4py is explicitly disallowed), else fall back to MPI.
if "TORCHELASTIC_RUN_ID" in os.environ:
    NRANKS = int(os.environ["WORLD_SIZE"])
else:
    from mpi4py import MPI

    NRANKS = MPI.COMM_WORLD.Get_size()

# Process counts the suite is designed for. ``GLOBAL_N`` divides evenly by each.
VALID_NRANKS = (1, 2, 4)
GLOBAL_N = 64
NRHS = 4

# Slab tags used by the e2e sweep: "R" == row-partitioned, "C" == col-partitioned.
PARTITION_DIM = {"R": 0, "C": 1}

# ``(package, memory_space)`` combos for the e2e correctness sweep. The
# ``inplace`` axis is orthogonal and parametrized separately by each test.
# numpy/cpu is always present; cupy and torch are optional and extend the sweep
# only when importable. Registering the package with the distributed tensor
# wrapper here keeps the registration next to the availability probe.
PACKAGE_MEMSPACES: list[tuple[str, str]] = [
    ("numpy", "cpu"),
]

try:
    import cupy  # noqa: F401

    HAS_CUPY = True
    maybe_register_package("cupy")
    PACKAGE_MEMSPACES.append(("cupy", "cuda"))
except ImportError:
    HAS_CUPY = False

try:
    import torch  # noqa: F401

    maybe_register_package("torch")
    PACKAGE_MEMSPACES.extend([("torch", "cpu"), ("torch", "cuda")])
except ImportError:
    pass

# cuda-operand tests need cupy for array construction/comparison.
skip_if_no_cupy = pytest.mark.skipif(not HAS_CUPY, reason="cupy is required for cuda-operand tests")
