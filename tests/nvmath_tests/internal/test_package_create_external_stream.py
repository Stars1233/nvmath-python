# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Test the contract of :meth:`Package.create_external_stream` for
each concrete package.
"""

import pytest


def _torch_lt_2_7():
    import torch

    return tuple(int(p) for p in torch.__version__.split(".")[:2]) < (2, 7)


def _cupy_lt_14():
    import cupy

    return int(cupy.__version__.split(".")[0]) < 14


@pytest.fixture(params=["torch", "cupy"])
def pkg(request):
    name = request.param
    module = pytest.importorskip(name)

    if name == "torch":
        if not module.cuda.is_available():
            pytest.skip("torch CUDA not available")
        from nvmath.internal.package_ifc_torch import TorchPackage

        return TorchPackage, module

    if name == "cupy":
        try:
            module.cuda.runtime.getDeviceCount()
        except Exception:
            pytest.skip("cupy CUDA not available")
        from nvmath.internal.package_ifc_cupy import CupyPackage

        return CupyPackage, module

    raise AssertionError(f"unhandled package {name!r}")


DEVICE_ID = 0


@pytest.mark.parametrize(
    "handle",
    [
        pytest.param(0x0, id="null-stream"),
        pytest.param(0x2, id="per-thread-default"),
    ],
)
def test_create_external_stream_sentinel_handle(pkg, handle):
    # CUDA defines sentinel ``cudaStream_t`` handles whose semantics are
    # resolved by the runtime on the fly:
    #   * ``0x0`` -- NULL stream / device default
    #     https://docs.nvidia.com/cuda/cuda-runtime-api/stream-sync-behavior.html
    #   * ``0x2`` -- ``cudaStreamPerThread``, defined as ``((cudaStream_t)0x2)``
    #     https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__TYPES.html
    # Wrapping either must return a wrapper whose underlying handle matches.
    pkg_cls, _ = pkg
    if pkg_cls.__name__ == "TorchPackage" and handle == 0 and _torch_lt_2_7():
        pytest.skip("torch < 2.7: ExternalStream(0) is broken; fixed upstream by get_stream_from_external in 2.7")
    stream = pkg_cls.create_external_stream(DEVICE_ID, handle)
    assert pkg_cls.to_stream_pointer(stream) == handle


def test_create_external_stream_real_handle(pkg):
    pkg_cls, module = pkg
    real = module.cuda.Stream(device=DEVICE_ID) if pkg_cls.__name__ == "TorchPackage" else module.cuda.Stream()
    real_handle = pkg_cls.to_stream_pointer(real)
    wrapped = pkg_cls.create_external_stream(DEVICE_ID, real_handle)
    assert pkg_cls.to_stream_pointer(wrapped) == real_handle


def test_create_external_stream_current_stream_round_trip(pkg):
    # Ask the framework for the current stream, extract its handle,
    # feed that handle into ``create_external_stream``, and verify the
    # resulting wrapper points at the same handle.
    pkg_cls, module = pkg
    if pkg_cls.__name__ == "TorchPackage":
        current = module.cuda.current_stream(device=DEVICE_ID)
    else:  # cupy: get_current_stream() honors the active device context
        with module.cuda.Device(DEVICE_ID):
            current = module.cuda.get_current_stream()
    handle = pkg_cls.to_stream_pointer(current)
    if pkg_cls.__name__ == "TorchPackage" and handle == 0 and _torch_lt_2_7():
        pytest.skip("torch < 2.7: ExternalStream(0) is broken; fixed upstream by get_stream_from_external in 2.7")
    wrapped = pkg_cls.create_external_stream(DEVICE_ID, handle)
    assert pkg_cls.to_stream_pointer(wrapped) == handle


def test_create_external_stream_returns_stream_subclass(pkg):
    pkg_cls, module = pkg
    if pkg_cls.__name__ == "CupyPackage" and _cupy_lt_14():
        # CuPy >= 14: CupyPackage.create_external_stream uses
        #   cp.cuda.Stream.from_external(), which constructs and returns a
        #   real Stream, so isinstance(stream, Stream) below holds.
        # CuPy <  14: from_external() does not exist yet, so we fall back to
        #   cp.cuda.ExternalStream(ptr). In cupy/cuda/stream.pyx, Stream and
        #   ExternalStream are not related by inheritance,
        #   so the isinstance check cannot hold.
        pytest.skip("cupy < 14: ExternalStream is not a subclass of Stream")
    stream = pkg_cls.create_external_stream(DEVICE_ID, 0)
    assert isinstance(stream, module.cuda.Stream)
