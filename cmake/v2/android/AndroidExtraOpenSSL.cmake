################################################################################
# Copyright (c) 2019-2022 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.03.06 Initial version (inspired from github.com/KDAB/android_openssl/CMakeLists.txt)
################################################################################
cmake_minimum_required(VERSION 3.5)
include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

# if (CMAKE_BUILD_TYPE STREQUAL "Debug")
#     set (SSL_ROOT_PATH ${CMAKE_CURRENT_LIST_DIR}/no-asm)
# else()
#     set (SSL_ROOT_PATH ${CMAKE_CURRENT_LIST_DIR})
# endif()

################################################################################
# _portable_android_openssl
#
# Usage:
#   portable_android_openssl(SSL_ROOT_PATH ANDROID_SSL_LIBS)
################################################################################
function (_portable_android_openssl SSL_ROOT_PATH QT_VERSION ANDROID_TARGET_ARCH ANDROID_SSL_LIBS)

    if (NOT EXISTS ${SSL_ROOT_PATH})
        _portable_target_error("SSL for Android root path not found: ${SSL_ROOT_PATH}")
    endif()

    if (${QT_VERSION} VERSION_LESS 5.12.4)
        #_portable_target_status("Qt version is less than 5.12.4")

        if (${ANDROID_TARGET_ARCH} STREQUAL "armeabi-v7a")
            set(_android_ssl_libs
                ${SSL_ROOT_PATH}/Qt-5.12.3/arm/libcrypto.so
                ${SSL_ROOT_PATH}/Qt-5.12.3/arm/libssl.so)
        elseif (${ANDROID_TARGET_ARCH} STREQUAL "arm64-v8a")
            set(_android_ssl_libs
                ${SSL_ROOT_PATH}/Qt-5.12.3/arm64/libcrypto.so
                ${SSL_ROOT_PATH}/Qt-5.12.3/arm64/libssl.so)
        elseif (${ANDROID_TARGET_ARCH} STREQUAL "x86")
            set(_android_ssl_libs
                ${SSL_ROOT_PATH}/Qt-5.12.3/x86/libcrypto.so
                ${SSL_ROOT_PATH}/Qt-5.12.3/x86/libssl.so)
        else()
            _portable_target_error("No Android target architecture matches: ${ANDROID_TARGET_ARCH}")
        endif()
    else()
        #_portable_target_status("Qt version is greater or equals to 5.12.4")

        if (${QT_VERSION} VERSION_EQUAL 5.12.4 OR ${QT_VERSION} VERSION_EQUAL 5.13.0)
            #_portable_target_status("Qt version is 5.12.4 or 5.13.0")
            if (${ANDROID_TARGET_ARCH} STREQUAL "armeabi-v7a")
                set(_android_ssl_libs
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/arm/libcrypto.so
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/arm/libssl.so)
            elseif (${ANDROID_TARGET_ARCH} STREQUAL "arm64-v8a")
                set(_android_ssl_libs
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/arm64/libcrypto.so
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/arm64/libssl.so)
            elseif (${ANDROID_TARGET_ARCH} STREQUAL "x86")
                set(_android_ssl_libs
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/x86/libcrypto.so
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/x86/libssl.so)
            elseif (${ANDROID_TARGET_ARCH} STREQUAL "x86_64")
                set(_android_ssl_libs
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/x86_64/libcrypto.so
                    ${SSL_ROOT_PATH}/Qt-5.12.4_5.13.0/x86_64/libssl.so)
            else()
                _portable_target_error("No Android target architecture matches: ${ANDROID_TARGET_ARCH}")
            endif()
        else()
            #_portable_target_status("Qt version is no 5.12.4 or 5.13.0")
            if (NOT (${QT_VERSION} VERSION_LESS 5.14.0))
                #_portable_target_status("Qt version is not less than 5.14.0")
                set(_android_ssl_libs
                    ${SSL_ROOT_PATH}/latest/arm/libcrypto_1_1.so
                    ${SSL_ROOT_PATH}/latest/arm/libssl_1_1.so
                    ${SSL_ROOT_PATH}/latest/arm64/libcrypto_1_1.so
                    ${SSL_ROOT_PATH}/latest/arm64/libssl_1_1.so
                    ${SSL_ROOT_PATH}/latest/x86/libcrypto_1_1.so
                    ${SSL_ROOT_PATH}/latest/x86/libssl_1_1.so
                    ${SSL_ROOT_PATH}/latest/x86_64/libcrypto_1_1.so
                    ${SSL_ROOT_PATH}/latest/x86_64/libssl_1_1.so)
            else()
                #_portable_target_status("Qt version is less than 5.14.0")
                if (${ANDROID_TARGET_ARCH} STREQUAL "armeabi-v7a")
                    set(_android_ssl_libs
                        ${SSL_ROOT_PATH}/latest/arm/libcrypto_1_1.so
                        ${SSL_ROOT_PATH}/latest/arm/libssl_1_1.so)
                elseif (${ANDROID_TARGET_ARCH} STREQUAL "arm64-v8a")
                    set(_android_ssl_libs
                        ${SSL_ROOT_PATH}/latest/arm64/libcrypto_1_1.so
                        ${SSL_ROOT_PATH}/latest/arm64/libssl_1_1.so)
                elseif (${ANDROID_TARGET_ARCH} STREQUAL "x86")
                    set(_android_ssl_libs
                        ${SSL_ROOT_PATH}/latest/x86/libcrypto_1_1.so
                        ${SSL_ROOT_PATH}/latest/x86/libssl_1_1.so)
                elseif (${ANDROID_TARGET_ARCH} STREQUAL "x86_64")
                    set(_android_ssl_libs
                        ${SSL_ROOT_PATH}/latest/x86_64/libcrypto_1_1.so
                        ${SSL_ROOT_PATH}/latest/x86_64/libssl_1_1.so)
                else()
                    _portable_target_error("No Android target architecture matches: ${ANDROID_TARGET_ARCH}")
                endif()
            endif()
        endif()
    endif()

    if (NOT DEFINED _android_ssl_libs)
        _portable_target_error("No Android extra SSL libraries found")
    else()
        #_portable_target_status("Android SSL libs found: ${ANDROID_SSL_LIBS}")
#         _portable_target_error("Android SSL libs found: ${_android_ssl_libs}")
        set(${ANDROID_SSL_LIBS} ${_android_ssl_libs} PARENT_SCOPE)
    endif()

endfunction()
