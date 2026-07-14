# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving implicitly batched systems of linear equations
with both ``inplace_a=True`` and ``inplace_b=True``. The inputs are CuPy
tensors on the GPU.

The batch entries are matrix slices in tensors with leading batch dimensions.
For GPU operands, ``inplace_a=True`` factorizes directly in the storage of each
LHS matrix slice, so ``a`` is overwritten by LU factors. Similarly,
``inplace_b=True`` writes each solution directly into the corresponding RHS
slice and returns ``b``. These options may also be used independently.

For GPU inputs with implicit batching, every matrix slice in ``a`` must be
row-major or column-major when using ``inplace_a=True``. Every matrix
right-hand side slice in ``b`` must be column-major when using
``inplace_b=True``.
"""

import cupy as cp

import nvmath.linalg as la

n = 8
n_batch = 2
nrhs = 2

rng = cp.random.default_rng(0)

a = rng.standard_normal((n_batch, n, n), dtype=cp.float64)
a += (n + 1) * cp.eye(n, dtype=cp.float64)
b = cp.ones((n_batch, nrhs, n), dtype=cp.float64).transpose(0, 2, 1)

a_ref = a.copy()
b_ref = b.copy()

# ``inplace_a`` and ``inplace_b`` can also be used independently.
options = {"inplace_a": True, "inplace_b": True}
x = la.direct_solver(a, b, options=options)

print(f"Solution: {x}")
print(f"a overwritten: {not bool(cp.allclose(a, a_ref))}")
print(f"b overwritten: {not bool(cp.allclose(b, b_ref))}")
print(f"x aliases b: {x is b}")

cp.testing.assert_allclose(a_ref @ x, b_ref, rtol=1e-4, atol=1e-5)
