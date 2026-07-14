# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Solve a dense square linear system ``a @ x = b`` via
:func:`~nvmath.distributed.linalg.direct_solver`, using NumPy operands.

$ mpiexec -n 4 python example01_numpy.py
"""

import numpy as np
from cuda.core import system
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import direct_solver

# Initialize nvmath.distributed.
# cuSOLVERMp requires the NCCL communication backend.
num_devices = system.get_num_devices()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % num_devices
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Global square system: 'a' is (n, n), 'b' is (n, nrhs).
n = 256
nrhs = 8  # number of right-hand sides; set to 1 for a single RHS ('b' stays 2D, shape (n, 1))
dtype = np.float64  # see docs for supported dtypes
assert n % nranks == 0, "for simplicity this example requires n divisible by the process count"
local_n = n // nranks

# Both 'a' and 'b' use a Slab.X distribution, which is a special case of
# the 2D block-cylic distribution: each process owns a contiguous row block of the
# global tensor (process r owns rows [r * local_n : (r + 1) * local_n)).
distributions = [Slab.X, Slab.X]

# Each rank constructs its own local row slab directly.
# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = np.random.default_rng(rank)
a = rng.random((local_n, n)).astype(dtype, order="F")
b = rng.random((local_n, nrhs)).astype(dtype, order="F")

# Make the global 'a' diagonally dominant so the system is well-conditioned: a[i, i] of this
# rank's row band lives at local position [k, rank * local_n + k].
idx = np.arange(local_n)
a[idx, rank * local_n + idx] += n

x = direct_solver(a, b, distributions=distributions)

# No synchronization is needed for CPU operands, since the execution always blocks.
# inplace_b defaults to True, so the solution was written into 'b' in place
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == tuple(b.shape), f"solution 'x' shape {tuple(x.shape)} should match 'b' shape {tuple(b.shape)}"
assert isinstance(x, np.ndarray), f"solution 'x' should be a numpy.ndarray, got {type(x)}"

if rank == 0:
    print(f"Solved a {n}x{n} system with {nrhs} right-hand side(s) across {nranks} process(es).")
    print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
