# Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

"""
This module defines C++ source code used by the UST.
"""

__all__ = []

prolog_decl = """
extern "C" __device__ CTP prolog_a(CTP);
extern "C" __device__ CTP prolog_b(CTP);
"""

prolog_a_impl = """
extern "C" __device__
CTP prolog_a(CTP a) {
    return a;
}
"""

prolog_b_impl = """
extern "C" __device__
CTP prolog_b(CTP b) {
    return b;
}
"""
