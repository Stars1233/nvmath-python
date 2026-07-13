# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""End-to-end numerical correctness sweep."""

from __future__ import annotations

import numpy as np
import pytest

import nvmath.distributed
from nvmath.distributed._internal.tensor_wrapper import wrap_operand as dist_wrap_operand
from nvmath.distributed.distribution import BlockCyclic, BlockNonCyclic, ProcessGrid, Slab
from nvmath.distributed.linalg import DirectSolver, DirectSolverOptions, direct_solver

from ....linalg.utils import to_numpy
from ...helpers import gather_array, process_group_broadcast
from .operand_factories import random_host_data, to_package_operand
from .params import GLOBAL_N, NRANKS, PACKAGE_MEMSPACES, PARTITION_DIM, VALID_NRANKS, skip_if_no_cupy


def _tols(dtype: str) -> tuple[float, float]:
    if dtype in ("float64", "complex128"):
        return 5e-12, 5e-12
    return 5e-3, 5e-3


def _nrhs_from_mode(nrhs_mode: str) -> int:
    return 1 if nrhs_mode in ("b_1d", "nrhs_1") else 4


def _add_local_diag_dominance(host_a, partition_dim, rank, n):
    """
    Add ``n * I_global[local_band]`` to ``host_a`` so the gathered global A
    is diagonally dominant.
    """
    # ``np.eye(N, M, k)``'s ``k`` is the (column - row) offset of the
    # diagonal. The global diagonal lives at (global_row == global_col),
    # so its position relative to the *local* origin depends on which
    # axis is locally truncated:
    #   - row-partitioned: cols span the global range, local rows start
    #     at rank*local_m. global_col - local_row = +rank*local_m.
    #   - col-partitioned: rows span the global range, local cols start
    #     at rank*local_n. local_col - global_row = -rank*local_n.
    if partition_dim == 0:
        local_m = host_a.shape[0]
        host_a += n * np.eye(local_m, n, k=rank * local_m, dtype=host_a.dtype)
    else:
        local_n = host_a.shape[1]
        host_a += n * np.eye(n, local_n, k=-rank * local_n, dtype=host_a.dtype)


def _alloc_local_a_and_b(package, memory_space, *, dtype, a_shape, b_shape, a_partition_dim, rank, device_id):
    """Generate fresh ``(host_a, a, host_b, b)`` for one factorize/solve.

    ``host_a`` and ``host_b`` are F-order (or 1-D) numpy arrays used for the
    rank-0 gather + reference solve; ``a`` and ``b`` are the operands handed
    to ``DirectSolver`` in the requested package, materialized for the
    requested memory space. ``host_*`` are independent copies of the
    operand source so that the default cpu path's overwrites don't clobber
    the reference path -- ``to_package_operand`` returns aliasing views
    under ``(numpy, cpu)`` and ``(torch, cpu)``."""
    host_a = random_host_data(a_shape, dtype)
    _add_local_diag_dominance(host_a, a_partition_dim, rank, GLOBAL_N)
    a = to_package_operand(host_a, package, memory_space, device_id=device_id)
    host_b = random_host_data(b_shape, dtype)
    b = to_package_operand(host_b, package, memory_space, device_id=device_id)
    return np.array(host_a, copy=True, order="K"), a, np.array(host_b, copy=True, order="K"), b


def _pick_row_col_dists(process_group, *, b_ndim: int):
    """Randomly bind the row-wise / col-wise abstract Slab axes to either
    ``Slab.X`` / ``Slab.Y`` or the equivalent ``BlockNonCyclic``
    distributions, so we cover both classes without doubling the parametrize
    matrix. Mirrors ``test_matmul.py``.

    Returns ``(row_wise_a, col_wise_a, row_wise_b, col_wise_b)``: A's pair
    is always 2-D (A is 2-D), b's pair matches ``b_ndim``.
    ``Slab`` works for both 1-D and 2-D b (it has no fixed ndim); the
    ``BlockNonCyclic`` branch is the one that has to be sized per operand.
    """
    nranks = process_group.nranks
    r = np.random.rand(2)
    process_group.broadcast_buffer(r)
    row_wise_a = BlockNonCyclic(ProcessGrid(shape=(nranks, 1))) if r[0] < 0.5 else Slab.X
    col_wise_a = BlockNonCyclic(ProcessGrid(shape=(1, nranks))) if r[1] < 0.5 else Slab.Y
    if b_ndim == 1:
        # 1-D b: pair with a 1-D distribution. col_wise is unused for 1-D b
        # anyway (uncollect_if forces b_dist == "R") but keep it well-formed.
        row_wise_b = BlockNonCyclic(ProcessGrid(shape=(nranks,))) if r[0] < 0.5 else Slab.X
        col_wise_b = col_wise_a
    else:
        row_wise_b = row_wise_a
        col_wise_b = col_wise_a
    return row_wise_a, col_wise_a, row_wise_b, col_wise_b


def _verify_solution(process_group, rank, host_a, host_b, host_x, a_partition_dim, b_partition_dim, dtype):
    a_global = gather_array(dist_wrap_operand(host_a), a_partition_dim, process_group, rank)
    b_global = gather_array(dist_wrap_operand(host_b), b_partition_dim, process_group, rank)
    x_global = gather_array(dist_wrap_operand(host_x), b_partition_dim, process_group, rank)

    if rank == 0:
        assert a_global is not None and b_global is not None and x_global is not None
        rtol, atol = _tols(dtype)
        try:
            x_ref = np.linalg.solve(a_global.tensor, b_global.tensor)
            np.testing.assert_allclose(np.asarray(x_global.tensor), x_ref, rtol=rtol, atol=atol)
            process_group_broadcast(process_group, None)
        except Exception as e:
            process_group_broadcast(process_group, e)
            raise
    else:
        e = process_group_broadcast(process_group, None)
        if e is not None:
            raise e


def _skip_test_direct_solver_e2e(package, memory_space, inplace, dtype, a_dist, b_dist, nrhs_mode, reset_method):
    # nranks outside the supported set: prune the whole matrix up-front so we
    # don't pay collection/fixture cost just to skip in the body.
    if NRANKS not in VALID_NRANKS:
        return True

    # 1-D b requires npcol == 1, i.e. b is row-partitioned only.
    if nrhs_mode == "b_1d" and b_dist != "R":
        return True

    # Col-partitioned b needs nrhs divisible by nranks (and at least 1 col per rank).
    if b_dist == "C":
        nrhs = _nrhs_from_mode(nrhs_mode)
        if nrhs % NRANKS != 0 or nrhs < NRANKS:
            return True

    # Pin reset_method != "none" to a single representative combo to keep the
    # matrix manageable -- same idea as test_matmul.py.
    if reset_method != "none":
        if (a_dist, b_dist) != ("R", "R"):
            return True
        if nrhs_mode != "nrhs_4":
            return True

    # release_operands() exercises a single CPU-vs-GPU mirror-cleanup
    # codepath that doesn't interact with dtype; pin to one dtype to avoid
    # bloat. Package is left free so both memory-space cleanup branches
    # ("cpu" -> drop user handles, "cuda" -> drop refs) still run.
    return reset_method == "release_then_reset" and dtype != "float64"


@pytest.mark.uncollect_if(func=_skip_test_direct_solver_e2e)
@pytest.mark.parametrize(
    "package,memory_space",
    PACKAGE_MEMSPACES,
    ids=[f"{p}-{m}" for p, m in PACKAGE_MEMSPACES],
)
@pytest.mark.parametrize("inplace", [False, True])
@pytest.mark.parametrize("dtype", ["float32", "float64", "complex64", "complex128"])
@pytest.mark.parametrize("a_dist", ("R", "C"))
@pytest.mark.parametrize("b_dist", ("R", "C"))
@pytest.mark.parametrize("nrhs_mode", ["b_1d", "nrhs_1", "nrhs_4"])
@pytest.mark.parametrize("reset_method", ["none", "checked", "unchecked", "release_then_reset"])
def test_direct_solver_e2e(package, memory_space, inplace, dtype, a_dist, b_dist, nrhs_mode, reset_method, nvmath_distributed):
    ctx = nvmath.distributed.get_context()
    process_group = ctx.process_group
    rank = process_group.rank
    nranks = process_group.nranks
    device_id = ctx.device_id

    a_partition_dim = PARTITION_DIM[a_dist]
    b_partition_dim = PARTITION_DIM[b_dist]
    b_ndim = 1 if nrhs_mode == "b_1d" else 2
    # Randomized Slab vs BlockNonCyclic. Same class on all ranks via broadcast.
    row_wise_a, col_wise_a, row_wise_b, col_wise_b = _pick_row_col_dists(process_group, b_ndim=b_ndim)
    a_dist_obj = row_wise_a if a_partition_dim == 0 else col_wise_a
    b_dist_obj = row_wise_b if b_partition_dim == 0 else col_wise_b

    n = GLOBAL_N
    nrhs = _nrhs_from_mode(nrhs_mode)

    a_shape = (n // nranks, n) if a_partition_dim == 0 else (n, n // nranks)
    if nrhs_mode == "b_1d":
        # uncollect_if already forced b_dist == "R" (b_partition_dim == 0).
        b_shape: tuple[int, ...] = (n // nranks,)
    else:
        b_shape = (n // nranks, nrhs) if b_partition_dim == 0 else (n, nrhs // nranks)

    host_a, a, host_b, b = _alloc_local_a_and_b(
        package,
        memory_space,
        dtype=dtype,
        a_shape=a_shape,
        b_shape=b_shape,
        a_partition_dim=a_partition_dim,
        rank=rank,
        device_id=device_id,
    )

    n_solves = 1 if reset_method == "none" else 2
    # Drive both per-operand flags from the same axis so the sweep
    # remains rectangular; mixed (inplace_a != inplace_b) is covered by
    # test_operand_semantics.py.
    options = DirectSolverOptions(inplace_a=inplace, inplace_b=inplace)
    with DirectSolver(a, b, distributions=[a_dist_obj, b_dist_obj], options=options) as solver:
        solver.plan()
        for iteration in range(n_solves):
            solver.factorize()

            x_local = solver.solve()
            if inplace:
                # inplace_b=True returns the user's b (Python object
                # identity preserved).
                assert x_local is b
            else:
                # inplace_b=False hands back a fresh tensor on the
                # user's memspace; the user's b stays untouched.
                assert x_local is not b
                # User's a is untouched too -- ``inplace_a=False`` keeps
                # the LU inside the mirror, never copies it back.
                np.testing.assert_array_equal(to_numpy(a), host_a)
                np.testing.assert_array_equal(to_numpy(b), host_b)

            host_x = to_numpy(x_local)
            _verify_solution(process_group, rank, host_a, host_b, host_x, a_partition_dim, b_partition_dim, dtype)

            if iteration == n_solves - 1:
                break

            if reset_method == "release_then_reset":
                solver.release_operands()

            # Under inplace=True a/b were clobbered by factorize/solve;
            # under inplace=False the mirror was clobbered. Either way,
            # allocate a fresh problem so the second iteration
            # exercises reset_operands against a genuinely new system.
            host_a, a, host_b, b = _alloc_local_a_and_b(
                package,
                memory_space,
                dtype=dtype,
                a_shape=a_shape,
                b_shape=b_shape,
                a_partition_dim=a_partition_dim,
                rank=rank,
                device_id=device_id,
            )
            if reset_method in ("checked", "release_then_reset"):
                solver.reset_operands(a=a, b=b)
            else:
                solver.reset_operands_unchecked(a=a, b=b)


@pytest.mark.parametrize(
    "package,memory_space",
    PACKAGE_MEMSPACES,
    ids=[f"{p}-{m}" for p, m in PACKAGE_MEMSPACES],
)
@pytest.mark.parametrize("inplace", [False, True])
@pytest.mark.parametrize("dtype", ["float32", "float64", "complex64", "complex128"])
def test_direct_solver_function(package, memory_space, inplace, dtype, nvmath_distributed):
    """stateless ``direct_solver(...)``. Pinned to row-partitioned Slab.X for both
    operands; the full distribution / reset matrix is exercised by the stateful
    sweep above, so here we limit the scope.
    """
    ctx = nvmath.distributed.get_context()
    process_group = ctx.process_group
    rank = process_group.rank
    nranks = process_group.nranks
    device_id = ctx.device_id

    n = GLOBAL_N
    nrhs = _nrhs_from_mode("nrhs_4")
    host_a, a, host_b, b = _alloc_local_a_and_b(
        package,
        memory_space,
        dtype=dtype,
        a_shape=(n // nranks, n),
        b_shape=(n // nranks, nrhs),
        a_partition_dim=0,
        rank=rank,
        device_id=device_id,
    )

    options = DirectSolverOptions(inplace_a=inplace, inplace_b=inplace)
    x = direct_solver(a, b, distributions=[Slab.X, Slab.X], options=options)

    host_x = to_numpy(x)
    _verify_solution(process_group, rank, host_a, host_b, host_x, 0, 0, dtype)


def _local_to_global(local_size, proc_coord, nproc, block_size):
    """Global indices owned by ``proc_coord`` along one block-cyclic axis.

    The standard ScaLAPACK local->global mapping.
    We need it here only because the test slices a
    rank's tile out of a globally-generated reference matrix.
    """
    local = np.arange(local_size)
    return (local // block_size) * nproc * block_size + proc_coord * block_size + (local % block_size)


@pytest.mark.parametrize(
    "package,memory_space",
    PACKAGE_MEMSPACES,
    ids=[f"{p}-{m}" for p, m in PACKAGE_MEMSPACES],
)
@pytest.mark.parametrize("inplace", [False, True])
@pytest.mark.parametrize("b_kind", ["slab_x_2d", "slab_x_1d", "noncyclic_1d"])
def test_direct_solver_a_2d_blockcyclic(package, memory_space, inplace, b_kind, nvmath_distributed):
    """A genuinely 2-D (2x2) block-cyclic grid, paired with a row-partitioned b.

    - ``descA`` lives on a 2x2 device grid
    - ``descB`` lives on an ``(nranks, 1)`` grid. The two layouts
    are only compatible because A's row block size (``mb``) equals b's row block
    (``n // nranks``). ``b_kind`` sweeps the two common row-partitioned b forms:

      * ``slab_x_2d``    -- 2-D multi-RHS b (nrhs=4) on ``Slab.X``.
      * ``slab_x_1d``    -- 1-D single-RHS b on ``Slab.X``.
      * ``noncyclic_1d`` -- 1-D single-RHS b on a 1-D ``(nranks,)``
                            ``BlockNonCyclic`` (promoted to ``(nranks, 1)``).

    Only run with ``float64`` for simplicity. A *cyclic* b is intentionally not
    covered: its scattered 2-D x would need explicit per-block reassembly to
    verify, unlike the row-partitioned x here, which gathers along rows.
    """
    ctx = nvmath.distributed.get_context()
    process_group = ctx.process_group
    rank = process_group.rank
    nranks = process_group.nranks
    device_id = ctx.device_id

    if nranks != 4:
        pytest.skip(f"requires exactly 4 ranks for a 2x2 process grid; got {nranks}")

    # Distribution schematic (n=64, mb=nb=16 -> 4x4 grid of 16x16 blocks).
    #
    # Process grid is 2x2 COL_MAJOR, so ranks are laid out as:
    #
    #          pcol0  pcol1
    #   prow0 [  0  |  2  ]
    #   prow1 [  1  |  3  ]
    #
    # A (block-cyclic 2-D): each rank owns
    # 4 scattered 16x16 blocks (its local tile is 32x32):
    #
    #          bc0 bc1 bc2 bc3            rank -> owned 16x16 A-blocks
    #   br0 [   0   2   0   2 ]          0 -> (br0,bc0)(br0,bc2)(br2,bc0)(br2,bc2)
    #   br1 [   1   3   1   3 ]          1 -> (br1,bc0)(br1,bc2)(br3,bc0)(br3,bc2)
    #   br2 [   0   2   0   2 ]          2 -> (br0,bc1)(br0,bc3)(br2,bc1)(br2,bc3)
    #   br3 [   1   3   1   3 ]          3 -> (br1,bc1)(br1,bc3)(br3,bc1)(br3,bc3)
    #
    # b (row-partitioned): each rank owns one contiguous 16-row band:
    #
    #   rank0 -> rows  0..15
    #   rank1 -> rows 16..31
    #   rank2 -> rows 32..47
    #   rank3 -> rows 48..63
    #
    # x is returned on b's distribution (same row banding as above).

    dtype = "float64"
    n = GLOBAL_N
    nprow, npcol = 2, 2
    # A's row block must equal b's row block (n // nranks) or cusolverMpTrsm
    # rejects the getrs (A.MB != X.MB). With n=64 / nranks=4 that gives mb=16:
    # 4 block-rows dealt over 2 process rows, i.e. a genuinely cyclic (2 blocks
    # per process row) 2-D layout, not a contiguous one.
    mb = nb = n // nranks

    # Global system, generated identically on every rank (fixed seed) so each
    # rank can slice its own tile without communication. Diagonally dominant
    # via ``n * I`` so the system is well-conditioned and nonsingular.
    rng = np.random.default_rng(23)
    global_a = (rng.standard_normal((n, n)) + n * np.eye(n)).astype(dtype)

    grid = ProcessGrid(shape=(nprow, npcol), layout=ProcessGrid.Layout.COL_MAJOR)
    a_dist = BlockCyclic(grid, block_sizes=(mb, nb))

    # Row-partitioned b: 2-D multi-RHS Slab.X, or 1-D single-RHS (on either
    # Slab.X or BlockNonCyclic). All three give a contiguous n // nranks row
    # band per rank with row block mb.
    rows_count = n // nranks
    if b_kind == "slab_x_2d":
        global_b = rng.standard_normal((n, 4)).astype(dtype)
        b_dist = Slab.X
        host_b = np.asfortranarray(global_b[rank * rows_count : (rank + 1) * rows_count, :])
    else:  # 1-D b: slab_x_1d (Slab.X) or noncyclic_1d (BlockNonCyclic)
        global_b = rng.standard_normal(n).astype(dtype)
        b_dist = Slab.X if b_kind == "slab_x_1d" else BlockNonCyclic(ProcessGrid(shape=(nranks,)))
        # must use .copy() here: a 1-D contiguous slice is already contiguous, so
        # np.ascontiguousarray would alias global_b. Under (cpu, inplace=True) the
        # operand is an aliasing view, so the in-place solve would write x back into
        # global_b and corrupt the reference solve below.
        host_b = np.ascontiguousarray(global_b[rank * rows_count : (rank + 1) * rows_count]).copy()

    # This rank's 2-D block-cyclic tile of A (COL_MAJOR: myprow = rank % nprow).
    # With n=64, mb=nb=16 and a 2x2 grid, every rank owns 2 blocks per axis,
    # i.e. a 32x32 local tile (hardwired here for clarity,
    # but one could use a_dist.shape).
    myprow, mypcol = rank % nprow, rank // nprow
    local_rows = local_cols = 32
    global_rows = _local_to_global(local_rows, myprow, nprow, mb)
    global_cols = _local_to_global(local_cols, mypcol, npcol, nb)
    host_a = np.asfortranarray(global_a[np.ix_(global_rows, global_cols)])

    a = to_package_operand(host_a, package, memory_space, device_id=device_id)
    b = to_package_operand(host_b, package, memory_space, device_id=device_id)

    options = DirectSolverOptions(inplace_a=inplace, inplace_b=inplace)
    x = direct_solver(a, b, distributions=[a_dist, b_dist], options=options)

    # x comes back on b's (row-partitioned) distribution, so gather along rows
    # and compare against the global reference solve on rank 0.
    x_global = gather_array(dist_wrap_operand(to_numpy(x)), 0, process_group, rank)
    if rank == 0:
        assert x_global is not None
        rtol, atol = _tols(dtype)
        try:
            x_ref = np.linalg.solve(global_a, global_b)
            x_got = np.asarray(x_global.tensor)
            np.testing.assert_allclose(x_got, x_ref, rtol=rtol, atol=atol)
            process_group_broadcast(process_group, None)
        except Exception as e:
            process_group_broadcast(process_group, e)
            raise
    else:
        e = process_group_broadcast(process_group, None)
        if e is not None:
            raise e


def _padded_cupy_view(host, *, pad_rows, pad_cols, device_id):
    """Return a CuPy column-major view into an oversized parent so the view's
    leading dimension (column stride) exceeds its local row count.

    ``host`` is an F-order NumPy array whose values are copied into the logical
    ``host.shape`` region of a ``(rows + pad_rows, cols + pad_cols)`` F-order
    parent. The returned view has ``strides[0] == 1`` and ``strides[1] ==
    rows + pad_rows`` (in elements), which is exactly the padded-LLD layout
    ``_is_col_major`` accepts (a slice of a larger allocation).
    """
    import cupy as cp

    rows, cols = host.shape
    with cp.cuda.Device(device_id):
        parent = cp.empty((rows + pad_rows, cols + pad_cols), dtype=host.dtype, order="F")
        view = parent[:rows, :cols]
        view[:] = cp.asarray(host)
    return view


@skip_if_no_cupy
@pytest.mark.parametrize("inplace", [False, True])
def test_direct_solver_sliced_padded_lld(inplace, nvmath_distributed):
    """Operands passed as slices of oversized column-major parents."""
    ctx = nvmath.distributed.get_context()
    process_group = ctx.process_group
    rank = process_group.rank
    nranks = process_group.nranks
    device_id = ctx.device_id

    import cupy as cp

    dtype = "float64"
    n = GLOBAL_N
    nrhs = 6
    local_m = n // nranks
    pad_rows, pad_cols_a = 4, 3

    # Host references (F-order); A is diagonally dominant so the global is nonsingular.
    host_a = random_host_data((local_m, n), dtype)
    _add_local_diag_dominance(host_a, 0, rank, n)
    host_b = random_host_data((local_m, nrhs), dtype)

    # Device operands are padded slices: lld = local_m + pad_rows > local_m. A is
    # padded on both axes (so there is also storage past the last logical column);
    # b only along rows.
    a = _padded_cupy_view(host_a, pad_rows=pad_rows, pad_cols=pad_cols_a, device_id=device_id)
    b = _padded_cupy_view(host_b, pad_rows=pad_rows, pad_cols=0, device_id=device_id)
    assert a.shape == (local_m, n) and b.shape == (local_m, nrhs)

    options = DirectSolverOptions(inplace_a=inplace, inplace_b=inplace)
    with DirectSolver(a, b, distributions=[Slab.X, Slab.X], options=options) as solver:
        solver.plan()
        solver.factorize()
        x_local = solver.solve()
        local_ld_a, local_ld_b = solver._local_ld_a, solver._local_ld_b
        x_is_b = x_local is b

    itemsize = a.dtype.itemsize
    # The user operands really are padded slices (leading dimension > local rows).
    assert a.strides[1] // itemsize == local_m + pad_rows
    assert b.strides[1] // itemsize == local_m + pad_rows
    if inplace:
        # cuSOLVERMp works on the padded user buffer; the descriptor LLD is the
        # padded stride and the returned x aliases b.
        assert local_ld_a == local_m + pad_rows
        assert local_ld_b == local_m + pad_rows
        assert x_is_b
    else:
        # The operand is cloned into a dense (tight) mirror, so the descriptor
        # LLD collapses to the local row count and x is a fresh array.
        assert local_ld_a == local_m
        assert local_ld_b == local_m
        assert not x_is_b

    # x is on the GPU; under inplace_b=True it is the padded `b` view, whose
    # strides a tight host buffer can't represent -- copy to a tight F-order
    # buffer before transferring to host for the reference comparison.
    with cp.cuda.Device(device_id):
        x_contig = cp.asfortranarray(x_local)
    host_x = cp.asnumpy(x_contig)

    _verify_solution(process_group, rank, host_a, host_b, host_x, 0, 0, dtype)
