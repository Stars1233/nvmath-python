# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the use of function-form redistribution APIs with NumPy
ndarrays, using the Box distribution type.

The NumPy ndarrays reside in CPU memory, and are copied transparently to GPU
symmetric memory for redistribution.

The input as well as the result of the Redistribute operation are NumPy ndarrays, resulting
in effortless interoperability between nvmath-python and NumPy.

In this example, given a 4x4 matrix which is initially distributed column-wise on two
processes, we redistribute it row-wise. This is illustrated below:

    0 0 | 1 1     0 0 1 1
    0 0 | 1 1  -> 0 0 1 1   P0
    0 0 | 1 1     -------
    0 0 | 1 1     0 0 1 1   P1
                  0 0 1 1
     P0   P1

where P0 and P1 refer to process 0 and 1, respectively. Initially, P0 holds the first
two columns and P1 the last two. After performing a redistribute operation, P0 holds the
first two rows and P1 the last two.

$ mpiexec -n 2 python example01_numpy.py
"""

import numpy as np
from cuda.core import system

# Initialize nvmath.distributed.
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Box

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % system.get_num_devices()
nvmath.distributed.initialize(device_id, comm, backends=["nvshmem"])

assert nranks == 2, "This example requires two processes"

# Initialize the matrix on each process, as a NumPy ndarray (on the CPU).
A = np.zeros((4, 2)) if rank == 0 else np.ones((4, 2))

# Redistribute from column-wise to row-wise.
if rank == 0:
    input_box = Box((0, 0), (4, 2))
    output_box = Box((0, 0), (2, 4))
else:
    input_box = Box((0, 2), (4, 4))
    output_box = Box((2, 0), (4, 4))
# Redistribute returns a new operand with its own buffer.
A_redistributed = nvmath.distributed.distribution.redistribute(A, input_box, output_box)

# The result is a NumPy ndarray, distributed row-wise:
# [0] A_redistributed:
# [[0. 0. 1. 1.]
#  [0. 0. 1. 1.]]
#
# [1] A_redistributed:
# [[0. 0. 1. 1.]
#  [0. 0. 1. 1.]]
print(f"[{rank}] A_redistributed:\n{A_redistributed}")
if rank == 0:
    print(f"Input type = {type(A)}, device = 'cpu'")
    print(f"Redistribute output type = {type(A_redistributed)}, device = 'cpu'")
