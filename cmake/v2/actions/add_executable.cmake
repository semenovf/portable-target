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
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

#
# Usage:
#
# portable_target_add_executable(<name>
#   [NO_UNICODE]
#   [NO_BIGOBJ]
#   source...)
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

    set(boolparm NO_UNICODE NO_BIGOBJ)
    set(singleparm)
    set(multiparm SOURCES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        add_library(${TARGET} SHARED)
        target_compile_definitions(${TARGET} PUBLIC "-DANDROID=1")

        # Shared libraries need PIC
        set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)

        # Avoid error: undefined reference to '__android_log_write'
        target_link_libraries(${TARGET} PRIVATE log)
    else()
        add_executable(${TARGET})
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_BIGOBJ)
        target_compile_options(${TARGET} PRIVATE "/bigobj")
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_UNICODE)
        target_compile_definitions(${TARGET} PRIVATE "/D_UNICODE /DUNICODE")
    endif()

    portable_target_get_property(RUNTIME_OUTPUT_DIRECTORY _output_dir)

    if (_output_dir)
        _portable_target_trace(${TARGET} "Runtime output directory: [${_output_dir}]")

        set_target_properties(${TARGET}
            PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${_output_dir}")
    endif()
endfunction(portable_target_add_executable)
