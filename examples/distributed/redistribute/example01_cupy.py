# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the use of function-form redistribution APIs with CuPy
ndarrays.

The input as well as the result of the Redistribute operation are CuPy ndarrays, resulting
in effortless interoperability between nvmath-python and CuPy.

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

$ mpiexec -n 2 python example01_cupy.py
"""

import cupy as cp

# Initialize nvmath.distributed.
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % cp.cuda.runtime.getDeviceCount()
nvmath.distributed.initialize(device_id, comm, backends=["nvshmem"])

assert nranks == 2, "This example requires two processes"

# Initialize the matrix on each process, as a CuPy ndarray (on the GPU).

# The redistribute implementation uses the NVSHMEM PGAS model for GPU-GPU transfers,
# which requires GPU operands to be on the symmetric heap.
A = nvmath.distributed.allocate_symmetric_memory((4, 2), cp)

# Note that the tensor is allocated on the same device on which nvmath.distributed
# was initialized.
if rank == 0:
    print("A is on device", A.device)

# A is a cupy ndarray and can be operated on using in-place cupy operations.
with cp.cuda.Device(device_id):
    A[:] = cp.zeros((4, 2)) if rank == 0 else cp.ones((4, 2))

# Redistribute from column-wise to row-wise.
# The operation returns a new operand with its own memory buffer on the symmetric heap.
A_redistributed = nvmath.distributed.distribution.redistribute(A, Slab.Y, Slab.X)

# Synchronize the default stream
with cp.cuda.Device(device_id):
    cp.cuda.get_current_stream().synchronize()

# The result is a CuPy ndarray, distributed row-wise:
# [0] A_redistributed:
# [[0. 0. 1. 1.]
#  [0. 0. 1. 1.]]
#
# [1] A_redistributed:
# [[0. 0. 1. 1.]
#  [0. 0. 1. 1.]]
print(f"[{rank}] A_redistributed:\n{A_redistributed}")
if rank == 0:
    print(f"Input type = {type(A)}, device = {A.device}")
    print(f"Redistribute output type = {type(A_redistributed)}, device = {A_redistributed.device}")

# GPU operands on the symmetric heap are not garbage-collected and the user is
# responsible for freeing any that they own (this deallocation is a collective
# operation that must be called by all processes at the same point in the execution).
nvmath.distributed.free_symmetric_memory(A, A_redistributed)
