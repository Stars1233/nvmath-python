# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Implicit batching** for :func:`~nvmath.linalg.direct_solver`: LHS ``(n_batch, n, n)``, RHS
``(n_batch, n, nrhs)`` (see ``example06_implicit_batching.py`` for GPU layout).

This example uses PyTorch CPU tensors. Host execution blocks when results are needed; no
CUDA stream synchronization is required.
"""

import torch

import nvmath.linalg as la

n = 8
n_batch = 2
nrhs = 3
device = torch.device("cpu")

torch.manual_seed(0)
a = torch.randn(n_batch, n, n, dtype=torch.float64, device=device)
a = a + (n + 1) * torch.eye(n, dtype=torch.float64, device=device)

b = torch.ones(n_batch, n, nrhs, dtype=torch.float64, device=device)

rtol = 1e-4
atol = 1e-5

x = la.direct_solver(a, b)

print(x)

print(f"Inputs were types {type(a)} and {type(b)}; result type is {type(x)}.")
print(f"Devices: a={a.device}, b={b.device}, x={x.device}.")

torch.testing.assert_close(torch.matmul(a, x), b, rtol=rtol, atol=atol)
