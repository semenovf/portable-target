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
find_program(MSGCAT_BIN   msgcat)
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

if (MSGCAT_BIN)
    _portable_target_status("`msgcat` program found at: ${MSGCAT_BIN}")
#else()
    #_portable_target_error("`msgcat` program not found (is mandatory)")
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
#   [LANG lang]
#   LANGUAGES lang [lang...])
#
# ADD_COMMENTS
#       Place all comment blocks preceding keyword lines in output file
#       (default is unspecified).
#
# SORT_OUTPUT
#       Generate sorted output (default is unspecified).
#
# HEADER_NAME header_name
#       Header name for keyword definitions (will be autogenerated at
#       ${CMAKE_BINARY_DIR}).
#
# SINGULAR_KEYWORD keyword
#       Singular keyword (`TR_` is default).
#
# PLURAL_KEYWORD keyword
#       Plural keyword (`TRn_` is default).
#
# NOOP_KEYWORD keyword
#       No-op keyword (`TRnoop_` is default).
#
# COPYRIGHT_HOLDER holder
#       Set copyright holder in output.
#
# PACKAGE_NAME package_name
#       Set package name in output (default is unspecified).
#
# PACKAGE_VERSION package_version
#       Set package version in output (default is unspecified).
#
# OUTPUT_SOURCE_DIR
#       Directory to output PO-files (default is
#       `${CMAKE_CURRENT_SOURCE_DIR}/locale`)
#
# OUTPUT_BINARY_DIR
#       Root directory to output MO-files (default is
#       `${CMAKE_CURRENT_BINARY_DIR}`). Resulting path will be
#       `OUTPUT_BINARY_DIR/locale/ll[_LL]/LC_MESSAGES`, where `ll_LL` is a
#       language abbreviation.
#
# LANG lang
#       According to `xgettext` `lang` is one of: C, C++, ObjectiveC, PO,
#       Shell, Python, Lisp, EmacsLisp, librep, Scheme, Smalltalk, Java,
#       JavaProperties, C#, awk, YCP, Tcl, Perl, PHP, Ruby, GCC-source,
#       NXStringTable, RST, RSJ, Glade, Lua, JavaScript, Vala, Desktop.
#       Default is C++.
#
# LANGUAGES
#

function (portable_target_translate TARGET)
    set(boolparm ADD_COMMENTS SORT_OUTPUT)
    set(singleparm
        HEADER_NAME
        SINGULAR_KEYWORD
        PLURAL_KEYWORD
        NOOP_KEYWORD
        COPYRIGHT_HOLDER
        PACKAGE_NAME
        PACKAGE_VERSION
        OUTPUT_SOURCE_DIR
        OUTPUT_BINARY_DIR
        LANG)
    set(multiparm LANGUAGES)

    if (NOT TARGET ${TARGET})
        _portable_target_error( "Unknown TARGET: ${TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_LANGUAGES)
        _portable_target_error(${TARGET} "No language(s) specified")
    endif()

    if (NOT _arg_SINGULAR_KEYWORD)
        set(_arg_SINGULAR_KEYWORD "_")
    endif()

    if (NOT _arg_PLURAL_KEYWORD)
        set(_arg_PLURAL_KEYWORD "n_")
    endif()

    if (NOT _arg_NOOP_KEYWORD)
        set(_arg_NOOP_KEYWORD "noop_")
    endif()

    #if (_arg_HEADER_NAME)
        #set(_header_file ${CMAKE_BINARY_DIR}/${_arg_HEADER_NAME})
        #_portable_target_trace(${TARGET} "Translation keywords header: [${_header_file}]")

        #if (NOT EXISTS ${_header_file})
            #string(TIMESTAMP _generation_time UTC)

            #file(WRITE ${_header_file}
                #"//////////////////////////////////////////////////////////////////////////////\n")
            #file(APPEND ${_header_file}
                #"/// AUTOMATICALLY GENERATED BY portable_target AT ${_generation_time} UTC ///\n")
            #file(APPEND ${_header_file}
                #"//////////////////////////////////////////////////////////////////////////////\n")

            #file(APPEND ${_header_file} [=[
##pragma once
##include <libintl.h>
#]=])
            #file(APPEND ${_header_file} "#define ${_arg_SINGULAR_KEYWORD}(x) gettext(x)\n")
            #file(APPEND ${_header_file} "#define ${_arg_PLURAL_KEYWORD}(x, y, n) ngettext(x, y, n)\n")
            #file(APPEND ${_header_file} "#define ${_arg_NOOP_KEYWORD}(x) x\n")
        #endif()

        #target_include_directories(${TARGET} PUBLIC ${CMAKE_BINARY_DIR})
    #endif()

    get_target_property(_target_sources ${TARGET} SOURCES)
    _portable_target_trace(${TARGET} "Sources for translation: [${_target_sources}]")

    set(_xgettext_args)

    if (_arg_ADD_COMMENTS)
        list(APPEND _xgettext_args "--add-comments" )
    endif()

    if (_arg_SORT_OUTPUT)
        list(APPEND _xgettext_args "--sort-output")
    endif()

    _optional_var_env(_arg_COPYRIGHT_HOLDER COPYRIGHT_HOLDER "Copyright holder")

    if (_arg_COPYRIGHT_HOLDER)
        _portable_target_trace(${TARGET} "Copyright holder: [${_arg_COPYRIGHT_HOLDER}]")
        list(APPEND _xgettext_args "--copyright-holder='${_arg_COPYRIGHT_HOLDER}'")
    endif()

    if (_arg_PACKAGE_NAME)
        list(APPEND _xgettext_args "--package-name='${_arg_PACKAGE_NAME}'")
    endif()

    if (_arg_PACKAGE_VERSION)
        list(APPEND _xgettext_args "--package-version='${_arg_PACKAGE_VERSION}'")
    endif()

    if (_arg_LANG)
        list(APPEND _xgettext_args "--language=${_arg_LANG}")
    else()
        list(APPEND _xgettext_args "--language=C++")
    endif()

    list(APPEND _xgettext_args "--keyword=${_arg_SINGULAR_KEYWORD}")
    list(APPEND _xgettext_args "--keyword=${_arg_PLURAL_KEYWORD}:1,2")
    list(APPEND _xgettext_args "--keyword=${_arg_NOOP_KEYWORD}")

    _portable_target_trace(${TARGET} "xgettext args: [${_xgettext_args}]")

    if (_arg_OUTPUT_SOURCE_DIR)
        set(_pot_output_dir ${_arg_OUTPUT_SOURCE_DIR})
    else()
        set(_pot_output_dir ${CMAKE_CURRENT_SOURCE_DIR}/locale)
    endif()

    if (_arg_OUTPUT_BINARY_DIR)
        set(_mo_output_dir ${_arg_OUTPUT_BINARY_DIR})
    else()
        set(_mo_output_dir "${CMAKE_CURRENT_BINARY_DIR}/locale")
    endif()

    set(_po_output_dir ${_pot_output_dir})

    foreach (_dir ${_pot_output_dir};${_po_output_dir};${_mo_output_dir})
        if (NOT EXISTS ${_dir})
            _portable_target_trace(${TARGET} "Create directory: [${_dir}]")
            file(MAKE_DIRECTORY ${_dir})
        endif()
    endforeach()

    # Portable Object Template (POT)
    set(_pot_file ${_pot_output_dir}/${TARGET}.pot)
    _portable_target_trace(${TARGET} "POT file: [${_pot_file}]")

    message(STATUS "${XGETTEXT_BIN} ${_xgettext_args} --output=${_pot_file} ${_target_sources}")

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
        set(_mo_file ${_mo_output_dir}/${_lang}/LC_MESSAGES/${TARGET}.mo)

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
                    "--locale=${_lang}"
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
