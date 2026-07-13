# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""This module defines an emitter for the universal sparse tensor (UST)."""

__all__ = []

import re
from enum import Enum
from io import StringIO
from itertools import permutations
from sys import stdout

from nvmath.sparse.ust.tensor_format import (
    Add,
    Dimension,
    Divide,
    LevelExpr,
    LevelFormat,
    Modulo,
    Sequence,
    Subtract,
    is_unique,
)

from ._cpp import prolog_decl
from ._utils import as_external_tensor, type_str

###############
# Definitions #
###############


class Backend(Enum):
    CUDA = 1
    OMP = 2


class Index(Enum):
    LEVEL = 1
    LEVEL_A = 2
    LEVEL_B = 3
    FREE = 4
    FREE_A = 5
    FREE_B = 6


ID = {Index.LEVEL: "l", Index.LEVEL_A: "ll", Index.LEVEL_B: "l", Index.FREE: "i", Index.FREE_A: "ii", Index.FREE_B: "i"}

CYCLIC = 1024  # cyclic scheduled coarsening

INDEX_DONE = 999


##################
# HELPER METHODS #
##################


def _id0(list):
    return f"{[('i' + str(i)) for i in list]}"


def _id1(list):
    return f"{[(ID[t] + str(i)) for t, i in list]}"


def _base(C):
    return f"idxC{len(C) - 1}" if len(C) > 0 else "0"


def _fmt(fmt):
    if isinstance(fmt, tuple):
        fmt, _ = fmt
    return fmt


def _is_unique(fmt):
    if isinstance(fmt, Sequence):
        _, prop = fmt
        return is_unique(prop)
    return True


def _collapse_type(ftypes, A, fmtA, k):
    """Returns loop type 'par' or 'red' depending on indexing."""
    if isinstance(k, Dimension):
        return ftypes[A[fmtA.dimensions.index(k)]]
    elif isinstance(k, LevelExpr) and (
        _collapse_type(ftypes, A, fmtA, k.expression1) == "red" or _collapse_type(ftypes, A, fmtA, k.expression2) == "red"
    ):
        return "red"
    return "par"


def _max_grid(indices, fmts):
    """Returns the maximum grid (up to 3-D) that can be supported."""
    maxg = 0
    for t, i in indices:
        if t == Index.FREE or _fmt(fmts[i]) in (LevelFormat.DENSE, LevelFormat.BATCH, LevelFormat.COMPRESSED):
            maxg += 1
            continue
        break
    return min(3, maxg)


def _lvl2dim(fmtA, A):
    """Returns the mapping of assignments that will implement lvl2dim."""

    def _mapi(k):
        return A[fmtA.dimensions.index(k)]

    def _find_range(litems, expr1, expr2):
        for lvl, (k, v) in enumerate(litems):
            if _fmt(v) == LevelFormat.RANGE and k in (expr1, expr2):
                return lvl, k
        raise AssertionError(f"Cannot find {expr1} or {expr2} in levels")

    lmap = []
    litems = fmtA.levels.items()
    for lvl, (k, _) in enumerate(litems):
        if isinstance(k, Dimension):
            i = _mapi(k)
            stmt = f"const CRD i{i} = l{lvl};"
            need, gen = [lvl], [i]
        elif isinstance(k.operator, Add):
            rl, re = _find_range(litems, k.expression1, k.expression2)
            if re == k.expression2:
                i = _mapi(k.expression1)
                stmt = f"const CRD i{i} = l{lvl} - l{rl};"
                need, gen = [lvl, rl], [i]
            else:
                assert re == k.expression1
                i = _mapi(k.expression2)
                stmt = f"const CRD i{i} = l{lvl} - l{rl};"
                need, gen = [lvl, rl], [i]
        elif isinstance(k.operator, Subtract):
            rl, re = _find_range(litems, k.expression1, k.expression2)
            if re == k.expression2:
                i = _mapi(k.expression1)
                stmt = f"const CRD i{i} = l{rl} + l{lvl};"
                need, gen = [rl, lvl], [i]
            else:
                assert re == k.expression1
                i = _mapi(k.expression2)
                stmt = f"const CRD i{i} = l{rl} - l{lvl};"
                need, gen = [rl, lvl], [i]
        elif isinstance(k.operator, Divide):
            i = _mapi(k.expression1)
            stmt = f"const CRD b{i} = l{lvl} * {k.expression2};"
            need, gen = [lvl], []  # i not ready yet!
        elif isinstance(k.operator, Modulo):
            i = _mapi(k.expression1)
            stmt = f"const CRD i{i} = b{i} + l{lvl};"
            need, gen = [lvl], [i]  # i ready!
        else:
            raise AssertionError(f"Unsupported: {k}")

        lmap.append((need, stmt, gen))

    return lmap


###################
# EMITTER METHODS #
###################


def _emit_linearize(name, subs, geni, stream=stdout, indent=0):
    """Emits linearized address computations for a dense tensor."""
    for n, i in enumerate(subs):
        if i == INDEX_DONE:
            continue
        elif i in geni:
            sub = f"(idx{name}{n - 1} + i{i})" if n > 0 else f"i{i}"
            if n == len(subs) - 1:  # last one
                print(f"{'':>{indent}}const CRD idx{name}{n} = {sub};", file=stream)
                if name == "C":
                    print(f"{'':>{indent}}CTP vC = 0;", file=stream)
                else:
                    assert name == "B"
                    print(f"{'':>{indent}}const CTP vB = prolog_b(static_cast<CTP>(B[idxB{n}]));", file=stream)
            else:
                print(f"{'':>{indent}}const CRD idx{name}{n} = {sub} * N{subs[n + 1]};", file=stream)
            subs[n] = INDEX_DONE
        else:
            return  # next subscript must wait


def _emit_ready(lmap, A, B, C, P, genl, geni, stream=stdout, indent=0):
    """Emits all variables that have their required inputs generated."""
    # Indices ready?
    for m in range(len(lmap)):
        if lmap[m] is not None:
            need, stmt, gen = lmap[m]
            if all(n in genl for n in need):
                print(f"{'':>{indent}}{stmt}", file=stream)
                geni.extend(gen)
                lmap[m] = None
    # A ready? Note that linearization is already done by sparse emitter.
    if all(i in geni for i in A):
        print(f"{'':>{indent}}const CTP vA = prolog_a(static_cast<CTP>(Aval[{P}]));", file=stream)
        A[0] = INDEX_DONE
    # B, C ready?
    _emit_linearize("B", B, geni, stream=stream, indent=indent)
    _emit_linearize("C", C, geni, stream=stream, indent=indent)


def _emit_types(ctp, vtp, itp, gtp, stream=stdout, backend=Backend.CUDA):
    """Emits type definitions with required includes."""
    if backend == Backend.CUDA:
        if vtp in ["__nv_fp8_e4m3", "__nv_fp8_e5m2"]:
            print("#include <cuda_fp8.h>\n", file=stream)
        elif vtp in ["__half"]:
            print("#include <cuda_fp16.h>\n", file=stream)
        elif vtp in ["__nv_bfloat16"]:
            print("#include <cuda_bf16.h>\n", file=stream)
        elif vtp.startswith("cuda::std::complex"):
            print("#include <cuda/std/complex>\n", file=stream)
    elif backend == Backend.OMP:
        if vtp in ["__nv_fp8_e4m3", "__nv_fp8_e5m2", "__half", "__nv_bfloat16"]:
            raise NotImplementedError()
    else:
        raise AssertionError(f"Unsupported backend: {backend}")
    print(f"using CTP = {ctp};", file=stream)
    print(f"using VAL = {vtp};", file=stream)
    print(f"using POS = {itp};", file=stream)
    print(f"using CRD = {itp};", file=stream)
    print(f"using GRD = {gtp};\n", file=stream)


def _emit_atomic(C, vtp, stream=stdout, indent=0, backend=Backend.CUDA):
    """Emits atomic operation."""
    if backend == Backend.CUDA:
        if not vtp.startswith("cuda::std::complex"):
            print(f"{'':>{indent}}atomicAdd(&C[{_base(C)}], static_cast<VAL>(vC));", file=stream)
        else:
            atp = re.search(r"<(.+?)>", vtp).group(1)
            print(f"{'':>{indent}}{atp}* addr = reinterpret_cast<{atp}*>(&C[{_base(C)}]);", file=stream)
            print(f"{'':>{indent}}const VAL c = static_cast<VAL>(vC);", file=stream)
            print(f"{'':>{indent}}atomicAdd(addr + 0, c.real());", file=stream)
            print(f"{'':>{indent}}atomicAdd(addr + 1, c.imag());", file=stream)
    elif backend == Backend.OMP:
        print(f"{'':>{indent}}omp_atomic_add(&C[{_base(C)}], static_cast<VAL>(vC));", file=stream)
    else:
        raise AssertionError(f"Unsupported backend: {backend}")


def _emit_shuffle_down(C, vtp, stream=stdout, indent=0, backend=Backend.CUDA):
    if backend != Backend.CUDA:
        raise NotImplementedError(f"Unsupported backend for shuffle down: {backend}")
    print(f"{'':>{indent}}// WARP REDUCTION (to reduce number of atomics)", file=stream)
    print(f"{'':>{indent}}assert((blockDim.x & 31) == 0);", file=stream)
    print(f"{'':>{indent}}#pragma unroll", file=stream)
    print(f"{'':>{indent}}for (int offset = 16; offset > 0; offset >>= 1) {{", file=stream)
    print(f"{'':>{indent}}  vC += __shfl_down_sync(0xffffffffu, vC, offset);", file=stream)
    print(f"{'':>{indent}}}}", file=stream)
    print(f"{'':>{indent}}int lane = threadIdx.x & 31;", file=stream)
    print(f"{'':>{indent}}if (lane == 0) {{", file=stream)
    _emit_atomic(C, vtp, stream=stream, indent=indent + 2, backend=backend)
    print(f"{'':>{indent}}}}", file=stream)


def _emit_accumulate(C, vtp, reduc, stream=stdout, indent=0, backend=Backend.CUDA):
    isAtomicRed, isWarpRed, _ = reduc
    if isAtomicRed:
        if isWarpRed:
            _emit_shuffle_down(C, vtp, stream=stream, indent=indent, backend=backend)
        else:
            _emit_atomic(C, vtp, stream=stream, indent=indent, backend=backend)
    else:
        print(f"{'':>{indent}}C[{_base(C)}] += static_cast<VAL>(vC);", file=stream)


def _emit_cleanup(N, C, vtp, reduc, isGrid=True, stream=stdout, indent=0, backend=Backend.CUDA):
    # OMP uses tightly nested parallel loops for grid set up, so the accumulation
    # must end and the inner loop nest level.
    _, _, cd = reduc
    if isGrid and backend == Backend.OMP and cd is not None:
        cd = N - 1
    # Loop nest closing.
    for i in range(N - 1, -1, -1):
        if cd == i:
            _emit_accumulate(C, vtp, reduc, stream=stream, indent=indent, backend=backend)
        indent -= 2
        print(f"{'':>{indent}}}}", file=stream)


def _emit_thread_grid_setup(
    indices, types, A, B, C, fmtA, lmap, genl, geni, endian, stream=stdout, indent=0, backend=Backend.CUDA
):
    """Emits a G-dim grid for a kernel."""
    G = len(indices)
    assert len(types) == G

    print(f"{'':>{indent}}// {G}-D GRID: {_id1(indices)} {types}", file=stream)

    # Grid setup.
    if backend == Backend.CUDA:
        if G == 1:
            print(f"{'':>{indent}}const GRD x = blockIdx.x * blockDim.x + threadIdx.x;", file=stream)
            # print(f"{'':>{indent}}const POS t = x;", file=stream)
            grid = ["x"]  # any endian
        elif G == 2:
            print(f"{'':>{indent}}const GRD x = blockIdx.x * blockDim.x + threadIdx.x;", file=stream)
            print(f"{'':>{indent}}const GRD y = blockIdx.y * blockDim.y + threadIdx.y;", file=stream)
            # print(f"{'':>{indent}}const GRD w = gridDim.x * blockDim.x;", file=stream)
            # print(f"{'':>{indent}}const GRD t = y * w + x;", file=stream)
            grid = ["x", "y"] if endian else ["y", "x"]
        elif G == 3:
            print(f"{'':>{indent}}const GRD x = blockIdx.x * blockDim.x + threadIdx.x;", file=stream)
            print(f"{'':>{indent}}const GRD y = blockIdx.y * blockDim.y + threadIdx.y;", file=stream)
            print(f"{'':>{indent}}const GRD z = blockIdx.z * blockDim.z + threadIdx.z;", file=stream)
            # print(f"{'':>{indent}}const GRD w = gridDim.x * blockDim.x;", file=stream)
            # print(f"{'':>{indent}}const GRD h = gridDim.y * blockDim.y;", file=stream)
            # print(f"{'':>{indent}}const GRD t = z * w * h + y * w + x;", file=stream)
            grid = ["x", "y", "z"] if endian else ["z", "y", "x"]
        else:
            raise AssertionError(f"unexpected {G}-D grid")
    elif backend == Backend.OMP:
        assert endian
        grid = ["x", "y", "z"][:G]
        print(f"{'':>{indent}}#pragma omp parallel for", file=stream)
        for i in range(G):
            grid_index = grid[i]
            grid_bound = f"G{grid_index}"
            print(f"{'':>{indent}}for (GRD {grid_index} = 0; {grid_index} < {grid_bound}; {grid_index}++) {{", file=stream)
            indent += 2
    else:
        raise AssertionError(f"Unsupported backend: {backend}")

    # Grid translation into loops.
    P = "0"
    isAtomicRed = False
    cd = None
    fmts = list(fmtA.levels.values())
    for g in range(G):
        t, a = indices[g]
        if t == Index.FREE or t == Index.FREE_A:
            if t == Index.FREE:
                ii, cnst = f"i{a}", "const "
                geni.append(a)
            else:
                ii, cnst = f"ii{a}", ""
            print(f"{'':>{indent}}{cnst}CRD {ii} = {grid[g]};", file=stream)
            if backend == Backend.CUDA:
                print(f"{'':>{indent}}if ({ii} < N{a}) {{", file=stream)
                indent += 2
            else:
                print(f"{'':>{indent}}if ({ii} >= N{a}) continue;", file=stream)
        elif t == Index.LEVEL or t == Index.LEVEL_A:
            isAtomicRed = isAtomicRed or types[g] == "red" or not _is_unique(fmts[a])
            if t == Index.LEVEL:
                pp, ll = f"p{a}", f"l{a}"
                genl.append(a)
            else:
                pp, ll = f"pp{a}", f"ll{a}"
            if _fmt(fmts[a]) in (LevelFormat.DENSE, LevelFormat.BATCH):
                print(f"{'':>{indent}}const POS {pp} = {P} * L{a} + {grid[g]};", file=stream)
                print(f"{'':>{indent}}const CRD {ll} = {grid[g]};", file=stream)
                if backend == Backend.CUDA:
                    print(f"{'':>{indent}}if ({ll} < L{a}) {{", file=stream)
                    indent += 2
                else:
                    print(f"{'':>{indent}}if ({ll} >= L{a}) continue;", file=stream)
            elif _fmt(fmts[a]) == LevelFormat.COMPRESSED:
                # TODO: batching?
                print(f"{'':>{indent}}const POS lo{a} = Apos{a}[{P}];", file=stream)
                print(f"{'':>{indent}}const POS hi{a} = Apos{a}[{P} + 1];", file=stream)
                print(f"{'':>{indent}}const POS {pp} = lo{a} + {grid[g]};", file=stream)
                if backend == Backend.CUDA:
                    print(f"{'':>{indent}}if ({pp} < hi{a}) {{", file=stream)
                    indent += 2
                else:
                    print(f"{'':>{indent}}if ({pp} >= hi{a}) continue;", file=stream)
                if t == Index.LEVEL:
                    print(f"{'':>{indent}}const CRD {ll} = Acrd{a}[{pp}];", file=stream)
            else:
                raise AssertionError(f"Unknown level format for {t}: {_fmt(fmts[a])}")
            P = pp
        else:
            raise AssertionError(f"Unexpected index type: {t}")
        _emit_ready(lmap, A, B, C, P, genl, geni, stream=stream, indent=indent)
        if cd is None and all(i == INDEX_DONE for i in C):
            cd = g

    return P, isAtomicRed, cd


def _emit_loop_structure(
    indices, types, A, B, C, fmtA, vtp, N, lmap, genl, geni, P, reduc, stream=stdout, indent=0, backend=Backend.CUDA
):
    """Emits computational loop nest for a kernel."""
    D = len(indices)
    assert D < N and len(types) == D

    def _find_add_sub(litems, r):
        for lvl, (k, _) in enumerate(litems):
            if isinstance(k, LevelExpr) and isinstance(k.operator, (Add, Subtract)):
                if k.expression1 == r:
                    return lvl, k, False, k.expression2
                if k.expression2 == r:
                    return lvl, k, True, k.expression1
        raise AssertionError(f"Cannot find {r} in levels")

    print(f"{'':>{indent}}// LOOPS: {_id1(indices)} {types}", file=stream)

    # Loop nest opening.
    isAtomicRed, isWarpRed, cd = reduc
    cd = None if cd is None else -1
    fmts = list(fmtA.levels.values())
    litems = fmtA.levels.items()
    batch = sum(_fmt(f) == LevelFormat.BATCH for f in fmts)
    for d in range(D):
        t, a = indices[d]
        if t == Index.FREE:
            print(f"{'':>{indent}}for (CRD i{a} = 0; i{a} < N{a}; i{a}++) {{", file=stream)
            geni.append(a)
        elif t == Index.FREE_B:
            print(f"{'':>{indent}}for (CRD i{a} = ii{a}; i{a} < N{a}; i{a}+={CYCLIC}) {{", file=stream)
            geni.append(a)
        elif t == Index.LEVEL:
            if _fmt(fmts[a]) in (LevelFormat.DENSE, LevelFormat.BATCH):
                print(f"{'':>{indent}}POS p{a} = {P} * L{a};", file=stream)
                print(f"{'':>{indent}}for (CRD l{a} = 0; l{a} < L{a}; l{a}++, p{a}++) {{", file=stream)
                P = f"p{a}"
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.COMPRESSED:
                if batch > 0:
                    # Batched uncompressed.
                    cidx = f"p{batch - 1} * (L{batch} + 1) + l{a - 1}"
                    hidx = f"p{batch - 1} * (L{batch} + 1) + L{batch}"
                    print(f"{'':>{indent}}const POS lo{a} = Apos{a}[{cidx}];", file=stream)
                    print(f"{'':>{indent}}const POS hi{a} = Apos{a}[{cidx} + 1];", file=stream)
                    print(f"{'':>{indent}}const POS no{a} = p{a - 2} * Apos{a}[{hidx}];", file=stream)
                    print(f"{'':>{indent}}for (POS p{a} = lo{a} + no{a}; p{a} < hi{a} + no{a}; p{a}++) {{", file=stream)
                    batch = 0
                else:
                    # Regular uncompressed.
                    print(f"{'':>{indent}}const POS lo{a} = Apos{a}[{P}];", file=stream)
                    print(f"{'':>{indent}}const POS hi{a} = Apos{a}[{P} + 1];", file=stream)
                    print(f"{'':>{indent}}for (POS p{a} = lo{a}; p{a} < hi{a}; p{a}++) {{", file=stream)
                print(f"{'':>{indent}}  const CRD l{a} = Acrd{a}[p{a}];", file=stream)
                P = f"p{a}"
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.SINGLETON:
                print(f"{'':>{indent}}const CRD l{a} = Acrd{a}[{P}];", file=stream)
                print(f"{'':>{indent}}{{", file=stream)
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.RANGE:
                q, _ = list(litems)[a]
                la, add, isI, r = _find_add_sub(litems, q)
                di, dj = fmtA.dimensions.index(q), fmtA.dimensions.index(r)
                szi, szj = f"N{di}", f"N{dj}"
                if isinstance(add.operator, Add):
                    print(f"{'':>{indent}}const CRD of{a} = l{la};", file=stream)
                    print(f"{'':>{indent}}const CRD lo{a} = llmax(0, of{a} - {szj} + 1);", file=stream)
                    print(f"{'':>{indent}}const CRD hi{a} = llmin({szi}, of{a} + 1);", file=stream)
                else:
                    print(f"{'':>{indent}}const CRD of{a} = {'-' if isI else ''}l{la};", file=stream)
                    print(f"{'':>{indent}}const CRD lo{a} = llmax(0, of{a});", file=stream)
                    print(f"{'':>{indent}}const CRD hi{a} = llmin({szi}, {szj} + of{a});", file=stream)
                print(f"{'':>{indent}}CRD p{a} = {P} * {szi} + lo{a};", file=stream)
                print(f"{'':>{indent}}for (CRD l{a} = lo{a}; l{a} < hi{a}; l{a}++, p{a}++) {{", file=stream)
                P = f"p{a}"
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.DELTA:
                print(f"{'':>{indent}}const POS lo{a} = Apos{a}[{P}];", file=stream)
                print(f"{'':>{indent}}const POS hi{a} = Apos{a}[{P} + 1];", file=stream)
                print(f"{'':>{indent}}CRD l{a} = 0; // start running sequence", file=stream)
                print(f"{'':>{indent}}for (POS p{a} = lo{a}; p{a} < hi{a}; p{a}++, l{a}++) {{", file=stream)
                print(f"{'':>{indent}}  l{a} += Acrd{a}[p{a}]; // adjust by delta", file=stream)
                P = f"p{a}"
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.STRUCTURED:
                n = fmts[a][1]
                print(f"{'':>{indent}}const POS lo{a} = {n} * {P};", file=stream)
                print(f"{'':>{indent}}const POS hi{a} = lo{a} + {n};", file=stream)
                print(f"{'':>{indent}}for (POS p{a} = lo{a}; p{a} < hi{a}; p{a}++) {{", file=stream)
                print(f"{'':>{indent}}  const CRD l{a} = Acrd{a}[p{a}];", file=stream)
                P = f"p{a}"
                genl.append(a)
            else:
                raise AssertionError(f"Unknown level format for {t}: {_fmt(fmts[a])}")
        elif t == Index.LEVEL_B:
            if _fmt(fmts[a]) in (LevelFormat.DENSE, LevelFormat.BATCH):
                print(f"{'':>{indent}}POS p{a} = {P};", file=stream)
                print(f"{'':>{indent}}for (CRD l{a} = ll{a}; l{a} < L{a}; l{a}+={CYCLIC}, p{a}+={CYCLIC}) {{", file=stream)
                P = f"p{a}"
                genl.append(a)
            elif _fmt(fmts[a]) == LevelFormat.COMPRESSED:
                assert batch == 0  # TODO: batching?
                print(f"{'':>{indent}}for (POS p{a} = {P}; p{a} < hi{a}; p{a}+={CYCLIC}) {{", file=stream)
                print(f"{'':>{indent}}  const CRD l{a} = Acrd{a}[p{a}];", file=stream)
                P = f"p{a}"
                genl.append(a)
            else:
                raise AssertionError(f"Unknown level format for {t}: {_fmt(fmts[a])}")
        else:
            raise AssertionError(f"Unexpected index type: {t}")
        indent += 2
        _emit_ready(lmap, A, B, C, P, genl, geni, stream=stream, indent=indent)
        if cd is None and all(i == INDEX_DONE for i in C):
            cd = d

    # Loop body.
    if B == [] and C == []:
        pars = ", ".join([f"i{i}" for i in range(fmtA.num_dimensions)])
        print(f"{'':>{indent}}Aval[{P}] = static_cast<VAL>(apply(vA, {pars}));", file=stream)
    elif C == []:
        print(f"{'':>{indent}}const CTP vC = vA * vB;", file=stream)
    else:
        print(f"{'':>{indent}}vC += vA * vB;", file=stream)

    # Loop nest closing.
    reduc = isAtomicRed, isWarpRed, cd
    _emit_cleanup(D, C, vtp, reduc, isGrid=False, stream=stream, indent=indent, backend=backend)


def _emit_A_parameters(fmtA, constA=True, stream=stdout, indent=0, backend=Backend.CUDA):
    """Emit kernel parameters for a UST."""
    for lvl, (_, v) in enumerate(fmtA.levels.items()):
        # Handle level format.
        if _fmt(v) in (LevelFormat.DENSE, LevelFormat.BATCH, LevelFormat.RANGE):
            pass
        elif _fmt(v) in (LevelFormat.COMPRESSED, LevelFormat.DELTA):
            print(f"{'':>{indent}}const POS* __restrict__ Apos{lvl},", file=stream)
            print(f"{'':>{indent}}const CRD* __restrict__ Acrd{lvl},", file=stream)
        elif _fmt(v) in (LevelFormat.SINGLETON, LevelFormat.STRUCTURED):
            print(f"{'':>{indent}}const CRD* __restrict__ Acrd{lvl},", file=stream)
        else:
            raise AssertionError(f"Unsupported: {_fmt(v)}")
    cnst = "const " if constA else ""
    print(f"{'':>{indent}}{cnst}VAL* __restrict__ Aval,", file=stream)


def _emit_BC_parameters(stream=stdout, indent=0):
    """Emits kernel parameters for dense B and C (shortcut for UST)."""
    print(f"{'':>{indent}}const VAL* __restrict__ B,", file=stream)
    print(f"{'':>{indent}}VAL* __restrict__ C,", file=stream)


def _emit_size_parameters(Q, L, stream=stdout, indent=0):
    """Emits kernel parameters for dimension and level sizes."""
    pars = ",\n  ".join([f"const GRD N{i}" for i in range(Q)] + [f"const GRD L{i}" for i in range(L)])
    print(f"{'':>{indent}}{pars}", file=stream)


def _emit_apply_kernel(
    indices, fmtA, endian, ctp, vtp, itp, gtp, with_indices, G, stream=stdout, indent=0, backend=Backend.CUDA
):
    """Emits a G-dim "apply" kernel for the given tensor format."""
    if backend != Backend.CUDA:
        raise NotImplementedError(f"Unsupported backend for apply kernel: {backend}")
    Q = fmtA.num_dimensions
    L = fmtA.num_levels

    print(f"\n// TENSOR FORMAT : {fmtA.name}\n", file=stream)

    _emit_types(ctp, vtp, itp, gtp, stream=stream, backend=backend)
    print("#define prolog_a(a) (a)\n", file=stream)

    dim = Q if with_indices else 0
    print(f'{"":>{indent}}extern "C" __device__ CTP apply(CTP{", CRD" * dim});\n', file=stream)
    print(f'{"":>{indent}}extern "C" __global__ void apply_kernel(', file=stream)
    indent += 2

    if with_indices:
        _emit_A_parameters(fmtA, constA=False, stream=stream, indent=indent)
        _emit_size_parameters(Q, L, stream=stream, indent=indent)
        print(") {", file=stream)
        types = ["par" for i in range(L)]
        A = list(range(Q))  # in terms of dim
        lmap, genl, geni = _lvl2dim(fmtA, A), [], []
        P, _, _ = _emit_thread_grid_setup(
            indices[:G], types[:G], A, [], [], fmtA, lmap, genl, geni, endian, stream=stream, indent=indent, backend=backend
        )
        indent += G * 2
        reduc = False, False, -1
        _emit_loop_structure(
            indices[G:], types[G:], A, [], [], fmtA, vtp, L, lmap, genl, geni, P, reduc, stream=stream, indent=indent
        )
        _emit_cleanup(G, [], vtp, reduc, isGrid=True, stream=stream, indent=indent, backend=backend)
        indent -= G * 2
    else:
        print(f"{'':>{indent}}VAL* __restrict__ Aval,\n{'':>{indent}}POS Anse) {{", file=stream)
        print(f"{'':>{indent}}const GRD x = blockIdx.x * blockDim.x + threadIdx.x;", file=stream)
        print(f"{'':>{indent}}if (x < Anse) {{", file=stream)
        print(f"{'':>{indent}}  const CTP vA = prolog_a(static_cast<CTP>(Aval[x]));", file=stream)
        print(f"{'':>{indent}}  Aval[x] = static_cast<VAL>(apply(vA));", file=stream)
        print(f"{'':>{indent}}}}", file=stream)

    indent -= 2
    print(f"{'':>{indent}}}}", file=stream)

    return indices[:G], endian


def _emit_matmul_kernel(
    indices, types, Q, G, A, B, C, fmtA, endian, ctp, vtp, itp, gtp, stream=stdout, indent=0, backend=Backend.CUDA
):
    """Emits a G-dim "matmul" kernel for the given tensor index expression."""
    N = len(indices)
    L = fmtA.num_levels
    assert len(types) == N and G <= N and L <= N

    print(f"// TENSOR ITERATION  : {_id0(list(range(Q)))}", file=stream)
    print(f"// TENSOR EXPRESSION : C{_id0(C)} += A{_id0(A)} * B{_id0(B)}", file=stream)
    print(f"// TENSOR FORMAT     : {fmtA.name}\n", file=stream)

    _emit_types(ctp, vtp, itp, gtp, stream=stream, backend=backend)
    if backend == Backend.CUDA:
        print(prolog_decl, file=stream)
    else:
        # OMP does not inject user-functions.
        print("#define prolog_a(a) (a)", file=stream)
        print("#define prolog_b(b) (b)\n", file=stream)

    print(f"{'':>{indent}}// MATMUL KERNEL: {_id1(indices)} {types}", file=stream)
    if backend == Backend.CUDA:
        print(f'{"":>{indent}}extern "C" __global__ void matmul_kernel(', file=stream)
    elif backend == Backend.OMP:
        print(f'{"":>{indent}}extern "C" void matmul_kernel(', file=stream)
    else:
        raise AssertionError(f"Unsupported backend for matmul kernel: {backend}")
    _emit_A_parameters(fmtA, stream=stream, indent=indent + 2)
    _emit_BC_parameters(stream=stream, indent=indent + 2)
    _emit_size_parameters(Q, L, stream=stream, indent=indent + 2)
    if backend == Backend.OMP:
        # For OMP, grid dimensions are passed as parameters
        print(f"{'':>{indent + 2}}, GRD Gx, GRD Gy, GRD Gz", file=stream)
    print(f"{'':>{indent}}) {{", file=stream)
    indent += 2

    lmap, genl, geni = _lvl2dim(fmtA, A), [], []
    P, isAtomicRed, cd = _emit_thread_grid_setup(
        indices[:G], types[:G], A, B, C, fmtA, lmap, genl, geni, endian, stream=stream, indent=indent, backend=backend
    )
    isWarpRed = not endian and types[G:] == [] and (types[:G] == ["par", "red"] or types[:G] == ["par", "par", "red"])
    reduc = isAtomicRed, isWarpRed, cd
    indent += G * 2
    _emit_loop_structure(
        indices[G:], types[G:], A, B, C, fmtA, vtp, N, lmap, genl, geni, P, reduc, stream=stream, indent=indent, backend=backend
    )
    _emit_cleanup(G, C, vtp, reduc, isGrid=True, stream=stream, indent=indent, backend=backend)
    indent -= G * 2

    indent -= 2
    print(f"{'':>{indent}}}}", file=stream)

    assert all(i is None for i in lmap)  # all consumed

    return indices[:G], endian


def _emit_search_space(A, B, C, fmtA, ctp, vtp, itp, gtp, kernel=None, stream=stdout, backend=Backend.CUDA):
    """Searches the state space of kernels for the given tensor index expression."""
    Q = len(set(A) | set(B) | set(C))
    L = fmtA.num_levels

    def _filter_order(indices):
        """Returns `True` when index order satisfies constraints."""
        level = 0
        for t, i in indices:
            if t == Index.LEVEL or t == Index.LEVEL_A or t == Index.LEVEL_B:
                if i < level:
                    return False
                elif t == Index.LEVEL_A:
                    level = i
                else:
                    level = i + 1
        return True  # all seen, no conflict

    # Convert iteration space [i0,i1,...] into iteration space [l0,l1,..,free].
    ftypes = ["par" if i in C else "red" for i in range(Q)]
    levels = [(Index.LEVEL, i) for i in range(L)]
    free = [(Index.FREE, i) for i in range(Q) if i not in A]
    fmts = list(fmtA.levels.values())
    llist = list(fmtA.levels)

    # Generate all valid iteration space permutations.
    count = 0
    space1 = levels + free
    for perm1 in permutations(space1):
        indices1 = list(perm1)
        if _filter_order(indices1):
            maxg = _max_grid(indices1, fmts)
            # Generate all legal 1D, 2D, 3D grid versions.
            for G in range(1, maxg + 1):
                E = [True] if (G == 1 or backend == Backend.OMP) else [True, False]
                # Generate the version for this grid without thread coarsening.
                for endian in E:
                    if count == kernel:
                        types1 = [
                            ftypes[i]
                            if t == Index.FREE or t == Index.FREE_A or t == Index.FREE_B
                            else _collapse_type(ftypes, A, fmtA, llist[i])
                            for t, i in indices1
                        ]
                        print(f"// UNCOARSENED KERNEL: K={kernel} G={G} E={endian}", file=stream)
                        return _emit_matmul_kernel(
                            indices1, types1, Q, G, A, B, C, fmtA, endian, ctp, vtp, itp, gtp, stream=stream, backend=backend
                        )
                    count += 1
                # Construct valid thread coarsening of the level and free indices.
                for gg in range(G):
                    if gg < G - 1 and all(t != Index.FREE for t, i in indices1[gg : G - 1]):
                        continue
                    prefix = []
                    suffix = []
                    for g in range(0, gg):
                        prefix.append(indices1[g])
                    for g in range(gg, G):
                        t, i = indices1[g]
                        if t == Index.LEVEL:
                            if g == G - 1:
                                prefix.append((Index.LEVEL_A, i))
                                suffix.append((Index.LEVEL_B, i))
                            else:
                                prefix.append((Index.LEVEL, i))
                        elif t == Index.FREE:
                            prefix.append((Index.FREE_A, i))
                            suffix.append((Index.FREE_B, i))
                        else:
                            raise AssertionError(f"Unexpected coarsening: {t}")
                    assert len(suffix) != 0
                    # Generate the other versions for this grid with thread coarsening.
                    space2 = suffix + indices1[G:]
                    for perm2 in permutations(space2):
                        indices2 = prefix + list(perm2)
                        if _filter_order(indices2):
                            for endian in E:
                                if count == kernel:
                                    types2 = [
                                        ftypes[i]
                                        if t == Index.FREE or t == Index.FREE_A or t == Index.FREE_B
                                        else _collapse_type(ftypes, A, fmtA, llist[i])
                                        for t, i in indices2
                                    ]
                                    print(f"// COARSENED KERNEL  : K={kernel} G={G} E={endian}", file=stream)
                                    return _emit_matmul_kernel(
                                        indices2,
                                        types2,
                                        Q,
                                        G,
                                        A,
                                        B,
                                        C,
                                        fmtA,
                                        endian,
                                        ctp,
                                        vtp,
                                        itp,
                                        gtp,
                                        stream=stream,
                                        backend=backend,
                                    )
                                count += 1

    assert kernel is None
    return count


##############
# POPULATION #
##############


#
# NVIDIA RTX A6000
#
# Threads per warp      : 32
# Max threads per block : 1024
# Max thread dimensions : (1024, 1024, 64)
# Max grid dimensions   : (2147483647, 65535, 65535)
#
#  thread dims == per axis maxima, and joint product cap 1024
#  grid   dims == per axis maxima, but no joint product cap
#
# NOTE
#  grid  (  gridDim.xyz ) -> blockIdx.xyz
#  block ( blockDim.xyz ) -> threadIdx.xyz
#
def _compute_grid_block(grid_xyz, endian):
    """Computes grid and block dimension for given grid.

    Note that we always keep X a multiple of 32 to get full warps,
    which means that X = min(x, 32) simply become X=32.
    """
    if len(grid_xyz) == 1:
        x = grid_xyz[0]  # any endian
        # X = min(x, 1024) -> 1024 max
        X = (min(x, 1024) + 31) // 32 * 32  # keep multiple of 32
        grid_dim = ((x + X - 1) // X,)
        block_dim = (X,)
    elif len(grid_xyz) == 2:
        x, y = (grid_xyz[0], grid_xyz[1]) if endian else (grid_xyz[1], grid_xyz[0])
        # X, Y = min(x, 32), min(y, 32) -> 32*32=1024 max
        X, Y = 32, min(y, 32)
        grid_dim = ((x + X - 1) // X, (y + Y - 1) // Y)
        block_dim = (X, Y)
    else:  # truncate to first three
        x, y, z = (grid_xyz[0], grid_xyz[1], grid_xyz[2]) if endian else (grid_xyz[2], grid_xyz[1], grid_xyz[0])
        # X, Y, Z = min(x, 32), min(y, 4), min(z, 8) -> 32*4*8=1024 max
        X, Y, Z = 32, min(y, 4), min(z, 8)
        grid_dim = ((x + X - 1) // X, (y + Y - 1) // Y, (z + Z - 1) // Z)
        block_dim = (X, Y, Z)
    # print(f"{grid_xyz} -> {grid_dim} {block_dim}")
    return grid_dim, block_dim


def _max_pos_diff(pos_tensor, stream_holder):
    pos_tensor = as_external_tensor(pos_tensor, stream_holder)
    return (pos_tensor[1:] - pos_tensor[:-1]).max().item()


def _populate_grid(tensorA, ti_grid_iter, sizes, stream_holder):
    """Populates grid x,y,z values given the tensor format and grid iteration."""
    fmts = list(tensorA.tensor_format.levels.values())
    grid_xyz = []
    for t, i in ti_grid_iter:
        if t == Index.FREE_A or t == Index.LEVEL_A:
            grid_xyz.append(CYCLIC)
        elif t == Index.FREE:
            grid_xyz.append(sizes[i])
        elif t == Index.LEVEL:
            if _fmt(fmts[i]) == LevelFormat.DENSE or _fmt(fmts[i]) == LevelFormat.BATCH:
                grid_xyz.append(tensorA.levels[i])
            elif _fmt(fmts[i]) == LevelFormat.COMPRESSED:
                pos_tensor = tensorA._pos[i].tensor
                grid_xyz.append(_max_pos_diff(pos_tensor, stream_holder))
            else:
                raise AssertionError(f"Unknown level format for {t}: {_fmt(fmts[i])}")
        else:
            raise AssertionError(f"Unexpected index type: {t}")
    return grid_xyz


def _populate_data_parameters(tensor):
    """Populates parameters for given UST."""
    params = []
    for lvl, (_, fmt) in enumerate(tensor.tensor_format.levels.items()):
        f = _fmt(fmt)
        if f in (LevelFormat.DENSE, LevelFormat.BATCH, LevelFormat.RANGE):
            pass
        elif f in (LevelFormat.COMPRESSED, LevelFormat.DELTA):
            params.append(tensor._pos.get(lvl).data_ptr)
            params.append(tensor._crd.get(lvl).data_ptr)
        elif f in (LevelFormat.SINGLETON, LevelFormat.STRUCTURED):
            params.append(tensor._crd.get(lvl).data_ptr)
        else:
            raise AssertionError(f"Unknown level format: {f}")
    params.append(tensor._val.data_ptr)
    return params


#################
# ENTRY METHODS #
#################


def emit_apply_kernel(tensorA, with_indices):
    """
    Emits the kernel for an apply operation (with or without indices).

    Returns source_code, grid_iter
    """
    stream = StringIO()
    fmtA = tensorA.tensor_format
    ctp = type_str(tensorA.dtype)
    vtp = ctp
    itp = type_str(tensorA.index_type)
    gtp = "int"
    indices = [(Index.LEVEL, i) for i in range(tensorA.num_levels)]
    fmts = list(fmtA.levels.values())
    G = _max_grid(indices, fmts)  # always max, with endian=True
    grid_iter = _emit_apply_kernel(indices, fmtA, True, ctp, vtp, itp, gtp, with_indices, G, stream=stream)
    return stream.getvalue(), grid_iter


def populate_apply_parameters(tensorA, with_indices, grid_iter, stream_holder):
    """
    Populates the parameters for an apply operation (with or without indices).

    Returns (grid_dim, block_dim), params
    """
    with stream_holder.ctx:
        ti_grid_iter, endian = grid_iter
        if with_indices:
            # Set grid and parameters.
            grid_xyz = _populate_grid(tensorA, ti_grid_iter, [], stream_holder)
            params = _populate_data_parameters(tensorA)
            for i in range(tensorA.num_dimensions):
                params.append(tensorA.extents[i])
            for i in range(tensorA.num_levels):
                params.append(tensorA.levels[i])
        else:
            # Set trivial grid and parameters.
            grid_xyz = [tensorA.nse]
            params = [tensorA._val.data_ptr, tensorA.nse]
        return _compute_grid_block(grid_xyz, endian), params


def emit_matmul_kernel(tensorA, tensorB, tensorC, ctp, transpose_a=False, transpose_b=False, kernel=0, backend=Backend.CUDA):
    """
    Emits the kernel for a generic C += AxB matmul operation.

    Returns source_code, grid_iter
    """
    stream = StringIO()
    vtp = type_str(tensorA.dtype)
    itp = type_str(tensorA.index_type)
    gtp = "int"

    # Restrictions on dense formats of B and C.
    if tensorB.tensor_format.name not in ["DenseVector", "DensedRight", "DensedLeft", "Dense3D-0-1-2", "Dense4D-0-1-2-3"]:
        raise NotImplementedError(f"Unsupported format {tensorB.tensor_format.name} for B operand.")
    if tensorC.tensor_format.name not in ["Scalar", "DenseVector", "DensedRight", "Dense3D-0-1-2", "Dense4D-0-1-2-3"]:
        raise NotImplementedError(f"Unsupported format {tensorC.tensor_format.name} for C operand.")

    # Construct tensor index expression.
    A, B, C = None, None, None
    if tensorA.num_dimensions == 0:
        # A is a scalar.
        raise NotImplementedError("Unsupported matmul scalar A")
    elif tensorA.num_dimensions == 1:
        # A is a vector.
        if tensorB.num_dimensions == 1 and tensorC.num_dimensions == 0:
            A, B, C = [0], [0], []  # DOT: c = a(i) b(i)
        elif tensorB.num_dimensions == 2 and tensorC.num_dimensions == 1:
            A, B, C = [0], [0, 1], [1]  # VM: c(j) = a(i) B(i,j)
    else:
        # A is a matrix or tensor.
        if tensorA.num_dimensions == 2 and tensorB.num_dimensions == 1 and tensorC.num_dimensions == 1:
            A, B, C = [0, 1], [1], [0]  # MV: c(i) = A(i,j) b(j)
        elif (
            tensorB.num_dimensions == 2 or tensorB.num_dimensions == tensorA.num_dimensions
        ) and tensorC.num_dimensions == tensorA.num_dimensions:
            bi = tensorA.num_dimensions - 2  # (B)M(B)M: C([bi*],i,k) = A([bi*],i,j) B({[bi*]},j,k)
            prefix = list(range(bi))
            prefixb = [] if tensorB.num_dimensions == 2 else prefix
            A, B, C = (
                prefix + [bi, bi + 1],
                prefixb + [bi + 1, bi + 2],
                prefix + [bi, bi + 2],
            )

    if A is None or B is None or C is None:
        raise NotImplementedError("Unsupported matmul situation in sparse emitter")

    # Transposition is on last two dimensions.
    if tensorB.tensor_format.name == "DensedLeft":
        transpose_b = not transpose_b
    if transpose_a:
        A[-2], A[-1] = A[-1], A[-2]
    if transpose_b:
        B[-2], B[-1] = B[-1], B[-2]

    grid_iter = _emit_search_space(
        A, B, C, tensorA.tensor_format, ctp, vtp, itp, gtp, kernel=kernel, stream=stream, backend=backend
    )
    return stream.getvalue(), grid_iter


def count_matmul_kernels(tensorA, tensorB, tensorC, ctp, transpose_a=False, transpose_b=False, backend=Backend.CUDA):
    """Returns the number of kernels for a generic C += AxB matmul operation."""
    _, G = emit_matmul_kernel(tensorA, tensorB, tensorC, ctp, transpose_a, transpose_b, kernel=None, backend=backend)
    return G


def populate_matmul_parameters(
    tensorA,
    tensorB,
    tensorC,
    grid_iter,
    stream_holder,
    transpose_a=False,
    transpose_b=False,
    backend=Backend.CUDA,
):
    """
    Populates the parameters for a generic C += AxB matmul operation.

    Returns (grid_dim, block_dim), params
    """
    with stream_holder.ctx:
        # Handle transposition. Because transposition can be either forced by caller
        # or due to "Left" layout of B, make sure to test "levels", not "extents".
        if tensorB.tensor_format.name == "DensedLeft":
            transpose_b = not transpose_b
        ai, aj = (1, 0) if transpose_a else (0, 1)
        bi, bj = (1, 0) if transpose_b else (0, 1)
        # Validate and extract sizes from tensor index expression.
        if tensorA.num_dimensions == 1:
            if tensorB.num_dimensions == 1 and tensorC.num_dimensions == 0:
                assert tensorA.extents[0] == tensorB.extents[0]
                sizes = [tensorA.extents[0]]  # DOT: c = a(i) b(i)
            else:
                assert tensorA.extents[0] == tensorB.levels[bi]
                assert tensorB.levels[bj] == tensorC.extents[0]
                sizes = [tensorA.extents[0], tensorC.extents[0]]  # VM: c(j) = a(i) B(i,j)
        elif tensorA.num_dimensions == 2 and tensorB.num_dimensions == 1 and tensorC.num_dimensions == 1:
            assert tensorA.extents[ai] == tensorC.extents[0]
            assert tensorA.extents[aj] == tensorB.extents[0]
            sizes = [tensorA.extents[ai], tensorA.extents[aj]]  # MV: c(i) = A(i,j) b(j)
        else:
            b = tensorA.num_dimensions - 2  # (B)M(B)M: C([bi*],i,k) = A([bi*],i,j) B({[bi*]},j,k)
            bb = 0 if tensorB.num_dimensions == 2 else b
            sizes = []
            for i in range(b):
                assert tensorA.extents[i] == tensorC.extents[i]
                assert bb == 0 or tensorA.extents[i] == tensorB.extents[i]
                sizes.append(tensorA.extents[i])
            assert tensorA.extents[b + ai] == tensorC.extents[b]
            assert tensorA.extents[b + aj] == tensorB.levels[bb + bi]
            assert tensorB.levels[bb + bj] == tensorC.extents[b + 1]
            sizes.append(tensorA.extents[b + ai])
            sizes.append(tensorA.extents[b + aj])
            sizes.append(tensorC.extents[b + 1])
        # Set grid and parameters.
        ti_grid_iter, endian = grid_iter
        grid_xyz = _populate_grid(tensorA, ti_grid_iter, sizes, stream_holder)
        params = _populate_data_parameters(tensorA)
        params.append(tensorB._val.data_ptr)
        params.append(tensorC._val.data_ptr)
        params.extend(sizes)
        for i in range(tensorA.num_levels):
            params.append(tensorA.levels[i])
        if backend == Backend.OMP:
            # For OMP, grid dimensions are passed as parameters
            params.extend(grid_xyz)
        return _compute_grid_block(grid_xyz, endian), params
