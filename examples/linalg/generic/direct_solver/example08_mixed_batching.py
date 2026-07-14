# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Mixed batching** for :func:`~nvmath.linalg.direct_solver`:
the LHS can be **explicit** (a Python
sequence of square matrices) while the RHS is **implicit** (one dense tensor with shape
``(n_batch, n, nrhs)``). The converse (implicit LHS, explicit RHS) is also supported.

Compare:

* ``example05_explicit_batching.py`` — both operands given as sequences.
* ``example06_implicit_batching.py`` — both operands as stacked tensors (one batch dim).

Operands are real ``float64`` CuPy arrays on the GPU.
"""

import cupy as cp

import nvmath.linalg as la

n = 8
n_batch = 2
nrhs = 2

rng = cp.random.default_rng(0)

# Explicit LHS: list of (n, n) systems.
a0 = rng.standard_normal((n, n)) + (n + 1) * cp.eye(n)
a1 = rng.standard_normal((n, n)) + (n + 1) * cp.eye(n)
a = [a0, a1]

# Implicit RHS: one ndarray, batch leading dimension matches len(a).
b = cp.ones((n_batch, n, nrhs), dtype=cp.float64)

rtol = 1e-4
atol = 1e-5

x = la.direct_solver(a, b)

cp.cuda.get_current_stream().synchronize()

print(f"LHS list element type {type(a[0])}; RHS ndarray shape {b.shape}; solution shape {x.shape}.")

for i in range(n_batch):
    cp.testing.assert_allclose(a[i] @ x[i], b[i], rtol=rtol, atol=atol)
