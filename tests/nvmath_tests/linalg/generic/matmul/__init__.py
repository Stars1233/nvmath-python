# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

try:
    from nvmath.linalg._internal.utils import get_handle

    get_handle(0, binding="cublas")
    del get_handle
    CUBLAS_AVAILABLE = True
except:
    CUBLAS_AVAILABLE = False

# cublas{S,D}gemmGroupedBatched (used by the explicitly-batched matmul dispatch)
# were added in cuBLAS 12.4. On older cuBLAS, executing an
# explicit-batch matmul raises FunctionNotFoundError at execute() time, so we
# expose this flag for tests that exercise that code path.
# https://docs.nvidia.com/cuda/archive/12.4.0/cuda-toolkit-release-notes/index.html
if CUBLAS_AVAILABLE:
    try:
        from nvmath.bindings import cublasLt as _cublasLt

        CUBLAS_GROUPED_BATCHED_AVAILABLE = _cublasLt.get_version() >= 120400
        del _cublasLt
    except Exception:
        CUBLAS_GROUPED_BATCHED_AVAILABLE = False
else:
    CUBLAS_GROUPED_BATCHED_AVAILABLE = False

try:
    from nvmath.bindings._internal.utils import FunctionNotFoundError
    from nvmath.bindings.nvpl.blas import get_version

    get_version()
    del get_version
    NVPL_AVAILABLE = True
except FunctionNotFoundError as e:
    if "function nvpl_blas_get_version is not found" not in str(e):
        raise e
    # An NVPL alternative was loaded which doesn't implement nvpl_blas_get_version
    NVPL_AVAILABLE = True
except RuntimeError as e:
    if "Failed to dlopen all of the following libraries" not in str(e):
        raise e
    # Neither NVPL or an alternative was loaded
    NVPL_AVAILABLE = False
