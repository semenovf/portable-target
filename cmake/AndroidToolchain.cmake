################################################################################
# Copyright (c) 2019 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2020.09.03 Initial version
#
#-------------------------------------------------------------------------------
# [Start the emulator from the command line](https://developer.android.com/studio/run/emulator-commandline)
#
# Some useful commands for installation APK into Android devices/emulators and testing
#
# Start ADB server
# $ adb start-server
#
# List of AVD names (optional):
# $ emulator -list-avds
#
# Cold boot---------------------------------------------------------------------|
# Starting a virtual device from a terminal prompt:                             v
# $ $ANDROID_SDK/emulator/emulator -avd <AVD> -netdelay none -netspeed full [-no-snapshot]
#
# List attached devices (optional):
# $ adb devices -l
#
# Install APK
# $ adb install -r <PATH_TO_APK>
#
# Dump a log of system messages
# $ adb logcat
#
# Stop ADB server (optional):
# $ adb kill-server
#
################################################################################
cmake_minimum_required(VERSION 3.5)
include(${CMAKE_CURRENT_LIST_DIR}/Functions.cmake)

_mandatory_var_env(JAVA_HOME
    JAVA_HOME
    "Java HOME")

if (NOT EXISTS ${JAVA_HOME})
    _portable_target_error("Java home directory not found: ${JAVA_HOME}")
endif()

# ANDROID_SDK variable must be set and point to Android SDK home directory
_mandatory_var_env(ANDROID_SDK
    ANDROID_SDK
    "Android SDK directory")

# androiddeployqt doesn't like backslashes in paths
string(REPLACE "\\" "/" ANDROID_SDK ${ANDROID_SDK})

if (NOT EXISTS ${ANDROID_SDK})
    _portable_target_error("Android SDK directory not found: ${ANDROID_SDK}")
endif()

_mandatory_var_env(ANDROID_NDK
    ANDROID_NDK
    "Android NDK directory"
    ${ANDROID_SDK}/ndk-bundle)

# androiddeployqt doesn't like backslashes in paths
string(REPLACE "\\" "/" ANDROID_NDK ${ANDROID_NDK})

if (NOT EXISTS ${ANDROID_NDK})
    _portable_target_error("Android NDK directory not found: ${ANDROID_NDK}")
endif()

_mandatory_var_env(ANDROID_TOOLCHAIN_FILE
    ANDROID_TOOLCHAIN_FILE
    "Android toolchain file"
    ${ANDROID_NDK}/build/cmake/android.toolchain.cmake)

if (NOT EXISTS ${ANDROID_TOOLCHAIN_FILE})
    _portable_target_error("Android toolchain file not found: ${ANDROID_TOOLCHAIN_FILE}")
endif()

# ANDROID_TOOLCHAIN variants:
#   * clang (default)
#   * gcc (no longer supported)
# NOTE: it is better to leave this value untouched
_mandatory_var_env(ANDROID_TOOLCHAIN
    ANDROID_TOOLCHAIN
    "Android toolchain"
    "clang")

# ANDROID_ABI:
#   - armeabi                - ARMv5TE based CPU with software floating point operations
#   - armeabi-v7a            - ARMv7 based devices with hardware FPU instructions (VFPv3_D16)
#   - armeabi-v7a with NEON  - same as armeabi-v7a, but sets NEON as floating-point unit
#   - armeabi-v7a with VFPV3 - same as armeabi-v7a, but sets VFPv3_D32 as floating-point unit
#   - armeabi-v6 with VFP    - tuned for ARMv6 processors having VFP
#   - x86                    - IA-32 instruction set
#   - mips                   - MIPS32 instruction set
#   - arm64-v8a              - ARMv8 AArch64 instruction set - only for NDK r10 and newer
#   - x86_64                 - Intel64 instruction set (r1) - only for NDK r10 and newer
#   - mips64                 - MIPS64 instruction set (r6) - only for NDK r10 and newer
_mandatory_var_env(ANDROID_ABI
    ANDROID_ABI
    "Android ABI")

# ANDROID_PLATFORM is equivalent to one of the directories from list:
#       `ls -1 ${ANDROID_NDK}/platforms` (android-16, .. , android-21, android-22, .. , android-30 etc)
_mandatory_var_env(ANDROID_PLATFORM
    ANDROID_PLATFORM
    "Android platform")

_mandatory_var_env(ANDROID_STL
    ANDROID_STL
    "Android STL"
    "c++_shared")

_optional_var_env(ANDROID_STL_PREFIX
    ANDROID_STL_PREFIX
    "Android STL prefix")

if (NOT ANDROID_STL_PREFIX)
    if (${ANDROID_STL} MATCHES "^[ ]*c\\+\\+_shared[ ]*$")
        set(ANDROID_STL_PREFIX "llvm-libc++")
    else()
        _portable_target_error("Unable to deduce ANDROID_STL_PREFIX, ANDROID_STL_PREFIX must be specified")
    endif()
endif()

# Used by `qtdeploy.json.in`
set(ANDROID_STL_PATH
    "${ANDROID_NDK}/sources/cxx-stl/${ANDROID_STL_PREFIX}/libs/${ANDROID_ABI}/lib${ANDROID_STL}.so")

if (NOT EXISTS ${ANDROID_STL_PATH})
    _portable_target_error("Android STL path not found: ${ANDROID_STL_PATH}")
endif()

# [<uses-sdk>](https://developer.android.com/guide/topics/manifest/uses-sdk-element)
# The minimum API Level required for the application to run.
# Associated with attribute 'android:minSdkVersion' of <uses-sdk> tag.
_mandatory_var_env(ANDROID_MIN_SDK_VERSION
    ANDROID_MIN_SDK_VERSION
    "Android min SDK version"
    21)

# The API Level that the application targets.
# If not set, the default value equals that given to minSdkVersion.
# Associated with attribute 'android:targetSdkVersion' of <uses-sdk> tag.
_mandatory_var_env(ANDROID_TARGET_SDK_VERSION
    ANDROID_TARGET_SDK_VERSION
    "Android target SDK version"
    28)

_portable_target_status("CMAKE command         : ${CMAKE_COMMAND}")
_portable_target_status("CMAKE version         : ${CMAKE_VERSION}")
_portable_target_status("Java HOME directory   : ${JAVA_HOME}")
_portable_target_status("Android SDK directory : ${ANDROID_SDK}")
_portable_target_status("Android NDK directory : ${ANDROID_NDK}")
_portable_target_status("Android toolchain file: ${ANDROID_TOOLCHAIN_FILE}")
_portable_target_status("Android toolchain     : ${ANDROID_TOOLCHAIN}")
_portable_target_status("Android ABI           : ${ANDROID_ABI}")
_portable_target_status("Android platform      : ${ANDROID_PLATFORM}")
_portable_target_status("Android STL           : ${ANDROID_STL}")
_portable_target_status("Android STL path      : ${ANDROID_STL_PATH}")

# Include actual toolchain file
include(${ANDROID_TOOLCHAIN_FILE})
