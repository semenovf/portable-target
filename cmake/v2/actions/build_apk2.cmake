################################################################################
# Copyright (c) 2021-2023 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2023.06.08 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)
# include(${CMAKE_CURRENT_LIST_DIR}/../android/AndroidExtraOpenSSL.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/properties.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/private/qt5_androiddeploy.cmake)

# set(QTDEPLOY_JSON_IN_FILE_DIR ${CMAKE_CURRENT_LIST_DIR}/../android)
# set(QTDEPLOY_JSON_IN_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/qtdeploy.json.in)
# set(BUILD_GRADLE_IN_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/build.gradle.in)
# set(GRADLE_WRAPPER_FILE ${QTDEPLOY_JSON_IN_FILE_DIR}/gradle-wrapper.properties)

# find_program(ADB_BIN adb)

#
# Usage:
#
# portable_target_build_apk2(<target>
# #       [ANDROIDDEPLOYQT_EXECUTABLE path]
# #       [PACKAGE_NAME package-name]
#       [APP_NAME app-name]
#       APP_NAMESPACE app-namespace
# #       [APK_BASENAME template]
# #       [QTDEPLOY_JSON_IN_FILE path]
#       [VERSION_MAJOR major-version]
#       [VERSION_MINOR minor-version]
#       [VERSION_PATCH patch-version]
# #       [SCREEN_ORIENTATION orientation]
# #       [CONFIG_CHANGES config-changes ]
# #       [PERMISSIONS permissions]
# #       [DEPENDS dependencies]
# #       [SSL_ROOT dir]
# #       [INSTALL ON|OFF]
#       [VERBOSE ON|OFF])
#
# # USE_ANDROIDDEPLOYQT
# #       If set and ANDROIDDEPLOYQT_EXECUTABLE is not
# #
# # ANDROIDDEPLOYQT_EXECUTABLE path
# #       Path to `androiddeployqt` executable. Set according to to default Qt5
# #       location if not specified.
# #
# # PACKAGE_NAME <package-name>
# #       Android package name
#
# APP_NAME app-name
#       Android application name (label). Default is ${TARGET}.
#
# APP_NAMESPACE app-namespace
#       Android application namespace (see build.gradle.in).
#
# # APK_BASENAME template
# #       Template for basename for resulting APK file path.
# #       Example: Hello_@ANDROID_APP_VERSION@_@ANDROID_ABI@
#
# VERSION_MAJOR major-version
#       Android application major version number. Default is 1.
#
# VERSION_MINOR minor-version
#       Android application minor version number. Default is 0.
#
# VERSION_PATCH
#       Android application patch version number. Default is 0.
#
# # SCREEN_ORIENTATION orientation
# #       `orientation` is one of: "unspecified", "behind", "landscape"
# #               , "portrait", "reverseLandscape", "reversePortrait"
# #               , "sensorLandscape", "sensorPortrait", "userLandscape"
# #               , "userPortrait", "sensor", "fullSensor", "nosensor"
# #               , "user", "fullUser", "locked".
# #       Default is "unspecified".
# #       see https://developer.android.com/guide/topics/manifest/activity-element#screen
# #
# # CONFIG_CHANGES config-changes
# #       `config-changes` is one of: "mcc", "mnc", "locale", "touchscreen"
# #               , "keyboard" , "keyboardHidden", "navigation", "screenLayout"
# #               , "fontScale" , "uiMode", "orientation", "density", "screenSize"
# #               , "smallestScreenSize".
# #       Default is empty string.
# #       see https://developer.android.com/guide/topics/manifest/activity-element#config
# #
# # DEPENDS dependencies
# #
# # PERMISSIONS permissions
# #       Set Android application permissions. Default is WAKE_LOCK.
# #
# # SSL_ROOT dir
# #       SSL libraries root directory (not implemented yet).
# #
# # INSTALL ON|OFF
# #       Install Android APK on device. Default is OFF. Can be set by
# #       PORTABLE_TARGET_ANDROID_INSTALL environment variable.
#
# VERBOSE ON|OFF
#       Output verbocity. Default is OFF.
#

################################################################################
# portable_target_build_apk2
################################################################################

function (portable_target_build_apk2 TARGET)
    set(boolparm)

    set(singleparm
#         ANDROIDDEPLOYQT_EXECUTABLE
        APP_NAME
        APP_NAMESPACE
#         APK_BASENAME
        STL_PREFIX
#         CONFIG_CHANGES
#         INSTALL
#         KEYSTORE_PASSWORD
#         PACKAGE_NAME
#         QTDEPLOY_JSON_IN_FILE
        QT_RCC_BUNDLE
#         SCREEN_ORIENTATION
#         SSL_ROOT
#         VERBOSE
        VERSION_MAJOR
        VERSION_MINOR
        VERSION_PATCH)

    set(multiparm
        DEPENDS
#         KEYSTORE
#         PERMISSIONS
    )

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

    # Used in AndroidManifest.xml.in
    if (_arg_APP_NAME)
        set(ANDROID_APP_LIB_NAME ${_arg_APP_NAME})
    else ()
        set(ANDROID_APP_LIB_NAME ${TARGET})
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

    if (NOT _arg_APP_NAMESPACE)
        _portable_target_fatal(${TARGET} "`APP_NAMESPACE` paramater is mandatory.")
    endif()

    math(EXPR ANDROID_APP_VERSION_CODE "${_arg_VERSION_MAJOR} * 1000000 + ${_arg_VERSION_MINOR} * 10000 + ${_arg_VERSION_PATCH}")
    set(ANDROID_APP_VERSION_NAME "${_arg_VERSION_MAJOR}.${_arg_VERSION_MINOR}.${_arg_VERSION_PATCH}")

    set(_android_src_dir ${CMAKE_SOURCE_DIR}/Android)
    set(_android_build_dir ${CMAKE_CURRENT_BINARY_DIR}/Android)

    # Used in build.gradle.in
    set(ANDROID_BUILD_DIR ${_android_build_dir}/build)
    set(ANDROID_APP_NAMESPACE ${_arg_APP_NAMESPACE})

    portable_target_get_property(Qt5_DIR _qt5_dir)
    portable_target_get_property(Qt5_VERSION _qt5_version)
    portable_target_get_property(Qt5_COMPONENTS _qt5_components)

    _portable_target_trace(${TARGET} "Qt5 COMPONENTS: ${_qt5_components}")

    if (NOT _qt5_dir)
        _portable_target_fatal(${TARGET} "`Qt5_DIR` property not set. Check if `QT5_DIR` variable set")
    endif()

    if (_qt5_components)
        get_filename_component(ANDROID_APP_QT_AIDL_DIR "${_qt5_dir}/../../../src/android/java/src" ABSOLUTE)
        get_filename_component(ANDROID_APP_QT_JAVA_DIR "${_qt5_dir}/../../../src/android/java/src" ABSOLUTE)
        get_filename_component(ANDROID_APP_QT_RES_DIR "${_qt5_dir}/../../../src/android/java/res" ABSOLUTE)

        qt5a_jar_implementations(${_qt5_dir} "${_qt5_components}" ANDROID_APP_DEPENDENCIES)
    endif()

    file(GLOB_RECURSE _android_sources
        FOLLOW_SYMLINKS
        LIST_DIRECTORIES TRUE
        RELATIVE ${_android_src_dir}
        ${_android_src_dir}/*)

    if (NOT EXISTS ${_android_build_dir})
        file(MAKE_DIRECTORY ${_android_build_dir})
    endif()

    if (NOT EXISTS ${ANDROID_BUILD_DIR})
        file(MAKE_DIRECTORY ${ANDROID_BUILD_DIR})
    endif()

    if (NOT EXISTS "${_android_build_dir}/src")
        file(MAKE_DIRECTORY "${_android_build_dir}/src")
    endif()

    foreach (_src ${_android_sources})
        # Ignore entries started with dot
        if (NOT (${_src} MATCHES "^\\." OR ${_src} MATCHES "/\\."))

            if (IS_DIRECTORY "${_android_src_dir}/${_src}")
                #_portable_target_trace(${TARGET} "DIR: ${_src}")

                if (NOT EXISTS "${_android_build_dir}/src/${_src}")
                    file(MAKE_DIRECTORY "${_android_build_dir}/src/${_src}")
                endif()
            else()
                if (${_src} MATCHES "\\.in$")
                    string(LENGTH ${_src} _src_length)
                    math(EXPR _src_length "${_src_length} - 3")
                    string(SUBSTRING ${_src} 0 ${_src_length} _generated_src)

                    #_portable_target_trace(${TARGET} "IN: ${_src} => ${_generated_src}")

                    # if (EXISTS "${_android_build_dir}/src/${_generated_src}")
                    #     _portable_target_fatal(${TARGET} "Already exists: ${_android_build_dir}/src/${_generated_src}")
                    # endif()

                    configure_file("${_android_src_dir}/${_src}"
                        "${_android_build_dir}/src/${_generated_src}"
                        @ONLY)
                else()
                    #_portable_target_trace(${TARGET} ${_src})

                    if (NOT EXISTS "${_android_build_dir}/src/${_src}")
                        # NOTE Gradle not work properly with symbolic links?
                        # file(CREATE_LINK
                        #     "${_android_src_dir}/${_src}"
                        #     "${_android_build_dir}/src/${_src}"
                        #     SYMBOLIC)

                        file(COPY_FILE
                            "${_android_src_dir}/${_src}"
                            "${_android_build_dir}/src/${_src}")
                    endif()
                endif()
            endif()
        endif()
    endforeach()

    if (NOT EXISTS "${_android_build_dir}/assets")
        file(MAKE_DIRECTORY "${_android_build_dir}/assets")
    endif()

    set(_assets_dir "${_android_build_dir}/src/app/src/main/assets")
    file(MAKE_DIRECTORY "${_assets_dir}")

    set(_jni_libs_dir "${_android_build_dir}/src/app/src/main/jniLibs/${ANDROID_ABI}")
    file(MAKE_DIRECTORY "${_jni_libs_dir}")

    #
    # C++ standard library.
    #
    # ANDROID_NDK, ANDROID_STL is global predefined variables
    # (see AndroidToolchain.cmake)
    #

    set(_cxx_shared_lib_filename "lib${ANDROID_STL}.so")

    # Old placement of C++ library
    set(_cxx_shared_lib "${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/${_cxx_shared_lib_filename}")

    if (NOT EXISTS ${_cxx_shared_lib})
        set(_cxx_shared_lib_base_dir "${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib")

        if (EXISTS ${_cxx_shared_lib_base_dir})
            if (ANDROID_ABI STREQUAL "x86")
                set(_cxx_shared_lib "${_cxx_shared_lib_base_dir}/i686-linux-android/${_cxx_shared_lib_filename}")
            elseif(ANDROID_ABI STREQUAL "x86_64")
                set(_cxx_shared_lib "${_cxx_shared_lib_base_dir}/x86_64-linux-android/${_cxx_shared_lib_filename}")
            elseif(ANDROID_ABI STREQUAL "arm64-v8a")
                set(_cxx_shared_lib "${_cxx_shared_lib_base_dir}/aarch64-linux-android/${_cxx_shared_lib_filename}")
            elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
                set(_cxx_shared_lib "${_cxx_shared_lib_base_dir}/arm-linux-androideabi/${_cxx_shared_lib_filename}")
            else()
                _portable_target_fatal(${TARGET} "Bad ANDROID_ABI: ${ANDROID_ABI}")
            endif()
        endif()

        if (NOT EXISTS ${_cxx_shared_lib_base_dir})
            _portable_target_fatal(${TARGET} "Android C++ library not found")
        endif()
    endif()

    file(CREATE_LINK
        ${_cxx_shared_lib}
        "${_jni_libs_dir}/${_cxx_shared_lib_filename}"
        SYMBOLIC)

    _portable_target_status(${TARGET} "Android C++ library: ${_cxx_shared_lib}")

    #
    # Generate/copy Qt for Android required files.
    #
    set(_libs_xml "${_android_build_dir}/src/app/src/main/res/values/libs.xml")

    qt5a_begin_libs_xml(${_libs_xml})

    qt5a_add_bundled_libs_xml(${_libs_xml} ${TARGET} "${_arg_DEPENDS}")

    if (_qt5_components)
        qt5a_add_qt5_libs_xml(${_libs_xml} "${_qt5_components}")
    endif()

    qt5a_end_libs_xml(${_libs_xml})

    if (_qt5_components)
        qt5a_copy_qt5_libs(${_qt5_dir} ${_jni_libs_dir} "${_qt5_components}")
        qt5a_copy_qt5_plugins(${_qt5_dir} ${_jni_libs_dir} "${_qt5_components}")
    endif()

    #
    # Build APK with gredlew
    #

    set(GRADLEW_COMMAND "${_android_build_dir}/src/gradlew")

    if (NOT EXISTS ${GRADLEW_COMMAND})
        _portable_target_fatal(${TARGET} "`gradlew` executable not found: ${GRADLEW_COMMAND}")
    endif()

    set(_build_apk_script "${_android_build_dir}/build_apk.cmake")
    string(TIMESTAMP _current_time)
    file(WRITE ${_build_apk_script}.in "### AUTOMATICALLY GENERATED AT ${_current_time} ###\n\n")
    file(APPEND ${_build_apk_script}.in "file(CREATE_LINK \"$<TARGET_FILE:${TARGET}>\" \"${_jni_libs_dir}/$<TARGET_FILE_NAME:${TARGET}>\" SYMBOLIC)\n")

    # Set the list of dependant libraries
    if (_arg_DEPENDS)
        foreach (_lib ${_arg_DEPENDS})
            if (TARGET ${_lib})
                # item is a CMake target, extract the library path
                #set(_lib "$<TARGET_FILE:${_lib}>")
                file(APPEND ${_build_apk_script}.in "file(CREATE_LINK \"$<TARGET_FILE:${_lib}>\" \"${_jni_libs_dir}/$<TARGET_FILE_NAME:${_lib}>\" SYMBOLIC)\n")
            endif()

            # if (_bundled_libs)
            #     set(_bundled_libs "${_bundled_libs},${_lib}")
            # else()
            #     set(_bundled_libs "${_lib}")
            # endif()
        endforeach()

#         #set(ANDROID_APP_EXTRA_LIBS "\"android-extra-libs\": \"${_extra_libs}\",")
#         set(ANDROID_APP_EXTRA_LIBS ${_extra_libs})
    endif()

    if (_arg_QT_RCC_BUNDLE)
        if (NOT EXISTS ${_arg_QT_RCC_BUNDLE})
            _portable_target_fatal(${TARGET} "Qt assets (Android RCC bundle) not found: ${_arg_QT_RCC_BUNDLE}")
        endif()

        get_filename_component(_qt5_rcc_bundle_filename ${_arg_QT_RCC_BUNDLE} NAME)

        file(CREATE_LINK
            "${_arg_QT_RCC_BUNDLE}"
            "${_assets_dir}/${_qt5_rcc_bundle_filename}"
            SYMBOLIC)
    endif()

#     if (_arg_APP_NAME OR _arg_VERSION_MAJOR OR _arg_VERSION_MINOR)
#         if (NOT _arg_PACKAGE_NAME)
#             _portable_apk_error(${TARGET} "PACKAGE_NAME must be specified")
#         endif()
#     endif()
#
#     if (NOT _arg_APP_NAME)
#         set(_arg_APP_NAME ${TARGET})
#     endif()
#
#
#     if (NOT _arg_SCREEN_ORIENTATION)
#         set(_arg_SCREEN_ORIENTATION "unspecified")
#     endif()
#
#     if (NOT _arg_CONFIG_CHANGES)
#         set(_arg_CONFIG_CHANGES "")
#     endif()
#
#     if (NOT _arg_INSTALL)
#         _optional_var_env(_arg_INSTALL
#             ANDROID_INSTALL
#             "Install APK"
#             OFF)
#     endif()
#
#     if (NOT _arg_PERMISSIONS)
#         set(_arg_PERMISSIONS WAKE_LOCK)
#         _portable_apk_warn(${TARGET} "Android permissions are not defined, only 'WAKE_LOCK' set by default")
#     endif()
#
#     # FIXME
#     if (_arg_SSL_ROOT)
# #         _portable_apk_status(${TARGET} "Android SSL extra libraries root: ${_arg_SSL_ROOT}")
# #         _portable_android_openssl(
# #             ${_arg_SSL_ROOT}
# #             ${Qt5Core_VERSION}
# #             ${ANDROID_ABI}
# #             _android_ssl_extra_libs)
# #         _portable_apk_status("Android SSL extra libraries: ${_android_ssl_extra_libs}")
#     endif()
#
#
#     # Used by `qtdeploy.json.in` and `AndroidManifest.xml.in`
#     set(ANDROID_PACKAGE_NAME ${_arg_PACKAGE_NAME})
#     set(ANDROID_APP_NAME ${_arg_APP_NAME})
#
#     # Whether your application's processes should be created with a large Dalvik
#     # heap (see https://developer.android.com/guide/topics/manifest/application-element#largeHeap for details).
#     set(ANDROID_APP_LARGE_HEAP "true")
#     set(ANDROID_APP_SCREEN_ORIENTATION "${_arg_SCREEN_ORIENTATION}")
#     set(ANDROID_APP_CONFIG_CHANGES "${_arg_CONFIG_CHANGES}")
#
#     if (${CMAKE_BUILD_TYPE} MATCHES "[Dd][Ee][Bb][Uu][Gg]"
#             OR ${CMAKE_BUILD_TYPE} MATCHES "[Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo]")
#         set(ANDROID_APP_IS_DEBUGGABLE "true")
#     else()
#         # TODO Check for older versions. It depends on androiddeployqt version
#         if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
#             if (_arg_KEYSTORE AND _arg_KEYSTORE_PASSWORD)
#                 set(SIGN_OPTIONS --sign ${_arg_KEYSTORE} release --storepass
#                     ${_arg_KEYSTORE_PASSWORD} --keypass ${_arg_KEYSTORE_PASSWORD})
#                 set(ANDROID_APP_IS_DEBUGGABLE "false")
#             else()
#                 set(ANDROID_APP_IS_DEBUGGABLE "true")
#             endif()
#         else()
#             set(ANDROID_APP_IS_DEBUGGABLE "true")
#         endif()
#     endif()
#
#     # Set the list of dependant libraries
#     if (_arg_DEPENDS OR _android_ssl_extra_libs)
#         foreach (_lib ${_arg_DEPENDS} ${_android_ssl_extra_libs})
#             if (TARGET ${_lib})
#                 # item is a CMake target, extract the library path
#                 set(_lib "$<TARGET_FILE:${_lib}>")
#             endif()
#
#             if (_extra_libs)
#                 set(_extra_libs "${_extra_libs},${_lib}")
#             else()
#                 set(_extra_libs "${_lib}")
#             endif()
#         endforeach()
#
#         #set(ANDROID_APP_EXTRA_LIBS "\"android-extra-libs\": \"${_extra_libs}\",")
#         set(ANDROID_APP_EXTRA_LIBS ${_extra_libs})
#     endif()
#
#     #---------------------------------------------------------------------------
#     # Detect latest Android SDK build-tools revision
#     #---------------------------------------------------------------------------
#     if (DEFINED ENV{ANDROID_SDK_BUILDTOOLS_REVISION})
#         set(ANDROID_SDK_BUILDTOOLS_REVISION "$ENV{ANDROID_SDK_BUILDTOOLS_REVISION}")
#     elseif (DEFINED ENV{ANDROID_SDK_BUILDTOOLS_VERSION})
#         set(ANDROID_SDK_BUILDTOOLS_REVISION "$ENV{ANDROID_SDK_BUILDTOOLS_VERSION}")
#     else()
#         set(ANDROID_SDK_BUILDTOOLS_REVISION "0.0.0")
#         file(GLOB _all_build_tools_versions RELATIVE ${ANDROID_SDK}/build-tools ${ANDROID_SDK}/build-tools/*)
#
#         foreach(_build_tools_version ${_all_build_tools_versions})
#             # Find subfolder with greatest version
#             if (${_build_tools_version} VERSION_GREATER ${ANDROID_SDK_BUILDTOOLS_REVISION})
#                 set(ANDROID_SDK_BUILDTOOLS_REVISION ${_build_tools_version})
#             endif()
#         endforeach()
#     endif()
#
#     # Used by `AndroidManifest.xml.in`
#     set(ANDROID_USES_PERMISSION)
#
#     foreach (_permission ${_arg_PERMISSIONS})
#         set(ANDROID_USES_PERMISSION "${ANDROID_USES_PERMISSION}\t<uses-permission android:name=\"android.permission.${_permission}\" />\n")
#     endforeach()
#
#     # Find suitable AndroidManifest.xml.in
#     set(_AndroidManifest_xml_in "AndroidManifest.xml.in")
#     set(_android_sources_dir "${CMAKE_CURRENT_SOURCE_DIR}/android-sources")
#
#     foreach(_sdk_version 21;22;23;24;25;26;27;28;29;30;31;32;33)
#         if (${_sdk_version} GREATER ${ANDROID_TARGET_SDK_VERSION})
#             break()
#         endif()
#
#         if (EXISTS "${_android_sources_dir}/AndroidManifest-${_sdk_version}.xml.in")
#             set(_AndroidManifest_xml_in "AndroidManifest-${_sdk_version}.xml.in")
#         endif()
#     endforeach()
#
#     if (NOT EXISTS ${_android_sources_dir}/${_AndroidManifest_xml_in})
#         _portable_apk_error(${TARGET} "${_AndroidManifest_xml_in} not found at: ${_android_sources_dir}"
#             "\n\tAndroidManifest.xml.in can be copied from portable_target/android directory")
#     else()
#         _portable_apk_status(${TARGET} "${_AndroidManifest_xml_in} found at: ${_android_sources_dir}")
#     endif()
#
#     # Create a subdirectory for the extra package sources
#     # Used by `qtdeploy.json.in`
#     set(ANDROID_APP_PACKAGE_SOURCE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/android-sources")
#
#     # Generate a manifest from the template
#     configure_file(${_android_sources_dir}/${_AndroidManifest_xml_in} ${ANDROID_APP_PACKAGE_SOURCE_ROOT}/AndroidManifest.xml @ONLY)
#
#     # Set "useLLVM" parameter in qtdeploy.json to default value 'false'
#     set(ANDROID_USE_LLVM "false")
#
#     # Set some toolchain variables used by androiddeployqt;
#     # unfortunately, Qt tries to build paths from these variables although these full paths
#     # are already available in the toochain file, so we have to parse them
#     string(REGEX MATCH "${ANDROID_NDK}/toolchains/(.*)-(.*)/prebuilt/.*" _android_toolchain_parsed ${ANDROID_TOOLCHAIN_ROOT})
#
#     if (_android_toolchain_parsed)
#         # Used by `qtdeploy.json.in`
#         set(ANDROID_TOOLCHAIN_PREFIX ${CMAKE_MATCH_1})
#         set(ANDROID_TOOLCHAIN_VERSION ${CMAKE_MATCH_2})
#     else()
#         string(REGEX MATCH "${ANDROID_NDK}/toolchains/llvm/prebuilt/.*" _android_toolchain_parsed ${ANDROID_TOOLCHAIN_ROOT})
#
#         if (_android_toolchain_parsed)
#             # Used by `qtdeploy.json.in`
#             set(ANDROID_TOOLCHAIN_PREFIX llvm)
#             set(ANDROID_TOOLCHAIN_VERSION)
#             set(ANDROID_USE_LLVM "true")
#         else()
#             _portable_apk_error(${TARGET}
#                 "Failed to parse ANDROID_TOOLCHAIN_ROOT (${ANDROID_TOOLCHAIN_ROOT}) to get toolchain prefix and version")
#         endif()
#     endif()
#
#     # Create the configuration file that will feed androiddeployqt
#     # Replace placeholder variables at generation time
#     configure_file(${_arg_QTDEPLOY_JSON_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in @ONLY)
#
#     # Evaluate generator expressions at build time
#     file(GENERATE
#         OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
#         INPUT ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json.in)
#
#     # Create gradle configuration
#     configure_file(${BUILD_GRADLE_IN_FILE} ${CMAKE_CURRENT_BINARY_DIR}/build.gradle.in @ONLY)
#     file(GENERATE
#         OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/android-build/build.gradle
#         INPUT ${CMAKE_CURRENT_BINARY_DIR}/build.gradle.in)
#
#     file(COPY ${GRADLE_WRAPPER_FILE} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/android-build/gradle/wrapper)
#
#     # Workaround for `androiddeployqt` bug with `llvm-strip` options.
#     # This bug takes places in Qt5.13.2 and older versions, but is already fixed
#     # in 5.12.9 and 5.15.0 as mentioned in the bug report:
#     # https://bugreports.qt.io/browse/QTBUG-74292.
#     # Let's not distinguish the Qt versions for now and apply this workaround
#     # for `llvm-strip` program in any cases.
#     if (ANDROID_TOOLCHAIN_PREFIX STREQUAL llvm)
#         if (CMAKE_STRIP MATCHES "llvm-strip$")
#             set(_llvm_strip_original "${CMAKE_STRIP}.original")
#
#             if (NOT EXISTS ${_llvm_strip_original})
#                 get_filename_component(_llvm_strip_dir ${CMAKE_STRIP} DIRECTORY)
#                 get_filename_component(_llvm_strip_filename ${CMAKE_STRIP} NAME)
#
#                 file(RENAME ${CMAKE_STRIP} ${_llvm_strip_original})
#                 file(WRITE ${CMAKE_BINARY_DIR}/${_llvm_strip_filename}
#                     "#!/usr/bin/env bash\n\n${_llvm_strip_original} \${@//-strip-all/--strip-all}\n")
#                 file(COPY ${CMAKE_BINARY_DIR}/${_llvm_strip_filename}
#                     DESTINATION ${_llvm_strip_dir}
#                     FILE_PERMISSIONS OWNER_EXECUTE OWNER_READ OWNER_WRITE)
#             endif()
#         endif()
#     endif()
#
#     # There are two options for `androiddeployqt` related to installation:
#     #   --install (will be called sequentially `adb uninstall` and `adb install -r`)
#     #   --reinstall (will be called `adb install -r` only).
#     # Will use second method.
#     if  (_arg_INSTALL)
#         #set(INSTALL_OPTIONS --reinstall)
#         set(INSTALL_YESNO "YES")
#     else()
#         set(INSTALL_YESNO "NO")
#     endif()
#
#     if (_arg_VERBOSE)
#         set(VERBOSE "--verbose")
#         set(VERBOSITY_YESNO "YES")
#     else()
#         set(VERBOSITY_YESNO "NO")
#     endif()
#
#     _portable_apk_status(${TARGET} "Android Min SDK version: ${ANDROID_MIN_SDK_VERSION}")
#     _portable_apk_status(${TARGET} "Android Target SDK version: ${ANDROID_TARGET_SDK_VERSION}")
#     _portable_apk_status(${TARGET} "Android SDK build tools revision: ${ANDROID_SDK_BUILDTOOLS_REVISION}")
#     _portable_apk_status(${TARGET} "Android Qt root         : ${ANDROID_QT_ROOT}")
#
#     if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
#         _portable_apk_status(${TARGET} "Android STL dir         : ${ANDROID_STL_DIR}")
#     else()
#         _portable_apk_status(${TARGET} "Android STL path        : ${ANDROID_STL_PATH}")
#     endif()
#
#     _portable_apk_status(${TARGET} "androiddeployqt path    : ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
#     _portable_apk_status(${TARGET} "Qt deploy JSON template : ${_arg_QTDEPLOY_JSON_IN_FILE}")
#     _portable_apk_status(${TARGET} "Target path             : ${ANDROID_APP_PATH}")
#     _portable_apk_status(${TARGET} "Target basename         : ${ANDROID_APP_BASENAME}")
#     _portable_apk_status(${TARGET} "Package name            : ${ANDROID_PACKAGE_NAME}")
#     _portable_apk_status(${TARGET} "Application name        : \"${ANDROID_APP_NAME}\"")
    _portable_target_status(${TARGET} "Application version code: ${ANDROID_APP_VERSION_CODE}")
    _portable_target_status(${TARGET} "Application version     : ${ANDROID_APP_VERSION_NAME}")
#     _portable_apk_status(${TARGET} "Verbosity output        : ${VERBOSITY_YESNO}")
#     _portable_apk_status(${TARGET} "Install APK             : ${INSTALL_YESNO}")
#
#     #---------------------------------------------------------------------------
#     # Create a custom command that will run the androiddeployqt utility
#     # to prepare the Android package
#     #---------------------------------------------------------------------------
#     # TODO A more precise definition is required to get TEMP_APK_PATH
#
#     if (_arg_APK_BASENAME)
#         string(CONFIGURE ${_arg_APK_BASENAME} _arg_APK_BASENAME @ONLY)
#     else()
#         set(_arg_APK_BASENAME "${_arg_APK_BASENAME}_${ANDROID_APP_VERSION}_${ANDROID_ABI}")
#     endif()
#
#     if (${ANDROID_APP_IS_DEBUGGABLE} STREQUAL "true")
#         set(_temp_apk_path "${CMAKE_CURRENT_BINARY_DIR}/android-build/build/outputs/apk/debug/android-build-debug.apk")
#         set(_target_apk_path "${CMAKE_BINARY_DIR}/${_arg_APK_BASENAME}_debug.apk")
#     else()
#         set(_temp_apk_path "${CMAKE_CURRENT_BINARY_DIR}/android-build/build/outputs/apk/release/android-build-release-signed.apk")
#         set(_target_apk_path "${CMAKE_BINARY_DIR}/${_arg_APK_BASENAME}.apk")
#     endif()
#
#     set(_output_dir ${CMAKE_CURRENT_BINARY_DIR}/android-build/libs/${ANDROID_ABI})
#
#     if (${_qt5_version} VERSION_GREATER_EQUAL 5.14)
#         set(_android_app_output_path ${_output_dir}/lib${ANDROID_APP_BASENAME}_${ANDROID_ABI}.so)
#     else()
#         set(_android_app_output_path ${_output_dir}/lib${ANDROID_APP_BASENAME}.so)
#     endif()

    if (${CMAKE_BUILD_TYPE} STREQUAL "Release")
        set(_gradlew_args "assembleRelease")
    else()
        set(_gradlew_args "assembleDebug")
    endif()

    if (_arg_VERBOSE AND _arg_VERBOSE STREQUAL "ON")
        set(_gradlew_args "${_gradlew_args} --info")
    endif()

    # Evaluate generator expressions at build time
    file(GENERATE OUTPUT ${_build_apk_script} INPUT ${_build_apk_script}.in)

    add_custom_target(
        ${TARGET}_apk
        ALL
        #COMMAND cd "${_android_build_dir}/src"
        #COMMAND ${CMAKE_COMMAND} -P ${_build_apk_script}
        COMMAND ${CMAKE_COMMAND} -E chdir "${_android_build_dir}/src" ${CMAKE_COMMAND} -P ${_build_apk_script}
        COMMAND ${CMAKE_COMMAND} -E chdir "${_android_build_dir}/src" ${GRADLEW_COMMAND} ${_gradlew_args}

#         COMMAND ${CMAKE_COMMAND} -E remove_directory ${_output_dir} # it seems that recompiled libraries are not copied if we don't remove them first
#         COMMAND ${CMAKE_COMMAND} -E make_directory ${_output_dir}
#         COMMAND ${CMAKE_COMMAND} -E copy ${ANDROID_APP_PATH} ${_android_app_output_path}
#         COMMAND ${CMAKE_COMMAND} -E copy_directory ${_android_sources_dir}/sources ${ANDROID_APP_PACKAGE_SOURCE_ROOT}
#         COMMAND ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}
#             ${VERBOSE}
#             --output ${CMAKE_CURRENT_BINARY_DIR}/android-build
#             --input ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
#             --gradle
#             --android-platform ${ANDROID_PLATFORM}
#             ${SIGN_OPTIONS}
#         COMMAND ${CMAKE_COMMAND} -E copy ${_temp_apk_path} ${_target_apk_path}
    )

#     if (_arg_INSTALL)
#         if (ADB_BIN)
#             list(APPEND _adb_install_opts "-r")
#
#             if (${ANDROID_APP_IS_DEBUGGABLE} STREQUAL "true")
#                 list(APPEND _adb_install_opts "-t")
#             endif()
#
#             add_custom_target(
#                 ${TARGET}_apk_install
#                 ALL
#                 COMMAND ${ADB_BIN} install ${_adb_install_opts} ${_target_apk_path})
#
#             add_dependencies(${TARGET}_apk_install ${TARGET}_apk)
#         else()
#             _portable_apk_warn(${TARGET} "`adb` tool not found, install APK manually")
#         endif()
#     endif()
#
#     if (_arg_DEPENDS)
#         add_dependencies(${TARGET}_apk ${_arg_DEPENDS})
#     endif()
endfunction(portable_target_build_apk2)

