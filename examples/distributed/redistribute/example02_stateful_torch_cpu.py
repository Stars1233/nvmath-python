# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates the use of stateful class-form Redistribute APIs with
Torch tensors on CPU.

Torch tensors residing in CPU memory are copied transparently to GPU symmetric
memory for redistribution.

The input as well as the result of the Redistribute operation are Torch tensors on CPU.

$ mpiexec -n 4 python example02_stateful_torch_cpu.py
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

a = torch.ones(shape, dtype=torch.complex64)  # cpu tensor

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

    if rank == 0:
        print(f"Input type = {type(a)}")
        print(f"Redistribute output type = {type(b)}")
