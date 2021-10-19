################################################################################
# Copyright (c) 2020 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2020.10.03 Initial version.
################################################################################

#
# Based on:
# https://stackoverflow.com/questions/18968979/how-to-get-colorized-output-with-cmake
#

# IMPORTANT
#   Must be included only once in the topmost CMakeLists.txt to avoid
#   endless recursion.

if (NOT WIN32)
    string(ASCII 27 Esc)
    set(ColourReset "${Esc}[m")
    set(ColourBold  "${Esc}[1m")
    set(Red         "${Esc}[31m")
    set(Green       "${Esc}[32m")
    set(Yellow      "${Esc}[33m")
    set(Blue        "${Esc}[34m")
    set(Magenta     "${Esc}[35m")
    set(Cyan        "${Esc}[36m")
    set(White       "${Esc}[37m")
    set(BoldRed     "${Esc}[1;31m")
    set(BoldGreen   "${Esc}[1;32m")
    set(BoldYellow  "${Esc}[1;33m")
    set(BoldBlue    "${Esc}[1;34m")
    set(BoldMagenta "${Esc}[1;35m")
    set(BoldCyan    "${Esc}[1;36m")
    set(BoldWhite   "${Esc}[1;37m")

    set(FatalErrorMessageColour    "${BoldRed}")
    set(WarningMessageColour       "${BoldYellow}")
    set(AuthorWarningMessageColour "${BoldCyan}")
    set(StatusMessageColour        "${Green}")
endif()

function (message)
    list(GET ARGV 0 MessageType)

    if (MessageType STREQUAL FATAL_ERROR OR MessageType STREQUAL SEND_ERROR)
        list(REMOVE_AT ARGV 0)
        _message(${MessageType} "${FatalErrorMessageColour}${ARGV}${ColourReset}")
    elseif (MessageType STREQUAL WARNING)
        list(REMOVE_AT ARGV 0)
        _message(${MessageType} "${WarningMessageColour}${ARGV}${ColourReset}")
    elseif (MessageType STREQUAL AUTHOR_WARNING)
        list(REMOVE_AT ARGV 0)
        _message(${MessageType} "${AuthorWarningMessageColour}${ARGV}${ColourReset}")
    elseif (MessageType STREQUAL STATUS)
        list(REMOVE_AT ARGV 0)
        _message(${MessageType} "${StatusMessageColour}${ARGV}${ColourReset}")
    else()
        _message("${ARGV}")
    endif()
endfunction()
