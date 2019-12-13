################################################################################
# Copyright (c) 2019 Vladislav Trifochkin
#
# Changelog:
#      2019.12.07 Initial version
################################################################################
# This is a minimal reference script for build cross-platform
# application based on Qt
#
# References:
# [Configure CMake](https://developer.android.com/studio/projects/configure-cmake)
#
# ### Building for ANDROID
# $ cmake -G <Generator> -DANDROID=ON ...
################################################################################
cmake_minimum_required (VERSION 3.5.1)

# Set ON if need add current directory to list of directories to be searched
# for header files during preprocessing
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(${CMAKE_SOURCE_DIR}/cmake/PortableTarget.cmake)

set(SOURCES main.cpp main.qrc)
set(Qt5_COMPONENTS Core Widgets Gui Network Qml)

if(ANDROID)
    set(Qt5_PLATFORM android_x86) #android_armv7)
else()
    set(Qt5_PLATFORM gcc_64)
endif()

portable_target(FileDialog
#     AUTOUIC_OFF
    Qt5_ROOT /opt/Qt5.13.2/5.13.2
    Qt5_PLATFORM ${Qt5_PLATFORM}
    Qt5_COMPONENTS ${Qt5_COMPONENTS}
    SOURCES ${SOURCES}

# Android specific parameters
    ANDROID_PLATFORM_LEVEL 28 # override toolchain's value
    ANDROID_ABI x86 #armeabi-v7a
    ANDROID_PACKAGE_NAME "ru.jobquest.FileDialog"
    ANDROID_APP_NAME "File Dialog"
    ANDROID_APP_VERSION 2
    ANDROID_PERMISSIONS
        INTERNET
        ACCESS_NETWORK_STATE
        RECORD_AUDIO
        WAKE_LOCK
        ACCESS_FINE_LOCATION
        WRITE_EXTERNAL_STORAGE
        READ_EXTERNAL_STORAGE
        CAMERA
    ANDROID_INSTALL)


