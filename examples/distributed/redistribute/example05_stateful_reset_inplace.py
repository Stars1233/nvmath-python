# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to reuse the stateful API to perform Redistribute operations
by resetting operands inplace. It's important to note that operands reset in this
manner have to preserve their distribution.

$ mpiexec -n 4 python example05_stateful_reset_inplace.py
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

# The global 3-D problem size is (512, 512, 512), initially partitioned on the Y
# axes across processes.
X, Y, Z = (512, 512, 512)
shape = X, Y // nranks, Z

# The redistribute implementation uses the NVSHMEM PGAS model for GPU-GPU transfers,
# which requires GPU operands to be on the symmetric heap.
a = nvmath.distributed.allocate_symmetric_memory(shape, cp, dtype=cp.complex64)
with cp.cuda.Device(device_id):
    a[:] = cp.random.rand(*shape, dtype=cp.float32) + 1j * cp.random.rand(*shape, dtype=cp.float32)

# We're going to redistribute the operand so that it is partitioned on the X axis.

# Create a stateful Redistribute object 'r'.
with nvmath.distributed.distribution.Redistribute(a, Slab.Y, Slab.X) as r:
    # Plan the Redistribute.
    r.plan()

    # Execute the Redistribute. Operand b will be partitioned on the X axis.
    b = r.execute()

    # Reset the operand inplace. Note that this implies maintaining the same
    # input operand distribution (partitioned on Y axis).
    with cp.cuda.Device(device_id):
        a[:] = cp.random.rand(*shape, dtype=cp.float32) + 1j * cp.random.rand(*shape, dtype=cp.float32)

    # Execute a new redistribution with the modified operand. Operand c will be partitioned
    # on the X axis.
    c = r.execute()

    # Synchronize the default stream
    with cp.cuda.Device(device_id):
        cp.cuda.get_current_stream().synchronize()
    if rank == 0:
        print(f"Input type = {type(a)}, device = {a.device}")
        print(f"Redistribute output type (1) = {type(b)}, device = {b.device}")
        print(f"Redistribute output type (2) = {type(c)}, device = {c.device}")

# GPU operands on the symmetric heap are not garbage-collected and the user is
# responsible for freeing any that they own (this deallocation is a collective
# operation that must be called by all processes at the same point in the execution).
nvmath.distributed.free_symmetric_memory(a, b, c)
