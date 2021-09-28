################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.28 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

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

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    set(_real_target ${TARGET})

    if (_arg_INTERFACE)
        _portable_target_trace(${_real_target} "Interface libraries: [${_arg_INTERFACE}]")
        target_link_libraries(${_real_target} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${_real_target} "Public libraries: [${_arg_PUBLIC}]")
        target_link_libraries(${_real_target} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${_real_target} "Private libraries: [${_arg_PRIVATE}]")
        target_link_libraries(${_real_target} PRIVATE ${_arg_PRIVATE})
    endif()

    if (_arg_UNPARSED_ARGUMENTS)
        _portable_target_trace(${_real_target} "Default libraries: [${_arg_UNPARSED_ARGUMENTS}]")

        if (_target_type STREQUAL "EXECUTABLE"
                OR _target_type STREQUAL "STATIC_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY")
            target_link_libraries(${_real_target} PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            target_link_libraries(${_real_target} INTERFACE ${_arg_UNPARSED_ARGUMENTS})
        else()
            target_link_libraries(${_real_target} PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        endif()
    endif()
endfunction(portable_target_link_libraries)
