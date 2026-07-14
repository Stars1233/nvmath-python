# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Interface to seamlessly use distributed Numpy ndarray objects.
"""

from __future__ import annotations  # allows typehint of class methods to return the self class

__all__ = ["NumpyDistributedTensor", "CudaDistributedTensor"]

from nvmath.internal.ndbuffer import NDBuffer
from nvmath.internal.tensor_ifc_numpy import CudaTensor, NumpyTensor

from .tensor_ifc import DistributedTensor
from .tensor_ifc_host_device import CudaDistributedTensorMixIn, HostDistributedTensorMixIn


class CudaDistributedTensor(CudaDistributedTensorMixIn, CudaTensor, DistributedTensor):
    """
    Tensor wrapper for distributed cuda ndarrays.
    """

    host_tensor_class: type[NumpyDistributedTensor]  # set at the end of the file
    device_tensor_class: type[CudaDistributedTensor]  # set at the end of the file

    @classmethod
    def wrap_ndbuffer(cls, ndbuffer: NDBuffer) -> CudaDistributedTensor:
        return cls(ndbuffer)


# Most methods aren't redefined, because they simply act on the local array
class NumpyDistributedTensor(HostDistributedTensorMixIn, NumpyTensor, DistributedTensor):
    """
    Tensor wrapper for distributed numpy ndarrays.
    """

    host_tensor_class: type[NumpyDistributedTensor]  # set at the end of the file
    device_tensor_class: type[CudaDistributedTensor]  # set at the end of the file


NumpyDistributedTensor.host_tensor_class = NumpyDistributedTensor
CudaDistributedTensor.host_tensor_class = NumpyDistributedTensor
NumpyDistributedTensor.device_tensor_class = CudaDistributedTensor
CudaDistributedTensor.device_tensor_class = CudaDistributedTensor
