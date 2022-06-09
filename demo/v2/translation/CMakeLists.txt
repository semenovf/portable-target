################################################################################
# Copyright (c) 2021,2022 Vladislav Trifochkin
#
# Changelog:
#      2022.01.18 Initial version.
################################################################################
cmake_minimum_required(VERSION 3.11)
project(translation)

include(${CMAKE_SOURCE_DIR}/cmake/v2/PortableTarget.cmake)

portable_target(SET ENABLE_TRACE ON)

if (NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# Variants (1), (2) and (3) give the same result
# (1)
set(COPYRIGHT_HOLDER "Vladislav Trifochkin <wladt@jobquest.ru>")
# (2) set(PORTABLE_TARGET_COPYRIGHT_HOLDER "Vladislav Trifochkin <wladt@jobquest.ru>")

portable_target(ADD_EXECUTABLE ${PROJECT_NAME})

portable_target(SOURCES ${PROJECT_NAME} main.cpp)
portable_target(TRANSLATE ${PROJECT_NAME}
    # (3) COPYRIGHT_HOLDER "Vladislav Trifochkin <wladt@jobquest.ru>"
    HEADER_NAME      "translate.h"
    PACKAGE_NAME     ${PROJECT_NAME}
    PACKAGE_VERSION  "1.0"
    LANGUAGES        "ru_RU")
