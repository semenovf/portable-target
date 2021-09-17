################################################################################
# Copyright (c) 2019-2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2019.12.10 Initial version.
#      2020.09.03 Splitted into Functions.cmake, AndroidToolchain.cmake and PortableTarget.cmake.
#      2021.03.06 Added support for extra Android SSL libraries.
#      2021.09.07 Started version 2.
###############################################################################
cmake_minimum_required(VERSION 3.11)

set(_PORTABLE_TARGET_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})
include(${_PORTABLE_TARGET_ROOT_DIR}/Functions.cmake)

#
# Usage:
#
# portable_target(<action> <target> <action-options>)
#
# Available actions (case sensitive):
#
# ADD_EXECUTABLE
# APPLICATION         Add executable or shared library for Android.
#
# ADD_LIBRARY
# LIBRARY             Add both shared and static (with '-static' suffix by default)
#                     libraries, or shared library only for Android).
#
# DEFINITIONS         Add compile defintions (see target_compile_definitions)
# INCLUDE_DIRECTORIES Add include directories (see target_include_directories)
#
function (portable_target ACTION TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    _portable_target_status(${TARGET} "Action: [${ACTION}]")

    if (ACTION STREQUAL "ADD_EXECUTABLE" OR ACTION STREQUAL "APPLICATION")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_executable.cmake)
        portable_target_add_executable(${TARGET} "${_arg_UNPARSED_ARGUMENTS}")
    elseif (ACTION STREQUAL "ADD_LIBRARY" OR ACTION STREQUAL "LIBRARY")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_library.cmake)
        portable_target_add_library(${TARGET} "${_arg_UNPARSED_ARGUMENTS}")
    elseif (ACTION STREQUAL "SOURCES")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/sources.cmake)
        portable_target_sources(${TARGET} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "DEFINITIONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/definitions.cmake)
        portable_target_definitions(${TARGET} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "INCLUDE_DIRECTORIES")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/include_directories.cmake)
        portable_target_include_directories(${TARGET} ${_arg_UNPARSED_ARGUMENTS})
    else ()
        _portable_target_error(${TARGET} "Bad action: [${ACTION}]")
    endif()
endfunction(portable_target)
