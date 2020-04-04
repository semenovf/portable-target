################################################################################
# Copyright (c) 2020 Vladislav Trifochkin
#
# Changelog:
#      2020.04.04 Initial version
################################################################################
#
# $ cmake -G <Generator>
################################################################################
include(${CMAKE_SOURCE_DIR}/cmake/PortableTarget.cmake)

set(PORTABLE_TARGET_AGGRESSIVE_COMPILER_CHECK ON)

if (NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

set(SOURCES main.cpp)

portable_target(aggressive_check
#     AGGRESSIVE_COMPILER_CHECK
    SOURCES ${SOURCES})


