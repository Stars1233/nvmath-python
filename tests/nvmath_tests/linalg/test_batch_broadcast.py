# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Behavior of stride-0 (broadcast) dimensions in matmul operand layouts.
"""

import pytest

from nvmath.linalg.advanced import MatmulOptions as AdvancedMatmulOptions
from nvmath.linalg.advanced import matmul as advanced_matmul
from nvmath.linalg.generic import MatmulOptions as GenericMatmulOptions
from nvmath.linalg.generic import matmul as generic_matmul

from .generic.matmul import CUBLAS_AVAILABLE
from .utils import assert_tensors_equal

parametrize_impl = pytest.mark.parametrize(
    "matmul_fn, options_cls",
    (
        pytest.param(advanced_matmul, AdvancedMatmulOptions, id="advanced"),
        pytest.param(generic_matmul, GenericMatmulOptions, id="generic"),
    ),
)
parametrize_framework = pytest.mark.parametrize("framework", ("torch", "cupy"))


def _make_helpers(framework):
    """
    Return (randn, expand) helpers for ``framework``.
    """
    if framework == "torch":
        torch = pytest.importorskip("torch")
        if not torch.cuda.is_available():
            pytest.skip("CUDA-capable torch required.")

        def randn(*shape):
            return torch.randn(*shape, device="cuda", dtype=torch.float32)

        def expand(t, shape):
            return t.expand(*shape)
    else:  # cupy
        cp = pytest.importorskip("cupy")
        rng = cp.random.default_rng(0)

        def randn(*shape):
            return rng.standard_normal(shape, dtype=cp.float32)

        def expand(t, shape):
            return cp.broadcast_to(t, shape)

    return randn, expand


@pytest.mark.skipif(not CUBLAS_AVAILABLE, reason="This test requires cuBLAS")
@parametrize_impl
@parametrize_framework
@pytest.mark.parametrize(
    "pattern",
    (
        "c_batch_broadcast_1d",
        "c_m_broadcast",
        "c_n_broadcast",
    ),
)
def test_inplace_rejects_broadcast_c(matmul_fn, options_cls, framework, pattern):
    """Reject ``inplace=True`` when ``C`` has a stride-0 dim of extent > 1:
    such layouts alias the same memory across distinct logical indices and
    would cause overlapping writes / undefined behavior on the inplace
    update."""
    randn, expand = _make_helpers(framework)

    M, K, N = 8, 16, 8
    Nb = 4

    if pattern == "c_batch_broadcast_1d":
        # 1-D batch where C is broadcast across the batch dim (stride 0).
        a = randn(Nb, M, K)
        b = randn(Nb, K, N)
        c = expand(randn(1, M, N), (Nb, M, N))
    elif pattern == "c_m_broadcast":
        # Non-batched, C's M dim is a stride-0 broadcast to full extent.
        a = randn(M, K)
        b = randn(K, N)
        c = expand(randn(1, N), (M, N))
    elif pattern == "c_n_broadcast":
        # Non-batched, C's N dim is a stride-0 broadcast to full extent N.
        # (The Nc == 1 broadcast case is already rejected by an earlier shape
        # check; this exercises the expand-to-full-extent variant that slips
        # past it: Nc == N0 but stride == 0.)
        a = randn(M, K)
        b = randn(K, N)
        c = expand(randn(M, 1), (M, N))

    with pytest.raises(ValueError, match="not injective"):
        matmul_fn(a, b, c=c, beta=1, options=options_cls(inplace=True))


@pytest.mark.skipif(not CUBLAS_AVAILABLE, reason="This test requires cuBLAS")
@parametrize_impl
@parametrize_framework
@pytest.mark.parametrize(
    "pattern",
    (
        "a_outer_singleton",
        "a_1d",
        "b_1d",
        "both_outer_singleton",
    ),
)
def test_batching_implicit_broadcast_stride0(matmul_fn, options_cls, framework, pattern):
    """Matmul accepts broadcast operands where some batch dim has stride 0
    (typically produced by ``torch.expand`` / ``cupy.broadcast_to``)."""
    randn, expand = _make_helpers(framework)

    M, K, N = 16, 32, 16
    A = randn(M, K)
    B = randn(K, N)

    if pattern == "a_outer_singleton":
        # strides (0, M*K, K, 1)
        a = expand(A.reshape(1, 1, M, K) if framework == "cupy" else A.unsqueeze(0).unsqueeze(0), (2, 1, M, K))
        b = randn(2, 1, K, N)
    elif pattern == "a_1d":
        # strides (0, K, 1)
        a = expand(A.reshape(1, M, K) if framework == "cupy" else A.unsqueeze(0), (4, M, K))
        b = randn(4, K, N)
    elif pattern == "b_1d":
        # strides (0, N, 1)
        a = randn(4, M, K)
        b = expand(B.reshape(1, K, N) if framework == "cupy" else B.unsqueeze(0), (4, K, N))
    elif pattern == "both_outer_singleton":
        a = expand(A.reshape(1, 1, M, K) if framework == "cupy" else A.unsqueeze(0).unsqueeze(0), (2, 1, M, K))
        b = expand(B.reshape(1, 1, K, N) if framework == "cupy" else B.unsqueeze(0).unsqueeze(0), (2, 1, K, N))

    result = matmul_fn(a, b, options=options_cls())
    assert_tensors_equal(result, a @ b)


@pytest.mark.skipif(not CUBLAS_AVAILABLE, reason="This test requires cuBLAS")
@parametrize_impl
@parametrize_framework
def test_batching_implicit_broadcast_rejects_mixed_stride0(matmul_fn, options_cls, framework):
    """A batch layout that mixes a real broadcast dim (stride 0, extent > 1)
    with a real non-broadcast dim (stride > 0, extent > 1) cannot be expressed
    as cuBLAS's single ``base + k * stride`` form. Both impls reject it via
    ``check_batch_tileable``."""
    randn, expand = _make_helpers(framework)

    M, K, N = 16, 32, 16
    N1, P = 2, 3
    X = randn(P, M, K)
    Y = randn(P, K, N)
    # batch (N1, P) / (0, M*K)
    a = expand(X.reshape(1, P, M, K) if framework == "cupy" else X.unsqueeze(0), (N1, P, M, K))
    # batch (N1, P) / (0, K*N)
    b = expand(Y.reshape(1, P, K, N) if framework == "cupy" else Y.unsqueeze(0), (N1, P, K, N))

    with pytest.raises(ValueError, match="not tileable"):
        matmul_fn(a, b, options=options_cls())
