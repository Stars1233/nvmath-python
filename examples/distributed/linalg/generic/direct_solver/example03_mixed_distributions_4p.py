# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example solves ``a @ x = b`` where 'a' and 'b' use different distributions:
'a' has a 2D (2x2) block-cyclic process grid, while 'b' is row-partitioned (``Slab.X``).

This example fills the operands with random values and asserts on the local shapes only
(see ``example06_inplace.py`` for a numerically verified solve).

$ mpiexec -n 4 python example03_mixed_distributions_4p.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import BlockCyclic, ProcessGrid, Slab
from nvmath.distributed.linalg import direct_solver

# Initialize nvmath.distributed. cuSOLVERMp requires the NCCL communication backend.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % cp.cuda.runtime.getDeviceCount()
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Make this rank's device current for all CuPy operations below.
cp.cuda.Device(device_id).use()

assert nranks == 4, "This example requires 4 processes for a 2x2 process grid"

# Global square system: 'a' is (n, n), 'b' is (n, nrhs).
n = 256
nrhs = 8
dtype = cp.float64

# 'a' and 'b' may use different distributions, but the row block factor chosen
# for 'a' must match the row block factor of 'b'. We pick the distribution of 'b' first,
# then size the blocks of 'a' to match.

# 1. 'b' has Slab.X: each rank owns a contiguous band of n // nranks rows.
b_dist = Slab.X
local_n = n // nranks  # Slab.X row band of 'b'

# 2. 'a' is 2D block-cyclic on a 2x2 column-major grid. Its row block size (mb) is
# set to the row band of 'b' so the layouts line up; the column block size (nb)
# is free (we reuse mb here).
process_grid = ProcessGrid(shape=(2, 2), layout=ProcessGrid.Layout.COL_MAJOR)
mb = nb = local_n  # = 64
a_dist = BlockCyclic(process_grid, block_sizes=(mb, nb))

# Local shapes on this rank: 'a' is 2D block-cyclic, 'b' is a contiguous row band.
a_shape = a_dist.shape(rank, (n, n))
b_shape = (local_n, nrhs)

# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)
a = rng.random(a_shape).astype(dtype, order="F")
b = rng.random(b_shape).astype(dtype, order="F")

# 'a' is block-cyclic, 'b' is Slab.X. inplace_b defaults to True,
# so the solve writes 'x' into 'b' in place
x = direct_solver(a, b, distributions=[a_dist, b_dist])

cp.cuda.get_current_stream().synchronize()

# 'x' is 'b'
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == tuple(b_shape), f"rank {rank}: 'x' shape {tuple(x.shape)} != local 'b' shape {tuple(b_shape)}"
assert isinstance(x, cp.ndarray), f"solution 'x' should be a cupy.ndarray, got {type(x)}"

print(f"Rank {rank}: local 'a' {tuple(a_shape)} (block-cyclic), local 'b'/'x' {tuple(x.shape)} (Slab.X).")

if rank == 0:
    print(f"Solved a {n}x{n} system with block-cyclic 'a' and Slab.X 'b' (mb = {mb}) on a 2x2 grid.")
