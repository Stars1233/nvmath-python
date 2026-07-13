**************
Linear Algebra
**************

.. _linalg-overview:

Overview
========

The Linear Algebra module :mod:`nvmath.linalg` in nvmath-python leverages various NVIDIA
math libraries to support dense [#]_ linear algebra computations. As of version 1.0.0, we
offer matrix multiplication APIs as well as a dense direct linear solver API.

For matrix multiplication, we offer both a generic API based on the cuBLAS and NVPL
libraries and a specialized API (:mod:`nvmath.linalg.advanced`) based on the cuBLASLt
library. See :ref:`Generic and Specialized APIs <generic specialized>` for motivation.
At a high-level, if your use case is predominantly GEMM and requires particular flexibility
in matrix data layouts, input and/or compute types, and also in choosing the algorithmic
implementation, look at the specialized APIs. Otherwise, look at the generic APIs.

For solving dense square linear systems of the form ``a @ x = b`` via LU factorization,
we offer a generic dense direct solver (:func:`~nvmath.linalg.direct_solver` and the
stateful :class:`~nvmath.linalg.DirectSolver`).

.. _linalg-api-reference:

API Reference
=============

.. module:: nvmath.linalg

Generic Linear Algebra APIs (:mod:`nvmath.linalg`)
--------------------------------------------------

The generic linear algebra module bundles host APIs that share a minimal, broadly
applicable surface. Beyond that, each operation has its own operand model and
configuration; the subsections below list each operation's surface independently.


Shared Utilities
^^^^^^^^^^^^^^^^

.. autosummary::
   :toctree: generated/
   :template: dataclass

   ExecutionCPU
   ExecutionCUDA


Matrix multiplication
^^^^^^^^^^^^^^^^^^^^^

Accepts structured matrices via :ref:`matrix qualifiers <matrix-tensor-qualifiers>`
(general, triangular, symmetric, Hermitian, diagonal) in addition to dense full
matrices. Runs on either CPU or CUDA execution.


.. autosummary::
   :toctree: generated/

   matmul
   Matmul
   matrix_qualifiers_dtype
   ComputeType
   DiagonalMatrixQualifier
   GeneralMatrixQualifier
   HermitianMatrixQualifier
   InvalidMatmulState
   SymmetricMatrixQualifier
   TriangularMatrixQualifier
   SideMode
   FillMode
   DiagType

.. autosummary::
   :toctree: generated/
   :template: dataclass

   MatmulOptions


Direct linear solver
^^^^^^^^^^^^^^^^^^^^

Solves the dense system ``a @ x = b`` for a *general* square ``a`` and dense ``b``
(including implicitly and explicitly batched inputs), via LU factorization on the GPU.
Execution is CUDA-only: host-side operands are copied to the selected device for
the factorization and solve using the triangular factors.
Native CPU execution is not available today but may be added in a future release.

.. autosummary::
   :toctree: generated/

   direct_solver
   DirectSolver
   InvalidDirectSolverState

.. autosummary::
   :toctree: generated/
   :template: dataclass

   DirectSolverOptions

.. module:: nvmath.linalg.advanced

Specialized Linear Algebra APIs (:mod:`nvmath.linalg.advanced`)
---------------------------------------------------------------

The specialized linear algebra module includes a matrix multiplication API which only
accepts general matrices, but provides extra functionality such as epilog functions, more
options and controls over computational precision, and control over algorithm selection and
planning.

.. autosummary::
   :toctree: generated/

   matmul
   matrix_qualifiers_dtype
   Algorithm
   Matmul
   MatmulComputeType
   MatmulEpilog
   MatmulInnerShape
   MatmulNumericalImplFlags
   MatmulReductionScheme

.. autosummary::
   :toctree: generated/
   :template: dataclass

   MatmulEpilogPreferences
   MatmulOptions
   MatmulPlanPreferences
   MatmulQuantizationScales

Helpers
^^^^^^^

The Specialized Linear Algebra helpers module :mod:`nvmath.linalg.advanced.helpers`
provides helper functions to facilitate working with some of the complex features of
:mod:`nvmath.linalg.advanced` module.

Matmul helpers (:mod:`nvmath.linalg.advanced.helpers.matmul`)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

.. module:: nvmath.linalg.advanced.helpers.matmul

.. autosummary::
   :toctree: generated/

   BlockScalingFormat
   create_mxfp8_scale
   invert_mxfp8_scale
   apply_mxfp8_scale
   quantize_to_fp4
   unpack_fp4
   get_block_scale_offset
   to_block_scale
   expand_block_scale

.. rubric:: Footnotes

.. [#] See :ref:`Sparse Linear Algebra <sparse-overview>` for sparse operations.
