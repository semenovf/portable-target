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
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

# Suppress warning:
# Policy CMP0076 is not set: target_sources() command converts relative paths
# to absolute.  Run "cmake --help-policy CMP0076" for policy details.  Use
# the cmake_policy command to set the policy and suppress this warning.
cmake_policy(SET CMP0076 NEW) # Since version 3.13.

#
# Usage:
#
# portable_target_sources(<target> sources...
#   [INTERFACE sources...]
#   [PUBLIC sources...]
#   [PRIVATE sources...])
#
function (portable_target_sources TARGET)
    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)

    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    set(_real_target ${TARGET})

    # see https://cmake.org/cmake/help/v3.11/prop_tgt/TYPE.html
    # Valid types:
    #  - STATIC_LIBRARY
    #  - MODULE_LIBRARY
    #  - SHARED_LIBRARY
    #  - INTERFACE_LIBRARY
    #  - EXECUTABLE
    #  - OBJECT_LIBRARY

    # For library target sources must be assigned to OBJECT target
    if (TARGET ${TARGET}${_objlib_suffix})
        set(_real_target ${TARGET}${_objlib_suffix})
        get_target_property(_target_type ${_real_target} TYPE)

        if (NOT _target_type STREQUAL "OBJECT_LIBRARY")
            _portable_target_error(${TARGET} "Expected OBJECT TYPE for '${TARGET}${_objlib_suffix}'")
        endif()
    endif()

    if (_arg_INTERFACE)
        _portable_target_trace(${_real_target} "Interface sources: [${_arg_INTERFACE}]")
        target_sources(${_real_target} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${_real_target} "Public sources: [${_arg_PUBLIC}]")
        target_sources(${_real_target} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${_real_target} "Private sources: [${_arg_PRIVATE}]")
        target_sources(${_real_target} PRIVATE ${_arg_PRIVATE})
    endif()

    if (_arg_UNPARSED_ARGUMENTS)
        _portable_target_trace(${_real_target} "Default sources: [${_arg_UNPARSED_ARGUMENTS}]")

        if (_target_type STREQUAL "EXECUTABLE"
                OR _target_type STREQUAL "STATIC_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY")
            target_sources(${_real_target} PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            target_sources(${_real_target} INTERFACE ${_arg_UNPARSED_ARGUMENTS})
        else()
            target_sources(${_real_target} PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        endif()
    endif()
endfunction(portable_target_sources)