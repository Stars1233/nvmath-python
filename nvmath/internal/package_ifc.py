# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
An abstract interface to certain package-provided operations.

Even though cuda.core does not have the concept of a "current stream" or a "stream context",
we promise to honor third-party CUDA stream contexts if they match the input operand's
package. The interface class defined in this module wraps around those stream concepts to
make them uniform.

The strategy is to use cuda.core everywhere internally except for context managers which
will need to wrap back around to the external implementation.
"""

__all__ = ["Package", "StreamHolder"]

from abc import ABC, abstractmethod
from collections.abc import Hashable
from contextlib import AbstractContextManager
from dataclasses import dataclass
from typing import Generic, Protocol, TypeVar

from cuda.core import Stream

from ._device_utils import get_device


class AnyStream(Hashable, Protocol):
    """Any supported Stream object such as a Stream from cuda.core, CuPy, or PyTorch."""

    # This empty protocol class is just a placeholder to make type checking more helpful.
    # Since the class is empty, it doesn't assume anything is true about the implementation
    # classes.
    pass


"""
A generic type for the third-party Stream which a given Package implementation wraps
around.
"""
S = TypeVar("S")


# CUDA stream protocol version, see
# https://nvidia.github.io/cuda-python/cuda-core/latest/interoperability.html#cuda-stream-protocol
_CUDA_STREAM_PROTOCOL_VERSION = 0


class _cuda_core_stream_holder(Generic[S]):
    """
    Expose a raw ``cudaStream_t`` handle through the CUDA stream protocol.

    This adapter can be passed to consumers that accept the protocol, such as
    ``cuda.core.Device.create_stream`` or ``cp.cuda.Stream.from_external``.

    Args:
        handle: The raw ``cudaStream_t`` value to expose.
        external: Optional object that owns or keeps ``handle`` alive. The
            holder stores a strong reference to this object but does not
            otherwise use it. Pass ``None`` when the consumer only reads the
            protocol immediately, or when the stream lifetime is guaranteed
            elsewhere.
    """

    __slots__ = ("external", "handle")

    def __init__(self, handle: int, external: S | None = None):
        self.handle = handle
        self.external = external

    def __cuda_stream__(self):
        return (_CUDA_STREAM_PROTOCOL_VERSION, self.handle)


class Package(ABC, Generic[S]):
    @staticmethod
    @abstractmethod
    def get_current_stream(device_id: int) -> S:
        """
        Obtain the current stream on the device.

        Args:
            device_id: The id (ordinal) of the device.
        """
        raise NotImplementedError

    @staticmethod
    @abstractmethod
    def to_stream_pointer(stream: S) -> int:
        """
        Obtain the stream pointer.

        Args:
            stream: The stream object.
        """
        raise NotImplementedError

    @staticmethod
    @abstractmethod
    def get_current_stream_ptr(device_id: int) -> int:
        """
        Return the raw ``cudaStream_t`` int for the current stream on ``device_id``.

        Args:
            device_id: The id (ordinal) of the device.
        """
        raise NotImplementedError

    @staticmethod
    @abstractmethod
    def to_stream_context(stream: S) -> AbstractContextManager[S]:
        """
        Create a context manager from the stream.

        Args:
            stream: The stream object.
        """
        raise NotImplementedError

    @staticmethod
    @abstractmethod
    def create_external_stream(device_id: int, stream_ptr: int) -> S:
        """
        Wrap a stream pointer into an external stream object.

        Args:
            device_id: The id (ordinal) of the device.
            stream: The stream pointer (int) to be wrapped.
        """
        raise NotImplementedError

    @classmethod
    def create_stream(cls, external: S, device_id: int) -> Stream:
        """
        Wrap an external Stream object into a cuda.core.Stream.

        Args:
            external: The external Stream object.
        """
        # use get_device to ensure the initial set_current is called
        device = get_device(device_id)
        # the stream holder ensures we tie the external reference to the
        # cuda.core stream object, extending its lifetime.
        holder = _cuda_core_stream_holder(cls.to_stream_pointer(external), external)
        return device.create_stream(holder)


@dataclass
class StreamHolder(Generic[S]):
    """A data class for easing CUDA stream manipulation.

    Attributes:
        ctx: A context manager for using the specified stream.
        device_id (int): The device ID where the encapsulated stream locates.
        external: A foreign object that holds the stream alive.
        obj: The cuda.core Stream object wrapping external.
        package (str): The name of the package to which the external stream belongs.
        ptr (int): The address of the underlying ``cudaStream_t`` object.
    """

    ctx: AbstractContextManager[S]
    device_id: int
    external: S
    obj: Stream
    package: str
    ptr: int
