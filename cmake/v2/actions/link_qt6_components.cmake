################################################################################
# Copyright (c) 2024 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2024.02.01 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/include_directories.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/link_libraries.cmake)

# Based on portable_target_link_qt6_components

# NOTE MUST BE ONE CALL PER PROJECT
#
# Usage:
#
# portable_target_link_qt6_components(target
#   [component...]           # INTERFACE, PUBLIC or PRIVATE depends on target type
#   [REQUIRED]
#   [QT6_DIR dir]            # The location of the Qt6Config.cmake file.
#                            # If not specified set to PORTABLE_TARGET_QT6_ROOT
#                            # or uses system platform
#   [AUTOMOC ON|OFF]         # (default is ON)
#   [AUTORCC ON|OFF]         # (default is ON)
#   [AUTOUIC ON|OFF]         # (default is ON)
#   [INTERFACE component...]
#   [PUBLIC component...]
#   [PRIVATE component...])
#
function (portable_target_link_qt6_components TARGET)
    set(boolparm REQUIRED)
    set(singleparm QT6_DIR AUTOMOC AUTORCC AUTOUIC)
    set(multiparm INTERFACE PUBLIC PRIVATE)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    # Automatically link Qt executables to qtmain target on Windows
    if (POLICY CMP0020)
        cmake_policy(SET CMP0020 NEW)
    endif()

    set(QT6_DEFAULT_COMPONENTS ${_arg_UNPARSED_ARGUMENTS})
    set(QT6_INTERFACE_COMPONENTS ${_arg_INTERFACE})
    set(QT6_PUBLIC_COMPONENTS ${_arg_PUBLIC})
    set(QT6_PRIVATE_COMPONENTS ${_arg_PRIVATE})

    _optional_var_env(_arg_QT6_DIR QT6_DIR "Qt6 directory")

    set(QT6_COMPONENTS
        ${QT6_DEFAULT_COMPONENTS}
        ${QT6_INTERFACE_COMPONENTS}
        ${QT6_PUBLIC_COMPONENTS}
        ${QT6_PRIVATE_COMPONENTS})

    if (NOT QT6_COMPONENTS)
        _portable_target_error(${TARGET} "No Qt6 components specified")
    endif()

    if (_arg_QT6_DIR)
        set(Qt6_DIR ${_arg_QT6_DIR} CACHE STRING "" FORCE)
        portable_target_set_property(Qt6_DIR ${Qt6_DIR})

        if (NOT EXISTS ${Qt6_DIR})
            _portable_target_error(${TARGET}
                "Bad Qt6_DIR location: '${Qt6_DIR}'")
        endif()

        _portable_target_status(${TARGET} "Qt6_DIR location: ${_arg_QT6_DIR}")

        set(QT_QMAKE_EXECUTABLE1 "${_arg_QT6_DIR}/../../../bin/qmake${CMAKE_EXECUTABLE_SUFFIX}")
        set(QT_QMAKE_EXECUTABLE2 "${_arg_QT6_DIR}/../../bin/qmake${CMAKE_EXECUTABLE_SUFFIX}")

        if (EXISTS ${QT_QMAKE_EXECUTABLE1})
            set(QT_QMAKE_EXECUTABLE ${QT_QMAKE_EXECUTABLE1})
        elseif (EXISTS ${QT_QMAKE_EXECUTABLE2})
            set(QT_QMAKE_EXECUTABLE ${QT_QMAKE_EXECUTABLE2})
        else()
            _portable_target_error(${TARGET}
                "Bad qmake location: neither '${QT_QMAKE_EXECUTABLE1}' nor '${QT_QMAKE_EXECUTABLE2}', need modification of this function")
        endif()

        _portable_target_status(${TARGET} "Qt6 qmake location: ${QT_QMAKE_EXECUTABLE}")

        # Set location of Qt6 modules if need
        foreach(_item IN LISTS QT6_COMPONENTS)
            if (_arg_QT6_DIR)
                set(Qt6${_item}_DIR "${_arg_QT6_DIR}/../Qt6${_item}")
                _portable_target_status(${TARGET} "Qt6::${_item} location: ${Qt6${_item}_DIR}")
            endif()
        endforeach()

    endif()

    _portable_target_trace(${TARGET} "Qt6 components: [${QT6_COMPONENTS}]")

    if (_arg_REQUIRED)
        find_package(Qt6 COMPONENTS ${QT6_COMPONENTS} REQUIRED)
    else()
        find_package(Qt6 COMPONENTS ${QT6_COMPONENTS})
    endif()

    _portable_target_status(${TARGET} "Qt6 version found: ${Qt6Core_VERSION} (compare with required)")

    # See https://gitlab.kitware.com/cmake/cmake/issues/19167
    # Since 3.14 (--wladt-- remark: since 13.4) CMake requires valid
    # QT_VERSION_MAJOR/MINOR (Qt4),
    # Qt5Core_VERSION_MAJOR/MINOR or
    # Qt6Core_VERSION_MAJOR/MINOR
    set_property(DIRECTORY PROPERTY Qt6Core_VERSION_MAJOR ${Qt6Core_VERSION_MAJOR})
    set_property(DIRECTORY PROPERTY Qt6Core_VERSION_MINOR ${Qt6Core_VERSION_MINOR})
    portable_target_set_property(Qt6_VERSION ${Qt6Core_VERSION})

    foreach(_item IN LISTS QT6_DEFAULT_COMPONENTS)
        list(APPEND _default_libraries "Qt6::${_item}")
        list(APPEND _default_include_directories "${Qt6${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT6_INTERFACE_COMPONENTS)
        list(APPEND _interface_libraries "Qt6::${_item}")
        list(APPEND _interface_include_directories "${Qt6${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT6_PUBLIC_COMPONENTS)
        list(APPEND _public_libraries "Qt6::${_item}")
        list(APPEND _public_include_directories "${Qt6${_item}_INCLUDE_DIRS}")
    endforeach()

    foreach(_item IN LISTS QT6_PRIVATE_COMPONENTS)
        list(APPEND _private_libraries "Qt6::${_item}")
        list(APPEND _private_include_directories "${Qt6${_item}_INCLUDE_DIRS}")
    endforeach()

    list(REMOVE_DUPLICATES _default_libraries)
    list(REMOVE_DUPLICATES _default_include_directories)
    list(REMOVE_DUPLICATES _interface_libraries)
    list(REMOVE_DUPLICATES _interface_include_directories)
    list(REMOVE_DUPLICATES _public_libraries)
    list(REMOVE_DUPLICATES _public_include_directories)
    list(REMOVE_DUPLICATES _private_libraries)
    list(REMOVE_DUPLICATES _private_include_directories)

    portable_target_get_property(Qt6_COMPONENTS _qt6_components)
    list(APPEND _qt6_components
        ${_default_libraries}
        ${_interface_libraries}
        ${_public_libraries}
        ${_private_libraries})
    list(REMOVE_DUPLICATES _qt6_components)
    portable_target_set_property(Qt6_COMPONENTS "${_qt6_components}")

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

    #############################################################################
    ## Configure AUTOMOC, AUTORCC, AUTOUIC
    #############################################################################
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
endfunction(portable_target_link_qt6_components)
