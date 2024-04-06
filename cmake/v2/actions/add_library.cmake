################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.09.16 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/category.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/compile_options.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

#
# Usage:
#
# portable_target_add_library(<target>
#       [CATEGORIES category...]
#       [SHARED | STATIC | INTERFACE]
#       [NO_UNICODE]
#       [NO_BIGOBJ]
#       [NO_NOMINMAX]
#       [ALIAS alias]
#       [EXPORTS export_def]
#       [OUTPUT dir]
#       [COMPONENT name])
#       # [BIND_STATIC static_target [STATIC_ALIAS static_alias] [STATIC_EXPORTS export_def]]
#
# NO_UNICODE (MSVC specific option)
#       Disable UNICODE support.
#
# NO_BIGOBJ (MSVC specific option)
#       Disable increase the number of sections that an object file can contain.
#       By default `/bigobj` option is set for compiler.
#       See [https://docs.microsoft.com/en-us/cpp/build/reference
#           /bigobj-increase-number-of-sections-in-dot-obj-file
#           ?redirectedfrom=MSDN&view=msvc-160]
#
# NO_NOMINMAX
#       Disable avoid of min/max macros for MSVC.
#
# BIND_STATIC static_target
#       Bind static library with shared (use configuration from parent target).
#
# STATIC_ALIAS
#       Alias for bound static library.
#
# STATIC_EXPORTS
#
# EXPORTS export_def
#       For SHARED only on MSVC platform.
#
# COMPONENT name
#       An installation component name with which the install rule is
#       associated.
#
# If neither SHARED nor STATIC and no INTERFACE is specified, both are set to ON.
#
# NOTE Since cmake v3.11 source files is optional for add_executable/add_library
#

function (portable_target_add_library TARGET)
    _portable_target_set_properties_defaults()

    set(boolparm SHARED STATIC INTERFACE NO_UNICODE NO_BIGOBJ NO_NOMINMAX)
    set(singleparm ALIAS OUTPUT COMPONENT STATIC_ALIAS EXPORTS STATIC_EXPORTS)
    set(multiparm CATEGORIES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SHARED AND NOT _arg_STATIC AND NOT _arg_INTERFACE)
        if (BUILD_SHARED_LIBS)
            _portable_target_warn(${TARGET} "Library type not specified, build SHARED")
            set(_arg_SHARED ON)
        else ()
            if (CMAKE_SYSTEM_NAME STREQUAL "Android")
                set(_arg_SHARED ON)
            else()
                if (NOT MSVC)
                    set(_arg_SHARED ON)
                    set(_arg_STATIC ON)
                else ()
                    _portable_target_error(${TARGET} "Library type must be specified")
                endif()
            endif()
        endif()
    endif()

    # Check  mutually exclusive arguments
    set(_exclusive_counter 0)
    set(_all_types _arg_SHARED;_arg_STATIC;_arg_INTERFACE)

    foreach(_opt IN LISTS _all_types)
        if (${_opt})
            math(EXPR _exclusive_counter "${_exclusive_counter} + 1")
        endif()
    endforeach()

    if (NOT ${_exclusive_counter})
        _portable_target_error(${TARGET} "Library type must be specified")
    elseif(${_exclusive_counter} GREATER 1)
        _portable_target_error(${TARGET} "More than one library type specified")
    endif()

    if (_arg_SHARED)
        add_library(${TARGET} SHARED)
    elseif (_arg_STATIC)
        add_library(${TARGET} STATIC)
    elseif (_arg_INTERFACE)
        add_library(${TARGET} INTERFACE)
    else ()
        _portable_target_error(${TARGET} "Oops! Unexpected variant")
    endif ()

    if (_arg_ALIAS)
        add_library(${_arg_ALIAS} ALIAS ${TARGET})
    endif()

#    if (_arg_BIND_STATIC AND (_arg_STATIC OR _arg_INTERFACE))
#        _portable_target_error(${TARGET} "Only SHARED library accepts BIND_STATIC")
#    endif()

    # Bind static library
#    if (_arg_BIND_STATIC)
#        add_library(${_arg_BIND_STATIC} STATIC)
#
#        if (_arg_STATIC_ALIAS)
#            add_library(${_arg_STATIC_ALIAS} ALIAS ${_arg_BIND_STATIC})
#        endif()
#
#        set_target_properties(${TARGET} PROPERTIES BIND_STATIC ${_arg_BIND_STATIC})
#    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_UNICODE)
        target_compile_definitions(${TARGET} INTERFACE _UNICODE UNICODE)
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_NOMINMAX)
        target_compile_definitions(${TARGET} INTERFACE NOMINMAX)
    endif()

    if (NOT _arg_INTERFACE)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND NOT _arg_NO_BIGOBJ)
            target_compile_options(${TARGET} PRIVATE "/bigobj")
            #if (_arg_BIND_STATIC)
            #    target_compile_options(${_arg_BIND_STATIC} PRIVATE "/bigobj")
            #endif()
        endif()

        # XXX_OUTPUT_DIRECTORY properties not applicable for INTERFACE library.
        if (_arg_OUTPUT AND _arg_STATIC)
            _portable_target_trace(${TARGET} "Archive output directory: [${_arg_OUTPUT}]")
            set_target_properties(${TARGET} PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
                ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}")
        endif()

        #if (_arg_OUTPUT AND _arg_BIND_STATIC)
        #    _portable_target_trace(${_arg_BIND_STATIC} "Archive output directory: [${_arg_OUTPUT}]")
        #    set_target_properties(${_arg_BIND_STATIC} PROPERTIES
        #        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
        #        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}")
        #endif()

        if (_arg_OUTPUT AND _arg_SHARED)
            _portable_target_trace(${TARGET} "Library output directory: [${_arg_OUTPUT}]")
            set_target_properties(${TARGET} PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
                LIBRARY_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}"
                ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${_arg_OUTPUT}"
                ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${_arg_OUTPUT}")
        endif()
    endif()

    if (CMAKE_SYSTEM_NAME STREQUAL "Android")
        if (_arg_INTERFACE)
            target_compile_definitions(${TARGET} INTERFACE "ANDROID=1")
        else()
            target_compile_definitions(${TARGET} PRIVATE "ANDROID=1")
        endif()

        #if (_arg_BIND_STATIC)
        #    target_compile_definitions(${_arg_BIND_STATIC} PRIVATE "ANDROID=1")
        #endif()
    endif()

    if (_arg_EXPORTS AND MSVC)
        if (_arg_SHARED)
            _portable_target_trace(${TARGET} "Exports: [${_arg_EXPORTS}]")
            target_compile_definitions(${TARGET} PRIVATE ${_arg_EXPORTS})
        elseif (_arg_STATIC)
            _portable_target_trace(${TARGET} "Exports: [${_arg_EXPORTS}]")
            target_compile_definitions(${TARGET} PUBLIC ${_arg_EXPORTS})
        endif()

        #if(_arg_BIND_STATIC)
        #    if (_arg_STATIC_EXPORTS)
        #        _portable_target_trace(${_arg_BIND_STATIC} "Exports: [${_arg_STATIC_EXPORTS}]")
        #        target_compile_definitions(${_arg_BIND_STATIC} PUBLIC ${_arg_STATIC_EXPORTS})
        #    endif()
        #endif()
    endif()

    # For link custom shared libraries with static library
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        if (_arg_STATIC)
            target_compile_options(${TARGET} PRIVATE "-fPIC")
        endif()

        #if (_arg_BIND_STATIC)
        #    target_compile_options(${_arg_BIND_STATIC} PRIVATE "-fPIC")
        #endif()
    endif()

    if (_arg_CATEGORIES)
        portable_target_set_category(${TARGET} ${_arg_CATEGORIES})
    endif()

    if (_arg_COMPONENT)
        set_target_properties(${TARGET}
            PROPERTIES
            COMPONENT "${_arg_COMPONENT}")
    endif(_arg_COMPONENT)
endfunction(portable_target_add_library)
