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
################################################################################
# portable_target_add_executable
################################################################################
function (portable_target_sources TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (_arg_INTERFACE)
        _portable_target_status(${TARGET} "Interface sources: [${_arg_INTERFACE}]")
        target_sources(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_status(${TARGET} "Public sources: [${_arg_PUBLIC}]")
        target_sources(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_status(${TARGET} "Private sources: [${_arg_PRIVATE}]")
        target_sources(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()

    if (_arg_UNPARSED_ARGUMENTS)
        _portable_target_status(${TARGET} "Default sources: [${_arg_UNPARSED_ARGUMENTS}]")

        # see https://cmake.org/cmake/help/v3.11/prop_tgt/TYPE.html
        # Valid types:
        #  - STATIC_LIBRARY
        #  - MODULE_LIBRARY
        #  - SHARED_LIBRARY
        #  - INTERFACE_LIBRARY
        #  - EXECUTABLE
        get_target_property(_target_type ${TARGET} TYPE)

        if (_target_type STREQUAL "EXECUTABLE"
                OR _target_type STREQUAL "STATIC_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY")
            target_sources(${TARGET} PRIVATE ${ARGN})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            target_sources(${TARGET} INTERFACE ${ARGN})
        else()
            target_sources(${TARGET} PRIVATE ${ARGN})
        endif()
    endif()
endfunction(portable_target_sources)


