# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example shows how to use **multiple CUDA streams** with the dense
:class:`nvmath.linalg.DirectSolver`: one stream for the first factor/solve cycle, a second
stream to build a new right-hand side, then ordered execution before ``reset_operands``
and a second ``solve``.

Operands are real ``float64`` CuPy arrays on the GPU.
"""

import cupy as cp

import nvmath.linalg as la

n = 8

rng = cp.random.default_rng(0)
a = rng.standard_normal((n, n), dtype=cp.float64) + (n + 1) * cp.eye(n, dtype=cp.float64)
b = cp.ones(n, dtype=cp.float64)

# Stream for construction, planning, factorization, and first solve.
s1 = cp.cuda.Stream()

with la.DirectSolver(a, b, stream=s1) as solver:
    solver.plan(stream=s1)
    solver.factorize(stream=s1)
    x = solver.solve(stream=s1)

    e1 = s1.record()

    s2 = cp.cuda.Stream()
    with s2:
        c = cp.random.default_rng().standard_normal(n, dtype=cp.float64)

    # Order reset/solve on ``s2`` after the first solve completes on ``s1``.
    s2.wait_event(e1)

    solver.reset_operands(b=c, stream=s2)
    y = solver.solve(stream=s2)

    s2.synchronize()

rtol = 1e-4
atol = 1e-5

print(x)
print(y)

print(f"LHS type {type(a)}; first rhs type {type(b)}; second rhs type {type(c)}.")
print(f"Solution types {type(x)} and {type(y)}.")

cp.testing.assert_allclose(a @ x, b, rtol=rtol, atol=atol)
cp.testing.assert_allclose(a @ y, c, rtol=rtol, atol=atol)
