Getting Started
***************

nvmath-python brings the power of the NVIDIA math libraries to the Python ecosystem.
The package aims to provide intuitive Pythonic APIs that provide users full access
to all the features offered by NVIDIA's libraries in a variety of execution spaces.
nvmath-python works seamlessly with existing Python array/tensor frameworks and focuses
on providing functionality that is missing from those frameworks.

To learn more about the design of nvmath-python, visit our :doc:`Overview<overview>`.

Installation
============

To quickly install nvmath-python just run the following command:

.. code-block:: bash
   :substitutions:

    pip install nvmath-python[cu12-dx]==|nvmath-python_version|

.. important::
    Using at least one of the ``pip`` extras is required for all ``pip`` installs to
    ensure that nvmath-python's dependencies are correctly constrained.

.. note::
    Specify the version of nvmath-python to ensure that pip doesn't install
    an outdated version if you're using a version of Python that is no longer supported.

For more details visit the :doc:`Installation Guide<installation>`.

Examples
=========

In the examples below, we quickly demonstrate the basic capabilities
of nvmath-python. You can find more examples in our
`GitHub repository <https://github.com/NVIDIA/nvmath-python/tree/main/examples>`_.

Matrix multiplication
---------------------

Using the nvmath-python API allows access to all parameters of the underlying
NVIDIA cuBLASLt library.
Some of these parameters are unavailable in other packages that wrap NVIDIA's C-API
libraries.

.. doctest::

    >>> import cupy as cp
    >>> import nvmath
    >>>
    >>> m, n, k = 123, 456, 789
    >>> a = cp.random.rand(m, k).astype(cp.float32)
    >>> b = cp.random.rand(k, n).astype(cp.float32)
    >>>
    >>> # Use the stateful nvmath.linalg.advanced.Matmul object in order to separate planning
    >>> # from actual execution of matrix multiplication. nvmath-python allows you to fine-tune
    >>> # your operations by, for example, selecting a mixed-precision compute type.
    >>> options = {
    ...     "compute_type": nvmath.linalg.advanced.MatmulComputeType.COMPUTE_32F_FAST_16F
    ... }
    >>> with nvmath.linalg.advanced.Matmul(a, b, options=options) as mm:
    ...     algorithms = mm.plan()
    ...     result = mm.execute()

To learn more about matrix multiplication in nvmath-python, have a look at
:py:class:`~nvmath.linalg.advanced.Matmul`.

FFT with callback
-----------------

User-defined functions can be `compiled to the LTO-IR format
<https://docs.nvidia.com/cuda/cufft/index.html#lto-load-and-store-callback-routines>`_ and
provided as epilog or prolog to the FFT operation, allowing for Link-Time Optimization and
fusing.

This example shows how to perform a convolution by providing a Python callback function as
prolog to the IFFT operation.

.. doctest::

    >>> import cupy as cp
    >>> import nvmath
    >>>
    >>> # Create the data for the batched 1-D FFT.
    >>> B, N = 256, 1024
    >>> a = cp.random.rand(B, N, dtype=cp.float64) + 1j * cp.random.rand(B, N, dtype=cp.float64)
    >>>
    >>> # Create the data to use as a filter.
    >>> filter_data = cp.sin(a)
    >>>
    >>> # Define the prolog function for the inverse FFT.
    >>> # A convolution corresponds to pointwise multiplication in the frequency domain.
    >>> def convolve(data_in, offset, filter_data, unused):
    ...     # Note we are accessing `data_out` and `filter_data` with a single `offset` integer,
    ...     # even though the input and `filter_data` are 2D tensors (batches of samples).
    ...     # Care must be taken to ensure that both arrays accessed here have the same memory
    ...     # layout.
    ...     return data_in[offset] * filter_data[offset] / N
    >>>
    >>> # Compile the prolog to LTO-IR.
    >>> with cp.cuda.Device():
    ...     prolog = nvmath.fft.compile_prolog(convolve, "complex128", "complex128")
    >>>
    >>> # Perform the forward FFT, followed by the inverse FFT, applying the filter as a prolog.
    >>> r = nvmath.fft.fft(a, axes=[-1])
    >>> r = nvmath.fft.ifft(r, axes=[-1], prolog={
    ...         "ltoir": prolog,
    ...         "data": filter_data.data.ptr
    ...     })

For further details, see the :ref:`FFT callbacks documentation <fft-callback>`.

Device APIs
-----------

The device APIs of nvmath-python allow you to access the functionalities
of cuFFTDx, cuBLASDx, cuSOLVERDx, and cuRAND libraries in your kernels.

This example shows how to solve a linear system ``A @ x = b`` directly inside
a kernel with the cuSOLVERDx-based :py:class:`nvmath.device.LUPivotSolver`,
which uses LU factorization with partial pivoting. The solver device functions
accept data in global memory or in shared memory (recommended for
performance).

.. doctest::

    >>> import cupy as cp
    >>> import numpy as np
    >>> from numba import cuda
    >>> from nvmath.device import LUPivotSolver
    >>>
    >>> n = 8
    >>> solver = LUPivotSolver(
    ...     size=(n, n, 1),
    ...     precision=np.float64,
    ...     execution="Block",
    ...     arrangement=("row_major", "row_major"),
    ... )
    >>> n_ipiv = solver.ipiv_size
    >>>
    >>> # Define a kernel that factorizes A and solves the system in place.
    >>> @cuda.jit
    ... def kernel(a, b, info):
    ...     ipiv = cuda.shared.array(n_ipiv, dtype=np.int32)
    ...     solver.factorize(a, ipiv, info)
    ...     cuda.syncthreads()
    ...     solver.solve(a, ipiv, b)
    >>>
    >>> # Prepare a random system directly on the GPU.
    >>> rng = cp.random.default_rng(2026)
    >>> a = rng.standard_normal((n, n))
    >>> b = rng.standard_normal(n)
    >>> info = cp.empty(solver.info_shape, dtype=solver.info_type)
    >>>
    >>> # Compute the reference solution before the kernel overwrites a and b.
    >>> x_ref = cp.linalg.solve(a, b)
    >>>
    >>> kernel[1, solver.block_dim](a, b, info)
    >>> cuda.synchronize()
    >>>
    >>> # The solution x overwrites b.
    >>> print(cp.allclose(b, x_ref))
    True

To learn more about this and other Device APIs,
visit the documentation of :mod:`nvmath.device`.
