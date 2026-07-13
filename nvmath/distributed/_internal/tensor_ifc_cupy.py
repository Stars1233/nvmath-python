# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to seamlessly use distributed Cupy ndarray objects.
"""

from __future__ import annotations  # allows typehint of class methods to return the self class

__all__ = ["CupyDistributedTensor", "HostDistributedTensor"]


try:
    import cupy
except ImportError:
    cupy = None


from nvmath.internal.ndbuffer import NDBuffer
from nvmath.internal.tensor_ifc_cupy import CupyTensor, HostTensor

from .tensor_ifc import DistributedTensor
from .tensor_ifc_host_device import CudaDistributedTensorMixIn, HostDistributedTensorMixIn


class HostDistributedTensor(HostDistributedTensorMixIn, HostTensor, DistributedTensor):
    host_tensor_class: type[HostDistributedTensor]  # set at the end of the file
    device_tensor_class: type[CupyDistributedTensor]  # set at the end of the file


# Most methods aren't redefined, because they simply act on the local array
class CupyDistributedTensor(CudaDistributedTensorMixIn, CupyTensor, DistributedTensor):
    """
    Tensor wrapper for distributed cupy ndarrays.
    """

    host_tensor_class: type[HostDistributedTensor]  # set at the end of the file
    device_tensor_class: type[CupyDistributedTensor]  # set at the end of the file

    @classmethod
    def wrap_ndbuffer(cls, ndbuffer: NDBuffer) -> CupyDistributedTensor:
        """
        Wraps NDBuffer into a cupy.ndarray, the method assumes the
        NDBuffer is backed by CUDA device memory.
        """
        base_ptr, size_in_bytes, offset_in_bytes = ndbuffer.raw_memory_range_info
        mem = cupy.cuda.UnownedMemory(
            base_ptr,
            size_in_bytes,
            owner=ndbuffer.data,
            device_id=ndbuffer.device_id,
        )
        memptr = cupy.cuda.MemoryPointer(mem, offset=offset_in_bytes)
        dtype = cls.name_to_dtype[ndbuffer.dtype_name]
        tensor = cupy.ndarray(
            ndbuffer.shape,
            dtype=dtype,
            strides=ndbuffer.strides_in_bytes,
            memptr=memptr,
        )
        return cls(tensor)


HostDistributedTensor.host_tensor_class = HostDistributedTensor
CupyDistributedTensor.host_tensor_class = HostDistributedTensor
HostDistributedTensor.device_tensor_class = CupyDistributedTensor
CupyDistributedTensor.device_tensor_class = CupyDistributedTensor
