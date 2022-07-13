################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.17 Initial version.
#      2021.11.25 Refactored totally.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

function (_definitions_helper TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

     if (_arg_INTERFACE)
        _portable_target_trace(${TARGET} "INTERFACE compile options: [${_arg_INTERFACE}]")
        target_compile_definitions(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${TARGET} "PUBLIC compile options: [${_arg_PUBLIC}]")
        target_compile_definitions(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${TARGET} "PRIVATE compile options: [${_arg_PRIVATE}]")
        target_compile_definitions(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(_definitions_helper)

#
# Usage:
#
# portable_target_definitions(<target> sources...
#   [INTERFACE defs...]
#   [PUBLIC defs...]
#   [PRIVATE defs...])
#
function (portable_target_definitions TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (_arg_UNPARSED_ARGUMENTS)
        # see https://cmake.org/cmake/help/v3.11/prop_tgt/TYPE.html
        # Valid types:
        #  - STATIC_LIBRARY
        #  - MODULE_LIBRARY
        #  - SHARED_LIBRARY
        #  - INTERFACE_LIBRARY
        #  - EXECUTABLE
        #  - OBJECT_LIBRARY

        get_target_property(_target_type ${TARGET} TYPE)

        if (_target_type STREQUAL "EXECUTABLE")
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "OBJECT_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY"
                OR _target_type STREQUAL "STATIC_LIBRARY")
            list(APPEND _arg_PUBLIC ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            list(APPEND _arg_INTERFACE ${_arg_UNPARSED_ARGUMENTS})
        else()
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        endif()
    endif()

    if (_arg_INTERFACE)
        _definitions_helper(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _definitions_helper(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _definitions_helper(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(portable_target_definitions)
