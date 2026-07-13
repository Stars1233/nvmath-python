# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to seamlessly use sparse tensors from different libraries.
"""

from __future__ import annotations  # allows typehint of class methods to return the self class

__all__ = ["SparseTensorHolder"]


from abc import ABC, abstractmethod
from typing import Literal

from nvmath.internal.package_ifc import StreamHolder


class SparseTensorHolder(ABC):
    """
    A simple base type for attributes common to *all* sparse formats.
    """

    @classmethod
    @abstractmethod
    def create_from_tensor(cls, tensor, attr_name_map):
        raise NotImplementedError

    @property
    @abstractmethod
    def attr_name_map(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def device(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def device_id(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def dtype(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def index_type(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def format_name(self) -> str:
        raise NotImplementedError

    @property
    @abstractmethod
    def num_dimensions(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def shape(self):
        raise NotImplementedError

    @property
    @abstractmethod
    def values(self):
        raise NotImplementedError

    @property
    def dense_tensorholder_type(self):
        """The tensor holder type for the dense constituent tensors."""
        return self._dense_tensorholder_type

    @abstractmethod
    def to(self, device_id: int | Literal["cpu"], stream_holder: StreamHolder | None):
        """Copy the SparseTensor representation to a different device.

        No copy is performed if the SparseTensor is already on the requested device.
        """
        # This path is suitable only if `self.tensor` is a ust.Tensor instance.
        # (Note, this can be the case for any known, named format holders, because
        # user can wrap external sparse tensor into ust.Tensor that is then
        # wrapped into SparseTensorHolder).
        # Here, we ensure that the resulting copy also has a proper .tensor : ust.Tensor
        # instance not just dense constituent tensors (extracted via attr_name_map)
        # from the original tensor. Matmulmod impl relies on .tensor to be present
        # for ust operands.
        # If self.tensor may not be a ust.Tensor instance, the subclass is responsible
        # for overriding this method to provide specialized implementation.
        tensor = self.tensor  # type: ignore[attr-defined]
        tensor = tensor._to(device_id=device_id, stream_holder=stream_holder)
        return self.create_from_tensor(tensor, attr_name_map=self.attr_name_map)

    @abstractmethod
    def copy_(self, src: SparseTensorHolder, stream_holder: StreamHolder | None) -> None:
        """Overwrite the sparse tensor (in-place) with a copy of src."""
        raise NotImplementedError

    @abstractmethod
    def to_ust(self, *, stream):
        """Create an UST from the named representation. This is a zero-copy operation."""
        raise NotImplementedError

    @abstractmethod
    def to_package(self):
        """
        This will create a sparse tensor for the original package from which this
        interface was created.
        """
        raise NotImplementedError

    @abstractmethod
    def release(self):
        """
        This method will release the wrapped tensor and any format-specific data
        by setting them to None.
        """
        raise NotImplementedError

    @abstractmethod
    def reset_unchecked(self, tensor):
        """
        This method will reset the wrapped tensor to the specified one, and update
        any format-specific data accordingly. It assumes that all attributes
        like the device, shape, etc are consistent between the existing and new tensor.
        """
        raise NotImplementedError
