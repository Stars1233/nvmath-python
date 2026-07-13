# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import glob
import os

import pytest
from nvmath_tests.device.helpers import skip_if_pipeline_unsupported

from nvmath._utils import get_nvrtc_version

from ..test_utils import DEVICE_COUNT, run_sample

samples_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "examples", "device")
sample_files = glob.glob(os.path.join(samples_path, "**", "cu*.py"), recursive=True)

if DEVICE_COUNT < 1:
    pytest.skip(allow_module_level=True, reason="Device examples require at least one CUDA device.")


# float16/bfloat16 examples that are known to be flaky with the
# numba-cuda-mlir compiler (e.g. a known LTO linking bug at the default
# optimization level that erases float16/bfloat16 stores and produces wrong
# results). When run with the numba-cuda-mlir variant, these are marked xfail
# so that a failure for any reason does not break the suite.
# BUG: https://github.com/NVIDIA/numba-cuda-mlir/pull/122
fp16_examples = {
    "cublasdx_simple_gemm_cfp16.py",
    "cublasdx_blockdim_gemm_fp16.py",
    "cublasdx_gemm_fft_fp16.py",
    "cublasdx_gemm_fusion.py",
    "cublasdx_single_gemm_performance.py",
    "cublasdx_single_gemm_tensor_performance.py",
    "cufftdx_simple_fft_block_r2c_fp16.py",
    "cufftdx_simple_fft_block_c2r_fp16.py",
    "cufftdx_simple_fft_block_half2.py",
    "cufftdx_simple_fft_thread_fp16.py",
}


@pytest.mark.parametrize("sample", sample_files)
class TestDeviceSamples:
    def test_sample(self, sample, request):
        ctk_version = get_nvrtc_version()
        filename = os.path.basename(sample)

        if filename == "cublasdx_fp64_emulation.py":
            # TODO: Uncomment once issue with LTO IR version resolved
            # spec = importlib.util.find_spec("cuda.cccl")
            # if spec is None:
            pytest.skip("Skipping test for cublasdx_fp64_emulation.py, requires cuda.cccl module")
        # TODO: figure out if the bug was fixed in 12.9 update
        if filename == "cublasdx_gemm_fft_fp16.py" and ctk_version < (13, 0, 0):
            pytest.skip("NVBug 5218000")

        # Skip pipeline tests for CTK < 13.0 and SM 100+ & CTK < 13.1
        if "pipeline" in filename:
            skip_if_pipeline_unsupported()

        if "cusolverdx" in filename and ctk_version < (12, 6, 85):
            pytest.skip(
                f"Skipping cuSolverDx test {filename}, requires "
                "CTK >= 12.6 Update 3 "
                f"(current: {ctk_version[0]}.{ctk_version[1]}.{ctk_version[2]})"
            )

        # The numba-cuda-mlir variant of the fp16 examples is known to be flaky
        # (e.g. a known LTO linking bug that erases float16/bfloat16 stores and
        # produces wrong results). Mark those as xfail so a failure for any
        # reason does not break the suite.
        is_mlir = "numba_cuda_mlir" in os.path.normpath(sample).split(os.sep)
        if is_mlir and filename in fp16_examples:
            request.node.add_marker(
                pytest.mark.xfail(
                    reason=f"fp16 example {filename} is flaky with the numba-cuda-mlir compiler",
                    strict=False,
                )
            )

        run_sample(samples_path, sample, {"__name__": "__main__"})
