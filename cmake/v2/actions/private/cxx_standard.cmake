################################################################################
# Copyright (c) 2024 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2024.10.07 Initial version.
###############################################################################
# https://learn.microsoft.com/en-us/cpp/build/reference/zc-cplusplus?view=msvc-170

function (_portable_target_cxx_standardize TARGET)
    get_target_property(_target_type ${TARGET} TYPE)

    if (NOT CMAKE_CXX_STANDARD)
        set(_cxx 11)
    else ()
        set(_cxx ${CMAKE_CXX_STANDARD})
    endif()

    # Unset property CXX_STANDARD
    # INTERFACE_LIBRARY targets may only have whitelisted properties.  The
    # property "CXX_STANDARD" is not allowed.
    if (NOT _target_type STREQUAL "INTERFACE_LIBRARY")
        set_property(TARGET ${TARGET} PROPERTY CXX_STANDARD)
    endif()

    # There is no /std:c++11 option for MSVC and CMake set standard to C++98.
    # See https://cmake.org/cmake/help/latest/prop_tgt/CXX_STANDARD.html:
    # ... If the value requested does not result in a compile flag being added 
    # for the compiler in use, a previous standard flag will be added instead.

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        set (_cxx_standard "/Zc:__cplusplus")

        if (CMAKE_CXX_STANDARD GREATER_EQUAL 20)
            set(_cxx_standard ${_cxx_standard} "/std:c++latest")
        elseif (CMAKE_CXX_STANDARD GREATER_EQUAL 17)
            set(_cxx_standard ${_cxx_standard} "/std:c++17")
        elseif (CMAKE_CXX_STANDARD GREATER_EQUAL 14)
            set(_cxx_standard ${_cxx_standard} "/std:c++14")
        elseif (CMAKE_CXX_STANDARD GREATER_EQUAL 11)
            # Comment see above
            set(_cxx_standard ${_cxx_standard} "/std:c++14")
        else ()
            # 199711L
            set(_cxx_standard "/Zc:__cplusplus-")
        endif()

        if (_target_type STREQUAL "INTERFACE_LIBRARY")
            target_compile_options(${TARGET} INTERFACE ${cxx_standard})
        else ()
            target_compile_options(${TARGET} PRIVATE ${cxx_standard})
        endif()
    else()
        if (_target_type STREQUAL "INTERFACE_LIBRARY")
            target_compile_options(${TARGET} INTERFACE "-std=c++${_cxx}")
        else ()
            set_property(TARGET ${TARGET} PROPERTY CXX_STANDARD ${_cxx})
        endif()
    endif()
endfunction(_portable_target_cxx_standardize)