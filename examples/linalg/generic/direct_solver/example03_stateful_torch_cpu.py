# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the stateful :class:`nvmath.linalg.DirectSolver` API. Separating
``plan()``, ``factorize()``, and ``solve()`` lets you reuse preparation across multiple
solves (see :func:`~nvmath.linalg.direct_solver` for a one-shot equivalent).

The inputs and result are PyTorch tensors on the CPU.
"""

import torch

import nvmath.linalg as la

# Matrix order.
n = 8

# Random complex coefficient matrix, made diagonally dominant for a stable solution.
torch.manual_seed(0)
re = torch.randn((n, n), dtype=torch.float32)
im = torch.randn((n, n), dtype=torch.float32)
a = (re + 1j * im).to(torch.complex64)
a += (n + 1) * torch.eye(n, dtype=torch.complex64)

# Right-hand side with two columns.
nrhs = 2
b = torch.ones((n, nrhs), dtype=torch.complex64)

# Solve a @ x = b for x.
# Use the stateful object as a context manager to automatically release resources.
with la.DirectSolver(a, b) as solver:
    solver.plan()
    solver.factorize()
    x = solver.solve()

# No synchronization is needed for CPU operands; execution blocks when results are
# required on the host.
print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
print(f"Inputs were on devices {a.device}, {b.device}; result is on {x.device}.")
assert isinstance(x, torch.Tensor)
assert x.device == b.device

torch.testing.assert_close(a @ x, b, rtol=1e-4, atol=1e-5)
