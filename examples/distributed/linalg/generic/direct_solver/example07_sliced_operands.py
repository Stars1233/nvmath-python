# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates performing a direct solve with sliced (non-contiguous) operands,
with CuPy (GPU) operands and a ``Slab.X`` distribution. It is a contrived example that also
verifies the computed solution against a known reference.

$ mpiexec -n 4 python example07_sliced_operands.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import direct_solver

# Initialize nvmath.distributed. cuSOLVERMp requires the NCCL communication backend.
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
rows = slice(rank * local_n, (rank + 1) * local_n)


# cuSOLVERMp accepts a column-major operand whose *leading dimension*
# is larger than its number of local rows -- in other words, a slice
# ``parent[:rows, :cols]`` of a bigger allocation.
# This is useful when a local tile is a window into a preallocated buffer
# and you would rather not copy it into a tight array before solving.
def sliced_local(global_array, *, pad_rows, pad_cols=0):
    """Return this rank's local row band as a *view* into an oversized column-major parent.

    The parent has ``pad_rows`` extra rows (and ``pad_cols`` extra columns), so the returned
    view has unit row stride but a column stride of ``local_n + pad_rows`` -- a leading
    dimension larger than the ``local_n`` logical rows. The solver reads only the logical
    ``(local_n, cols)`` window and uses the parent's column stride as the descriptor's
    leading dimension; no copy to a tight buffer is needed.
    """
    local = global_array[rows]
    local_rows, cols = local.shape
    parent = cp.empty((local_rows + pad_rows, cols + pad_cols), dtype=dtype, order="F")
    view = parent[:local_rows, :cols]
    view[:] = local
    return view


# Build the global system from a shared seed (identical on every rank) with a known solution
# x_ref, so b = a @ x_ref and each rank can check its own band of x against x_ref.
rng = cp.random.default_rng(0)
a_global = rng.standard_normal((n, n), dtype=dtype) + n * cp.eye(n, dtype=dtype)
x_ref = rng.standard_normal((n, nrhs), dtype=dtype)
b_global = a_global @ x_ref

# 'a' and 'b' are passed as padded slices: both are padded on both axes, so their column
# stride exceeds local_n (a leading dimension larger than the local row count) and there
# is also storage past the last logical column.
a = sliced_local(a_global, pad_rows=4, pad_cols=2)
b = sliced_local(b_global, pad_rows=4, pad_cols=2)
assert a.strides[1] // a.dtype.itemsize == local_n + 4, "'a' leading dimension should exceed local rows (padded slice)"
assert b.strides[1] // b.dtype.itemsize == local_n + 4, "'b' leading dimension should exceed local rows (padded slice)"

x = direct_solver(a, b, distributions=[Slab.X, Slab.X])

# inplace_b defaults to True, so the solve writes 'x' in place into the padded parent
# of 'b' and returns b itself. x is the same (Slab.X-distributed) padded view, no copy made.
assert x is b, "with inplace_b=True (the default), direct_solver should return the same object as 'b'"
assert tuple(x.shape) == (local_n, nrhs), f"solution 'x' shape {tuple(x.shape)} should match local 'b' shape {(local_n, nrhs)}"

# Verify this rank's block of 'x' against the reference solution.
cp.testing.assert_allclose(x, x_ref[rows], rtol=1e-6, atol=1e-6)

if rank == 0:
    lld = a.strides[1] // a.dtype.itemsize
    print(f"Solved a {n}x{n} system with sliced (padded leading-dimension) operands across {nranks} process(es).")
    print(f"Local 'a' leading dimension was {lld} for {local_n} local rows (padded slice of a larger buffer).")
