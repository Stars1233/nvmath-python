# Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# SPDX-License-Identifier: Apache-2.0

import logging
import math
import os
import random
from io import StringIO

import cuda.core as cc
import pytest
from cuda.core import system
from nvmath.internal._bindings import get_driver_version, get_runtime_version
from packaging.version import Version

from nvmath.internal.memory import get_pinned_async_memory_resource
from nvmath.internal.ndbuffer import NDBuffer, StridedLayout

from .helpers import (
    _SL,
    DummyDeviceMemoryResource,
    DummyHostMemoryResource,
    DummyPinnedMemoryResource,
    Param,
    almost_equal_strides,
    arange,
    array_ptr,
    as_array,
    as_cp_array,
    as_ndbuffer,
    assert_equal,
    cp,
    create_stream,
    device_ctx,
    free_memory,
    idfn,
    mem_locations_from_direction,
    np,
    package,
    random_negated_strides,
    random_non_empty_slice,
    random_permutations,
    stream_ctx,
    zeros,
)

num_devices = system.get_num_devices()


try:
    import cupyx as cpx
except ImportError:
    cpx = None


has_old_numpy = Version(np.__version__) < Version("2.0.0")
has_old_cupy = cp is not None and Version(cp.__version__) < Version("14.0.0")
np_max_ndim = 32 if has_old_numpy or has_old_cupy else 64


def _has_pinned_memory_resource():
    if Version(cc.__version__) < Version("0.5.0"):
        return False
    pool_disable_flag = os.environ.get("NVMATH_DISABLE_PINNED_MEMORY_POOL")
    if pool_disable_flag and pool_disable_flag.lower()[:1] not in ["0", "f"]:
        return False
    return get_runtime_version() >= 12060 and get_driver_version() >= 12060


has_pinned_memory_resource = _has_pinned_memory_resource()


def _shuffled(rng, x):
    x = list(x)
    rng.shuffle(x)
    return x


def _shape(rng, ndim):
    if ndim <= 9:
        return tuple(range(2, 2 + ndim))
    else:
        non_ones = rng.sample(list(range(ndim)), min(20, ndim))
        shape = [1] * ndim
        for i in non_ones:
            shape[i] = 2
        return tuple(shape)


def _zero_vol_shape(rng, ndim):
    shape = [0] * ndim
    num_non_zero = rng.randint(max(0, ndim - 2), ndim - 1)
    non_zero_indices = rng.sample(range(ndim), num_non_zero)
    for i in non_zero_indices:
        shape[i] = rng.randint(1, 2 ** (63 // ndim))
    assert math.prod(shape) == 0
    return tuple(shape)


def _skip(device_id):
    if device_id == "cpu":
        return
    if cp is None:
        pytest.skip("Cupy is required to run this test")
    if device_id >= num_devices:
        pytest.skip(f"Test requires at least {device_id + 1} gpus")


py_rng = random.Random(42)

_dtype_names = [
    "int8",
    "uint8",
    "int16",
    "uint16",
    "int32",
    "uint32",
    "float32",
    "float64",
    "complex64",
    "complex128",
]

_dtypes = [np.dtype(name) for name in _dtype_names]
dtype_and_names = _dtype_names + _dtypes


def test_size_overflow():
    with pytest.raises(OverflowError):
        NDBuffer.empty((2**31, 2**29, 13), dtype="int8", device_id=0)
    with pytest.raises(OverflowError):
        NDBuffer.empty((2**31, 2**29, 3), dtype="float32", device_id=0)


def test_unsupported_ndim():
    with pytest.raises(ValueError, match="Max supported ndim is 64"):
        NDBuffer.empty((1,) * 65, dtype="int8", device_id="cpu")


@pytest.mark.parametrize(
    (
        "shape_a",
        "shape_b",
        "dtype",
    ),
    [
        (
            Param("shape_a", shape_a),
            Param("shape_b", shape_b),
            Param("dtype", dtype),
        )
        for shape_a, shape_b in [
            ((1, 2, 3), (1, 3, 2)),
            ((4,), (1, 1, 1, 1, 1, 1, 2, 3, 1, 1, 1, 1, 1, 1)),
        ]
        for dtype in [py_rng.choice(dtype_and_names)]
    ],
    ids=idfn,
)
def test_mismatched_shape(shape_a, shape_b, dtype):
    device_id = 0
    _skip(device_id)
    stream_holder = create_stream(device_id)
    shape_a = shape_a.value
    shape_b = shape_b.value
    dtype = dtype.value
    a = zeros("cpu", None, shape_a, dtype)
    b = zeros(device_id, stream_holder, shape_b, dtype)
    aw = as_ndbuffer(a)
    bw = as_ndbuffer(b)
    msg = "Shapes cannot be broadcast together"
    with device_ctx(device_id):
        with pytest.raises(ValueError, match=msg):
            bw.copy_(aw, stream=stream_holder)
        with pytest.raises(ValueError, match=msg):
            aw.copy_(bw, stream=stream_holder)


@pytest.mark.parametrize(
    (
        "shape",
        "itemsize",
        "dtype",
        "msg",
    ),
    [
        (
            Param("shape", shape),
            Param("itemsize", itemsize),
            Param("dtype", dtype),
            Param("msg", msg),
        )
        for shape, dtype, itemsize, msg in [
            ((1, -2, 3), np.int8, None, "Extents must be non-negative"),
            ((4,), "float32", 8, "itemsize of the dtype and the layout must match"),
            ((4,), "some_type", -2, "The itemsize must be positive"),
            ((4,), "some_type", 3, "The itemsize must be a power of two"),
        ]
    ],
    ids=idfn,
)
def test_invalid_shape_or_itemsize(shape, itemsize, dtype, msg):
    shape = shape.value
    itemsize = itemsize.value
    dtype = dtype.value
    msg = msg.value
    device_id = 0
    _skip(device_id)
    stream_holder = create_stream(device_id)
    with device_ctx(device_id), pytest.raises(ValueError, match=msg):
        if itemsize is None:
            NDBuffer.empty(shape, dtype=dtype, device_id=device_id, stream=stream_holder)
        else:
            layout = StridedLayout.dense(shape, itemsize)
            NDBuffer.empty(layout, dtype=dtype, device_id=device_id, stream=stream_holder)


def test_mismatched_dtype():
    device_id = 0
    _skip(device_id)
    stream_holder = create_stream(device_id)
    a = zeros("cpu", None, (1, 2, 3), np.int32)
    b = zeros(device_id, stream_holder, (1, 2, 3), np.int64)
    aw = NDBuffer.from_numpy(a)
    bw = NDBuffer.from_cupy(b)
    msg = "The data types of the source and destination buffers must match"
    with device_ctx(device_id):
        with pytest.raises(ValueError, match=msg):
            bw.copy_(aw, stream=stream_holder)
        with pytest.raises(ValueError, match=msg):
            aw.copy_(bw, stream=stream_holder)


@pytest.mark.parametrize("device_id", ["cpu", 0])
def test_from_data(device_id):
    _skip(device_id)
    xp = np if device_id == "cpu" else cp
    a = xp.arange(5 * 7, dtype=np.complex64).reshape(5, 7)[1:, ::-2]

    if device_id == "cpu":
        ndbuf = NDBuffer.from_numpy(a)
    else:
        ndbuf = NDBuffer.from_cupy(a)

    layout = StridedLayout(a.shape, a.strides, a.dtype.itemsize, divide_strides=True)
    ndbuf_from_data = NDBuffer.from_data(layout, a, array_ptr(a), a.dtype, device_id)

    assert ndbuf.size == ndbuf_from_data.size == a.size == 16
    assert ndbuf.data_ptr == ndbuf_from_data.data_ptr == array_ptr(a)
    assert ndbuf.shape == ndbuf_from_data.shape == a.shape
    assert ndbuf.strides_in_bytes == ndbuf_from_data.strides_in_bytes == a.strides

    assert_equal(as_array(ndbuf), a)
    assert_equal(as_array(ndbuf_from_data), a)


@pytest.mark.parametrize(
    (
        "ndim",
        "device_id",
        "dtype",
        "shape",
    ),
    [
        (
            Param("ndim", ndim),
            Param("device_id", device_id),
            Param("dtype", dtype),
            Param("shape", shape),
        )
        for ndim in [1, 2, 3, 4, 5, 31, 64]
        if ndim <= np_max_ndim
        for device_id in ["cpu", 0, 1]
        for dtype in [py_rng.choice(dtype_and_names)]
        for shape in [_zero_vol_shape(py_rng, ndim)]
    ],
    ids=idfn,
)
def test_zero_vol_tensor(ndim, shape, device_id, dtype):
    ndim = ndim.value
    shape = shape.value
    device_id = device_id.value
    dtype = dtype.value
    _skip(device_id)

    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        ndbuffer = NDBuffer.empty(shape, dtype, device_id, stream=stream_holder)
    assert ndbuffer.shape == shape
    assert ndbuffer.strides == tuple(0 for _ in range(ndim))
    assert ndbuffer.strides_in_bytes == tuple(0 for _ in range(ndim))
    assert ndbuffer.raw_memory_range_info == (0, 0, 0)
    assert ndbuffer.size == 0
    assert ndbuffer.device_id == device_id
    assert ndbuffer.data_ptr == 0

    a = zeros(device_id, stream_holder, shape, dtype)
    nda = as_ndbuffer(a)
    dst_device_id = 0 if device_id == "cpu" else "cpu"
    with device_ctx(dst_device_id):
        dst = NDBuffer.empty_like(nda, device_id=dst_device_id, stream=stream_holder)
    assert dst.shape == shape
    assert dst.strides_in_bytes == a.strides
    assert dst.raw_memory_range_info == (0, 0, 0)
    assert dst.size == 0
    assert dst.device_id == dst_device_id
    assert dst.data_ptr == 0

    # this should all be no-op, make sure nothing explodes
    nda.fill_(42, stream=stream_holder)
    ndbuffer.copy_(nda, stream=stream_holder)


@pytest.mark.parametrize(
    (
        "use_custom_alloc",
        "use_logging",
        "alloc_kind",
        "device",
        "dtype",
        "shape",
    ),
    [
        (
            Param("use_custom_alloc", use_custom_alloc),
            Param("use_logging", use_logging),
            Param("alloc_kind", alloc_kind),
            Param("device", device),
            Param("dtype", dtype),
            Param("shape", shape),
        )
        for use_custom_alloc in [False, True]
        for use_logging in [False, True]
        for alloc_kind in ["host", "pinned", "device"]
        if use_custom_alloc or alloc_kind != "pinned"
        for device in (["cpu"] if alloc_kind == "host" else [0, 1])
        for dtype in [py_rng.choice(dtype_and_names)]
        for shape in [_shape(py_rng, 3)]
    ],
    ids=idfn,
)
def test_allocators(use_custom_alloc, use_logging, alloc_kind, device, dtype, shape):
    use_custom_alloc = use_custom_alloc.value
    use_logging = use_logging.value
    alloc_kind = alloc_kind.value
    device = device.value
    dtype = dtype.value
    shape = shape.value

    _skip(device)

    if use_logging:
        logger_name = "ndbuffer_test_allocators"
        log_stream = StringIO()
        logger = logging.Logger(logger_name, level=logging.DEBUG)
        logger.addHandler(logging.StreamHandler(log_stream))
        logger.setLevel(logging.DEBUG)
    else:
        logger = None

    if not use_custom_alloc:
        memory_resource = None
    else:
        if alloc_kind == "host":
            memory_resource = DummyHostMemoryResource()
        elif alloc_kind == "pinned":
            memory_resource = DummyPinnedMemoryResource()
        elif alloc_kind == "device":
            memory_resource = DummyDeviceMemoryResource(device)
        else:
            raise ValueError(f"Invalid allocation kind: {alloc_kind}")

    np_dtype = np.dtype(dtype)
    itemsize = np_dtype.itemsize

    if use_custom_alloc:
        assert len(memory_resource.active_allocs) == 0

    stream_holder = None
    if alloc_kind != "host":
        stream_holder = create_stream(device)

    tensors = []
    device_id = device if alloc_kind == "device" else "cpu"

    for _ in range(2):
        with device_ctx(device_id):
            tensor = NDBuffer.empty(
                shape,
                dtype,
                device_id,
                stream=stream_holder,
                memory_resource=memory_resource,
                logger=logger,
            )
        assert tensor.device_id == device_id
        assert tensor.itemsize == itemsize
        assert tensor.shape == shape
        assert tensor.data_ptr != 0
        if use_custom_alloc:
            assert tensor.data_ptr in memory_resource.active_allocs
        tensors.append(tensor)
        tensor = None

    if memory_resource is not None:
        if stream_holder is None:
            assert len(memory_resource.seen_streams) == 0
        else:
            assert len(memory_resource.seen_streams) == 1
            assert int(stream_holder.obj.handle) in memory_resource.seen_streams

    # test doing something meaningful with the tensors
    with device_ctx(device):
        for i, tensor in enumerate(tensors):
            tensor.fill_(42 + i, stream=stream_holder)
            tensor = None

    if use_custom_alloc:
        assert len(memory_resource.active_allocs) == 2
        assert len(set(memory_resource.active_allocs)) == 2

    with device_ctx(device), stream_ctx(stream_holder):
        a = as_array(tensors[0])
        b = as_array(tensors[1])
        assert (a == 42).all()
        assert (b == 43).all()
        del a, b

    tensors.clear()

    if use_custom_alloc:
        assert len(memory_resource.active_allocs) == 0

    # we don't log default host allocations
    if use_logging and (use_custom_alloc or alloc_kind != "host"):
        log = log_stream.getvalue()
        assert log.count("allocate memory") == 2
        assert log.count("release memory") == 2


@pytest.mark.parametrize("device_id", [0, 1])
def test_pinned_pool_is_host_and_device_accessible(device_id):
    _skip(device_id)
    mr = get_pinned_async_memory_resource(device_id)
    for _ in range(2):
        assert mr is get_pinned_async_memory_resource(device_id)
    if not has_pinned_memory_resource:
        assert mr is None
        pytest.skip("Pinned memory pool is not supported")
    if device_id > 0:
        assert mr is not get_pinned_async_memory_resource(0)
    assert mr is not None
    assert mr.is_host_accessible
    assert mr.is_device_accessible
    dtype = np.int64
    with device_ctx(device_id):
        stream = create_stream(device_id)
        shape = (3, 1007)
        nprod = math.prod(shape)
        expected_sum = (nprod * (nprod - 1)) // 2
        ndbuf = NDBuffer.empty(shape, dtype, "cpu", stream=stream, memory_resource=mr)
        stream.obj.sync()
        ndbuf.fill_(424242, stream=stream)
        np_view = ndbuf.as_numpy()
        assert np.all(np_view == 424242)
        cp_view = as_cp_array(ndbuf, device_id)
        np_view.reshape(-1)[...] = np.arange(np.prod(np_view.shape), dtype=dtype)
        with stream_ctx(stream):
            assert cp_view.sum().item() == expected_sum
            cp_view += 1
            assert cp_view.sum().item() == expected_sum + nprod


def test_as_numpy():
    memory_resource = DummyHostMemoryResource()
    ndbuf = NDBuffer.empty((17, 13), "int32", "cpu", memory_resource=memory_resource)
    assert len(memory_resource.active_allocs) == 1
    assert ndbuf.data_ptr in memory_resource.active_allocs
    ndbuf[...] = 444
    a = ndbuf.as_numpy()
    assert array_ptr(a) == ndbuf.data_ptr
    del ndbuf
    assert len(memory_resource.active_allocs) == 1
    assert array_ptr(a) in memory_resource.active_allocs
    assert (a == 444).all()
    del a
    assert len(memory_resource.active_allocs) == 0


def test_unsupported_dtype():
    # Test we orderly reject numpy unsupported dtypes when using numpy
    layout = StridedLayout((10, 10), None, 4)
    ndbuf = NDBuffer.empty(layout, "complex32", "cpu")
    assert ndbuf.dtype_name == "complex32"
    assert ndbuf.dtype == "complex32"
    with pytest.raises(TypeError, match="complex32"):
        ndbuf.numpy_dtype  # noqa: B018

    with pytest.raises(TypeError, match="complex32"):
        ndbuf.as_numpy()

    layout = StridedLayout((10, 10), None, 4)
    ndbuf = NDBuffer.empty(layout, "complex32", "cpu")
    with pytest.raises(TypeError, match="complex32"):
        ndbuf[0, 0].item()

    layout = StridedLayout((10, 10), None, 4)
    ndbuf = NDBuffer.empty(layout, "complex32", "cpu")
    with pytest.raises(TypeError, match="complex32"):
        ndbuf.fill_(2 + 3j)

    # But it is still usable (you can allocate it, copy two ndbuffer of this type etc.)
    layout = StridedLayout((10, 10), None, 4)
    ndbuf = NDBuffer.empty(layout, "complex32", "cpu")
    # have another ndbuffer of this type
    ndbuf2 = NDBuffer.empty(2, "float16", "cpu")
    ndbuf2.fill_([2, 3])
    ndbuf2 = ndbuf2.repack("complex32", itemsize=4)
    # copy into ndbuf
    ndbuf.copy_(ndbuf2)
    # check the result
    a = ndbuf.repack("float16").as_numpy().astype("float32").view("complex64")
    assert (a == 2 + 3j).all()


@pytest.mark.parametrize(
    (
        "device_id",
        "shape",
        "slices",
        "expected_ndim",
        "dtype",
    ),
    [
        (
            Param("device_id", device_id),
            Param("shape", shape),
            Param("slices", slices),
            Param("expected_ndim", expected_ndim),
            Param("dtype", py_rng.choice(dtype_and_names)),
        )
        for device_id in ["cpu", 0, 1]
        for shape, slices, expected_ndim in [
            ((), None, 0),
            ((1,), None, 1),
            ((1, 1, 1), None, 3),
            ((1,) * 32, None, 32),
            ((1,) * 64, None, 64),
            ((2, 3, 4, 5), _SL[1, 0, 2, 3], 0),
            ((3, 4, 5), _SL[-1:, :1, 2:3], 3),
            ((3, 4, 5), _SL[-1:, 0, 2:3], 2),
        ]
        if len(shape) <= np_max_ndim
    ],
    ids=idfn,
)
def test_item(device_id, shape, slices, expected_ndim, dtype):
    device_id = device_id.value
    shape = shape.value
    slices = slices.value
    expected_ndim = expected_ndim.value
    dtype = dtype.value
    _skip(device_id)

    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        ndbuf = NDBuffer.empty(shape, dtype, device_id, stream=stream_holder)
    if slices is not None:
        ndbuf = ndbuf[slices]
    itemsize = np.dtype(dtype).itemsize
    with device_ctx(device_id):
        ndbuf.fill_(123 + itemsize, stream=stream_holder)
        assert ndbuf.shape == (1,) * expected_ndim
        assert ndbuf.ndim == expected_ndim
        assert ndbuf.itemsize == itemsize
        assert ndbuf.dtype_name == np.dtype(dtype).name
        assert ndbuf.item(stream=stream_holder) == np.array([123 + itemsize], dtype=dtype).item()


@pytest.mark.parametrize(
    ("device_id",),
    [(Param("device_id", device_id),) for device_id in ["cpu", 0, 1]],
    ids=idfn,
)
def test_item_invalid(device_id):
    device_id = device_id.value
    _skip(device_id)

    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        ndbuf = NDBuffer.empty((2, 3, 0, 4), "int32", device_id, stream=stream_holder)
        ndbuf.fill_(123, stream=stream_holder)
    with pytest.raises(ValueError, match="Python scalar"):
        ndbuf.item(stream=stream_holder)

    with device_ctx(device_id):
        ndbuf = NDBuffer.empty((2, 3, 4), "float32", device_id, stream=stream_holder)
        ndbuf.fill_(123, stream=stream_holder)
    with pytest.raises(ValueError, match="Python scalar"):
        ndbuf.item(stream=stream_holder)

    with device_ctx(device_id):
        ndbuf = NDBuffer.empty(StridedLayout.dense((), itemsize=4), "this_type_does_not_exist", device_id, stream=stream_holder)
    with pytest.raises(TypeError, match="this_type_does_not_exist"):
        ndbuf.item(stream=stream_holder)


@pytest.mark.parametrize(
    ("device_id", "dtype", "blocking"),
    [
        (Param("device_id", device_id), Param("dtype", dtype), Param("blocking", blocking))
        for device_id in ["cpu", 0, 1]
        for dtype in ["int8", "float32", "int64", "complex128"]
        for blocking in [True, False]
    ],
    ids=idfn,
)
def test_fill(device_id, dtype, blocking):
    device_id = device_id.value
    dtype = dtype.value
    blocking = blocking.value
    _skip(device_id)

    logger_name = "ndbuffer_test_fill"
    log_stream = StringIO()
    logger = logging.Logger(logger_name, level=logging.DEBUG)
    logger.addHandler(logging.StreamHandler(log_stream))
    logger.setLevel(logging.DEBUG)
    stream_holder = create_stream(device_id)
    shape = (1024, 1024)
    scalar = 123 if "complex" not in dtype else 123 + 55j
    with device_ctx(device_id):
        ndbuf = NDBuffer.empty(shape, dtype, device_id, stream=stream_holder)
        ndbuf.fill_(scalar, stream=stream_holder, logger=logger, blocking=blocking)
        arr_view = as_array(ndbuf)
        with stream_ctx(stream_holder):
            assert (arr_view == scalar).all()
    log = log_stream.getvalue()

    if device_id != "cpu":
        itemsize = np.dtype(dtype).itemsize
        volume = math.prod(shape)
        if itemsize <= 4:
            assert f"The src is a single scalar, dispatching to cuMemsetD{itemsize * 8}." in log
            assert f"Memset {volume} elements on stream {stream_holder.ptr}" in log
            assert "copy kernel" not in log
            assert "Memcpy" not in log
        else:
            assert f"Memcpy of {itemsize} bytes on stream {stream_holder.ptr}" in log
            assert "Memset" not in log
        if blocking:
            assert f"Sync stream {stream_holder.ptr}" in log
        elif has_pinned_memory_resource:
            assert "Sync stream" not in log


@pytest.mark.parametrize(
    (
        "base_size",
        "device_id",
        "dtype",
    ),
    [
        (
            Param("base_size", base_size),
            Param("device_id", device_id),
            Param("dtype", dtype),
        )
        for base_size in [0, 1, 513, 1537, 2**20 + 1]
        for device_id in [0, 1]
        for dtype in [py_rng.choice(dtype_and_names)]
    ],
    ids=idfn,
)
def test_default_device_allocation_size(base_size, device_id, dtype):
    device_id = device_id.value
    dtype = dtype.value
    base_size = base_size.value
    _skip(device_id)
    stream_holder = create_stream(device_id)
    itemsize = np.dtype(dtype).itemsize
    additional_sizes = 512 // itemsize + 1
    for i in range(additional_sizes):
        size = base_size + i
        shape = (size,)
        with device_ctx(device_id):
            ndbuffer = NDBuffer.empty(shape, dtype, device_id, stream=stream_holder)
        size_in_bytes = size * itemsize
        assert ndbuffer.shape == shape
        assert ndbuffer.strides == ((0,) if size == 0 else (1,))
        assert ndbuffer.strides_in_bytes == ((0,) if size == 0 else (itemsize,))
        assert ndbuffer.raw_memory_range_info[1] == size_in_bytes
        assert ndbuffer.size == size
        assert ndbuffer.device_id == device_id

        rounded_size_in_bytes = (size_in_bytes + 511) // 512 * 512
        assert rounded_size_in_bytes >= size_in_bytes, f"{rounded_size_in_bytes} < {size_in_bytes}"
        if size_in_bytes % 512 == 0:
            rounded_size_in_bytes = size_in_bytes

        if size == 0:
            assert ndbuffer.data is None
            assert ndbuffer.data_ptr == 0
        else:
            assert ndbuffer.data.size == rounded_size_in_bytes, f"{ndbuffer.data.size} != {rounded_size_in_bytes}"
            assert ndbuffer.data_ptr != 0

        b = np.arange(size, dtype=dtype)
        with device_ctx(device_id):
            ndbuffer.copy_(NDBuffer.from_numpy(b), stream=stream_holder)
            assert_equal(cp.asnumpy(as_array(ndbuffer)), b)


def _nd_reshape(ndbuf, new_shape, pass_tuple, use_view):
    reshape_fn = ndbuf.reshape if use_view else ndbuf.view
    if pass_tuple:
        return reshape_fn(new_shape)
    elif len(new_shape) == 1:
        return reshape_fn(new_shape[0])
    else:
        return reshape_fn(list(new_shape))


@pytest.mark.parametrize(
    (
        "shape",
        "slices",
        "new_shape",
        "permutation",
        "allowed",
        "device_id",
        "dtype",
        "pass_tuple",
        "use_view",
    ),
    [
        (
            Param("shape", shape),
            Param("slices", slices),
            Param("new_shape", new_shape),
            Param("permutation", permutation),
            Param("allowed", allowed),
            Param("device_id", device_id),
            Param("dtype", py_rng.choice(dtype_and_names)),
            Param("pass_tuple", py_rng.choice([True, False])),
            Param("use_view", py_rng.choice([True, False])),
        )
        for shape, slices, new_shape, permutation, allowed in [
            ((12,), _SL[:], (12,), (0,), True),
            ((12,), _SL[:], (13,), (0,), False),
            ((0,), _SL[:], (0,), (0,), True),
            ((0,), _SL[:], (1, 3), (0,), False),
            ((3,), _SL[3:], (3,), (0,), False),
            ((3,), _SL[3:], (0,), (0,), True),
            ((3, 0, 3), _SL[:], (2, 3, 4, 5, 6, 7, 0, 12), (0, 1, 2), True),
            ((3, 0, 3), _SL[:], (0,), (0, 1, 2), True),
            ((18,), _SL[:], (0,), (0,), False),
            ((12,), _SL[:], (2, 3, 2), (0,), True),
            ((12,), _SL[:], (2, 6), (0,), True),
            ((12,), _SL[:], (4, 3), (0,), True),
            ((12,), _SL[:], (3, 4), (0,), True),
            ((7, 12), _SL[:, :], (7, 12), (0, 1), True),
            ((12, 11), _SL[:, :], (2, 3, 2, 11), (0, 1), True),
            ((5, 12), _SL[:, :], (5, 2, 6), (0, 1), True),
            ((12, 7), _SL[:, :], (4, 3, 7), (0, 1), True),
            ((7, 12), _SL[:, :], (7, 3, 4), (0, 1), True),
            ((7, 12), _SL[:, :], (3, 4, 7), (0, 1), True),
            ((2, 3, 2), _SL[:, :, :], (12,), (0, 1, 2), True),
            ((2, 3, 2), _SL[:, :, :], (6, 2), (0, 1, 2), True),
            ((2, 3, 2), _SL[:, :, :], (2, 3, 2), (1, 2, 0), True),
            ((2, 3, 2), _SL[:, :, :], (6, 2), (1, 2, 0), True),
            ((2, 3, 2), _SL[:, :, :], (2, 6), (1, 2, 0), False),
            ((2, 3, 2), _SL[:, :, :], (12,), (1, 2, 0), False),
            ((2, 3, 2), _SL[:, :, :], (3, 2, 2), (1, 0, 2), True),
            ((10, 10, 10), _SL[::-1, ::-1, :], (10, 10, 10), (0, 1, 2), True),
            ((10, 10, 10), _SL[::-1, ::-1, :], (100, 10), (0, 1, 2), True),
            ((10, 10, 10), _SL[::-1, ::-1, ::-1], (1000,), (0, 1, 2), True),
            ((10, 10, 10), _SL[:, :, ::-1], (100, 10), (0, 1, 2), True),
            ((10, 10, 10), _SL[:, :, ::-1], (10, 100), (0, 1, 2), False),
            ((10, 10, 10), _SL[::-1, :, ::-1], (1000,), (0, 1, 2), False),
            ((10, 10, 10), _SL[::-1, ::-1, :], (100, 10), (1, 0, 2), False),
            ((10, 10, 10), _SL[::-1, ::-1, :], (10, 100), (0, 1, 2), False),
            ((5, 3), _SL[:-1, :], (12,), (0, 1), True),
            ((13, 3), _SL[1:, :], (6, 6), (0, 1), True),
            ((12, 4), _SL[:, :-1], (6, 2, 3), (0, 1), True),
            ((12, 4), _SL[:, :-1], (6, 6), (0, 1), False),
        ]
        for device_id in ["cpu", 0]
    ],
    ids=idfn,
)
def test_reshape(shape, slices, new_shape, permutation, allowed, device_id, dtype, pass_tuple, use_view):
    shape = shape.value
    slices = slices.value
    new_shape = new_shape.value
    permutation = permutation.value
    allowed = allowed.value
    device_id = device_id.value
    dtype = dtype.value
    pass_tuple = pass_tuple.value
    use_view = use_view.value
    _skip(device_id)
    stream_holder = create_stream(device_id)

    ref = arange(device_id, stream_holder, math.prod(shape), dtype).reshape(shape)
    ref = ref[slices]
    ref = ref.transpose(permutation)
    with device_ctx(device_id):
        ndbuf = NDBuffer.empty(shape, dtype, device_id, stream=stream_holder)
    ndbuf = ndbuf[slices]
    ndbuf = ndbuf.permute(permutation)
    assert ndbuf.shape == ref.shape
    vol = ref.size
    assert ndbuf.size == vol
    if vol == 0:
        assert ndbuf.strides == ndbuf.strides_in_bytes == (0,) * ndbuf.ndim
    else:
        assert almost_equal_strides(ndbuf.shape, ndbuf.strides_in_bytes, ref.strides)
    assert ndbuf.dtype_name == ref.dtype.name
    assert ndbuf.device_id == device_id
    assert vol == 0 or ndbuf.data_ptr != array_ptr(ref)

    if not allowed:
        if math.prod(new_shape) != math.prod(ref.shape):
            msg = "The original volume \\d+ and the new volume \\d+ must be equal"
        else:
            msg = "Layout strides are incompatible with the new shape"
        with pytest.raises(ValueError, match=msg):
            _nd_reshape(ndbuf, new_shape, pass_tuple, use_view)
        return

    ndbuf = _nd_reshape(ndbuf, new_shape, pass_tuple, use_view)
    ref = ref.reshape(new_shape)
    assert ndbuf.shape == ref.shape
    if vol == 0:
        assert ndbuf.strides == ndbuf.strides_in_bytes == (0,) * ndbuf.ndim
    else:
        assert almost_equal_strides(ndbuf.shape, ndbuf.strides_in_bytes, ref.strides)
    with device_ctx(device_id), stream_ctx(stream_holder):
        ndbuf.copy_(as_ndbuffer(ref), stream=stream_holder)
        assert_equal(as_array(ndbuf), ref)


@pytest.mark.parametrize(
    (
        "device_id",
        "shape",
    ),
    [
        (
            Param("device_id", device_id),
            Param("shape", shape),
        )
        for device_id in ["cpu", 0]
        for shape in [(3, 5, 4), (3, 5, 2)]
    ],
    ids=idfn,
)
def test_repacked_view(device_id, shape):
    device_id = device_id.value
    shape = shape.value
    _skip(device_id)
    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        nd_float = NDBuffer.empty(shape, "float32", device_id=device_id, stream=stream_holder)
    assert nd_float.dtype_name == nd_float.dtype == "float32"
    assert nd_float.numpy_dtype == np.dtype("float32")
    ref_float = arange(device_id, stream_holder, math.prod(shape), "float32").reshape(shape)
    nd_float.copy_(as_ndbuffer(ref_float), stream=stream_holder)
    nd_complex = nd_float.view("complex64")
    assert nd_complex.dtype_name == nd_complex.dtype == "complex64"
    assert nd_complex.numpy_dtype == np.dtype("complex64")
    ref_complex = ref_float.view("complex64")
    assert nd_complex.shape == ref_complex.shape
    assert nd_complex.strides_in_bytes == ref_complex.strides
    assert nd_complex.dtype_name == ref_complex.dtype.name
    with stream_ctx(stream_holder):
        assert_equal(as_array(nd_complex), ref_complex)

    nd_float = nd_complex.view("float32")
    ref_float = ref_complex.view("float32")
    assert nd_float.shape == ref_float.shape
    assert nd_float.strides_in_bytes == ref_float.strides
    assert nd_float.dtype_name == ref_float.dtype.name
    with stream_ctx(stream_holder):
        assert_equal(as_array(nd_float), ref_float)


def test_as_strided_repack():
    device_id = 0
    _skip(device_id)
    stream_holder = create_stream(device_id)
    layout = StridedLayout.dense((10, 5), itemsize=4, stride_order="F")
    with device_ctx(device_id):
        ndbuf = NDBuffer.empty(layout, "float32", device_id=device_id, stream=stream_holder)
    ref = arange(device_id, stream_holder, math.prod(layout.shape), "float32").reshape(layout.shape, order="F")

    with device_ctx(device_id):
        ndbuf.copy_(as_ndbuffer(ref), stream=stream_holder)
    with pytest.raises(ValueError, match="must be 1"):
        ndbuf.repack("complex64")
    with pytest.raises(ValueError, match="the last axis"):
        ref.view("complex64")
    ndbuf_complex = ndbuf.repack("complex64", axis=0)
    assert ndbuf_complex.shape == (5, 5)
    assert ndbuf_complex.strides == (1, 5)
    assert ndbuf_complex.dtype_name == "complex64"
    assert ndbuf_complex.itemsize == 8
    ref_complex = ref.transpose(1, 0).view("complex64").transpose(1, 0)
    with stream_ctx(stream_holder):
        assert_equal(as_array(ndbuf_complex), ref_complex)

    with pytest.raises(ValueError, match="must be 1"):
        ndbuf = ndbuf_complex.repack(np.float32)
    ndbuf = ndbuf_complex.repack(np.float32, axis=0)
    assert ndbuf.shape == (10, 5)
    assert ndbuf.strides == (1, 10)
    assert ndbuf.dtype_name == "float32"
    assert ndbuf.itemsize == 4
    with stream_ctx(stream_holder):
        assert_equal(as_array(ndbuf), ref)

    complex_slice = ndbuf_complex[::2]
    assert complex_slice.shape == (3, 5)
    assert complex_slice.strides == (2, 5)
    # None of the axis has stride 1, we cannot simply repack it
    with pytest.raises(ValueError, match="must be 1"):
        ndbuf = complex_slice.repack(np.float32, axis=0)
    # But StridedLayout has extra option to add the new dimension
    layout_unpacked = complex_slice.layout.unpacked(4, axis=0, add_dim=True)
    assert layout_unpacked.shape == (2, 3, 5)
    assert layout_unpacked.strides == (1, 4, 10)
    ndbuf = complex_slice.as_strided(layout_unpacked, np.float32)
    with stream_ctx(stream_holder):
        assert_equal(as_array(ndbuf), ref.reshape(5, 2, 5)[::2].transpose(1, 0, 2))


def test_non_tuple_shape_strides():
    device_id = 0
    _skip(device_id)

    layout = StridedLayout([5, 4], [4, 1], 4)
    layout2 = StridedLayout([5, 4], None, 4)
    layout3 = StridedLayout((i for i in [5, 4]), (i for i in [4, 1]), 4)
    assert layout.shape == layout2.shape == layout3.shape == (5, 4)
    assert layout.strides == layout2.strides == layout3.strides == (4, 1)
    assert layout == layout2 == layout3

    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        base = NDBuffer.empty(10, "float32", device_id=device_id, stream=stream_holder)
    assert base.shape == (10,)
    assert base.strides == (1,)
    assert base.strides_in_bytes == (4,)

    ndbuf_2d = base.reshape([2, 5])
    assert ndbuf_2d.shape == (2, 5)
    assert ndbuf_2d.strides == (5, 1)
    assert ndbuf_2d.strides_in_bytes == (20, 4)
    assert ndbuf_2d.size == 10
    assert ndbuf_2d.base is base

    for new_shape in (10, -1):
        ndbuf_flat = ndbuf_2d.reshape(new_shape)
        assert ndbuf_flat.shape == (10,)
        assert ndbuf_flat.strides == (1,)
        assert ndbuf_flat.strides_in_bytes == (4,)
        assert ndbuf_flat.size == 10
        assert ndbuf_flat.base is base

    scalar = base[3]
    for new_shape in (70, [70], (70,)):
        scalar = scalar.broadcast_to(new_shape)
        assert scalar.shape == (70,)
        assert scalar.strides == (0,)
        assert scalar.strides_in_bytes == (0,)
        assert scalar.size == 70
        assert scalar.base is base

    with device_ctx(device_id):
        base = NDBuffer.empty([2, 3], "float32", device_id=device_id, stream=stream_holder)
    assert base.shape == (2, 3)
    assert base.strides == (3, 1)
    assert base.strides_in_bytes == (12, 4)
    assert base.size == 6
    assert base.base is None


def test_sliced_with_as_strided():
    a = arange("cpu", None, 12, "float32")
    ndbuf = NDBuffer.from_numpy(a)
    ref = a.reshape(3, -1).view(np.complex64)[..., ::-1]
    view = ndbuf.reshape((3, -1)).view(np.complex64)[..., ::-1]
    assert view.shape == ref.shape
    assert view.strides_in_bytes == ref.strides
    assert view.size == ref.size
    assert view.base is ndbuf
    assert_equal(view.as_numpy(), ref)
    offset_in_bytes = ref.ctypes.data - a.ctypes.data

    sliced_layout = StridedLayout((3, 4), None, itemsize=4).packed(itemsize=8)[..., ::-1]
    assert sliced_layout.slice_offset_in_bytes == offset_in_bytes

    view2 = ndbuf.as_strided(sliced_layout.layout, np.complex64, offset_in_bytes=offset_in_bytes)
    assert view2.shape == ref.shape
    assert view2.strides_in_bytes == ref.strides
    assert view2.size == ref.size
    assert view2.base is ndbuf
    assert_equal(view2.as_numpy(), ref)
    assert view2.layout == view.layout


def test_as_strided_bounds_check():
    a = arange("cpu", None, 7, "float32")
    view = NDBuffer.from_numpy(a)
    narrow_view = view[3:-2]
    assert narrow_view.base is view
    assert narrow_view.shape == (2,)
    assert_equal(narrow_view.as_numpy(), a[3:-2])
    assert narrow_view.layout == StridedLayout.dense(2, itemsize=4)

    wider_layout = StridedLayout.dense(5, itemsize=4)
    with pytest.raises(ValueError, match="layout is incompatible"):
        # we moved 3 elements from the start, viewing 5 elements would exceed the
        # original 7 elements
        narrow_view.as_strided(wider_layout)

    # but if we move back 1 element, it's fine
    wider_view = narrow_view.as_strided(wider_layout, offset_in_bytes=-4)
    assert_equal(wider_view.as_numpy(), a[2:])

    narrow_view2 = NDBuffer.from_numpy(a[3:-2])
    # This won't work if we don't know the base
    assert narrow_view2.base is None
    with pytest.raises(ValueError, match="layout is incompatible"):
        narrow_view2.as_strided(wider_layout, offset_in_bytes=-4)

    # For that we need to disable the bounds check
    wider_view2 = narrow_view2.as_strided(wider_layout, offset_in_bytes=-4, check_bounds=False)
    assert_equal(wider_view2.as_numpy(), a[2:])

    a_float = arange("cpu", None, 5, "float32")
    with pytest.raises(ValueError, match="must be aligned"):
        NDBuffer.from_numpy(a_float[1:]).view(np.complex64)
    with pytest.raises(ValueError, match="must be aligned"):
        layout_complex = StridedLayout.dense(2, itemsize=8)
        NDBuffer.from_numpy(a_float[1:]).as_strided(layout_complex, np.complex64)
    with pytest.raises(ValueError, match="must be aligned"):
        layout_complex = StridedLayout.dense(2, itemsize=8)
        NDBuffer.from_numpy(a_float).as_strided(layout_complex, np.complex64, offset_in_bytes=4)


@pytest.mark.parametrize(
    ("axis",),
    [(Param("axis", axis),) for axis in [0, 1, 2, 3, 4, (0, 2), [2, 4], (0, 4), [0, 1, 2], (0, 2, 4)]],
    ids=idfn,
)
def test_squeeze_unsqueeze(axis):
    """
    We test it thoroughly in the layout tests and this is very thin wrapper
    around the layout methods, so just a quick check here.
    """
    axis = axis.value
    shape = (1, 2, 1, 3, 1)
    ndbuf = NDBuffer.empty(shape, "float32", device_id="cpu")
    assert ndbuf.shape == shape
    axis_tuple = (axis,) if isinstance(axis, int) else tuple(axis)
    expected_shape = tuple(shape[i] for i, e in enumerate(shape) if e != 1 or i not in axis_tuple)
    mask = 0
    for i in axis_tuple:
        mask |= 1 << i
    squeezed = ndbuf.squeeze(axis)
    squeezed2 = ndbuf.squeeze(mask=mask)
    for s in [squeezed, squeezed2]:
        assert s.shape == expected_shape
        if expected_shape != shape:
            assert s.base is ndbuf
        else:
            assert s.base is None
            assert s is ndbuf

    totally_squeezed = squeezed.squeeze()
    assert totally_squeezed.shape == (2, 3)
    assert totally_squeezed.base is ndbuf

    unit_extents_mask = ndbuf.layout.unit_extents_mask()
    assert unit_extents_mask == 1 + 4 + 16
    squeezed_mask = unit_extents_mask & mask
    true_axis = tuple(i for i in range(len(shape)) if (1 << i) & squeezed_mask)
    unsqueezed = squeezed.unsqueeze(true_axis)
    unsqueezed2 = squeezed.unsqueeze(mask=squeezed_mask)
    for s in [unsqueezed, unsqueezed2]:
        assert s.shape == shape
        if expected_shape != shape:
            assert s.base is ndbuf
        else:
            assert s.base is None
            assert s is ndbuf


@pytest.mark.parametrize(
    (
        "ndim",
        "shape",
        "permutation",
        "slices",
        "neg_slices",
        "direction",
        "device_id",
        "dtype",
    ),
    [
        (
            Param("ndim", ndim),
            Param("shape", shape),
            Param("permutation", permutation),
            Param("slices", slices),
            Param("neg_slices", neg_slices),
            Param("direction", direction),
            Param("device_id", device_id),
            Param(
                "dtype",
                py_rng.choice(dtype_and_names),
            ),
        )
        for ndim in [2, 3, 4, 5, 7, 13, 21, 32]
        for shape in [_shape(py_rng, ndim)]
        for permutation in random_permutations(py_rng, ndim)
        for slices, neg_slices in [
            (None, None),
            (random_non_empty_slice(py_rng, shape), None),
            (random_non_empty_slice(py_rng, shape), random_negated_strides(py_rng, shape)),
        ]
        for direction in ["d2h", "h2d"]
        for device_id in _shuffled(py_rng, [0, 1])
    ],
    ids=idfn,
)
def test_slice_permute_empty_like(ndim, shape, permutation, slices, neg_slices, direction, device_id, dtype):
    ndim = ndim.value
    shape = shape.value
    permutation = permutation.value
    slices = slices.value
    neg_slices = neg_slices.value
    direction = direction.value
    dtype = dtype.value
    device_id = device_id.value
    _skip(device_id)

    src_device_id, other_device_id = mem_locations_from_direction(device_id, direction)
    stream_holder = create_stream(device_id)

    a = arange(src_device_id, stream_holder, math.prod(shape), dtype).reshape(shape)
    base = as_ndbuffer(a)
    base_ptr = base.data_ptr
    assert base_ptr == array_ptr(a)

    ndbuf = base
    assert ndbuf.device_id == src_device_id
    assert ndbuf.base is None

    if slices is not None:
        a = a[slices]
        ndbuf = ndbuf[slices]
        assert ndbuf.base is base
    if neg_slices is not None:
        a = a[neg_slices]
        ndbuf = ndbuf[neg_slices]
        assert ndbuf.base is base

    a = a.transpose(permutation)
    ndbuf = ndbuf.permute(permutation)
    if slices is not None or neg_slices is not None or permutation != tuple(range(ndim)):
        assert ndbuf.base is base
    else:
        assert ndbuf.base is None
        assert ndbuf is base
    del base

    assert a.shape == ndbuf.shape
    assert almost_equal_strides(a.shape, ndbuf.strides_in_bytes, a.strides)
    assert ndbuf.dtype_name == a.dtype.name

    a_nd = as_ndbuffer(a)
    assert a_nd.shape == a.shape
    assert almost_equal_strides(a_nd.shape, a_nd.strides_in_bytes, a.strides)
    assert a_nd.dtype_name == a.dtype.name
    assert a_nd.data_ptr == array_ptr(a)
    with device_ctx(src_device_id):
        ndbuf.copy_(a_nd, stream=stream_holder)
        if src_device_id != "cpu":
            stream_holder.obj.sync()
        assert_equal(as_array(ndbuf), a)

        dst = NDBuffer.empty_like(ndbuf, stream=stream_holder)
        dst_ref = a.copy("K")
        assert dst.device_id == src_device_id
        assert dst.shape == dst_ref.shape
        assert almost_equal_strides(dst.shape, dst.strides_in_bytes, dst_ref.strides)
        assert dst.dtype_name == dst_ref.dtype.name
        dst.copy_(ndbuf, stream=stream_holder)
        if src_device_id != "cpu":
            stream_holder.obj.sync()
        assert_equal(as_array(dst), dst_ref)

    with device_ctx(other_device_id):
        dst_other = NDBuffer.empty_like(ndbuf, device_id=other_device_id, stream=stream_holder)
        assert dst_other.device_id == other_device_id
        assert dst_other.shape == dst_ref.shape
        assert almost_equal_strides(dst_other.shape, dst_other.strides_in_bytes, dst_ref.strides)
        assert dst_other.dtype_name == dst_ref.dtype.name
    with device_ctx(device_id):
        dst_other.copy_(ndbuf, stream=stream_holder)
        with stream_ctx(stream_holder):
            assert_equal(cp.asnumpy(as_array(dst_other)), cp.asnumpy(dst_ref))


@pytest.mark.parametrize(
    (
        "shape",
        "transformation",
        "direction",
        "device_id",
        "dtype",
        "num_threads",
        "use_barrier",
    ),
    [
        (
            Param("shape", shape),
            Param("transformation", transformation),
            Param("direction", direction),
            Param("device_id", device_id),
            Param(
                "dtype",
                py_rng.choice(dtype_and_names),
            ),
            Param("num_threads", num_threads),
            Param("use_barrier", use_barrier),
        )
        for shape in [(51,), (1024, 1023), (101, 101, 101)]
        for transformation in ["id", "slice", "reverse"]
        for direction in ["d2h", "d2d", "h2d"]
        for device_id in [0, 1]
        for num_threads in [1, 2, 16]
        for use_barrier in [True, False]
    ],
    ids=idfn,
)
def test_multithreaded(shape, transformation, direction, device_id, dtype, num_threads, use_barrier):
    import threading

    shape = shape.value
    transformation = transformation.value
    direction = direction.value
    dtype = dtype.value
    device_id = device_id.value
    num_threads = num_threads.value

    _skip(device_id)

    if use_barrier:
        # artificially increase contention for the caches in the ndbuffer code
        barier = threading.Barrier(num_threads)
    else:
        barier = None

    def copy_(thread_id, thread_data):
        try:
            for i in range(3):
                logger_name = f"ndbuffer_test_multithreaded_{thread_id}"
                log_stream = StringIO()
                logger = logging.Logger(logger_name, level=logging.DEBUG)
                logger.addHandler(logging.StreamHandler(log_stream))
                logger.setLevel(logging.DEBUG)
                stream_holder = create_stream(device_id)
                src_device_id = "cpu" if direction == "h2d" else device_id
                volume = math.prod(shape)
                a = arange(src_device_id, stream_holder, volume, dtype)
                with device_ctx(src_device_id):
                    ndbuf = NDBuffer.empty((volume,), dtype, src_device_id, stream=stream_holder)
                a = a.reshape(shape)
                ndbuf = ndbuf.reshape(shape)
                if transformation == "slice":
                    a = a[..., ::-1]
                    ndbuf = ndbuf[..., ::-1]
                elif transformation == "reverse":
                    a = a.transpose(tuple(reversed(range(len(shape)))))
                    ndbuf = ndbuf.permute(tuple(reversed(range(len(shape)))))
                elif transformation != "id":
                    raise ValueError(f"Invalid transformation: {transformation}")
                assert a.shape == ndbuf.shape
                assert almost_equal_strides(a.shape, ndbuf.strides_in_bytes, a.strides)
                assert ndbuf.dtype_name == a.dtype.name
                dst_device_id = "cpu" if direction == "d2h" else device_id
                if use_barrier:
                    barier.wait()
                with device_ctx(dst_device_id):
                    nd_dst = NDBuffer.empty(a.shape, dtype, dst_device_id, stream=stream_holder)
                if use_barrier:
                    barier.wait()
                with device_ctx(device_id):
                    ndbuf.copy_(as_ndbuffer(a), stream=stream_holder)
                    nd_dst.copy_(ndbuf, stream=stream_holder, logger=logger)
                    if direction == "d2d":
                        stream_holder.obj.sync()
                logs = log_stream.getvalue()
                launched_kernel = "Launching elementwise copy kernel" in logs or "Launching transpose copy kernel" in logs
                if launched_kernel:
                    if i == 0:
                        assert "Cached strided copy include dir" in logs
                    else:
                        assert "Cached strided copy include dir" not in logs, logs
                if "Compiling kernel" in logs:
                    thread_data["compiled"] += 1
                with device_ctx(device_id), stream_ctx(stream_holder):
                    assert_equal(cp.asnumpy(as_array(nd_dst)), cp.asnumpy(a))

        except Exception as e:
            thread_data["exception"] = e
            raise

    threads = []
    thread_data = [{"exception": None, "compiled": 0} for _ in range(num_threads)]
    for i in range(num_threads):
        t = threading.Thread(target=copy_, args=(i, thread_data[i]))
        threads.append(t)
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    for i in range(num_threads):
        if thread_data[i]["exception"] is not None:
            raise AssertionError(f"Thread {i} failed") from thread_data[i]["exception"]
    total_compilations = sum(thread_data["compiled"] for thread_data in thread_data)
    assert total_compilations <= 1, f"total_compilations={total_compilations}"

    if direction != "d2h":
        import nvmath.internal.memory

        pool = nvmath.internal.memory.get_device_memory_resource(device_id)
        reserved_memory = nvmath.internal._bindings.get_memory_pool_reserved_memory_size(pool.handle)
        with device_ctx(device_id) as device:
            device.sync()
            nvmath.internal.memory.free_reserved_memory()
            reserved_memory_after = nvmath.internal._bindings.get_memory_pool_reserved_memory_size(pool.handle)
            assert reserved_memory_after < reserved_memory, (
                f"reserved_memory_after={reserved_memory_after} >= reserved_memory={reserved_memory}"
            )


@pytest.mark.parametrize(
    (
        "shape",
        "slices",
        "dtype",
        "needs_wide_strides",
        "transpose",
    ),
    [
        (
            Param("shape", shape),
            Param("slices", slices),
            Param("dtype", dtype),
            Param("needs_wide_strides", needs_wide_strides),
            Param("transpose", transpose),
        )
        for shape, slices, dtype, needs_wide_strides in [
            # this is a nice edge case:
            # 1. depending on the dtype max offset does or doesn't exceed INT_MAX
            # 2. the dot(shape - 1, strides) is less than INT_MAX but
            # the dot(shape, strides) is bigger than INT_MAX
            ((3, 2**24 + 1, 33), _SL[:, ::999, :], "int8", False),
            ((3, 2**24 + 1, 33), _SL[::-1, ::-999, ::-1], "int8", False),
            ((3, 2**24 + 1, 33), _SL[:, ::999, :], "int16", False),
            ((3, 2**24 + 1, 33), _SL[::-1, ::-999, ::-1], "int16", False),
            # volume and dot(shape, strides) exceed INT_MAX
            # but the actual max offset not
            ((1, 3, 715827883), _SL[:, ::-1, -19:], "int8", False),
            ((1, 3, 715827883), _SL[:, :, -19:], "int8", False),
            ((1, 3, 715827883), _SL[::-1, :, -19:], "int8", False),
            ((1, 3, 715827883), _SL[::-1, ::-1, 18::-1], "int8", False),
            # offset really exceeds INT_MAX (while sliced volume is still small)
            ((1, 4, 715827883), _SL[:, ::-1, -19:], "int8", True),
            ((1, 4, 715827883), _SL[:, :, -19:], "int8", True),
            ((1, 4, 715827883), _SL[::-1, :, -19:], "int8", True),
            ((1, 4, 715827883), _SL[::-1, ::-1, 18::-1], "int8", True),
            # like above but split 4 into 2x2 and check if wide strides
            # are used iff the strides have the same sign
            ((2, 2, 715827883), _SL[:, :, -19:], "int8", True),
            ((2, 2, 715827883), _SL[::-1, :, -19:], "int8", False),
            ((2, 2, 715827883), _SL[:, ::-1, -19:], "int8", False),
            ((2, 2, 715827883), _SL[::-1, ::-1, -19:], "int8", True),
        ]
        for transpose in [False, True]
    ],
    ids=idfn,
)
def test_wide_strides_small_volume_copy(caplog, shape, slices, dtype, needs_wide_strides, transpose):
    # test that wide strides are used when needed due to big offsets of the elements
    # (even when the volume is small)
    device_id = 0
    _skip(device_id)

    logger_name = "ndbuffer_test_wide_strides_copy"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)

    shape = shape.value
    dtype = dtype.value
    slices = slices.value

    # the full unsliced src array must be allocated even though the sliced volume is small;
    # dst is negligible (only the sliced volume), so 1.5x covers src + overhead
    if cp.cuda.Device(device_id).mem_info[1] < 1.5 * math.prod(shape) * np.dtype(dtype).itemsize:
        pytest.skip("Not enough memory to run the test")

    free_memory()
    stream_holder = create_stream(0)
    a = arange(device_id, stream_holder, math.prod(shape), dtype).reshape(shape)[slices]
    if transpose:
        a = a.transpose(0, 2, 1)
    b = zeros(device_id, stream_holder, a.shape, dtype)
    aw = as_ndbuffer(a)
    bw = as_ndbuffer(b)
    caplog.clear()
    with device_ctx(device_id):  # noqa: SIM117
        with caplog.at_level(logging.DEBUG, logger_name):
            bw.copy_(aw, stream=stream_holder, logger=logger)
    log_text = caplog.text
    if needs_wide_strides:
        assert "TRANSPOSE_KERNEL(int64_t" in log_text or "ELEMENTWISE_KERNEL(int64_t" in log_text
    else:
        assert "TRANSPOSE_KERNEL(int32_t" in log_text or "ELEMENTWISE_KERNEL(int32_t" in log_text
    stream_holder.obj.sync()
    assert_equal(b, a)


@pytest.mark.parametrize(
    (
        "shape",
        "slices",
        "permutation",
        "dtype",
    ),
    [
        (
            Param("shape", shape),
            Param("slices", slices),
            Param("permutation", permutation),
            Param("dtype", dtype),
        )
        for shape, slices, permutation in [
            # 2**31 - 127 factorized, respectively sliced or transposed
            # to enforce elementwise and transpose kernels usage
            ((53, 419, 96703), (_SL[:, :, ::-1]), (0, 1, 2)),
            ((53, 419, 96703), (_SL[:, :, :]), (2, 1, 0)),
            # 2**32 - 127 factorized
            ((3, 23, 347, 179383), (_SL[:, ::-1, :, :]), (0, 1, 2, 3)),
            ((3, 23, 347, 179383), (_SL[:, :, :, :]), (3, 2, 1, 0)),
            # 4/3 * (2**32 - 1) factorized
            ((5, 4, 17, 257, 65537), (_SL[:, :, :, ::-1, :]), (0, 1, 2, 3, 4)),
            ((5, 4, 17, 257, 65537), (_SL[:, :, :, :, :]), (4, 3, 2, 1, 0)),
        ]
        for dtype in ["int8"]
    ],
    ids=idfn,
)
def test_wide_strides_large_volume_copy(caplog, shape, slices, permutation, dtype):
    # test that kernels properly compute offsets when the 64-bit strides are needed
    # this test uses large volumes to make sure that computing flat index and unravelling
    # it to ndim-coordinates does not overflow
    # NOTE, this test is slow
    logger_name = "ndbuffer_test_wide_strides_large_volume_copy"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)

    shape = shape.value
    dtype = dtype.value
    slices = slices.value
    permutation = permutation.value
    device_id = 0

    _skip(device_id)
    # we need to allocate src, dst and take into account that
    # cp testing assertion for tensor equality may copy the tensors
    # as well (likely due to their sliced/permuted layouts)
    if cp.cuda.Device(device_id).mem_info[1] < 4.1 * math.prod(shape) * np.dtype(dtype).itemsize:
        pytest.skip("Not enough memory to run the test")

    with cp.cuda.Device(device_id):
        cp.cuda.Device(device_id).synchronize()
        free_memory()
        stream_holder = create_stream(device_id)

    a = arange(device_id, stream_holder, math.prod(shape), dtype).reshape(shape)[slices].transpose(permutation)
    b = zeros(device_id, stream_holder, a.shape, dtype)
    aw = as_ndbuffer(a)
    bw = as_ndbuffer(b)
    caplog.clear()
    with device_ctx(device_id):  # noqa: SIM117
        with caplog.at_level(logging.DEBUG, logger_name):
            bw.copy_(aw, stream=stream_holder, logger=logger)
    log_text = caplog.text
    assert "TRANSPOSE_KERNEL(int64_t" in log_text or "ELEMENTWISE_KERNEL(int64_t" in log_text
    stream_holder.obj.sync()
    assert_equal(b, a)


@pytest.mark.parametrize(
    (
        "shape",
        "dtype",
        "expected_itemsize",
        "transpose",
        "device_id",
    ),
    [
        (
            Param("shape", shape),
            Param("dtype", dtype),
            Param("expected_itemsize", expected_itemsize),
            Param("transpose", transpose),
            Param("device_id", device_id),
        )
        for shape, dtype, expected_itemsize in [
            ((2, 255, 4), "int8", 4),
            ((2, 255, 4), "int16", 8),
            ((2, 255, 4), "float32", 8),
            ((2, 255, 4), "float64", 8),
            ((2, 255, 4), "complex128", 16),
            ((2, 255, 6), "int8", 2),
            ((2, 255, 6), "int16", 4),
            ((2, 255, 6), "float32", 8),
            ((2, 255, 6), "float64", 8),
            ((2, 255, 6), "complex128", 16),
            ((2, 255, 3), "int8", 1),
            ((2, 255, 3), "int16", 2),
            ((2, 255, 3), "float32", 4),
            ((2, 255, 3), "float64", 8),
            ((2, 255, 3), "complex128", 16),
        ]
        for transpose in [False, True]
        for device_id in [1, 0]
    ],
    ids=idfn,
)
def test_vectorized_copy(caplog, shape, dtype, expected_itemsize, transpose, device_id):
    logger_name = "ndbuffer_test_wide_strides_copy"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)

    shape = shape.value
    dtype = dtype.value
    expected_itemsize = expected_itemsize.value
    device_id = device_id.value
    _skip(device_id)

    stream_holder = create_stream(device_id)
    a_base = arange(device_id, stream_holder, math.prod(shape), dtype).reshape(shape)
    a = a_base[:, :-1, :]  # take a slice so that plain memcopy is not used
    with device_ctx(device_id):
        bw = NDBuffer.empty(a.shape, dtype, device_id, stream=stream_holder)
    if transpose:
        a = a.transpose(2, 1, 0)
        bw = bw.permute((2, 1, 0))
    aw = as_ndbuffer(a)
    b = as_array(bw)
    with device_ctx(device_id):
        with caplog.at_level(logging.DEBUG, logger_name):
            bw.copy_(aw, stream=stream_holder, logger=logger)
            if expected_itemsize == np.dtype(dtype).itemsize:
                assert "Copy will use bigger/vectorized itemsize" not in caplog.text
            else:
                assert "Copy will use bigger/vectorized itemsize" in caplog.text
                assert f"itemsize={expected_itemsize}" in caplog.text
        stream_holder.obj.sync()
        assert_equal(b, a)


@pytest.mark.parametrize(
    (
        "ndim",
        "shape",
        "permutation",
        "negative_strides",
        "dtype",
    ),
    [
        (
            Param("ndim", ndim),
            Param("shape", shape),
            Param("permutation", permutation),
            Param("negative_strides", negative_strides),
            Param("dtype", dtype),
        )
        for ndim in [2, 3, 4]
        for shape in [_shape(py_rng, ndim)]
        for permutation in random_permutations(py_rng, ndim, 4)
        for negative_strides in [False, True]
        for dtype in [py_rng.choice(dtype_and_names)]
    ],
    ids=idfn,
)
def test_abs_dense_layout_is_memcopied(caplog, ndim, shape, permutation, negative_strides, dtype):
    device_id = 0
    _skip(device_id)

    ndim = ndim.value
    shape = shape.value
    permutation = permutation.value
    negative_strides = negative_strides.value
    dtype = dtype.value
    stream_holder = create_stream(device_id)
    a = arange(device_id, stream_holder, math.prod(shape), dtype).reshape(shape)
    a = a.transpose(permutation)
    b = zeros(device_id, stream_holder, shape, dtype)
    b = b.transpose(permutation)
    if negative_strides:
        a = a[..., ::-1]
        b = b[..., ::-1]
    aw = as_ndbuffer(a)
    bw = as_ndbuffer(b)
    logger_name = "ndbuffer_test_permuted_dense_strides"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    caplog.clear()
    with device_ctx(device_id):  # noqa: SIM117
        with caplog.at_level(logging.DEBUG, logger_name):
            bw.copy_(aw, stream=stream_holder, logger=logger)
    log_text = caplog.text
    assert "Launching direct D2D memcpy" in log_text
    assert "copy kernel" not in log_text
    stream_holder.obj.sync()
    assert_equal(b, a)


@pytest.mark.parametrize(
    (
        "base_shape",
        "broadcast_shape",
        "broadcast_strides",
        "dtype",
        "direction",
    ),
    [
        (
            Param("base_shape", base_shape),
            Param("broadcast_shape", broadcast_shape),
            Param("broadcast_strides", broadcast_strides),
            Param("dtype", py_rng.choice(dtype_and_names)),
            Param("direction", direction),
        )
        for base_shape, broadcast_shape, broadcast_strides in [
            # broadcast
            ((1,), (7, 255, 3), (0, 0, 0)),
            ((255, 1), (255, 3), (1, 0)),
            ((1, 3), (255, 3), (0, 1)),
            ((6, 1, 12), (6, 3, 12), (6, 0, 1)),
            ((1, 1, 12), (6, 3, 12), (0, 0, 1)),
            ((1, 1, 12), (3, 6, 12), (0, 0, 1)),
            # broadcast and permute
            ((6, 1, 12), (12, 3, 6), (1, 0, 6)),
            ((1024,), (1024, 1024), (0, 1)),
            ((1024,), (1024, 1024), (1, 0)),
            # sliding window
            ((10,), (2, 7), (3, 1)),
            ((10,), (7, 2), (1, 3)),
        ]
        for direction in ["h2d", "d2d", "d2h"]
    ],
    ids=idfn,
)
def test_stride_tricks_copy(base_shape, broadcast_shape, broadcast_strides, dtype, direction):
    device_id = 0
    _skip(device_id)
    base_shape = base_shape.value
    broadcast_shape = broadcast_shape.value
    broadcast_strides = broadcast_strides.value
    dtype = dtype.value
    direction = direction.value
    itemsize = np.dtype(dtype).itemsize
    stream_holder = create_stream(device_id)
    src_device_id, dst_device_id = mem_locations_from_direction(device_id, direction)
    # First let's compare stride tricks vs ndbuffer.as_strided
    a = arange(src_device_id, stream_holder, math.prod(base_shape), dtype)
    aw = as_ndbuffer(a).reshape(base_shape)
    aw = aw.as_strided(StridedLayout(broadcast_shape, broadcast_strides, itemsize))
    a = a.reshape(base_shape)
    strides_in_bytes = tuple(s * itemsize for s in broadcast_strides)
    a = package(a).lib.stride_tricks.as_strided(a, shape=broadcast_shape, strides=strides_in_bytes)
    assert aw.shape == a.shape
    assert almost_equal_strides(aw.shape, aw.strides_in_bytes, strides_in_bytes)
    assert aw.dtype_name == np.dtype(dtype).name
    # Then let's see if empty_like keeps the stride order as promised,
    # compare it against cupy/numpy's copy("K")
    with device_ctx(device_id):
        b_nd = NDBuffer.empty_like(aw, device_id=dst_device_id, stream=stream_holder)
    assert b_nd.device_id == dst_device_id
    assert b_nd.shape == broadcast_shape
    with device_ctx(device_id):
        b_nd.copy_(aw, stream=stream_holder)
        if direction == "d2d":
            stream_holder.obj.sync()
    a_copy = a.copy("K")
    assert b_nd.strides_in_bytes == a_copy.strides
    with stream_ctx(stream_holder):
        assert_equal(cp.asnumpy(as_array(b_nd)), cp.asnumpy(a))


@pytest.mark.parametrize(
    (
        "base_shape",
        "base_slice",
        "broadcast_shape",
        "broadcast_strides",
        "broadcast_slice",
        "dtype",
        "direction",
        "blocking",
    ),
    [
        (
            Param("base_shape", base_shape),
            Param("base_slice", base_slice),
            Param("broadcast_shape", broadcast_shape),
            Param("broadcast_strides", broadcast_strides),
            Param("broadcast_slice", broadcast_slice),
            Param("dtype", py_rng.choice(dtype_and_names)),
            Param("direction", direction),
            Param("blocking", blocking),
        )
        for base_shape, base_slice, broadcast_shape, broadcast_slice, broadcast_strides in [
            # broadcast
            ((1,), None, (7, 255, 3), None, (0, 0, 0)),
            ((255, 1), None, (255, 3), None, (1, 0)),
            ((255, 1), None, (255, 3), _SL[..., ::-1], (1, 0)),
            ((255, 1), None, (255, 3), _SL[::-1], (1, 0)),
            ((1, 3), None, (255, 3), None, (0, 1)),
            ((1, 3), None, (255, 3), _SL[::-1, ::-1], (0, 1)),
            ((6, 1, 12), None, (6, 3, 12), None, (6, 0, 1)),
            ((1, 1, 12), None, (6, 3, 12), None, (0, 0, 1)),
            ((1, 1, 12), None, (3, 6, 12), None, (0, 0, 1)),
            ((15, 1, 7), None, (15, 3, 13), _SL[..., ::2], (7, 0, 1)),
            ((15, 1, 13), _SL[..., ::2], (15, 3, 7), None, (13, 0, 2)),
            ((15, 1, 13), _SL[..., ::2], (15, 3, 13), _SL[..., ::2], (13, 0, 2)),
        ]
        for direction in ["h2h", "h2d", "d2d", "d2h"]
        for blocking in [True, False, None]
    ],
    ids=idfn,
)
def test_copy_broadcast(
    caplog,
    base_shape,
    base_slice,
    broadcast_shape,
    broadcast_strides,
    broadcast_slice,
    dtype,
    direction,
    blocking,
):
    device_id = 0
    _skip(device_id)

    base_shape = base_shape.value
    base_slice = base_slice.value
    broadcast_shape = broadcast_shape.value
    broadcast_strides = broadcast_strides.value
    broadcast_slice = broadcast_slice.value
    dtype = dtype.value
    direction = direction.value
    blocking = blocking.value

    if blocking is not None:
        expected_blocking = blocking
    else:
        expected_blocking = direction != "d2d"

    stream_holder = create_stream(device_id)
    src_device_id, dst_device_id = mem_locations_from_direction(device_id, direction)
    a = arange(src_device_id, stream_holder, math.prod(base_shape), dtype).reshape(base_shape)
    aw = as_ndbuffer(a)
    if base_slice is not None:
        aw = aw[base_slice]
        a = a[base_slice]
        assert aw.shape == a.shape
        assert aw.strides_in_bytes == a.strides
    with device_ctx(dst_device_id):
        b_nd = NDBuffer.empty(broadcast_shape, dtype, dst_device_id, stream=stream_holder)
    b_ref = zeros(dst_device_id, stream_holder, broadcast_shape, dtype)
    if broadcast_slice is not None:
        b_nd = b_nd[broadcast_slice]
        b_ref = b_ref[broadcast_slice]
        assert b_nd.strides_in_bytes == b_ref.strides
        assert b_nd.layout.has_no_negative_stride == all(s >= 0 for s in b_ref.strides)
    with device_ctx(device_id):
        b_nd.fill_(44, stream=stream_holder.obj)
    b = as_array(b_nd)
    with stream_ctx(stream_holder):
        assert (b == 44).all()

    logger_name = "ndbuffer_test_permuted_dense_strides"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    caplog.clear()
    with device_ctx(device_id), caplog.at_level(logging.DEBUG, logger_name):
        b_nd.copy_(aw, stream=stream_holder, logger=logger, blocking=blocking)

    itemsize = np.dtype(dtype).itemsize
    src_vol = math.prod(a.shape)
    can_memset = src_vol == 1 and itemsize in [1, 2, 4]
    if direction == "h2d" and can_memset:
        assert f"Memset {math.prod(broadcast_shape)} elements on stream {stream_holder.ptr}" in caplog.text
    elif direction == "h2d" or direction == "d2h":
        # check that we memcopy the "compact" representation
        # not the full broadcast shape
        expected_memcopy_size = src_vol * itemsize
        assert f"Memcpy of {expected_memcopy_size} bytes on stream {stream_holder.ptr}" in caplog.text

    if direction == "h2d" or direction == "d2d":
        if expected_blocking:
            assert f"Sync stream {stream_holder.ptr}" in caplog.text
        elif has_pinned_memory_resource:
            assert "Sync stream" not in caplog.text
        else:
            assert ("Sync stream" not in caplog.text and "H2H" not in caplog.text) or (
                "Note, the non-blocking flag is ignored" in caplog.text and f"Sync stream {stream_holder.ptr}" in caplog.text
            )
    elif direction == "d2h":
        # When we broadcast, the D2H copy ends with a scatter H2H copy,
        # which is always blocking. Make sure we enforce that.
        assert f"Sync stream {stream_holder.ptr}" in caplog.text
        if not expected_blocking:
            assert "Note, the non-blocking flag is ignored" in caplog.text

    with device_ctx(device_id), stream_ctx(stream_holder):
        if direction == "h2d":
            b_ref[...] = cp.asarray(a)
        elif direction == "d2h":
            b_ref[...] = cp.asnumpy(a)
        else:
            b_ref[...] = a

        assert_equal(cp.asnumpy(b), cp.asnumpy(b_ref))


@pytest.mark.parametrize(
    ("direction", "blocking", "device_id"),
    [
        (Param("direction", direction), Param("blocking", blocking), Param("device_id", device_id))
        for direction in ["h2d", "d2h", "d2d"]
        for blocking in [True, False, None]
        for device_id in [0, 1]
    ],
    ids=idfn,
)
def test_simple_async_copy(caplog, direction, blocking, device_id):
    direction = direction.value
    blocking = blocking.value
    device_id = device_id.value
    _skip(device_id)

    expected_blocking = blocking if blocking is not None else direction != "d2d"
    src_device_id, dst_device_id = mem_locations_from_direction(device_id, direction)
    stream_holder = create_stream(device_id)
    with device_ctx(device_id):
        src = NDBuffer.empty((7, 1009), np.int32, src_device_id, stream=stream_holder)
        src.fill_(0, stream=stream_holder)
        dst = NDBuffer.empty((7, 1009), np.int32, dst_device_id, stream=stream_holder)
        dst.fill_(1, stream=stream_holder)

    logger_name = "ndbuffer_test_simple_async_copy"
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    caplog.clear()
    with device_ctx(device_id), caplog.at_level(logging.DEBUG, logger_name):
        dst.copy_(src, stream=stream_holder, logger=logger, blocking=blocking)

        with stream_ctx(stream_holder):
            assert_equal(cp.asnumpy(as_array(dst)), cp.asnumpy(as_array(src)))

    if expected_blocking:
        assert f"Sync stream {stream_holder.ptr}" in caplog.text
    elif has_pinned_memory_resource:
        assert "Sync stream" not in caplog.text
        if direction == "h2d":
            assert "staging H2H copy into temporary buffer" in caplog.text
    else:
        assert ("Sync stream" not in caplog.text and "H2H" not in caplog.text) or (
            "Note, the non-blocking flag is ignored" in caplog.text and f"Sync stream {stream_holder.ptr}" in caplog.text
        )


@pytest.mark.parametrize(("device_id"), [Param("device_id", device_id) for device_id in [0, 1]])
def test_async_h2d(device_id):
    device_id = device_id.value
    _skip(device_id)

    stream_holder = create_stream(device_id)

    with device_ctx(device_id):
        n = 64 * 1024
        src_array = cpx.empty_pinned(n, dtype=np.int32)
        src_array[...] = 1
        src = NDBuffer.from_numpy(src_array)
        dst = NDBuffer.empty(n, np.int32, device_id, stream=stream_holder)
        dst_array = as_cp_array(dst)
        assert array_ptr(src_array) == src.data_ptr
        assert array_ptr(dst_array) == dst.data_ptr

        for i in range(50):
            # launch h2d async copy
            dst.copy_(src, stream=stream_holder, blocking=False)
            # and start updating the source array immediately
            np.add(src_array, 1, out=src_array[::-1])
            with stream_ctx(stream_holder):
                ok_count = cp.sum(dst_array == i + 1).item()
                if ok_count != n:
                    raise AssertionError(f"ok_count != n: {ok_count} != {n} at iteration {i}")
