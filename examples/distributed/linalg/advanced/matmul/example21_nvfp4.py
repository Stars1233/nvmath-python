# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates basic distributed matrix multiplication of FP4 tensors using
NVFP4 (microscaled FP4) quantization scales.

With NVFP4 microscaling:
- NVFP4 scales are applied to each 16-element block of the tensors, rather than using a
  single tensor-wide scaling factor. This allows more fine-grained control over scaling
  and improves the accuracy of NVFP4 operations.
- NVFP4 scales are E4M3 numbers.
- In NVFP4 mode, if the output is FP4, it is scaled automatically during the matmul, and the
  scale factors that were applied are returned in the auxiliary output under the
  `d_out_scale` key. This is covered in the next example.

To use NVFP4, set the `block_scaling` option to True.

The layout of the quantization scales is relatively complex. To facilitate working with
NVFP4, we provide helper functions in `nvmath.linalg.advanced.helpers.matmul`.

NVFP4 is only supported with compute capability 10.0 or higher.

$ mpiexec -n 4 python example21_nvfp4.py
"""

import numpy as np
import torch
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg.advanced import matrix_qualifiers_dtype
from nvmath.linalg.advanced.helpers.matmul import quantize_to_fp4

# Initialize nvmath.distributed.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % torch.cuda.device_count()
# cuBLASMp requires NCCL communication backend.
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Prepare sample input data. Note that, for local GEMMs, M and N must be divisible
# by 128, and K must be divisible by 64 for NVFP4.
m, n, k = 512, 512, 512

row_wise_distribution = Slab.X
col_wise_distribution = Slab.Y

# FP4 operations require TN input layout.

with torch.cuda.device(device_id):
    a_fp32 = torch.zeros(*row_wise_distribution.shape(rank, (m, k)), dtype=torch.float32, device="cuda")
    # 'b' is filled with ones.
    b_fp32 = torch.ones(*row_wise_distribution.shape(rank, (n, k)), dtype=torch.float32, device="cuda")

# Get a transposed view to obtain column-major memory layout. Note that this
# also changes the distribution of 'a' and 'b' (see example01 for more information).
a_fp32 = a_fp32.T  # 'a' is now (k, m) with col_wise_distribution
b_fp32 = b_fp32.T  # 'b' is now (k, n) with col_wise_distribution

# Distributions for 'a', 'b', and result matrix 'd'
distributions = [col_wise_distribution, col_wise_distribution, row_wise_distribution]

# Initialize 'a' as a global identity matrix.
with torch.cuda.device(device_id):
    i = rank * (m // nranks)
    j = i + (m // nranks)
    a_fp32[i:j, :] = torch.eye(m // nranks, device="cuda", dtype=torch.float32)

# Quantize 'a' and 'b' to FP4.
a = quantize_to_fp4(a_fp32, axis=-2)
b = quantize_to_fp4(b_fp32, axis=-2)

# While NVFP4 allows different scales for different blocks in 'a' and 'b',
# for simplicity we assign the same scale to every block.
# Scales have E4M3 dtype.
scales = {
    # 0.5 scale factor for all blocks of 'a'.
    "a": torch.full((a_fp32.numel() // 16,), 0.5, dtype=torch.float8_e4m3fn, device=f"cuda:{device_id}"),
    # 8.0 scale factor for all blocks of 'b'.
    "b": torch.full((b_fp32.numel() // 16,), 8.0, dtype=torch.float8_e4m3fn, device=f"cuda:{device_id}"),
}

qualifiers = np.zeros((3,), dtype=matrix_qualifiers_dtype)
qualifiers[0]["is_transpose"] = True

# Enable block scaling by setting the `block_scaling` option to True. For simplicity, we
# request FP16 output. For NVFP4 output scaling, see the nvfp4_d_out_scale example.
options = {"block_scaling": True, "result_type": nvmath.CudaDataType.CUDA_R_16F}

# Perform the multiplication.
result = nvmath.distributed.linalg.advanced.matmul(
    a,
    b,
    distributions=distributions,
    qualifiers=qualifiers,
    quantization_scales=scales,
    options=options,
)

# Compute reference result without scaling
reference = nvmath.distributed.linalg.advanced.matmul(
    a_fp32,
    b_fp32,
    distributions=distributions,
    qualifiers=qualifiers,
)
if rank == 0:
    # Printing the tensor synchronizes on the default CUDA stream.
    print(f"Reference result (without scaling):\n{reference}")

    # Print the result with scaling applied
    print(f"Result with scaling ('a' scaled by 0.5, 'b' scaled by 8):\n{result}")
