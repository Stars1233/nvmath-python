# Copyright (c) 2024-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0
import logging
import typing

import numpy as np
import pytest
from hypothesis import HealthCheck, assume, given, reproduce_failure, settings  # noqa: F401
from hypothesis.strategies import (
    booleans,
    composite,
    floats,
    lists,
    none,
    one_of,
    sampled_from,
)

from nvmath.internal.tensor_wrapper import maybe_register_package
from nvmath.linalg.generic import (
    ExecutionCPU,
    ExecutionCUDA,
    GeneralMatrixQualifier,
    matmul,
    matrix_qualifiers_dtype,
)

from . import CUBLAS_GROUPED_BATCHED_AVAILABLE, NVPL_AVAILABLE
from .hypothesis_blocks import explicitly_batched_matmul_matrices
from .test_matmul_with_hypothesis import verify_result

# Setup available tensor libraries
AVAILABLE_TENSOR_LIBRARIES: list[str] = ["numpy"]

try:
    import cupy as cp

    maybe_register_package("cupy")
    AVAILABLE_TENSOR_LIBRARIES.append("cupy")
except ModuleNotFoundError:
    cp = None

try:
    import torch

    maybe_register_package("torch")
    AVAILABLE_TENSOR_LIBRARIES.append("torch-cpu")
    AVAILABLE_TENSOR_LIBRARIES.append("torch-gpu")
except ImportError:
    torch = None

ab_type_values = [
    np.float32,
    np.float64,
]


def to_numpy(t):
    """Convert a tensor of any supported framework to a numpy array."""
    if isinstance(t, np.ndarray):
        return t
    if cp is not None and isinstance(t, cp.ndarray):
        return cp.asnumpy(t)
    # Assume torch tensor
    return t.cpu().detach().numpy()


@composite
def explicitly_batched_matmul_inputs(draw):
    a, b, c = draw(
        explicitly_batched_matmul_matrices(
            implicit={
                "axis_order_strategy": sampled_from(
                    [
                        (1, 0),
                        (0, 1),
                    ]
                ),
                "dtype": draw(sampled_from(ab_type_values)),
                "min_batch": 0,
                "max_batch": 2,
                "with_broadcasting": False,
            },
            min_batch=1,
            max_batch=3,
            framework_strategy=sampled_from(AVAILABLE_TENSOR_LIBRARIES),
        )
    )
    qualifiers = []
    for _ in range(len(c)):
        q = np.full(
            3,
            fill_value=GeneralMatrixQualifier.create(),
            dtype=matrix_qualifiers_dtype,
        )
        q[0]["conjugate"] = draw(booleans())
        q[1]["conjugate"] = draw(booleans())
        qualifiers.append(q)
    element_properties: dict[str, typing.Any] = {
        "allow_infinity": False,
        "allow_nan": False,
        "allow_subnormal": False,
        "max_value": 5,
        "min_value": 0,
    }
    num_batch = max(len(a), len(b), len(c))
    alpha = draw(
        one_of(
            none(),
            floats(**element_properties),
            lists(floats(**element_properties), min_size=num_batch, max_size=num_batch),
        )
    )
    beta = draw(
        one_of(
            none() if c is None else floats(**element_properties),
            floats(**element_properties),
            lists(floats(**element_properties), min_size=num_batch, max_size=num_batch),
        )
    )
    return a, b, c, qualifiers, alpha, beta


# None is intentionally excluded: it would require host-side BLAS, but not all
# test envs ship those deps.
AVAILABLE_EXECUTIONS = [
    *((ExecutionCUDA(),) if CUBLAS_GROUPED_BATCHED_AVAILABLE else ()),
    *((ExecutionCPU(),) if NVPL_AVAILABLE else ()),
]


@pytest.mark.skipif(
    not AVAILABLE_EXECUTIONS,
    reason="Explicit-batch matmul requires cuBLAS >= 12.4 (for ExecutionCUDA) or NVPL (for ExecutionCPU).",
)
@settings(suppress_health_check=[HealthCheck.data_too_large])
@given(
    input_arrays=explicitly_batched_matmul_inputs(),
    options=one_of(none()),
    execution=sampled_from(AVAILABLE_EXECUTIONS),
)
def test_explicit_batch_matmul(input_arrays, options, execution):
    """Test explicitly batched matmul with sequences of tensors."""
    a_list, b_list, c_list, qualifiers_list, alpha_list, beta_list = input_arrays

    try:
        result_list = matmul(
            a_list,
            b_list,
            c=c_list,
            alpha=alpha_list,
            beta=beta_list,
            execution=execution,
            options=options,
            qualifiers=qualifiers_list,
        )

        assert isinstance(result_list, list), "Result should be a sequence for explicit batching"
        assert len(result_list) == len(a_list), f"Expected {len(a_list)} results, got {len(result_list)}"

        for i, (a, b, c, result, qualifiers) in enumerate(
            zip(a_list, b_list, c_list, result_list, qualifiers_list, strict=True)
        ):
            alpha = alpha_list[i] if isinstance(alpha_list, list) else alpha_list
            beta = beta_list[i] if isinstance(beta_list, list) else beta_list
            logging.debug("Verifying explicit batch %d ...", i)
            verify_result(to_numpy(a), to_numpy(b), to_numpy(c), to_numpy(result), alpha, beta, qualifiers)

    except ValueError as error:
        if "No BLAS compatible view" in str(error):
            logging.warning("Hypothesis ignored the following error: %s", error)
            return
        raise error
    except NotImplementedError as error:
        logging.warning("Hypothesis ignored NotImplementedError: %s", error)
        return
