# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from .common import *  # noqa: F403
from .common_cuda import *  # noqa: F403
from .cublasdx import *  # noqa: F403
from .cublasdx_backend import *  # noqa: F403
from .cufftdx import *  # noqa: F403
from .cusolverdx import *  # noqa: F403
from .types import *  # noqa: F403

# isort: split

# register models in compilers; must occur after imports above
from .common import _HAS_NUMBA, _HAS_NUMBA_CUDA_MLIR

if _HAS_NUMBA:
    from . import (
        cublasdx_numba,  # noqa: F401
        cufftdx_numba,  # noqa: F401
        cusolverdx_numba,  # noqa: F401
    )
    from .vector_types_numba import *  # noqa: F403

if _HAS_NUMBA_CUDA_MLIR:
    from numba_cuda_mlir.extending import refresh_registries

    from . import (
        common_numba_cuda_mlir,  # noqa: F401
        cublasdx_numba_cuda_mlir,  # noqa: F401
        cufftdx_numba_cuda_mlir,  # noqa: F401
        cusolverdx_numba_cuda_mlir,  # noqa: F401
    )

    # Required for scenario when we compile some kernel
    # and afterwards we import the device APIs
    refresh_registries(include_uninitialized_cuda=False)
