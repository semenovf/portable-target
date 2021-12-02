################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# Changelog:
#      2021.12.02 Initial version.
################################################################################
cmake_minimum_required (VERSION 3.5)

if (NOT PFS_SPDLOG__LIBRARY)
    if (TARGET spdlog::spdlog)
        set(PFS_SPDLOG__LIBRARY spdlog::spdlog)
    elseif (TARGET spdlog)
        set(PFS_SPDLOG__LIBRARY spdlog)
    else()
        if (PFS_SPDLOG__ROOT AND EXISTS ${PFS_SPDLOG__ROOT}/CMakeLists.txt)
            add_subdirectory(${PFS_SPDLOG__ROOT} spdlog)
            set(PFS_SPDLOG__LIBRARY spdlog::spdlog)
            set(PFS_SPDLOG__INCLUDE_DIR ${PFS_SPDLOG__ROOT}/include)
        else()
            find_library(PFS_SPDLOG__LIBRARY NAMES spdlog)
        endif()
    endif()
endif()
