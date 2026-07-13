# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving a dense square linear system ``a @ x = b`` with the
distributed :func:`~nvmath.distributed.linalg.direct_solver`, using CuPy
operands with a 2D block-cyclic distribution and multiple right-hand sides.

All sizes below are for ``n = 128``, ``nrhs = 16``, on 4 ranks.
'a' and 'b' share an 8-row block size (this is a hard requirement: ``mb_a == mb_b``)
but use different column block factors to illustrate that the
column block factor is independent.

A 2x2 column-major process grid; 'a' uses an ``8x8`` block factor and 'b' uses ``8x4``.

The schematic below: the 4 ranks sit in a 2x2 grid with column-major layout.
Each matrix is cut into blocks (8 rows tall for both 'a' and 'b';
8 columns wide for 'a', 4 for 'b'). Counting blocks from the top-left as row ``I`` and
column ``J``, the block at (I, J) is owned by the rank sitting at grid row ``I % 2``
and grid column ``J % 2``. The numbers inside the grids below are those owning ranks.

    PROCESS GRID (2x2, COL_MAJOR)        n = 128   -> 16 block-rows (I = 0..15)
       ---------                         'a': 16 block-cols of width 8
       | 0 | 2 |   grid row 0            nrhs = 16 -> 'b': 4 block-cols of width 4
       ---------
       | 1 | 3 |   grid row 1
       ---------
 grid col 0  1

    'a': 16x16 grid of 8x8 blocks          'b' and 'x': 16x4 grid of 8x4 blocks
         J: 0 1 2 3 ... 14 15                J: 0 1 2 3
            +-----------------+                  +-------+
       I=0  | 0 2 0 2 ... 0 2|            I=0    |0 2 0 2|   cols 0-3 | 4-7 | 8-11 | 12-15
       I=1  | 1 3 1 3 ... 1 3|            I=1    |1 3 1 3|
       I=2  | 0 2 0 2 ... 0 2|            ...    |. . . .|
       I=3  | 1 3 1 3 ... 1 3|            I=15   |1 3 1 3|
        ...                                     +-------+
       I=14 | 0 2 0 2 ... 0 2|
       I=15 | 1 3 1 3 ... 1 3|
            +-----------------+

Each rank's local 'a' is 64x64 and local 'b' is 64x8. 'x' uses the same distribution as
'b', so each rank's local 'x' is also 64x8.

The operands here are filled with random values: this example focuses on the distribution
mechanics and asserts on local shapes only. See ``example06_inplace.py`` for a
numerically verified solve, and ``example02_2d_block_cyclic_single_rhs_4p.py`` for the
single-RHS caveat.

$ mpiexec -n 4 python example02_2d_block_cyclic_multi_rhs_4p.py
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

# Global square system: 'a' is (n, n), 'b' is (n, nrhs).
n = 128
nrhs = 16
dtype = cp.float64

# 2D 2x2 process grid (4 processes) with column-major layout.
# ---------
# | 0 | 2 |
# ---------
# | 1 | 3 |
# ---------
process_grid = ProcessGrid(shape=(2, 2), layout=ProcessGrid.Layout.COL_MAJOR)

# Block-cyclic distributions. 'a' and 'b' share the row block factor (cuSOLVERMp requires
# mb_b == mb_a) but 'b' uses a smaller column block factor than 'a' to illustrate that the
# column block factor of 'b' is independent of that of 'a'.
a_distribution = BlockCyclic(process_grid, block_sizes=(8, 8))
b_distribution = BlockCyclic(process_grid, block_sizes=(8, 4))

# Local shapes on this rank according to each distribution.
a_shape = a_distribution.shape(rank, (n, n))
b_shape = b_distribution.shape(rank, (n, nrhs))

# Seeding for reproducibility. Column-major layout is required by cuSOLVERMp.
rng = cp.random.default_rng(rank)
a = rng.random(a_shape).astype(dtype, order="F")
b = rng.random(b_shape).astype(dtype, order="F")

# 'a' and 'b' are block-cyclic on the same process grid but with
# different column block factors.
# Solve a @ x = b for x. inplace_b defaults to True, so 'x' is written into 'b' in place
x = direct_solver(a, b, distributions=[a_distribution, b_distribution])

# Synchronize the default stream, since execution may be non-blocking for GPU operands.
cp.cuda.get_current_stream().synchronize()

# 'x' is 'b' (same buffer); it uses the same distribution as 'b',
# so their local shapes match.
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == tuple(b_shape), f"rank {rank}: 'x' shape {tuple(x.shape)} != local 'b' shape {tuple(b_shape)}"
assert isinstance(x, cp.ndarray), f"solution 'x' should be a cupy.ndarray, got {type(x)}"

print(f"Rank {rank}: local 'a' shape {tuple(a_shape)}.")
print(f"Rank {rank}: local 'b' shape {tuple(b_shape)}, 'x' shape {tuple(x.shape)}.")

if rank == 0:
    print(f"Solved a {n}x{n} system with {nrhs} right-hand sides on a 2x2 process grid.")
