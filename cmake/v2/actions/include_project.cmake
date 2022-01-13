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
    include(${PATH})
endfunction(portable_target_include_project)
