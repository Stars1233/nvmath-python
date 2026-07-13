# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates the optimized result layout for binary tensor contraction.

The contraction has low arithmetic intensity, so output memory access is a
meaningful part of the runtime. In this regime, choosing result strides that
match the contraction structure can significantly improve performance.
"""

import cupy as cp
from cupyx.profiler import benchmark

import nvmath

# This hand-picked contraction has low arithmetic intensity, making it useful
# for comparing the performance impact of different result layouts.
expr = "abcde,fghie->afbgchdi"
a_shape = (4, 16, 2**13, 2, 16)
b_shape = (2, 2, 4, 2, 16)

a = cp.random.rand(*a_shape, dtype=cp.float32)
b = cp.random.rand(*b_shape, dtype=cp.float32)

print("Binary contraction benchmark by result layout")
print(f"Expression: {expr}, {a_shape=}, {b_shape=}\n")

for result_layout in ("auto", "optimized", "C", "F"):
    with nvmath.tensor.BinaryContraction(expr, a, b, options={"result_layout": result_layout}) as contraction:
        contraction.plan()
        r = contraction.execute()
        result_strides = [s // r.itemsize for s in r.strides]
        print(f"{result_layout=}, {result_strides=}")
        print(benchmark(contraction.execute, n_repeat=100))
