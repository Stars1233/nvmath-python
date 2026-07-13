# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates user-side in-place mutation of operands between stateful solves,
with CuPy (GPU) operands and a ``Slab.X`` distribution.

Unlike the other examples in this folder, this one intentionally constructs a system with
a known reference solution ``x_ref`` (every rank builds the same global 'a' from a shared
seed and derives ``b = a @ x_ref``, then slices its own row block) so that each solve can
be verified against ``x_ref``. That verification is what lets us explain the behavior of
each mutation scenario clearly below (including the silent wrong answer in scenario 2).

$ mpiexec -n 4 python example06_inplace.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg import DirectSolver, DirectSolverOptions

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
rows = slice(rank * local_n, (rank + 1) * local_n)


def create_matrix(*, seed):
    """Build the global diagonally-dominant matrix 'a' from a shared seed."""
    rng = cp.random.default_rng(seed)
    return rng.standard_normal((n, n), dtype=dtype) + n * cp.eye(n, dtype=dtype)


def create_rhs(a_global, *, seed):
    """Pick a reference 'x' from a shared seed and derive b = a @ x; return this rank's
    local row block of 'b' together with the matching block of 'x' for verification."""
    rng = cp.random.default_rng(seed)
    x_ref = rng.standard_normal((n, nrhs), dtype=dtype)
    b_global = a_global @ x_ref
    return cp.asfortranarray(b_global[rows, :]), x_ref[rows, :]


# Initial system. inplace_a/inplace_b = True (the solver defaults):
# since the operands are already on the device, the solver works
# directly on our 'a' and 'b' buffers -- factorize() writes the LU factors into 'a',
# and solve() writes the solution into 'b' and returns it.
# Working in place is what lets us drive new solves by editing
# the operands directly below.
a_global = create_matrix(seed=33)
a = cp.asfortranarray(a_global[rows, :])
b, x_ref_local = create_rhs(a_global, seed=100)
options = DirectSolverOptions(inplace_a=True, inplace_b=True)

with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
    solver.plan()
    solver.factorize()
    x = solver.solve()
    cp.testing.assert_allclose(x, x_ref_local, rtol=1e-6, atol=1e-6)

    # Now, 'a' holds the LU factors and 'b' holds
    # the solution (solve() returns 'b', so 'x' is 'b').

    # Scenario 1: solve a new right-hand side by editing 'b' in place.
    # inplace_b=True means the previous solve() left its solution in 'b',
    # so we overwrite it with the new RHS and
    # solve again. The LU in 'a' is untouched, so no re-factorize is needed.
    b_new, x_ref_local = create_rhs(a_global, seed=101)
    b[:] = b_new
    x = solver.solve()
    cp.testing.assert_allclose(x, x_ref_local, rtol=1e-6, atol=1e-6)

    # Scenario 2: editing 'a' in place is silently wrong. inplace_a=True
    # means the LU lives in 'a'; overwriting it with a new matrix destroys
    # those factors, and solve() never re-factorizes on its own,
    # it runs the triangular solve against whatever is in 'a'.
    a_global = create_matrix(seed=1)
    a[:] = a_global[rows, :]  # destroys the LU stored in 'a'
    b_new, x_ref_local = create_rhs(a_global, seed=200)
    b[:] = b_new
    x = solver.solve()
    try:
        cp.testing.assert_allclose(x, x_ref_local, rtol=1e-6, atol=1e-6)
    except AssertionError:
        pass  # expected: a non-factorized 'a' produces a wrong answer
    else:
        raise RuntimeError("expected the destroyed-LU solve to produce a wrong answer; got the right one")

    # Scenario 3: the fix is to re-factorize: this re-reads the
    # in-place-edited 'a' and rebuilds the LU factors.
    # Scenario 2's solve overwrote 'b' with its (wrong) solution,
    # so re-supply the RHS before solving again.
    solver.factorize()
    b[:] = b_new
    x = solver.solve()
    cp.testing.assert_allclose(x, x_ref_local, rtol=1e-6, atol=1e-6)

if rank == 0:
    print(f"User-side in-place edit scenarios complete on {nranks} process(es).")
