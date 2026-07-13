# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example show how to save algorithms from a planned and possibly autotuned matrix
multiplication object.

The saved algorithms can be provided later for another compatible matrix multiplication
operation, thereby avoiding the cost of planning and autotuning.
"""

import os

import cupy as cp
import numpy as np

import nvmath

# Tip: turn logging on to get information on performance improvement from autotuning.
# import logging
# logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-8s %(message)s", datefmt="%m-%d %H:%M:%S")  # noqa: W505,E501

# Prepare sample input data
m, n, k = 2048, 4096, 1024
a = cp.random.rand(m, k)
b = cp.random.rand(k, n)
bias = cp.random.rand(m, 1)

npy_file = f"algorithms_{m}_{n}_{k}_f64_relu_bias.npy"
# In the first pass, we will plan and autotune the matrix multiplication. Autotuning
# reorders the algorithms based on measured performance from fastest to slowest, and we will
# save the ordered algorithms.
print("= Phase 1: Plan, autotune, and save the optimal algorithm sequence. =")
with nvmath.linalg.advanced.Matmul(a, b) as mm:
    epilog = nvmath.linalg.advanced.MatmulEpilog.RELU_BIAS
    mm.plan(epilog=epilog, epilog_inputs={"bias": bias})

    mm.autotune(iterations=5)

    # Save the algorithms as ordered by autotuning.
    np.save(npy_file, [a.as_numpy() for a in mm.algorithms], allow_pickle=False)
    print(f"Saved optimized algorithms to '{npy_file}' for later use.")

    # Execute the multiplication
    result = mm.execute()


print()
print("= Phase 2: Reuse the optimized algorithm sequence later in another compatible matrix multiplication. =")
# Load the algorithms saved earlier for use in a compatible matrix multiplication.
algorithms = [nvmath.linalg.advanced.Algorithm.from_numpy(a) for a in np.load(npy_file, allow_pickle=False)]
print(f"Loaded optimized algorithms from '{npy_file}'.")

# In the second pass, we will provide the loaded algorithms to plan() to bypass planning and
# autotuning costs, since we already know the optimal algorithm(s) for this case.
with nvmath.linalg.advanced.Matmul(a, b) as mm:
    epilog = nvmath.linalg.advanced.MatmulEpilog.RELU_BIAS

    # Provide the optimized algorithms directly to plan.
    mm.plan(algorithms=algorithms, epilog=epilog, epilog_inputs={"bias": bias})
    print("Provided optimized algorithms to plan(), bypassing planning cost.")
    print("No autotuning is needed, since the loaded algorithms sequence is in optimal order.")

    # Execute the multiplication
    result = mm.execute()
    print("Executed the matrix multiplication using the provided algorithms.")

    # Synchronize the default stream, since by default the execution is non-blocking for GPU
    # operands.
    cp.cuda.get_current_stream().synchronize()

# Remove the npy file.
os.remove(npy_file)
