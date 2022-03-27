################################################################################
# Copyright (c) 2021,2022 Vladislav Trifochkin
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

set(QTDEPLOY_JSON_IN_FILE ${CMAKE_CURRENT_LIST_DIR}/../android/qtdeploy.json.in)

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
#       [VERSION_MAJOR app-version]
#       [VERSION_MINOR app-version]
#       [SCREEN_ORIENTATION orientation]
#       [CONFIG_CHANGES config-changes ]
#       [PERMISSIONS permissions]
#       [DEPENDS dependencies]
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
        PACKAGE_NAME
        APP_NAME
        VERSION_MAJOR
        VERSION_MINOR
        SCREEN_ORIENTATION
        CONFIG_CHANGES
        SSL_ROOT
        INSTALL
        VERBOSE
        #KEYSTORE_PASSWORD
    )

    set(multiparm
        PERMISSIONS
        DEPENDS
        #KEYSTORE
    )

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    set(ANDROID_APP_PATH "$<TARGET_FILE:${TARGET}>")

    if (_arg_APP_NAME OR _arg_VERSION_MAJOR OR _arg_VERSION_MINOR)
        if (NOT _arg_PACKAGE_NAME)
            _portable_apk_error(${TARGET} "PACKAGE_NAME must be specified")
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

    if (NOT _arg_SCREEN_ORIENTATION)
        set(_arg_SCREEN_ORIENTATION "unspecified")
    endif()

    if (NOT _arg_CONFIG_CHANGES)
        set(_arg_CONFIG_CHANGES "")
    endif()

    portable_target_get_property(Qt5_DIR _qt5_dir)

    if (_qt5_dir)
        if (NOT _arg_ANDROIDDEPLOYQT_EXECUTABLE)
            get_filename_component(_arg_ANDROIDDEPLOYQT_EXECUTABLE "${_qt5_dir}/../../../bin/androiddeployqt" ABSOLUTE)
        endif()

        if (NOT EXISTS ${_arg_ANDROIDDEPLOYQT_EXECUTABLE})
            _portable_apk_error(${TARGET} "androiddeployqt not found at: ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
        endif()

        # Used by `qtdeploy.json.in`
        get_filename_component(ANDROID_QT_ROOT "${_arg_ANDROIDDEPLOYQT_EXECUTABLE}/../.." ABSOLUTE)
    endif()

    if (NOT _arg_INSTALL)
        _optional_var_env(_arg_INSTALL
            ANDROID_INSTALL
            "Install APK"
            OFF)
    endif()

    if (NOT _arg_PERMISSIONS)
        set(_arg_PERMISSIONS WAKE_LOCK)
        _portable_apk_warn(${TARGET} "Android permissions are not defined, only 'WAKE_LOCK' set by default")
    endif()

    # FIXME
    if (_arg_SSL_ROOT)
#         _portable_apk_status(${TARGET} "Android SSL extra libraries root: ${_arg_SSL_ROOT}")
#         _portable_android_openssl(
#             ${_arg_SSL_ROOT}
#             ${Qt5Core_VERSION}
#             ${ANDROID_ABI}
#             _android_ssl_extra_libs)
#         _portable_apk_status("Android SSL extra libraries: ${_android_ssl_extra_libs}")
    endif()


    # Used by `qtdeploy.json.in` and `AndroidManifest.xml.in`
    set(ANDROID_PACKAGE_NAME ${_arg_PACKAGE_NAME})
    set(ANDROID_APP_NAME ${_arg_APP_NAME})

    # Used by `AndroidManifest.xml.in`
    set(ANDROID_APP_VERSION "${_arg_VERSION_MAJOR}.${_arg_VERSION_MINOR}")
    math(EXPR ANDROID_APP_VERSION_CODE "${_arg_VERSION_MAJOR} * 1000 + ${_arg_VERSION_MINOR}")
    # Whether your application's processes should be created with a large Dalvik
    # heap (see https://developer.android.com/guide/topics/manifest/application-element#largeHeap for details).
    set(ANDROID_APP_LARGE_HEAP "true")
    set(ANDROID_APP_SCREEN_ORIENTATION "${_arg_SCREEN_ORIENTATION}")
    set(ANDROID_APP_CONFIG_CHANGES "${_arg_CONFIG_CHANGES}")

    if (${CMAKE_BUILD_TYPE} MATCHES "[Dd][Ee][Bb][Uu][Gg]"
            OR ${CMAKE_BUILD_TYPE} MATCHES "[Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo]")
        set(ANDROID_APP_IS_DEBUGGABLE "true")
    else()
        set(ANDROID_APP_IS_DEBUGGABLE "false")
        #set(SIGN_OPTIONS --release)
        #set(SIGN_OPTIONS --release --jarsigner --sign /home/wladt/TacticalPad2Cert.keystore --storepass 12345678 --keypass 12345678)
    endif()

    # TODO check if the apk must be signed
#     if(ARG_KEYSTORE)
#         set(SIGN_OPTIONS --release --sign ${ARG_KEYSTORE} --tsa http://timestamp.digicert.com)
#         if(ARG_KEYSTORE_PASSWORD)
#             set(SIGN_OPTIONS ${SIGN_OPTIONS} --storepass ${ARG_KEYSTORE_PASSWORD})
#         endif()
#     endif()

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

    #---------------------------------------------------------------------------
    # Detect latest Android SDK build-tools revision
    #---------------------------------------------------------------------------
    set(ANDROID_SDK_BUILDTOOLS_REVISION "0.0.0")
    file(GLOB _all_build_tools_versions RELATIVE ${ANDROID_SDK}/build-tools ${ANDROID_SDK}/build-tools/*)

    foreach(_build_tools_version ${_all_build_tools_versions})
        # Find subfolder with greatest version
        if (${_build_tools_version} VERSION_GREATER ${ANDROID_SDK_BUILDTOOLS_REVISION})
            set(ANDROID_SDK_BUILDTOOLS_REVISION ${_build_tools_version})
        endif()
    endforeach()

    # Used by `AndroidManifest.xml.in`
    set(ANDROID_USES_PERMISSION)

    foreach (_permission ${_arg_PERMISSIONS})
        set(ANDROID_USES_PERMISSION "${ANDROID_USES_PERMISSION}\t<uses-permission android:name=\"android.permission.${_permission}\" />\n")
    endforeach()

    # Find suitable AndroidManifest.xml.in
    set(_AndroidManifest_xml_in "AndroidManifest.xml.in")

    foreach(_sdk_version 21;22;23;24;25;26;27;28;29;30;31;32)
        if (${_sdk_version} GREATER ${ANDROID_MIN_SDK_VERSION})
            break()
        endif()

        if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest-${_sdk_version}.xml.in")
            set(_AndroidManifest_xml_in "AndroidManifest-${_sdk_version}.xml.in")
        endif()
    endforeach()

    if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${_AndroidManifest_xml_in})
        _portable_apk_error(${TARGET} "${_AndroidManifest_xml_in} not found at: ${CMAKE_CURRENT_SOURCE_DIR}"
            "\n\tAndroidManifest.xml.in can be copied from portable_target/android directory")
    else()
        _portable_apk_status(${TARGET} "${_AndroidManifest_xml_in} found at: ${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    # Create a subdirectory for the extra package sources
    # Used by `qtdeploy.json.in`
    set(ANDROID_APP_PACKAGE_SOURCE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/android-sources")

    # Generate a manifest from the template
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${_AndroidManifest_xml_in} ${ANDROID_APP_PACKAGE_SOURCE_ROOT}/AndroidManifest.xml @ONLY)

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
            _portable_apk_error(${TARGET}
                "Failed to parse ANDROID_TOOLCHAIN_ROOT (${ANDROID_TOOLCHAIN_ROOT}) to get toolchain prefix and version")
        endif()
    endif()

    # Create the configuration file that will feed androiddeployqt
    # NOTE ANDROID_NDK_HOST_SYSTEM_NAME not set yet
    # configure_file(${QTDEPLOY_JSON_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json @ONLY)

    # Create the configuration file that will feed androiddeployqt
    # Replace placeholder variables at generation time
    configure_file(${QTDEPLOY_JSON_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in @ONLY)
    # Evaluate generator expressions at build time
    file(GENERATE
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
        INPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in)

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
        set(INSTALL_OPTIONS --reinstall)
    endif()

    if (_arg_VERBOSE)
        set(VERBOSE "--verbose")
        set(VERBOSITY "YES")
    else()
        set(VERBOSITY "NO")
    endif()

    set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/android-build/libs/${ANDROID_ABI})
#     file(MAKE_DIRECTORY ${OUTPUT_DIR})

    _portable_apk_status(${TARGET} "Android Min SDK version: ${ANDROID_MIN_SDK_VERSION}")
    _portable_apk_status(${TARGET} "Android Target SDK version: ${ANDROID_TARGET_SDK_VERSION}")
    _portable_apk_status(${TARGET} "Android SDK build tools revision: ${ANDROID_SDK_BUILDTOOLS_REVISION}")
    _portable_apk_status(${TARGET} "Android Qt root         : ${ANDROID_QT_ROOT}")
    _portable_apk_status(${TARGET} "androiddeployqt path    : ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
    _portable_apk_status(${TARGET} "Target path             : ${ANDROID_APP_PATH}")
    _portable_apk_status(${TARGET} "Package name            : ${ANDROID_PACKAGE_NAME}")
    _portable_apk_status(${TARGET} "Application name        : \"${ANDROID_APP_NAME}\"")
    _portable_apk_status(${TARGET} "Application version     : ${ANDROID_APP_VERSION}")
    _portable_apk_status(${TARGET} "Application version code: ${ANDROID_APP_VERSION_CODE}")
    _portable_apk_status(${TARGET} "Verbosity output        : ${VERBOSITY} ")
    _portable_apk_status(${TARGET} "Install APK             : ${_arg_INSTALL}")

    #---------------------------------------------------------------------------
    # Create a custom command that will run the androiddeployqt utility
    # to prepare the Android package
    #---------------------------------------------------------------------------
    add_custom_target(
        ${TARGET}_apk
        ALL
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${OUTPUT_DIR} # it seems that recompiled libraries are not copied if we don't remove them first
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy ${ANDROID_APP_PATH} ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/android-sources ${ANDROID_APP_PACKAGE_SOURCE_ROOT}
        COMMAND ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}
            ${VERBOSE}
            --output ${CMAKE_CURRENT_BINARY_DIR}/android-build
            --input ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
            --gradle
            --android-platform ${ANDROID_PLATFORM}
            ${INSTALL_OPTIONS}
            ${SIGN_OPTIONS})

    add_dependencies(${TARGET}_apk ${_arg_DEPENDS})
endfunction(portable_target_build_apk)
