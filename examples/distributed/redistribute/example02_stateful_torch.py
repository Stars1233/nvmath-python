# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the use of stateful class-form Redistribute APIs with
Torch tensors on GPU.

The input as well as the result of the Redistribute operation are Torch tensors on GPU.

$ mpiexec -n 4 python example02_stateful_torch.py
"""

import torch
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab

# Initialize nvmath.distributed.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % torch.cuda.device_count()
nvmath.distributed.initialize(device_id, comm, backends=["nvshmem"])

# The problem consists of a global 3-D array of size (512, 256, 512), that is
# initially partitioned on the Y axis across processes.
X, Y, Z = (512, 256, 512)
shape = X, Y // nranks, Z

# The redistribute implementation uses the NVSHMEM PGAS model for GPU-GPU transfers,
# which requires GPU operands to be on the symmetric heap.
a = nvmath.distributed.allocate_symmetric_memory(shape, torch, dtype=torch.float64)
# a is a torch tensor and can be operated on using in-place torch operations.
a[:] = torch.ones(shape, dtype=torch.float64, device=device_id)

# We're going to redistribute the operand so that it is partitioned on the X axis.
# Create a stateful Redistribute object 'r'.
with nvmath.distributed.distribution.Redistribute(a, Slab.Y, Slab.X) as r:
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
    with torch.cuda.device(device_id):
        torch.cuda.default_stream().synchronize()
    if rank == 0:
        print(f"Input type = {type(a)}, device = {a.device}")
        print(f"Redistribute output type = {type(b)}, device = {b.device}")

# GPU operands on the symmetric heap are not garbage-collected and the user is
# responsible for freeing any that they own (this deallocation is a collective
# operation that must be called by all processes at the same point in the execution).
nvmath.distributed.free_symmetric_memory(a, b)
