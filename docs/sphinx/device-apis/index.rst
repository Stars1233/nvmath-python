
*************************
nvmath-python Device APIs
*************************

.. experimental:: module

.. module:: nvmath.device

.. _device-api-overview:

The device module of nvmath-python :mod:`nvmath.device` offers integration with NVIDIA's
high-performance computing libraries through device APIs for
:cufftdx_doc:`cuFFTDx <index.html>`,
:cublasdx_doc:`cuBLASDx <index.html>`,
:cusolverdx_doc:`cuSOLVERDx <index.html>`,
and `cuRAND
<https://docs.nvidia.com/cuda/curand/group__DEVICE.html#group__DEVICE>`_.
Device APIs can only be called from CUDA device or kernel code, and execute on the GPU.

Users may take advantage of the device module via the approaches below:

- ``numba-cuda`` Extensions: Users can access these device APIs via Numba by utilizing
  specific extensions that simplify the process of defining functions, querying device
  traits, and calling device functions.
- ``numba-cuda-mlir`` Extensions: The same extensions are available with the MLIR-based
  Numba CUDA compiler. See :ref:`device-api-supported-compilers` for the current
  support status.
- Third-party JIT Compilers: The APIs are also available through low-level interfaces in
  other JIT compilers, allowing advanced users to work directly with the raw device code.
  See :ref:`device-api-third-party-ltoir`.

.. note::

   The :class:`~nvmath.device.FFT`, :class:`~nvmath.device.Matmul`, and
   :class:`~nvmath.device.Solver` device APIs in module :mod:`nvmath.device`
   currently support cuFFTDx |cufftdx_version|, cuBLASDx |cublasdx_version|, and
   cuSOLVERDx |cusolverdx_version|, also available as part of MathDx
   |mathdx_version|. Refer to the per-library pages below for the supported
   functionality. Notably, cuFFTDx C++ APIs with a workspace argument are
   currently not available in nvmath-python.

.. _device-api-supported-compilers:

Supported Compilers
===================

The device API objects (:class:`~nvmath.device.FFT`, :class:`~nvmath.device.Matmul`,
and :class:`~nvmath.device.Solver`) can be used
with both the ``numba-cuda`` and ``numba-cuda-mlir`` compilers. Switching between the
compilers requires changing only the import of the ``cuda`` module:

.. code-block:: python

    import numpy as np
    from numba_cuda_mlir import cuda
    # from numba import cuda  # the only change needed to use numba-cuda

    from nvmath.device import Matmul

    MM = Matmul(
        size=(32, 32, 32),
        precision=np.float64,
        data_type="real",
        arrangement=("row_major", "col_major", "col_major"),
        execution="Block",
    )

    @cuda.jit
    def kernel(alpha, a, b, beta, c):
        # stage the a, b and c matrices in shared memory
        ...
        MM.execute(alpha, smem_a, smem_b, beta, smem_c)
        # store the result back to global memory
        ...

.. note::

   There are currently two limitations when using ``numba-cuda-mlir``:

   - the :mod:`nvmath.device.random` APIs are available only with ``numba-cuda``,
   - the advanced :class:`~nvmath.device.Matmul` APIs (opaque tensors, accumulators,
     and pipelines) are available only with ``numba-cuda``.

.. _device-api-third-party-ltoir:

Using Device APIs with Third-party Compilers
============================================

For JIT compilers other than the supported Numba compilers, the device functions can be
obtained directly in the LTO-IR format with the ``compile_blas_execute``,
``compile_fft_execute``, and ``compile_solver_execute`` functions. The example below
compiles the execute function of a Matmul object. It returns the LTO-IR code together
with the name of the C-ABI symbol to link against:

.. code-block:: python

    import numpy as np

    from nvmath.device import Matmul, compile_blas_execute, current_device_lto

    MM = Matmul(
        size=(32, 32, 32),
        precision=np.float32,
        data_type="real",
        arrangement=("row_major", "col_major", "col_major"),
        execution="Block",
    )

    code, symbol = compile_blas_execute(
        MM, code_type=current_device_lto(), execute_api="static_leading_dimensions"
    )

    ltoir = code.data  # the LTO-IR buffer to pass to the compiler or linker

.. toctree::
   :caption: Contents
   :maxdepth: 1

   Device API utilities <utils.rst>
   cuBLASDx <cublas.rst>
   cuFFTDx <cufft.rst>
   cuSOLVERDx <cusolver.rst>
   cuRAND Device APIs <curand.rst>
