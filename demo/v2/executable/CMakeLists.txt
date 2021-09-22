################################################################################
# Copyright (c) 2020 Vladislav Trifochkin
#
# Changelog:
#      2020.04.04 Initial version
################################################################################
#
# $ cmake -G <Generator>
################################################################################
cmake_minimum_required(VERSION 3.11)
project(executable)

include(${CMAKE_SOURCE_DIR}/cmake/v2/PortableTarget.cmake)

if (NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

portable_target(SET ENABLE_TRACE ON)

portable_target(GET OBJLIB_SUFFIX _objlib_suffix)
portable_target(GET STATIC_SUFFIX _static_suffix)
portable_target(GET STATIC_ALIAS_SUFFIX _static_alias_suffix)
portable_target(GET UNDEFINED_VAR _undefined_var "UNDEFINED VALUE")

_portable_target_trace("OBJLIB_SUFFIX      : [${_objlib_suffix}]")
_portable_target_trace("STATIC_SUFFIX      : [${_static_suffix}]")
_portable_target_trace("STATIC_ALIAS_SUFFIX: [${_static_alias_suffix}]")
_portable_target_trace("UNDEFINED_VAR      : [${_undefined_var}]")

portable_target(ADD_EXECUTABLE executable)

portable_target(SOURCES executable
    main.cpp src.cpp
    INTERFACE iface1.cpp iface2.cpp
    PRIVATE priv1.cpp priv2.cpp
    PUBLIC pub1.cpp pub2.cpp
    INTERFACE iface3.cpp)
portable_target(SOURCES executable INTERFACE iface4.cpp)
portable_target(INCLUDE_DIRS executable ./)

portable_target(ADD_LIBRARY mylib)
portable_target(SOURCES mylib src.cpp)
portable_target(DEFINITIONS mylib "-DDEFIN1=1 -DDEFIN2=0")

# portable_target(LIBRARY mylib1 STATIC)
# portable_target(LINK STATIC mylib SHARED mylib)
