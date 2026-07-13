# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to use batched operands in a generic matrix multiplication.
We distinguish batching into explicit, where the samples in a batch are provided as a
sequence of matrices, and implicit, where the samples are inferred from 3D or higher-
dimensional tensors. See example07 for implicit batching and example09 for the baseline
explicit batching example.

This example shows that each sample in an explicitly batched multiplication can be of
different size, resulting in a flexible user interface. We use CuPy operands on the GPU.
"""

import cupy as cp

import nvmath

# The (m, n, k) dimensions for each of the three samples in the batch.
shapes = [(4, 5, 6), (10, 7, 8), (16, 12, 20)]

# Build an explicit batch for 'a' and 'b' as sequences of matrices, where each sample has a
# different shape.
a = [cp.random.rand(m, k) for m, _, k in shapes]
b = [cp.random.rand(k, n) for _, n, k in shapes]

# Perform the multiplication. Each result in the returned sequence has the shape (m, n)
# corresponding to its input sample.
result = nvmath.linalg.matmul(a, b)

# Synchronize the default stream, since by default the execution is non-blocking for GPU
# operands.
cp.cuda.get_current_stream().synchronize()

for i, r in enumerate(result):
    print(f"Sample {i}: 'a' shape {a[i].shape}, 'b' shape {b[i].shape}, result shape {r.shape}.")
