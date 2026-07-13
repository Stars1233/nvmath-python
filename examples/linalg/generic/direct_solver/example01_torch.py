# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving a dense square linear system ``a @ x = b`` with
:class:`nvmath.linalg.DirectSolver` via :func:`~nvmath.linalg.direct_solver`, using PyTorch
operands with ``complex64`` dtype on the GPU.

``nvmath.linalg.direct_solver`` plans, factorizes, and solves in one call. For non-batched
inputs, factorization uses cuSOLVER (LU with partial pivoting).
"""

import torch

import nvmath.linalg as la

# Matrix order.
n = 8
device = torch.device("cuda", 0)

# Random complex coefficient matrix, made diagonally dominant for a stable solution.
g = torch.Generator(device=device)
g.manual_seed(0)
re = torch.randn((n, n), dtype=torch.float32, device=device, generator=g)
im = torch.randn((n, n), dtype=torch.float32, device=device, generator=g)
a = (re + 1j * im).to(torch.complex64)
a += (n + 1) * torch.eye(n, dtype=torch.complex64, device=device)

# Right-hand side with two columns.
nrhs = 2
b = torch.ones((n, nrhs), dtype=torch.complex64, device=device)

# Solve a @ x = b for x.
x = la.direct_solver(a, b)

# Synchronize the default stream, since execution may be non-blocking for GPU operands.
torch.cuda.default_stream(device).synchronize()

print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
print(f"Inputs were on devices {a.device}, {b.device}; result is on {x.device}.")
assert isinstance(x, torch.Tensor)
assert x.device == b.device

torch.testing.assert_close(a @ x, b, rtol=1e-4, atol=1e-5)
