################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.21 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

function (_portable_target_set_property BASE_NAME VALUE)
    set_property(GLOBAL PROPERTY PORTABLE_TARGET_PROP_${BASE_NAME} ${VALUE})
endfunction(_portable_target_set_property)

#
# Properties:
#   OBJLIB_SUFFIX
#   STATIC_SUFFIX
#   STATIC_ALIAS_SUFFIX
#
function (_portable_target_set_properties_defaults)
    # Check if default values set
    get_property(_is_defaults_set GLOBAL PROPERTY PORTABLE_TARGET_PROP_DEFAULTS)

    if (NOT _is_defaults_set)
        # Mark of applying default values for properties
        set_property(GLOBAL PROPERTY PORTABLE_TARGET_PROP_DEFAULTS TRUE)

        _portable_target_set_property(OBJLIB_SUFFIX "_OBJLIB")
        _portable_target_set_property(STATIC_SUFFIX "-static")
        _portable_target_set_property(STATIC_ALIAS_SUFFIX "::static")
    endif()
endfunction(_portable_target_set_properties_defaults)

#
# Usage:
#
# portable_target_set_property(<name> <value>)
#
function (portable_target_set_property PROPERTY_NAME PROPERTY_VALUE)
    _portable_target_set_properties_defaults()

    if (NOT PROPERTY_NAME)
        _portable_target_error("PROPERTY_NAME must be specified")
    endif()

    if (NOT DEFINED PROPERTY_VALUE)
        _portable_target_error("PROPERTY_VALUE must be specified")
    endif()

    set_property(GLOBAL PROPERTY PORTABLE_TARGET_PROP_${PROPERTY_NAME} ${PROPERTY_VALUE})
endfunction(portable_target_set_property)

#
# Usage:
#
# portable_target_get_property(<name> <var> [<default_value>])
#
function (portable_target_get_property PROPERTY_NAME VARIABLE)
    _portable_target_set_properties_defaults()

    if (${ARGC} GREATER 2)
        set(_default_value ${ARGV2})
    endif()

    if (NOT PROPERTY_NAME)
        _portable_target_error("PROPERTY_NAME must be specified and not empty")
    endif()

    get_property(_var GLOBAL PROPERTY PORTABLE_TARGET_PROP_${PROPERTY_NAME})

    if (NOT DEFINED _var)
        if (DEFINED _default_value)
            set(_var ${_default_value})
        endif()
    endif()

    #_portable_target_status("VARIABLE: [${VARIABLE}]")
    set(${VARIABLE} ${_var} PARENT_SCOPE)
endfunction(portable_target_get_property)
