# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""Operand factories for the distributed :class:`DirectSolver` test modules.

The structured factories (:func:`nonsingular_a`, :func:`singular_a`,
:func:`constant_b`) accept a ``partition_dim`` keyword that selects which
axis the operand is partitioned along (``0`` == rows, ``1`` == columns).
Today only ``partition_dim=0`` is implemented;
non-zero values raise :class:`NotImplementedError`.
"""

from __future__ import annotations

import numpy as np


def random_host_data(shape, dtype):
    """Generate an F-order (2-D) or contiguous (1-D) numpy array of random values.

    Uses ``np.random.rand`` (uniform in ``[0, 1)``) for real dtypes;
    independent real and imaginary draws for complex dtypes. 2-D arrays
    are returned in column-major (Fortran) order, which matches the
    layout cuSOLVERMp's getrf / getrs descriptors expect.
    """
    if dtype in ("complex64", "complex128"):
        data = (np.random.rand(*shape) + 1j * np.random.rand(*shape)).astype(dtype)
    else:
        data = np.random.rand(*shape).astype(dtype)
    if data.ndim == 2:
        data = np.asfortranarray(data)
    return data


def to_package_operand(host_data, package, memory_space, *, device_id):
    if package == "numpy":
        return host_data
    if package == "cupy":
        # cupy/torch are optional test deps; fail loudly if a caller selects
        # one that isn't installed instead of letting a bare ImportError leak.
        try:
            import cupy
        except ImportError as e:
            raise RuntimeError("operand factory requested package='cupy', but cupy is not installed") from e

        with cupy.cuda.Device(device_id):
            local = cupy.asarray(host_data)
            if local.ndim == 2:
                local = cupy.asfortranarray(local)
        return local
    if package == "torch":
        try:
            import torch
        except ImportError as e:
            raise RuntimeError("operand factory requested package='torch', but torch is not installed") from e

        if host_data.ndim == 2:
            # Round-trip through a C-order transpose so the resulting
            # tensor is F-strided (same trick as test_matmul.py:1076).
            c_host = np.ascontiguousarray(host_data.T)
            t = torch.from_numpy(c_host)
            if memory_space == "cuda":
                t = t.to(device_id)
            return t.T
        t = torch.from_numpy(host_data)
        if memory_space == "cuda":
            t = t.to(device_id)
        return t
    raise AssertionError(f"unknown package {package}")


def _check_partition_dim(partition_dim: int) -> None:
    if partition_dim != 0:
        raise NotImplementedError(
            f"partition_dim={partition_dim} is not yet supported; only "
            f"partition_dim=0 (row-partitioned slab, e.g. Slab.X) is implemented."
        )


def nonsingular_a(
    local_dim,
    global_n,
    rank,
    *,
    scale=1.0,
    strict_lower=False,
    partition_dim=0,
    dtype="float64",
    package="numpy",
    memory_space="cpu",
    device_id=None,
):
    """Rank-local diagonally-dominant slab; gathered global matrix is ``scale * I``.

    For ``partition_dim=0``: returns ``(local_dim, global_n)``, content
    ``scale * np.eye(local_dim, global_n, k=rank*local_dim)`` -- each rank owns
    a contiguous row block of the (scaled) global identity. Assumes uniform row
    partitioning (``local_dim == global_n // nranks``).

    ``scale`` lets callers solve a closed-form ``A x = b`` with ``x = b / scale``
    that is distinct from ``b`` (so a no-op solver can't pass by returning ``b``).

    ``strict_lower`` adds a single sub-diagonal entry per diagonal block so that
    ``LU(A) != A``; this makes "factorize overwrote the user's A" assertions
    meaningful (a plain diagonal A has ``LU == A`` and would pass even if the
    copy-back were broken). No-op when ``local_dim < 2``.
    """
    _check_partition_dim(partition_dim)
    host = scale * np.eye(local_dim, global_n, k=rank * local_dim, dtype=np.dtype(dtype), order="F")
    if strict_lower and local_dim > 1:
        host[1, rank * local_dim] = 1.0
    return to_package_operand(host, package, memory_space, device_id=device_id)


def singular_a(
    local_dim,
    global_n,
    *,
    partition_dim=0,
    dtype="float64",
    package="numpy",
    memory_space="cpu",
    device_id=None,
):
    """Rank-local all-zeros slab. Gathered global matrix is the zero matrix (singular).

    For ``partition_dim=0``: returns shape ``(local_dim, global_n)``. The
    content (all zeros) is partition-invariant; only the shape signature
    is row-partition-specific.
    """
    _check_partition_dim(partition_dim)
    host = np.zeros((local_dim, global_n), dtype=np.dtype(dtype), order="F")
    return to_package_operand(host, package, memory_space, device_id=device_id)


def constant_b(
    local_dim,
    nrhs,
    *,
    partition_dim=0,
    value=1.0,
    dtype="float64",
    package="numpy",
    memory_space="cpu",
    device_id=None,
):
    """Constant-valued 2-D F-order right-hand-side operand.

    For ``partition_dim=0``: returns shape ``(local_dim, nrhs)`` -- b is
    row-partitioned, each rank owns a row block and all ``nrhs`` columns.
    Content (constant ``value``) is partition-invariant.
    """
    _check_partition_dim(partition_dim)
    host = np.full((local_dim, nrhs), value, dtype=np.dtype(dtype), order="F")
    return to_package_operand(host, package, memory_space, device_id=device_id)
