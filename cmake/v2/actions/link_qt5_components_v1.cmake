################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.28 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/include_directories.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/link_libraries.cmake)

#
# NOTE MUST BE ONE CALL PER PROJECT
#
# Usage:
#
# portable_target_link_qt5_components(target
#   [component...]           # INTERFACE, PUBLIC or PRIVATE depends on target type
#   [REQUIRED]
#   [QT5_ROOT dir]           # Must point to Qt5 official distribution
#                            # directory. If not specified set to
#                            # PORTABLE_TARGET_QT5_ROOT or uses system platform
#   [QT5_PLATFORM platform]  # If not specified set to
#                            # PORTABLE_TARGET_QT5_PLATFORM or uses
#                            # system platform
#   [AUTOMOC ON|OFF]         # (default is ON)
#   [AUTORCC ON|OFF]         # (default is ON)
#   [AUTOUIC ON|OFF]         # (default is ON)
#   [INTERFACE component...]
#   [PUBLIC component...]
#   [PRIVATE component...])
#
#   Available platforms for Qt5.13.2:
#       - gcc_64
#       - android_x86
#       - android_armv7
#       - android_arm64_v8a
#
function (portable_target_link_qt5_components TARGET)
    set(boolparm REQUIRED)
    set(singleparm QT5_ROOT QT5_PLATFORM AUTOMOC AUTORCC AUTOUIC)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    # Automatically link Qt executables to qtmain target on Windows
    if (POLICY CMP0020)
        cmake_policy(SET CMP0020 NEW)
    endif()

    set(QT5_DEFAULT_COMPONENTS ${_arg_UNPARSED_ARGUMENTS})
    set(QT5_INTERFACE_COMPONENTS ${_arg_INTERFACE})
    set(QT5_PUBLIC_COMPONENTS ${_arg_PUBLIC})
    set(QT5_PRIVATE_COMPONENTS ${_arg_PRIVATE})

    _optional_var_env(_arg_QT5_PLATFORM
        QT5_PLATFORM
        "Qt5 target platform")

    _optional_var_env(_arg_QT5_ROOT
        QT5_ROOT
        "Qt5 root directory")

    if (_arg_QT5_ROOT)
        if (NOT _arg_QT5_PLATFORM)
            _portable_target_error(${TARGET} "Qt5 platform must be specified")
        endif()

        if (NOT EXISTS ${_arg_QT5_ROOT})
            _portable_target_error(${TARGET}
                "Bad Qt5 location: '${_arg_QT5_ROOT}', check QT5_ROOT parameter")
        endif()

        set(Qt5_DIR "${_arg_QT5_ROOT}/${_arg_QT5_PLATFORM}/lib/cmake/Qt5")
        portable_target_set_property(Qt5_DIR ${Qt5_DIR})

        if (NOT EXISTS ${Qt5_DIR})
            _portable_target_error(${TARGET}
                "Bad Qt5_DIR location: '${Qt5_DIR}', check QT5_PLATFORM parameter or may be need modification of this function")
        endif()

        set(Qt5Core_DIR "${_arg_QT5_ROOT}/${_arg_QT5_PLATFORM}/lib/cmake/Qt5Core")

        if (NOT EXISTS ${Qt5Core_DIR})
            _portable_target_error(${TARGET}
                "Bad Qt5Core location: '${Qt5Core_DIR}', need modification of this function")
        endif()

        _portable_target_status(${TARGET} "Qt5 location: ${_arg_QT5_ROOT}")

        set(QT_QMAKE_EXECUTABLE "${_arg_QT5_ROOT}/${_arg_QT5_PLATFORM}/bin/qmake${CMAKE_EXECUTABLE_SUFFIX}")

        if (NOT EXISTS ${QT_QMAKE_EXECUTABLE})
            _portable_target_error(${TARGET}
                "Bad qmake location: '${QT_QMAKE_EXECUTABLE}', need modification of this function")
        endif()

        _portable_target_status(${TARGET} "Qt5 qmake location: ${QT_QMAKE_EXECUTABLE}")
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        #list(APPEND QT5_COMPONENTS MultimediaQuick QuickParticles AndroidExtras)
        list(APPEND QT5_DEFAULT_COMPONENTS AndroidExtras)
    endif()

    set(QT5_COMPONENTS
        ${QT5_DEFAULT_COMPONENTS}
        ${QT5_INTERFACE_COMPONENTS}
        ${QT5_PUBLIC_COMPONENTS}
        ${QT5_PRIVATE_COMPONENTS})

    if (NOT QT5_COMPONENTS)
        _portable_target_error(${TARGET} "No Qt5 components specified")
    endif()

    _portable_target_trace(${TARGET} "Qt5 components: [${QT5_COMPONENTS}]")

    # Set location of Qt5 modules if need
    foreach(_item IN LISTS QT5_COMPONENTS)
        if (_arg_QT5_ROOT)
            set(Qt5${_item}_DIR "${_arg_QT5_ROOT}/${_arg_QT5_PLATFORM}/lib/cmake/Qt5${_item}")
            _portable_target_status(${TARGET} "Qt5::${_item} location: ${Qt5${_item}_DIR}")
        endif()
    endforeach()

    if (_arg_REQUIRED)
        find_package(Qt5 COMPONENTS ${QT5_COMPONENTS} REQUIRED)
    else()
        find_package(Qt5 COMPONENTS ${QT5_COMPONENTS})
    endif()

    _portable_target_status(${TARGET} "Qt5 version found: ${Qt5Core_VERSION} (compare with required)")

    # See https://gitlab.kitware.com/cmake/cmake/issues/19167
    # Since 3.14 (--wladt-- remark: since 13.4) CMake requires valid
    # QT_VERSION_MAJOR/MINOR (Qt4),
    # Qt5Core_VERSION_MAJOR/MINOR or
    # Qt6Core_VERSION_MAJOR/MINOR
    set_property(DIRECTORY PROPERTY Qt5Core_VERSION_MAJOR ${Qt5Core_VERSION_MAJOR})
    set_property(DIRECTORY PROPERTY Qt5Core_VERSION_MINOR ${Qt5Core_VERSION_MINOR})

    foreach(_item IN LISTS QT5_DEFAULT_COMPONENTS)
        list(APPEND _default_libraries "Qt5::${_item}")
        list(APPEND _default_include_directories "${Qt5${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT5_INTERFACE_COMPONENTS)
        list(APPEND _interface_libraries "Qt5::${_item}")
        list(APPEND _interface_include_directories "${Qt5${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT5_PUBLIC_COMPONENTS)
        list(APPEND _public_libraries "Qt5::${_item}")
        list(APPEND _public_include_directories "${Qt5${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT5_PRIVATE_COMPONENTS)
        list(APPEND _private_libraries "Qt5::${_item}")
        list(APPEND _private_include_directories "${Qt5${_item}_INCLUDE_DIRS}")
    endforeach()

    portable_target_include_directories(${TARGET}
        ${_default_include_directories}
        INTERFACE ${_interface_include_directories}
        PUBLIC ${_public_include_directories}
        PRIVATE ${_private_include_directories})

    portable_target_link_libraries(${TARGET}
        ${_default_libraries}
        INTERFACE ${_interface_libraries}
        PUBLIC ${_public_libraries}
        PRIVATE ${_private_libraries})

    ############################################################################
    # Configure AUTOMOC, AUTORCC, AUTOUIC
    ############################################################################
    if (NOT DEFINED _arg_AUTOMOC OR _arg_AUTOMOC)
        set(_arg_AUTOMOC ON)
    else()
        set(_arg_AUTOMOC OFF)
    endif()

    if (NOT DEFINED _arg_AUTORCC OR _arg_AUTORCC)
        set(_arg_AUTORCC ON)
    else()
        set(_arg_AUTORCC OFF)
    endif()

    if (NOT DEFINED _arg_AUTOUIC OR _arg_AUTOUIC)
        set(_arg_AUTOUIC ON)
    else()
        set(_arg_AUTOUIC OFF)
    endif()

    _portable_target_trace(${TARGET} "AUTOMOC: [${_arg_AUTOMOC}]")
    _portable_target_trace(${TARGET} "AUTORCC: [${_arg_AUTORCC}]")
    _portable_target_trace(${TARGET} "AUTOUIC: [${_arg_AUTOUIC}]")

    set_target_properties(${TARGET}
        PROPERTIES
            AUTOMOC ${_arg_AUTOMOC}
            AUTORCC ${_arg_AUTORCC}
            AUTOUIC ${_arg_AUTOUIC})
endfunction(portable_target_link_qt5_components)
