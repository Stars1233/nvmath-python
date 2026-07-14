# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to Torch operations.
"""

__all__ = ["TorchPackage"]

import torch

from .package_ifc import Package

_TORCH_VERSION = tuple(int(p) for p in torch.__version__.split(".")[:2])

# Goal: return the raw ``cudaStream_t`` int for the current stream on a
# given device. ``torch.cuda.current_stream(device=...).cuda_stream``
# does this but allocates a fresh ``torch.cuda.Stream`` Python wrapper
# just to read one ``int`` off it. As an alternative, torch's C
# bindings expose ``torch._C._cuda_getCurrentRawStream``, which returns
# the raw int directly. Being a private symbol it is not guaranteed
# on every torch build, so we guard with ``hasattr`` and fall back
# to the other path when absent.
# This is resolved once at import time, not per call.
if hasattr(torch._C, "_cuda_getCurrentRawStream"):
    _get_current_stream_ptr = torch._C._cuda_getCurrentRawStream
else:
    # Parameter is named ``device_id`` to match ``Package.get_current_stream_ptr``;
    # the ``# type: ignore[misc]`` silences mypy's redefinition warning, since
    # torch's typed signature for ``_cuda_getCurrentRawStream`` calls the
    # argument ``device`` rather than ``device_id``. The runtime call is
    # positional, so the name disagreement is purely a typing artifact.
    def _get_current_stream_ptr(device_id: int) -> int:  # type: ignore[misc]
        return torch.cuda.current_stream(device=device_id).cuda_stream


class TorchPackage(Package[torch.cuda.Stream]):
    @staticmethod
    def get_current_stream(device_id: int) -> torch.cuda.Stream:
        return torch.cuda.current_stream(device=device_id)

    @staticmethod
    def to_stream_pointer(stream: torch.cuda.Stream) -> int:
        return stream.cuda_stream

    # Same ``device`` vs ``device_id`` parameter-name disagreement as above:
    # torch's typed signature uses ``device``, but ``Package`` declares
    # ``device_id``. Runtime calls are positional, so this is type-only noise.
    get_current_stream_ptr = staticmethod(_get_current_stream_ptr)  # type: ignore[assignment]

    @staticmethod
    def to_stream_context(stream: torch.cuda.Stream) -> torch.cuda.StreamContext:
        return torch.cuda.stream(stream)

    @staticmethod
    def create_external_stream(device_id: int, stream_ptr: int) -> torch.cuda.Stream:
        # Issue: ``torch.cuda.ExternalStream(0, ...)`` does not wrap handle
        # ``0x0`` (= the device default stream). Its C++ ctor treats
        # ``stream_ptr == 0`` as "no ptr supplied" and silently returns a
        # fresh pooled stream instead.
        #
        # Use ``torch.cuda.get_stream_from_external`` (first shipped in
        # torch 2.7), which routes through a different C++ path and faithfully
        # wraps any handle, including ``0x0``. On older torch we leave the
        # pre-existing buggy behavior in place.
        if _TORCH_VERSION >= (2, 7):
            return torch.cuda.get_stream_from_external(stream_ptr, device=device_id)
        return torch.cuda.ExternalStream(stream_ptr, device=device_id)
