
***********************************
cuFFTDx APIs (:mod:`nvmath.device`)
***********************************

.. _device-api-cufft-overview:

Overview
========

These APIs offer integration with the NVIDIA cuFFTDx library.
Detailed documentation of cuFFTDx can be found in the
:cufftdx_doc:`cuFFTDx documentation <index.html>`.

.. note::

   The FFT device APIs support both the ``numba-cuda`` and the ``numba-cuda-mlir``
   compilers. See :ref:`device-api-supported-compilers` for details.

.. note::

   The :class:`~nvmath.device.FFT` device APIs in module
   :mod:`nvmath.device` currently support cuFFTDx |cufftdx_version|, also available
   as part of MathDx |mathdx_version|. All functionalities from the C++ library are
   supported with the exception of cuFFTDx C++ APIs with a workspace argument, which
   are currently not available in nvmath-python. This means that certain FFT sizes
   and configurations that require a workspace are not supported. For more information
   on which sizes and configurations require a workspace, please refer to the
   :cufftdx_doc:`cuFFTDx Supported Functionality documentation <requirements_func.html#supported-functionality>`.

.. _device-api-cufft-reference:

API Reference
=============

.. currentmodule:: nvmath.device

.. autosummary::
   :toctree: generated/

   FFT
