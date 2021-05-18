################################################################################
# Copyright (c) 2020 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2020.12.01 Initial version
################################################################################
cmake_minimum_required(VERSION 3.5)
include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/Functions.cmake)

find_program(_lupdate_program "lupdate")
find_program(_lrelease_program "lrelease")
find_program(_lconvert_program "lconvert")

function (portable_translation BASENAME)
    set(boolparm)

    set(singleparm
        PARENT_TARGET
        SOURCE_LANG
        TARGET_LANG
        RELEASE_DIR)

    set(multiparm
        SOURCES
        DEPENDS)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SOURCE_LANG)
        _portable_target_error(${BASENAME} "No source language specified")
    endif()

    if (NOT _arg_TARGET_LANG)
        _portable_target_error(${BASENAME} "No target language specified")
    endif()

    if (NOT _arg_SOURCES)
        _portable_target_error(${BASENAME} "No sources specified")
    endif()

    if (NOT _arg_RELEASE_DIR)
        set(_arg_RELEASE_DIR "${CMAKE_BINARY_DIR}/Translation")
    endif()

    set(_lupdate_target ${BASENAME}_${_arg_TARGET_LANG}_translation_update)
    set(_lrelease_target ${BASENAME}_${_arg_TARGET_LANG}_translation_release)

    _optional_var_env(Qt5_ROOT Qt5_ROOT "Qt5 Root directory")
    _optional_var_env(Qt5_PLATFORM Qt5_PLATFORM "Qt5 Platform directory")

    if (Qt5_ROOT AND Qt5_PLATFORM)
        set(Qt5_BIN_DIR "${Qt5_ROOT}/${Qt5_PLATFORM}/bin")
    endif()

    if (NOT _lupdate_program)
        if (Qt5_BIN_DIR AND EXISTS "${Qt5_BIN_DIR}/lupdate${CMAKE_EXECUTABLE_SUFFIX}")
            set(_lupdate_program "${Qt5_BIN_DIR}/lupdate${CMAKE_EXECUTABLE_SUFFIX}")
        endif()
    endif()

    if (_lupdate_program)
        add_custom_target(${_lupdate_target}
            #DEPENDS ${_arg_SOURCES}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMAND ${_lupdate_program}
                    -source-language ${_arg_SOURCE_LANG}
                    -target-language ${_arg_TARGET_LANG}
                    -no-recursive
                    -locations relative
                    #-no-sort
                    -silent
                    ${_arg_SOURCES}
                    -ts ${BASENAME}_${_arg_TARGET_LANG}.ts)

        if (_arg_DEPENDS)
            add_dependencies(${_lupdate_target} ${_arg_DEPENDS})
        endif()
    else()
        add_custom_target(${_lupdate_target}
            COMMAND ${CMAKE_COMMAND} -E echo "`lupdate` command/program not found"
            COMMAND ${CMAKE_COMMAND} -E false)
    endif()

    if (NOT _lrelease_program)
        if (Qt5_BIN_DIR AND EXISTS "${Qt5_BIN_DIR}/lrelease${CMAKE_EXECUTABLE_SUFFIX}")
            set(_lrelease_program "${Qt5_BIN_DIR}/lrelease${CMAKE_EXECUTABLE_SUFFIX}")
        endif()
    endif()

    if (_lrelease_program)
        set(_source "${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}_${_arg_TARGET_LANG}.ts")
        set(_dest "${_arg_RELEASE_DIR}/${BASENAME}_${_arg_TARGET_LANG}.qm")

        add_custom_target(${_lrelease_target}
            DEPENDS ${_lupdate_target}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${_arg_RELEASE_DIR}
            COMMAND ${_lrelease_program} ${_source} -qm ${_dest})

        # Push destination file to list to use by amalgamation process
        set(_prop _PORTABLE_TARGET_TRANSLATION_${_arg_TARGET_LANG})
        get_property(_list GLOBAL PROPERTY ${_prop})
        list(APPEND _list ${_dest})
        set_property(GLOBAL PROPERTY ${_prop} ${_list})
    else()
        add_custom_target(${_lrelease_target}
            COMMAND ${CMAKE_COMMAND} -E echo "`lrelease` command/program not found"
            COMMAND ${CMAKE_COMMAND} -E false)
    endif()

    if (_arg_PARENT_TARGET)
        if (NOT TARGET ${_arg_PARENT_TARGET})
            add_custom_target(${_arg_PARENT_TARGET})
        endif()

        add_dependencies(${_arg_PARENT_TARGET} ${_lrelease_target})
    endif()
endfunction()

#
# portable_translation_amalgamate(<basename>
#       TARGET_LANG <lang>    <= input
#       [RELEASE_DIR <dir>]   <= input
#       [OUTPUT_DIR <dir>]    <= input
#       [OUTPUT_FILE <path>]) <= output
#
function (portable_translation_amalgamate BASENAME)
    set(boolparm)

    set(singleparm
        TARGET_LANG
        RELEASE_DIR
        OUTPUT_DIR
        OUTPUT_FILE)

    set(multiparm
        DEPENDS)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_TARGET_LANG)
        _portable_target_error(${BASENAME} "No target language specified")
    endif()

    if (NOT _arg_RELEASE_DIR)
        set(_arg_RELEASE_DIR "${CMAKE_BINARY_DIR}/Translation")
    endif()

    if (NOT _arg_OUTPUT_DIR)
        set(_arg_OUTPUT_DIR ${_arg_RELEASE_DIR})
    endif()

    set(_target ${BASENAME}_${_arg_TARGET_LANG})

    _optional_var_env(Qt5_ROOT Qt5_ROOT "Qt5 Root directory")
    _optional_var_env(Qt5_PLATFORM Qt5_PLATFORM "Qt5 Platform directory")

    if (Qt5_ROOT AND Qt5_PLATFORM)
        set(Qt5_BIN_DIR "${Qt5_ROOT}/${Qt5_PLATFORM}/bin")
    endif()

    if (NOT _lconvert_program)
        if (Qt5_BIN_DIR AND EXISTS "${Qt5_BIN_DIR}/lconvert${CMAKE_EXECUTABLE_SUFFIX}")
            set(_lconvert_program "${Qt5_BIN_DIR}/lconvert${CMAKE_EXECUTABLE_SUFFIX}")
        endif()
    endif()

    if (_lconvert_program)
        set(_dest "${_arg_OUTPUT_DIR}/${_target}.qm")

        # Get files from list
        set(_prop _PORTABLE_TARGET_TRANSLATION_${_arg_TARGET_LANG})
        get_property(_sources GLOBAL PROPERTY ${_prop})

        add_custom_target(${_target}
            WORKING_DIRECTORY ${_arg_RELEASE_DIR}
            COMMAND ${_lconvert_program} -o ${_dest} ${_sources})

        if (_arg_OUTPUT_FILE)
            set(${_arg_OUTPUT_FILE} ${_dest} PARENT_SCOPE)
        endif()

        if (_arg_DEPENDS)
            add_dependencies(${_target} ${_arg_DEPENDS})
        endif()
   else()
        add_custom_target(${_target}
            COMMAND ${CMAKE_COMMAND} -E echo "`lconvert` command/program not found"
            COMMAND ${CMAKE_COMMAND} -E false)
    endif()

endfunction()
