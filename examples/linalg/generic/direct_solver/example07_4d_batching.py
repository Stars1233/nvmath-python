# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Implicit batching** with **multiple leading batch dimensions**: the LHS has shape
``(*batch_shape, n, n)`` and the RHS ``(*batch_shape, n, nrhs)`` (or ``(*batch_shape, n)``
for one column). Here ``batch_shape = (b0, b1)`` so operands are rank-4 tensors — a
natural layout for problems indexed by two independent batch axes.

This uses :func:`~nvmath.linalg.direct_solver` with PyTorch on CUDA.
CPU tensors work the same with ``device=torch.device("cpu")`` (no stream synchronization
needed).

See ``example06_implicit_batching.py`` for a single batch dimension ``(n_batch, n, n)``.
"""

import torch

import nvmath.linalg as la

n = 8
b0 = 2
b1 = 2
nrhs = 3
device = torch.device("cuda", 0)

torch.manual_seed(0)
# LHS (b0, b1, n, n): random + diagonal shift per (i, j) slice.
a = torch.randn(b0, b1, n, n, dtype=torch.float64, device=device)
a = a + (n + 1) * torch.eye(n, dtype=torch.float64, device=device)

# RHS (b0, b1, n, nrhs) — leading dims match ``a``.
b = torch.ones(b0, b1, n, nrhs, dtype=torch.float64, device=device)

rtol = 1e-4
atol = 1e-5

x = la.direct_solver(a, b)

torch.cuda.default_stream(device).synchronize()

print(f"a.shape={a.shape}, b.shape={b.shape}, x.shape={x.shape}")

print(f"Types: a={type(a)}, b={type(b)}, x={type(x)}")
print(f"Devices: a={a.device}, b={b.device}, x={x.device}")

# Leading batch dims broadcast like torch.matmul on … x (n,n) @ (n,nrhs).
torch.testing.assert_close(torch.matmul(a, x), b, rtol=rtol, atol=atol)
