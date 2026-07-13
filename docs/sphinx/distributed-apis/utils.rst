******************************
Distributed Host API Utilities
******************************

.. Use ``group`` here rather than ``module``. These helpers are effectively a
   group of APIs that lives in the umbrella ``nvmath.distributed`` module, which
   this page registers with ``:no-index:`` (see the API Reference section below).
   ``module`` would emit a build warning here: ``:no-index:``
   leaves no module registration for it to deduce a banner name from, so it would
   fall back to generic wording. Dropping ``:no-index:`` would not help either
   because it would deduce the umbrella name ``nvmath.distributed``, overstating
   the intended scope (only these helpers are experimental, not all of it).

.. experimental:: group

   The symmetric memory management APIs are experimental
   and potentially subject to future changes.

NVSHMEM symmetric memory management
===================================

Some distributed host APIs like :class:`nvmath.distributed.fft.FFT` and
:class:`nvmath.distributed.distribution.Redistribute` use a
Partitioned Global Address Space (PGAS) model for parallelism and require GPU operands
to be allocated on the
`NVSHMEM symmetric memory heap <https://docs.nvidia.com/nvshmem/api/using.html>`_.
We offer helpers to allocate CuPy ndarrays and PyTorch tensors in symmetric memory.
To do so, simply specify the *local* shape, the array package and dtype:

.. code-block:: python

    import cupy
    import torch
    import nvmath.distributed

    # NVSHMEM backend required for the following symmetric memory APIs.
    nvmath.distributed.initialize(device_id, process_group, backends=["nvshmem"])

    # Allocate a CuPy array of shape (3,3) on each process
    a = nvmath.distributed.allocate_symmetric_memory((3,3), cupy, dtype=cupy.float32)

    # Allocate a torch tensor of shape (3,3) on each process
    b = nvmath.distributed.allocate_symmetric_memory((3,3), torch, dtype=torch.float64)

    # ... do distributed computations using these operands, as well as any
    # array operations supported by the array package

    nvmath.distributed.free_symmetric_memory(a, b)

.. important::
    Any symmetric memory owned by the user (e.g. allocated
    with :func:`~nvmath.distributed.allocate_symmetric_memory` or returned to the
    user by a distributed host API) must be deleted explicitly using
    :func:`~nvmath.distributed.free_symmetric_memory`. You cannot rely on the Python
    garbage collector to do this, since freeing a symmetric allocation is a
    collective call which must be done by all processes, and the garbage collector
    does not free memory in a deterministic fashion.

.. note::
    The allocation size on each process must be the same (due to the symmetric
    memory requirement). This implies that, by default, the shape and dtype must
    be the same on every process. For non-uniform shapes, you can use
    ``make_symmetric=True`` to force a symmetric allocation under the hood (see
    the example below).

If the shape and dtype is not uniform across processes, you can make the allocation
symmetric by using ``make_symmetric=True``:

.. code-block:: python

    # Get my process rank.
    rank = nvmath.distributed.get_context().process_group.rank
    # Note: this will raise an error if make_symmetric is False.
    if rank == 0:
        a = nvmath.distributed.allocate_symmetric_memory((3,3), cupy, make_symmetric=True)
    else:
        a = nvmath.distributed.allocate_symmetric_memory((2,3), cupy, make_symmetric=True)
    # ...
    nvmath.distributed.free_symmetric_memory(a)

This will allocate a buffer of the same size (in bytes) on each process, with
the returned ndarray/tensor backed by that buffer, but of exactly the requested shape
on that process. The size of the buffer is determined based on the process with most
elements (rank 0 in the above example).

.. _distributed-api-util-reference:

API Reference
-------------

.. module:: nvmath.distributed
   :no-index:

nvmath-python provides host-side APIs for managing symmetric memory.

.. autosummary::
   :toctree: generated/

   allocate_symmetric_memory
   free_symmetric_memory
