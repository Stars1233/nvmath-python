# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

__all__ = [
    "nccl_empty_dlpack",
    "NcclNDBufferAllocator",
]

import logging
from typing import TYPE_CHECKING

from .symmetric_memory import calculate_symmetric_size

if TYPE_CHECKING:
    from cuda.core import Buffer, Stream

    from nvmath.distributed import DistributedContext
    from nvmath.distributed.process_group import ProcessGroup


def nccl_empty_dlpack(
    size: int,
    device_id: int,
    process_group: ProcessGroup,
    make_symmetric: bool = False,
    skip_symmetric_check: bool = False,
    logger: logging.Logger | None = None,
) -> Buffer:
    """
    Allocates a buffer with nccl4py. This function can be used to prepare a buffer
    for symmetric memory registration, but **doesn't register the buffer as symmetric
    memory** (because buffer registrations in NCCL are not global but on a
    per-communicator basis, so for registration the buffer typically has to be passed
    to the library that owns the communicator).

    This is a collective call when ``make_symmetric=True`` or
    ``skip_symmetric_check=False``.

    Args:
        size: Number of bytes to allocate.

        device_id: Device on which to allocate.

        process_group: nvmath.distributed process group.

        make_symmetric: If the buffer is going to be registered with NCCL symmetric memory,
            use ``make_symmetric=True`` to allocate the same size on every process (padding
            the buffer to the maximum size given by all processes).

        skip_symmetric_check: True if buffer is not needed for NCCL symmetric memory or
            already known to be of the same size on every process.
    """

    logger = logger if logger is not None else logging.getLogger()

    size = calculate_symmetric_size(size, process_group, make_symmetric, skip_symmetric_check, logger)

    import nccl.core as nccl  # type: ignore

    mem_buffer = nccl.buffer.mem_alloc(size, device_id)
    return mem_buffer


class NcclNDBufferAllocator:
    __slots__ = ("ctx", "make_symmetric", "skip_symmetric_check")

    def __init__(self, device_id: int, ctx: DistributedContext, make_symmetric: bool, skip_symmetric_check: bool):
        assert ctx.device_id == device_id, (
            "Internal error: attempting to allocate symmetric memory on a device not used by NCCL on this process"
        )
        self.ctx = ctx
        self.make_symmetric = make_symmetric
        self.skip_symmetric_check = skip_symmetric_check

    def allocate(self, size: int, stream: Stream, logger: logging.Logger | None = None) -> Buffer:
        return nccl_empty_dlpack(
            size,
            self.ctx.device_id,
            self.ctx.process_group,
            make_symmetric=self.make_symmetric,
            skip_symmetric_check=self.skip_symmetric_check,
            logger=logger,
        )
