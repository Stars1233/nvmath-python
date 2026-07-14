# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example solves ``a @ x = b`` with a 2D block-cyclic distribution and a single
right-hand side via :func:`~nvmath.distributed.linalg.direct_solver`.

It uses the same 2x2 process grid as ``example02_2d_block_cyclic_multi_rhs_4p.py``
(see that file for the ownership schematic). Operands are random; only local shapes are
asserted (see ``example06_inplace.py`` for a numerically verified solve).

$ mpiexec -n 4 python example02_2d_block_cyclic_single_rhs_4p.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import BlockCyclic, ProcessGrid
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

assert nranks == 4, "This example requires 4 processes"

# Global square system: 'a' is (n, n), 'b' is (n, nrhs) with a single right-hand side.
n = 128
nrhs = 1
dtype = cp.float64

# 2D 2x2 process grid (4 processes) with column-major layout. 'a' uses an 8x8 block factor;
# 'b' uses an 8x1 block factor -- the row block factor must match that of 'a' (cuSOLVERMp
# requires mb_b == mb_a), and the column block factor is naturally sized to the single RHS.
process_grid = ProcessGrid(shape=(2, 2), layout=ProcessGrid.Layout.COL_MAJOR)
a_distribution = BlockCyclic(process_grid, block_sizes=(8, 8))
b_distribution = BlockCyclic(process_grid, block_sizes=(8, 1))

# Single-RHS caveat: the columns of 'b' are spread across the grid's two process columns,
# but with only one RHS there is a single column to give out, and it all goes to the first
# process column. So on this 2x2 grid, the two ranks in the first process column each
# hold a (local_rows, 1) slice of 'b' and 'x', while the two ranks in the second process
# column get a (local_rows, 0) slice -- nothing at all. Those idle ranks still help
# factorize 'a' across the full grid, but contribute nothing to the solve itself: for a
# single RHS, the second grid column is wasted.
# When nrhs is small, prefer a 1D Slab.X RHS distribution instead.
nprow, npcol = process_grid.shape
mypcol = rank // nprow  # this rank's process-column index
a_shape = a_distribution.shape(rank, (n, n))
b_shape = b_distribution.shape(rank, (n, nrhs))

# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)
a = rng.random(a_shape).astype(dtype, order="F")
b = rng.random(b_shape).astype(dtype, order="F")

x = direct_solver(a, b, distributions=[a_distribution, b_distribution])

cp.cuda.get_current_stream().synchronize()

# The single RHS column is owned only by process-column 0.
expected_b_cols = 1 if mypcol == 0 else 0
assert b_shape[1] == expected_b_cols, f"rank {rank}: expected {expected_b_cols} 'b' columns, got {b_shape[1]}"
# inplace_b defaults to True, so 'x' is 'b': the solve wrote 'x' into 'b' in place
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == tuple(b_shape), f"rank {rank}: 'x' shape {tuple(x.shape)} != local 'b' shape {tuple(b_shape)}"
assert isinstance(x, cp.ndarray), f"solution 'x' should be a cupy.ndarray, got {type(x)}"

print(f"Rank {rank} (process column {mypcol}): local 'b'/'x' shape {tuple(x.shape)}.")
print(f"Rank {rank} (process column {mypcol}): {'empty' if b_shape[1] == 0 else 'owns the RHS'}.")
