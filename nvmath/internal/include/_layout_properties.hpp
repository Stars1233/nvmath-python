// Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef NVMATH_LAYOUT_PROPS_HPP
#define NVMATH_LAYOUT_PROPS_HPP

#include <cstdint>

namespace nvmath_strided_layout {

using property_mask_t = unsigned int;

enum OrderFlag : int {
    ORDER_NONE = 0,
    ORDER_C = 1,
    ORDER_F = 2,
    ORDER_PERM = 3,
};

enum BooleanProperty : int {
    IS_CONTIGUOUS_C = 0,
    IS_ABS_DENSE_C,
    IS_LEADING_DENSE_C,
    IS_ABS_LEADING_DENSE_C,

    IS_CONTIGUOUS_F,
    IS_ABS_DENSE_F,
    IS_LEADING_DENSE_F,
    IS_ABS_LEADING_DENSE_F,

    IS_CONTIGUOUS_ANY,
    IS_ABS_DENSE_ANY,
    IS_LEADING_DENSE_ANY,
    IS_ABS_LEADING_DENSE_ANY,

    HAS_STRIDE_ORDER_C,
    HAS_STRIDE_ORDER_F,
    IS_UNIQUE,
    IS_EXHAUSTIVE,
    HAS_NO_NEGATIVE_STRIDE,

    _BOOLEAN_PROPERTY_COUNT,
};

enum Property : int {
    OFFSET_BOUNDS = _BOOLEAN_PROPERTY_COUNT,
    MEMORY_RANGE_SIZE,
    SHAPE,
    STRIDES,
    STRIDES_IN_BYTES,
    STRIDE_ORDER,
    UNIT_EXTENTS,
    VOLUME,
    MIN_MAX_STRIDE,
    _PROPERTY_COUNT,
};

static_assert(_PROPERTY_COUNT <= sizeof(property_mask_t) * 8, "property_mask_t is too small for the number of properties");

constexpr inline property_mask_t _flag(int prop) {
    return property_mask_t(1) << prop;
}

constexpr int _has_valid_property(property_mask_t has_props, int prop) {
    return (has_props & _flag(prop)) != 0;
}

constexpr void _mark_property_valid(property_mask_t& has_props, int prop) {
    has_props |= _flag(prop);
}

constexpr int _dense_prop(OrderFlag order_flag, int allow_negative_strides, int allow_leading_dim_stride) {
    int prop = 0;
    if (order_flag == ORDER_C) {
        prop = IS_CONTIGUOUS_C;
    } else if (order_flag == ORDER_F) {
        prop = IS_CONTIGUOUS_F;
    } else {
        prop = IS_CONTIGUOUS_ANY;
    }
    if (allow_negative_strides) {
        prop += IS_ABS_DENSE_C - IS_CONTIGUOUS_C;
    }
    if (allow_leading_dim_stride) {
        prop += IS_LEADING_DENSE_C - IS_CONTIGUOUS_C;
    }
    return prop;
}

// Workaround for constexpr std::array not being supported until C++17
template <typename T, size_t N>
struct _array {
    T data[N];

    constexpr T& operator[](size_t index) {
        return data[index];
    }

    constexpr const T& operator[](size_t index) const {
        return data[index];
    }

};


/* Given a list of pairs (prop_p, prop_q),
   meaning "prop_p implies prop_q",
   return an array of property masks such that
   implied[prop] = bitmask of all flags for all props (transitively) implied by prop.
   In particular, for every prop, implied[prop] & _flag(prop) != 0
   (i.e. the property is implied by itself).
   If is_true is false, returns the inverse implications, i.e.
   implied[prop] is the bitmask for all props that must be false if prop is false.
*/
template<bool is_true, int num_impls>
constexpr auto _implied_array(const std::pair<int, int> implications[num_impls]) {
    _array<property_mask_t, _BOOLEAN_PROPERTY_COUNT> implied = {0};
    for (int prop = 0; prop < _BOOLEAN_PROPERTY_COUNT; prop++) {
        implied[prop] = _flag(prop);
    }
    // fixpoint - repeat enough times to make sure the longest
    // possible transitive implication chain is covered
    for (int i = 0; i < _BOOLEAN_PROPERTY_COUNT; i++) {
        for (int j = 0; j < num_impls; j++) {
            int prop = implications[j].first;
            int implied_prop = implications[j].second;
            if (is_true) {
                // p -> q
                implied[prop] |= implied[implied_prop];
            } else {
                // not p -> not q
                implied[implied_prop] |= implied[prop];
            }
        }
    }
    return implied;
}

template<bool is_true>
constexpr property_mask_t _implied_props(int prop) {
    constexpr std::pair<int, int> implications[] = {
        // diamond implications: contig -> abs_dense, leading_dense -> abs_leading_dense
        {IS_CONTIGUOUS_C, IS_ABS_DENSE_C},
        {IS_CONTIGUOUS_C, IS_LEADING_DENSE_C},
        {IS_ABS_DENSE_C, IS_ABS_LEADING_DENSE_C},
        {IS_LEADING_DENSE_C, IS_ABS_LEADING_DENSE_C},

        {IS_CONTIGUOUS_F, IS_ABS_DENSE_F},
        {IS_CONTIGUOUS_F, IS_LEADING_DENSE_F},
        {IS_ABS_DENSE_F, IS_ABS_LEADING_DENSE_F},
        {IS_LEADING_DENSE_F, IS_ABS_LEADING_DENSE_F},

        {IS_CONTIGUOUS_ANY, IS_ABS_DENSE_ANY},
        {IS_CONTIGUOUS_ANY, IS_LEADING_DENSE_ANY},
        {IS_ABS_DENSE_ANY, IS_ABS_LEADING_DENSE_ANY},
        {IS_LEADING_DENSE_ANY, IS_ABS_LEADING_DENSE_ANY},

        // c -> any
        {IS_CONTIGUOUS_C, IS_CONTIGUOUS_ANY},
        {IS_ABS_DENSE_C, IS_ABS_DENSE_ANY},
        {IS_LEADING_DENSE_C, IS_LEADING_DENSE_ANY},
        {IS_ABS_LEADING_DENSE_C, IS_ABS_LEADING_DENSE_ANY},

        // f -> any
        {IS_CONTIGUOUS_F, IS_CONTIGUOUS_ANY},
        {IS_ABS_DENSE_F, IS_ABS_DENSE_ANY},
        {IS_LEADING_DENSE_F, IS_LEADING_DENSE_ANY},
        {IS_ABS_LEADING_DENSE_F, IS_ABS_LEADING_DENSE_ANY},

        // weakest dense in c/f order -> has_stride_order_c/f
        {IS_ABS_LEADING_DENSE_C, HAS_STRIDE_ORDER_C},
        {IS_ABS_LEADING_DENSE_F, HAS_STRIDE_ORDER_F},

        // leading dense in any order -> has_no_negative_stride
        {IS_LEADING_DENSE_ANY, HAS_NO_NEGATIVE_STRIDE},

        // being dense in any sense in any order -> is_unique
        // abs_leading_dense is the weakest dense, all other
        // will imply is_unique transitively.
        {IS_ABS_LEADING_DENSE_ANY, IS_UNIQUE},

        // any abs_dense -> is_exhaustive
        {IS_ABS_DENSE_ANY, IS_EXHAUSTIVE},
    };

    constexpr int num_impls = sizeof(implications) / sizeof(implications[0]);
    constexpr auto true_implied = _implied_array<true, num_impls>(implications);
    constexpr auto false_implied = _implied_array<false, num_impls>(implications);

    if (is_true) {
        return true_implied[prop];
    } else {
        return false_implied[prop];
    }
}

// Some checks on the transitivity and the compile-time computation
// is_contiguous_c -> is_unique
static_assert(_implied_props<true>(IS_CONTIGUOUS_C) & _flag(IS_UNIQUE));
// is_contiguous_c -> is_exhaustive
static_assert(_implied_props<true>(IS_CONTIGUOUS_C) & _flag(IS_EXHAUSTIVE));
// not is_exhaustive -> not is_contiguous_c
static_assert(_implied_props<false>(IS_EXHAUSTIVE) & _flag(IS_CONTIGUOUS_C));
// not is_unique -> not is_contiguous_f
static_assert(_implied_props<false>(IS_UNIQUE) & _flag(IS_CONTIGUOUS_F));
// not (is_contiguous_c -> is_contiguous_f)
static_assert(!(_implied_props<true>(IS_CONTIGUOUS_C) & _flag(IS_CONTIGUOUS_F)));
// not has_no_negative_stride -> not is_contiguous_c
static_assert(_implied_props<false>(HAS_NO_NEGATIVE_STRIDE) & _flag(IS_CONTIGUOUS_C));

constexpr int _boolean_property(property_mask_t bool_props, int prop) {
    return (bool_props & _flag(prop)) != 0;
}

constexpr void _set_boolean_property(property_mask_t& has_props, property_mask_t& bool_props, int prop, int value) {
    property_mask_t mask = value ? _implied_props<true>(prop) : _implied_props<false>(prop);
    if (value) {
        bool_props |= mask;
    } else {
        bool_props &= ~mask;
    }
    has_props |= mask;
}

} // namespace nvmath_strided_layout

#endif // NVMATH_LAYOUT_PROPS_HPP
