# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example demonstrates automatic output scaling in NVFP4 mode.
When using NVFP4, the output is automatically scaled during the matmul, and the scale
factors that were applied are returned in the auxiliary output under the `d_out_scale`
key. These scales can be used as input for subsequent matrix multiplications (see the
mxfp8_chaining example) or applied to the result using helper functions.

To use NVFP4, set the `block_scaling` option to True.

The layout of NVFP4 scales is complex. To simplify working with them, we provide helper
functions in `nvmath.linalg.advanced.helpers.matmul`. For more advanced
operations on NVFP4 scales, please refer to the cuBLAS documentation.

NVFP4 is only supported with compute capability 10.0 or higher.

$ mpiexec -n 4 python example22_nvfp4_d_out.py
"""

import numpy as np
import torch
from mpi4py import MPI

import nvmath.distributed
from nvmath.distributed.distribution import Slab
from nvmath.distributed.linalg.advanced import matrix_qualifiers_dtype
from nvmath.linalg.advanced.helpers.matmul import BlockScalingFormat, expand_block_scale, quantize_to_fp4, unpack_fp4

# Initialize nvmath.distributed.
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nranks = comm.Get_size()
device_id = rank % torch.cuda.device_count()
# cuBLASMp requires NCCL communication backend.
nvmath.distributed.initialize(device_id, comm, backends=["nccl"])

# Prepare sample input data. Note that, for local GEMMs, M and N must be divisible
# by 128, and K must be divisible by 64 for NVFP4.
m, n, k = 512, 256, 512

row_wise_distribution = Slab.X
col_wise_distribution = Slab.Y

# FP4 operations require TN input layout.

with torch.cuda.device(device_id):
    a_fp32 = torch.zeros(*row_wise_distribution.shape(rank, (m, k)), dtype=torch.float32, device="cuda")
    b_fp32 = torch.rand(*row_wise_distribution.shape(rank, (n, k)), dtype=torch.float32, device="cuda")

# Get a transposed view to obtain column-major memory layout. Note that this
# also changes the distribution of 'a' and 'b' (see example01 for more information).
a_fp32 = a_fp32.T  # 'a' is now (k, m) with col_wise_distribution
b_fp32 = b_fp32.T  # 'b' is now (k, n) with col_wise_distribution

# Distributions for 'a', 'b', and result matrix 'd'
distributions = [col_wise_distribution, col_wise_distribution, row_wise_distribution]

# Create matrix 'a' with values increasing by column to demonstrate scaling with different
# magnitudes (each column will have progressively larger values)
a_fp32[:] = torch.arange(m // nranks * rank, m // nranks * (rank + 1))[None, :]

# Quantize 'a' and 'b' to FP4. FP4 E2M1 packs two 4-bit values per byte.
# The packing is performed along the specified axis, which must be the row axis
# for column-major matrices (as required by cuBLASMp).
a = quantize_to_fp4(a_fp32, axis=-2)
b = quantize_to_fp4(b_fp32, axis=-2)

print("Matrix 'a' (note that this is packed format with two FP4 values per byte):")
print(a)
print()

print("Matrix 'b' (note that this is packed format with two FP4 values per byte):")
print(b)
print()

# While NVFP4 allows different scales for different blocks in 'a' and 'b',
# for simplicity we assign the same scale to every block.
# Scales have E4M3 dtype.
# Note: We don't set a scale for 'd' since NVFP4 automatically scales the result to fit
# within the output type's dynamic range.
scales = {
    # 0.02 scale factor for all blocks of 'a'.
    "a": torch.full((a_fp32.numel() // 16,), 0.02, dtype=torch.float8_e4m3fn, device=f"cuda:{device_id}"),
    # 1.0 scale factor for all blocks of 'b'.
    "b": torch.full((b_fp32.numel() // 16,), 1.0, dtype=torch.float8_e4m3fn, device=f"cuda:{device_id}"),
}

# Enable block scaling
options = {"block_scaling": True}

qualifiers = np.zeros((3,), dtype=matrix_qualifiers_dtype)
qualifiers[0]["is_transpose"] = True

# Perform the multiplication. The result is a tuple containing (result, aux).
# The aux dictionary contains "d_out_scale" - the scale used for the result.
result, aux = nvmath.distributed.linalg.advanced.matmul(
    a,
    b,
    distributions=distributions,
    qualifiers=qualifiers,
    quantization_scales=scales,
    options=options,
)

# Decode from packed FP4 to FP32 (note that the result is still unscaled).
result = unpack_fp4(result, axis=-2)

# Display results
print("Result (each block scaled to fit within FP4 range):")
# Printing the tensor synchronizes on the default CUDA stream.
print(result)
print()

# Examine the output quantization scales
if rank == 0:
    print(f"Auxiliary output contains these keys: {list(aux.keys())}")
print(
    f"'d' scale tensor shape: {aux['d_out_scale'].shape}, type: {aux['d_out_scale'].dtype}. "
    f"Contains {len(aux['d_out_scale'].type(torch.float32).unique())} unique scale factors."
)

# Apply the scale to get the actual result. Note: This helper function is for demonstration
# purposes. For production use, set result_type to a non-FP4 type instead.
expanded_scales = expand_block_scale(aux["d_out_scale"], result, BlockScalingFormat.NVFP4, axis=-2, output_dtype=torch.float32)
actual_result = result.type(torch.float32) * expanded_scales
print("Final result (with quantization scales applied):")
print(actual_result)
