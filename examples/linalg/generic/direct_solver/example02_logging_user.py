# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates the use of a user-provided logger
while solving a dense linear system with :func:`~nvmath.linalg.direct_solver`.
"""

import logging

import cupy as cp

import nvmath.linalg as la

# Create and configure a user logger.
# Any of the features provided by the logging module can be used.
logger = logging.getLogger("userlogger")
logger.setLevel(logging.NOTSET)

# Create a console handler for the logger and set level.
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)

# Create a formatter and associate with handler.
formatter = logging.Formatter("%(asctime)s %(name)-12s %(levelname)-8s %(message)s", datefmt="%m-%d %H:%M:%S")
handler.setFormatter(formatter)

# Associate handler with logger, resulting in a logger with the desired level, format, and
# console output.
logger.addHandler(handler)

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

# Specify the custom logger in the linear solver options.
o = la.DirectSolverOptions(logger=logger)
x = la.direct_solver(a, b, options=o)

print("---")

# Recall that the options can also be provided as a dict, so the following is an
# alternative, entirely equivalent way to specify options.
x = la.direct_solver(a, b, options={"logger": logger})

# Synchronize the default stream, since execution may be non-blocking for GPU operands.
cp.cuda.get_current_stream().synchronize()

print(x)

print(f"Inputs were of types {type(a)} and {type(b)}; result type is {type(x)}.")
assert isinstance(x, cp.ndarray)

cp.testing.assert_allclose(a @ x, b, rtol=1e-4, atol=1e-5)
