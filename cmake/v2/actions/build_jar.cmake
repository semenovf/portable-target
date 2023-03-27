################################################################################
# Copyright (c) 2021-2023 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2023.03.20 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
#include(${CMAKE_CURRENT_LIST_DIR}/../android/AndroidExtraOpenSSL.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

# Usage:
#
# portable_target_build_jar(<target>
#       SOURCES source...
#       [JAVA_HOME dir]
#       [JAVA_MIN_VERSION version]
#       [CLASSPATH classpath]
#       [COMPILE_FLAGS flags...]
#       [LINK_ANDROID])
#
# SOURCES
#       Java source files.
#
# JAVA_HOME
#       Java home directory. Default is $ENV{JAVA_HOME}. Failure if not set.
#
# JAVA_MIN_VERSION version
#       Minimum required Java version. Default is 1.8.
#
# CLASSPATH classpath
#       Class path.
#
# LINK_ANDROID
#       Automatic find Android JAR base on ANDROID_SDK and ANDROID_PLATFORM
#       variables. Path to android-xx.jar will be added to classpath.
#
function (portable_target_build_jar TARGET)
    set(boolparm LINK_ANDROID)
    set(singleparm JAVA_HOME JAVA_MIN_VERSION CLASSPATH)
    set(multiparm SOURCES COMPILE_FLAGS)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SOURCES)
        _portable_target_error(${TARGET} "SOURCES must be specified")
    endif()

    if (NOT _arg_JAVA_MIN_VERSION)
        set(_arg_JAVA_MIN_VERSION "1.8")
    endif()

    if (NOT _arg_JAVA_HOME)
        _mandatory_var_env(_arg_JAVA_HOME JAVA_HOME "Java home directory")
    endif()

    set(ENV{JAVA_HOME} ${_arg_JAVA_HOME})

    _portable_target_status(${TARGET} "JAVA_HOME: $ENV{JAVA_HOME}")

    if (_arg_LINK_ANDROID)
        _mandatory_var_env(_android_jar_dir ANDROID_SDK "Android SDK directory")

        set(_android_jar_dir "${_android_jar_dir}/platforms")

        _optional_var_env(_android_platform ANDROID_PLATFORM)

        if (NOT EXISTS ${_android_jar_dir})
            _portable_target_error(${TARGET} "Android SDK platforms directory not found")
        endif()

        if (_android_platform)
            if (EXISTS ${_android_jar_dir}/${_android_platform}
                    AND IS_DIRECTORY ${_android_jar_dir}/${_android_platform})
                set(_android_jar ${_android_jar_dir}/${_android_platform}/android.jar)
            endif()
        endif()

        if (NOT _android_jar)
            foreach(_sdk_version 35;34;33;32;31;30;29;28;27;26;25;24;23;22;21)
                if (EXISTS ${_android_jar_dir}/android-${_sdk_version}/android.jar)
                    set(_android_jar ${_android_jar_dir}/android-${_sdk_version}/android.jar)
                    break()
                endif()
            endforeach()
        endif()

        if (NOT _android_jar)
            _portable_target_error(${TARGET} "Android JAR not found, specify it manually using CLASSPATH argument")
        endif()

        _portable_target_status(${TARGET} "Android JAR found: ${_android_jar}")
    endif()

    find_package(Java ${_arg_JAVA_MIN_VERSION} COMPONENTS Development REQUIRED)

    if (NOT DEFINED Java_Development_FOUND)
        _portable_target_error(${PROJECT_NAME} "No Java found, may be JAVA_HOME environment variable has invalid value")
    endif()

    include(UseJava)

    if (_arg_COMPILE_FLAGS)
        set(CMAKE_JAVA_COMPILE_FLAGS ${_arg_COMPILE_FLAGS})
    endif()

    if (_arg_CLASSPATH)
        set(CMAKE_JAVA_INCLUDE_PATH "${_arg_CLASSPATH}")
    endif()

    if (_android_jar)
        if ("${CMAKE_JAVA_INCLUDE_PATH}" STREQUAL "")
            set(CMAKE_JAVA_INCLUDE_PATH "${_android_jar}")
        else()
            set(CMAKE_JAVA_INCLUDE_PATH "${_android_jar}:${CMAKE_JAVA_INCLUDE_PATH}")
        endif()
    endif()

    add_jar(${TARGET} SOURCES ${_arg_SOURCES})

    get_target_property(_jar_file ${TARGET} JAR_FILE)
    get_target_property(_class_dir ${TARGET} CLASSDIR)

    _portable_target_trace(${PROJECT_NAME} "JAR file path: ${_jar_file}")
    _portable_target_trace(${PROJECT_NAME} "Class compiled to: ${_class_dir}")
endfunction(portable_target_build_jar)

