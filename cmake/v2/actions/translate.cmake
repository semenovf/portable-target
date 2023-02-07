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
#find_package(Intl REQUIRED)

if (NOT DEFINED TRANSLATION_GENERATION_DISABLED)
    if (XGETTEXT_BIN)
        _portable_target_status("`xgettext` program found at: ${XGETTEXT_BIN}")
    else()
        list(APPEND _translation_tools_not_found "xgettext")
    endif()

    if (MSGFMT_BIN)
        _portable_target_status("`msgfmt` program found at: ${MSGFMT_BIN}")
    else()
        list(APPEND _translation_tools_not_found "msgfmt")
    endif()

    if (MSGINIT_BIN)
        _portable_target_status("`msginit` program found at: ${MSGINIT_BIN}")
    else()
        list(APPEND _translation_tools_not_found "msginit")
    endif()

    if (MSGMERGE_BIN)
        _portable_target_status("`msgmerge` program found at: ${MSGMERGE_BIN}")
    else()
        list(APPEND _translation_tools_not_found "msgmerge")
    endif()

    if (MSGCAT_BIN)
        _portable_target_status("`msgcat` program found at: ${MSGCAT_BIN}")
    else()
        list(APPEND _translation_tools_not_found "msgcat")
    endif()

    if (DEFINED _translation_tools_not_found)
        _portable_target_warn("One or more `gettext` tools not found: ${_translation_tools_not_found}")
        _portable_target_warn("File translation generation disabled")
    endif()

    if (_translation_tools_not_found)
        set(TRANSLATION_GENERATION_DISABLED TRUE CACHE BOOL "")
    else()
        set(TRANSLATION_GENERATION_DISABLED FALSE CACHE BOOL "")
    endif()
endif()

#
# Useful references
# * [GNU gettext utilities](https://www.gnu.org/software/gettext/manual/gettext.html)
# * https://github.com/Skyb0rg007/Gettext-CMake
#

#
# Usage:
#
# portable_target (TRANSLATE AMALGAMATE TARGET
#   [OUTPUT_DIR]
#   [BASENAME basename])
#
# OUTPUT_DIR
#       Root directory to output MO-files (default is
#       `${CMAKE_CURRENT_BINARY_DIR}`). Resulting path will be
#       `OUTPUT_BINARY_DIR/locale/ll[_LL]/LC_MESSAGES`, where `ll_LL` is a
#       language abbreviation.
#
# BASENAME basename
#       Basename for amalgamated file name (for naming PO and MO-files).
#       Default is TARGET name.
#

function (_portable_target_translate_amalgamate TARGET)
    if (TRANSLATION_GENERATION_DISABLED)
        return()
    endif()

    set(boolparm)
    set(singleparm OUTPUT_DIR BASENAME)
    set(multiparm)

    _portable_target_set_properties_defaults()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    portable_target_get_property(_TRANSLATE_LANGUAGES _translate_languages)

    if (NOT _arg_BASENAME)
        set(_arg_BASENAME ${TARGET})
    endif()

    add_custom_target(${TARGET})

    if (_translate_languages)
        foreach (_lang ${_translate_languages})
            portable_target_get_property(_TRANSLATE_LANGUAGES_${_lang} _po_files)

            if (_po_files)
                if (NOT _arg_OUTPUT_DIR)
                    set(_arg_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/locale")
                endif()

                set(_amalgamated_po_file "${_arg_OUTPUT_DIR}/${_arg_BASENAME}.${_lang}.po")
                set(_mo_output_dir "${_arg_OUTPUT_DIR}/${_lang}/LC_MESSAGES")
                set(_amalgamated_mo_file "${_mo_output_dir}/${_arg_BASENAME}.mo")

                if (NOT EXISTS ${_arg_OUTPUT_DIR})
                    _portable_target_trace(${TARGET} "Create directory: [${_arg_OUTPUT_DIR}]")
                    file(MAKE_DIRECTORY ${_arg_OUTPUT_DIR})
                endif()

                if (NOT EXISTS ${_mo_output_dir})
                    _portable_target_trace(${TARGET} "Create directory: [${_mo_output_dir}]")
                    file(MAKE_DIRECTORY ${_mo_output_dir})
                endif()

                list(APPEND _msgcat_args "")

                add_custom_command(
                    COMMENT "Amalgamate PO-files into ${_amalgamated_po_file}"
                    OUTPUT "${_amalgamated_po_file}"
                    COMMAND "${MSGCAT_BIN}" ${_msgcat_args}
                       "--output-file=${_amalgamated_po_file}"
                        ${_po_files}
                    DEPENDS "${_po_files}")

                list(APPEND _msgfmt_args "")

                add_custom_command(
                    COMMENT "Create MO-file ${_amalgamated_mo_file}"
                    OUTPUT "${_amalgamated_mo_file}"
                    COMMAND "${MSGFMT_BIN}" ${_msgfmt_args}
                        "--output-file=${_amalgamated_mo_file}"
                        "${_amalgamated_po_file}"
                    DEPENDS "${_amalgamated_po_file}")

                add_custom_target("${TARGET}_${_lang}" DEPENDS "${_amalgamated_mo_file}")
                add_dependencies("${TARGET}" "${TARGET}_${_lang}")
            endif()
        endforeach()

        _portable_target_trace(${TARGET} "Amalgamated translation root target: ${TARGET}")
    else()
        _portable_target_warn(${TARGET} "No languages for translations are specified")
    endif()

endfunction(_portable_target_translate_amalgamate)

#
# Usage:
#
# portable_target (TRANSLATE UPDATE PARENT_TARGET
#   [ADD_COMMENTS]
#   [SORT_OUTPUT]
#   [COPYRIGHT_HOLDER holder]
#   [PACKAGE_NAME package_name]
#   [PACKAGE_VERSION package_version]
#   [LANG lang]
#   [NO_SOURCE_LOCATION]
#   [KEYWORD keyword [keyword...]]
#   [OVERRIDE_KEYWORDS]
#   [OUTPUT_DIR dir]
#   [SOURCES source [source...]]
#   LANGUAGES language [language...])
#
# ADD_COMMENTS
#       Place all comment blocks preceding keyword lines in output file
#       (default is unspecified).
#
# SORT_OUTPUT
#       Generate sorted output (default is unspecified).
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
# OVERRIDE_KEYWORDS
#       Overrides default keywords.
#
# KEYWORD keyword...
#       Add keywords.
#
# LANG lang
#       According to `xgettext` `lang` is one of: C, C++, ObjectiveC, PO,
#       Shell, Python, Lisp, EmacsLisp, librep, Scheme, Smalltalk, Java,
#       JavaProperties, C#, awk, YCP, Tcl, Perl, PHP, Ruby, GCC-source,
#       NXStringTable, RST, RSJ, Glade, Lua, JavaScript, Vala, Desktop.
#       Default is C++.
#
# NO_SOURCE_LOCATION
#       Do not write ‘#: filename:line’ lines.
#
# OUTPUT_DIR dir
#       Directory to output PO-files (default is
#       `${CMAKE_CURRENT_SOURCE_DIR}/locale`)
#
# SOURCES source...
#       Sources additional to parent target sources for extract information
#       for translation.
#
# LANGUAGES
#       Target translation languages.
#
#
function (_portable_target_translate_update PARENT_TARGET)
    if (TRANSLATION_GENERATION_DISABLED)
        return()
    endif()

    set(boolparm ADD_COMMENTS SORT_OUTPUT NO_SOURCE_LOCATION)
    set(singleparm
        COPYRIGHT_HOLDER
        PACKAGE_NAME
        PACKAGE_VERSION
        OUTPUT_DIR
        LANG)
    set(multiparm LANGUAGES SOURCES KEYWORD)

    if (NOT TARGET ${PARENT_TARGET})
        _portable_target_error( "Unknown parent target: ${PARENT_TARGET}")
    endif()

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_LANGUAGES)
        _portable_target_error(${PARENT_TARGET} "No language(s) specified")
    endif()

    get_target_property(_target_type ${PARENT_TARGET} TYPE)

    if (NOT _target_type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(_target_sources ${PARENT_TARGET} SOURCES)
    endif()

    if (_arg_SOURCES)
        list(APPEND _target_sources ${_arg_SOURCES})
    endif()

    _portable_target_trace(${PARENT_TARGET} "Sources for translation: [${_target_sources}]")

    set(_xgettext_args "--from-code=UTF-8")

    if (_arg_ADD_COMMENTS)
        list(APPEND _xgettext_args "--add-comments" )
    endif()

    if (_arg_SORT_OUTPUT)
        list(APPEND _xgettext_args "--sort-output")
    endif()

    _optional_var_env(_arg_COPYRIGHT_HOLDER COPYRIGHT_HOLDER "Copyright holder")

    if (_arg_COPYRIGHT_HOLDER)
        _portable_target_trace(${PARENT_TARGET} "Copyright holder: [${_arg_COPYRIGHT_HOLDER}]")
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

    if (NOT _arg_OVERRIDE_KEYWORDS)
        list(APPEND _xgettext_args "--keyword=_")
        list(APPEND _xgettext_args "--keyword=n_:1,2")
        list(APPEND _xgettext_args "--keyword=noop_")
        list(APPEND _xgettext_args "--keyword=f_")
        list(APPEND _xgettext_args "--keyword=tr")
        list(APPEND _xgettext_args "--keyword=qsTr")
    endif()

    if (_arg_KEYWORD)
        foreach (_keyword ${_arg_KEYWORD})
            list(APPEND _xgettext_args "--keyword=${_keyword}")
        endforeach()
    endif()

    if (_arg_NO_SOURCE_LOCATION)
        list(APPEND _xgettext_args "--no-location")
    endif()

    _portable_target_trace(${PARENT_TARGET} "xgettext args: [${_xgettext_args}]")

    if (_arg_OUTPUT_DIR)
        set(_pot_output_dir ${_arg_OUTPUT_DIR})
    else()
        set(_pot_output_dir ${CMAKE_CURRENT_SOURCE_DIR}/locale)
    endif()

    set(_po_output_dir ${_pot_output_dir})

    # Portable Object Template (POT)
    set(_pot_file ${_pot_output_dir}/${PARENT_TARGET}.pot)
    _portable_target_trace(${PARENT_TARGET} "POT file: [${_pot_file}]")

    message(STATUS "${XGETTEXT_BIN} ${_xgettext_args} --output=${_pot_file} ${_target_sources}")

    # POT-file initialization
    if (NOT EXISTS ${_pot_file})
        file(MAKE_DIRECTORY ${_pot_output_dir})

        execute_process(
            COMMAND "${XGETTEXT_BIN}"
                ${_xgettext_args}
                "--force-po"    # Always write an output file even if no message is defined.
                "--output=${_pot_file}"
                ${_target_sources}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE _xgettext_result
            ERROR_VARIABLE _xgettext_error
            ERROR_STRIP_TRAILING_WHITESPACE)

        if (_xgettext_result)
            if (NOT _xgettext_result MATCHES "^[0-9]+$")
                _portable_target_error(${PARENT_TARGET} "${XGETTEXT_BIN}: ${_xgettext_result}: ${_xgettext_error}")
            else ()
                _portable_target_error(${PARENT_TARGET} "${XGETTEXT_BIN}: ${_xgettext_error} [error code: ${_xgettext_result}]")
            endif ()
        endif()
    endif()

    if (EXISTS ${_pot_file})
        # POT-file updating
        add_custom_command(
            COMMENT "Updating ${_pot_file}"

            # Need to prevent from delete generated file while
            # `cmake --build. . --target clean`
            OUTPUT "${_pot_file}-prevent-from-delete.tmp"
            COMMAND "${XGETTEXT_BIN}"
                ${_xgettext_args}
                "--output=${_pot_file}"
                ${_target_sources}
            DEPENDS ${_target_sources}
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

        portable_target_get_property(_TRANSLATE_LANGUAGES _translate_languages)

        foreach(_lang ${_arg_LANGUAGES})
            _portable_target_trace(${PARENT_TARGET} "Process language: [${_lang}]")

            set(_po_file ${_po_output_dir}/${PARENT_TARGET}.${_lang}.po)

            list(APPEND _po_files ${_po_file})

            list(APPEND _translate_languages ${_lang})
            list(REMOVE_DUPLICATES _translate_languages)

            portable_target_set_property(_TRANSLATE_LANGUAGES "${_translate_languages}")
            portable_target_append_property(_TRANSLATE_LANGUAGES_${_lang} ${_po_file})

            _portable_target_trace(${PARENT_TARGET} "PO file: [${_po_file}]")

            if (NOT EXISTS ${_po_file})
                file(MAKE_DIRECTORY ${_po_output_dir})

                # Supress `user-email: cannot create /dev/tty: No such device or address`
                # Supress `A translation team for your language () does not exist yet.`
                # Supress other inessential messages
                list(APPEND _msginit_args "--no-translator")

                execute_process(
                    COMMAND ${CMAKE_COMMAND} -E make_directory ${_po_output_dir}
                    COMMAND "${MSGINIT_BIN}" ${_msginit_args}
                        "--input=${_pot_file}"
                        "--output-file=${_po_file}"
                        "--locale=${_lang}"
                    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                    RESULT_VARIABLE _msginit_result
                    ERROR_VARIABLE _msginit_error
                    ERROR_STRIP_TRAILING_WHITESPACE)

                if (_msginit_result)
                    _portable_target_error(${PARENT_TARGET} "${_msginit_error}")
                endif()
            endif()

            list(APPEND _msgmerge_args "")

            add_custom_command(
                COMMENT "Update ${_po_file}"

                # Need to prevent from delete generated file while
                # `cmake --build. . --target clean`
                OUTPUT "${_po_file}-prevent-from-delete.tmp"

                COMMAND "${MSGMERGE_BIN}" ${_msgmerge_args}
                    "${_po_file}"
                    "${_pot_file}"
                    "--output-file=${_po_file}"
                DEPENDS "${_pot_file}")
        endforeach() # foreach LANGUAGES

        set(TRANSLATE_TARGET "${PARENT_TARGET}-translate")

        add_custom_target(${TRANSLATE_TARGET} DEPENDS ${_po_files})
        add_dependencies(${PARENT_TARGET} ${TRANSLATE_TARGET})

    endif() # EXISTS ${_pot_file}
endfunction(_portable_target_translate_update)

#
# Usage:
#
# portable_target_translate(SUBCOMMAND ...)
#
# SUBCOMMAND
#       One of subcommand: `AMALGAMATE` | `UPDATE`
#

function (portable_target_translate SUBCOMMAND)
    set(boolparm)
    set(singleparm)
    set(multiparm)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT SUBCOMMAND)
        _portable_target_error("TRANSLATE action expected at least SUBCOMMAND")
    endif()

    if (SUBCOMMAND STREQUAL "AMALGAMATE")
        _portable_target_translate_amalgamate(${_arg_UNPARSED_ARGUMENTS})
    elseif (SUBCOMMAND STREQUAL "UPDATE")
        _portable_target_translate_update(${_arg_UNPARSED_ARGUMENTS})
    else()
        _portable_target_error("Bad command for TRANSLATE action: ${COMMAND}")
    endif()

endfunction(portable_target_translate)
