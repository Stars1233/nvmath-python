# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the stateful :class:`nvmath.linalg.DirectSolver` API. Separating
``plan()``, ``factorize()``, and ``solve()`` lets you reuse preparation across multiple
solves (see :func:`~nvmath.linalg.direct_solver` for a one-shot equivalent).

The inputs and result are CuPy ndarrays on the GPU.
"""

import cupy as cp

import nvmath.linalg as la

# Matrix order.
n = 8

# Random complex coefficient matrix, made diagonally dominant for a stable solution.
rng = cp.random.default_rng(0)
re = rng.standard_normal((n, n), dtype=cp.float32)
im = rng.standard_normal((n, n), dtype=cp.float32)
a = (re + 1j * im).astype(cp.complex64)
a += (n + 1) * cp.eye(n, dtype=cp.complex64)

# Right-hand side with two columns.
nrhs = 2
b = cp.ones((n, nrhs), dtype=cp.complex64)

# Solve a @ x = b for x.
# Use the stateful object as a context manager to automatically release resources.
with la.DirectSolver(a, b) as solver:
    # Planning queries LU workspace sizes (cuSOLVER) for non-batched inputs.
    solver.plan()
    solver.factorize()
    x = solver.solve()

    # Synchronize the default stream, since execution may be non-blocking for GPU operands.
    cp.cuda.get_current_stream().synchronize()

print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
assert isinstance(x, cp.ndarray)

cp.testing.assert_allclose(a @ x, b, rtol=1e-4, atol=1e-5)
