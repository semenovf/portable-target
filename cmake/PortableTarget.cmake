cmake_minimum_required(VERSION 3.0)
include(CMakeParseArguments)
#
# Usage:
#
# portable_target(MyApp
#       [ANDROID]
#       [STATIC]                               # Target is static library (ignored by Android version)
#       [SHARED]                               # Target is shared library (ignored by Android version)
#       [AUTOMOC_OFF]                          # Default is ON
#       [AUTOUIC_OFF]                          # Default is ON
#       [AUTORCC_OFF]                          # Default is ON
#       [Qt5_ROOT <dir>]                       # Must point to Qt5 official distribution directory
#       [Qt5_PLATFORM <qt5-platform>]
#       [Qt5_COMPONENTS <qt5-components>]
#       [ANDROID_PLATFORM <android-platform>]  # Default is 'android-21' (affects compiler/linker option `--target`)
#       [ANDROID_ABI <android-abi>]            # Mandatory for Android
#       [ANDROID_TOOLCHAIN <toolchain>]        # Default is 'clang'
#       [ANDROID_STL <stl-library>]            # Default is 'c++_shared'
#       [ANDROID_STL_PREFIX <stl-prefix>]      # Used as a component of STL library path ('llvm-libc++' for c++_shared)
#       SOURCES <source1> <source2> ...
#
# By default, if not specifed STATIC and/or SHARED target is shared library
# on Android platform or executable on Linux/Windows
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
# ANDROID_PLATFORM:
#       - android-21
#       - ... (TODO Extend list)
#
# ANDROID_ABI:
#       - armeabi                - ARMv5TE based CPU with software floating point operations
#       - armeabi-v7a            - ARMv7 based devices with hardware FPU instructions (VFPv3_D16)
#       - armeabi-v7a with NEON  - same as armeabi-v7a, but sets NEON as floating-point unit
#       - armeabi-v7a with VFPV3 - same as armeabi-v7a, but sets VFPv3_D32 as floating-point unit
#       - armeabi-v6 with VFP    - tuned for ARMv6 processors having VFP
#       - x86                    - IA-32 instruction set
#       - mips                   - MIPS32 instruction set
#       - arm64-v8a              - ARMv8 AArch64 instruction set - only for NDK r10 and newer
#       - x86_64                 - Intel64 instruction set (r1) - only for NDK r10 and newer
#       - mips64                 - MIPS64 instruction set (r6) - only for NDK r10 and newer
#
# Build for Android properly with:
#       - Qt5.13.2 + ANDROID NDK r20
#

################################################################################
# _portable_target_error
################################################################################
function (_portable_target_error TEXT)
    message(FATAL_ERROR "*** ERROR: portable_target: ${TEXT}")
endfunction()

################################################################################
# _portable_target_status
################################################################################
function (_portable_target_status TEXT)
    message(STATUS "portable_target: ${TEXT}")
endfunction()

################################################################################
# _portable_apk_error
################################################################################
function (_portable_apk_error TEXT)
    message(FATAL_ERROR "*** ERROR: portable_apk: ${TEXT}")
endfunction()

################################################################################
# _portable_apk_status
################################################################################
function (_portable_apk_status TEXT)
    message(STATUS "portable_apk: ${TEXT}")
endfunction()

################################################################################
# _portable_apk
#
# Inspired from:
#       [Qt Android CMake utility](https://github.com/LaurentGomila/qt-android-cmake)
################################################################################
cmake_policy(SET CMP0026 OLD) # allow use of the LOCATION target property

function (_portable_apk TARGET SOURCE_TARGET)
#     set(boolparm INSTALL)

    set(singleparm
        ANDROID_SDK
        ANDROID_NDK
        ANDROID_ABI
        ANDROID_PLATFORM_LEVEL
        ANDROID_STL
        ANDROID_STL_PREFIX
        ANDROIDDEPLOYQT_EXECUTABLE
        PACKAGE_NAME
        APP_NAME
        APP_VERSION
        #KEYSTORE_PASSWORD
        INSTALL
    )

    set(multiparm
        DEPENDS)
        #KEYSTORE)

    # parse the macro arguments
    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    #
    # Check arguments
    #
    if (NOT _arg_ANDROID_SDK)
        _portable_apk_error("ANDROID_SDK must be specified")
    endif()

    if (NOT _arg_ANDROID_NDK)
        _portable_apk_error("ANDROID_NDK must be specified")
    endif()

    if (NOT _arg_ANDROID_ABI)
        _portable_apk_error("ANDROID_ABI must be specified")
    endif()

    if (NOT _arg_ANDROID_PLATFORM_LEVEL)
        _portable_apk_error("ANDROID_PLATFORM_LEVEL must be specified")
    endif()

    if (NOT _arg_ANDROID_STL)
        _portable_apk_error("ANDROID_STL must be specified")
    endif()

    if (NOT _arg_ANDROID_STL_PREFIX)
        _portable_apk_error("ANDROID_STL_PREFIX must be specified")
    endif()

    if (NOT _arg_ANDROIDDEPLOYQT_EXECUTABLE)
        _portable_apk_error("ANDROIDDEPLOYQT_EXECUTABLE must be specified")
    endif()

    if (NOT _arg_PACKAGE_NAME)
        _portable_apk_error("PACKAGE_NAME must be specified")
    endif()

    if (NOT _arg_APP_NAME)
        _portable_apk_error("APP_NAME must be specified")
    endif()

    if (NOT _arg_APP_VERSION)
        _portable_apk_error("APP_VERSION must be specified")
    endif()

    if (NOT _arg_INSTALL)
        _portable_apk_error("INSTALL must be specified")
    endif()

    set(_ANDROID_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/android-sources")
    # create a subdirectory for the extra package sources
    set(QT_ANDROID_APP_PACKAGE_SOURCE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/android-sources")

    # extract the full path of the source target binary
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        get_property(QT_ANDROID_APP_PATH TARGET ${SOURCE_TARGET} PROPERTY DEBUG_LOCATION)
    else()
        get_property(QT_ANDROID_APP_PATH TARGET ${SOURCE_TARGET} PROPERTY LOCATION)
    endif()

    get_filename_component(QT_ANDROID_QT_ROOT "${_arg_ANDROIDDEPLOYQT_EXECUTABLE}/../.." ABSOLUTE)
    set(QT_ANDROID_SDK_ROOT ${_arg_ANDROID_SDK})
    set(QT_ANDROID_NDK_ROOT ${_arg_ANDROID_NDK})
    set(QT_ANDROID_STL_PATH "${_arg_ANDROID_NDK}/sources/cxx-stl/${_arg_ANDROID_STL_PREFIX}/libs/${_arg_ANDROID_ABI}/lib${_arg_ANDROID_STL}.so")
    set(QT_ANDROID_APP_PACKAGE_NAME ${_arg_PACKAGE_NAME})
    set(QT_ANDROID_APP_NAME ${_arg_APP_NAME})
    set(QT_ANDROID_APP_VERSION_CODE ${_arg_APP_VERSION})

    # androiddeployqt doesn't like backslashes in paths
    string(REPLACE "\\" "/" QT_ANDROID_SDK_ROOT ${QT_ANDROID_SDK_ROOT})
    string(REPLACE "\\" "/" QT_ANDROID_NDK_ROOT ${QT_ANDROID_NDK_ROOT})

    #
    # Detect latest Android SDK build-tools revision
    #
    set(QT_ANDROID_SDK_BUILDTOOLS_REVISION "0.0.0")
    file(GLOB ALL_BUILD_TOOLS_VERSIONS RELATIVE ${QT_ANDROID_SDK_ROOT}/build-tools ${QT_ANDROID_SDK_ROOT}/build-tools/*)
    foreach(BUILD_TOOLS_VERSION ${ALL_BUILD_TOOLS_VERSIONS})
        # find subfolder with greatest version
        if (${BUILD_TOOLS_VERSION} VERSION_GREATER ${QT_ANDROID_SDK_BUILDTOOLS_REVISION})
            set(QT_ANDROID_SDK_BUILDTOOLS_REVISION ${BUILD_TOOLS_VERSION})
        endif()
    endforeach()

    _portable_apk_status("Android SDK build tools version detected: ${QT_ANDROID_SDK_BUILDTOOLS_REVISION}")
    _portable_apk_status("Android STL path      : ${QT_ANDROID_STL_PATH}")
    _portable_apk_status("Android platform level: ${_arg_ANDROID_PLATFORM_LEVEL}")
    _portable_apk_status("Android Qt root       : ${QT_ANDROID_QT_ROOT}")
    _portable_apk_status("androiddeployqt       : ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}")
    _portable_apk_status("Target path           : ${QT_ANDROID_APP_PATH}")
    _portable_apk_status("Package name          : ${QT_ANDROID_APP_PACKAGE_NAME}")
    _portable_apk_status("Application name      : \"${QT_ANDROID_APP_NAME}\"")
    _portable_apk_status("Application version   : ${QT_ANDROID_APP_VERSION}")

    if (NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/AndroidManifest.xml.in)
        _portable_apk_error("AndroidManifest.xml.in not found at: ${CMAKE_CURRENT_LIST_DIR}")
    else()
        _portable_apk_status("AndroidManifest.xml.in found at: ${CMAKE_CURRENT_LIST_DIR}")
    endif()

    # generate a manifest from the template
    configure_file(${CMAKE_CURRENT_LIST_DIR}/AndroidManifest.xml.in ${QT_ANDROID_APP_PACKAGE_SOURCE_ROOT}/AndroidManifest.xml @ONLY)

    # Set "useLLVM" parameter in qtdeploy.json to 'false'
    set(QT_ANDROID_USE_LLVM "false")

    # set some toolchain variables used by androiddeployqt;
    # unfortunately, Qt tries to build paths from these variables although these full paths
    # are already available in the toochain file, so we have to parse them
    string(REGEX MATCH "${ANDROID_NDK}/toolchains/(.*)-(.*)/prebuilt/.*" ANDROID_TOOLCHAIN_PARSED ${ANDROID_TOOLCHAIN_ROOT})
    if(ANDROID_TOOLCHAIN_PARSED)
        set(QT_ANDROID_TOOLCHAIN_PREFIX ${CMAKE_MATCH_1})
        set(QT_ANDROID_TOOLCHAIN_VERSION ${CMAKE_MATCH_2})
    else()
        string(REGEX MATCH "${ANDROID_NDK}/toolchains/llvm/prebuilt/.*" ANDROID_TOOLCHAIN_PARSED ${ANDROID_TOOLCHAIN_ROOT})
        if(ANDROID_TOOLCHAIN_PARSED)
#             if(NOT _arg_ANDROID_COMPILER_VERSION)
#                 _portable_apk_error("ANDROID_COMPILER_VERSION must be specifiedcmake variable required")
#             endif()
            set(QT_ANDROID_TOOLCHAIN_PREFIX llvm)
            set(QT_ANDROID_TOOLCHAIN_VERSION)# ${ANDROID_COMPILER_VERSION})
            set(QT_ANDROID_USE_LLVM "true")
        else()
            _portable_apk_error("Failed to parse ANDROID_TOOLCHAIN_ROOT (${ANDROID_TOOLCHAIN_ROOT}) to get toolchain prefix and version")
        endif()
    endif()

    # make sure that the output directory for the Android package exists
    set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/android-build/libs/${_arg_ANDROID_ABI})
    file(MAKE_DIRECTORY ${OUTPUT_DIR})

    # create the configuration file that will feed androiddeployqt
    configure_file(${CMAKE_SOURCE_DIR}/cmake/qtdeploy.json.in ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json @ONLY)

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

    #
    # Create a custom command that will run the androiddeployqt utility
    # to prepare the Android package
    #
    add_custom_target(
        ${TARGET}
        ALL
        DEPENDS ${SOURCE_TARGET}
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${OUTPUT_DIR} # it seems that recompiled libraries are not copied if we don't remove them first
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy ${QT_ANDROID_APP_PATH} ${OUTPUT_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_LIST_DIR}/android-sources ${QT_ANDROID_APP_PACKAGE_SOURCE_ROOT}
        COMMAND ${_arg_ANDROIDDEPLOYQT_EXECUTABLE}
                --verbose
                --output ${CMAKE_CURRENT_BINARY_DIR}/android-build
                --input ${CMAKE_CURRENT_BINARY_DIR}/qtdeploy.json
                --gradle
                --android-platform android-${_arg_ANDROID_PLATFORM_LEVEL}
                ${INSTALL_OPTIONS} ${SIGN_OPTIONS})
endfunction()

################################################################################
# portable_target
################################################################################
function (portable_target TARGET)
    set(boolparm
        AUTOMOC_OFF
        AUTOUIC_OFF
        AUTORCC_OFF
        STATIC
        SHARED
        ANDROID_INSTALL)

    set(singleparm
        Qt5_ROOT
        Qt5_PLATFORM
        ANDROID_PLATFORM
        ANDROID_PLATFORM_LEVEL
        ANDROID_ABI
        ANDROID_COMPILER_VERSION
        ANDROID_TOOLCHAIN
        ANDROID_STL
        ANDROID_STL_PREFIX
        ANDROID_PACKAGE_NAME
        ANDROID_APP_NAME
        ANDROID_APP_VERSION
    ) # DLL_API)

    set(multiparm
        Qt5_COMPONENTS
        SOURCES)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

#     if (NOT _arg_UNPARSED_ARGUMENTS)
#         message(FATAL_ERROR "qt5_portable_app: ...")
#     endif()

    if (ANDROID)
        # Touch variables to suppress "unused variable" warning.
        # This happens if CMake is invoked with the same command line the second time.
        if(CMAKE_TOOLCHAIN_FILE)
        endif()
        if(ANDROID_ABI)
        endif()
        if(ANDROID_NDK)
        endif()
        if(ANDROID_PLATFORM)
        endif()
        if(ANDROID_STL)
        endif()
        if(ANDROID_TOOLCHAIN)
        endif()

        if (NOT ANDROID_85de0b22-2f4a-4aeb-beba-265a793aad00)
            if (NOT DEFINED ENV{JAVA_HOME})
                _portable_target_error("JAVA_HOME variable must be set and point to Java home directory")
            endif()

            if (NOT EXISTS $ENV{JAVA_HOME})
                _portable_target_error("JAVA_HOME directory not found: $ENV{JAVA_HOME}")
            endif()

            if (NOT DEFINED ENV{ANDROID_SDK})
                _portable_target_error("ANDROID_SDK variable must be set and point to Android SDK home directory")
            endif()

            if (NOT EXISTS $ENV{ANDROID_SDK})
                _portable_target_error("Android SDK directory not found: $ENV{ANDROID_SDK}")
            endif()

            # Set variable affects Android toolchain
            set(ANDROID_NDK "$ENV{ANDROID_SDK}/ndk-bundle")

            if (NOT EXISTS ${ANDROID_NDK})
                _portable_target_error("Android NDK directory not found: ${ANDROID_NDK}")
            endif()

            set(ANDROID_TOOLCHAIN_FILE "${ANDROID_NDK}/build/cmake/android.toolchain.cmake")

            if (NOT EXISTS ${ANDROID_TOOLCHAIN_FILE})
                _portable_target_error("Android toolchain file not found: ${ANDROID_TOOLCHAIN_FILE}")
            endif()

            if (NOT _arg_ANDROID_PLATFORM)
                set(_arg_ANDROID_PLATFORM android-21)
            endif()

            if (NOT _arg_ANDROID_PLATFORM_LEVEL)
                _portable_target_error("ANDROID_PLATFORM_LEVEL must be specified")
            endif()

            if (NOT _arg_ANDROID_ABI)
                _portable_target_error("ANDROID_ABI must be specified")
            endif()

            if (NOT _arg_ANDROID_TOOLCHAIN)
                set(_arg_ANDROID_TOOLCHAIN "clang")
            endif()

            if (NOT _arg_ANDROID_STL)
                set(_arg_ANDROID_STL "c++_shared")
            endif()

            _portable_target_status("CMAKE command           : ${CMAKE_COMMAND}")
            _portable_target_status("CMAKE version           : ${CMAKE_VERSION}")
            _portable_target_status("Java HOME directory     : $ENV{JAVA_HOME}")
            _portable_target_status("Android SDK directory   : $ENV{ANDROID_SDK}")
            _portable_target_status("Android NDK directory   : ${ANDROID_NDK}")
            _portable_target_status("Android toolchain file  : ${ANDROID_TOOLCHAIN_FILE}")
            _portable_target_status("Android platform        : ${_arg_ANDROID_PLATFORM}")
            _portable_target_status("Android ABI             : ${_arg_ANDROID_ABI}")
            _portable_target_status("Android toolchain       : ${_arg_ANDROID_TOOLCHAIN}")
            _portable_target_status("Android STL             : ${_arg_ANDROID_STL}")

            execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/Android")
            execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}"
                    -DANDROID_85de0b22-2f4a-4aeb-beba-265a793aad00=ON
#                    -UCMAKE_CXX_COMPILER
                    -DCMAKE_TOOLCHAIN_FILE=${ANDROID_TOOLCHAIN_FILE}
                    -DANDROID_NDK=${ANDROID_NDK}
                    -DANDROID_PLATFORM=${_arg_ANDROID_PLATFORM}
                    -DANDROID_TOOLCHAIN=${_arg_ANDROID_TOOLCHAIN}
                    -DANDROID_ABI=${_arg_ANDROID_ABI}
                    -DANDROID_STL=${_arg_ANDROID_STL}
                    -DANDROID=ON
                    ${CMAKE_SOURCE_DIR}

                    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/Android")
            return()
        endif() # ! ANDROID_85de0b22-2f4a-4aeb-beba-265a793aad00
    endif(ANDROID)

    _portable_target_status("CMAKE_CXX_COMPILER  : ${CMAKE_CXX_COMPILER}")
    _portable_target_status("CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

    if (_arg_AUTOMOC_OFF)
        _portable_target_status("AUTOMOC is OFF")
        set(CMAKE_AUTOMOC OFF)
    else()
        _portable_target_status("AUTOMOC is ON")
        set(CMAKE_AUTOMOC ON)
    endif()

    if (_arg_AUTOUIC_OFF)
        _portable_target_status("AUTOUIC is OFF")
        set(CMAKE_AUTOUIC OFF)
    else()
        _portable_target_status("AUTOUIC is ON")
        set(CMAKE_AUTOUIC ON)
    endif()

    if (_arg_AUTORCC_OFF)
        _portable_target_status("AUTORCC is OFF")
        set(CMAKE_AUTORCC OFF)
    else()
        _portable_target_status("AUTORCC is ON")
        set(CMAKE_AUTORCC ON)
    endif()

    if (NOT _arg_SOURCES)
        _portable_target_error("No sources specified")
    endif()

    if (_arg_Qt5_ROOT)
        if(NOT _arg_Qt5_PLATFORM)
            _portable_target_error("Qt5 platform must be specified")
        endif()

        if (NOT EXISTS ${_arg_Qt5_ROOT})
            _portable_target_error("Bad Qt5 location: '${_arg_Qt5_ROOT}', check Qt5_ROOT parameter")
        endif()

        set(Qt5_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5")

        if (NOT EXISTS ${Qt5_DIR})
            _portable_target_error("Bad Qt5_DIR location: '${Qt5_DIR}', check Qt5_PLATFORM parameter or mey be need modification of this function")
        endif()

        set(Qt5Core_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5Core")

        if (NOT EXISTS ${Qt5Core_DIR})
            _portable_target_error("Bad Qt5Core location: '${Qt5Core_DIR}', need modification of this function")
        endif()

        _portable_target_status("Qt5 location: ${_arg_Qt5_ROOT}")

        set(QT_QMAKE_EXECUTABLE "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/bin/qmake${CMAKE_EXECUTABLE_SUFFIX}")

        if (NOT EXISTS ${QT_QMAKE_EXECUTABLE})
            _portable_target_error("Bad qmake location: '${QT_QMAKE_EXECUTABLE}', need modification of this function")
        endif()

        _portable_target_status("Qt5 qmake location: ${QT_QMAKE_EXECUTABLE}")
    endif()

    set(_link_libraries)

    if (_arg_Qt5_COMPONENTS)
        if(ANDROID)
            #list(APPEND _arg_Qt5_COMPONENTS MultimediaQuick QuickParticles AndroidExtras)
            list(APPEND _arg_Qt5_COMPONENTS AndroidExtras)
        endif()

        # Set location of Qt5 modules if need
        foreach(_item IN LISTS _arg_Qt5_COMPONENTS)
            if (_arg_Qt5_ROOT)
                set(Qt5${_item}_DIR "${_arg_Qt5_ROOT}/${_arg_Qt5_PLATFORM}/lib/cmake/Qt5${_item}")
                _portable_target_status("Qt5::${_item} location: ${Qt5${_item}_DIR}")
            endif()
        endforeach()

        find_package(Qt5 COMPONENTS ${_arg_Qt5_COMPONENTS} REQUIRED)
        _portable_target_status("Qt5 version found: ${Qt5Core_VERSION} (compare with required)")

        foreach(_item IN LISTS _arg_Qt5_COMPONENTS)
            list(APPEND _link_libraries "Qt5::${_item}")
        endforeach()
    endif()

    if (ANDROID)
        message(TRACE "*** _arg_SOURCES=[${_arg_SOURCES}]")
        add_library(${TARGET} SHARED ${_arg_SOURCES})
        target_compile_definitions(${TARGET} PRIVATE ANDROID)

        # Shared libraries need PIC
        set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)

        if (NOT _arg_ANDROID_PLATFORM_LEVEL)
            # Set to toolchain's value
            set(_arg_ANDROID_PLATFORM_LEVEL ${ANDROID_PLATFORM_LEVEL})

            if (NOT _arg_ANDROID_PLATFORM_LEVEL)
                _portable_target_error("ANDROID_PLATFORM_LEVEL is not provided by toolchain")
            endif()
        endif()

        if (NOT _arg_ANDROID_STL_PREFIX)
            string(REGEX MATCH "^[ ]*c\\+\\+_shared[ ]*$" ANDROID_STL_MATCHED ${ANDROID_STL})
            if (NOT ANDROID_STL_MATCHED)
                _portable_apk_error("Unable to deduce ANDROID_STL_PREFIX, ANDROID_STL_PREFIX must be specified")
            else()
                set(_arg_ANDROID_STL_PREFIX "llvm-libc++")
            endif()
        endif()

        if (NOT _arg_ANDROID_PACKAGE_NAME)
            _portable_apk_error("ANDROID_PACKAGE_NAME must be specified")
        endif()

        if (NOT _arg_ANDROID_APP_NAME)
            set(_arg_ANDROID_APP_NAME ${TARGET})
        endif()

        if (NOT _arg_ANDROID_APP_VERSION)
            set(_arg_ANDROID_APP_VERSION 1)
        endif()

        if (_arg_Qt5_COMPONENTS)
            get_filename_component(ANDROIDDEPLOYQT_EXECUTABLE "${Qt5_DIR}/../../../bin/androiddeployqt" ABSOLUTE)

            if (NOT EXISTS ${ANDROIDDEPLOYQT_EXECUTABLE})
                _portable_apk_error("androiddeployqt not found at: ${ANDROIDDEPLOYQT_EXECUTABLE}")
            endif()

            if (_arg_ANDROID_INSTALL)
                set(ANDROID_INSTALL ON)
            else()
                set(ANDROID_INSTALL OFF)
            endif()

            _portable_apk(${TARGET}_apk ${TARGET}
                    ANDROID_SDK $ENV{ANDROID_SDK}
                    ANDROID_NDK ${ANDROID_NDK}
                    ANDROID_ABI ${ANDROID_ABI}
                    ANDROID_PLATFORM_LEVEL ${_arg_ANDROID_PLATFORM_LEVEL}
                    ANDROID_STL ${ANDROID_STL}
                    ANDROID_STL_PREFIX ${_arg_ANDROID_STL_PREFIX}
                    ANDROIDDEPLOYQT_EXECUTABLE ${ANDROIDDEPLOYQT_EXECUTABLE}
                    PACKAGE_NAME ${_arg_ANDROID_PACKAGE_NAME}
                    APP_NAME ${_arg_ANDROID_APP_NAME}
                    APP_VERSION  ${_arg_ANDROID_APP_VERSION}
                    #KEYSTORE ${CMAKE_CURRENT_SOURCE_DIR}/pad.keystore pad
#                    DEPENDS ${TARGET}
                    INSTALL ${ANDROID_INSTALL}
            )
        else()
            # TODO Settings for building non-Qt application
        endif()
    else(ANDROID)
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

            # Shared libraries need PIC
            set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)

            add_library(${TARGET} SHARED $<TARGET_OBJECTS:${TARGET}_OBJLIB>)
            add_library(${TARGET}-static STATIC $<TARGET_OBJECTS:${TARGET}_OBJLIB>)
        elseif(_arg_STATIC)
            add_library(${TARGET}-static STATIC ${_arg_SOURCES})
        elseif(_arg_SHARED)
            # Shared libraries need PIC
            set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
            add_library(${TARGET} SHARED ${_arg_SOURCES})
        else()
            add_executable(${TARGET} ${_arg_SOURCES})
        endif()
    endif(ANDROID)

    if(_arg_STATIC AND _arg_SHARED AND NOT ANDROID)
        target_link_libraries(${TARGET} ${_link_libraries})
        target_link_libraries(${TARGET}-static ${_link_libraries})
    else()
        target_link_libraries(${TARGET} ${_link_libraries})
    endif()

endfunction()
