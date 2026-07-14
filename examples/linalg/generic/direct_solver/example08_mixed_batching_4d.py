# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Mixed batching** with **several leading batch dimensions** for
:func:`~nvmath.linalg.direct_solver`: the implicit operand can have shape ``(b0, b1, n, *)``
instead of a single batch axis ``(n_batch, n, *)``, with ``n_batch = b0 * b1``.

* **Case 1 — explicit LHS, implicit RHS:** ``a`` is a length-``n_batch`` list of
  ``(n, n)`` matrices; ``b`` has shape ``(b0, b1, n, nrhs)``.
* **Case 2 — implicit LHS, explicit RHS:** ``a`` has shape ``(b0, b1, n, n)``;
  ``b`` is a length-``n_batch`` list of ``(n, nrhs)`` matrices.

For a **single** batch dimension ``(n_batch, n, *)`` on both sides, see
``example08_mixed_batching.py``. For uniform explicit or implicit batching, see
``example05_explicit_batching.py`` and ``example06_implicit_batching.py``.

Operands are real ``float64`` CuPy arrays on the GPU.
"""

import cupy as cp

import nvmath.linalg as la

n = 8
b0, b1 = 2, 3
n_batch = b0 * b1
nrhs = 2
rtol = 1e-4
atol = 1e-5

rng = cp.random.default_rng(0)


def random_diagonally_dominant_matrix(n: int) -> cp.ndarray:
    """Create a diagonally dominant matrix with random normal entries."""
    return rng.standard_normal((n, n)) + (n + 1) * cp.eye(n)


# --- Case 1: explicit LHS (list), implicit RHS (b0, b1, n, nrhs) ---

lhs_list = [random_diagonally_dominant_matrix(n) for _ in range(n_batch)]
rhs_implicit = cp.ones((b0, b1, n, nrhs), dtype=cp.float64)

x = la.direct_solver(lhs_list, rhs_implicit)

cp.cuda.get_current_stream().synchronize()

print(f"Case 1: RHS shape {rhs_implicit.shape}, solution shape {x.shape}.")

rhs_flat = rhs_implicit.reshape(n_batch, n, nrhs)
x_flat = x.reshape(n_batch, n, nrhs)
for i in range(n_batch):
    cp.testing.assert_allclose(lhs_list[i] @ x_flat[i], rhs_flat[i], rtol=rtol, atol=atol)

# --- Case 2: implicit LHS (b0, b1, n, n), explicit RHS (list) ---

lhs_implicit = cp.stack(lhs_list).reshape(b0, b1, n, n)
rhs_list = [cp.ones((n, nrhs), dtype=cp.float64) for _ in range(n_batch)]

x = la.direct_solver(lhs_implicit, rhs_list)

cp.cuda.get_current_stream().synchronize()

print(f"Case 2: LHS shape {lhs_implicit.shape}, RHS list of {n_batch} x {rhs_list[0].shape}.")

lhs_flat = lhs_implicit.reshape(n_batch, n, n)
for i in range(n_batch):
    cp.testing.assert_allclose(lhs_flat[i] @ x[i], rhs_list[i], rtol=rtol, atol=atol)
