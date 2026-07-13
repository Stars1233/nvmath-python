# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates solving explicitly batched systems of linear equations
with both ``inplace_a=True`` and ``inplace_b=True``. The inputs are PyTorch
tensors on the GPU.

Each batch member is a separate matrix in a Python sequence. For GPU operands,
``inplace_a=True`` factorizes directly in the storage of each LHS matrix, so
each matrix is overwritten by LU factors. Similarly, ``inplace_b=True`` writes
each solution directly into the corresponding RHS matrix and returns ``b``.
These options may also be used independently.

For GPU inputs with explicit batching, each matrix in ``a`` must be row-major or
column-major for ``inplace_a=True``. Each matrix right-hand side in ``b`` must
be column-major for ``inplace_b=True``.
"""

import torch

import nvmath.linalg as la

n = 8
n_batch = 2
nrhs = 2
device = torch.device("cuda", 0)

torch.manual_seed(0)

eye = torch.eye(n, dtype=torch.float64, device=device)
a = [torch.randn((n, n), dtype=torch.float64, device=device) + (n + 1) * eye for _ in range(n_batch)]
b = [((i + 1) * torch.ones((n, nrhs), dtype=torch.float64, device=device)).mT.contiguous().mT for i in range(n_batch)]

a_ref = [a_i.clone() for a_i in a]
b_ref = [b_i.clone() for b_i in b]

# ``inplace_a`` and ``inplace_b`` can also be used independently.
options = {"inplace_a": True, "inplace_b": True}
x = la.direct_solver(a, b, options=options)

print(f"Solution: {x}")

for i in range(n_batch):
    assert not bool(torch.allclose(a[i], a_ref[i])), f"a[{i}] is not overwritten by the solver"
    assert x[i] is b[i], f"b[{i}] is not aliasing x[{i}]"
    torch.testing.assert_close(a_ref[i] @ x[i], b_ref[i], rtol=1e-4, atol=1e-5)
