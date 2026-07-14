# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

__all__ = ["calculate_symmetric_size"]

import numpy as np

from nvmath.distributed.process_group import ReductionOp


def calculate_symmetric_size(size, process_group, make_symmetric, skip_symmetric_check, logger):
    if make_symmetric and skip_symmetric_check:
        raise ValueError("skip_symmetric_check is incompatible with make_symmetric=True")

    if not skip_symmetric_check:
        max_size = np.array([-size, size], dtype=np.int64)
        process_group.allreduce_buffer(max_size, op=ReductionOp.MAX)
        if -max_size[0] != max_size[1]:
            # The buffer size is not the same on all processes.
            if make_symmetric:
                logger.info(
                    "Symmetric memory allocator: the buffer will be padded on some processes to "
                    f"satisfy symmetric requirement (make_symmetric=True), size={size} max_size={max_size[1]}."
                )
            else:
                raise ValueError(
                    "The buffer size for symmetric memory allocation is not the same on all processes. "
                    "Consider using make_symmetric=True if you have uneven data distribution."
                )
        else:
            logger.info(f"Symmetric memory allocator: the requested buffer size ({size}) is the same on all processes.")
        # Sizes are equal or make_symmetric=True.
        size = max_size[1]
    return size
