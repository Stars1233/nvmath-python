# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates configuring the distributed direct solver through
:class:`~nvmath.distributed.linalg.DirectSolverOptions`, using CuPy operands and a
``Slab.X`` distribution. It covers three themes, each in its own titled block:

1. Logging (global): configure the root logger and the solver logs its phases there.
2. Logging (user): pass a custom logger via ``DirectSolverOptions(logger=...)``.
3. ``blocking``: ``True`` vs ``"auto"`` (the default)

The ``inplace_a`` / ``inplace_b`` options (whether the user's operand buffers are reused
and overwritten or preserved) are discussed in the docstring of
``example06_inplace.py``, which uses them to set up user-side in-place editing of
operands between stateful solves.

$ mpiexec -n 4 python example05_options.py
"""

import logging

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolverOptions, direct_solver

# Initialize nvmath.distributed.
# cuSOLVERMp requires the NCCL communication backend.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % cp.cuda.runtime.getDeviceCount()
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Make this rank's device current for all CuPy operations below.
cp.cuda.Device(device_id).use()

n = 256
nrhs = 8
dtype = cp.float64
assert n % nranks == 0, "for simplicity this example requires n divisible by the process count"
local_n = n // nranks

distributions = [Slab.X, Slab.X]

# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)


def create_operands():
    a = rng.random((local_n, n)).astype(dtype, order="F")
    # Make the global 'a' diagonally dominant so the system is well-conditioned: a[i, i] of
    # this rank's row band lives at local position [k, rank * local_n + k].
    idx = cp.arange(local_n)
    a[idx, rank * local_n + idx] += n
    b = rng.random((local_n, nrhs)).astype(dtype, order="F")
    return a, b


# 1) Global logging
# Configure the root logger; a solve with no explicit logger logs its phases there.
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(levelname)s %(message)s", datefmt="%H:%M:%S")
a, b = create_operands()
direct_solver(a, b, distributions=distributions)

# 2) User logging
# A dedicated logger (propagate=False so it does not also go through the root logger).
user_logger = logging.getLogger("direct_solver_example")
user_logger.setLevel(logging.INFO)
user_logger.propagate = False
if not user_logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("[user] %(levelname)s %(message)s"))
    user_logger.addHandler(handler)
a, b = create_operands()
direct_solver(a, b, distributions=distributions, options=DirectSolverOptions(logger=user_logger))

# Parts 1 and 2 run on the CuPy current stream and could potentially be non-blocking,
# so synchronize it to ensure their GPU work has completed before moving on.
cp.cuda.get_current_stream().synchronize()

# 3) blocking
# blocking=True forces blocking execution, so no explicit synchronization is needed after.
a, b = create_operands()
direct_solver(a, b, distributions=distributions, options=DirectSolverOptions(blocking=True))

if rank == 0:
    print(f"Ran logging and blocking option demos on {nranks} process(es).")
