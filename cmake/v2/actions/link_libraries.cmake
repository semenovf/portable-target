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

function (_target_link_libraries_helper TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)

    set(_real_target ${TARGET})

    # Check TARGET is library (SHARED and/or STATIC)
    if (TARGET ${TARGET}${_objlib_suffix})
        set(_real_target ${TARGET}${_objlib_suffix})
        get_target_property(_target_type ${_real_target} TYPE)

        if (NOT _target_type STREQUAL "OBJECT_LIBRARY")
            _portable_target_error(${TARGET} "Expected OBJECT TYPE for '${TARGET}${_objlib_suffix}'")
        endif()
    endif()

    if (_arg_INTERFACE)
        _portable_target_trace(${TARGET} "Interface libraries: [${_arg_INTERFACE}]")
        target_link_libraries(${_real_target} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${TARGET} "Public libraries: [${_arg_PUBLIC}]")
        target_link_libraries(${_real_target} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${TARGET} "Private libraries: [${_arg_PRIVATE}]")
        target_link_libraries(${_real_target} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(_target_link_libraries_helper)

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

    if (_arg_UNPARSED_ARGUMENTS)
        _portable_target_trace(${TARGET} "Default libraries: [${_arg_UNPARSED_ARGUMENTS}]")

        if (_target_type STREQUAL "EXECUTABLE"
                OR _target_type STREQUAL "STATIC_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY")
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            list(APPEND _arg_INTERFACE ${_arg_UNPARSED_ARGUMENTS})
        else()
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        endif()
    endif()

    if (_arg_INTERFACE)
        _target_link_libraries_helper(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _target_link_libraries_helper(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _target_link_libraries_helper(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(portable_target_link_libraries)
