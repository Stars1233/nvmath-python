# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to use batched operands in a generic matrix multiplication.
We distinguish batching into explicit, where the samples in a batch are provided as a
sequence of matrices, and implicit, where the samples are inferred from 3D or higher-
dimensional tensors. See example07 for implicit batching and example09 for the baseline
explicit batching example.

This example shows that the two batching forms compose: each sample in an explicit
batch may itself be an implicitly-batched tensor with leading batch dimensions. We use
CuPy operands on the GPU.
"""

import cupy as cp

import nvmath

# Prepare sample input data. Each element of the explicit batch is a 3D tensor whose
# leading dimension is an implicit batch.
m, n, k = 32, 48, 64
implicit_batch = 3

# The explicit batch for 'a' is a sequence of 3D tensors of shape (implicit_batch, m, k).
a = [cp.random.rand(implicit_batch, m, k), cp.random.rand(implicit_batch, m, k)]

# The explicit batch for 'b' is a sequence of 2D tensors of shape (k, n); each broadcasts
# against the implicit batch of the corresponding 'a' element.
b = [cp.random.rand(k, n), cp.random.rand(k, n)]

# Perform the multiplication. The result is a sequence whose elements are 3D tensors of
# shape (implicit_batch, m, n).
result = nvmath.linalg.matmul(a, b)

# Synchronize the default stream, since by default the execution is non-blocking for GPU
# operands.
cp.cuda.get_current_stream().synchronize()

print(f"Explicit batch size = {len(result)}, each element has shape {result[0].shape}.")
for i, r in enumerate(result):
    assert cp.allclose(r, a[i] @ b[i])
