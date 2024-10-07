################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.07 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/category.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/private/cxx_standard.cmake)

#
# Usage:
#
# portable_target_add_executable(<name>
#   [CATEGORIES category...]
#   [NO_UNICODE]
#   [NO_BIGOBJ]
#   [NO_NOMINMAX]
#   [OUTPUT dir]
#   [COMPONENT name])
#
# NO_UNICODE (MSVC specific option)
#       Disable UNICODE support.
#
# NO_BIGOBJ (MSVC specific option)
#       Disable increase the number of sections that an object file can contain.
#       By default `/bigobj` option is set for compiler.
#       See [https://docs.microsoft.com/en-us/cpp/build/reference
#           /bigobj-increase-number-of-sections-in-dot-obj-file
#           ?redirectedfrom=MSDN&view=msvc-160]
#
# NO_NOMINMAX
#       Disable avoid of min/max macros for MSVC.
#
# COMPONENT name
#       An installation component name with which the install rule is
#       associated.
#
# NOTE WIN32 option for `add_executable()` must be controled by
#      CMAKE_WIN32_EXECUTABLE variable.
# NOTE MACOSX_BUNDLE option for `add_executable()` must be controled by
#      CMAKE_MACOSX_BUNDLE variable.
#
# NOTE Since cmake v3.11 source files is optional for add_executable/add_library

################################################################################
# portable_target_add_executable
################################################################################
function (portable_target_add_executable TARGET)
    _portable_target_set_properties_defaults()

    set(boolparm NO_UNICODE NO_BIGOBJ NO_NOMINMAX)
    set(singleparm OUTPUT COMPONENT)
    set(multiparm CATEGORIES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        add_library(${TARGET} SHARED)
        target_compile_definitions(${TARGET} PUBLIC "-DANDROID=1")

        # Shared libraries need PIC
        set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)

        # Avoid error: undefined reference to '__android_log_write'
        target_link_libraries(${TARGET} PRIVATE log)

        #set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME ${TARGET}_${ANDROID_ABI})
        #set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME ${TARGET})
    else()
        add_executable(${TARGET})
    endif()

    _portable_target_cxx_standardize(${TARGET})

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        if (NOT _arg_NO_BIGOBJ)
            target_compile_options(${TARGET} PRIVATE "/bigobj")
        endif()

        if (NOT _arg_NO_UNICODE)
            target_compile_definitions(${TARGET} PRIVATE _UNICODE UNICODE)
        endif()

        if (NOT _arg_NO_NOMINMAX)
            target_compile_definitions(${TARGET} PRIVATE NOMINMAX)
        endif()
    endif()

    if (_arg_OUTPUT)
        if (CMAKE_SYSTEM_NAME STREQUAL "Android")
            _portable_target_trace(${TARGET} "Library output directory: [${_arg_OUTPUT}]")
            set_target_properties(${TARGET} PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
                LIBRARY_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}")
        else()
            _portable_target_trace(${TARGET} "Runtime output directory: [${_arg_OUTPUT}]")
            set_target_properties(${TARGET}
                PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
                RUNTIME_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}")
        endif()
    endif(_arg_OUTPUT)

    if (_arg_CATEGORIES)
        portable_target_set_category(${TARGET} ${_arg_CATEGORIES})
    endif(_arg_CATEGORIES)

    if (_arg_COMPONENT)
        set_target_properties(${TARGET}
            PROPERTIES
            COMPONENT "${_arg_COMPONENT}")
    endif(_arg_COMPONENT)
endfunction(portable_target_add_executable)
