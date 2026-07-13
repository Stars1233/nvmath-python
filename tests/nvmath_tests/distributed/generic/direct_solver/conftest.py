# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Shared fixtures for the direct-solver test modules."""

from __future__ import annotations

import pytest

import nvmath.distributed

from .params import VALID_NRANKS


@pytest.fixture(scope="module", autouse=True)
def _skip_if_invalid_nranks(process_group):
    """Skip the whole module if ``nranks`` is outside :data:`params.VALID_NRANKS`."""
    if process_group.nranks not in VALID_NRANKS:
        pytest.skip(f"This module needs nranks in {VALID_NRANKS}; got {process_group.nranks}")


@pytest.fixture
def require_multi_rank(process_group):
    """Skip tests that rely on cross-rank divergence (rank 0 differing from its
    peers, or a multi-column process grid). There are no peer ranks at
    ``nranks=1``, so these checks can't be exercised on a single process.
    """
    if process_group.nranks < 2:
        pytest.skip(f"requires nranks >= 2 for cross-rank divergence; got {process_group.nranks}")


@pytest.fixture(scope="module")
def nvmath_distributed(process_group):
    """Initialize ``nvmath.distributed`` once per test module, finalize on exit.

    Resolves the rank's device id from the visible CUDA devices and
    brings up the NCCL backend (cuSOLVERMp's collective backend).
    Skips the module cleanly when more ranks than GPUs are launched,
    since NCCL only allows one rank per GPU.
    """
    from cuda.core import system

    try:
        num_devices = system.get_num_devices()
    except AttributeError:
        num_devices = system.num_devices

    if process_group.nranks > num_devices:
        pytest.skip(f"NCCL only allows one rank per GPU: nranks={process_group.nranks}, num_devices={num_devices}")

    device_id = process_group.rank % num_devices
    # cuSOLVERMp uses NCCL for its collectives
    nvmath.distributed.initialize(device_id, process_group, backends=["nccl"])

    yield

    nvmath.distributed.finalize()
