# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Each MXFP8 block-scaled matrix multiplication produces both a result and the quantization
scale that describes it. This example shows how that output scale can be fed straight
in as the input scale for the next multiplication. We use this to compute a matrix
exponentiation by chaining multiplications, feeding each result back in as operand 'a'.

FP8 is only supported with cuBLAS 12.8 or newer and on devices with compute
capability 10.0 or higher.
"""

import torch

import nvmath

size = 256

p = 4

# We will compute b^p = a*b*b*...*b
a = torch.eye(size, device="cuda", dtype=torch.float8_e4m3fn)  # Identity matrix
print("Initial value of 'a' (identity matrix):")
print(a)
print()

b = (
    (torch.eye(size, device="cuda") * (1 + torch.arange(size, device="cuda"))).type(torch.float8_e4m3fn).T
)  # Diagonal matrix with ascending values
print("Initial value of 'b' (diagonal matrix):")
print(b)
print()

b_scale = nvmath.linalg.advanced.helpers.matmul.create_mxfp8_scale(b, 0)  # 2^0 = 1

init_scales = {
    "a": nvmath.linalg.advanced.helpers.matmul.create_mxfp8_scale(a, 0),  # 2^0 = 1
    "b": b_scale,
}

options = {
    "block_scaling": True,
}

torch.set_printoptions(sci_mode=False)

with nvmath.linalg.advanced.Matmul(a, b, quantization_scales=init_scales, options=options) as mm:
    mm.plan()
    for i in range(1, p + 1):
        d, aux = mm.execute()

        # Replace 'a' with a*b and use the output scale as input scale for the new 'a'
        d_out_scale = aux["d_out_scale"]
        print(f"{d_out_scale=}")
        mm.reset_operands(a=d, quantization_scales={"a": d_out_scale})

        # Print the result with quantization scales applied
        print(f"Result of b^{i} (with quantization scales applied):")
        print(nvmath.linalg.advanced.helpers.matmul.apply_mxfp8_scale(d, d_out_scale))
        print()
