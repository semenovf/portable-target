################################################################################
# Copyright (c) 2021-2023 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2022.03.24 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../android/AndroidExtraOpenSSL.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)

set(QTDEPLOY_JSON_IN_FILE_DIR ${CMAKE_CURRENT_LIST_DIR}/../android)
set(QTDEPLOY_JSON_IN_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/qtdeploy.json.in)
set(BUILD_GRADLE_IN_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/build.gradle.in)
set(GRADLE_WRAPPER_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/gradle-wrapper.properties)

find_program(ADB_BIN adb)

#
# Checked environment
#   [OK]    Qt 5.13.2 + NDK 22.0.7026061
#   [FALSE] Qt 5.13.2 + NDK 24.0.8215888

# see https://developer.android.com/guide/topics/manifest/manifest-element
#
# Usage:
#
# portable_target_build_apk(<target>
#       [ANDROIDDEPLOYQT_EXECUTABLE path]
#       [PACKAGE_NAME package-name]
#       [APP_NAME app-name]
#       [APK_BASENAME template]
#       [STL_PREFIX prefix]
#       [QTDEPLOY_JSON_IN_FILE path]
#       [VERSION_MAJOR major-version]
#       [VERSION_MINOR minor-version]
#       [VERSION_PATCH patch-version]
#       [SCREEN_ORIENTATION orientation]
#       [CONFIG_CHANGES config-changes ]
#       [PERMISSIONS permissions]
#       [DEPENDS dependencies]
#       [PLUGINS plugins]
#       [SSL_ROOT dir]
#       [INSTALL ON|OFF]
#       [VERBOSE ON|OFF])
#
# USE_ANDROIDDEPLOYQT
#       If set and ANDROIDDEPLOYQT_EXECUTABLE is not
#
# ANDROIDDEPLOYQT_EXECUTABLE path
#       Path to `androiddeployqt` executable. Set according to to default Qt5
#       location if not specified.
#
# PACKAGE_NAME <package-name>
#       Android package name
#
# APP_NAME app-name
#       Android application name (label). Default is ${TARGET}.
#
# APK_BASENAME template
#       Template for basename for resulting APK file path.
#       Example: Hello_@ANDROID_APP_VERSION@_@ANDROID_ABI@
#
# STL_PREFIX prefix
#       Prefix to generate path to STL library
#
# VERSION_MAJOR major-version
#       Android application major version number. Default is 1.
#
# VERSION_MINOR minor-version
#       Android application minor version number. Default is 0.
#
# SCREEN_ORIENTATION orientation
#       `orientation` is one of: "unspecified", "behind", "landscape"
#               , "portrait", "reverseLandscape", "reversePortrait"
#               , "sensorLandscape", "sensorPortrait", "userLandscape"
#               , "userPortrait", "sensor", "fullSensor", "nosensor"
#               , "user", "fullUser", "locked".
#       Default is "unspecified".
#       see https://developer.android.com/guide/topics/manifest/activity-element#screen
#
# CONFIG_CHANGES config-changes
#       `config-changes` is one of: "mcc", "mnc", "locale", "touchscreen"
#               , "keyboard" , "keyboardHidden", "navigation", "screenLayout"
#               , "fontScale" , "uiMode", "orientation", "density", "screenSize"
#               , "smallestScreenSize".
#       Default is empty string.
#       see https://developer.android.com/guide/topics/manifest/activity-element#config
#
# DEPENDS dependencies
#
# PLUGINS plugins
#
# PERMISSIONS permissions
#       Set Android application permissions. Default is WAKE_LOCK.
#
# SSL_ROOT dir
#       SSL libraries root directory (not implemented yet).
#
# INSTALL ON|OFF
#       Install Android APK on device. Default is OFF. Can be set by
#       PORTABLE_TARGET_ANDROID_INSTALL environment variable.
#
# VERBOSE ON|OFF
#       Output verbocity. Default is OFF.
#

function (portable_target_build_apk TARGET)
    set(boolparm)

    set(singleparm
        ANDROIDDEPLOYQT_EXECUTABLE
        APP_NAME
        APK_BASENAME
        STL_PREFIX
        CONFIG_CHANGES
        INSTALL
        KEYSTORE_PASSWORD
        PACKAGE_NAME
        QTDEPLOY_JSON_IN_FILE
        SCREEN_ORIENTATION
        SSL_ROOT
        VERBOSE
        VERSION_MAJOR
        VERSION_MINOR
        VERSION_PATCH)

    set(multiparm
        DEPENDS
        PLUGINS
        KEYSTORE
        PERMISSIONS)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT ANDROID_MIN_SDK_VERSION)
        _portable_target_fatal(${TARGET} "`ANDROID_MIN_SDK_VERSION` not set.")
    endif()

    if (NOT ANDROID_TARGET_SDK_VERSION)
        _portable_target_fatal(${TARGET} "`ANDROID_TARGET_SDK_VERSION` not set.")
    endif()

    if (NOT ANDROID_COMPILE_SDK_VERSION)
        set(ANDROID_COMPILE_SDK_VERSION ${ANDROID_TARGET_SDK_VERSION})
    endif()

    set(ANDROID_APP_PATH "$<TARGET_FILE:${TARGET}>")
    set(ANDROID_APP_BASENAME "$<TARGET_FILE_BASE_NAME:${TARGET}>")

    if (_arg_APP_NAME OR _arg_VERSION_MAJOR OR _arg_VERSION_MINOR)
        if (NOT _arg_PACKAGE_NAME)
            _portable_target_fatal(${TARGET} "PACKAGE_NAME must be specified")
        endif()
    endif()

    if (NOT _arg_APP_NAME)
        set(_arg_APP_NAME ${TARGET})
    endif()

    if (NOT _arg_VERSION_MAJOR)
        set(_arg_VERSION_MAJOR 1)
    endif()

    if (NOT _arg_VERSION_MINOR)
        set(_arg_VERSION_MINOR 0)
    endif()

    if (NOT _arg_VERSION_PATCH)
        set(_arg_VERSION_PATCH 0)
    endif()

    if (NOT _arg_SCREEN_ORIENTATION)
        set(_arg_SCREEN_ORIENTATION "unspecified")
    endif()

    if (NOT _arg_CONFIG_CHANGES)
        set(_arg_CONFIG_CHANGES "")
    endif()

    if (NOT _arg_QTDEPLOY_JSON_IN_FILE)
        set(_arg_QTDEPLOY_JSON_IN_FILE ${QTDEPLOY_JSON_IN_FILE})
    endif()

    portable_target_get_property(Qt5_DIR _qt5_dir)
    portable_target_get_property(Qt5_VERSION _qt5_version)

    # Check if QTDEPLOY_JSON_IN_FILE is path or filename
    get_filename_component(_json_in_file ${_arg_QTDEPLOY_JSON_IN_FILE} NAME)

    if (${_json_in_file} STREQUAL ${_arg_QTDEPLOY_JSON_IN_FILE})
        set(_arg_QTDEPLOY_JSON_IN_FILE "${QTDEPLOY_JSON_IN_FILE_DIR}/${_json_in_file}")
    endif()

    if (_qt5_dir)
        if (NOT _arg_ANDROIDDEPLOYQT_EXECUTABLE)
            get_filename_component(_arg_ANDROIDDEPLOYQT_EXECUTABLE "${_qt5_dir}/../../../bin/androiddeployqt" ABSOLUTE)
        endif()

        if (NOT EXISTS ${_arg_ANDROIDDEPLOYQT_EXECUTABLE})
            _portable_target_fatal(${TARGET} "androiddeployqt not found at: ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
        endif()

        # Used by `qtdeploy.json.in`
        get_filename_component(ANDROID_QT_ROOT "${_arg_ANDROIDDEPLOYQT_EXECUTABLE}/../.." ABSOLUTE)
    endif()


    if (NOT _arg_STL_PREFIX)
        if (${ANDROID_STL} MATCHES "^[ ]*c\\+\\+_shared[ ]*$")
            set(_arg_STL_PREFIX "llvm-libc++")
        else()
            _portable_target_fatal(${TARGET} "Unable to deduce STL_PREFIX, STL_PREFIX must be specified")
        endif()
    endif()

    # Used by `qtdeploy.json.in`
    if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
        set(ANDROID_STL_DIR "${ANDROID_NDK}/sources/cxx-stl/${_arg_STL_PREFIX}/libs")

        # if (NOT EXISTS ${ANDROID_STL_DIR})
        #     # FIXME------------------------------------------------------------------v
        #     set(ANDROID_STL_DIR "${ANDROID_TOOLCHAIN_ROOT}/sysroot/usr/lib/aarch64-linux-android")

            if (NOT EXISTS ${ANDROID_STL_DIR})
                _portable_target_fatal(${TARGET} "Android STL dir not found: ${ANDROID_STL_DIR}")
            endif()
        # endif()
    else()
        set(ANDROID_STL_PATH "${ANDROID_NDK}/sources/cxx-stl/${_arg_STL_PREFIX}/libs/${ANDROID_ABI}/lib${ANDROID_STL}.so")

        if (NOT EXISTS ${ANDROID_STL_PATH})
            _portable_target_fatal(${TARGET} "Android STL path not found: ${ANDROID_STL_PATH}")
        endif()
    endif()

    if (NOT _arg_INSTALL)
        _optional_var_env(_arg_INSTALL
            ANDROID_INSTALL
            "Install APK"
            OFF)
    endif()

    if (NOT _arg_PERMISSIONS)
        set(_arg_PERMISSIONS WAKE_LOCK)
        _portable_target_warn(${TARGET} "Android permissions are not defined, only 'WAKE_LOCK' set by default")
    endif()

    # FIXME
    if (_arg_SSL_ROOT)
#         _portable_target_status(${TARGET} "Android SSL extra libraries root: ${_arg_SSL_ROOT}")
#         _portable_android_openssl(
#             ${_arg_SSL_ROOT}
#             ${Qt5Core_VERSION}
#             ${ANDROID_ABI}
#             _android_ssl_extra_libs)
#         _portable_target_status("Android SSL extra libraries: ${_android_ssl_extra_libs}")
    endif()


    # Used by `qtdeploy.json.in` and `AndroidManifest.xml.in`
    set(ANDROID_PACKAGE_NAME ${_arg_PACKAGE_NAME})
    set(ANDROID_APP_NAME ${_arg_APP_NAME})

    # Used by `AndroidManifest.xml.in`
    set(ANDROID_APP_VERSION "${_arg_VERSION_MAJOR}.${_arg_VERSION_MINOR}.${_arg_VERSION_PATCH}")
    math(EXPR ANDROID_APP_VERSION_CODE "${_arg_VERSION_MAJOR} * 1000000 + ${_arg_VERSION_MINOR} * 1000 + ${_arg_VERSION_PATCH}")

    # Whether your application's processes should be created with a large Dalvik
    # heap (see https://developer.android.com/guide/topics/manifest/application-element#largeHeap for details).
    set(ANDROID_APP_LARGE_HEAP "true")
    set(ANDROID_APP_SCREEN_ORIENTATION "${_arg_SCREEN_ORIENTATION}")
    set(ANDROID_APP_CONFIG_CHANGES "${_arg_CONFIG_CHANGES}")

    if (${CMAKE_BUILD_TYPE} MATCHES "[Dd][Ee][Bb][Uu][Gg]"
            OR ${CMAKE_BUILD_TYPE} MATCHES "[Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo]")
        set(ANDROID_APP_IS_DEBUGGABLE "true")
    else()
        # TODO Check for older versions. It depends on androiddeployqt version
        if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
            if (_arg_KEYSTORE AND _arg_KEYSTORE_PASSWORD)
                set(SIGN_OPTIONS --release --sign ${_arg_KEYSTORE} release --storepass
                    ${_arg_KEYSTORE_PASSWORD} --keypass ${_arg_KEYSTORE_PASSWORD})
                set(ANDROID_APP_IS_DEBUGGABLE "false")
            else()
                set(ANDROID_APP_IS_DEBUGGABLE "true")
            endif()
        else()
            set(ANDROID_APP_IS_DEBUGGABLE "true")
        endif()
    endif()

    # Set the list of dependant libraries
    if (_arg_DEPENDS OR _android_ssl_extra_libs)
        foreach (_lib ${_arg_DEPENDS} ${_android_ssl_extra_libs})
            if (TARGET ${_lib})
                # item is a CMake target, extract the library path
                set(_lib "$<TARGET_FILE:${_lib}>")
            endif()

            if (_extra_libs)
                set(_extra_libs "${_extra_libs},${_lib}")
            else()
                set(_extra_libs "${_lib}")
            endif()
        endforeach()

        #set(ANDROID_APP_EXTRA_LIBS "\"android-extra-libs\": \"${_extra_libs}\",")
        set(ANDROID_APP_EXTRA_LIBS ${_extra_libs})
    endif()

    if (_arg_PLUGINS)
        foreach (_t ${_arg_PLUGINS})
            if (TARGET ${_t})
                # item is a CMake target, extract the library path
                list(APPEND _plugin_dirs "$<TARGET_FILE_DIR:${_t}>")
            else()
                _portable_target_warn(${TARGET} "Plugin must be a target: ${_t}")
                continue()
            endif()

            if (_plugins)
                set(_plugins "${_plugins},${_lib}")
            else ()
                set(_plugins "${_lib}")
            endif()
        endforeach()

        if (_plugin_dirs)
            list(REMOVE_DUPLICATES _plugin_dirs)
        endif()
    endif()

    if (_plugin_dirs)
        list(JOIN _plugin_dirs "," _plugin_dirs)

        set(ANDROID_APP_EXTRA_PLUGINS "\"android-extra-plugins\": \"${_plugin_dirs}\"")
    else ()
        set(ANDROID_APP_EXTRA_PLUGINS "\"--android-extra-plugins\": \"\"")
    endif()

    #---------------------------------------------------------------------------
    # Detect latest Android SDK build-tools revision
    #---------------------------------------------------------------------------
    if (DEFINED ENV{ANDROID_SDK_BUILDTOOLS_REVISION})
        set(ANDROID_SDK_BUILDTOOLS_REVISION "$ENV{ANDROID_SDK_BUILDTOOLS_REVISION}")
    elseif (DEFINED ENV{ANDROID_SDK_BUILDTOOLS_VERSION})
        set(ANDROID_SDK_BUILDTOOLS_REVISION "$ENV{ANDROID_SDK_BUILDTOOLS_VERSION}")
    else()
        set(ANDROID_SDK_BUILDTOOLS_REVISION "0.0.0")
        file(GLOB _all_build_tools_versions RELATIVE ${ANDROID_SDK}/build-tools ${ANDROID_SDK}/build-tools/*)

        foreach(_build_tools_version ${_all_build_tools_versions})
            # Find subfolder with greatest version
            if (${_build_tools_version} VERSION_GREATER ${ANDROID_SDK_BUILDTOOLS_REVISION})
                set(ANDROID_SDK_BUILDTOOLS_REVISION ${_build_tools_version})
            endif()
        endforeach()
    endif()

    # Used by `AndroidManifest.xml.in`
    set(ANDROID_USES_PERMISSION)

    foreach (_permission ${_arg_PERMISSIONS})
        set(ANDROID_USES_PERMISSION "${ANDROID_USES_PERMISSION}\t<uses-permission android:name=\"android.permission.${_permission}\" />\n")
    endforeach()

    # Find suitable AndroidManifest.xml.in
    set(_AndroidManifest_xml_in "AndroidManifest.xml.in")
    set(_android_sources_dir "${CMAKE_CURRENT_SOURCE_DIR}/android-sources")

    foreach(_sdk_version 21;22;23;24;25;26;27;28;29;30;31;32;33)
        if (${_sdk_version} GREATER ${ANDROID_TARGET_SDK_VERSION})
            break()
        endif()

        if (EXISTS "${_android_sources_dir}/AndroidManifest-${_sdk_version}.xml.in")
            set(_AndroidManifest_xml_in "AndroidManifest-${_sdk_version}.xml.in")
        endif()
    endforeach()

    if (NOT EXISTS ${_android_sources_dir}/${_AndroidManifest_xml_in})
        _portable_target_fatal(${TARGET} "${_AndroidManifest_xml_in} not found at: ${_android_sources_dir}"
            "\n\tAndroidManifest.xml.in can be copied from portable_target/android directory")
    else()
        _portable_target_status(${TARGET} "${_AndroidManifest_xml_in} found at: ${_android_sources_dir}")
    endif()

    # Create a subdirectory for the extra package sources
    # Used by `qtdeploy.json.in`
    set(ANDROID_APP_PACKAGE_SOURCE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/android-sources")

    # Generate a manifest from the template
    configure_file(${_android_sources_dir}/${_AndroidManifest_xml_in} ${ANDROID_APP_PACKAGE_SOURCE_ROOT}/AndroidManifest.xml @ONLY)

    # Set "useLLVM" parameter in qtdeploy.json to default value 'false'
    set(ANDROID_USE_LLVM "false")

    # Set some toolchain variables used by androiddeployqt;
    # unfortunately, Qt tries to build paths from these variables although these full paths
    # are already available in the toochain file, so we have to parse them
    string(REGEX MATCH "${ANDROID_NDK}/toolchains/(.*)-(.*)/prebuilt/.*" _android_toolchain_parsed ${ANDROID_TOOLCHAIN_ROOT})

    if (_android_toolchain_parsed)
        # Used by `qtdeploy.json.in`
        set(ANDROID_TOOLCHAIN_PREFIX ${CMAKE_MATCH_1})
        set(ANDROID_TOOLCHAIN_VERSION ${CMAKE_MATCH_2})
    else()
        string(REGEX MATCH "${ANDROID_NDK}/toolchains/llvm/prebuilt/.*" _android_toolchain_parsed ${ANDROID_TOOLCHAIN_ROOT})

        if (_android_toolchain_parsed)
            # Used by `qtdeploy.json.in`
            set(ANDROID_TOOLCHAIN_PREFIX llvm)
            set(ANDROID_TOOLCHAIN_VERSION)
            set(ANDROID_USE_LLVM "true")
        else()
            _portable_target_fatal(${TARGET}
                "Failed to parse ANDROID_TOOLCHAIN_ROOT (${ANDROID_TOOLCHAIN_ROOT}) to get toolchain prefix and version")
        endif()
    endif()

    # Create the configuration file that will feed androiddeployqt
    # Replace placeholder variables at generation time
    configure_file(${_arg_QTDEPLOY_JSON_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in @ONLY)

    # Evaluate generator expressions at build time
    file(GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
        INPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in)

    # Create gradle configuration
    configure_file(${BUILD_GRADLE_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/build.gradle.in @ONLY)
    file(GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/android-build/build.gradle
        INPUT ${CMAKE_CURRENT_BINARY_DIR}/build.gradle.in)

    file(COPY ${GRADLE_WRAPPER_FILE} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/android-build/gradle/wrapper)

    # Workaround for `androiddeployqt` bug with `llvm-strip` options.
    # This bug takes places in Qt5.13.2 and older versions, but is already fixed
    # in 5.12.9 and 5.15.0 as mentioned in the bug report:
    # https://bugreports.qt.io/browse/QTBUG-74292.
    # Let's not distinguish the Qt versions for now and apply this workaround
    # for `llvm-strip` program in any cases.
    if (ANDROID_TOOLCHAIN_PREFIX STREQUAL llvm)
        if (CMAKE_STRIP MATCHES "llvm-strip$")
            set(_llvm_strip_original "${CMAKE_STRIP}.original")

            if (NOT EXISTS ${_llvm_strip_original})
                get_filename_component(_llvm_strip_dir ${CMAKE_STRIP} DIRECTORY)
                get_filename_component(_llvm_strip_filename ${CMAKE_STRIP} NAME)

                file(RENAME ${CMAKE_STRIP} ${_llvm_strip_original})
                file(WRITE ${CMAKE_BINARY_DIR}/${_llvm_strip_filename}
                    "#!/usr/bin/env bash\n\n${_llvm_strip_original} \${@//-strip-all/--strip-all}\n")
                file(COPY ${CMAKE_BINARY_DIR}/${_llvm_strip_filename}
                    DESTINATION ${_llvm_strip_dir}
                    FILE_PERMISSIONS OWNER_EXECUTE OWNER_READ OWNER_WRITE)
            endif()
        endif()
    endif()

    # There are two options for `androiddeployqt` related to installation:
    #   --install (will be called sequentially `adb uninstall` and `adb install -r`)
    #   --reinstall (will be called `adb install -r` only).
    # Will use second method.
    if  (_arg_INSTALL)
        #set(INSTALL_OPTIONS --reinstall)
        set(INSTALL_YESNO "YES")
    else()
        set(INSTALL_YESNO "NO")
    endif()

    if (_arg_VERBOSE)
        set(VERBOSE "--verbose")
        set(VERBOSITY_YESNO "YES")
    else()
        set(VERBOSITY_YESNO "NO")
    endif()

    _portable_target_status(${TARGET} "Android Min SDK version: ${ANDROID_MIN_SDK_VERSION}")
    _portable_target_status(${TARGET} "Android Target SDK version: ${ANDROID_TARGET_SDK_VERSION}")
    _portable_target_status(${TARGET} "Android Compile SDK version: ${ANDROID_COMPILE_SDK_VERSION}")
    _portable_target_status(${TARGET} "Android SDK build tools revision: ${ANDROID_SDK_BUILDTOOLS_REVISION}")
    _portable_target_status(${TARGET} "Android Qt root         : ${ANDROID_QT_ROOT}")

    if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
        _portable_target_status(${TARGET} "Android STL dir         : ${ANDROID_STL_DIR}")
    else()
        _portable_target_status(${TARGET} "Android STL path        : ${ANDROID_STL_PATH}")
    endif()

    _portable_target_status(${TARGET} "androiddeployqt path    : ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
    _portable_target_status(${TARGET} "Qt deploy JSON template : ${_arg_QTDEPLOY_JSON_IN_FILE}")
    _portable_target_status(${TARGET} "Target path             : ${ANDROID_APP_PATH}")
    _portable_target_status(${TARGET} "Target basename         : ${ANDROID_APP_BASENAME}")
    _portable_target_status(${TARGET} "Package name            : ${ANDROID_PACKAGE_NAME}")
    _portable_target_status(${TARGET} "Application name        : \"${ANDROID_APP_NAME}\"")
    _portable_target_status(${TARGET} "Application version     : ${ANDROID_APP_VERSION}")
    _portable_target_status(${TARGET} "Application version code: ${ANDROID_APP_VERSION_CODE}")
    _portable_target_status(${TARGET} "Verbosity output        : ${VERBOSITY_YESNO}")
    _portable_target_status(${TARGET} "Install APK             : ${INSTALL_YESNO}")

    #---------------------------------------------------------------------------
    # Create a custom command that will run the androiddeployqt utility
    # to prepare the Android package
    #---------------------------------------------------------------------------
    # TODO A more precise definition is required to get TEMP_APK_PATH

    if (_arg_APK_BASENAME)
        string(CONFIGURE ${_arg_APK_BASENAME} _arg_APK_BASENAME @ONLY)
    else()
        set(_arg_APK_BASENAME "${_arg_APK_BASENAME}_${ANDROID_APP_VERSION}_${ANDROID_ABI}")
    endif()

    if (${ANDROID_APP_IS_DEBUGGABLE} STREQUAL "true")
        set(_temp_apk_path "${CMAKE_CURRENT_BINARY_DIR}/android-build/build/outputs/apk/debug/android-build-debug.apk")
        set(_target_apk_path "${CMAKE_BINARY_DIR}/${_arg_APK_BASENAME}_debug.apk")
    else()
        set(_temp_apk_path "${CMAKE_CURRENT_BINARY_DIR}/android-build/build/outputs/apk/release/android-build-release-signed.apk")
        set(_target_apk_path "${CMAKE_BINARY_DIR}/${_arg_APK_BASENAME}.apk")
    endif()

    set(_output_dir ${CMAKE_CURRENT_BINARY_DIR}/android-build/libs/${ANDROID_ABI})

    if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
        set(_android_app_output_path ${_output_dir}/lib${ANDROID_APP_BASENAME}_${ANDROID_ABI}.so)
    else()
        set(_android_app_output_path ${_output_dir}/lib${ANDROID_APP_BASENAME}.so)
    endif()

    # ANDROID_PLATFORM <- from toolchain cmake
    add_custom_target(
        ${TARGET}_apk
        ALL
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${_output_dir} # it seems that recompiled libraries are not copied if we don't remove them first
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_output_dir}
        COMMAND ${CMAKE_COMMAND} -E copy ${ANDROID_APP_PATH} ${_android_app_output_path}
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${_android_sources_dir}/sources ${ANDROID_APP_PACKAGE_SOURCE_ROOT}
        COMMAND ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}
            ${VERBOSE}
            --output ${CMAKE_CURRENT_BINARY_DIR}/android-build
            --input ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
            --gradle
            --android-platform ${ANDROID_PLATFORM}
            ${SIGN_OPTIONS}
        COMMAND ${CMAKE_COMMAND} -E copy ${_temp_apk_path} ${_target_apk_path})

    if (_arg_INSTALL)
        if (ADB_BIN)
            list(APPEND _adb_install_opts "-r")

            if (${ANDROID_APP_IS_DEBUGGABLE} STREQUAL "true")
                list(APPEND _adb_install_opts "-t")
            endif()

            add_custom_target(
                ${TARGET}_apk_install
                ALL
                COMMAND ${ADB_BIN} install ${_adb_install_opts} ${_target_apk_path})

            add_dependencies(${TARGET}_apk_install ${TARGET}_apk)
        else()
            _portable_target_warn(${TARGET} "`adb` tool not found, install APK manually")
        endif()
    endif()

    if (_arg_DEPENDS)
        add_dependencies(${TARGET}_apk ${_arg_DEPENDS})
    endif()
endfunction(portable_target_build_apk)
