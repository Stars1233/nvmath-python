# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
Tests for :meth:`Distribution.to`.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

import pytest

import nvmath.distributed
from nvmath.distributed.distribution import (
    BlockCyclic,
    BlockNonCyclic,
    Box,
    ConvertDistributionError,
    Distribution,
    ProcessGrid,
    Slab,
)


@pytest.fixture(scope="module")
def nvmath_distributed(process_group):
    """Install a minimal ``nvmath.distributed`` context for the module.

    ``Distribution.to`` performs no collectives and touches no GPU memory -- it
    only reads ``nranks`` and validates process grids. So rather than bringing up
    NCCL, we use a lightweight context backed by the process group with
    no communication backends. This lets the tests run regardless of GPU count.
    """
    assert nvmath.distributed.get_context() is None, "nvmath.distributed is already initialized"

    # We deliberately bypass nvmath.distributed.initialize(), injecting the
    # context directly via the private _ctx attribute.
    # This couples the test to that internal name, so we immediately verify the public
    # get_context() sees what we set -- if _ctx is ever renamed, this assertion fails
    # here at setup instead of as a confusing AttributeError inside a test.
    ctx = nvmath.distributed.DistributedContext(
        device_id=-1,
        process_group=process_group,
        nvshmem_available=False,
        nccl_comm=None,
    )
    nvmath.distributed._ctx = ctx
    assert nvmath.distributed.get_context() is ctx, "nvmath.distributed._ctx injection no longer wires up get_context()"
    try:
        yield
    finally:
        nvmath.distributed._ctx = None


_MB = 4  # row block size used throughout, rank-independent


# ----------------------------------------------------------------------
# Source-distribution builders
# ----------------------------------------------------------------------


def _blockcyclic_1d(n: int) -> BlockCyclic:
    return BlockCyclic(ProcessGrid(shape=(n,)), block_sizes=(_MB,), first_process=(0,))


def _blocknoncyclic_1d(n: int) -> BlockNonCyclic:
    return BlockNonCyclic(ProcessGrid(shape=(n,)), first_process=(0,))


def _blockcyclic_2d(n: int) -> BlockCyclic:
    return BlockCyclic(ProcessGrid(shape=(n, 1), layout=ProcessGrid.Layout.COL_MAJOR), block_sizes=(_MB, 1))


def _slab_unset(_n: int) -> Slab:
    return Slab(0)  # ndim unset; adopts the destination ndim on conversion


def _slab_1d(_n: int) -> Slab:
    return Slab(0, ndim=1)


def _box_1d(_n: int) -> Box:
    return Box(lower=(0,), upper=(_MB,))


def _box_2d(_n: int) -> Box:
    return Box(lower=(0, 0), upper=(_MB, _MB))


# ----------------------------------------------------------------------
# Schema
# ----------------------------------------------------------------------


@dataclass
class Promotion:
    id: str
    make_source: Callable[[int], Distribution]
    destination: type[Distribution]
    ndim: int | None
    expect_type: type[Distribution]
    # Assertions on the converted result, as {attribute: expected_value}.
    # The key is an attribute name looked up on the result, dotted for nesting
    # (e.g. "process_grid.shape" reads result.process_grid.shape). The value is
    # either the expected value directly, or a function of nranks returning it
    # (e.g. lambda nranks: (nranks, 1)) for expectations that depend on the rank count.
    expect: dict[str, Any]
    marks: tuple = ()


@dataclass
class Rejection:
    id: str
    make_source: Callable[[int], Distribution]
    destination: type[Distribution]
    ndim: int | None
    exc: type[BaseException]
    match: str | None = None


# ----------------------------------------------------------------------
# Support matrix
#
# Each row's id is the `.to()` call (source + destination family + ndim).
# Note `destination` is the *requested* family, while `expect_type` is the
# class actually returned: converting a BlockNonCyclic to the BlockCyclic
# family yields a BlockNonCyclic (it's a BlockCyclic subclass), so those
# two columns intentionally differ on the non-cyclic rows.
#
#   source                .to() call                  result            status
#   --------------------  --------------------------  ----------------  ----------
#   BlockCyclic    (1-D)   .to(BlockCyclic, ndim=2)    BlockCyclic (2D)  ok
#   BlockNonCyclic (1-D)   .to(BlockCyclic, ndim=2)    BlockNonCyclic(2D) ok
#   Slab (ndim unset)      .to(BlockCyclic, ndim=2)    BlockNonCyclic(2D) ok
#   Slab           (1-D)   .to(BlockCyclic, ndim=2)    BlockNonCyclic(2D) ok
#   Slab           (1-D)   .to(Slab, ndim=2)           Slab (2D)         ok
#   BlockNonCyclic (1-D)   .to(Slab, ndim=2)           Slab (2D)         ok
#   Box            (1-D)   .to(Box, ndim=2)            Box (2D)          ok
#
# Rejections (see REJECTIONS below):
#
#   source                .to() call                  raises
#   --------------------  --------------------------  ------------------------
#   BlockCyclic    (2-D)   .to(BlockCyclic, ndim=1)    ValueError (ndim < source)
#   Slab                   .to(Box, ndim=2)            NotImplementedError
#   BlockCyclic            .to(BlockNonCyclic, ndim=2) NotImplementedError
#   Box                    .to(Slab, ndim=2)           NotImplementedError
#   BlockCyclic (unbound)  .to(Slab, ndim=2)           ConvertDistributionError
# ----------------------------------------------------------------------

PROMOTIONS: list[Promotion] = [
    Promotion(
        id="blockcyclic_1d.to(BlockCyclic,ndim=2)",
        make_source=_blockcyclic_1d,
        destination=BlockCyclic,
        ndim=2,
        expect_type=BlockCyclic,
        expect={
            "ndim": 2,
            "process_grid.shape": lambda nranks: (nranks, 1),
            "block_sizes": (_MB, 1),
            "first_process": (0, 0),
        },
    ),
    Promotion(
        # Slab with unset ndim: Slab.to() takes the ndim-substitution path.
        id="slab.to(BlockCyclic,ndim=2)",
        make_source=_slab_unset,
        destination=BlockCyclic,
        ndim=2,
        expect_type=BlockNonCyclic,
        expect={
            "ndim": 2,
            "process_grid.shape": lambda nranks: (nranks, 1),
            "block_sizes": (-1, -1),
        },
    ),
    Promotion(
        # Slab with explicit ndim=1: same destination as above, but exercises
        # the ndim != self._ndim promotion path in Slab.to() instead.
        id="slab_1d.to(BlockCyclic,ndim=2)",
        make_source=_slab_1d,
        destination=BlockCyclic,
        ndim=2,
        expect_type=BlockNonCyclic,
        expect={
            "ndim": 2,
            "process_grid.shape": lambda nranks: (nranks, 1),
            "block_sizes": (-1, -1),
        },
    ),
    Promotion(
        id="slab_1d.to(Slab,ndim=2)",
        make_source=_slab_1d,
        destination=Slab,
        ndim=2,
        expect_type=Slab,
        expect={"ndim": 2, "partition_dim": 0},
    ),
    Promotion(
        id="blocknoncyclic_1d.to(Slab,ndim=2)",
        make_source=_blocknoncyclic_1d,
        destination=Slab,
        ndim=2,
        expect_type=Slab,
        expect={"ndim": 2, "partition_dim": 0},
    ),
    Promotion(
        id="box_1d.to(Box,ndim=2)",
        make_source=_box_1d,
        destination=Box,
        ndim=2,
        expect_type=Box,
        expect={"ndim": 2, "lower": (0, 0), "upper": (_MB, 1)},
    ),
    Promotion(
        # Converting a BlockNonCyclic to the BlockCyclic family keeps it a
        # BlockNonCyclic (for which block sizes are irrelevant until
        # they're resolved at bind time).
        id="blocknoncyclic_1d.to(BlockCyclic,ndim=2)",
        make_source=_blocknoncyclic_1d,
        destination=BlockCyclic,
        ndim=2,
        expect_type=BlockNonCyclic,
        expect={
            "ndim": 2,
            "process_grid.shape": lambda nranks: (nranks, 1),
            "block_sizes": (-1, 1),
            "first_process": (0, 0),
        },
    ),
]


# ----------------------------------------------------------------------
# Unsupported conversions / guards.
# ----------------------------------------------------------------------

REJECTIONS: list[Rejection] = [
    Rejection(
        id="reject_lower_ndim",
        make_source=_blockcyclic_2d,
        destination=BlockCyclic,
        ndim=1,
        exc=ValueError,
        match=r"ndim argument .* must be >= .* dimensionality",
    ),
    Rejection(
        id="reject_blockcyclic->blocknoncyclic",
        make_source=_blockcyclic_2d,
        destination=BlockNonCyclic,
        ndim=2,
        exc=NotImplementedError,
    ),
    Rejection(
        id="reject_box->slab",
        make_source=_box_2d,
        destination=Slab,
        ndim=2,
        exc=NotImplementedError,
    ),
    Rejection(
        id="reject_unbound_blockcyclic->slab",
        make_source=_blockcyclic_2d,
        destination=Slab,
        ndim=2,
        exc=ConvertDistributionError,
        match=r"Unbound BlockCyclic",
    ),
]


# ----------------------------------------------------------------------
# Helpers + tests.
# ----------------------------------------------------------------------


def _resolve(obj: object, dotted: str) -> Any:
    for attr in dotted.split("."):
        obj = getattr(obj, attr)
    return obj


def _check(obj: object, expected: dict[str, Any], nranks: int) -> None:
    for path, val in expected.items():
        if callable(val):
            val = val(nranks)
        actual = _resolve(obj, path)
        assert actual == val, f"{path}: expected {val!r}, got {actual!r}"


@pytest.mark.parametrize("case", [pytest.param(c, id=c.id, marks=c.marks) for c in PROMOTIONS])
def test_promotion(case: Promotion, nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks

    source = case.make_source(nranks)
    result = source.to(case.destination, ndim=case.ndim)

    assert type(result) is case.expect_type, f"expected {case.expect_type.__name__}, got {type(result).__name__}"
    _check(result, case.expect, nranks)


@pytest.mark.parametrize("case", [pytest.param(c, id=c.id) for c in REJECTIONS])
def test_rejected(case: Rejection, nvmath_distributed):
    nranks = nvmath.distributed.get_context().process_group.nranks

    source = case.make_source(nranks)
    with pytest.raises(case.exc, match=case.match):
        source.to(case.destination, ndim=case.ndim)
