# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Implicit batching** for :func:`~nvmath.linalg.direct_solver`: pack the batch dimension
into dense tensors — LHS with shape ``(n_batch, n, n)`` and RHS with shape
``(n_batch, n, nrhs)``.
This contrasts with explicit batching (Python sequences of matrices; see
``example05_explicit_batching.py``).

This example uses PyTorch on CUDA.
For CPU tensors see ``example06_implicit_batching_cpu.py``;
for batched vector RHS see ``example06_implicit_batching_rhs_vectors.py``.
"""

import torch

import nvmath.linalg as la

n = 8
n_batch = 2
nrhs = 3
device = torch.device("cuda", 0)

torch.manual_seed(0)
a = torch.randn(n_batch, n, n, dtype=torch.float64, device=device)
a = a + (n + 1) * torch.eye(n, dtype=torch.float64, device=device)

b = torch.ones(n_batch, n, nrhs, dtype=torch.float64, device=device)

rtol = 1e-4
atol = 1e-5

x = la.direct_solver(a, b)

torch.cuda.default_stream(device).synchronize()

print(x)

print(f"Inputs were types {type(a)} and {type(b)}; result type is {type(x)}.")
print(f"Devices: a={a.device}, b={b.device}, x={x.device}.")

torch.testing.assert_close(torch.matmul(a, x), b, rtol=rtol, atol=atol)
