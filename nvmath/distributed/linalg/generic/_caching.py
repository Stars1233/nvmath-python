# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Cache for cuSOLVERMp lifecycle resources.

``_HANDLES`` -- cuSOLVERMp library handles, keyed on ``device_id`` -- is
subject to the "one process per device" cuSOLVERMp model (single host thread
per device, so no locking or thread-local state is needed). The handle lazily
splits NCCL sub-communicators off the parent communicator on the first
``cusolverMpGetrf`` / ``cusolverMpGetrs`` and caches them for its lifetime.
That one-time split is expensive, so reusing the handle amortizes the cost.

Cleanup is driven by ``nvmath.distributed.finalize()``, not by ``atexit``.
``finalize()`` calls :func:`clear_handles` before tearing down the
``nvmath.distributed`` runtime's NCCL communicator: :func:`clear_handles`
destroys each cuSOLVERMp handle, which in turn destroys the NCCL
sub-communicators that cuSOLVERMp split off from the runtime's parent
communicator. Those sub-communicators must be destroyed while the parent is
still alive, so this has to happen before ``finalize()`` tears the parent down.
"""

__all__ = ["clear_handles", "get_handle"]

from nvmath.bindings import cusolverMp  # type: ignore[attr-defined]
from nvmath.internal import utils

_HANDLES: dict[int, int] = {}


def get_handle(device_id: int, stream_ptr: int) -> int:
    """
    Return the cached cuSOLVERMp handle for ``device_id``, creating and
    caching one if necessary.

    ``stream_ptr`` is used only on first creation per device; subsequent
    calls return the cached handle unchanged.

    **This is not a collective call.** ``cusolverMpCreate`` only allocates
    local resources (CUDA streams/events, child cuBLAS/cuSOLVERDn handles,
    scratch buffers, an empty communicator cache); it never touches the NCCL
    communicator, so ranks may create their handles independently.
    """
    handle = _HANDLES.get(device_id)
    if handle is None:
        with utils.device_ctx(device_id):
            handle = cusolverMp.create(device_id, stream_ptr)
        _HANDLES[device_id] = handle
    return handle


def clear_handles() -> None:
    """Destroy and forget all cached handles.

    **This is a collective call.** ``cusolverMpDestroy`` tears down the NCCL
    sub-communicators the handle split off and any cached cuBLASMp grids,
    both of which are collective over the runtime communicator.
    All ranks must therefore call this in lockstep, and it must happen
    while that parent communicator is still alive, i.e.
    before ``nvmath.distributed.finalize()`` tears it down.
    """
    for device_id, handle in _HANDLES.items():
        with utils.device_ctx(device_id):
            cusolverMp.destroy(handle)
    _HANDLES.clear()
