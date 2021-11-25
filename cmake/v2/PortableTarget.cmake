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
# INCLUDE_DIRS        Add include directories (see target_include_directories)
#
# SET                 Set named property
# GET                 Get named property
#
function (portable_target ACTION FIRST_ARG)
    set(boolparm)
    set(singleparm)
    set(multiparm)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    #_portable_target_trace(${TARGET} "Action: [${ACTION}]")

    if (ACTION STREQUAL "SET")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/properties.cmake)
        portable_target_set_property(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "GET")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/properties.cmake)

        set(_prop_variable ${ARGV2})

        if (ARGC GREATER 3)
            set(_default_value ${ARGV3})
            portable_target_get_property(${FIRST_ARG} ${_prop_variable} ${_default_value})
        else()
            portable_target_get_property(${FIRST_ARG} ${_prop_variable})
        endif()
        set(${_prop_variable} ${${_prop_variable}} PARENT_SCOPE)
    elseif (ACTION STREQUAL "ADD_EXECUTABLE" OR ACTION STREQUAL "APPLICATION")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_executable.cmake)
        portable_target_add_executable(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ADD_LIBRARY" OR ACTION STREQUAL "LIBRARY")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_library.cmake)
        portable_target_add_library(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "SOURCES")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/sources.cmake)
        portable_target_sources(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "DEFINITIONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/definitions.cmake)
        portable_target_definitions(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "COMPILE_OPTIONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/compile_options.cmake)
        portable_target_compile_options(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "INCLUDE_DIRS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/include_directories.cmake)
        portable_target_include_directories(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_libraries.cmake)
        portable_target_link_libraries(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK_QT5_COMPONENTS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_qt5_components.cmake)
        portable_target_link_qt5_components(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    else ()
        _portable_target_error("Bad action: [${ACTION}]")
    endif()
endfunction(portable_target)
