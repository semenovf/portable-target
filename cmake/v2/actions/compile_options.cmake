################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.30 Initial version.
#      2021.11.25 Refactored totally.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/link_libraries.cmake)

function (_compile_options_helper TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)
    portable_target_get_property(STATIC_SUFFIX _static_suffix)

    # see https://cmake.org/cmake/help/v3.11/prop_tgt/TYPE.html
    # Valid types:
    #  - STATIC_LIBRARY
    #  - MODULE_LIBRARY
    #  - SHARED_LIBRARY
    #  - INTERFACE_LIBRARY
    #  - EXECUTABLE
    #  - OBJECT_LIBRARY

    # For library target definitions must be assigned to OBJECT target
    if (TARGET ${TARGET}${_objlib_suffix})
        set(_objlib_target ${TARGET}${_objlib_suffix})
        get_target_property(_target_type ${_objlib_target} TYPE)

        if (NOT _target_type STREQUAL "OBJECT_LIBRARY")
            _portable_target_error(${TARGET} "Expected OBJECT TYPE for '${_objlib_target}'")
        endif()

        set(_static_target ${TARGET}${_static_suffix})
    endif()

    if (_arg_INTERFACE)
        _portable_target_trace(${TARGET} "INTERFACE options: [${_arg_INTERFACE}]")
        target_compile_options(${TARGET} INTERFACE ${_arg_INTERFACE})

        if (TARGET _objlib_target)
            target_compile_options(${_objlib_target} PRIVATE ${_arg_INTERFACE})
        endif()

        if (TARGET _static_target)
            target_compile_options(${_static_target} INTERFACE ${_arg_INTERFACE})
        endif()

    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${TARGET} "PUBLIC options: [${_arg_PUBLIC}]")
        target_compile_options(${TARGET} PUBLIC ${_arg_PUBLIC})

        if (TARGET _objlib_target)
            target_compile_options(${_objlib_target} PRIVATE ${_arg_PUBLIC})
        endif()

        if (TARGET _static_target)
            target_compile_options(${_static_target} PUBLIC ${_arg_PUBLIC})
        endif()
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${TARGET} "PRIVATE options: [${_arg_PRIVATE}]")
        target_compile_options(${TARGET} PRIVATE ${_arg_PRIVATE})

        if (TARGET _objlib_target)
            target_compile_options(${_objlib_target} PRIVATE ${_arg_PRIVATE})
        endif()

        if (TARGET _static_target)
            target_compile_options(${_static_target} PRIVATE ${_arg_PRIVATE})
        endif()
    endif()
endfunction(_compile_options_helper)

#
# Usage:
#
# portable_target_compile_options(target
#   [opts...]
#   [AGGRESSIVE_CHECK ON|OFF]
#   [INTERFACE opts...]
#   [PUBLIC opts...]
#   [PRIVATE opts...]))
#
function (portable_target_compile_options TARGET)
    set(boolparm)
    set(singleparm AGGRESSIVE_CHECK)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (DEFINED _arg_AGGRESSIVE_CHECK AND _arg_AGGRESSIVE_CHECK)
        set(_arg_AGGRESSIVE_CHECK ON)
    else()
        set(_arg_AGGRESSIVE_CHECK OFF)
    endif()

    _portable_target_trace(${TARGET} "Aggressive compiler check: [${_arg_AGGRESSIVE_CHECK}]")

    if (_arg_AGGRESSIVE_CHECK)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            #
            # See [https://codeforces.com/blog/entry/15547](https://codeforces.com/blog/entry/15547)
            #
            _portable_target_status(${TARGET} "Aggressive compiler check is ON")

            list(APPEND _aggressive_check_flags
                "-D_GLIBCXX_DEBUG=1"
                "-D_GLIBCXX_DEBUG_PEDANTIC=1"
                "-D_FORTIFY_SOURCE=2"
                "-pedantic"
                "-O2"
                "-Wall"
                "-Wextra"
                "-Wshadow"
                "-Wformat=2"
                "-Wfloat-equal"
                # "-Wconversion" # <-- Annoying message, may be need separate option for this
                "-Wlogical-op"
                "-Wshift-overflow=2"
                "-Wduplicated-cond"
                "-Wcast-qual"
                "-Wcast-align"
                "-fsanitize=address"   # <-- The option cannot be combined with -fsanitize=thread and/or -fcheck-pointer-bounds.
                "-fsanitize=undefined"
                "-fsanitize=leak"      # <-- The option cannot be combined with -fsanitize=thread
                "-fno-sanitize-recover"
                "-fstack-protector"

                # gcc: error: -fsanitize=address and -fsanitize=kernel-address are incompatible with -fsanitize=thread
                # "-fsanitize=thread"
            )

            list(APPEND _link_flags
                "-fsanitize=address"
                "-fsanitize=undefined"
                "-fsanitize=leak")

            list(APPEND _link_libraries
                "-lasan"  # <-- need for -fsanitize=address
                "-lubsan" # <-- need for -fsanitize=undefined
                #"-ltsan"  # <-- need for -fsanitize=thread
            )

            _portable_target_trace(${TARGET} "Aggressive compiler check flags: [${_aggressive_check_flags}]")

            list(APPEND _arg_PRIVATE ${_aggressive_check_flags})

            portable_target_link_libraries(${TARGET} PRIVATE ${_link_flags} ${_link_libraries})
        else()
            _portable_target_trace(${TARGET} "Aggressive compiler check: supported for GCC only at the moment")
        endif()
    endif(_arg_AGGRESSIVE_CHECK)

    if (_arg_UNPARSED_ARGUMENTS)
        get_target_property(_target_type ${TARGET} TYPE)

        if (_target_type STREQUAL "EXECUTABLE")
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "STATIC_LIBRARY"
                OR _target_type STREQUAL "SHARED_LIBRARY")
            list(APPEND _arg_PUBLIC ${_arg_UNPARSED_ARGUMENTS})
        elseif(_target_type STREQUAL "INTERFACE_LIBRARY")
            list(APPEND _arg_INTERFACE ${_arg_UNPARSED_ARGUMENTS})
        else()
            list(APPEND _arg_PRIVATE ${_arg_UNPARSED_ARGUMENTS})
        endif()
    endif()

    if (_arg_INTERFACE)
        _compile_options_helper(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _compile_options_helper(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _compile_options_helper(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(portable_target_compile_options)

