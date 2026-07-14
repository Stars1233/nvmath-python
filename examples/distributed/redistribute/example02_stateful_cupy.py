# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the use of stateful class-form Redistribute APIs with
CuPy ndarrays.

The input as well as the result of the Redistribute operation are CuPy ndarrays.

$ mpiexec -n 4 python example02_stateful_cupy.py
"""

import cupy as cp
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab

# Initialize nvmath.distributed.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % cp.cuda.runtime.getDeviceCount()
nvmath.distributed.initialize(device_id, comm, backends=["nvshmem"])

# The problem consists of a global 3-D array of size (512, 256, 512), that is
# initially partitioned on the X axis across processes.
X, Y, Z = (512, 256, 512)
shape = X // nranks, Y, Z

# The redistribute implementation uses the NVSHMEM PGAS model for GPU-GPU transfers,
# which requires GPU operands to be on the symmetric heap.
a = nvmath.distributed.allocate_symmetric_memory(shape, cp, dtype=cp.float32)
# a is a cupy ndarray and can be operated on using in-place cupy operations.
with cp.cuda.Device(device_id):
    a[:] = cp.ones(shape, dtype=cp.float32)

# We're going to redistribute the operand so that it is partitioned on the Y axis.
# Create a stateful Redistribute object 'r'.
with nvmath.distributed.distribution.Redistribute(a, Slab.X, Slab.Y) as r:
    # Plan the Redistribute.
    r.plan()

    # Execute the Redistribute. This returns a new operand with its own memory buffer
    # on the symmetric heap.
    b = r.execute()

    # Note the difference in shape of operand a and b due to the modified distribution.
    if rank == 0:
        print(f"Shape of a on rank {rank} is {a.shape}")
        print(f"Shape of b on rank {rank} is {b.shape}")

    # Synchronize the default stream.
    with cp.cuda.Device(device_id):
        cp.cuda.get_current_stream().synchronize()
    if rank == 0:
        print(f"Input type = {type(a)}, device = {a.device}")
        print(f"Redistribute output type = {type(b)}, device = {b.device}")

# GPU operands on the symmetric heap are not garbage-collected and the user is
# responsible for freeing any that they own (this deallocation is a collective
# operation that must be called by all processes at the same point in the execution).
nvmath.distributed.free_symmetric_memory(a, b)
