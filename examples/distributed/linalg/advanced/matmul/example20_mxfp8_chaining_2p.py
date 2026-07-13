# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Each MXFP8 block-scaled matrix multiplication produces both a result and the quantization
scale that describes it. This example shows how that output scale can be fed straight back
in as the input scale for the next multiplication. We use this to compute a matrix
exponentiation by chaining multiplications, feeding each result back in as operand 'a'.

FP8 is only supported with compute capability 10.0 or higher.

$ mpiexec -n 2 python example20_mxfp8_chaining_2p.py
"""

import numpy as np
import torch
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg.advanced import matrix_qualifiers_dtype

# Initialize nvmath.distributed.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % torch.cuda.device_count()
# cuBLASMp requires NCCL communication backend.
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# 'a' and 'b' are square matrices of the given global size:
size = 256

# We will compute b^p = a*b*b*...*b
p = 4

row_wise_distribution = Slab.X
col_wise_distribution = Slab.Y

# FP8 operations require TN input layout.

with torch.cuda.device(device_id):
    a = torch.zeros(*row_wise_distribution.shape(rank, (size, size)), device="cuda").type(torch.float8_e4m3fn)
    b = torch.zeros(*row_wise_distribution.shape(rank, (size, size)), device="cuda").type(torch.float8_e4m3fn)

# Get a transposed view to obtain column-major memory layout. Note that this
# also changes the distribution of 'a' and 'b' (see example01 for more information).
a = a.T  # 'a' now uses col_wise_distribution
b = b.T  # 'b' now uses col_wise_distribution

# Distributions for 'a', 'b', and result matrix 'd'
distributions = [col_wise_distribution, col_wise_distribution, row_wise_distribution]

# Initialize 'a' as global identity matrix.
with torch.cuda.device(device_id):
    i = rank * (size // nranks)
    j = i + (size // nranks)
    a[i:j, :] = torch.eye(size // nranks, device="cuda", dtype=torch.float8_e4m3fn)

print("Initial value of 'a' (identity matrix):")
print(a)
print()

# Diagonal matrix with ascending values
with torch.cuda.device(device_id):
    b[i:j, :] = (torch.eye(size // nranks, device="cuda") * (1 + torch.arange(i, j, device="cuda"))).type(torch.float8_e4m3fn)

print("Initial value of 'b' (diagonal matrix):")
print(b)
print()

init_scales = {
    "a": nvmath.distributed.linalg.advanced.helpers.matmul.create_mxfp8_scale(a, 0),  # 2^0 = 1
    "b": nvmath.distributed.linalg.advanced.helpers.matmul.create_mxfp8_scale(b, 0),  # 2^0 = 1
}

qualifiers = np.zeros((3,), dtype=matrix_qualifiers_dtype)
qualifiers[0]["is_transpose"] = True

options = {"block_scaling": True}

torch.set_printoptions(sci_mode=False)

with nvmath.distributed.linalg.advanced.Matmul(
    a,
    b,
    distributions=distributions,
    qualifiers=qualifiers,
    quantization_scales=init_scales,
    options=options,
) as mm:
    mm.plan()
    for i in range(1, p + 1):
        d, aux = mm.execute()

        torch.cuda.default_stream().synchronize()

        # Replace 'a' with a*b and use the output scale as input scale for the new 'a'
        d_out_scale = aux["d_out_scale"]
        print(f"{d_out_scale=}")
        # The result has row-wise distribution and 'a' has column-wise distribution.
        # To replace 'a' we need to change the result's distribution. Since a*b is
        # symmetric, we can simply transpose to change the distribution.
        a[:] = d.T
        mm.reset_operands(quantization_scales={"a": d_out_scale})

        # Print the result with quantization scales applied
        print(f"Result of b^{i} (with quantization scales applied):")
        print(nvmath.distributed.linalg.advanced.helpers.matmul.apply_mxfp8_scale(d, d_out_scale))
        print()
