# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to use batched operands in a generic matrix multiplication.
We distinguish batching into explicit, where the samples in a batch are provided as a
sequence of matrices, and implicit, where the samples are inferred from 3D or higher-
dimensional tensors. See example07 for implicit batching.

Each sample in an explicitly batched multiplication can be of different size, resulting
in a flexible user interface, as we'll see in a later example.

This example illustrates explicit batching of both 'a' and 'b' using CuPy operands.
"""

import cupy as cp

import nvmath

# Prepare sample input data.
m, n, k = 123, 456, 789
a = cp.random.rand(m, k)
b = cp.random.rand(k, n)

# Create an explicit batch for 'a' and 'b' as sequences of matrices. In this case, all
# samples have the same shape but this is not required, as we'll see in example10.
a = [a, 10 * a]
b = [b, b]

# Perform the multiplication. The result is a sequence of matrices matching the inputs.
result = nvmath.linalg.matmul(a, b)

# Synchronize the default stream, since by default the execution is non-blocking for GPU
# operands.
cp.cuda.get_current_stream().synchronize()

print(
    f"Inputs were sequences of types {type(a[0])} and {type(b[0])} and the result \
sequence is of type {type(result[0])}."
)
print(f"Result batch size is {len(result)}, each of shape {result[0].shape}.")

# The alpha and beta scalar factors can also be specified per batch as a sequence.
alpha = [1.0, 2.0]
scaled = nvmath.linalg.matmul(a, b, alpha=alpha)
cp.cuda.get_current_stream().synchronize()
assert cp.allclose(scaled[0], alpha[0] * (a[0] @ b[0]))
assert cp.allclose(scaled[1], alpha[1] * (a[1] @ b[1]))
