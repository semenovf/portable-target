################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.28 Initial version.
#      2021.11.25 Refactored totally.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

function (_link_libraries_helper TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (_arg_INTERFACE)
        _portable_target_trace(${TARGET} "INTERFACE link libs: [${_arg_INTERFACE}]")
        target_link_libraries(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${TARGET} "PUBLIC link libs: [${_arg_PUBLIC}]")
         target_link_libraries(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${TARGET} "PRIVATE link libs: [${_arg_PRIVATE}]")
        target_link_libraries(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(_link_libraries_helper)

#
# Usage:
#
# portable_target_link_libraries(<target>
#   [lib...]
#   [INTERFACE lib...]
#   [PUBLIC lib...]
#   [PRIVATE lib...])
#
function (portable_target_link_libraries TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (_arg_UNPARSED_ARGUMENTS)
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
        _link_libraries_helper(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _link_libraries_helper(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _link_libraries_helper(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(portable_target_link_libraries)
