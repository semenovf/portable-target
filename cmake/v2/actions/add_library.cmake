################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.09.16 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

#
# Usage:
#
# portable_target_add_library(<name>)
#
# NOTE Since cmake v3.11 source files is optional for add_executable/add_library

################################################################################
# portable_target_add_executable
################################################################################
function (portable_target_add_library TARGET)
    set(boolparm)
    set(singleparm)
    set(multiparm SOURCES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

#     if (NOT _arg_SOURCES)
#         _portable_target_error(${TARGET} "No SOURCES specified")
#     endif()
#
#     #if (ANDROID)
#     if (CMAKE_SYSTEM_NAME STREQUAL "Android")
#         add_library(${TARGET} SHARED ${_arg_SOURCES})
#         target_compile_definitions(${TARGET} PUBLIC "-DANDROID=1")
#
#         # Shared libraries need PIC
#         set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
#     else()
#         add_executable(${TARGET} ${_arg_SOURCES})
#     endif()
endfunction(portable_target_add_library)

