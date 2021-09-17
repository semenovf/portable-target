################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.17 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

#
# Usage:
#
# portable_target_definitions(<target> sources...
#   [INTERFACE defs...]
#   [PUBLIC defs...]
#   [PRIVATE defs...])
#
function (portable_target_definitions TARGET)
    # TODO This variables may be configurable (see add_library.cmake)
    set(_objlib_siffix "_OBJLIB")
    set(_static_siffix "-static")

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

    # For library target defintions must be assigned to OBJECT target
    if (TARGET ${TARGET}${_objlib_siffix})
        set(_real_target ${TARGET}${_objlib_siffix})
        get_target_property(_target_type ${_real_target} TYPE)

        if (NOT _target_type STREQUAL "OBJECT_LIBRARY")
            _portable_target_error(${TARGET} "Expected OBJECT TYPE for '${TARGET}${_objlib_siffix}'")
        endif()
    endif()

    if (_arg_INTERFACE)
        _portable_target_status(${_real_target} "Interface sources: [${_arg_INTERFACE}]")
        target_compile_definitions(${_real_target} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_status(${_real_target} "Public sources: [${_arg_PUBLIC}]")
        target_compile_definitions(${_real_target} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_status(${_real_target} "Private sources: [${_arg_PRIVATE}]")
        target_compile_definitions(${_real_target} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(portable_target_definitions)

