# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Solve a dense square linear system ``a @ x = b`` via
:func:`~nvmath.distributed.linalg.direct_solver`, using CuPy operands on the GPU.
This is the GPU counterpart of ``example01_numpy.py``.

$ mpiexec -n 4 python example01_cupy.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import direct_solver

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
dtype = cp.float64  # see docs for supported dtypes
assert n % nranks == 0, "for simplicity this example requires n divisible by the process count"
local_n = n // nranks

# Both 'a' and 'b' use a Slab.X distribution, which is a special case of
# the 2D block-cylic distribution: each process owns a contiguous row block of the
# global tensor (process r owns rows [r * local_n : (r + 1) * local_n)).
distributions = [Slab.X, Slab.X]

# Each rank constructs its own local row slab directly.
# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)
a = rng.random((local_n, n)).astype(dtype, order="F")
b = rng.random((local_n, nrhs)).astype(dtype, order="F")

# Make the global 'a' diagonally dominant so the system is well-conditioned:
# a[i, i] of this rank's row band lives at local position [k, rank * local_n + k].
idx = cp.arange(local_n)
a[idx, rank * local_n + idx] += n

x = direct_solver(a, b, distributions=distributions)

# Synchronize the default stream, since execution may be non-blocking for GPU operands.
cp.cuda.get_current_stream().synchronize()

# inplace_b defaults to True, so the solve wrote the solution into 'b'
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == tuple(b.shape), f"solution 'x' shape {tuple(x.shape)} should match 'b' shape {tuple(b.shape)}"
assert isinstance(x, cp.ndarray), f"solution 'x' should be a cupy.ndarray, got {type(x)}"

if rank == 0:
    print(f"Solved a {n}x{n} system with {nrhs} right-hand side(s) across {nranks} process(es).")
    print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
