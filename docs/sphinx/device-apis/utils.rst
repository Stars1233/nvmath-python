*******************************************
Device API utilities (:mod:`nvmath.device`)
*******************************************

.. _device-api-util-overview:

Overview
========

nvmath-python provides the following device-side utilities.

.. note::

   For most use cases, prefer the :class:`~nvmath.device.Complex` and
   :class:`~nvmath.device.Vector` types and their instances (``complex32``,
   ``complex64``, ``complex128``, ``half2``, and ``half4``). During compilation, they
   resolve automatically to the matching underlying type: with ``numba-cuda``, the
   vector types provided by nvmath-python, and with ``numba-cuda-mlir``, the compiler's
   native complex and vector types.

   They also carry a host-side numpy dtype (the ``dtype`` property), so they can be used
   for host allocation as well.

   The remaining Numba vector types (``float16x2`` to ``uint32x4`` and their ``*_type``
   variants) are supported only with the ``numba-cuda`` compiler. nvmath-python provides
   them because ``numba-cuda`` does not expose all of the required vector types (for
   example, the ``float16`` vectors). The ``numba-cuda-mlir`` compiler exposes all of them
   in the ``numba_cuda_mlir.cuda.vector_types`` module, so the
   nvmath-python ones are neither needed nor supported there.

   See :ref:`device-api-supported-compilers` for an overview of the compiler support.

.. _device-api-util-reference:

API Reference
=============

.. currentmodule:: nvmath.device

.. autosummary::
   :toctree: generated/

   current_device_lto
   current_device_sm
   Complex
   Vector
   complex32
   complex64
   complex128
   np_float16x2
   np_float16x4
   half2
   half4
   float16x2
   float16x2_type
   float16x4
   float16x4_type
   float32x2
   float32x2_type
   float32x4
   float32x4_type
   float64x2
   float64x2_type
   float64x4
   float64x4_type
   uint32x4
   uint32x4_type

.. autosummary::
   :toctree: generated/
   :template: namedtuple

   ISAVersion
   Code
   CodeType
   ComputeCapability
   Dim3
