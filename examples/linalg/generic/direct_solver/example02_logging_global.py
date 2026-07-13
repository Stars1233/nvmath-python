# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates how to turn on logging using the global logger while solving a
dense linear system with :func:`~nvmath.linalg.direct_solver`.
"""

# Turn on logging. Here we use the global logger, set the level to "debug", and use a custom
# format for the log.
import logging

import cupy as cp

import nvmath.linalg as la

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)-8s %(message)s",
    datefmt="%m-%d %H:%M:%S",
)

# Matrix order.
n = 8

# Random complex coefficient matrix, made diagonally dominant for a stable solution.
rng = cp.random.default_rng(0)
re = rng.standard_normal((n, n), dtype=cp.float32)
im = rng.standard_normal((n, n), dtype=cp.float32)
a = (re + 1j * im).astype(cp.complex64)
a += (n + 1) * cp.eye(n, dtype=cp.complex64)

# Right-hand side with two columns.
nrhs = 2
b = cp.ones((n, nrhs), dtype=cp.complex64)

# Solve a @ x = b for x.
x = la.direct_solver(a, b)

# Synchronize the default stream, since execution may be non-blocking for GPU operands.
cp.cuda.get_current_stream().synchronize()

print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
assert isinstance(x, cp.ndarray)

cp.testing.assert_allclose(a @ x, b, rtol=1e-4, atol=1e-5)
