// Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef NVMATH_LAYOUT_HPP
#define NVMATH_LAYOUT_HPP

#include <algorithm>
#include <cmath>
#include <numeric>
#include <vector>
#include <bitset>
#include <cstdint>

#define STRIDED_LAYOUT_MAX_NDIM 64
#define STRIDED_LAYOUT_AXES_MASK_ALL 0xFFFFFFFFFFFFFFFFULL

namespace nvmath_strided_layout {

typedef uint64_t axes_mask_t;
static_assert(sizeof(axes_mask_t) * 8 == STRIDED_LAYOUT_MAX_NDIM, "axes_mask_t must be exactly STRIDED_LAYOUT_MAX_NDIM bits wide");
typedef int64_t extent_t;
typedef int64_t stride_t;
typedef int32_t axis_t;
typedef std::vector<stride_t> extents_strides_mem_t;
typedef std::vector<axis_t> axis_vec_t;

template <typename T>
void _swap(T &a, T &b) noexcept { std::swap(a, b); }

inline void _order_from_strides(axis_vec_t &indices, const extent_t *shape,
                                const stride_t *strides, int ndim)
{
    indices.resize(ndim);
    std::iota(indices.begin(), indices.end(), 0);
    if (!strides)
    {
        return;
    }
    std::sort(indices.begin(), indices.end(), [&strides, &shape](int i, int j)
              {
    const auto stride_i = std::abs(strides[i]);
    const auto stride_j = std::abs(strides[j]);
    if (stride_i != stride_j) {
      return stride_i > stride_j;
    }
    const auto shape_i = shape[i];
    const auto shape_j = shape[j];
    if (stride_i != 0 && shape_i != shape_j) {
      return shape_i > shape_j;
    }
    return i < j; });
}

inline int _popcount(axes_mask_t x) {
  return std::bitset<sizeof(axes_mask_t) * 8>(x).count();
}

} // namespace nvmath_strided_layout

#endif // NVMATH_LAYOUT_HPP
