# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
"""
Test the explicitly batched matrix multiplication API.
"""

import numpy as np
import pytest

import nvmath.linalg

from ...utils import assert_tensors_equal, sample_matrix
from . import CUBLAS_GROUPED_BATCHED_AVAILABLE, NVPL_AVAILABLE

use_cuda_options = (
    *((True,) if CUBLAS_GROUPED_BATCHED_AVAILABLE else ()),
    *((False,) if NVPL_AVAILABLE else ()),
)


@pytest.mark.parametrize(
    "qualifier_type,operand_index,dtype",
    [
        (nvmath.linalg.SymmetricMatrixQualifier, 0, np.float32),
        (nvmath.linalg.TriangularMatrixQualifier, 0, np.float32),
        (nvmath.linalg.HermitianMatrixQualifier, 0, np.complex64),
        (nvmath.linalg.DiagonalMatrixQualifier, 1, np.float32),
    ],
)
def test_unsupported_matrix_qualifiers(qualifier_type, operand_index, dtype):
    """Tests that a ValueError is raised when non-general matrix qualifiers are provided."""

    # Create simple test matrices
    m, n, k = 4, 4, 4
    if np.issubdtype(dtype, np.complexfloating):
        # For complex dtypes, create complex arrays
        a = (np.random.rand(m, k) + 1j * np.random.rand(m, k)).astype(dtype)
        b = (np.random.rand(k, n) + 1j * np.random.rand(k, n)).astype(dtype)
        c = (np.random.rand(m, n) + 1j * np.random.rand(m, n)).astype(dtype)
    else:
        # For real dtypes, create real arrays
        a = np.random.rand(m, k).astype(dtype, order="F")
        if qualifier_type == nvmath.linalg.DiagonalMatrixQualifier:
            b = np.random.rand(k).astype(dtype, order="F")
        else:
            b = np.random.rand(k, n).astype(dtype, order="F")
        if qualifier_type == nvmath.linalg.DiagonalMatrixQualifier:
            c = np.random.rand(m, k).astype(dtype, order="F")
        else:
            c = np.random.rand(m, n).astype(dtype, order="F")

    # Create qualifiers array with one non-general qualifier
    qualifiers = np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)

    qualifiers[operand_index] = qualifier_type.create()

    with pytest.raises(ValueError, match="No available explicitly batched generic matrix multiplication"):
        # Explicit batch: pass operands as lists
        nvmath.linalg.matmul(
            [a],
            [b],
            c=[c],
            beta=1.0,
            qualifiers=[qualifiers],
            execution="cuda",
        )


@pytest.mark.parametrize(
    "len_a,len_b,len_qualifiers",
    [
        # C has length 1, other operands have length > 1
        (4, 4, 4),
        (1, 2, 2),
        (2, 1, 2),
        (2, 2, 1),
        (3, 1, 1),
        (1, 3, 1),
        (1, 1, 3),
    ],
)
def test_unsupported_broadcasting(len_a, len_b, len_qualifiers):
    """
    Tests that a ValueError is raised when explicitly batched matmul
    does not support inplace execution when C is broadcast.
    """
    # Create test matrices for multiple batches
    m, n, k = 4, 4, 4
    dtype = np.float32
    len_c = 1

    # Create sequences with specified lengths
    a = [np.random.rand(m, k).astype(dtype, order="F") for _ in range(len_a)]
    b = [np.random.rand(k, n).astype(dtype, order="F") for _ in range(len_b)]
    c = [np.random.rand(m, n).astype(dtype, order="F") for _ in range(len_c)]

    # Create qualifiers for specified length
    qualifiers = [
        np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)
        for _ in range(len_qualifiers)
    ]

    # Create options with inplace=True
    options = nvmath.linalg.MatmulOptions(inplace=True)

    # Inplace execution with C broadcast should raise an error
    with pytest.raises(ValueError, match="Operation cannot be inplace if operand C is broadcast"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            qualifiers=qualifiers,
            options=options,
            execution="cuda",
        )


@pytest.mark.parametrize(
    "a_type,b_type,c_type,qualifiers_type",
    [
        ("explicit", "implicit", "explicit", "explicit"),
        ("implicit", "explicit", "explicit", "explicit"),
        ("non-batched", "non-batched", "explicit", "non-batched"),
        ("explicit", "non-batched", "non-batched", "non-batched"),
        ("non-batched", "explicit", "non-batched", "non-batched"),
        ("explicit", "explicit", "explicit", "non-batched"),
        ("explicit", "explicit", "explicit", "implicit"),
        ("non-batched", "non-batched", "non-batched", "explicit"),
    ],
)
def test_unsupported_mixed_batch_type(a_type, b_type, c_type, qualifiers_type):
    """
    Tests that a NotImplementedError is raised when some operands are explicitly
    batched and others are implicitly batched.
    """
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Create operand a based on type
    if a_type == "explicit":
        a = [np.random.rand(m, k).astype(dtype, order="F")]
    elif a_type == "implicit":
        a = np.random.rand(2, m, k).astype(dtype, order="F")
    else:  # non-batched
        a = np.random.rand(m, k).astype(dtype, order="F")

    # Create operand b based on type
    if b_type == "explicit":
        b = [np.random.rand(k, n).astype(dtype, order="F")]
    elif b_type == "implicit":
        b = np.random.rand(2, k, n).astype(dtype, order="F")
    else:  # non-batched
        b = np.random.rand(k, n).astype(dtype, order="F")

    # Create operand c based on type
    if c_type == "explicit":
        c = [np.random.rand(m, n).astype(dtype, order="F")]
    elif c_type == "implicit":
        c = np.random.rand(2, m, n).astype(dtype, order="F")
    else:  # non-batched
        c = np.random.rand(m, n).astype(dtype, order="F")

    # Create qualifiers based on type
    if qualifiers_type == "explicit":
        qualifiers = [np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)]
    elif qualifiers_type == "implicit":
        # Implicit batching not typically used for qualifiers, but test it anyway
        qualifiers = np.full((2, 3), nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)
    else:  # non-batched
        qualifiers = np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)

    with pytest.raises(ValueError, match="All arguments a, b, c, and qualifiers must be either implicitly batched"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            beta=1.0,
            qualifiers=qualifiers,
        )


@pytest.mark.parametrize("nested_operand", ["a", "b", "c", "qualifiers"])
def test_unsupported_multiple_explicit_batch_dimensions(nested_operand):
    """
    Tests that a ValueError is raised when multiple explicit batch
    dimensions are provided (sequence of sequences).
    """
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Create normal single-level sequences
    a = [np.random.rand(m, k).astype(dtype, order="F")]
    b = [np.random.rand(k, n).astype(dtype, order="F")]
    c = [np.random.rand(m, n).astype(dtype, order="F")]
    qualifiers = [np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)]

    # Make the specified operand a nested sequence (multiple explicit batch dimensions)
    if nested_operand == "a":
        a = [
            [np.random.rand(m, k).astype(dtype, order="F")],
            [np.random.rand(m, k).astype(dtype, order="F")],
        ]
    elif nested_operand == "b":
        b = [
            [np.random.rand(k, n).astype(dtype, order="F")],
            [np.random.rand(k, n).astype(dtype, order="F")],
        ]
    elif nested_operand == "c":
        c = [
            [np.random.rand(m, n).astype(dtype, order="F")],
            [np.random.rand(m, n).astype(dtype, order="F")],
        ]
    elif nested_operand == "qualifiers":
        qualifiers = [
            [np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)],
            [np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)],
        ]

    with pytest.raises(ValueError, match="Explicitly batched operands cannot be nested"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            beta=1.0,
            qualifiers=qualifiers,
        )


@pytest.mark.parametrize("use_cuda", use_cuda_options)
def test_simultaneous_explicit_and_implicit_batching(use_cuda):
    """
    Tests that mixed explicit and implicit batching works correctly.
    Each explicit batch element may itself be implicitly batched (leading dims).
    """
    m, n, k = 4, 4, 4
    dtype = np.float32
    execution = nvmath.linalg.ExecutionCUDA() if use_cuda else nvmath.linalg.ExecutionCPU()

    a = [np.random.rand(2, m, k).astype(dtype, order="C")]
    b = [np.random.rand(k, n).astype(dtype, order="C")]
    c = [np.random.rand(2, m, n).astype(dtype, order="C")]
    qualifiers = [np.full(3, nvmath.linalg.GeneralMatrixQualifier.create(), dtype=nvmath.linalg.matrix_qualifiers_dtype)]
    result = nvmath.linalg.matmul(
        a,
        b,
        c=c,
        beta=1.0,
        qualifiers=qualifiers,
        execution=execution,
    )
    assert len(result) == 1
    expected = a[0] @ b[0] + c[0]
    np.testing.assert_allclose(result[0], expected, rtol=1e-5)


def test_unsupported_batched_options():
    """Tests that a ValueError is raised when batched options are provided."""
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Create explicit batch operands
    a = [
        np.random.rand(m, k).astype(dtype, order="F"),
        np.random.rand(m, k).astype(dtype, order="F"),
    ]
    b = [
        np.random.rand(k, n).astype(dtype, order="F"),
        np.random.rand(k, n).astype(dtype, order="F"),
    ]

    # Try to provide options as a sequence (batched)
    batched_options = [
        nvmath.linalg.MatmulOptions(inplace=False),
        nvmath.linalg.MatmulOptions(inplace=False),
    ]

    with pytest.raises(TypeError, match="options must be a single value."):
        nvmath.linalg.matmul(a, b, options=batched_options)


def test_unsupported_batched_execution():
    """Tests that a ValueError is raised when batched execution is provided."""
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Create explicit batch operands
    a = [
        np.random.rand(m, k).astype(dtype, order="F"),
        np.random.rand(m, k).astype(dtype, order="F"),
    ]
    b = [
        np.random.rand(k, n).astype(dtype, order="F"),
        np.random.rand(k, n).astype(dtype, order="F"),
    ]

    # Try to provide execution as a sequence (batched)
    batched_execution = ["cuda", "cuda"]

    with pytest.raises(TypeError, match="execution must be a single value."):
        nvmath.linalg.matmul(a, b, execution=batched_execution)


@pytest.mark.parametrize("use_cuda", use_cuda_options)
def test_batched_alpha(use_cuda):
    """Tests that per-batch alpha applies correct per-batch scaling."""
    m, n, k = 4, 4, 4
    dtype = np.float32
    execution = nvmath.linalg.ExecutionCUDA() if use_cuda else nvmath.linalg.ExecutionCPU()

    # Create explicit batch operands
    a = [
        np.random.rand(m, k).astype(dtype, order="F"),
        np.random.rand(m, k).astype(dtype, order="F"),
    ]
    b = [
        np.random.rand(k, n).astype(dtype, order="F"),
        np.random.rand(k, n).astype(dtype, order="F"),
    ]

    batched_alpha = [1.0, 2.0]

    results = nvmath.linalg.matmul(a, b, alpha=batched_alpha, execution=execution)

    for i, r in enumerate(results):
        expected = batched_alpha[i] * (a[i] @ b[i])
        assert np.allclose(r, expected, rtol=1e-5), f"Batch {i} failed with alpha={batched_alpha[i]}"


@pytest.mark.parametrize("use_cuda", use_cuda_options)
def test_batched_beta(use_cuda):
    """Tests that per-batch beta applies correct per-batch scaling."""
    m, n, k = 4, 4, 4
    dtype = np.float32
    execution = nvmath.linalg.ExecutionCUDA() if use_cuda else nvmath.linalg.ExecutionCPU()

    # Create explicit batch operands
    a = [
        np.random.rand(m, k).astype(dtype, order="F"),
        np.random.rand(m, k).astype(dtype, order="F"),
    ]
    b = [
        np.random.rand(k, n).astype(dtype, order="F"),
        np.random.rand(k, n).astype(dtype, order="F"),
    ]
    c = [
        np.random.rand(m, n).astype(dtype, order="F"),
        np.random.rand(m, n).astype(dtype, order="F"),
    ]

    batched_beta = [0.5, 1.5]

    results = nvmath.linalg.matmul(a, b, c=c, beta=batched_beta, execution=execution)

    for i, r in enumerate(results):
        expected = (a[i] @ b[i]) + batched_beta[i] * c[i]
        assert np.allclose(r, expected, rtol=1e-5), f"Batch {i} failed with beta={batched_beta[i]}"


def test_unsupported_batched_stream():
    """Tests that a ValueError is raised when batched stream is provided."""
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Create explicit batch operands
    a = [
        np.random.rand(m, k).astype(dtype, order="F"),
        np.random.rand(m, k).astype(dtype, order="F"),
    ]
    b = [
        np.random.rand(k, n).astype(dtype, order="F"),
        np.random.rand(k, n).astype(dtype, order="F"),
    ]

    # Try to provide stream as a sequence (batched)
    batched_stream = [None, None]

    with pytest.raises(TypeError, match="stream must be a single value."):
        nvmath.linalg.matmul(a, b, stream=batched_stream)


def test_unsupported_mixed_package_operands():
    """
    Tests that a ValueError is raised if the operands in different explicit batches come
    from different packages.
    """
    m, n, k = 4, 4, 4
    dtype = np.float32

    # Test requires comparing CPU (numpy) with GPU (cupy)
    try:
        import cupy as cp
    except ImportError:
        pytest.skip("CuPy not available for testing mixed memory spaces")

    # First batch: All CuPy arrays (GPU memory)
    # Second batch: All NumPy arrays (CPU memory)
    a = [
        cp.random.rand(m, k).astype(dtype, order="F"),  # Batch 1: GPU
        np.random.rand(m, k).astype(dtype, order="F"),  # Batch 2: CPU
    ]
    b = [
        cp.random.rand(k, n).astype(dtype, order="F"),  # Batch 1: GPU
        np.random.rand(k, n).astype(dtype, order="F"),  # Batch 2: CPU
    ]
    c = [
        cp.random.rand(m, n).astype(dtype, order="F"),  # Batch 1: GPU
        np.random.rand(m, n).astype(dtype, order="F"),  # Batch 2: CPU
    ]

    with pytest.raises(TypeError, match="Library package mismatch"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            beta=1.0,
            execution="cuda",
        )


def test_unsupported_mixed_package_memory_spaces():
    """
    Tests that a ValueError is raised if different explicit batches use
    operands from different memory spaces (e.g., one batch on CPU, one batch on GPU).
    Uses torch so the package is always torch, but device_id differs.
    """
    torch = pytest.importorskip("torch")

    if not torch.cuda.is_available():
        pytest.skip("Test requires at least one CUDA device")

    m, n, k = 4, 4, 4
    dtype = torch.float32

    # First batch on CPU, second batch on CUDA:0 (package is torch for both)
    a = [
        torch.rand((m, k), dtype=dtype, device="cpu"),
        torch.rand((m, k), dtype=dtype, device="cuda:0"),
    ]
    b = [
        torch.rand((k, n), dtype=dtype, device="cpu"),
        torch.rand((k, n), dtype=dtype, device="cuda:0"),
    ]
    c = [
        torch.rand((m, n), dtype=dtype, device="cpu"),
        torch.rand((m, n), dtype=dtype, device="cuda:0"),
    ]

    with pytest.raises(TypeError, match="same device"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            beta=1.0,
            execution="cuda",
        )


@pytest.mark.parametrize(
    "a_batch,b_batch,c_batch,out_batch",
    (
        ((1,), (1,), (1,), (1,)),
        ((8,), (8,), (8,), (8,)),
        ((3,), (1,), (1,), (3,)),
        ((1,), (4,), (1,), (4,)),
        ((1,), (1,), (5,), (5,)),
        ((6,), (1,), (6,), (6,)),
        ((1,), (7,), (7,), (7,)),
        # NOTE: Multi-dimensional explicit batching not supported
        # ((10, 20), (10, 20), (10, 20), (10, 20)),
    ),
)
@pytest.mark.parametrize("use_cuda", use_cuda_options)
def test_batching_explicit(a_batch, b_batch, c_batch, out_batch, use_cuda):
    """
    Tests if matmul works with different batch sizes.
    """
    matrix_shape = (7, 7)

    def sample_batch(batch_shape):
        if batch_shape == ():
            return [sample_matrix("numpy/cupy", "float32", matrix_shape, use_cuda=use_cuda)]
        return [sample_matrix("numpy/cupy", "float32", matrix_shape, use_cuda=use_cuda) for _ in range(batch_shape[0])]

    a = sample_batch(a_batch)
    b = sample_batch(b_batch)
    c = sample_batch(c_batch)

    result = nvmath.linalg.matmul(a, b, c, beta=1)

    result = np.stack(result, axis=0)
    a = np.stack(a, axis=0)
    b = np.stack(b, axis=0)
    c = np.stack(c, axis=0)

    assert result.shape == (*out_batch, *matrix_shape)
    assert_tensors_equal(result, a @ b + c)


@pytest.mark.parametrize("framework", ("torch", "numpy/cupy"))
@pytest.mark.parametrize(
    "dtype_a,dtype_b",
    (
        ("float32", "float64"),
        ("complex64", "complex128"),
    ),
)
@pytest.mark.parametrize("use_cuda", use_cuda_options)
def test_dtype_mismatch_explicit_batch(framework, dtype_a, dtype_b, use_cuda):
    """
    Tests that an error is reported when explicit batches have different dtypes.
    """
    try:
        a = [
            sample_matrix(framework, dtype_a, (2, 2), use_cuda=use_cuda),
            sample_matrix(framework, dtype_b, (2, 2), use_cuda=use_cuda),
        ]
        b = [
            sample_matrix(framework, dtype_a, (2, 2), use_cuda=use_cuda),
            sample_matrix(framework, dtype_b, (2, 2), use_cuda=use_cuda),
        ]
    except NotImplementedError:
        pytest.skip("Unable to generate matrix of this dtype")
    with pytest.raises(ValueError, match=r"All batches must have the same dtype"):
        nvmath.linalg.matmul(a, b)


def _matrix_from_form(form, framework, dtype, shape, use_cuda):
    """Build a matrix operand from a form descriptor.

    Forms: ``None`` (absent), ``"naked"`` (single tensor), or int N (length-N list).
    """
    if form is None:
        return None
    if form == "naked":
        return sample_matrix(framework, dtype, shape, use_cuda=use_cuda)
    return [sample_matrix(framework, dtype, shape, use_cuda=use_cuda) for _ in range(form)]


def _scalar_from_form(form, base=0.5):
    """Same form descriptors as :func:`_matrix_from_form`, but for alpha/beta scalars."""
    if form is None:
        return None
    if form == "naked":
        return base
    return [base] * form


@pytest.mark.parametrize("use_cuda", use_cuda_options)
@pytest.mark.parametrize("batch_size", (1, 3))
@pytest.mark.parametrize("with_c", (False, True))
@pytest.mark.parametrize("use_execute_unchecked", (False, True), ids=("execute", "execute_unchecked"))
@pytest.mark.parametrize("reset_method", ("checked", "unchecked"))
def test_reset_explicit_batch(use_cuda, batch_size, with_c, use_execute_unchecked, reset_method):
    """End-to-end: reset_operands on explicit-batch Matmul recomputes correctly.

    Constructs an explicitly-batched Matmul, executes once, calls reset_operands with
    same-length explicit-batch lists, executes again, and verifies the second result
    matches the reference computed with the new operands. Guards against the validator
    over-rejecting legitimate same-length resets.
    """
    framework = "numpy/cupy"
    dtype = "float32"
    m, n, k = 4, 5, 6

    def mat(shape):
        return sample_matrix(framework, dtype, shape, use_cuda=use_cuda)

    init_kwargs = {"alpha": [0.3 + 0.1 * i for i in range(batch_size)]}
    if with_c:
        init_kwargs["c"] = [mat((m, n)) for _ in range(batch_size)]
        init_kwargs["beta"] = [0.5 + 0.1 * i for i in range(batch_size)]

    with nvmath.linalg.Matmul(
        [mat((m, k)) for _ in range(batch_size)],
        [mat((k, n)) for _ in range(batch_size)],
        **init_kwargs,
    ) as mm:
        mm.plan()
        do_execute = mm.execute_unchecked if use_execute_unchecked else mm.execute
        do_execute()

        a_new = [mat((m, k)) for _ in range(batch_size)]
        b_new = [mat((k, n)) for _ in range(batch_size)]
        reset_kwargs = {"a": a_new, "b": b_new}
        if with_c:
            reset_kwargs["c"] = [mat((m, n)) for _ in range(batch_size)]

        if reset_method == "unchecked":
            mm.reset_operands_unchecked(**reset_kwargs)
        else:
            mm.reset_operands(**reset_kwargs)
        results = do_execute()

        # Compare per-batch in the operand's native array package so cupy/numpy stay
        # consistent — np.stack would silently return a cupy array via the dispatch
        # protocol when use_cuda is True, which then can't be multiplied by a numpy array.
        for i in range(batch_size):
            expected = (a_new[i] @ b_new[i]) * init_kwargs["alpha"][i]
            if with_c:
                expected = expected + reset_kwargs["c"][i] * init_kwargs["beta"][i]
            assert_tensors_equal(results[i], expected)


@pytest.mark.parametrize("reset_method", ("checked", "unchecked"))
def test_reset_explicit_batch_form_equivalence(reset_method):
    """reset_operands accepts naked vs. length-1 Sequence as equivalent forms.

    Construction-only (no plan/execute), so this exercises the validator on any
    machine — CI workers without BLAS included.
    """
    framework, dtype, use_cuda = "numpy/cupy", "float32", False

    def mat_a():
        return sample_matrix(framework, dtype, (2, 3), use_cuda=use_cuda)

    def mat_b():
        return sample_matrix(framework, dtype, (3, 2), use_cuda=use_cuda)

    # Constructor: a is a length-3 list, b is a length-1 list (effective length 1 =
    # broadcast).
    with nvmath.linalg.generic.Matmul([mat_a() for _ in range(3)], [mat_b()]) as mm:

        def do_reset(**kwargs):
            if reset_method == "unchecked":
                mm.reset_operands_unchecked(**kwargs)
            else:
                mm.reset_operands(**kwargs)

        # All-None reset only has a defined contract on the checked path, where it is
        # rejected because there is nothing to update. The unchecked path makes no such
        # guarantee -- the caller must supply a correct, complete operand set -- so an
        # all-None call there is out of contract and not exercised here.
        if reset_method == "checked":
            with pytest.raises(ValueError, match="at least one operand"):
                do_reset()
        # Length-3 list for a — matches construction effective length.
        do_reset(a=[mat_a() for _ in range(3)])
        # Naked tensor for b — effective length 1, matches construction.
        do_reset(b=mat_b())
        # Length-1 list for b — also effective length 1; form-equivalent to naked.
        do_reset(b=[mat_b()])
        # Combined selective reset.
        do_reset(a=[mat_a() for _ in range(3)], b=mat_b())


@pytest.mark.parametrize(
    "construct_forms,reset_forms,expected_match",
    [
        # Length-mismatch errors (mismatches branch).
        pytest.param(
            {"a": 3, "b": 1},
            {"a": 2},
            r"a was originally length 3 but reset_operands received length 2",
            id="a-too-short",
        ),
        pytest.param(
            {"a": 3, "b": 1},
            {"a": "naked"},
            r"a was originally length 3 but reset_operands received length 1",
            id="a-naked-replaces-seq3",
        ),
        pytest.param(
            {"a": 3, "b": 1},
            {"b": 3},
            r"b was originally length 1 but reset_operands received length 3",
            id="b-seq3-replaces-broadcast",
        ),
        pytest.param(
            {"a": 3, "b": 3, "alpha": 3},
            {"alpha": 2},
            r"alpha was originally length 3 but reset_operands received length 2",
            id="alpha-len2-replaces-len3",
        ),
        pytest.param(
            {"a": 3, "b": 3, "alpha": 3},
            {"alpha": "naked"},
            r"alpha was originally length 3 but reset_operands received length 1",
            id="alpha-naked-replaces-len3",
        ),
        pytest.param(
            {"a": 3, "b": 3, "alpha": "naked"},
            {"alpha": 3},
            r"alpha was originally length 1 but reset_operands received length 3",
            id="alpha-len3-replaces-naked",
        ),
        pytest.param(
            {"a": 3, "b": 1},
            {"a": "naked", "b": 3},
            r"a was originally length 3 .* b was originally length 1",
            id="multiple-mismatches",
        ),
        # Unprovided errors (unprovided branch).
        pytest.param(
            {"a": 3, "b": 3},
            {"c": 3},
            r"cannot set operand\(s\) c because they were not provided",
            id="unprovided-c",
        ),
        pytest.param(
            {"a": 3, "b": 3},
            {"alpha": "naked"},
            r"cannot set operand\(s\) alpha because they were not provided",
            id="unprovided-alpha",
        ),
        pytest.param(
            {"a": 3, "b": 3},
            {"beta": "naked"},
            r"cannot set operand\(s\) beta because they were not provided",
            id="unprovided-beta",
        ),
        pytest.param(
            {"a": 3, "b": 3},
            {"c": "naked", "alpha": "naked"},
            r"cannot set operand\(s\) c, alpha because they were not provided",
            id="unprovided-multiple",
        ),
    ],
)
def test_reset_explicit_batch_rejects(construct_forms, reset_forms, expected_match):
    """reset_operands rejects mismatched batch counts and unprovided operands.

    Construction-only (validator fires before plan/execute), so this runs on any worker.
    """
    framework, dtype, use_cuda = "numpy/cupy", "float32", False
    shape_a, shape_b, shape_c = (2, 3), (3, 2), (2, 2)

    init_kwargs = {}
    a = _matrix_from_form(construct_forms.get("a"), framework, dtype, shape_a, use_cuda)
    b = _matrix_from_form(construct_forms.get("b"), framework, dtype, shape_b, use_cuda)
    if (c := _matrix_from_form(construct_forms.get("c"), framework, dtype, shape_c, use_cuda)) is not None:
        init_kwargs["c"] = c
    if (alpha := _scalar_from_form(construct_forms.get("alpha"))) is not None:
        init_kwargs["alpha"] = alpha
    if (beta := _scalar_from_form(construct_forms.get("beta"))) is not None:
        init_kwargs["beta"] = beta

    with nvmath.linalg.Matmul(a, b, **init_kwargs) as mm:
        reset_kwargs = {}
        for key, shape in (("a", shape_a), ("b", shape_b), ("c", shape_c)):
            if key in reset_forms:
                reset_kwargs[key] = _matrix_from_form(reset_forms[key], framework, dtype, shape, use_cuda)
        for key in ("alpha", "beta"):
            if key in reset_forms:
                reset_kwargs[key] = _scalar_from_form(reset_forms[key])

        with pytest.raises(ValueError, match=expected_match):
            mm.reset_operands(**reset_kwargs)


@pytest.mark.parametrize("use_cuda", use_cuda_options)
@pytest.mark.parametrize("batch_size", (1, 3))
@pytest.mark.parametrize("with_c", (False, True))
@pytest.mark.parametrize("reset_method", ("checked", "unchecked"))
def test_release_then_reset_explicit_batch(use_cuda, batch_size, with_c, reset_method):
    """
    After release_operands on explicit batching:
    - reset_operands with an incomplete set of required operands must raise
      (checked path only -- unchecked deliberately waives this validation).
    - reset_operands(_unchecked) with the full set recovers the planned state,
      preserving the originally constructed alpha/beta.
    """
    framework = "numpy/cupy"
    dtype = "float32"
    m, n, k = 4, 5, 6

    def mat(shape):
        return sample_matrix(framework, dtype, shape, use_cuda=use_cuda)

    a = [mat((m, k)) for _ in range(batch_size)]
    b = [mat((k, n)) for _ in range(batch_size)]
    matmul_kwargs = {"alpha": [0.3 + 0.1 * i for i in range(batch_size)]}
    if with_c:
        matmul_kwargs["c"] = [mat((m, n)) for _ in range(batch_size)]
        matmul_kwargs["beta"] = [0.5 + 0.1 * i for i in range(batch_size)]

    a_new = [mat((m, k)) for _ in range(batch_size)]
    b_new = [mat((k, n)) for _ in range(batch_size)]
    c_new = [mat((m, n)) for _ in range(batch_size)] if with_c else None

    with nvmath.linalg.Matmul(a, b, **matmul_kwargs) as mm:
        mm.plan()
        mm.execute()
        mm.release_operands()

        if reset_method == "checked":
            required_match = r"After release_operands.*all required operands must be provided"
            with pytest.raises(ValueError, match=required_match):
                mm.reset_operands(a=a_new)
            with pytest.raises(ValueError, match=required_match):
                mm.reset_operands(b=b_new)
            if with_c:
                with pytest.raises(ValueError, match=required_match):
                    mm.reset_operands(a=a_new, b=b_new)
                with pytest.raises(ValueError, match=required_match):
                    mm.reset_operands(a=a_new, c=c_new)
                with pytest.raises(ValueError, match=required_match):
                    mm.reset_operands(b=b_new, c=c_new)

        reset_kwargs = {"a": a_new, "b": b_new}
        if with_c:
            reset_kwargs["c"] = c_new
        if reset_method == "unchecked":
            mm.reset_operands_unchecked(**reset_kwargs)
        else:
            mm.reset_operands(**reset_kwargs)
        results = mm.execute()

        for i in range(batch_size):
            expected = (a_new[i] @ b_new[i]) * matmul_kwargs["alpha"][i]
            if with_c:
                expected = expected + c_new[i] * matmul_kwargs["beta"][i]
            assert_tensors_equal(results[i], expected)


@pytest.mark.parametrize(
    "len_alpha,len_beta",
    [
        # Singleton C combined with batched alpha and/or beta also broadcasts C
        # across groups via ``_zip_broadcast`` and must be rejected for inplace.
        (3, 1),
        (1, 3),
        (3, 3),
    ],
)
def test_unsupported_broadcasting_alpha_beta(len_alpha, len_beta):
    """``alpha``/``beta`` as sequences drive group-level broadcasting just like
    a/b/qualifiers do; combined with a singleton ``C`` and ``inplace=True`` they
    would reuse the same ``C`` buffer across groups, so reject up front."""
    m, n, k = 4, 4, 4
    dtype = np.float32

    a = [np.random.rand(m, k).astype(dtype, order="F")]
    b = [np.random.rand(k, n).astype(dtype, order="F")]
    c = [np.random.rand(m, n).astype(dtype, order="F")]
    alpha = [1.0] * len_alpha
    beta = [1.0] * len_beta

    options = nvmath.linalg.MatmulOptions(inplace=True)

    with pytest.raises(ValueError, match="Operation cannot be inplace if operand C is broadcast"):
        nvmath.linalg.matmul(
            a,
            b,
            c=c,
            alpha=alpha,
            beta=beta,
            options=options,
            execution="cuda",
        )
