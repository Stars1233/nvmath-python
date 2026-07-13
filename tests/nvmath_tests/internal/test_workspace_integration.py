# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Integration tests for nvmath._internal.workspace.Workspace exercising real
CUDA allocators end-to-end.

Unlike test_workspace.py (which uses fake allocators with a stubbed device_ctx
to cover state-machine semantics), this file requires a real CUDA device and
runs Workspace against four production allocators spanning all three protocol
branches plus host-pinned memory:

- ``raw``    — internal ``_RawCUDAMemoryManager`` (BaseCUDAMemoryManagerAsync)
- ``cupy``   — ``_CupyCUDAMemoryManager`` (BaseCUDAMemoryManagerAsync, 3rd-party)
- ``device`` — ``cuda.core.DeviceMemoryResource`` (MemoryResource, device-only)
- ``pinned`` — ``cuda.core.LegacyPinnedMemoryResource`` (MemoryResource, host)

Tests skip cleanly when CUDA or cupy is unavailable.
"""

import ctypes
import logging

import pytest
from cuda.core import Device, DeviceMemoryResource, LegacyPinnedMemoryResource

import nvmath.memory as nvmem
from nvmath._internal.workspace import NumpyMemoryResource, Workspace
from nvmath.internal import utils
from nvmath.memory import MemoryPointer

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def cuda_device():
    """Real cuda.core.Device(0). Skips the entire module if no CUDA device."""
    try:
        d = Device(0)
        d.set_current()
        return d
    except Exception as e:  # pragma: no cover — environment skip
        pytest.skip(f"No CUDA device available: {e}")


@pytest.fixture
def stream_holder(cuda_device):
    """Real StreamHolder built from a fresh cuda.core stream — same construction
    path consumers use via ``utils.get_or_create_stream``."""
    stream = cuda_device.create_stream()
    return utils.get_or_create_stream(device_id=0, stream=stream, op_package="cuda")


@pytest.fixture
def logger():
    return logging.getLogger("nvmath.test.workspace_integration")


def _build_allocator(kind: str, device_id: int, logger: logging.Logger):
    """Construct one of the four canonical allocators by id, skipping the test
    if its backing package isn't installed."""
    if kind == "raw":
        return nvmem._MEMORY_MANAGER["_raw"](device_id, logger)
    if kind == "cupy":
        try:
            nvmem.lazy_load_cupy()
        except ImportError:
            pytest.skip("cupy not installed")
        return nvmem._MEMORY_MANAGER["cupy"](device_id, logger)
    if kind == "device":
        return DeviceMemoryResource(device_id)
    if kind == "pinned":
        return LegacyPinnedMemoryResource()
    raise ValueError(f"unknown allocator kind: {kind}")  # pragma: no cover


ALLOCATOR_IDS = ["raw", "cupy", "device", "pinned"]
LEGACY_ALLOCATOR_IDS = ["raw", "cupy"]  # the ones with the 0-byte sentinel path


@pytest.fixture(params=ALLOCATOR_IDS)
def allocator(request, cuda_device, logger):
    """Parametrized fixture: each test using ``allocator`` runs once per kind."""
    return _build_allocator(request.param, device_id=0, logger=logger)


# ---------------------------------------------------------------------------
# Smoke tests parametrized over the four allocators
# ---------------------------------------------------------------------------


def test_alloc_release_roundtrip(allocator, stream_holder, logger):
    """End-to-end smoke: real allocate, lifecycle through the with block,
    real free + stream-ordered close on release. Sanity-checks every state
    transition in the basic Empty → JustAllocated → ReuseHeld → Empty path."""
    # device_id passed explicitly because the `pinned` parametrization uses
    # LegacyPinnedMemoryResource, whose `device_id` deliberately raises (pinned
    # memory isn't bound to a specific GPU). The other three allocators expose
    # device_id=0; the explicit kwarg covers all four uniformly.
    ws = Workspace(allocator, device_id=0, logger=logger, label="roundtrip")
    ws.set_size(4096)

    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        assert w.raw_ptr != 0
        assert w.allocated_size >= 4096
        assert w.allocated_here is True
        assert w.stream is stream_holder.obj

    # ReuseHeld between blocks: buffer kept, allocated_here cleared.
    assert ws.ptr is not None
    assert ws.allocated_here is False

    ws.release(None)
    assert ws.ptr is None
    assert ws.allocated_size == 0


def test_reuse_short_circuits_second_alloc(allocator, stream_holder, logger):
    """A second `with` block at the same size reuses the buffer — verified
    behaviorally: the underlying ptr object is the same across both blocks
    (a fresh allocation would replace it)."""
    ws = Workspace(allocator, device_id=0, logger=logger, label="reuse")
    ws.set_size(2048)

    with ws.allocate_perhaps(stream_holder, get_last_event=None):
        first_ptr = ws.ptr

    with ws.allocate_perhaps(stream_holder, get_last_event=None):
        # Same Python object → reuse, not a new allocation.
        assert ws.ptr is first_ptr

    ws.release(None)


def test_grow_releases_old_and_allocates_new(allocator, stream_holder, logger):
    """Grow path: second `with` block at a larger size triggers the
    grow-cleanup release of the held buffer plus a fresh allocation. The
    consumer's last_compute_event is a real cuda.core.Event recorded from
    the prior block — verifies the runtime accepts it for `stream.wait()`."""
    ws = Workspace(allocator, device_id=0, logger=logger, label="grow")

    ws.set_size(1024)
    with ws.allocate_perhaps(stream_holder, get_last_event=None):
        first_ptr = ws.ptr

    last_event = stream_holder.obj.record()

    ws.set_size(8192)
    with ws.allocate_perhaps(stream_holder, get_last_event=lambda: last_event):
        # Distinct object — fresh allocation replaced the old one.
        assert ws.ptr is not first_ptr
        assert ws.allocated_size >= 8192

    ws.release(None)


def test_release_workspace_inside_block(allocator, stream_holder, logger):
    """Mirror of the consumer's ``release_workspace=True`` pattern: record a
    real event, call ``ws.release(event)`` mid-block, verify state transitions
    to Empty and the block exits cleanly without re-releasing."""
    ws = Workspace(allocator, device_id=0, logger=logger, label="release-mid")
    ws.set_size(512)

    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        event = stream_holder.obj.record()
        w.release(event)
        assert w.ptr is None  # state = Empty
        assert w.allocated_here is False

    # __exit__ on Empty is a no-op (allocated_here was already cleared by release).
    assert ws.ptr is None


def test_on_allocated_callback_fires_with_real_pointer(allocator, stream_holder, logger):
    """The on_allocated hook fires with the integer pointer right after a
    successful allocation, inside the device + stream context. Verifies
    ``_get_ptr`` resolves the pointer correctly for each backing (Buffer
    handle vs MemoryPointer device_ptr)."""
    captured: list[int] = []
    ws = Workspace(
        allocator,
        device_id=0,
        logger=logger,
        label="on-allocated",
        on_allocated=captured.append,
    )
    ws.set_size(1024)

    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        assert captured == [w.raw_ptr]
        assert captured[0] != 0

    ws.release(None)


# ---------------------------------------------------------------------------
# Pinned-only tests — exercise host-dereferenceability of the buffer
# ---------------------------------------------------------------------------


def test_pinned_host_writable_via_ctypes(stream_holder, cuda_device, logger):
    """Pinned-host workspace's raw_ptr is a real host-dereferenceable pointer:
    write a byte pattern via ctypes, read it back, see the same bytes. Catches
    any regression where Workspace returned a non-host pointer for a pinned
    backing."""
    ws = Workspace(LegacyPinnedMemoryResource(), device_id=0, logger=logger, label="pinned-host")
    ws.set_size(64)

    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        buf = (ctypes.c_ubyte * w.size).from_address(w.raw_ptr)
        for i in range(w.size):
            buf[i] = i & 0xFF
        # Re-read via a fresh ctypes view to avoid buffer aliasing artifacts.
        readback = (ctypes.c_ubyte * w.size).from_address(w.raw_ptr)
        assert list(readback) == [i & 0xFF for i in range(w.size)]

    ws.release(None)


def test_pinned_h2d_d2h_roundtrip(stream_holder, cuda_device, logger):
    """End-to-end real-CUDA round-trip: pinned-host → device → pinned-host.
    Fill via host write, copy_to(device), zero the host, copy_from(device),
    assert the original pattern is restored. This is the flow that motivated
    MirroredWorkspace/NumPyWorkspaceView and cleanly proves stream-ordered
    Buffer.close on a pinned resource doesn't corrupt anything in flight."""
    pinned_ws = Workspace(LegacyPinnedMemoryResource(), device_id=0, logger=logger, label="pinned-rt")
    device_ws = Workspace(DeviceMemoryResource(0), logger=logger, label="device-rt")
    size = 256
    pinned_ws.set_size(size)
    device_ws.set_size(size)

    with (
        pinned_ws.allocate_perhaps(stream_holder, get_last_event=None) as host_w,
        device_ws.allocate_perhaps(stream_holder, get_last_event=None) as dev_w,
    ):
        # Host fill.
        host_buf = (ctypes.c_ubyte * size).from_address(host_w.raw_ptr)
        for i in range(size):
            host_buf[i] = (i * 7 + 3) & 0xFF
        expected = list(host_buf)

        # H→D, D→H using the cuda.core Buffer copy API on the same stream.
        # Sync after H→D so the host memset can't race with the (asynchronous)
        # DMA reading from the pinned buffer.
        host_w.ptr.copy_to(dev_w.ptr, stream=stream_holder.obj)
        stream_holder.obj.sync()
        # Zero the host buffer to prove the readback isn't reading stale data.
        ctypes.memset(host_w.raw_ptr, 0, size)
        dev_w.ptr.copy_to(host_w.ptr, stream=stream_holder.obj)
        stream_holder.obj.sync()

        readback = (ctypes.c_ubyte * size).from_address(host_w.raw_ptr)
        assert list(readback) == expected

    pinned_ws.release(None)
    device_ws.release(None)


# ---------------------------------------------------------------------------
# NumpyMemoryResource — host-only path against the real cuda.core API
# (no CUDA device required; runs whenever cuda.core is importable)
# ---------------------------------------------------------------------------


def test_numpy_alloc_release_roundtrip(logger):
    """End-to-end smoke for the host-only path against the real cuda.core
    types: NumpyMemoryResource produces a real cuda.core.Buffer (via
    Buffer.from_handle), Workspace state machine transitions Empty →
    JustAllocated → ReuseHeld → Empty, and release() routes Buffer.close(None)
    back to NumpyMemoryResource.deallocate without touching the CUDA driver."""
    mr = NumpyMemoryResource()
    ws = Workspace(mr, logger=logger, label="numpy-roundtrip")
    ws.set_size(4096)

    with ws.allocate_perhaps(None, get_last_event=None) as w:
        assert w.raw_ptr != 0
        assert w.allocated_size >= 4096
        assert w.allocated_here is True
        assert w.stream is None  # host-only path retains no stream

    assert ws.ptr is not None  # ReuseHeld between blocks
    assert ws.allocated_here is False

    ws.release(None)
    assert ws.ptr is None
    assert ws.allocated_size == 0


def test_numpy_reuse_short_circuits_second_alloc(logger):
    """Second `with` block at the same size reuses the buffer — same Python
    object across both entries proves no fresh Buffer.from_handle call."""
    mr = NumpyMemoryResource()
    ws = Workspace(mr, logger=logger, label="numpy-reuse")
    ws.set_size(2048)

    with ws.allocate_perhaps(None, get_last_event=None):
        first_ptr = ws.ptr

    with ws.allocate_perhaps(None, get_last_event=None):
        assert ws.ptr is first_ptr

    ws.release(None)


def test_numpy_grow_releases_old_and_allocates_new(logger):
    """Grow path: second `with` at a larger size releases the held buffer and
    allocates a fresh one. Whitebox: verify against NumpyMemoryResource._held
    that the old ptr is dropped and the new one held."""
    mr = NumpyMemoryResource()
    ws = Workspace(mr, logger=logger, label="numpy-grow")

    ws.set_size(1024)
    with ws.allocate_perhaps(None, get_last_event=None):
        small_ptr = ws.raw_ptr
    assert small_ptr in mr._held

    ws.set_size(8192)
    with ws.allocate_perhaps(None, get_last_event=None):
        big_ptr = ws.raw_ptr
        assert big_ptr != small_ptr
        assert ws.allocated_size >= 8192

    # Old buffer was released through Buffer.close(None) → MR.deallocate.
    assert small_ptr not in mr._held
    assert big_ptr in mr._held

    ws.release(None)
    assert big_ptr not in mr._held


def test_numpy_host_writable_via_ctypes(logger):
    """raw_ptr is a real host-dereferenceable address: write a byte pattern
    via ctypes, read it back via a fresh ctypes view. Catches any regression
    where NumpyMemoryResource handed Workspace a non-host pointer."""
    mr = NumpyMemoryResource()
    ws = Workspace(mr, logger=logger, label="numpy-host")
    ws.set_size(64)

    with ws.allocate_perhaps(None, get_last_event=None) as w:
        buf = (ctypes.c_ubyte * w.size).from_address(w.raw_ptr)
        for i in range(w.size):
            buf[i] = i & 0xFF
        readback = (ctypes.c_ubyte * w.size).from_address(w.raw_ptr)
        assert list(readback) == [i & 0xFF for i in range(w.size)]

    ws.release(None)


def test_numpy_release_inside_block_with_none_event(logger):
    """Mid-block release(None) on the host-only path: state transitions to
    Empty, the `with` block exits cleanly, and there's no double-free
    (Buffer.close(stream=None) routes through NumpyMemoryResource.deallocate
    once)."""
    mr = NumpyMemoryResource()
    ws = Workspace(mr, logger=logger, label="numpy-release-mid")
    ws.set_size(512)

    with ws.allocate_perhaps(None, get_last_event=None) as w:
        ptr = w.raw_ptr
        assert ptr in mr._held
        w.release(None)
        assert w.ptr is None
        assert w.allocated_here is False
        assert ptr not in mr._held  # deallocate fired exactly once

    assert ws.ptr is None  # __exit__ on Empty is a no-op


# ---------------------------------------------------------------------------
# Legacy-only 0-byte sentinel: exercises the special path that produces a
# MemoryPointer(0, 0) sentinel rather than calling the allocator with size=0.
# ---------------------------------------------------------------------------


@pytest.fixture(params=LEGACY_ALLOCATOR_IDS)
def legacy_allocator(request, cuda_device, logger):
    return _build_allocator(request.param, device_id=0, logger=logger)


def test_legacy_zero_byte_sentinel_then_grow(legacy_allocator, stream_holder, logger):
    """size=0 with a legacy allocator: Workspace produces a MemoryPointer(0, 0)
    sentinel without invoking the allocator (some backends raise on
    memalloc_async(0)). A subsequent set_size(128) follows the grow path
    from the sentinel to a real allocation."""
    ws = Workspace(legacy_allocator, logger=logger, label="zero-byte")
    ws.set_size(0)

    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        assert isinstance(w.ptr, MemoryPointer)
        assert w.raw_ptr == 0
        assert w.allocated_size == 0
        assert w.allocated_here is True

    # Grow from the 0-byte sentinel: real allocation runs.
    ws.set_size(128)
    with ws.allocate_perhaps(stream_holder, get_last_event=None) as w:
        assert w.raw_ptr != 0
        assert w.allocated_size >= 128

    ws.release(None)
