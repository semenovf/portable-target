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
cmake_minimum_required (VERSION 3.11)
project(FileDialog CXX C)

# Set ON if need add current directory to list of directories to be searched
# for header files during preprocessing
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(${CMAKE_SOURCE_DIR}/cmake/v2/PortableTarget.cmake)

portable_target(ADD_EXECUTABLE ${PROJECT_NAME})
portable_target(SOURCES ${PROJECT_NAME} main.cpp main.qrc)
portable_target(LINK_QT5_COMPONENTS ${PROJECT_NAME} Core Gui Network Qml)

if (ANDROID)
portable_target(BUILD_APK ${PROJECT_NAME}
        VERBOSE ON
        #INSTALL ON
        PACKAGE_NAME "ru.jobquest.${PROJECT_NAME}"
        APP_NAME "File Dialog"
        VERSION_MAJOR 2
        VERSION_MINOR 0
        SCREEN_ORIENTATION "sensorLandscape"
        CONFIG_CHANGES="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|locale|fontScale|keyboard|keyboardHidden|navigation"
        PERMISSIONS
            INTERNET
            ACCESS_NETWORK_STATE
            WAKE_LOCK
            ACCESS_FINE_LOCATION
            WRITE_EXTERNAL_STORAGE
            READ_EXTERNAL_STORAGE)
endif(ANDROID)