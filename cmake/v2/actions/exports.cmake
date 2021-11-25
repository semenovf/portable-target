################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.11.25 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

#
# Usage:
#
# portable_target_exports(<target> <export_def> <static_def>)
#
# MSVC specific function.
# Declares dllexport/dllimport macros
#

function (portable_target_exports TARGET EXPORT_DEF STATIC_DEF)
    if (MSVC)
        _portable_target_set_properties_defaults()

        portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)
        portable_target_get_property(STATIC_SUFFIX _static_suffix)

        # For library target definitions must be assigned to OBJECT target
        if (TARGET ${TARGET}${_objlib_suffix})
            get_target_property(_target_type ${TARGET}${_objlib_suffix} TYPE)

            if (NOT _target_type STREQUAL "OBJECT_LIBRARY")
                _portable_target_error(${TARGET} "Expected OBJECT TYPE for '${TARGET}${_objlib_suffix}'")
            endif()

            target_compile_definitions(${TARGET}${_objlib_suffix} PRIVATE -D${EXPORT_DEF})

            if (TARGET ${TARGET})
                target_compile_definitions(${TARGET} PUBLIC -D{EXPORT_DEF})
            endif()

            if (TARGET ${TARGET}{_static_suffix})
                target_compile_definitions(${TARGET} PUBLIC -D{STATIC_DEF})
            endif()
        endif()
   endif(MSVC)
endfunction(portable_target_exports)
