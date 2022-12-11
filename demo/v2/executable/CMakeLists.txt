################################################################################
# Copyright (c) 2020 Vladislav Trifochkin
#
# Changelog:
#      2021.09.07 Initial version.
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

# Enable output of trace info
portable_target(SET ENABLE_TRACE ON)
portable_target(SET AGGRESSIVE_COMPILER_CHECK ON)
portable_target(GET UNDEFINED_VAR _undefined_var "UNDEFINED VALUE")

#
# Workaround for
# set_target_properties(${target_name}
#         PROPERTIES
#         ARCHIVE_OUTPUT_DIRECTORY "${_output_dir}"
#         LIBRARY_OUTPUT_DIRECTORY "${_output_dir}"
#         RUNTIME_OUTPUT_DIRECTORY "${_output_dir}")
if (MSVC)
    set(_output_dir "${CMAKE_BINARY_DIR}")
else()
    set(_output_dir "${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}")
endif()

portable_target(SET ARCHIVE_OUTPUT_DIRECTORY ${_output_dir})
portable_target(SET LIBRARY_OUTPUT_DIRECTORY ${_output_dir})
portable_target(SET RUNTIME_OUTPUT_DIRECTORY ${_output_dir})
portable_target(SET OUTPUT_DIRECTORY ${_output_dir})

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

portable_target(ADD_SHARED mylib)
portable_target(SOURCES mylib src.cpp)
portable_target(DEFINITIONS mylib "-DDEFIN1=1 -DDEFIN2=0")
portable_target(COMPILE_OPTIONS mylib AGGRESSIVE_CHECK ON)

# portable_target(LIBRARY mylib1 STATIC)
portable_target(LINK executable mylib)

#portable_target(LINK_QT5_COMPONENTS executable REQUIRED
    #Core
    #INTERFACE Xml
    #PUBLIC Network
    #PRIVATE Sql
    #AUTOUIC)
