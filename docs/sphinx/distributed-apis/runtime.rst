*******************
Distributed runtime
*******************

.. Use ``group`` here rather than ``module``. These runtime-management APIs are
   effectively a group of APIs that lives in the umbrella ``nvmath.distributed``
   module (registered in the API Reference section below). ``module`` would
   deduce that umbrella name for the banner, which overstates the scope (only
   these runtime APIs are experimental, not all of ``nvmath.distributed``).

.. experimental:: group

   The APIs for managing the distributed runtime are experimental
   and potentially subject to future changes.

.. _distributed-api-initialize:

Initializing the distributed runtime
====================================

To use the distributed host APIs, you must first initialize the distributed runtime.
This is done by having each process provide a local CUDA device ID (referring
to a GPU on the host on which that process runs), the process group, and the
desired communication backends. For example:

.. code-block:: python

    import nvmath.distributed
    from nvmath.distributed import MPIProcessGroup
    from mpi4py import MPI
    process_group = MPIProcessGroup(MPI.COMM_WORLD)  # can use any MPI communicator
    nvmath.distributed.initialize(device_id, process_group, backends=["nvshmem", "nccl"])

The process group specifies the set of processes that will participate in subsequent
calls to distributed APIs. The process group *type* is tied to the bootstrapping method
(e.g. MPI or `torch.distributed <https://docs.pytorch.org/docs/stable/distributed.html>`_).

.. note::

    nvmath-python supports both MPI and
    `torch.distributed <https://docs.pytorch.org/docs/stable/distributed.html>`_ for
    bootstrapping and setup. Additionally, developers can provide their own implementation
    of :class:`nvmath.distributed.ProcessGroup` to add support for new bootstrapping
    schemes.

.. important::

    The bootstrapping method is only used for initialization and setup, not for compute.

.. tip::

    Distributed FFT requires the NVSHMEM backend.

    Distributed dense linear algebra operations require the NCCL backend.

After initializing the distributed runtime you may use the distributed APIs.
Certain APIs such as FFT and Redistribute require GPU operands to be allocated on the
NVSHMEM *symmetric memory heap*. Refer to :doc:`Distributed Host API Utilities <utils>` for
examples and details of how to manage GPU operands on this type of symmetric memory.

Initialize with MPI process group
---------------------------------

An :class:`nvmath.distributed.MPIProcessGroup` specifies a set of processes that were
launched using MPI (e.g. with mpiexec). You can construct an ``MPIProcessGroup`` from any
mpi4py communicator, and provide it to :func:`nvmath.distributed.initialize`.

Initialize with ``torch.distributed`` process group
---------------------------------------------------

A :class:`nvmath.distributed.TorchProcessGroup` specifies a set of processes that
communicate using ``torch.distributed`` (e.g. launched with torchrun).

You can construct a ``TorchProcessGroup`` by providing a ``torch.distributed`` process
group handle, or ``None`` to use the default PyTorch process group. The resulting
``TorchProcessGroup`` can then be passed to :func:`nvmath.distributed.initialize`.

.. note::

    If the ``torch.distributed`` process group internally uses a GPU communication
    backend (such as NCCL), when creating the ``TorchProcessGroup`` you must provide
    the device ID used by said backend on this process.

API Reference
=============

.. module:: nvmath.distributed

.. autosummary::
   :toctree: generated/

   initialize
   finalize

   ProcessGroup
   MPIProcessGroup
   TorchProcessGroup

   get_context

.. autosummary::
   :toctree: generated/
   :template: dataclass

   DistributedContext
