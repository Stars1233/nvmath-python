# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to specify options to a redistribution operation.

In this example, we will use a CuPy ndarray as input, and we will look at two equivalent
ways of providing options to control the blocking behavior of the redistribution operation.

$ mpiexec -n 4 python example03_options.py
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

# The problem consists of a global 3-D array of size (64, 256, 128), that is
# initially partitioned on the X axis across processes.
X, Y, Z = (64, 256, 128)
shape = Slab.X.shape(rank, (X, Y, Z))

# The redistribute implementation uses the NVSHMEM PGAS model for GPU-GPU transfers,
# which requires GPU operands to be on the symmetric heap.
a = nvmath.distributed.allocate_symmetric_memory(shape, cp, dtype=cp.float64)
# a is a cupy ndarray and can be operated on using in-place cupy operations.
with cp.cuda.Device(device_id):
    a[:] = cp.random.rand(*shape, dtype=cp.float64)

# We're going to redistribute the operand so that it is partitioned on the Y axis.

# Alternative #1 for specifying options, using dataclass.
options = nvmath.distributed.distribution.RedistributeOptions(blocking=True)
b = nvmath.distributed.distribution.redistribute(a, Slab.X, Slab.Y, options=options)

# The result is ready because the above operation is blocking.

# Alternative #2 for specifying options, using dict. The two alternatives are entirely
# equivalent.
c = nvmath.distributed.distribution.redistribute(a, Slab.X, Slab.Y, options={"blocking": "auto"})

# Because the input operand is in GPU memory, the "auto" behavior is to not block.
# Therefore, we have to synchronize before we can access the result.
with cp.cuda.Device(device_id):
    cp.cuda.get_current_stream().synchronize()

# GPU operands on the symmetric heap are not garbage-collected and the user is
# responsible for freeing any that they own (this deallocation is a collective
# operation that must be called by all processes at the same point in the execution).
nvmath.distributed.free_symmetric_memory(a, b, c)
