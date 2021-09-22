################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
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
# portable_target_add_executable(<name>)
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

    set(boolparm)
    set(singleparm)
    set(multiparm SOURCES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        add_library(${TARGET} SHARED)
        target_compile_definitions(${TARGET} PUBLIC "-DANDROID=1")

        # Shared libraries need PIC
        set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
    else()
        add_executable(${TARGET})
    endif()
endfunction(portable_target_add_executable)
