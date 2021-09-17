################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.16 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

#
# Usage:
#
# portable_target_add_library(<target>
#       [SHARED]
#       [STATIC]
#       [ALIAS <alias>]
#
# If neither SHARED nor STATIC is specified, both are set to ON.
#
# NOTE Since cmake v3.11 source files is optional for add_executable/add_library
#

function (portable_target_add_library TARGET)
    # TODO This variables may be configurable
    set(_objlib_siffix "_OBJLIB")
    set(_static_siffix "-static")
    set(_static_alias_siffix "::static")

    set(boolparm SHARED STATIC)
    set(singleparm SHARED_ALIAS STATIC_ALIAS)
    set(multiparm)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SHARED AND NOT _arg_STATIC)
        set(_arg_SHARED ON)
        set(_arg_STATIC ON)
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        set(_arg_STATIC OFF)
    endif()

    # Make object files for STATIC and SHARED targets
    add_library(${TARGET}${_objlib_siffix} OBJECT)

    # Shared libraries need PIC
    # For SHARED and MODULE libraries the POSITION_INDEPENDENT_CODE target property
    # is set to ON automatically, but need for OBJECT type
    set_target_properties(${TARGET}${_objlib_siffix} PROPERTIES POSITION_INDEPENDENT_CODE ON)

    if (_arg_SHARED)
        add_library(${TARGET} SHARED $<TARGET_OBJECTS:${TARGET}${_objlib_siffix}>)
        set_target_properties(${TARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON)
    endif()

    if (_arg_STATIC)
        add_library(${TARGET}${_static_siffix} STATIC $<TARGET_OBJECTS:${TARGET}${_objlib_siffix}>)
    endif()

    if (_arg_ALIAS)
        if (_arg_SHARED)
            add_library(${_arg_ALIAS} ALIAS ${TARGET})
        endif()

        if (_arg_STATIC)
            add_library(${_arg_ALIAS}${_static_alias_siffix} ALIAS ${TARGET}${_static_siffix})
        endif()
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        target_compile_definitions(${TARGET} PUBLIC "-DANDROID=1")
    endif()
endfunction(portable_target_add_library)

