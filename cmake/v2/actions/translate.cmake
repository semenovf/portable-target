################################################################################
# Copyright (c) 2021,2022 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2022.01.18 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

find_program(XGETTEXT_BIN xgettext)
find_program(MSGFMT_BIN   msgfmt)
find_program(MSGINIT_BIN  msginit)
find_program(MSGMERGE_BIN msgmerge)
find_package(Intl REQUIRED)

if (XGETTEXT_BIN)
    _portable_target_status("`xgettext` program found at: ${XGETTEXT_BIN}")
else()
    _portable_target_error("`xgettext` program not found (is mandatory)")
endif()

if (MSGFMT_BIN)
    _portable_target_status("`msgfmt` program found at: ${MSGFMT_BIN}")
else()
    _portable_target_error("`msgfmt` program not found (is mandatory)")
endif()

if (MSGINIT_BIN)
    _portable_target_status("`msginit` program found at: ${MSGINIT_BIN}")
else()
    _portable_target_error("`msginit` program not found (is mandatory)")
endif()

if (MSGMERGE_BIN)
    _portable_target_status("`msgmerge` program found at: ${MSGMERGE_BIN}")
else()
    _portable_target_error("`msgmerge` program not found (is mandatory)")
endif()

#
# Useful references
# * [GNU gettext utilities](https://www.gnu.org/software/gettext/manual/gettext.html)
# * https://github.com/Skyb0rg007/Gettext-CMake
#

#
# Usage:
#
# portable_target_translate(<target>
#   [ADD_COMMENTS]
#   [SORT_OUTPUT]
#   [HEADER_NAME header_name]
#   [SINGULAR_KEYWORD keyword]
#   [PLURAL_KEYWORD keyword]
#   [COPYRIGHT_HOLDER holder]
#   [PACKAGE_NAME package_name]
#   [PACKAGE_VERSION package_version]
#   LANGUAGES lang [lang...])
#
# ADD_COMMENTS
#       place all comment blocks preceding keyword lines in output file
#       (default is unspecified)
#
# SORT_OUTPUT
#       generate sorted output (default is unspecified)
#
# HEADER_NAME header_name
#       header name for keyword definitions (will be autogenerated at
#       ${CMAKE_BINARY_DIR})
#
# SINGULAR_KEYWORD keyword
#       singular keyword (`TR_` is default)
#
# PLURAL_KEYWORD keyword
#       plural keyword (`TRn_` is default)
#
# COPYRIGHT_HOLDER holder
#       set copyright holder in output
#
# PACKAGE_NAME package_name
#       set package name in output (default is unspecified)
#
# PACKAGE_VERSION package_version
#       set package version in output (default is unspecified)
#
# LANGUAGES
#

function (portable_target_translate TARGET)
    set(boolparm ADD_COMMENTS SORT_OUTPUT)
    set(singleparm
        HEADER_NAME
        SINGULAR_KEYWORD
        PLURAL_KEYWORD
        COPYRIGHT_HOLDER
        PACKAGE_NAME
        PACKAGE_VERSION)
    set(multiparm LANGUAGES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_LANGUAGES)
        _portable_target_error(${TARGET} "No language(s) specified")
    endif()

    portable_target_get_property(OBJLIB_SUFFIX _objlib_suffix)

    # For library target definitions must be assigned to OBJECT target
    if (TARGET ${TARGET}${_objlib_suffix})
        set(TARGET ${TARGET}${_objlib_suffix})
    endif()

    if (NOT _arg_SINGULAR_KEYWORD)
        set(_arg_SINGULAR_KEYWORD "TR_")
    endif()

    if (NOT _arg_PLURAL_KEYWORD)
        set(_arg_PLURAL_KEYWORD "TRn_")
    endif()

    if (_arg_HEADER_NAME)
        set(_header_file ${CMAKE_BINARY_DIR}/${_arg_HEADER_NAME})
        _portable_target_trace(${TARGET} "Translation keywords header: [${_header_file}]")

        if (NOT EXISTS ${_header_file})
            string(TIMESTAMP _generation_time UTC)

            file(WRITE ${_header_file}
                "//////////////////////////////////////////////////////////////////////////////\n")
            file(APPEND ${_header_file}
                "/// AUTOMATICALLY GENERATED BY portable_target AT ${_generation_time} UTC ///\n")
            file(APPEND ${_header_file}
                "//////////////////////////////////////////////////////////////////////////////\n")

            file(APPEND ${_header_file} [=[
#pragma once
#include <libintl.h>
#define TR_(x)        ::gettext(x)
#define TRn_(x, y, n) ::ngettext(x, y, n)
]=])
        endif()

        target_include_directories(${TARGET} PUBLIC ${CMAKE_BINARY_DIR})
    endif()

    get_target_property(_target_sources ${TARGET} SOURCES)
    _portable_target_trace(${TARGET} "Sources for translation: [${_target_sources}]")

    set(_xgettext_args)

    if (_arg_ADD_COMMENTS)
        list(APPEND _xgettext_args "--add-comments" )
    endif()

    if (_arg_SORT_OUTPUT)
        list(APPEND _xgettext_args "--sort-output")
    endif()

    if (_arg_COPYRIGHT_HOLDER)
        list(APPEND _xgettext_args "--copyright-holder='${_arg_COPYRIGHT_HOLDER}'")
    endif()

    if (_arg_PACKAGE_NAME)
        list(APPEND _xgettext_args "--package-name='${_arg_PACKAGE_NAME}'")
    endif()

    if (_arg_PACKAGE_VERSION)
        list(APPEND _xgettext_args "--package-version='${_arg_PACKAGE_VERSION}'")
    endif()

    list(APPEND _xgettext_args "--keyword=${_arg_SINGULAR_KEYWORD}")
    list(APPEND _xgettext_args "--keyword=${_arg_PLURAL_KEYWORD}:1,2")
    #list(APPEND _xgettext_args "--language=C")
    list(APPEND _xgettext_args "--language=C++")

    _portable_target_trace(${TARGET} "xgettext args: [${_xgettext_args}]")

    set(_pot_output_dir ${CMAKE_CURRENT_SOURCE_DIR}/locale)
    set(_po_output_dir ${_pot_output_dir})
    set(_mo_output_dir ${CMAKE_CURRENT_BINARY_DIR}/locale)

    foreach (_dir ${_pot_output_dir};${_po_output_dir};${_mo_output_dir})
        if (NOT EXISTS ${_dir})
            _portable_target_trace(${TARGET} "Create directory: [${_dir}]")
            file(MAKE_DIRECTORY ${_dir})
        endif()
    endforeach()

    # Portable Object Template (POT)
    set(_pot_file ${_pot_output_dir}/${TARGET}.pot)
    _portable_target_trace(${TARGET} "POT file: [${_pot_file}]")

    # POT-file initialization
    if (NOT EXISTS ${_pot_file})
        execute_process(
            COMMAND "${XGETTEXT_BIN}"
                ${_xgettext_args}
                "--output=${_pot_file}"
                ${_target_sources}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE _xgettext_result
            ERROR_VARIABLE _xgettext_error
            ERROR_STRIP_TRAILING_WHITESPACE)

        if (_xgettext_result)
            _portable_target_error(${TARGET} "${_xgettext_error}")
        endif()
    endif()

    # POT-file updating
    add_custom_command(
        COMMENT "Updating ${_pot_file}"
        OUTPUT ${_pot_file}
        COMMAND "${XGETTEXT_BIN}"
            ${_xgettext_args}
            "--output=${_pot_file}"
            ${_target_sources}
        DEPENDS ${_target_sources}
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

    foreach(_lang ${_arg_LANGUAGES})
        _portable_target_trace(${TARGET} "Process language: [${_lang}]")

        set(_po_file ${_po_output_dir}/${TARGET}_${_lang}.po)
        set(_mo_file ${_mo_output_dir}/${TARGET}_${_lang}.mo)

        _portable_target_trace(${TARGET} "PO file: [${_po_file}]")

        if (NOT EXISTS ${_po_file})
            # Supress `user-email: cannot create /dev/tty: No such device or address`
            # Supress `A translation team for your language () does not exist yet.`
            # Supress other inessential messages
            list(APPEND _msginit_args "--no-translator")

            execute_process(
                COMMAND "${MSGINIT_BIN}" ${_msginit_args}
                    "--input=${_pot_file}"
                    "--output-file=${_po_file}"
                    "--locale=${_lang}.UTF-8"
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                RESULT_VARIABLE _msginit_result
                ERROR_VARIABLE _msginit_error
                ERROR_STRIP_TRAILING_WHITESPACE)

            if (_msginit_result)
                _portable_target_error(${TARGET} "${_msginit_error}")
            endif()
        endif()

        list(APPEND _msgmerge_args "")

        add_custom_command(
            COMMENT "Update ${_po_file}"
            OUTPUT "${_po_file}"
            COMMAND "${MSGMERGE_BIN}" ${_msgmerge_args}
                "${_po_file}"
                "${_pot_file}"
                "--output-file=${_po_file}"
            DEPENDS "${_pot_file}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

        list(APPEND _msgfmt_args "")

        add_custom_command(
            COMMENT "Create ${_mo_file}"
            OUTPUT "${_mo_file}"
            COMMAND "${MSGFMT_BIN}" ${_msgfmt_args}
                "${_po_file}"
                "--output-file=${_mo_file}"
            DEPENDS "${_po_file}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

        add_custom_target("${TARGET}-${_lang}" DEPENDS "${_mo_file}")
        add_dependencies("${TARGET}" "${TARGET}-${_lang}")
    endforeach()
endfunction(portable_target_translate)