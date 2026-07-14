.. module:: nvmath.bindings.cusolverMp

cuSOLVERMp (:mod:`nvmath.bindings.cusolverMp`)
==============================================

For detailed documentation on the original C APIs, refer to the `cuSOLVERMp documentation
<https://docs.nvidia.com/cuda/cusolvermp/>`_.

Enums and constants
*******************

.. autosummary::
   :toctree: generated/

   GridMapping
   NewtonSchulzDescriptorAttribute
   cuSOLVERMpError

Functions
*********

.. autosummary::
   :toctree: generated/

   buffer_deregister
   buffer_register
   create
   create_device_grid
   create_matrix_desc
   destroy
   destroy_grid
   destroy_matrix_desc
   gels
   gels_buffer_size
   geqrf
   geqrf_buffer_size
   get_emulation_strategy
   get_math_mode
   get_newton_schulz_descriptor_attribute_dtype
   get_stream
   get_version
   getrf
   getrf_buffer_size
   getrs
   getrs_buffer_size
   laset
   logger_force_disable
   logger_open_file
   logger_set_file
   logger_set_level
   logger_set_mask
   matrix_gather_d2h
   matrix_scatter_h2d
   newton_schulz
   newton_schulz_buffer_size
   newton_schulz_descriptor_create
   newton_schulz_descriptor_destroy
   newton_schulz_descriptor_get_attribute
   newton_schulz_descriptor_set_attribute
   numroc
   orgqr
   orgqr_buffer_size
   ormqr
   ormqr_buffer_size
   ormtr
   ormtr_buffer_size
   potrf
   potrf_buffer_size
   potrs
   potrs_buffer_size
   set_emulation_strategy
   set_math_mode
   set_stream
   stedc
   stedc_buffer_size
   syevd
   syevd_buffer_size
   sygst
   sygst_buffer_size
   sygvd
   sygvd_buffer_size
   sytrd
   sytrd_buffer_size
