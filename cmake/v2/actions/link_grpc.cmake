################################################################################
# Copyright (c) 2021,2022 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2022.06.15 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/compile_options.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/include_directories.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/link_libraries.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sources.cmake)

find_program(PROTOC_BIN protoc)

#
# Usage:
#
# portable_target_link_grpc (target
#   [DLL_EXPORT_DECL string]
#   [DLL_EXPORT_HEADER path]
#   [PROTOC_BIN path]
#   [CPP_PLUGIN path]
#   PROTO_PATH dir                # Base directory for sources
#   OUTPUT_DIR dir                # Base output directory
#   SOURCES sources)              # Source file names
#
function (portable_target_link_grpc TARGET)
    set(boolparm PROTOBUF_ONLY)
    set(singleparm
        DLL_EXPORT_DECL
        DLL_EXPORT_HEADER
        PROTOC_BIN
        CPP_PLUGIN
        PROTO_PATH
        OUTPUT_DIR)
    set(multiparm SOURCES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SOURCES)
        _portable_target_error(${TARGET} "No protocol sources specified")
    endif()

    if (NOT _arg_PROTOC_BIN)
        if (PROTOC_BIN)
            set(_arg_PROTOC_BIN ${PROTOC_BIN})
        else()
            _portable_target_error(${TARGET} "`protoc` program not found and must be specified explicitly by `PROTOC_BIN` option")
        endif()
    endif()

    if (EXISTS ${_arg_PROTOC_BIN})
        _portable_target_status(${TARGET} "`protoc` location: ${_arg_PROTOC_BIN}")
    else()
        _portable_target_error(${TARGET} "`protoc` program not found at: ${_arg_PROTOC_BIN}")
    endif()

    if (NOT _arg_PROTOBUF_ONLY)
        if (NOT _arg_CPP_PLUGIN)
            _portable_target_error(${TARGET} "C++ plugin must be specified by `CPP_PLUGIN` option")
        endif()

        if (EXISTS ${_arg_CPP_PLUGIN})
            _portable_target_status(${TARGET} "C++ plugin location: ${_arg_CPP_PLUGIN}")
        else()
            _portable_target_error(${TARGET} "C++ plugin not found at: ${_arg_CPP_PLUGIN}")
        endif()
    endif()

    if (NOT _arg_PROTO_PATH)
        _portable_target_error(${TARGET} "Proto files base directory must be specified by `PROTO_PATH` option")
    endif()

    if (NOT EXISTS ${_arg_PROTO_PATH})
        _portable_target_error(${TARGET} "Bad proto path: ${_arg_PROTO_PATH}")
    endif()

    _portable_target_trace(${TARGET} "Proto files base directory: [${_arg_PROTO_PATH}]")

    if (NOT _arg_OUTPUT_DIR)
        #set(_arg_OUTPUT_DIR "$<TARGET_FILE_DIR:${TARGET}>")
        _portable_target_error(${TARGET} "Output directory must be specified by `OUTPUT_DIR` option")
    endif()

    _portable_target_trace(${TARGET} "Output directory: [${_arg_OUTPUT_DIR}]")

    foreach (_src ${_arg_SOURCES})
        get_filename_component(_basename ${_src} NAME_WE)
#         get_filename_component(_dir ${_src} DIRECTORY)
#         get_filename_component(_filename ${_src} NAME)

        if (EXISTS ${_src})
            list(APPEND _proto_SOURCES "${_src}")
        elseif(EXISTS "${_arg_PROTO_PATH}/${_src}")
            list(APPEND _proto_SOURCES "${_arg_PROTO_PATH}/${_src}")
        else()
            _portable_target_error(${TARGET} "Proto file not found: ${_src}")
        endif()

        if (NOT _arg_PROTOBUF_ONLY)
            list(APPEND _grpc_CPP_SOURCES "${_arg_OUTPUT_DIR}/${_basename}.grpc.pb.cc")
            list(APPEND _grpc_CPP_SOURCES "${_arg_OUTPUT_DIR}/${_basename}.grpc.pb.h")
        endif()

        list(APPEND _protobuf_CPP_SOURCES "${_arg_OUTPUT_DIR}/${_basename}.pb.cc")
        list(APPEND _protobuf_CPP_SOURCES "${_arg_OUTPUT_DIR}/${_basename}.pb.h")
    endforeach()

    ################################################################################
    # Generate gRPC-specific source codes
    ################################################################################
    if (NOT _arg_PROTOBUF_ONLY)
        list(APPEND _protoc_OPTS "--grpc_out=\"${_arg_OUTPUT_DIR}\"")
        list(APPEND _protoc_OPTS "--plugin=protoc-gen-grpc=\"${_arg_CPP_PLUGIN}\"")
        list(APPEND _protoc_OPTS "--proto_path=\"${_arg_PROTO_PATH}\"")

        add_custom_command(
            COMMAND ${_arg_PROTOC_BIN} ${_protoc_OPTS} ${_arg_SOURCES}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            OUTPUT ${_grpc_CPP_SOURCES}
            DEPENDS ${_proto_SOURCES})

        portable_target_sources(${TARGET} ${_grpc_CPP_SOURCES})
    endif()

    ############################################################################
    # Generate Protobuf-specific source codes
    ############################################################################
    list(APPEND _protoc_OPTS "--proto_path=\"${_arg_PROTO_PATH}\"")

    if(_arg_DLL_EXPORT_DECL)
        list(APPEND _protoc_OPTS "--cpp_out=\"dllexport_decl=${_arg_DLL_EXPORT_DECL}:${_arg_OUTPUT_DIR}\"")
    else()
        list(APPEND _protoc_OPTS "--cpp_out=\"${_arg_OUTPUT_DIR}\"")
    endif()

    add_custom_command(
        COMMAND ${_arg_PROTOC_BIN} ${_protoc_OPTS} ${_arg_SOURCES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT ${_protobuf_CPP_SOURCES}
        DEPENDS ${_proto_SOURCES})

    portable_target_sources(${TARGET} ${_protobuf_CPP_SOURCES})
    portable_target_include_directories(${TARGET} ${_arg_OUTPUT_DIR} ${_arg_OUTPUT_DIR}/..)

    if (_arg_DLL_EXPORT_HEADER)
        if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            portable_target_compile_options(${TARGET} "/FI\"${_arg_DLL_EXPORT_HEADER}\"")
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
                OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            portable_target_compile_options(${TARGET} -include;${_arg_DLL_EXPORT_HEADER})
        endif()
    endif()

    if (NOT _arg_PROTOBUF_ONLY)
        # Note: gRPC libraries with dependences:
        #       grpc++_reflection grpc gpr address_sorting cares protobuf z
        portable_target_link_libraries(${TARGET} grpc++)
    else()
        portable_target_link_libraries(${TARGET} protobuf)
    endif()
endfunction(portable_target_link_grpc)
