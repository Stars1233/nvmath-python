# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example shows how to reuse a stateful :class:`nvmath.linalg.DirectSolver` across
multiple solves by updating operands with
:meth:`~nvmath.linalg.DirectSolver.reset_operands`
or :meth:`~nvmath.linalg.DirectSolver.reset_operands_unchecked`.

Typical patterns:

* **RHS only changes** — keep the existing factorization of ``a``; call
  ``factorize()`` only when ``a`` changes.
* **LHS changes** — call ``factorize()`` again before the next ``solve()``.

Operands are real NumPy arrays on the CPU.
"""

import numpy as np

import nvmath.linalg as la

# Matrix order and number of right-hand sides (columns of 'b').
n = 8
nrhs = 3

rng = np.random.default_rng(0)

# Two square systems a0 @ x = … and a1 @ z = …; diagonal shift keeps LU well conditioned.
a0 = rng.standard_normal((n, n)) + (n + 1) * np.eye(n)
a1 = rng.standard_normal((n, n)) + (n + 1) * np.eye(n)

b0 = np.ones((n, nrhs))
b1 = rng.standard_normal((n, nrhs))

rtol = 1e-4
atol = 1e-5

with la.DirectSolver(a0, b0) as solver:
    solver.plan()
    solver.factorize()

    # 1) Solve a0 @ x0 = b0.
    x0 = solver.solve()
    np.testing.assert_allclose(a0 @ x0, b0, rtol=rtol, atol=atol)

    # 2) Same matrix a0, new rhs b1 — refresh rhs only; reuse the existing factorization.
    solver.reset_operands(b=b1)
    y = solver.solve()
    np.testing.assert_allclose(a0 @ y, b1, rtol=rtol, atol=atol)

    # 3) New lhs a1, same rhs b1 as in step 2 — refactor. ``reset_operands_unchecked(a=a1)``
    #    is enough (user rhs is still b1); then factorize() and solve().
    solver.reset_operands_unchecked(a=a1)
    solver.factorize()
    z = solver.solve()
    np.testing.assert_allclose(a1 @ z, b1, rtol=rtol, atol=atol)

# Host operands do not require an explicit device synchronization call.
