# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Persistent device state (pivot vector + info words) and the cross-rank
info reducer used by :meth:`DirectSolver.factorize`.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Final

import cuda.bindings.runtime as cbr
import numpy as np

from nvmath.internal.tensor_ifc_ndbuffer import NDBufferTensor
from nvmath.internal.tensor_ifc_numpy import NumpyTensor

if TYPE_CHECKING:
    from cuda.core import Event

    from nvmath.internal.package_ifc import StreamHolder


class _FactorizationState:
    """Pivot vector and post-call info codes for cuSOLVERMp getrf/getrs."""

    # info dtype, as documented by the cusolverMp getrf / getrs.
    # Annotated as Final[str] so static checkers flag any reassignment.
    _INFO_DTYPE: Final[str] = "int32"

    __slots__ = (
        "_alloc_stream",
        "_info_getrf_d",
        "_info_getrf_h",
        "_info_getrs_d",
        "_ipiv",
    )

    def __init__(
        self,
        *,
        local_cols_a: int,
        device_id: int,
        stream_holder: StreamHolder,
    ) -> None:
        # Stream the device buffers are allocated on, used in free().
        self._alloc_stream = stream_holder.obj

        # ``ipiv`` is pure cuSOLVERMp scratch: getrf writes the pivot
        # indices, getrs reads them, we never inspect the contents.
        # ipiv has extent N (one entry per column of A, one per pivot step).
        # Each entry's value is still a global row index (the row swapped
        # to the leading position at that step). The dtype is int64.
        # max(.., 1) is used for ranks that own zero columns.
        #
        self._ipiv = NDBufferTensor.empty(
            (max(local_cols_a, 1),),
            device_id=device_id,
            dtype="int64",
            stream_holder=stream_holder,
        )

        # ``_info_getrs_d`` is kept as a write-only target: cuSOLVERMp's
        # getrs requires a non-NULL pointer for the info argument, but
        # we never read the value back -- getrs has no info>0 case and
        # info<0 would indicate an internal binding bug we cannot
        # productively surface here.
        self._info_getrs_d = NDBufferTensor.empty(
            (1,),
            device_id=device_id,
            dtype=self._INFO_DTYPE,
            stream_holder=stream_holder,
        )

        # Three-element buffer: element 0 holds the getrf info word and feeds
        # the cross-rank info check, elements 1 and 2 receive its MAX and MIN
        # reductions; see sync_and_check_factorize_info.
        self._info_getrf_h = NumpyTensor.empty((3,), dtype=self._INFO_DTYPE)
        self._info_getrf_d = self._info_getrf_h.to(device_id, stream_holder)

    @property
    def ipiv_device_ptr(self) -> int:
        return self._ipiv.data_ptr

    @property
    def info_getrf_device_ptr(self) -> int:
        # getrf's single int32 info word goes in element 0 of the shared buffer.
        return self._info_getrf_d.data_ptr

    @property
    def info_getrs_device_ptr(self) -> int:
        return self._info_getrs_d.data_ptr

    def reset_info_getrs_device(self, stream_holder) -> None:
        """Stream-ordered zero of ``_info_getrs_d``."""
        (status,) = cbr.cudaMemsetAsync(self._info_getrs_d.data_ptr, 0, np.dtype(self._INFO_DTYPE).itemsize, stream_holder.ptr)
        if status != cbr.cudaError_t.cudaSuccess:
            raise RuntimeError(f"cudaMemsetAsync on info_getrs_d failed with status {status!r}")

    def sync_and_check_factorize_info(self, stream_holder, *, nccl_comm) -> None:
        """Sync the factorize stream, reduce the per-rank getrf ``info`` word
        across ranks, and raise on failure.

        getrf writes ``info`` on each rank (0 = success, >0 = singular
        leading-minor order, <0 = illegal argument). Raises ``RuntimeError`` if
        any rank is singular, or ``AssertionError`` if any rank reports an
        illegal argument (a solver-internal bug). See the inline comments for
        the MIN/MAX reduction and the raise ordering.
        """
        assert nccl_comm is not None  # should have been enforced at solver init
        multi_rank = nccl_comm.nranks > 1
        info_ptr = self._info_getrf_d.data_ptr  # getrf wrote the local info word here (element 0)
        if multi_rank:
            # Reduce the local info word (element 0) across ranks with both MIN
            # and MAX: MAX alone would miss negatives (``max(-3, 0) == 0``) and
            # MIN alone would miss positives, and we must catch both. The two
            # allreduces are grouped into a single NCCL launch; NCCL gives no
            # ordering between operations in a group, so we have MAX/MIN write
            # distinct outputs. The group is enqueued on the factorize
            # stream so it orders after getrf.
            # nccl is imported lazily here because importing nccl.core eagerly
            # imports the torch and cupy packages (its interop submodules run
            # ``import torch`` / ``import cupy`` at load time), which we can avoid
            # unless we actually need it.
            from nccl.bindings import nccl as nccl_bindings  # type: ignore
            from nccl.core.typing import INT32, MAX, MIN  # type: ignore

            vmax_ptr = info_ptr + self._info_getrf_d.itemsize  # element 1
            vmin_ptr = info_ptr + 2 * self._info_getrf_d.itemsize  # element 2
            nccl_bindings.group_start()
            nccl_bindings.all_reduce(info_ptr, vmax_ptr, 1, int(INT32), int(MAX), nccl_comm.ptr, stream_holder.ptr)
            nccl_bindings.all_reduce(info_ptr, vmin_ptr, 1, int(INT32), int(MIN), nccl_comm.ptr, stream_holder.ptr)
            nccl_bindings.group_end()

        # copy_ is blocking here.
        self._info_getrf_h.copy_(self._info_getrf_d, stream_holder)
        # Element 0 holds the local info word (used directly when single-rank);
        # for the multi-rank, element 1 holds max(info) and element 2 holds min(info).
        if multi_rank:
            vmax = self._info_getrf_h.tensor[1]
            vmin = self._info_getrf_h.tensor[2]
        else:
            vmax = vmin = self._info_getrf_h.tensor[0]

        # Raise based on the allreduced values so every rank raises together.
        # Negative info means an illegal argument: getrf's args are
        # solver-internal, so it's our bug. Check it before the singular case
        # so an internal bug still surfaces when another rank also flags a
        # singular minor, and via AssertionError to survive `python -O`.
        if vmin < 0:
            raise AssertionError(
                f"Internal error: cuSOLVERMp getrf reported an illegal argument at position {-vmin} (info={vmin})."
            )
        if vmax > 0:
            raise RuntimeError(f"DirectSolver factorization failed: matrix is singular (leading minor of order {vmax}).")

    def free(self, last_compute_event: Event | None = None) -> None:
        """Release the pivot vector and the host/device info buffers.

        Device buffers free stream-ordered on their allocation stream when
        dropped; waiting that stream on ``last_compute_event`` first orders
        the free after any in-flight getrf/getrs (mirrors
        :meth:`Workspace.release`).
        """
        if last_compute_event is not None and self._alloc_stream is not None:
            self._alloc_stream.wait(last_compute_event)
        self._info_getrf_h = None
        self._ipiv = None
        self._info_getrf_d = None
        self._info_getrs_d = None
