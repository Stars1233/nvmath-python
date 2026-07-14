# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Test the contract of :meth:`Package.get_current_stream_ptr` for each
concrete package.
"""

import pytest

DEVICE_ID = 0


def test_get_current_stream_ptr_inside_stream_context_cupy():
    # outside a stream context the ptr matches cupy's current-stream
    # inside a fresh ``Stream()`` context it tracks the new stream;
    # after the context exits it restores to the prior ptr.
    cupy = pytest.importorskip("cupy")
    from nvmath.internal.package_ifc_cupy import CupyPackage

    initial = CupyPackage.get_current_stream_ptr(DEVICE_ID)
    # cupy < 13 doesn't accept a device_id argument on get_current_stream,
    # so set the device explicitly to match what CupyPackage does internally.
    with cupy.cuda.Device(DEVICE_ID):
        assert initial == cupy.cuda.get_current_stream().ptr
        with cupy.cuda.Stream(non_blocking=True) as new_stream:
            assert CupyPackage.get_current_stream_ptr(DEVICE_ID) == new_stream.ptr

    assert CupyPackage.get_current_stream_ptr(DEVICE_ID) == initial


def test_get_current_stream_ptr_inside_stream_context_torch():
    # outside a stream context the ptr matches torch's current-stream
    # inside a fresh ``Stream`` context it tracks the new stream;
    # after the context exits it restores to the prior ptr.
    torch = pytest.importorskip("torch")
    from nvmath.internal.package_ifc_torch import TorchPackage

    initial = TorchPackage.get_current_stream_ptr(DEVICE_ID)
    assert initial == torch.cuda.current_stream(device=DEVICE_ID).cuda_stream

    new_stream = torch.cuda.Stream(device=DEVICE_ID)
    with torch.cuda.stream(new_stream):
        assert TorchPackage.get_current_stream_ptr(DEVICE_ID) == new_stream.cuda_stream

    assert TorchPackage.get_current_stream_ptr(DEVICE_ID) == initial


# Set a stream wrapping a known ``cudaStream_t`` sentinel as the current
# stream and verify the under-test getter returns the same sentinel:
#   * ``0x0`` -- NULL stream / device default
#     https://docs.nvidia.com/cuda/cuda-runtime-api/stream-sync-behavior.html
#   * ``0x2`` -- ``cudaStreamPerThread``, defined as ``((cudaStream_t)0x2)``
#     https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html
_SENTINEL_PTRS = [
    pytest.param(0x0, id="null-stream"),
    pytest.param(0x2, id="per-thread-default"),
]


@pytest.mark.parametrize("ptr", _SENTINEL_PTRS)
def test_get_current_stream_ptr_returns_set_sentinel_cupy(ptr):
    cupy = pytest.importorskip("cupy")
    from nvmath.internal.package_ifc_cupy import CupyPackage

    stream = CupyPackage.create_external_stream(DEVICE_ID, ptr)
    # cupy: stream context lives on the active device
    with cupy.cuda.Device(DEVICE_ID), stream:
        assert CupyPackage.get_current_stream_ptr(DEVICE_ID) == ptr


@pytest.mark.parametrize("ptr", _SENTINEL_PTRS)
def test_get_current_stream_ptr_returns_set_sentinel_torch(ptr):
    torch = pytest.importorskip("torch")
    torch_lt_2_7 = tuple(int(p) for p in torch.__version__.split(".")[:2]) < (2, 7)
    if ptr == 0 and torch_lt_2_7:
        pytest.skip("torch < 2.7: ExternalStream(0) is broken; fixed upstream by get_stream_from_external in 2.7")
    from nvmath.internal.package_ifc_torch import TorchPackage

    stream = TorchPackage.create_external_stream(DEVICE_ID, ptr)
    with torch.cuda.stream(stream):
        assert TorchPackage.get_current_stream_ptr(DEVICE_ID) == ptr


def test_get_current_stream_ptr_cuda_returns_device_default():
    # cuda.core has no thread-local "current stream" notion: every
    # caller sees the device's default stream, whose ptr is a CUDA
    # driver sentinel (``CU_STREAM_LEGACY = 0x1`` or
    # ``CU_STREAM_PER_THREAD = 0x2``) that's constant for the life of
    # the process.
    #
    # Mirror the import ``package_ifc_cuda`` does internally.
    from cuda.core import Device

    from nvmath.internal.package_ifc_cuda import CUDAPackage

    device = Device(DEVICE_ID)
    # cuda.core 0.5.0 requires ``set_current()`` before ``.default_stream``
    # is accessible; ``CUDAPackage`` does this via ``get_device``. Mirror
    # it here so the test doesn't depend on incidental init order.
    device.set_current()
    truth = int(device.default_stream.handle)
    assert CUDAPackage.get_current_stream_ptr(DEVICE_ID) == truth
