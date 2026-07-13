.. module:: nvmath.bindings.cusolverSp

cuSOLVERSp (:mod:`nvmath.bindings.cusolverSp`)
==============================================

.. warning::

   **Deprecated.** NVIDIA's cuSOLVERSp sparse LAPACK APIs are deprecated; see the CUDA
   documentation linked below. For better performance and ongoing support, prefer
   `cuDSS <https://docs.nvidia.com/cuda/cudss/>`__ for sparse direct factorization and
   solves. In nvmath-python, use :mod:`nvmath.bindings.cudss` for cuDSS bindings.

For detailed documentation on the original C APIs, refer to the
`cuSOLVERSp documentation`_.

.. _`cuSOLVERSp documentation`: https://docs.nvidia.com/cuda/cusolver/
   #cusolversp-sparse-lapack-function-reference-deprecated

Functions
*********

.. autosummary::
   :toctree: generated/

   ccsreigs_host
   ccsreigvsi
   ccsreigvsi_host
   ccsrlsqvqr_host
   ccsrlsvchol
   ccsrlsvchol_host
   ccsrlsvlu_host
   ccsrlsvqr
   ccsrlsvqr_host
   ccsrqr_buffer_info_batched
   ccsrqrsv_batched
   ccsrzfd_host
   create
   create_csrqr_info
   dcsreigs_host
   dcsreigvsi
   dcsreigvsi_host
   dcsrlsqvqr_host
   dcsrlsvchol
   dcsrlsvchol_host
   dcsrlsvlu_host
   dcsrlsvqr
   dcsrlsvqr_host
   dcsrqr_buffer_info_batched
   dcsrqrsv_batched
   dcsrzfd_host
   destroy
   destroy_csrqr_info
   get_stream
   scsreigs_host
   scsreigvsi
   scsreigvsi_host
   scsrlsqvqr_host
   scsrlsvchol
   scsrlsvchol_host
   scsrlsvlu_host
   scsrlsvqr
   scsrlsvqr_host
   scsrqr_buffer_info_batched
   scsrqrsv_batched
   scsrzfd_host
   set_stream
   xcsrissym_host
   xcsrmetisnd_host
   xcsrperm_buffer_size_host
   xcsrperm_host
   xcsrqr_analysis_batched
   xcsrsymamd_host
   xcsrsymmdq_host
   xcsrsymrcm_host
   zcsreigs_host
   zcsreigvsi
   zcsreigvsi_host
   zcsrlsqvqr_host
   zcsrlsvchol
   zcsrlsvchol_host
   zcsrlsvlu_host
   zcsrlsvqr
   zcsrlsvqr_host
   zcsrqr_buffer_info_batched
   zcsrqrsv_batched
   zcsrzfd_host
