################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2022.06.26 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

#
# Usage:
#
# portable_target_set_category(target category...)
#
function (portable_target_set_category TARGET)
    _portable_target_set_properties_defaults()

    list(REMOVE_AT ARGV 0)

    if (ARGV)
        portable_target_get_property(_TARGET_CATEGORIES _categories)

        foreach(_c ${ARGV})
            portable_target_append_property(_TARGET_CATEGORY_${_c} ${TARGET})
            list(APPEND _categories ${_c})
            list(REMOVE_DUPLICATES _categories)
            portable_target_set_property(_TARGET_CATEGORIES "${_categories}")
        endforeach()
    endif()
endfunction(portable_target_set_category)

#
# Usage:
#
# portable_target_get_categories(target variable)
#
function (portable_target_get_categories VARIABLE)
    portable_target_get_property(_TARGET_CATEGORIES _var)
    set(${VARIABLE} ${_var} PARENT_SCOPE)
endfunction(portable_target_get_categories)

#
# Usage:
#
# portable_target_get_categories(target variable)
#
function (portable_target_category_items NAME VARIABLE)
    portable_target_get_property(_TARGET_CATEGORY_${NAME} _var)
    set(${VARIABLE} ${_var} PARENT_SCOPE)
endfunction(portable_target_category_items)

