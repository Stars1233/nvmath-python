# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving a dense square linear system ``a @ x = b`` with
:class:`nvmath.linalg.DirectSolver` via :func:`~nvmath.linalg.direct_solver`, using NumPy
operands with ``complex64`` dtype.

``nvmath.linalg.direct_solver`` plans, factorizes, and solves in one call. For non-batched
inputs, factorization uses cuSOLVER (LU with partial pivoting).
"""

import numpy as np

import nvmath.linalg as la

# Matrix order.
n = 8

# Random complex coefficient matrix, made diagonally dominant for a stable solution.
rng = np.random.default_rng(0)
re = rng.standard_normal((n, n), dtype=np.float32)
im = rng.standard_normal((n, n), dtype=np.float32)
a = (re + 1j * im).astype(np.complex64)
a += (n + 1) * np.eye(n, dtype=np.complex64)

# Right-hand side with two columns.
nrhs = 2
b = np.ones((n, nrhs), dtype=np.complex64)

# Solve a @ x = b for x.
x = la.direct_solver(a, b)

print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
assert isinstance(x, np.ndarray)

np.testing.assert_allclose(a @ x, b, rtol=1e-4, atol=1e-5)
