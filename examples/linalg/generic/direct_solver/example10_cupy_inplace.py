# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving a non-batched CuPy system on the GPU with both
``inplace_a=True`` and ``inplace_b=True``.

For GPU operands, ``inplace_a=True`` makes the solver factorize directly in the
storage of ``a``, so ``a`` is overwritten by the LU factors. Similarly,
``inplace_b=True`` writes the solution directly into ``b`` and returns ``b``.
These options may also be used independently.

For GPU inputs in the non-batched case, ``inplace_a=True`` requires ``a`` to
be row-major or column-major, and ``inplace_b=True`` requires the right-hand
side to be column-major.
"""

import cupy as cp

import nvmath.linalg as la

n = 8
nrhs = 2

rng = cp.random.default_rng(0)

a = rng.standard_normal((n, n), dtype=cp.float64)
a += (n + 1) * cp.eye(n, dtype=cp.float64)
b = cp.ones((n, nrhs), dtype=cp.float64, order="F")

a_ref = a.copy()
b_ref = b.copy()

# ``inplace_a`` and ``inplace_b`` can also be used independently.
options = {"inplace_a": True, "inplace_b": True}
x = la.direct_solver(a, b, options=options)

print(f"Solution: {x}")
print(f"a modified in place: {not bool(cp.allclose(a, a_ref))}")
print(f"b modified in place: {not bool(cp.allclose(b, b_ref))}")
print(f"x aliases b: {x is b}")

assert isinstance(x, cp.ndarray)
cp.testing.assert_allclose(a_ref @ x, b_ref, rtol=1e-4, atol=1e-5)
