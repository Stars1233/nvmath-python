# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates ``reset_operands(a=...)`` and how updating 'a' differs from
updating the right-hand side 'b' in the stateful distributed direct solver,
with CuPy operands and a ``Slab.X`` distribution: when 'a' changes, the cached LU
factorization is stale and must be recomputed, whereas a new 'b' can be solved directly.
For the cheap b-side workflow (new RHS without re-factorizing),
see ``example04_stateful.py``.

$ mpiexec -n 4 python example04_stateful_reset.py
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

    # New matrix via reset_operands(a=, b=): this invalidates the cached LU,
    # so factorize() must run before the next solve().
    a = random_matrix()
    b = random_rhs()
    solver.reset_operands(a=a, b=b)
    solver.factorize()
    solver.solve()

    # release_operands() drops the solver's internal references to the user operands,
    # so the user can potentially decide whether to reuse or free that memory.
    # This enables users to interleave multiple large solver operations
    # without having to recreate the stateful objects.
    solver.release_operands()

    # After a release, reset_operands(a=..., b=...) must re-supply both operands
    # before solving again; a new 'a' still needs a factorize().
    a = random_matrix()
    b = random_rhs()
    solver.reset_operands(a=a, b=b)
    solver.factorize()
    solver.solve()

cp.cuda.get_current_stream().synchronize()

if rank == 0:
    print(f"Stateful reset workflow complete on {nranks} process(es).")
