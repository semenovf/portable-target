################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.16 Initial version.
#      2021.11.25 Refactored totally.
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
# portable_target_sources(<target> sources...)
#
function (portable_target_sources TARGET)
    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)

    set(boolparm)
    set(singleparm)
    set(multiparm)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    _portable_target_trace(${TARGET} "Sources: [${_arg_UNPARSED_ARGUMENTS}]")
    target_sources(${TARGET} PRIVATE ${_arg_UNPARSED_ARGUMENTS})

    get_target_property(_BIND_STATIC ${TARGET} BIND_STATIC)

    if (_BIND_STATIC)
        target_sources(${_BIND_STATIC} PRIVATE ${_arg_UNPARSED_ARGUMENTS})
    endif()

endfunction(portable_target_sources)
