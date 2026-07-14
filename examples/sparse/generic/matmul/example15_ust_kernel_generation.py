# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This example illustrates how to exhaustively find the best performing kernel
in the state space of automatically generated kernels for a particular format
and operation. The example uses experimentals APIs that are subject to change.
"""

import os

import torch
from cupyx.profiler import benchmark

from nvmath.sparse.generic import Matmul
from nvmath.sparse.ust import NamedFormats, Tensor
from nvmath.sparse.ust._emitter import count_matmul_kernels  # experimental API

# Select a size.
n = 1024 * 64

# Construct the tridiagonal matrix by summing the offsets
a = (
    torch.diag(4 * torch.ones((n,), dtype=torch.float32), 0)
    + torch.diag(torch.ones((n - 1,), dtype=torch.float32), 1)
    + torch.diag(-torch.ones((n - 1,), dtype=torch.float32), -1)
    + torch.diag(torch.ones((n - 2,), dtype=torch.float32), 2)
    + torch.diag(-torch.ones((n - 2,), dtype=torch.float32), -2)
    + torch.diag(torch.ones((n - 3,), dtype=torch.float32), 3)
    + torch.diag(-torch.ones((n - 3,), dtype=torch.float32), -3)
    + torch.diag(torch.ones((n - 5,), dtype=torch.float32), 5)
    + torch.diag(-torch.ones((n - 5,), dtype=torch.float32), -5)
).to_sparse_csr()
b = torch.ones((n,), dtype=torch.float32)

# Benchmark CPU using torch implementation of SpMV.
torch_cpu_result = torch.mv(a, b)
torch_cpu_bench_result = benchmark(torch.mv, (a, b), n_repeat=10)
torch_cpu_runtime_us = min(torch_cpu_bench_result.cpu_times) * 1e6
print(f"Torch ran in {torch_cpu_runtime_us:.2f}us. on CPU")

# Move to GPU.
a_gpu = a.cuda()
b_gpu = b.cuda()

# Benchmark GPU using torch implementation of SpMV.
torch_gpu_result = torch.mv(a_gpu, b_gpu)
torch_gpu_bench_result = benchmark(torch.mv, (a_gpu, b_gpu), n_repeat=10)
torch_gpu_runtime_us = min(torch_gpu_bench_result.gpu_times[0]) * 1e6
print(f"Torch ran in {torch_gpu_runtime_us:.2f}us. on GPU")

# Sanity check.
assert torch.allclose(torch_cpu_result.cuda(), torch_gpu_result, atol=1e-3)

# Prepare b and result in UST on GPU.
b_u = Tensor.from_package(b_gpu)
c_gpu = torch.zeros((n,), dtype=torch.float32).cuda()
c_u = Tensor.from_package(c_gpu)

# Try a few common formats provided by the UST (Universal Sparse Tensor).
for format_a in [
    NamedFormats.COO,
    NamedFormats.CSR,
    NamedFormats.CSC,
    NamedFormats.DIAI,
    NamedFormats.DIAJ,
    NamedFormats.DCSR,
    NamedFormats.DCSC,
    NamedFormats.BSRRight((16, 16)),
    NamedFormats.BSCRight((16, 16)),
]:
    # View "a" as UST, then convert to desired format on host, then migrate to device.
    # Note that because the UST conversion has a proof-of-concept implementation only,
    # this step may be costly.
    device_id = 0
    a_u = Tensor.from_package(a).convert(tensor_format=format_a, copy=False).to(device_id)

    # Determine number of kernels available to the code generator. Note that this is an
    # experimental method, and may be removed in future releases.
    K = count_matmul_kernels(a_u, b_u, c_u, a_u.dtype)
    print(f"=> {format_a.name} has {K} kernels")
    for kernel in range(K):
        os.environ["UST_CODEGEN_KERNEL"] = str(kernel)  # experimental API to pass kernel
        c_gpu.zero_()
        with Matmul(a_u, b_u, c_u, options={"codegen": True}) as mm:
            mm.plan()
            mm.execute()
            # Sanity check (note that since c_u and c_gpu share underlying memory, we can
            # directly assert on c_gpu rather than first making a pytorch view into c_u).
            assert torch.allclose(c_gpu, torch_gpu_result, atol=1e-3)
            # Benchmark.
            ust_gpu_bench_result = benchmark(mm.execute, n_repeat=10)
            ust_gpu_runtime_us = min(ust_gpu_bench_result.gpu_times[0]) * 1e6
            print(f"UST {format_a.name} kernel {kernel} ran in {ust_gpu_runtime_us:.2f}us. on GPU")
