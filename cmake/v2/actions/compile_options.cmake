################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.30 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/link_libraries.cmake)

function (_target_compile_options_helper TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

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
        _portable_target_trace(${TARGET} "Interface compile options: [${_arg_INTERFACE}]")
        target_compile_options(${_real_target} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _portable_target_trace(${TARGET} "Public compile options: [${_arg_PUBLIC}]")
        target_compile_options(${_real_target} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _portable_target_trace(${TARGET} "Private compile options: [${_arg_PRIVATE}]")
        target_compile_options(${_real_target} PRIVATE ${_arg_PRIVATE})
    endif()
endfunction(_target_compile_options_helper)

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
        _portable_target_trace(${TARGET} "Default compile options: [${_arg_UNPARSED_ARGUMENTS}]")

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
        _target_compile_options_helper(${TARGET} INTERFACE ${_arg_INTERFACE})
    endif()

    if (_arg_PUBLIC)
        _target_compile_options_helper(${TARGET} PUBLIC ${_arg_PUBLIC})
    endif()

    if (_arg_PRIVATE)
        _target_compile_options_helper(${TARGET} PRIVATE ${_arg_PRIVATE})
    endif()

endfunction(portable_target_compile_options)

