################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.16 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/category.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/compile_options.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

#
# Usage:
#
# portable_target_add_library(<target>
#       [CATEGORIES category...]
#       [INTERFACE]
#       [SHARED]
#       [STATIC]
#       [NO_UNICODE]
#       [NO_BIGOBJ]
#       [ALIAS alias]
#       [OUTPUT dir]
#       [COMPONENT name])
#
# NO_UNICODE (MSVC specific option)
#       Disable UNICODE support.
#
# NO_BIGOBJ (MSVC specific option)
#       Disable increase the number of sections that an object file can contain.
#       By default `/bigobj` option is set for compiler.
#       See [https://docs.microsoft.com/en-us/cpp/build/reference
#           /bigobj-increase-number-of-sections-in-dot-obj-file
#           ?redirectedfrom=MSDN&view=msvc-160]
#
# COMPONENT name
#       An installation component name with which the install rule is
#       associated.
#
# If neither SHARED nor STATIC and no INTERFACE is specified, both are set to ON.
#
# NOTE Since cmake v3.11 source files is optional for add_executable/add_library
#

function (portable_target_add_library TARGET)
    _portable_target_set_properties_defaults()

    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)
    portable_target_get_property(STATIC_SUFFIX _static_suffix)
    portable_target_get_property(STATIC_ALIAS_SUFFIX _static_alias_suffix)

    set(boolparm SHARED STATIC INTERFACE NO_UNICODE NO_BIGOBJ)
    set(singleparm ALIAS OUTPUT COMPONENT)
    set(multiparm CATEGORIES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    # Explicit STATIC keyword do not ignore on Android
    if (NOT _arg_SHARED AND NOT _arg_STATIC)
        set(_arg_SHARED ON)

        if (CMAKE_SYSTEM_NAME STREQUAL "Android")
            set(_arg_STATIC OFF)
        else()
            set(_arg_STATIC ON)
        endif()
    endif()

    if (NOT _arg_INTERFACE)
        # Make object files for STATIC and SHARED targets
        add_library(${TARGET}${_objlib_suffix} OBJECT)

        if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_BIGOBJ)
            target_compile_options(${TARGET}${_objlib_suffix} PRIVATE "/bigobj")
        endif()

        if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_UNICODE)
            target_compile_definitions(${TARGET}${_objlib_suffix} PRIVATE "/D_UNICODE /DUNICODE")
        endif()

        # Shared libraries need PIC
        # For SHARED and MODULE libraries the POSITION_INDEPENDENT_CODE target property
        # is set to ON automatically, but need for OBJECT type
        set_target_properties(${TARGET}${_objlib_suffix} PROPERTIES POSITION_INDEPENDENT_CODE ON)

        if (_arg_SHARED)
            add_library(${TARGET} SHARED $<TARGET_OBJECTS:${TARGET}${_objlib_suffix}>)
            set_target_properties(${TARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON)
        endif()

        if (_arg_STATIC)
            add_library(${TARGET}${_static_suffix} STATIC $<TARGET_OBJECTS:${TARGET}${_objlib_suffix}>)
        endif()

        if (_arg_ALIAS)
            if (_arg_SHARED)
                add_library(${_arg_ALIAS} ALIAS ${TARGET})
            endif()

            if (_arg_STATIC)
                add_library(${_arg_ALIAS}${_static_alias_suffix} ALIAS ${TARGET}${_static_suffix})
            endif()
        endif()
    else ()
        add_library(${TARGET} INTERFACE)

        if (_arg_ALIAS)
            add_library(${_arg_ALIAS} ALIAS ${TARGET})
        endif()
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        portable_target_compile_options(${TARGET} "-DANDROID=1")
    endif()

    # XXX_OUTPUT_DIRECTORY properties not applicable for INTERFACE library.
    if (NOT _arg_INTERFACE)
        if (_arg_OUTPUT AND _arg_STATIC)
            _portable_target_trace(${TARGET}${_static_suffix} "Archive output directory: [${_arg_OUTPUT}]")

            set_target_properties(${TARGET}${_static_suffix}
                PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY "${_arg_OUTPUT}")
        endif()

        if (_arg_OUTPUT AND _arg_SHARED)
            _portable_target_trace(${TARGET} "Library output directory: [${_arg_OUTPUT}]")
            set_target_properties(${TARGET}
                PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY "${_arg_OUTPUT}")
        endif()
    endif()

    if (_arg_CATEGORIES)
        portable_target_set_category(${TARGET} ${_arg_CATEGORIES})
    endif()

    if (_arg_COMPONENT)
        set_target_properties(${TARGET}
            PROPERTIES
            COMPONENT "${_arg_COMPONENT}")
    endif(_arg_COMPONENT)
endfunction(portable_target_add_library)
