# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Tests specific to the FFT key APIs: :meth:`nvmath.fft.FFT.create_key` and the
matching :meth:`nvmath.fft.FFT.get_key` instance method."""

import numpy as np
import pytest

import nvmath
from nvmath.internal import tensor_wrapper

from .utils.common_axes import (
    DType,
    Framework,
)
from .utils.input_fixtures import (
    get_random_input_data,
    init_assert_exec_backend_specified,
)
from .utils.support_matrix import supported_backends

# DO NOT REMOVE, this call creates a fixture that enforces
# specifying execution option to the FFT calls in tests
# defined in this file
assert_exec_backend_specified = init_assert_exec_backend_specified()


@pytest.mark.parametrize(
    ("framework", "exec_backend", "mem_backend", "shape", "ndim", "axes"),
    [
        (
            framework,
            exec_backend,
            mem_backend,
            shape,
            ndim,
            axes,
        )
        for framework in Framework.enabled()
        for exec_backend in supported_backends.exec
        for mem_backend in supported_backends.framework_mem[framework]
        for shape, ndim, axes in [
            ((128,), 1, (0,)),
            ((128,), 1, (-1,)),
            ((64, 128), 2, (1,)),
            ((64, 128), 2, (0, 1)),
            ((64, 128), 2, (-1,)),
        ]
    ],
)
def test_key_from_init_matches_create_key(
    seeder,
    framework,
    exec_backend,
    mem_backend,
    shape,
    ndim,
    axes,
):
    """
    This test verifies that using the same data to create an FFT object and
    calling get_key() on the object produces the same key as calling
    the static create_key() method.
    """

    dtype = DType.complex64

    # Generate random operand
    signal = get_random_input_data(framework, shape, dtype, mem_backend)

    # Create FFT object and get key from instance method
    with nvmath.fft.FFT(signal, axes=axes, execution=exec_backend.nvname) as f:
        f.plan()
        key_from_instance = f.get_key()

    # Get key from static method
    key_from_static = nvmath.fft.FFT.create_key(signal, axes=axes, execution=exec_backend.nvname)

    # Verify they match
    assert key_from_instance == key_from_static, (
        f"Keys do not match for ndim={ndim}, axes={axes}\nInstance key: {key_from_instance}\nStatic key: {key_from_static}"
    )


@pytest.mark.parametrize("exec_backend", supported_backends.exec)
def test_key_cross_device_strided_operand(exec_backend):
    """
    create_key() and get_key() should return the same key for cross-device execution
    with a strided (non-contiguous) NumPy array as user-provided operand.
    """

    base_shape = 10, 30, 40
    a = np.arange(np.prod(base_shape), dtype=np.float32).reshape(base_shape)
    # Create a strided (non-contiguous) array via slicing
    a = a[4:, 3:, 1:]

    axes = (-2, -1)
    options = {"fft_type": "R2C"}

    # Get key from static method (computes from user's original operand)
    key_from_static = nvmath.fft.FFT.create_key(a, axes=axes, options=options, execution=exec_backend.nvname)

    # Create FFT object and get key from instance method
    with nvmath.fft.FFT(a, axes=axes, options=options, execution=exec_backend.nvname) as fft:
        fft.plan()
        key_from_instance = fft.get_key()

    # Verify they match
    assert key_from_instance == key_from_static, (
        f"Keys do not match for cross-device strided operand.\nInstance key: {key_from_instance}\nStatic key: {key_from_static}"
    )


@pytest.mark.parametrize(
    ("framework", "exec_backend", "mem_backend", "shape1", "shape2", "axes"),
    [
        (framework, exec_backend, mem_backend, shape1, shape2, axes)
        for framework in Framework.enabled()
        for exec_backend in supported_backends.exec
        for mem_backend in supported_backends.framework_mem[framework]
        for shape1, shape2, axes in [
            # 1D FFT with rearranged batch dims
            ((2, 3, 64), (3, 2, 64), (2,)),
            ((4, 2, 32), (2, 4, 32), (2,)),
            # 2D FFT with rearranged batch dims
            ((2, 3, 16, 32), (3, 2, 16, 32), (2, 3)),
            ((5, 2, 8, 16), (2, 5, 8, 16), (2, 3)),
        ]
    ],
)
def test_rearranged_batch_dims_produce_same_key(framework, exec_backend, mem_backend, shape1, shape2, axes):
    """
    Verify that rearranging batch dimensions produces the same FFT key
    for both 1D and 2D FFTs.
    This is the premise for test_reset_operand_with_rearranged_batch_dims.

    For the 1D case with shape1=(2,3,64), shape2=(3,2,64), axes=(2,):

                            Operand 1           Operand 2
                            ---------           ---------
    shape                   (2, 3, 64)          (3, 2, 64)          <- different
    strides                 (192, 64, 1)        (128, 64, 1)        <- different

    FFT axis (2):
      stride                1                   1                   <- same
      size                  64                  64                  <- same

    Batch axes (0, 1):
      batch_size            2 x 3 = 6           3 x 2 = 6           <- same
      sorted batch strides  (64, 192)           (64, 128)           <- different

    cuFFT plan parameters, the full key includes all of these:
      istride               1                   1                   <- same
      idistance             64 (min batch str)  64 (min batch str)  <- same
      ostride               1                   1                   <- same
      odistance             64                  64                  <- same
      fft_batch_size        6                   6                   <- same
      embedding_shape       (64,)               (64,)               <- same
      fft_in/out_shape      (64,)               (64,)               <- same
      data types            all identical                           <- same

    cuFFT treats batches as a flat sequence with a single distance
    parameter; it does not see the multi-dimensional batch layout.
    Since all key components match, the key is the same.
    """
    dtype = DType.complex64
    operand1 = get_random_input_data(framework, shape1, dtype, mem_backend)
    operand2 = get_random_input_data(framework, shape2, dtype, mem_backend)

    key1 = nvmath.fft.FFT.create_key(operand1, axes=axes, execution=exec_backend.nvname)
    key2 = nvmath.fft.FFT.create_key(operand2, axes=axes, execution=exec_backend.nvname)
    assert key1 == key2, (
        f"Expected matching keys for rearranged batch dims.\n"
        f"  shape1={shape1}, shape2={shape2}, axes={axes}\n"
        f"  key1={key1}\n  key2={key2}"
    )


@pytest.mark.parametrize(
    ("shape", "transpose_axes", "fft_axes"),
    [
        # 1D FFT: transpose batch dims of a (3,2,64) source to get (2,3,64)
        # with non-contiguous strides
        ((3, 2, 64), (1, 0, 2), (2,)),
        # 2D FFT: transpose batch dims
        ((3, 2, 16, 32), (1, 0, 2, 3), (2, 3)),
    ],
)
def test_transposed_strides_produce_same_key(shape, transpose_axes, fft_axes):
    """
    Verify that a contiguous operand and a transposed view with the same
    shape but different strides produce the same FFT key.
    This is the premise for test_reset_operand_with_transposed_strides.

    For the 1D case with shape=(3,2,64), transpose_axes=(1,0,2),
    fft_axes=(2,):

                            Operand 1           Operand 2
                            ---------           ---------
    shape                   (2, 3, 64)          (2, 3, 64)          <- same
    strides                 (192, 64, 1)        (64, 128, 1)        <- different

    FFT axis (2):
      stride                1                   1                   <- same
      size                  64                  64                  <- same

    Batch axes (0, 1):
      batch_size            2 x 3 = 6           2 x 3 = 6           <- same
      sorted batch strides  (64, 192)           (64, 128)           <- different

    cuFFT plan parameters, the full key includes all of these:
      istride               1                   1                   <- same
      idistance             64 (min batch str)  64 (min batch str)  <- same
      ostride               1                   1                   <- same
      odistance             64 (min result      64 (min result      <- same
                              batch stride)       batch stride)
      fft_batch_size        6                   6                   <- same
      embedding_shape       (64,)               (64,)               <- same
      fft_in/out_shape      (64,)               (64,)               <- same
      data types            all identical                           <- same

    cuFFT treats batches as a flat sequence with a single distance
    parameter; it does not see the multi-dimensional batch layout.
    Since all key components match, the key should be the same.
    """
    operand1_shape = tuple(shape[a] for a in transpose_axes)

    dtype = np.complex64
    operand1 = np.random.rand(*operand1_shape).astype(dtype)
    operand2 = np.random.rand(*shape).astype(dtype).transpose(transpose_axes)

    assert operand1.shape == operand2.shape
    assert operand1.strides != operand2.strides

    key1 = nvmath.fft.FFT.create_key(operand1, axes=fft_axes, execution="cuda")
    key2 = nvmath.fft.FFT.create_key(operand2, axes=fft_axes, execution="cuda")
    assert key1 == key2, (
        f"Expected matching keys for same shape with different strides.\n"
        f"  shape={operand1.shape}\n"
        f"  operand1 strides={operand1.strides}, operand2 strides={operand2.strides}\n"
        f"  key1={key1}\n  key2={key2}"
    )


def _metadata_equivalence_cases(dtypes):
    """(framework, exec_backend, mem_backend, dtype) cases where the operand device
    matches the execution space, so operand- and metadata-derived keys must agree."""
    cases = []
    for framework in Framework.enabled():
        for exec_backend in supported_backends.exec:
            mem_backend = exec_backend.mem
            if mem_backend not in supported_backends.framework_mem[framework]:
                continue
            for dtype in dtypes:
                cases.append((framework, exec_backend, mem_backend, dtype))
    return cases


@pytest.mark.parametrize(
    ("framework", "exec_backend", "mem_backend", "dtype"),
    _metadata_equivalence_cases([DType.complex64, DType.float32]),
)
def test_create_key_metadata_matches_operand_contiguous(seeder, framework, exec_backend, mem_backend, dtype):
    """A key built from shape/dtype matches the one built from a contiguous operand."""
    shape = (8, 16)
    axes = (0, 1)
    a = get_random_input_data(framework, shape, dtype, mem_backend)
    k_array = nvmath.fft.FFT.create_key(a, axes=axes, execution=exec_backend.nvname)
    k_meta = nvmath.fft.FFT.create_key_from_metadata(
        shape, dtype.name, axes=axes, memory_space=mem_backend.name, execution=exec_backend.nvname
    )
    assert k_array == k_meta


@pytest.mark.parametrize(
    ("framework", "exec_backend", "mem_backend", "dtype"),
    _metadata_equivalence_cases([DType.complex64]),
)
def test_create_key_metadata_matches_operand_strided(seeder, framework, exec_backend, mem_backend, dtype):
    """A key built from shape/dtype/strides matches a non-contiguous operand's key."""
    batch, n = 4, 16
    base = get_random_input_data(framework, (2 * batch, n), dtype, mem_backend)
    # Strided in the batch dimension, contiguous in the (last) transformed axis.
    a = base[::2]
    elem_strides = tuple(tensor_wrapper.wrap_operand(a).strides)
    k_array = nvmath.fft.FFT.create_key(a, axes=(1,), execution=exec_backend.nvname)
    k_meta = nvmath.fft.FFT.create_key_from_metadata(
        tuple(a.shape),
        dtype.name,
        strides=elem_strides,
        axes=(1,),
        memory_space=mem_backend.name,
        execution=exec_backend.nvname,
    )
    assert k_array == k_meta


def test_create_key_operand_scalar_rejected():
    """A 0-D (scalar) operand is rejected by create_key.

    The guard fires before any backend initialization, so no CPU/CUDA FFT library is
    required.
    """
    a = np.array(1.0, dtype=np.complex64)  # 0-D operand
    with pytest.raises(ValueError, match="The FFT of a scalar is a no-op."):
        nvmath.fft.FFT.create_key(a, execution="cuda")


def test_create_key_from_metadata_validation_errors():
    """Invalid metadata arguments raise ValueError.

    These are all rejected before any backend initialization, so no CPU/CUDA FFT
    library is required.
    """
    # Invalid memory space.
    with pytest.raises(ValueError, match="'memory_space' must be 'cpu' or 'cuda'"):
        nvmath.fft.FFT.create_key_from_metadata((8,), "complex64", memory_space="gpu")

    # Scalar (0-D) shape is rejected, matching FFT.__init__.
    with pytest.raises(ValueError, match="identifies a scalar"):
        nvmath.fft.FFT.create_key_from_metadata((), "complex64", memory_space="cuda")

    # Unknown dtype name.
    with pytest.raises(ValueError, match="Unsupported or invalid 'dtype'"):
        nvmath.fft.FFT.create_key_from_metadata((8,), "not_a_dtype", memory_space="cuda")

    # Strides length must match shape length.
    with pytest.raises(ValueError, match="length of 'strides'"):
        nvmath.fft.FFT.create_key_from_metadata((8, 4), "complex64", strides=(1,), memory_space="cuda")
