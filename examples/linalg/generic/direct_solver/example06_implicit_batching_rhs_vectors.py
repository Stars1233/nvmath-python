# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
**Implicit batching** with **one column** per batch for
:func:`~nvmath.linalg.direct_solver`:
``a`` has shape ``(n_batch, n, n)`` and ``b`` has shape ``(n_batch, n, 1)`` (a batched
column vector; the trailing ``1`` is the column count).

For several right-hand sides per batch, use ``b`` with shape ``(n_batch, n, nrhs)``
instead (see ``example06_implicit_batching.py`` in this directory).

PyTorch CUDA tensors; default memory order is fine.
"""

import torch

import nvmath.linalg as la

n = 8
n_batch = 2
device = torch.device("cuda", 0)

torch.manual_seed(0)
a = torch.randn(n_batch, n, n, dtype=torch.float64, device=device)
a = a + (n + 1) * torch.eye(n, dtype=torch.float64, device=device)

b = torch.ones(n_batch, n, 1, dtype=torch.float64, device=device)

x = la.direct_solver(a, b)

torch.cuda.default_stream(device).synchronize()

print(x)

print(f"Inputs were types {type(a)} and {type(b)}; result type is {type(x)}.")
print(f"Devices: a={a.device}, b={b.device}, x={x.device}.")

# One column per batch: matvec matches vector b.
torch.testing.assert_close(
    a @ x,
    b,
    rtol=1e-4,
    atol=1e-5,
)
