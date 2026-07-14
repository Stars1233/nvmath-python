nvmath-python Release Notes
***************************

.. _Release Notes_v1.0.0:

nvmath-python v1.0.0
====================

.. _Release Notes_v1.0.0_Release Summary:

Release Summary
---------------

.. releasenotes/notes/release-summary-9bd5c94185de0d8e.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

The first nvmath-python GA release, with key new features including the
single-GPU and distributed dense generic direct solver, performance
improvements to the sparse generic matrix multiplication API, support for
``numba-cuda-mlir`` for device APIs, support for NVFP4 in distributed
matrix multiplication, support for explicit batching in generic matrix
multiplication, and more. As always, we look forward to your feedback
and suggestions as we continue to improve the library to meet your needs.


.. _Release Notes_v1.0.0_New Features:

New Features
------------

.. releasenotes/notes/1168-e0fed5d27ac44d8c.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Added :mod:`nvmath.bindings.cusolverMp` bindings for cuSOLVERMp 0.7.2 through 0.8.0.

.. releasenotes/notes/1228-ab37e279efe97beb.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Reduced stream parsing overhead in :func:`nvmath.sparse.advanced.direct_solver`.

.. releasenotes/notes/1262-519ff5d553524f41.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Added :mod:`nvmath.bindings.cusolverSp` bindings for the deprecated cuSolverSp library.

.. releasenotes/notes/1263-aed81edfa3dea7c4.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Added :mod:`nvmath.bindings.cusparse` coverage for deprecated cuSPARSE APIs.

.. releasenotes/notes/1267-ed5c690a3dd2fef3.yaml @ b'c62a7a3e5f4526348d6c612a6f0f4779cc8b6cbc'

- Added :mod:`nvmath.bindings.cutensor` support for cuTENSOR 2.6.0.

.. releasenotes/notes/1282-61cb631bb23a36aa.yaml @ b'62d9926c77cce59539e7d28205a41651a9d6380e'

- Added :py:meth:`nvmath.linalg.generic.Matmul.reset_operands_unchecked`, a
  performance-optimized variant of :py:meth:`~nvmath.linalg.generic.Matmul.reset_operands`
  that skips operand validation and logging.

.. releasenotes/notes/1296-3c5d9f0a1b2e4d76.yaml @ b'c0ea90821f5355b91133d0909bdee8f6f4377819'

- Added distributed generic direct solver API including
  :class:`nvmath.distributed.linalg.DirectSolver` and
  :func:`nvmath.distributed.linalg.direct_solver`.

.. releasenotes/notes/1301-e8b93547df07b938.yaml @ b'000bdaeece7eb7bb8ece66e9ce817ece2eb30582'

- Added generic direct solver API including :class:`nvmath.linalg.DirectSolver` and
  :func:`nvmath.linalg.direct_solver`.

.. releasenotes/notes/1303-7da89a9fbd471102.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Added new :attr:`nvmath.tensor.ContractionOptions.result_layout` option to control the
  layout of contraction output.

.. releasenotes/notes/1313-d574eb338642e6fa.yaml @ b'd66d21f12e2ea005a85fc46eaf2b1502b3068e24'

- Added experimental free-threaded support on bindings

.. releasenotes/notes/1332-60345572f5c91efd.yaml @ b'c868d023d75434652c2a895d39c6001c496dccc1'

- Improved thread-safety for :mod:`nvmath.linalg`. A :class:`Matmul` instance should now
  only be used by its creating thread.

.. releasenotes/notes/1436-cafa0875747c6d2d.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Calling ``release_operand(s)`` more than once is now safe across all stateful APIs; extra
  calls are a no-op and log an info-level message.

.. releasenotes/notes/1453-3b9f0c1d2e4a5b6c.yaml @ b'8d37db7c866a564f2739b247ee7411d659760fc2'

- Added :meth:`nvmath.fft.FFT.create_key_from_metadata`, the metadata-based counterpart to
  :meth:`nvmath.fft.FFT.create_key`. It builds an FFT key from operand metadata (``shape``,
  ``dtype``, and optional ``strides``) together with a ``memory_space``, instead of
  requiring a fully allocated operand. This is useful, for example, to estimate the
  workspace size before an operand exists. The ``execution`` space is optional and defaults
  to ``memory_space``.

.. releasenotes/notes/878-a73dec356163b6f5.yaml @ b'2a2d23101dfe4730782b9fd5c199212cdef5baaf'

- Added support for explicit batching to generic matmul.

.. releasenotes/notes/cudss-v0.8-c7b55e64a26bc97b.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

- The sparse advanced direct solver has been updated to use cuDSS ``v0.8.0``,
  and hence benefits from the performance improvements and bug fixes in this
  version.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- The device APIs now support the MLIR-based ``numba-cuda-mlir`` compiler in
  addition to ``numba-cuda``. The ``FFT``, ``Matmul``, and ``Solver``
  objects are compiler-agnostic; the compiler is selected by the
  ``cuda.jit`` decorator used for the kernel. The ``nvmath.device.random``
  APIs and the advanced ``Matmul`` APIs (opaque tensors, accumulators, and
  pipelines) remain available only with ``numba-cuda``.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Added the ``float32x4``, ``float64x4``, and ``uint32x4`` vector types
  (and the corresponding ``*_type`` numba types) to ``nvmath.device``.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- The cuBLASDx ``DevicePipeline`` now accepts any input
  arrays supporting DLPack or the CUDA Array Interface.

.. releasenotes/notes/distributed-mm-drelu-epilogues-8cbb0c0c8d446b2f.yaml @ b'9372a30e4cee40cb5bd0b16f6fce49793d5e1452'

- Support DRELU and DRELU_BGRAD epilogues in distributed matrix multiplication.

.. releasenotes/notes/distributed-mm-nccl-symmetric-memory-9613cef845effd8f.yaml @ b'959a110f1987d1522100fa724eddfe75e016f1c7'

- Distributed matrix multiplication now registers operand B with NCCL symmetric memory
  whenever possible, which improves Allgather+GEMM performance.

.. releasenotes/notes/distributed-mm-nvfp4-9e9c44564b2064a8.yaml @ b'd44361e5cb5363cbb474d2ca214bf34ad5d1b64a'

- Support for NVFP4 in the distributed matrix multiplication API.

.. releasenotes/notes/nvpl-blas-26.5-fab56956b45ffcfc.yaml @ b'9b1657eb91063c611d06d674aeeeff1999e171fc'

- Update :mod:`nvmath.bindings.nvpl.blas` to NVPL 26.5.

.. releasenotes/notes/ust-cpu-memspace-2d42883dedb36948.yaml @ b'73f627437a65cccc57ea7c20599005925e293c03'

- The :class:`nvmath.sparse.Matmul` and :func:`nvmath.sparse.matmul` APIs now
  support UST operands in the CPU memory space for library dispatch as well as
  code generation.

.. releasenotes/notes/ust-emitter-v2-171c398b2c7f023f.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

- Improved performance of the generic sparse matrix multiplication (SpMM) APIs
  (:class:`nvmath.sparse.Matmul` and :func:`nvmath.sparse.matmul`) for the code
  generation path with universal sparse tensor operands due to new kernel
  emitter capabilities.


.. _Release Notes_v1.0.0_Bugs Fixed:

Bugs Fixed
----------

.. releasenotes/notes/1177-fdb1b59d88005972.yaml @ b'2a2d23101dfe4730782b9fd5c199212cdef5baaf'

- Silence deprecation warnings from cupy about :class:`cupy.cuda.ExternalStream`.

.. releasenotes/notes/1240-20d192256167651d.yaml @ b'2a2d23101dfe4730782b9fd5c199212cdef5baaf'

- Fixed a cuSPARSE handle leak which occurred when :meth:`nvmath.sparse.generic.Matmul.plan`
  was called multiple times on the same instance.

.. releasenotes/notes/1245-8e26f8ae23b3cf4c.yaml @ b'd9859cd47a1ca419e7b6439866590cae5540e8e5'

- Fixed :mod:`nvmath.bindings.nvpl` compatibility with MKL 2026.0.0.

.. releasenotes/notes/1259-a81c687578866ffe.yaml @ b'2a2d23101dfe4730782b9fd5c199212cdef5baaf'

- Fixed an incorrectly sized host memory allocation in
  :class:`nvmath.distributed.linalg.advanced.Matmul`.

.. releasenotes/notes/1270-2c0b406591eaaab1.yaml @ b'2a2d23101dfe4730782b9fd5c199212cdef5baaf'

- Fixed an incorrect ``AttributeError`` when reusing a
  :class:`nvmath.linalg.advanced.Matmul` with block scaling and tensor quantization scales;
  calling release_operands() → reset_operands() now completes without error.

.. releasenotes/notes/1325-4b2e1c8a7f9d6051.yaml @ b'af3cc6b40986e39ba2de03ff0ea3f026b5d5539f'

- Fixed :py:func:`nvmath.linalg.advanced.helpers.matmul.to_block_scale`
  to validate the full scale-tensor shape against the operand's logical
  block-scaling shape. Previously, only the trailing two dimensions
  were compared, so scale tensors with permuted batch dimensions could
  be silently accepted.

.. releasenotes/notes/1342-74adefa86d1a79a4.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Fixed logging state leaking from one example test to another

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Fixed a crash in ``get_current_device_cc()`` caused by unpacking the
  3-field ``ComputeCapability``.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- ``FFT`` now raises a descriptive error instead of a
  cryptic ``KeyError`` when an incomplete ``real_fft_options`` dict is
  provided.

.. releasenotes/notes/remove-deprecated-device-apis-2d6d63ac6983acd0.yaml @ b'189f8f78c24fb03acf2fbe18a405a074bf0f699a'

- Exported :py:func:`nvmath.device.compile_blas_execute`, which was
  missing from the public API.

.. releasenotes/notes/remove-deprecated-device-apis-2d6d63ac6983acd0.yaml @ b'189f8f78c24fb03acf2fbe18a405a074bf0f699a'

- Fixed :py:func:`nvmath.device.compile_blas_execute` to convert its
  ``code_type`` argument with ``parse_code_type``, matching the behavior
  of the other device APIs.

.. releasenotes/notes/ust-cpu-memspace-2d42883dedb36948.yaml @ b'73f627437a65cccc57ea7c20599005925e293c03'

- Added the ``stream`` argument to the :class:`nvmath.sparse.ust.Tensor` methods
  that were missing one.


.. _Release Notes_v1.0.0_Breaking Changes:

Breaking Changes
----------------

.. releasenotes/notes/1323-6a65fe42d6ae92ca.yaml @ b'6545db3303f73f99d5fce8081e8954e3cc4dabca'

- Changed :attr:`nvmath.bindings.cufftMp.XtSubFormat.FORMAT_FORMAT_UNDEFINED` to
  :attr:`nvmath.bindings.cufftMp.XtSubFormat.FORMAT_UNDEFINED`.

.. releasenotes/notes/1405-8548c314c47df3d5.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Deprecated function ``get_mxfp8_scale_offset`` was removed. Use
  :func:`~nvmath.linalg.advanced.helpers.matmul.get_block_scale_offset` instead.

.. releasenotes/notes/1434-9c2f7a1b8e4d6035.yaml @ b'e91ca56bc6e4e366661c3623c9f9c012c2eed5de'

- ``reset_operand(s)`` now requires at least one operand to be provided across
  all stateful APIs; otherwise it raises a ``ValueError``.

.. releasenotes/notes/cudss-v0.8-c7b55e64a26bc97b.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

- The common algorithm type (``nvmath.sparse.advanced.DirectSolverAlgType``)
  for the sparse advanced direct solver has been removed in favor of new
  algorithm types specific to each phase such as
  :class:`nvmath.sparse.advanced.DirectSolverFactorizationAlg`. This is a
  result of the changes in cuDSS ``v0.8.0``.

.. releasenotes/notes/dist-fft-reshape-rename-5b6004953558f033.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Distributed FFT API: renamed reshape option to redistribute.

.. releasenotes/notes/distributed-mm-inplace-default-703086a6636bcaef.yaml @ b'75d23c0ef50b8b8db5d2a2ef1a749dcf01ac66c3'

- Distributed matrix multiplication API is now inplace by default when C is provided (result
  is stored in C).

.. releasenotes/notes/remove-deprecated-device-apis-2d6d63ac6983acd0.yaml @ b'189f8f78c24fb03acf2fbe18a405a074bf0f699a'

- Removed the deprecated cuBLASDx API surface from
  :mod:`nvmath.device.cublasdx`:

  * the ``matmul()`` factory function (construct the ``Matmul`` class
    directly instead)
  * the ``Matmul`` methods ``definition()`` and ``create()``
  * the ``Matmul`` properties ``value_type``, ``input_type``,
    ``output_type``, ``shared_memory_size``, ``files`` and ``codes``
  * direct ``Matmul(...)`` invocation, replaced by ``Matmul.execute(...)``

.. releasenotes/notes/remove-deprecated-device-apis-2d6d63ac6983acd0.yaml @ b'189f8f78c24fb03acf2fbe18a405a074bf0f699a'

- Removed the deprecated cuFFTDx API surface from
  :mod:`nvmath.device.cufftdx`:

  * the ``fft()`` factory function (construct the ``FFT`` class directly
    instead)
  * the ``FFT`` methods ``definition()`` and ``create()``
  * the ``FFT`` properties ``requires_workspace`` and ``workspace_size``,
    together with the associated workspace support
  * the ``files`` property
  * direct ``FFT(...)`` invocation, replaced by ``FFT.execute(...)``

.. releasenotes/notes/remove-deprecated-device-apis-2d6d63ac6983acd0.yaml @ b'189f8f78c24fb03acf2fbe18a405a074bf0f699a'

- Removed the deprecated ``make`` property from the numba vector-type
  wrappers in :mod:`nvmath.device.types`. Use numba types directly.

.. releasenotes/notes/renamed-redistribute-api-15b2d38d3bf0d1a7.yaml @ b'dc0e982febbac34775fa9ef59874a3e1554d4d53'

- Distributed reshape has moved to ``nvmath.distributed.distribution.Redistribute`` and the
  API has been generalized to accept any Distribution type as input and output distribution.
  Note that the specific distributions that are supported depends on the capabilities of the
  underlying library (currently cuFFTMp).

.. releasenotes/notes/sparse-mm-cusparse-unsupported-6e046831c03c4515.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Support for ``complex32`` operands in sparse matrix multiplication
  (:func:`nvmath.sparse.generic.matmul`) has been removed. Passing ``complex32`` operands
  now raises a ``TypeError``.

.. releasenotes/notes/spmm-semiring-epilog-55dd8cfc98347299.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

- The ``semiring`` and ``epilog`` parameters to the generic sparse matrix
  multiplication (SpMM) plan (:meth:`nvmath.sparse.Matmul.plan`) have been
  removed. In addition, prolog cannot be specified for the ``c`` operand.
  We plan to introduce comprehensive support for these in the near future.


.. _Release Notes_v1.0.0_Documentation Changes:

Documentation Changes
---------------------

.. releasenotes/notes/1330-7b3e1c8a2f4d9e65.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Distributed APIs are now described as distributed host APIs.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- The device API documentation was refreshed.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- The device API examples were restructured to mirror the CUDALibrarySamples
  layout, and ``numba-cuda-mlir`` variants of the examples were added.

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- New cuSOLVERDx examples were added, matching the cuSOLVERDx 0.3 CUDA samples.

.. releasenotes/notes/initial-bootstrap-79b06486f05a8ead.yaml @ b'8564eec2c141460b3f175e0bc455f6f83cacc8ee'

- Adopted reno as the release notes manager.


.. _Release Notes_v1.0.0_Dependency Changes:

Dependency Changes
------------------

.. releasenotes/notes/device_apis-fd5f47ecb3c1c6cc.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- The ``numba`` extra now installs ``numba-cuda-mlir`` in addition to ``numba-cuda``.

.. releasenotes/notes/support-cuda-core-v1.0-e593ca888287f25a.yaml @ b'bd88ce8582306192ca0f8cfec8aecbc85e9f4f13'

- The ``nvmath-python`` package now requires ``cuda-core >=0.5, <2``
  (updated from ``cuda-core >=0.4.2, <1``).


.. _Release Notes_v1.0.0_Known Issues:

Known Issues
------------

.. releasenotes/notes/doc-known-issue-win-torch-mkl-clash-fa8b822de464c828.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- On Windows, if both ``torch`` and ``nvmath-python[cpu]`` are installed,
  there may be two ``libiomp5md.dll`` files present in the environment:

  * one shipped with ``torch``, and
  * one coming from transitive dependency: ``nvmath-python[cpu] -> mkl -> intel_openmp``.

  By default, OMP will terminate the program with an error when attempting to load both
  copies. As a workaround, users can:

  * set ``KMP_DUPLICATE_LIB_OK=TRUE`` environment variable to silence the error, or
  * remove one of the ``libiomp5md.dll`` copies, for instance, by uninstalling
    ``intel_openmp`` package (e.g. ``pip uninstall intel-openmp``).

.. releasenotes/notes/sparse-mm-cusparse-unsupported-6e046831c03c4515.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Sparse matrix multiplication (:func:`nvmath.sparse.generic.matmul`) using the CSC format
  with ``float16`` or ``bfloat16`` operands is not supported on newer CUDA Toolkit versions
  and raises ``cuSPARSEError NOT_SUPPORTED``.

.. releasenotes/notes/torch-distributed-issue-7f4ed875c2d6437c.yaml @ b'5cd42ebca9be67582dae73cc59315e35ef9344da'

- Using the :class:`nvmath.distributed.distributions.Box` distribution with
  :class:`nvmath.distributed.fft.FFT` and
  :class:`nvmath.distributed.distributions.Redistribute` APIs may result in
  a spurious validation error. The workaround is to use an equivalent
  :class:`nvmath.distributed.distributions.Slab` distribution.


.. _Release Notes_v1.0.0_Security Issues:

Security Issues
---------------

.. releasenotes/notes/1129-46c0a46645027e87.yaml @ b'f2f7dde968048e2a341d41e05133b24483033438'

- Added :meth:`~nvmath.linalg.advanced.Algorithm.from_numpy` and
  :meth:`~nvmath.linalg.advanced.Algorithm.as_numpy` so that Matmul plans may be saved
  without pickle.


nvmath-python v0.9.0
====================

Beta9 release.

* New universal sparse tensor (UST) and generic sparse matrix multiplication API
  (:mod:`nvmath.sparse.ust`, :class:`nvmath.sparse.Matmul`).
* Support for NVFP4 in the advanced matrix multiplication API, along with new helpers
  in :mod:`nvmath.linalg.advanced.helpers.matmul`:
  :func:`~nvmath.linalg.advanced.helpers.matmul.quantize_to_fp4`,
  :func:`~nvmath.linalg.advanced.helpers.matmul.unpack_fp4`,
  :class:`~nvmath.linalg.advanced.helpers.matmul.BlockScalingFormat`,
  :func:`~nvmath.linalg.advanced.helpers.matmul.to_block_scale`,
  :func:`~nvmath.linalg.advanced.helpers.matmul.get_block_scale_offset`, and
  :func:`~nvmath.linalg.advanced.helpers.matmul.expand_block_scale`.
* Distributed matrix multiplication API:

  * Support for FP8 and MXFP8 datatypes.
  * Support for epilogs.
  * Support for inplace operation.
* New ``release_operand(s)`` methods on :class:`nvmath.fft.FFT`,
  :class:`nvmath.linalg.advanced.Matmul`, :class:`nvmath.linalg.Matmul`,
  :class:`nvmath.tensor.BinaryContraction`, :class:`nvmath.tensor.TernaryContraction`,
  :class:`nvmath.sparse.advanced.DirectSolver`,
  :class:`nvmath.distributed.fft.FFT`,
  :class:`nvmath.distributed.linalg.advanced.Matmul`, and
  :class:`nvmath.distributed.reshape.Reshape` for releasing operand memory
  while preserving the plan.
* New :class:`nvmath.distributed.ProcessGroup` abstraction
  (:class:`nvmath.distributed.MPIProcessGroup`,
  :class:`nvmath.distributed.TorchProcessGroup`) for distributed APIs, allowing for
  initialization of ``nvmath.distributed`` with either ``mpi4py`` or ``torch.distributed``
  (thus making ``mpi4py`` optional). :func:`nvmath.distributed.initialize` still directly
  accepts an ``mpi4py`` communicator for convenience.
* Added a new pip extra (numba) which installs the appropriate numba toolchain for
  callback APIs without installing device API dependencies.
* New cuSOLVERDx device API in :mod:`nvmath.device`: high-level adapter classes
  and the lower-level :class:`nvmath.device.Solver` class that mimics
  the C++ cuSOLVERDx API. The available operations depend on the installed
  libmathdx version, see the
  :ref:`supported functions table <device-api-cusolver-supported-functions>`
  for the full list, version notes, and adapter mapping.
* Bindings updated to support libmathdx 0.3.2, which extends cuSOLVERDx functionality,
  and brings improvements to cuBLASDx and cuFFTDx.
* New experimental ``reset_operand(s)_unchecked`` methods on
  :class:`nvmath.linalg.advanced.Matmul`, :class:`nvmath.tensor.BinaryContraction`,
  :class:`nvmath.tensor.TernaryContraction`, and
  :class:`nvmath.distributed.fft.FFT` to minimize overhead in repeated calls,
  analogous to :meth:`nvmath.fft.FFT.reset_operand_unchecked` which was added in
  v0.8.0.
* New :func:`nvmath.fft.estimate_workspace_size` free function for estimating FFT
  workspace size.
* Added bindings for new APIs introduced in CTK version 13.2.0
* Added support for more compute types in the tensor contraction API and
  improved property getters for :class:`nvmath.tensor.ContractionPlanPreference`.
* Optimized internal ``release`` and ``reset_operand(s)`` code paths for FFT and tensor
  contraction by retaining inner tensor references, reducing per-call overhead.
* New preference classes :class:`nvmath.sparse.advanced.DirectSolverPlanPreferences`,
  :class:`nvmath.sparse.advanced.DirectSolverFactorizationPreferences`, and
  :class:`nvmath.sparse.advanced.DirectSolverSolutionPreferences` for configuring plan,
  factorization, and solution phases in a stateless direct sparse solver API call.
* Added Python 3.14 support.

Bugs Fixed
----------

* Fixed in-place C2R FFT repeated execution silently producing wrong results due
  to the input buffer being overwritten.
* Fixed some incorrectly named enums in cuFFT bindings.
* ``pivot_eps_algorithm``, ``pivot_eps``, ``hybrid_device_memory_limit``, and
  ``hybrid_execute_mode`` properties were returning the wrong values.
* cuFFT status codes from CUDA 13 were missing.
* ``FFT.create_key()`` and ``FFT.get_key()`` had mismatched outputs.
* ``apply_mxfp8_scale()`` could overflow.
* ``BinaryContraction`` outputs were not fully-owned by user and were overwritten by
  subsequent calls to ``BinaryContraction.contract()``.
* cuDSS ``DirectSolver`` rejected valid F-order matrices with shape ``(..., m, 1)`` because
  stride validation didn't account for the dummy last dimension
  (`#53 <https://github.com/NVIDIA/nvmath-python/issues/53>`_).
* Fixed LTOIR ABI correctness for device APIs where argument names and return types
  did not match the libmathdx functions.
* Fixed a missing synchronization for host-to-device torch tensor copy.
* Fixed missing fields in the cuBLASDx Numba matmul cache key, which could lead to
  stale cached results.
* Improved error handling for unsupported cuDSS ``FactorizationInfo`` and ``PlanInfo``
  attributes, which now raise ``RuntimeError`` instead of silently returning wrong
  values.
* Fixed ``reset_operands_unchecked`` semantics for FFT to match the checked version,
  behaving correctly when called after releasing operands.

Breaking Changes
----------------

* Removed the dx extra. Users should continue to use the cu12-dx or cu13-dx extra for
  installing device API dependencies.
* ``cuda-core >=0.4.2`` is now required.
* ``libmathdx >=0.3.1`` is now required.
* ``numba-cuda >=0.28.1`` is now required.
* ``cuTensor >=2.5.0`` is now required.
* ``cuBLASMp >=0.8.1`` is now required, which no longer uses NVSHMEM. This means that
  the NVSHMEM backend is no longer required for the distributed matrix multiplication API.
* The ``operand`` parameter to :class:`nvmath.fft.FFT` and
  :class:`nvmath.distributed.fft.FFT` is now positional-only.
* The following cusolverDn bindings getter functions now return their value directly:
  :func:`nvmath.bindings.cusolverDn.get_math_mode`,
  :func:`nvmath.bindings.cusolverDn.get_emulation_strategy`,
  :func:`nvmath.bindings.cusolverDn.get_fixed_point_emulation_mantissa_control`,
  :func:`nvmath.bindings.cusolverDn.get_fixed_point_emulation_max_mantissa_bit_count`,
  :func:`nvmath.bindings.cusolverDn.get_fixed_point_emulation_mantissa_bit_offset`,
  :func:`nvmath.bindings.cusolverDn.get_emulation_special_values_support`.
* ``reset_operand(s)`` no longer accepts ``None`` to release operands across all
  stateful APIs. The new ``release_operand(s)`` methods should be used instead.
* All parameters to ``reset_operands()`` are now keyword-only for
  tensor contraction, advanced matmul, generic matmul, distributed
  matmul, and cuDSS direct solver.
* :func:`nvmath.distributed.initialize` no longer accepts ``None`` for process group
  / communicator. It requires a concrete :class:`nvmath.distributed.ProcessGroup`
  instance or mpi4py communicator.

Known Issues
------------

* cuFFT in CUDA Toolkit 12.8, 12.9 may fail to compile LTO-IR callbacks
  on Blackwell devices (compute capability 12.0). As a workaround, the
  ``compute_capability`` argument in :func:`nvmath.fft.compile_prolog` and
  :func:`nvmath.fft.compile_epilog` can be set to ``'50'``.


nvmath-python v0.8.0
====================

Beta8 release.

* New pipeline and supporting features for device matrix multiplication APIs
  that enable applications such as floating-point emulation.
* Support for inplace operation in the advanced Matmul host APIs.
* Support for implicit batching in the generic Matmul host APIs.
* Windows support for the tensor contraction APIs.
* A new experimental :meth:`nvmath.fft.FFT.reset_operand_unchecked` API
  to reduce redundant checking and minimize overhead.
* Added bindings for new APIs introduced in CTK version 13.1.
* cuBLASMp bindings updated to 0.7

Bugs Fixed
----------

* The tensor contraction API always blocked in Beta7, even if asynchronous
  execution (the default) was requested. This has been fixed.
* Fixed the outdated references in the documentation that state the CuPy
  will be installed as part of nvmath-python extras. This was no longer true
  from Beta7 onwards.
* The internal references to the tensor contraction and direct solver operands
  held in those objects relied on garbage collection to be released. This
  has been fixed, so that the references are now released when the context
  manager exits or when the object is explicitly freed.
* A performance issue has been fixed for certain tensor contractions that
  involve small contraction extents along with large batch extents.


Breaking Changes
----------------

* The ``transpose`` option has been removed from the generic matrix
  multiplication qualifiers (:class:`nvmath.linalg.GeneralMatrixQualifier`,
  :class:`nvmath.linalg.DiagonalMatrixQualifier`,
  :class:`nvmath.linalg.SquareMatrixQualifier`,
  :class:`nvmath.linalg.HermitianMatrixQualifier`,
  :class:`nvmath.linalg.SymmetricMatrixQualifier`,
  :class:`nvmath.linalg.TriangularMatrixQualifier`). The transpose
  operation that the array library provides (``a.T``) should be
  used instead.

Known Issues
------------

* The use of Python logging set to the debug level (``logging.DEBUG``) may result
  in a ``TypeError`` when
  `compiling Numba kernels <https://github.com/NVIDIA/numba-cuda/issues/454>`_.

nvmath-python v0.7.0
====================

Beta7 release.

* This release supports CUDA 12 and CUDA 13. Support for CUDA 11 has been dropped.
* New binary and ternary tensor contraction host APIs on GPU.
* New generic host Matmul APIs that support dense and structured matrices (such as
  triangular and diagonal) on GPU and CPU.
* New distributed Matmul APIs to run on multi-node/multi-GPU systems.
* Support for 64-bit integer indexing for the sparse direct solver.
* The FFT and Matmul device APIs are now implicitly linked in kernels and the
  ``link=`` argument to :func:`numba.cuda.jit` is no longer needed.
* The device APIs now use custom types that lower to NumPy (host) or Numba (device)
  types. As a result of this, :attr:`nvmath.device.FFT.value_type` and
  ``nvmath.device.Matmul.value_type`` return NumPy types.

Bugs Fixed
----------

* `nvmath-python/#47 <https://github.com/NVIDIA/nvmath-python/issues/47>`_
  Fixed a "key error" bug that prevented use of complex-to-real double precision
  distributed FFT.
* `cuda-python/#852 <https://github.com/NVIDIA/cuda-python/issues/852>`_
  An internal symbol table used when loading symbols from libraries was made
  thread-safe.

Breaking Changes
----------------

* :func:`nvmath.distributed.initialize` now requires the ``backends`` argument, which
  was introduced to support more than one communication backend (NVSHMEM, NCCL, ...).
* The ``code_type`` argument was replaced by the ``sm`` argument in
  :class:`nvmath.device.FFT` and :class:`nvmath.device.Matmul`.

Deprecations
------------

* The ``nvmath.device.fft`` and ``nvmath.device.matmul`` utility functions
  are deprecated. Use :class:`nvmath.device.FFT` and :class:`nvmath.device.Matmul` instead.
* The Slab distribution has moved to :mod:`nvmath.distributed.distribution` and
  :attr:`nvmath.distributed.fft.Slab` will be removed in the future. Use
  :class:`nvmath.distributed.distribution.Slab` instead.

nvmath-python v0.6.0
====================

Beta6 release.

* This will be the last release to support CUDA 11.
* Added support for distributed R2C/C2R FFTs, along with support for non-uniform partition
  sizes across PEs.
* The ``distribution`` option for distributed FFTs is now a required keyword-only argument.
* To enable making CuPy an optional dependency, an internal ``NDBuffer`` datastructure
  was introduced that facilitates copying tensors across memory spaces and layouts. Users
  may notice a one-time latency for each unique layout since the copy kernel is JIT compiled
  and cached.
* Replaced internal logic with
  `cuda-pathfinder <https://github.com/NVIDIA/cuda-python/tree/main/cuda_pathfinder>`_ for
  locating libraries and components.

Bugs Fixed
----------

* The :meth:`nvmath.linalg.advanced.Matmul.autotune` method in the advanced Matmul APIs may
  not have selected the best kernel, since the L2-cache wasn't cleared.
* The return status of an internal call to a CUDA API  wasn't checked, resulting
  in a misleading error regarding memory limit.
* Fixed a use-after-free issue with the batched direct sparse solver.
* Fixed a deadlock that may occur in certain circumstances during distributed FFT.
* Added appropriate constraints for cuda-bindings based on the CTK version.
* Fixed missing logging messages when a Python logger was not created with ``force=True``.


Known Issues
------------

* The minimum supported versions for CuPy and PyTorch are out-of-date and will be increased
  in the next release.
* An internal symbol table used when loading symbols from libraries needs to be made
  thread-safe. This will be done in the next release.

nvmath-python v0.5.0
====================

Beta5 release.

* New single-GPU and hybrid CPU-GPU sparse direct solver APIs supporting SciPy, CuPy,
  and PyTorch.

Known Issues
------------

* Python overhead for matmul host-APIs has increased since v0.3.0 by 21 microseconds on
  average. We are investigating.

* CUDA 12.8.0, 12.8.1 and 12.9.0 have been known to miscompile cuBLASDx in some
  rare slow-path cases (see
  `cuBLASDx <https://docs.nvidia.com/cuda/cublasdx/0.4.0/index.html>`_ for more
  details).

nvmath-python v0.4.0
====================

Beta4 release.

* New distributed FFT APIs to run on multi-node/multi-GPU systems.
* New device matrix multiplication tensor API to enable advanced techniques such as
  cooperative copy and floating-point emulation using integer tensor cores.
* Transition from CuPy to `cuda-python (cuda.core)
  <https://nvidia.github.io/cuda-python/cuda-core/latest/>`_ for core CUDA constructs.

Bugs Fixed
----------

* FFT prolog or epilog fails to compile on ``SM >= 100``.

Known Issues
------------

* Python overhead for matmul host-APIs has increased since v0.3.0 by 21 microseconds on
  average. We are investigating.

nvmath-python v0.3.0
====================

Beta3 release.

* FP8 and MXFP8 support for the advanced matrix multiplication API.
* Notebook to illustrate use of FP8 and MXFP8 in the advanced matrix multiplication API.
* Added bindings for new APIs introduced in CTK version 12.8.

Bugs Fixed
----------

* The advanced matrix multiplication API may return an incorrect result when a bias vector
  is used along with 1-D A and C operands.

API Changes
-----------

* The ``last_axis_size`` option in :class:`nvmath.fft.FFTOptions` is removed in favor of
  ``last_axis_parity`` to better reflect its semantics.

nvmath-python v0.2.1
====================

Beta2 update 1 with improved diagnostics, testing enhancements, and bug fixes.

* New tests for batched epilogs and autotuning with epilogs for the advanced matrix
  multiplication APIs.
* Added more hypothesis-based tests for host APIs.
* Improved algorithm for detecting overlapping memory operands for certain sliced tensors,
  thereby supporting such layouts for FFTs.
* Added bindings for new APIs introduced in CTK versions 12.5 and 12.6.
* Further coding style fixes toward meeting PEP8 recommendations.
* Clarified batched semantics for matrix multiplication epilogs in the documentation.
* Code snippets in API docstrings are now tested.

Bugs Fixed
----------

* C2R FFT may fail with "illegal memory access" on sliced tensors.
* Improved diagnostics to detect incompatible combinations of scale and compute types for
  matrix multiplication, that previously may have resulted in incorrect results.
* Matrix multiplication provided incorrect results when operand A is a vector (number of
  dimensions=1).

API Changes
-----------

* The ``last_axis_size`` option in :class:`nvmath.fft.FFTOptions` is now deprecated in favor
  of ``last_axis_parity`` to better reflect its semantics.

.. note::

   Deprecated APIs will be removed in the next release.

nvmath-python v0.2.0
====================

Beta2 release.

* CPU execution space support for FFT libraries that conform to FFTW3 API (for example MKL,
  NVPL).
* Support for prolog and epilog callback for FFT, written in Python.
* New device APIs for random number generation.
* Notebooks to illustrate use of advanced matrix multiplication APIs.
* Introduced hypothesis-based tests for host APIs.
* Reduced Python overhead in ``execute`` methods.

Bugs Fixed
----------

* Matrix multiplication may fail with "illegal memory access" for K=1 with DRELU and DGELU
  epilogs.

Packaging
---------

* Added support for NumPy 2.
* Removed Python 3.9 support.
* Patching changes and pynvjitlink version.

Known issues
------------

* When ``compute_type`` argument of :class:`nvmath.linalg.advanced.Matmul` is set to
  ``COMPUTE_16F``, an incompatible default for ``scale_type`` is chosen, resulting in
  incorrect results for CTKs older than 12.6 and an error for CTK 12.6 and newer. As a
  workaround we recommend setting both ``compute_type`` and ``scale_type`` in a compatible
  manner according to `supported data types table
  <https://docs.nvidia.com/cuda/cublas/#cublasltmatmul>`_.

nvmath-python v0.1.0
====================

Initial beta release, with single-GPU support only.

* FFT APIs based on cuFFT.
* Specialized matrix multiplication APIs based on cuBLASLt.
* Device APIs for FFT and matrix multiplication based on the MathDx libraries.

The required and optional dependencies are summarized in the :ref:`cheatsheet <cheatsheet>`.

*Limitations:*

* Many matrix multiplication epilogs require CTK 11.5+, and a few require CTK 11.8+.
  Refer to `cuBLAS Release Notes
  <https://docs.nvidia.com/cuda/archive/11.8.0/cuda-toolkit-release-notes/index.html
  #title-cublas-library>`_
  for more details.

Disclaimer
==========

nvmath-python is in a Beta state. Beta products may not be fully functional, may contain
errors or design flaws, and may be changed at any time without notice. We appreciate your
feedback to improve and iterate on our Beta products.
