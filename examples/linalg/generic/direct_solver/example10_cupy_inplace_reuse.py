# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates repeated solves for a non-batched CuPy system using
both ``inplace_a=True`` and ``inplace_b=True``.

Repeated ``factorize`` and ``solve`` calls use the current values of the
original ``a`` and ``b`` operands, so direct updates such as ``a[:] = new_a``
and ``b[:] = new_b`` are supported for both CPU and GPU operands. In this CuPy
example, ``inplace_a=True`` and ``inplace_b=True`` make ``factorize`` overwrite
``a`` with LU factors and ``solve`` overwrite ``b`` with the solution. For
reuse, write the intended LHS/RHS values into those same device allocations
before each ``factorize``/``solve`` call.

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

# Let the solver operate directly on the user-provided CuPy allocations.
options = {"inplace_a": True, "inplace_b": True}

with la.DirectSolver(a, b, options=options) as solver:
    solver.plan()
    solver.factorize()
    x = solver.solve()

    assert x is b

    cp.testing.assert_allclose(a_ref @ b, b_ref, rtol=1e-4, atol=1e-5)

    # Write new values into the same allocations before reusing this in-place direct solver.
    # This is equivalent to calling solver.reset_operands(a=a_ref * 2, b=b_ref * 3)

    a[:] = a_ref * 2
    b[:] = b_ref * 3

    solver.factorize()
    x = solver.solve()

    assert x is b
    cp.testing.assert_allclose(a_ref * 2 @ x, b_ref * 3, rtol=1e-4, atol=1e-5)
