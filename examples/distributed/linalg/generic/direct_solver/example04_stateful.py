# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates the stateful distributed direct solver,
:class:`~nvmath.distributed.linalg.DirectSolver`, with CuPy operands and a
``Slab.X`` distribution: factorize once and solve many times with different
right-hand sides.

$ mpiexec -n 4 python example04_stateful.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolver

# Initialize nvmath.distributed.
# cuSOLVERMp requires the NCCL communication backend.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % cp.cuda.runtime.getDeviceCount()
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Make this rank's device current for all CuPy operations below.
cp.cuda.Device(device_id).use()

# Global square system: 'a' is (n, n), 'b' is (n, nrhs).
n = 256
nrhs = 8
dtype = cp.float64
assert n % nranks == 0, "for simplicity this example requires n divisible by the process count"
local_n = n // nranks

# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)


def random_matrix():
    """Allocate this rank's column-major local row slab of 'a' (diagonally dominant)."""
    a = rng.random((local_n, n)).astype(dtype, order="F")
    # a[i, i] of this rank's row band lives at local position [k, rank * local_n + k].
    idx = cp.arange(local_n)
    a[idx, rank * local_n + idx] += n
    return a


def random_rhs():
    """Allocate this rank's column-major local row slab of 'b' (local_n, nrhs)."""
    return rng.random((local_n, nrhs)).astype(dtype, order="F")


# Each rank constructs its own local row slab directly.
a = random_matrix()
b = random_rhs()

with DirectSolver(a, b, distributions=[Slab.X, Slab.X]) as solver:
    solver.plan()
    solver.factorize()
    solver.solve()

    # Factorize-once / solve-many: bind new right-hand sides for the same
    # 'a' via reset_operands(b=...). No re-factorization.
    for _ in range(3):
        b = random_rhs()
        solver.reset_operands(b=b)
        solver.solve()

cp.cuda.get_current_stream().synchronize()

if rank == 0:
    print(f"Stateful solve complete on {nranks} process(es): one factorization, many solves.")
