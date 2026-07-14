# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import os

import numpy as np
import pytest
import scipy.sparse as sps

from nvmath.sparse.generic import Matmul
from nvmath.sparse.ust import NamedFormats, Tensor
from nvmath.sparse.ust._emitter import Backend, count_matmul_kernels, emit_apply_kernel

from ..utils.common_axes import JIT_AVAILABLE


def _modify_value_only(value):
    return value * 2


def _modify_value_with_indices(value, i, j):
    return value + i + j


def _compile_and_apply_kernel_value_only(a):
    u = Tensor.from_package(a)
    u.set_kernel(_modify_value_only, with_indices=False)
    u.run_kernel()
    return u


def _compile_and_apply_kernel_with_indices(a):
    u = Tensor.from_package(a)
    u.set_kernel(_modify_value_with_indices, with_indices=True)
    u.run_kernel()
    return u


def _tensor_to_backend(tensor, backend):
    if tensor.__module__ == "torch":
        torch_device = "cuda" if backend == Backend.CUDA else "cpu"
        return tensor.to(torch_device)
    else:
        raise NotImplementedError(f"Test error: don't know how to move {type(tensor)} to {backend}")


def _format_params():
    return [
        pytest.param(format_a, id=f"{format_a.name}")
        for format_a in [
            NamedFormats.DenseMatrixRight,
            NamedFormats.DenseMatrixLeft,
            NamedFormats.COO,
            NamedFormats.CSR,
            NamedFormats.CSC,
            NamedFormats.DCSR,
            NamedFormats.DCSC,
            NamedFormats.CROW,
            NamedFormats.CCOL,
            NamedFormats.DIAI,
            NamedFormats.DIAJ,
            NamedFormats.SkewDIAI,
            NamedFormats.SkewDIAJ,
            NamedFormats.BSRRight((2, 2)),
            NamedFormats.BSCRight((2, 2)),
            NamedFormats.BSRLeft((2, 2)),
            NamedFormats.BSCLeft((2, 2)),
            NamedFormats.DELTA(2),
            NamedFormats.Structured(4, 4),  # stress-test as "dense"
        ]
    ]


_FORMAT_PARAMS = _format_params()


# Transposition can be set directly on A or B or it can be implied
# by layout (viz "Right" on B). This has subtle differences on the
# information that the emitter sees, so we test these separately.
def _matmul(a, b, c, transpose_a=False, transpose_b=False):
    A_u = Tensor.from_package(a)
    B_u = Tensor.from_package(b)
    C_u = Tensor.from_package(c)
    if transpose_a or transpose_b:
        matrix_qualifiers_dtype = np.dtype([("is_transpose", "<i4"), ("is_conjugate", "<i4")])
        qualifiers = np.zeros((3,), dtype=matrix_qualifiers_dtype)
        qualifiers[0]["is_transpose"] = transpose_a
        qualifiers[1]["is_transpose"] = transpose_b
    else:
        qualifiers = None
    mm = Matmul(A_u, B_u, C_u, qualifiers=qualifiers, options={"codegen": True})
    mm.plan()
    mm.execute()


def test_source_code():
    cp = pytest.importorskip("cupy")
    a = cp.ones((10, 20), dtype=np.int64)
    u = Tensor.from_package(a)
    src, grid_iter = emit_apply_kernel(u, with_indices=False)
    assert (
        src == ""
        "\n"
        "// TENSOR FORMAT : DensedRight\n"
        "\n"
        "using CTP = long long;\n"
        "using VAL = long long;\n"
        "using POS = int;\n"
        "using CRD = int;\n"
        "using GRD = int;\n"
        "\n"
        "#define prolog_a(a) (a)\n"
        "\n"
        'extern "C" __device__ CTP apply(CTP);\n'
        "\n"
        'extern "C" __global__ void apply_kernel(\n'
        "  VAL* __restrict__ Aval,\n"
        "  POS Anse) {\n"
        "  const GRD x = blockIdx.x * blockDim.x + threadIdx.x;\n"
        "  if (x < Anse) {\n"
        "    const CTP vA = prolog_a(static_cast<CTP>(Aval[x]));\n"
        "    Aval[x] = static_cast<VAL>(apply(vA));\n"
        "  }\n"
        "}\n"
    )
    ti_grid_iter, endian = grid_iter
    assert len(ti_grid_iter) == 2 and endian


@pytest.mark.skipif(not JIT_AVAILABLE, reason="jitting is required for this test")
def test_apply_cupy_jit():
    cp = pytest.importorskip("cupy")
    cps = pytest.importorskip("cupyx.scipy.sparse")
    row = cp.array([0, 0, 1, 1, 2, 3], dtype=np.int32)
    col = cp.array([0, 1, 1, 3, 2, 3], dtype=np.int32)
    val = cp.array([1, 2, 3, 4, 5, 6], dtype=np.float32)
    coo = cps.coo_matrix((val, (row, col)), shape=(4, 8))
    coo.sum_duplicates()
    csr = cps.csr_matrix(coo)
    csc = cps.csc_matrix(coo)

    e1 = cp.array([2, 4, 6, 8, 10, 12], dtype=np.float32)
    e2 = cp.array([2, 5, 8, 12, 14, 18], dtype=np.float32)
    e3 = cp.array([2, 4, 6, 10, 8, 12], dtype=np.float32)
    e4 = cp.array([2, 5, 8, 14, 12, 18], dtype=np.float32)
    e5 = cp.array([2, 6, 10, 16, 18, 24], dtype=np.float32)
    e6 = cp.array([2, 6, 4, 5, 10, 16, 5, 6, 2, 18, 6, 7, 3, 24, 7, 8], dtype=np.float32)

    u = _compile_and_apply_kernel_value_only(coo)
    assert cp.array_equal(u.val, e1)
    u = _compile_and_apply_kernel_with_indices(coo)
    assert cp.array_equal(u.val, e2)

    u = _compile_and_apply_kernel_value_only(csr)
    assert cp.array_equal(u.val, e1)
    u = _compile_and_apply_kernel_with_indices(csr)
    assert cp.array_equal(u.val, e2)

    u = _compile_and_apply_kernel_value_only(csc)
    assert cp.array_equal(u.val, e3)
    u = _compile_and_apply_kernel_with_indices(csc)
    assert cp.array_equal(u.val, e4)

    # Examples that also visit the extra elements.

    d = u.convert(tensor_format=NamedFormats.DELTA(2))
    d.set_kernel(_modify_value_with_indices, with_indices=True)
    d.run_kernel()
    assert cp.array_equal(d.val, e5)

    s = u.convert(tensor_format=NamedFormats.Structured(2, 4))
    s.set_kernel(_modify_value_with_indices, with_indices=True)
    s.run_kernel()
    assert cp.array_equal(s.val, e6)


@pytest.mark.skipif(not JIT_AVAILABLE, reason="jitting is required for this test")
def test_apply_cupy_dia_jit():
    cps = pytest.importorskip("cupyx.scipy.sparse")
    row = np.array([0, 0, 1, 1, 1, 2], dtype=np.int32)
    col = np.array([0, 15, 0, 1, 7, 15], dtype=np.int32)
    val = np.array([1, 2, 3, 4, 5, 6], dtype=np.float32)
    coo = sps.coo_array((val, (row, col)), shape=(3, 16))
    dia = cps.dia_matrix(coo)  # builds fromp np/scipy only

    u = _compile_and_apply_kernel_value_only(dia)
    assert str(u) == (
        "---- Sparse Tensor<VAL=float32,POS=int32,CRD=int32,DIM=2,LVL=2>\n"
        "format   : [i, j] -> ((j - i): <LevelFormat.COMPRESSED>, j: <LevelFormat.RANGE>)\n"
        "device   : cuda\n"
        "dim      : [3, 16]\n"
        "lvl      : [18, 16]\n"
        "nse      : 80\n"
        "pos[0]   : [0, 5] #2\n"
        "crd[0]   : [-1, 0, 6, 13, 15] #5\n"
        "values   : [6.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, "
        "2.0, 8.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ..., 0.0, "
        "0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 12.0, 0.0, 0.0, 0.0, "
        "0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0] #80\n"
        "data     : 348 bytes\n"
        "sparsity : -66.67%\n"
        "----"
    )
    u = _compile_and_apply_kernel_with_indices(dia)
    assert str(u) == (
        "---- Sparse Tensor<VAL=float32,POS=int32,CRD=int32,DIM=2,LVL=2>\n"
        "format   : [i, j] -> ((j - i): <LevelFormat.COMPRESSED>, j: <LevelFormat.RANGE>)\n"
        "device   : cuda\n"
        "dim      : [3, 16]\n"
        "lvl      : [18, 16]\n"
        "nse      : 80\n"
        "pos[0]   : [0, 5] #2\n"
        "crd[0]   : [-1, 0, 6, 13, 15] #5\n"
        "values   : [7.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, "
        "2.0, 10.0, 4.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ..., 0.0, "
        "0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 13.0, 15.0, 29.0, 0.0, 0.0, 0.0, "
        "0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 19.0] #80\n"
        "data     : 348 bytes\n"
        "sparsity : -66.67%\n"
        "----"
    )


@pytest.mark.skipif(not JIT_AVAILABLE, reason="jitting is required for this test")
def test_apply_torch_jit():
    torch = pytest.importorskip("torch")
    a = torch.ones([10, 20], dtype=torch.float64).cuda()
    e = 2 * a
    u = _compile_and_apply_kernel_value_only(a)
    b = u.to_package()
    assert torch.equal(b, e)
    assert torch.equal(a, e)  # changed underlying array!


def test_matmul_cupy_jit():
    cp = pytest.importorskip("cupy")

    # DOT operation.
    a = cp.array([1, 2, 3, 4, 5, 6, 7, 8], dtype=np.float32)
    x = cp.array([8, 7, 6, 5, 4, 3, 2, 1], dtype=np.float32)
    y = cp.zeros((), dtype=np.float32)
    _matmul(a, x, y)
    assert y == 120.0

    # VM operation.
    a = cp.ones(32, dtype=np.float32)
    X = cp.ones((32, 64), dtype=np.float32)
    y = cp.zeros(64, dtype=np.float32)
    _matmul(a, X, y)
    e = cp.ones(64, dtype=np.float32) * 32
    assert cp.array_equal(y, e)

    # MV operation.
    A = cp.array([[1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 4, 1]], dtype=np.float32)
    x = cp.array([10, 20, 30, 40], dtype=np.float32)
    y = cp.zeros((3,), dtype=np.float32)
    _matmul(A, x, y)
    e = cp.array([300, 700, 410], dtype=np.float32)
    assert cp.array_equal(y, e)

    # MM operation.
    A = cp.array([[1, 2, 3, 4], [5, 6, 7, 8], [9, 8, 4, 1]], dtype=np.float32)
    X = cp.array([[10, 1, -1], [20, 2, -2], [30, 3, -3], [40, 4, -4]], dtype=np.float32)
    Y = cp.zeros((3, 3), dtype=np.float32)
    _matmul(A, X, Y)
    E = cp.array([[300.0, 30.0, -30.0], [700.0, 70.0, -70.0], [410.0, 41.0, -41.0]], dtype=np.float32)
    assert cp.array_equal(Y, E)

    # BMM operation (A and Y are batched).
    A = cp.ones((3, 7, 5), dtype=np.float32)
    X = cp.ones((5, 11), dtype=np.float32)
    Y = cp.zeros((3, 7, 11), dtype=np.float32)
    _matmul(A, X, Y)
    E = cp.ones((3, 7, 11), dtype=np.float32) * 5
    assert cp.array_equal(Y, E)

    # BMBM operation (all are batched).
    A = cp.ones((3, 7, 5), dtype=np.float32)
    X = cp.ones((3, 5, 11), dtype=np.float32)
    Y = cp.zeros((3, 7, 11), dtype=np.float32)
    _matmul(A, X, Y)
    E = cp.ones((3, 7, 11), dtype=np.float32) * 5
    assert cp.array_equal(Y, E)


def test_matmul_torch_jit():
    """
    Prepare a batched MM: C(b,i,k) = A(b,i,j) B(j,k)

    [[[ 1.,  2.,  3.,  4.],
      [ 5.,  6.,  7.,  8.],     [[1., 2.],
      [ 9., 10., 11., 12.]], x   [3., 4.],
               .                 [5., 6.],
     [[13., 14., 15., 16.],      [7., 8.]],
      [17., 18., 19., 20.],
      [21., 22., 23., 24.]]]  =  [[[ 50.,  60.],
                                   [114., 140.],
                                   [178., 220.]],
                                        .
                                  [[242., 300.],
                                   [306., 380.],
                                   [370., 460.]]
    """
    torch = pytest.importorskip("torch")

    # This is dense/dense/dense batching.
    A = (1.0 + torch.arange(2 * 3 * 4)).reshape(2, 3, 4).cuda()
    B = (1.0 + torch.arange(4 * 2)).reshape(4, 2).cuda()
    C = torch.zeros((2, 3, 2), dtype=torch.float32).cuda()
    E = torch.matmul(A, B)
    _matmul(A, B, C)
    assert torch.equal(C, E)

    # This is batch/dense/compressed batching.
    C = torch.zeros((2, 3, 2), dtype=torch.float32).cuda()
    batched_csr = A.to_sparse_csr(dense_dim=0)
    _matmul(batched_csr, B, C)
    assert torch.equal(C, E)

    # This is batch/dense/compressed batching with more dimensions.
    A = (1.0 + torch.arange(2 * 3 * 4 * 5)).reshape(2, 3, 4, 5).cuda()
    B = (1.0 + torch.arange(5 * 3)).reshape(5, 3).cuda()
    C = torch.zeros((2, 3, 4, 3), dtype=torch.float32).cuda()
    E = torch.matmul(A, B)
    batched_csr = A.to_sparse_csr(dense_dim=0)
    _matmul(batched_csr, B, C)
    assert torch.equal(C, E)

    # This is batch/dense/compressed batching with more dimensions (csc).
    C = torch.zeros((2, 3, 4, 3), dtype=torch.float32).cuda()
    batched_csc = A.to_sparse_csc(dense_dim=0)
    _matmul(batched_csc, B, C)
    assert torch.equal(C, E)

    # This is batch/dense/compressed batching with more dimensions (bsr).
    A = (1.0 + torch.arange(2 * 3 * 4 * 8)).reshape(2, 3, 4, 8).cuda()
    B = (1.0 + torch.arange(8 * 8)).reshape(8, 8).cuda()
    C = torch.zeros((2, 3, 4, 8), dtype=torch.float32).cuda()
    E = torch.matmul(A, B)
    batched_bsr = A.to_sparse_bsr(blocksize=(2, 2), dense_dim=0)
    _matmul(batched_bsr, B, C)
    assert torch.equal(C, E)

    # This is batch/dense/compressed batching with more dimensions (bsc).
    C = torch.zeros((2, 3, 4, 8), dtype=torch.float32).cuda()
    batched_bsc = A.to_sparse_bsc(blocksize=(2, 2), dense_dim=0)
    _matmul(batched_bsc, B, C)
    assert torch.equal(C, E)


def test_matmul_torch_transposed_vm_jit():
    torch = pytest.importorskip("torch")

    # VM: c(j) = a(i) B(i,j), direct and transposed
    A = 1.0 + torch.arange(5).cuda()
    B1 = 1.0 + torch.arange(5 * 3).reshape(5, 3).cuda()
    B2 = 1.0 + torch.arange(3 * 5).reshape(3, 5).cuda()
    C1 = torch.matmul(A, B1)
    C2 = torch.matmul(A, B2.T)

    # Same with dense UST.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A, B1, Z1)
    _matmul(A, B2.T, Z2)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with dense UST and transpose_b.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A, B1, Z1, transpose_b=False)
    _matmul(A, B2, Z2, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse UST.
    A = A.to_sparse()
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A, B1, Z1)
    _matmul(A, B2.T, Z2)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse UST and transpose_b.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A, B1, Z1, transpose_b=False)
    _matmul(A, B2, Z2, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)


def test_matmul_torch_transposed_mv_jit():
    torch = pytest.importorskip("torch")

    # MV: c(i) = A(i,j) b(i), direct, transposed
    A1 = 1.0 + torch.arange(3 * 5).reshape(3, 5).cuda()
    A2 = 1.0 + torch.arange(5 * 3).reshape(5, 3).cuda()
    B = 1.0 + torch.arange(5).cuda()
    C1 = torch.matmul(A1, B)
    C2 = torch.matmul(A2.T, B)

    # Same with dense UST.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1)
    _matmul(A2.T, B, Z2)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with dense UST and transpose_a.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1, transpose_a=False)
    _matmul(A2, B, Z2, transpose_a=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse UST.
    A1 = A1.to_sparse()
    A2 = A2.to_sparse()
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1)
    _matmul(A2.T.coalesce(), B, Z2)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse UST and transpose_a.
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1, transpose_a=False)
    _matmul(A2, B, Z2, transpose_a=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse CSR UST and transpose_a.
    A1 = A1.to_sparse_csr()
    A2 = A2.to_sparse_csr()
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1, transpose_a=False)
    _matmul(A2, B, Z2, transpose_a=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)

    # Same with sparse CSC UST and transpose_a.
    A1 = A1.to_sparse_csc()
    A2 = A2.to_sparse_csc()
    Z1 = torch.zeros((3,), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3,), dtype=torch.float32).cuda()
    _matmul(A1, B, Z1, transpose_a=False)
    _matmul(A2, B, Z2, transpose_a=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)


def test_matmul_torch_transposed_mm_jit():
    torch = pytest.importorskip("torch")

    # MM: c(i,k) = A(i,j) b(j,k), direct, transposed
    A1 = 1.0 + torch.arange(3 * 5).reshape(3, 5).cuda()
    A2 = 1.0 + torch.arange(5 * 3).reshape(5, 3).cuda()
    B1 = 1.0 + torch.arange(5 * 7).reshape(5, 7).cuda()
    B2 = 1.0 + torch.arange(7 * 5).reshape(7, 5).cuda()
    C1 = torch.matmul(A1, B1)
    C2 = torch.matmul(A1, B2.T)
    C3 = torch.matmul(A2.T, B1)
    C4 = torch.matmul(A2.T, B2.T)

    # Same with dense UST.
    Z1 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z3 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z4 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    _matmul(A1, B1, Z1)
    _matmul(A1, B2.T, Z2)
    _matmul(A2.T, B1, Z3)
    _matmul(A2.T, B2.T, Z4)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)
    assert torch.equal(Z3, C3)
    assert torch.equal(Z4, C4)

    # Same with dense UST and transpose_a/b.
    Z1 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z3 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z4 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    _matmul(A1, B1, Z1, transpose_a=False, transpose_b=False)
    _matmul(A1, B2, Z2, transpose_a=False, transpose_b=True)
    _matmul(A2, B1, Z3, transpose_a=True, transpose_b=False)
    _matmul(A2, B2, Z4, transpose_a=True, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)
    assert torch.equal(Z3, C3)
    assert torch.equal(Z4, C4)

    # Same with sparse UST and transpose_a/b.
    A1 = A1.to_sparse()
    A2 = A2.to_sparse()
    Z1 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z3 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z4 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    _matmul(A1, B1, Z1, transpose_a=False, transpose_b=False)
    _matmul(A1, B2, Z2, transpose_a=False, transpose_b=True)
    _matmul(A2, B1, Z3, transpose_a=True, transpose_b=False)
    _matmul(A2, B2, Z4, transpose_a=True, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)
    assert torch.equal(Z3, C3)
    assert torch.equal(Z4, C4)

    # Same with sparse CSR UST and transpose_a/b.
    A1 = A1.to_sparse_csr()
    A2 = A2.to_sparse_csr()
    Z1 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z3 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z4 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    _matmul(A1, B1, Z1, transpose_a=False, transpose_b=False)
    _matmul(A1, B2, Z2, transpose_a=False, transpose_b=True)
    _matmul(A2, B1, Z3, transpose_a=True, transpose_b=False)
    _matmul(A2, B2, Z4, transpose_a=True, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)
    assert torch.equal(Z3, C3)
    assert torch.equal(Z4, C4)

    # Same with sparse CSC UST and transpose_a/b.
    A1 = A1.to_sparse_csc()
    A2 = A2.to_sparse_csc()
    Z1 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z2 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z3 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    Z4 = torch.zeros((3, 7), dtype=torch.float32).cuda()
    _matmul(A1, B1, Z1, transpose_a=False, transpose_b=False)
    _matmul(A1, B2, Z2, transpose_a=False, transpose_b=True)
    _matmul(A2, B1, Z3, transpose_a=True, transpose_b=False)
    _matmul(A2, B2, Z4, transpose_a=True, transpose_b=True)
    assert torch.equal(Z1, C1)
    assert torch.equal(Z2, C2)
    assert torch.equal(Z3, C3)
    assert torch.equal(Z4, C4)


@pytest.mark.parametrize("format_a", _FORMAT_PARAMS)
@pytest.mark.parametrize("backend", [Backend.CUDA])
def test_matmul_torch_exhaustive_mv_jit(format_a, backend):
    torch = pytest.importorskip("torch")

    # MV: c(i) = A(i,j) b(j).
    A = _tensor_to_backend(1.0 + torch.arange(4 * 8).reshape(4, 8), backend)
    B = _tensor_to_backend(1.0 + torch.arange(8), backend)
    C = _tensor_to_backend(torch.matmul(A, B), backend)

    # JIT and test all the kernels exhaustively.
    A_d = Tensor.from_package(A)
    A_u = A_d.convert(tensor_format=format_a)
    B_u = Tensor.from_package(B)
    C_u = Tensor.from_package(_tensor_to_backend(torch.zeros(4), backend))
    K = count_matmul_kernels(A_u, B_u, C_u, A_u.dtype, backend=backend)
    for kernel in range(K):
        os.environ["UST_CODEGEN_KERNEL"] = str(kernel)
        Z = _tensor_to_backend(torch.zeros(4, dtype=A.dtype), backend)
        C_u = Tensor.from_package(Z)
        mm = Matmul(A_u, B_u, C_u, options={"codegen": True})
        mm.plan()
        mm.execute()
        assert torch.equal(C, Z)
    os.environ.pop("UST_CODEGEN_KERNEL", None)


@pytest.mark.parametrize("format_a", _FORMAT_PARAMS)
@pytest.mark.parametrize("backend", [Backend.CUDA])
def test_matmul_torch_exhaustive_mm_jit(format_a, backend):
    torch = pytest.importorskip("torch")

    # MM: c(i,k) = A(i,j) b(j,k).
    A = _tensor_to_backend(1.0 + torch.arange(4 * 8).reshape(4, 8), backend)
    B = _tensor_to_backend(1.0 + torch.arange(8 * 16).reshape(8, 16), backend)
    C = _tensor_to_backend(torch.matmul(A, B), backend)

    # JIT and test all kernels exhaustively.
    A_d = Tensor.from_package(A)
    A_u = A_d.convert(tensor_format=format_a)
    B_u = Tensor.from_package(B)
    C_u = Tensor.from_package(_tensor_to_backend(torch.zeros(4, 16), backend))
    K = count_matmul_kernels(A_u, B_u, C_u, A_u.dtype, backend=backend)
    for kernel in range(K):
        os.environ["UST_CODEGEN_KERNEL"] = str(kernel)
        Z = _tensor_to_backend(torch.zeros(4, 16), backend)
        C_u = Tensor.from_package(Z)
        mm = Matmul(A_u, B_u, C_u, options={"codegen": True})
        mm.plan()
        mm.execute()
        assert torch.equal(C, Z)
    os.environ.pop("UST_CODEGEN_KERNEL", None)
