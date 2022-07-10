################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.12.09 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)

#
# Usage:
#
# portable_target_include_project(PATH)
#
function (portable_target_include_project PATH)
    set(_saved_CMAKE_PROJECT_NAME ${CMAKE_PROJECT_NAME})
    set(_saved_PROJECT_NAME ${PROJECT_NAME})

    get_filename_component(PORTABLE_TARGET__CURRENT_PROJECT_DIR
        ${PATH} DIRECTORY)

    include(${PATH})

    set(CMAKE_PROJECT_NAME ${_saved_CMAKE_PROJECT_NAME})
    project(${_saved_PROJECT_NAME})
endfunction(portable_target_include_project)
