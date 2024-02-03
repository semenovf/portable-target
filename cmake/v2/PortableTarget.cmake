################################################################################
# Copyright (c) 2019-2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2019.12.10 Initial version.
#      2020.09.03 Splitted into Functions.cmake, AndroidToolchain.cmake and PortableTarget.cmake.
#      2021.03.06 Added support for extra Android SSL libraries.
#      2021.09.07 Started version 2.
#      2023.06.08 Added BUILD_APK2 action.
###############################################################################
cmake_minimum_required(VERSION 3.11)

set(PORTABLE_TARGET__ENABLED TRUE)
set(_PORTABLE_TARGET_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})
include(${_PORTABLE_TARGET_ROOT_DIR}/Functions.cmake)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

_portable_target_status(${TARGET} "Cross-compiling     : ${CMAKE_CROSSCOMPILING}")
_portable_target_status(${TARGET} "CMAKE_CXX_COMPILER  : ${CMAKE_CXX_COMPILER}")
_portable_target_status(${TARGET} "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")
_portable_target_status(${TARGET} "CMAKE_BUILD_TYPE    : ${CMAKE_BUILD_TYPE}")

#
# Usage:
#
# portable_target(<action> <target> <action-options>)
#
# Available actions (case sensitive):
#
# ADD_EXECUTABLE
# APPLICATION         Add executable or shared library for Android.
#
# ADD_SHARED          Add shared library.
# ADD_STATIC          Add static library.
# ADD_INTERFACE       Add interface library.
#
# DEFINITIONS         Add compile defintions (see target_compile_definitions).
# INCLUDE_DIRS        Add include directories (see target_include_directories).
#
# LINK                Link with specified libraries.
# LINK_QT5_COMPONENTS Link with Qt5 components.
# LINK_QT6_COMPONENTS Link with Qt6 components.
# LINK_PROTOBUF       Genarate sources and link with PROTOBUF library.
# LINK_GRPC           Genarate sources and link with gRPC library.

# SET                 Set named property.
# GET                 Get named property.
#
# SET_CATEGORY        Set categories for target.
# GET_CATEGORIES      Get list of categories.
# CATEGORY_ITEMS      Get items for specified category.
#
# INCLUDE_PROJECT     Call `include()` method wrapped by function.
#                     This useful when including `cmake` scripts that contains
#                    `project` directive to avoid `PROJECT_NAME` variable
#                     overriding.
#
# ICONS               Build icons library
# TRANSLATE           Add internationalization support
# TEST                Add tests
#
# BUILD_APK           Build Android package (used androiddeployqt, deprecated, unsupported since )
# BUILD_APK2          Build Android package (used Android native build tools directly)
#
# BUILD_JAR           Build Java JAR package
#
# WINDEPLOY           Build package for Windows (using NSIS)
#
function (portable_target ACTION FIRST_ARG)
    set(boolparm)
    set(singleparm)
    set(multiparm)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    #_portable_target_trace(${TARGET} "Action: [${ACTION}]")

    if (ACTION STREQUAL "SET")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/properties.cmake)
        portable_target_set_property(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "GET")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/properties.cmake)

        set(_prop_variable ${ARGV2})

        if (ARGC GREATER 3)
            set(_default_value ${ARGV3})
            portable_target_get_property(${FIRST_ARG} ${_prop_variable} ${_default_value})
        else()
            portable_target_get_property(${FIRST_ARG} ${_prop_variable})
        endif()
        set(${_prop_variable} ${${_prop_variable}} PARENT_SCOPE)
    elseif (ACTION STREQUAL "ADD_EXECUTABLE" OR ACTION STREQUAL "APPLICATION")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_executable.cmake)
        portable_target_add_executable(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ADD_SHARED")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_library.cmake)
        portable_target_add_library(${FIRST_ARG} SHARED ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ADD_STATIC")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_library.cmake)
        portable_target_add_library(${FIRST_ARG} STATIC ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ADD_INTERFACE")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_library.cmake)
        portable_target_add_library(${FIRST_ARG} INTERFACE ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ADD_TEST")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/add_test.cmake)
        portable_target_add_test(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "SOURCES")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/sources.cmake)
        portable_target_sources(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "DEFINITIONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/definitions.cmake)
        portable_target_definitions(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "COMPILE_OPTIONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/compile_options.cmake)
        portable_target_compile_options(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "INCLUDE_DIRS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/include_directories.cmake)
        portable_target_include_directories(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_libraries.cmake)
        portable_target_link_libraries(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK_QT5_COMPONENTS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_qt5_components.cmake)
        portable_target_link_qt5_components(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK_QT6_COMPONENTS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_qt6_components.cmake)
        portable_target_link_qt6_components(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK_PROTOBUF")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_protobuf.cmake)
        portable_target_link_protobuf(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "LINK_GRPC")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/link_protobuf.cmake)
        portable_target_link_protobuf(${FIRST_ARG} ENABLE_GRPC ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "INCLUDE_PROJECT")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/include_project.cmake)
        portable_target_include_project(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "ICONS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/icons.cmake)
        portable_target_icons(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "TRANSLATE")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/translate.cmake)
        portable_target_translate(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "BUILD_APK")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/build_apk.cmake)
        portable_target_build_apk(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "BUILD_APK2")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/build_apk2.cmake)
        portable_target_build_apk2(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "BUILD_JAR")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/build_jar.cmake)
        portable_target_build_jar(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "WINDEPLOY")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/windeploy.cmake)
        portable_target_windeploy(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "SET_CATEGORY")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/category.cmake)
        portable_target_set_category(${FIRST_ARG} ${_arg_UNPARSED_ARGUMENTS})
    elseif (ACTION STREQUAL "GET_CATEGORIES")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/category.cmake)
        set(_var ${ARGV1})
        portable_target_get_categories(${_var})
        set(${_var} ${${_var}} PARENT_SCOPE)
    elseif (ACTION STREQUAL "CATEGORY_ITEMS")
        include(${_PORTABLE_TARGET_ROOT_DIR}/actions/category.cmake)
        set(_var ${ARGV2})
        portable_target_category_items(${FIRST_ARG} ${_var})
        set(${_var} ${${_var}} PARENT_SCOPE)
    else ()
        _portable_target_error("Bad action: [${ACTION}]")
    endif()
endfunction(portable_target)
