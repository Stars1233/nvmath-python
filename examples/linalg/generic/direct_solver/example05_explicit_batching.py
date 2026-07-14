# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example shows **explicit batching** for :func:`~nvmath.linalg.direct_solver`:
each batch member
is a separate dense matrix in a Python sequence (list) of LHS matrices and a matching
sequence of RHS matrices. The batched path uses cuBLAS (``getrfBatched``/``getrsBatched``).

**Implicit** batching stacks the batch dimension into rank-3 tensors instead; see the other
examples under this folder.

All systems in this demo share the same dimensions ``(n, n)`` and ``(n, nrhs)``; each LHS
must have the same square shape and each RHS the same leading shape, as required by the
solver checks.

Operands are real ``float64`` CuPy arrays on the GPU; default (C) memory order is fine.
"""

import cupy as cp

import nvmath.linalg as la

n = 8
nrhs = 2
n_batch = 2

rng = cp.random.default_rng(0)

# Explicit batch: one square matrix per batch entry, diagonally shifted for a stable LU.
a0 = rng.standard_normal((n, n)) + (n + 1) * cp.eye(n)
a1 = rng.standard_normal((n, n)) + (n + 1) * cp.eye(n)
a = [a0, a1]

# Matching RHS batch (same shape per member).
b0 = cp.ones((n, nrhs))
b1 = cp.ones((n, nrhs)) * 2
b = [b0, b1]

x = la.direct_solver(a, b)

cp.cuda.get_current_stream().synchronize()

print(f"Inputs were sequences of types {type(a[0])} and {type(b[0])}; result sequence element type is {type(x[0])}.")

for i in range(n_batch):
    cp.testing.assert_allclose(a[i] @ x[i], b[i], rtol=1e-4, atol=1e-5)
