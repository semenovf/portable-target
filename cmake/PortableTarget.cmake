################################################################################
# Copyright (c) 2019 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2019.12.10 Initial version
#      2020.09.03 Splitted into Functions.cmake, AndroidToolchain.cmake and PortableTarget.cmake
################################################################################
cmake_minimum_required(VERSION 3.5)
include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/Functions.cmake)

set(QTDEPLOY_JSON_IN_FILE ${CMAKE_CURRENT_LIST_DIR}/qtdeploy.json.in)

# TODO Check `android-source` directory existance (_portable_apk)
# TODO Add support build for Windows
# TODO Add support KEYSTORE_PASSWORD for Android (_portable_apk)
# TODO Add support KEYSTORE for Android (_portable_apk)
# TODO Add support DEPENDS for Android (_portable_apk)
# TODO Check ANDROID_APP_PATH is valid according to https://developer.android.com/studio/build/application-id

#
# Usage:
#
# portable_target(MyApp
#       [AGGRESSIVE_COMPILER_CHECK]            # Default is OFF (Global variable PORTABLE_TARGET_AGGRESSIVE_COMPILER_CHECK)
#       [AUTOMOC_OFF]                          # Default is ON
#       [AUTOUIC_OFF]                          # Default is ON
#       [AUTORCC_OFF]                          # Default is ON
#       [STATIC]                               # Target is static library (ignored by Android version)
#       [SHARED]                               # Target is shared library (ignored by Android version)
#       [Qt5_ROOT <dir>]                       # Must point to Qt5 official distribution directory. If not specified set to PORTABLE_TARGET_Qt5_ROOT or uses system platform
#       [Qt5_PLATFORM <qt5-platform>]          # If not specified set to PORTABLE_TARGET_Qt5_PLATFORM or uses system platform
#       [Qt5_COMPONENTS <qt5-components>]
#
#       # Android specific options
#       # see https://developer.android.com/guide/topics/manifest/manifest-element
#       [ANDROID_PACKAGE_NAME <package-name>]  # Android package name
#       [ANDROID_APP_NAME <app-name>]          # Android application name (label)
#       [ANDROID_APP_VERSION_MAJOR <app-version>]    # Android application major version number
#       [ANDROID_APP_VERSION_MINOR <app-version>]    # Android application minor version number
#       # see https://developer.android.com/guide/topics/manifest/activity-element#screen
#       [ANDROID_APP_SCREEN_ORIENTATION "unspecified"
#               | "behind" | "landscape" | "portrait"
#               | "reverseLandscape" | "reversePortrait"
#               | "sensorLandscape" | "sensorPortrait"
#               | "userLandscape" | "userPortrait"
#               | "sensor" | "fullSensor" | "nosensor"
#               | "user" | "fullUser" | "locked"]
#       # see https://developer.android.com/guide/topics/manifest/activity-element#config
#       [ANDROID_APP_CONFIG_CHANGES "mcc", "mnc", "locale", "touchscreen"
#               , "keyboard" , "keyboardHidden", "navigation", "screenLayout"
#               , "fontScale" , "uiMode", "orientation", "density", "screenSize"
#               , "smallestScreenSize"]
#       [ANDROID_INSTALL]                      # Install Android APK on device
#       SOURCES <source1> <source2> ...
#
# By default, if not specifed STATIC and/or SHARED target is shared library
# on Android platform (always SHARED) or executable on Linux/Windows
#
# Set AGGRESSIVE_COMPILER_CHECK if want the compiler more pedantic. This option
# activate specific compiler flags for concrete compiler (NOTE now supports
# only `gcc`)
#
# Set AUTOMOC_OFF if not required to autogenerate moc sources:
#       - project has custom signals/slots
#       - ... (TODO add cases)
# Set AUTOUIC_OFF if not required UIC to autogenerate UI sources
# Set AUTORCC_OFF if not required RCC to autogenerate resource sources
#       from qrc-files listed in sources list
#
# Qt5_PLATFORM (Qt5.13.2):
#       - gcc_64
#       - android_x86
#       - android_armv7
#       - android_arm64_v8a
#
# Recomendations:
# Build for Android properly (successfull tested) with:
#       - Qt5.13.2 + ANDROID NDK r20
#

################################################################################
# _portable_apk
#
# Inspired from:
#       [Qt Android CMake utility](https://github.com/LaurentGomila/qt-android-cmake)
################################################################################
#cmake_policy(SET CMP0026 OLD) # allow use of the LOCATION target property

function (_portable_apk TARGET SOURCE_TARGET)
    set(boolparm)

    set(singleparm
        ANDROIDDEPLOYQT_EXECUTABLE
        PACKAGE_NAME
        APP_NAME
        APP_VERSION
        APP_VERSION_MAJOR
        APP_VERSION_MINOR
        APP_SCREEN_ORIENTATION
        APP_CONFIG_CHANGES
        INSTALL
        #KEYSTORE_PASSWORD
    )

    set(multiparm
        PERMISSIONS
        DEPENDS
        #KEYSTORE
    )

    # Parse the macro arguments
    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    set(ANDROID_APP_PATH "$<TARGET_FILE:${SOURCE_TARGET}>")

    # Used by `qtdeploy.json.in`
    get_filename_component(ANDROID_QT_ROOT "${_arg_ANDROIDDEPLOYQT_EXECUTABLE}/../.." ABSOLUTE)

    # Used by `qtdeploy.json.in` and `AndroidManifest.xml.in`
    set(ANDROID_PACKAGE_NAME ${_arg_PACKAGE_NAME})
    set(ANDROID_APP_NAME ${_arg_APP_NAME})

    # Used by `AndroidManifest.xml.in`
    set(ANDROID_APP_VERSION "${_arg_APP_VERSION_MAJOR}.${_arg_APP_VERSION_MINOR}")
    math(EXPR ANDROID_APP_VERSION_CODE "${_arg_APP_VERSION_MAJOR} * 1000 + ${_arg_APP_VERSION_MINOR}")
    # Whether your application's processes should be created with a large Dalvik
    # heap (see https://developer.android.com/guide/topics/manifest/application-element#largeHeap for details).
    set(ANDROID_APP_LARGE_HEAP "true")
    set(ANDROID_APP_SCREEN_ORIENTATION "${_arg_APP_SCREEN_ORIENTATION}")
    set(ANDROID_APP_CONFIG_CHANGES "${_arg_APP_CONFIG_CHANGES}")

    if (${CMAKE_BUILD_TYPE} MATCHES "[Dd][Ee][Bb][Uu][Gg]"
            OR ${CMAKE_BUILD_TYPE} MATCHES "[Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo]")
        set(ANDROID_APP_IS_DEBUGGABLE "true")
    else()
        set(ANDROID_APP_IS_DEBUGGABLE "false")
    endif()

    # Set the list of dependant libraries
    if (_arg_DEPENDS)
        foreach (_lib ${_arg_DEPENDS})
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

    if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest.xml.in)
        _portable_apk_error(${TARGET} "AndroidManifest.xml.in not found at: ${CMAKE_CURRENT_SOURCE_DIR}"
            "\n\tAndroidManifest.xml.in can be copied from portable_target/android directory")
    else()
        _portable_apk_status(${TARGET} "AndroidManifest.xml.in found at: ${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    # Create a subdirectory for the extra package sources
    # Used by `qtdeploy.json.in`
    set(ANDROID_APP_PACKAGE_SOURCE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/android-sources")

    # Generate a manifest from the template
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest.xml.in ${ANDROID_APP_PACKAGE_SOURCE_ROOT}/AndroidManifest.xml @ONLY)

    # Set "useLLVM" parameter in qtdeploy.json to 'false'
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

    set(SIGN_OPTIONS)

    # TODO check if the apk must be signed
#     if(ARG_KEYSTORE)
#         set(SIGN_OPTIONS --release --sign ${ARG_KEYSTORE} --tsa http://timestamp.digicert.com)
#         if(ARG_KEYSTORE_PASSWORD)
#             set(SIGN_OPTIONS ${SIGN_OPTIONS} --storepass ${ARG_KEYSTORE_PASSWORD})
#         endif()
#     endif()

    # TODO check if the apk must be installed to the device
    if  (_arg_INSTALL)
        set(INSTALL_OPTIONS --reinstall)
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
    _portable_apk_status(${TARGET} "Install APK             : ${_arg_INSTALL}")

    #---------------------------------------------------------------------------
    # Create a custom command that will run the androiddeployqt utility
    # to prepare the Android package
    #---------------------------------------------------------------------------
    add_custom_target(
        ${TARGET}
        ALL
        DEPENDS ${SOURCE_TARGET}
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${OUTPUT_DIR} # it seems that recompiled libraries are not copied if we don't remove them first
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy ${ANDROID_APP_PATH} ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/android-sources ${ANDROID_APP_PACKAGE_SOURCE_ROOT}
        COMMAND ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}
            --verbose
            --output ${CMAKE_CURRENT_BINARY_DIR}/android-build
            --input ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
            --gradle
            --android-platform ${ANDROID_PLATFORM}
            ${INSTALL_OPTIONS}
            ${SIGN_OPTIONS})
endfunction()

################################################################################
# portable_target
################################################################################
function (portable_target TARGET)
    set(boolparm
        AGGRESSIVE_COMPILER_CHECK
        AUTOMOC_OFF
        AUTOUIC_OFF
        AUTORCC_OFF
        STATIC
        SHARED
        ANDROID_INSTALL)

    set(singleparm
        Qt5_ROOT
        Qt5_PLATFORM
        ANDROID_PACKAGE_NAME
        ANDROID_APP_NAME
        ANDROID_APP_VERSION_MAJOR
        ANDROID_APP_VERSION_MINOR
        ANDROID_APP_SCREEN_ORIENTATION
        ANDROID_APP_CONFIG_CHANGES)

    set(multiparm
        Qt5_COMPONENTS
        ANDROID_PERMISSIONS
        SOURCES
        DEPENDS
        CATEGORIES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    _optional_var_env(_arg_Qt5_PLATFORM
        Qt5_PLATFORM
        "Qt5 target platform")

    _optional_var_env(_arg_Qt5_ROOT
        Qt5_ROOT
        "Qt5 root directory")

    _portable_target_status(${TARGET} "Cross-compiling     : ${CMAKE_CROSSCOMPILING}")
    _portable_target_status(${TARGET} "CMAKE_CXX_COMPILER  : ${CMAKE_CXX_COMPILER}")
    _portable_target_status(${TARGET} "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

    if (_arg_AUTOMOC_OFF)
        _portable_target_status(${TARGET} "AUTOMOC is OFF")
        set(CMAKE_AUTOMOC OFF)
    else()
        _portable_target_status(${TARGET} "AUTOMOC is ON")
        set(CMAKE_AUTOMOC ON)
    endif()

    if (_arg_AUTOUIC_OFF)
        _portable_target_status(${TARGET} "AUTOUIC is OFF")
        set(CMAKE_AUTOUIC OFF)
    else()
        _portable_target_status(${TARGET} "AUTOUIC is ON")
        set(CMAKE_AUTOUIC ON)
    endif()

    if (_arg_AUTORCC_OFF)
        _portable_target_status(${TARGET} "AUTORCC is OFF")
        set(CMAKE_AUTORCC OFF)
    else()
        _portable_target_status(${TARGET} "AUTORCC is ON")
        set(CMAKE_AUTORCC ON)
    endif()

    if (NOT _arg_SOURCES)
        _portable_target_error(${TARGET} "No sources specified")
    endif()

    if (_arg_Qt5_ROOT)
        if (NOT _arg_Qt5_PLATFORM)
            _portable_target_error(${TARGET} "Qt5 platform must be specified")
        endif()

        if (NOT EXISTS ${_arg_Qt5_ROOT})
            _portable_target_error(${TARGET}
                "Bad Qt5 location: '${_arg_Qt5_ROOT}', check Qt5_ROOT parameter")
        endif()

        set(Qt5_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5")

        if (NOT EXISTS ${Qt5_DIR})
            _portable_target_error(${TARGET}
                "Bad Qt5_DIR location: '${Qt5_DIR}', check Qt5_PLATFORM parameter or may be need modification of this function")
        endif()

        set(Qt5Core_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5Core")

        if (NOT EXISTS ${Qt5Core_DIR})
            _portable_target_error(${TARGET}
                "Bad Qt5Core location: '${Qt5Core_DIR}', need modification of this function")
        endif()

        _portable_target_status(${TARGET} "Qt5 location: ${_arg_Qt5_ROOT}")

        set(QT_QMAKE_EXECUTABLE "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/bin/qmake${CMAKE_EXECUTABLE_SUFFIX}")

        if (NOT EXISTS ${QT_QMAKE_EXECUTABLE})
            _portable_target_error(${TARGET}
                "Bad qmake location: '${QT_QMAKE_EXECUTABLE}', need modification of this function")
        endif()

        _portable_target_status(${TARGET} "Qt5 qmake location: ${QT_QMAKE_EXECUTABLE}")
    endif()

    set(_link_libraries)

    if (_arg_Qt5_COMPONENTS)
        if (ANDROID)
            #list(APPEND _arg_Qt5_COMPONENTS MultimediaQuick QuickParticles AndroidExtras)
            list(APPEND _arg_Qt5_COMPONENTS AndroidExtras)
        endif()

        # Set location of Qt5 modules if need
        foreach(_item IN LISTS _arg_Qt5_COMPONENTS)
            if (_arg_Qt5_ROOT)
                set(Qt5${_item}_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5${_item}")
                _portable_target_status(${TARGET} "Qt5::${_item} location: ${Qt5${_item}_DIR}")
            endif()
        endforeach()

        find_package(Qt5 COMPONENTS ${_arg_Qt5_COMPONENTS} REQUIRED)
        _portable_target_status(${TARGET} "Qt5 version found: ${Qt5Core_VERSION} (compare with required)")

        # See https://gitlab.kitware.com/cmake/cmake/issues/19167
        # Since 3.14 (--wladt-- remark: since 13.4) CMake requires valid
        # QT_VERSION_MAJOR/MINOR (Qt4),
        # Qt5Core_VERSION_MAJOR/MINOR or
        # Qt6Core_VERSION_MAJOR/MINOR
        set_property(DIRECTORY PROPERTY Qt5Core_VERSION_MAJOR ${Qt5Core_VERSION_MAJOR})
        set_property(DIRECTORY PROPERTY Qt5Core_VERSION_MINOR ${Qt5Core_VERSION_MINOR})

        foreach(_item IN LISTS _arg_Qt5_COMPONENTS)
            list(APPEND _link_libraries "Qt5::${_item}")
        endforeach()
    endif()

    if (ANDROID)
        add_library(${TARGET} SHARED ${_arg_SOURCES})
        target_compile_definitions(${TARGET} PRIVATE ANDROID)

        # Shared libraries need PIC
        set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)

        if (_arg_ANDROID_APP_NAME OR _arg_ANDROID_APP_VERSION_MAJOR OR _arg_ANDROID_APP_VERSION_MINOR)
            if (NOT _arg_ANDROID_PACKAGE_NAME)
                _portable_target_error(${TARGET} "ANDROID_PACKAGE_NAME must be specified")
            endif()
        endif()

        if (_arg_Qt5_COMPONENTS)
            if (_arg_ANDROID_PACKAGE_NAME)
                get_filename_component(ANDROIDDEPLOYQT_EXECUTABLE "${Qt5_DIR}/../../../bin/androiddeployqt" ABSOLUTE)

                if (NOT EXISTS ${ANDROIDDEPLOYQT_EXECUTABLE})
                    _portable_target_error(${TARGET} "androiddeployqt not found at: ${ANDROIDDEPLOYQT_EXECUTABLE}")
                endif()

                if (NOT _arg_ANDROID_APP_NAME)
                    set(_arg_ANDROID_APP_NAME ${TARGET})
                endif()

                if (NOT _arg_ANDROID_APP_VERSION_MAJOR)
                    set(_arg_ANDROID_APP_VERSION_MAJOR 1)
                endif()

                if (NOT _arg_ANDROID_APP_VERSION_MINOR)
                    set(_arg_ANDROID_APP_VERSION_MINOR 0)
                endif()

                if (NOT _arg_ANDROID_APP_SCREEN_ORIENTATION)
                    set(_arg_ANDROID_APP_SCREEN_ORIENTATION "unspecified")
                endif()

                if (NOT _arg_ANDROID_APP_CONFIG_CHANGES)
                    set(_arg_ANDROID_APP_CONFIG_CHANGES "")
                endif()

                if (_arg_ANDROID_INSTALL)
                    set(ANDROID_INSTALL_YESNO ON)
                else()
                    _mandatory_var_env(ANDROID_INSTALL_YESNO
                        ANDROID_INSTALL
                        "Install APK"
                        OFF)
                endif()

                if (NOT _arg_ANDROID_PERMISSIONS)
                    set(_arg_ANDROID_PERMISSIONS WAKE_LOCK)
                    message(WARNING "Android permissions are not defined, only 'WAKE_LOCK' set by default")
                endif()

                _portable_apk(${TARGET}_apk ${TARGET}
                    ANDROIDDEPLOYQT_EXECUTABLE ${ANDROIDDEPLOYQT_EXECUTABLE}
                    PACKAGE_NAME "${_arg_ANDROID_PACKAGE_NAME}"
                    APP_NAME "${_arg_ANDROID_APP_NAME}"
                    APP_VERSION_MAJOR "${_arg_ANDROID_APP_VERSION_MAJOR}"
                    APP_VERSION_MINOR "${_arg_ANDROID_APP_VERSION_MINOR}"
                    APP_SCREEN_ORIENTATION "${_arg_ANDROID_APP_SCREEN_ORIENTATION}"
                    APP_CONFIG_CHANGES "${_arg_ANDROID_APP_CONFIG_CHANGES}"
                    PERMISSIONS ${_arg_ANDROID_PERMISSIONS}
                    #KEYSTORE ${CMAKE_CURRENT_SOURCE_DIR}/pad.keystore pad
                    INSTALL ${ANDROID_INSTALL_YESNO}
                    DEPENDS ${_arg_DEPENDS})
            endif(_arg_ANDROID_PACKAGE_NAME)
        else(_arg_Qt5_COMPONENTS)
            # TODO Settings for building non-Qt application
            message(FATAL_ERROR "Only Android application based on Qt supported")
        endif(_arg_Qt5_COMPONENTS)
    else() # NOT ANDROID
        if(_arg_STATIC AND _arg_SHARED)
            # Prepare OBJECT target
            if (_arg_Qt5_COMPONENTS)
                foreach(_item IN LISTS _arg_Qt5_COMPONENTS)
                    list(APPEND _include_directories "${Qt5${_item}_INCLUDE_DIRS}")
                endforeach()
            endif()

            add_library(${TARGET}_OBJLIB OBJECT ${_arg_SOURCES})
            set_property(TARGET ${TARGET}_OBJLIB PROPERTY POSITION_INDEPENDENT_CODE 1)
            target_include_directories(${TARGET}_OBJLIB PRIVATE ${_include_directories})

            add_library(${TARGET} SHARED $<TARGET_OBJECTS:${TARGET}_OBJLIB>)
            add_library(${TARGET}-static STATIC $<TARGET_OBJECTS:${TARGET}_OBJLIB>)

            # Shared libraries need PIC
            set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
        elseif(_arg_STATIC)
#             add_library(${TARGET}-static STATIC ${_arg_SOURCES})
            add_library(${TARGET} STATIC ${_arg_SOURCES})
        elseif(_arg_SHARED)
            add_library(${TARGET} SHARED ${_arg_SOURCES})

            # Shared libraries need PIC
            set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
        else()
            add_executable(${TARGET} ${_arg_SOURCES})
        endif()

        _optional_var_env(_arg_AGGRESSIVE_COMPILER_CHECK
            AGGRESSIVE_COMPILER_CHECK
            "Aggressive compiler check")

        set(_link_flags)

        if (_arg_AGGRESSIVE_COMPILER_CHECK)
            if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                #
                # See [https://codeforces.com/blog/entry/15547](https://codeforces.com/blog/entry/15547)
                #
                _portable_target_status(${TARGET} "Aggressive compiler check is ON")
                list(APPEND _aggressive_check_flags
                    "-D_GLIBCXX_DEBUG=1"
                    "-D_GLIBCXX_DEBUG_PEDANTIC=1"
                    "-D_FORTIFY_SOURCE=2"
                    "-pedantic"
                    "-O2"
                    "-Wall"
                    "-Wextra"
                    "-Wshadow"
                    "-Wformat=2"
                    "-Wfloat-equal"
                    # "-Wconversion" # <-- Annoying message, may be need separate option for this
                    "-Wlogical-op"
                    "-Wshift-overflow=2"
                    "-Wduplicated-cond"
                    "-Wcast-qual"
                    "-Wcast-align"
                    "-fsanitize=address"   # <-- The option cannot be combined with -fsanitize=thread and/or -fcheck-pointer-bounds.
                    "-fsanitize=undefined"
                    "-fsanitize=leak"      # <-- The option cannot be combined with -fsanitize=thread
                    "-fno-sanitize-recover"
                    "-fstack-protector"

                    # gcc: error: -fsanitize=address and -fsanitize=kernel-address are incompatible with -fsanitize=thread
                    # "-fsanitize=thread"
                )

                list(APPEND _link_flags
                    "-fsanitize=address"
                    "-fsanitize=undefined"
                    "-fsanitize=leak"
                )

                list(APPEND _link_libraries
                    "-lasan"  # <-- need for -fsanitize=address
                    "-lubsan" # <-- need for -fsanitize=undefined
                    #"-ltsan"  # <-- need for -fsanitize=thread
                )

                target_compile_options(${TARGET} PRIVATE ${_aggressive_check_flags})
            endif()
        endif()
    endif()

    if (_arg_CATEGORIES)
        foreach(_cat IN LISTS _arg_CATEGORIES)
            get_property(_prop GLOBAL PROPERTY ${_cat})
            list(APPEND _prop ${TARGET})
            set_property(GLOBAL PROPERTY ${_cat} ${_prop})
        endforeach()
    endif()

    if(_arg_STATIC AND _arg_SHARED AND NOT ANDROID)
        target_link_libraries(${TARGET} ${_link_flags} ${_link_libraries})
        target_link_libraries(${TARGET}-static ${_link_flags} ${_link_libraries})
    else()
        target_link_libraries(${TARGET} ${_link_flags} ${_link_libraries})
    endif()

    if (_arg_DEPENDS)
        add_dependencies(${TARGET} ${_arg_DEPENDS})
    endif()

endfunction()
