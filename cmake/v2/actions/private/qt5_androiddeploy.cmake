################################################################################
# Copyright (c) 2021-2023 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2023.06.09 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)

function (qt5a_jar_implementations _qt5_dir _qt5_components _result)
    list(JOIN _qt5_components " " _qt5_components_str)

    get_filename_component(_qt5_jar_dir "${_qt5_dir}/../../../jar" ABSOLUTE)

    list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroid.jar')\n")
    list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidExtras.jar')\n")

    if (${_qt5_components_str} MATCHES "Network")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidNetwork.jar')\n")
    endif()

    list(JOIN _deps "" _deps)

    set(${_result} ${_deps} PARENT_SCOPE)
endfunction(qt5a_jar_implementations)

function (qt5a_begin_libs_xml _xml_file)
    file(WRITE  ${_xml_file} "<resources>\n")
endfunction(qt5a_begin_libs_xml)

function (qt5a_end_libs_xml _xml_file)
    file(APPEND ${_xml_file} "</resources>\n")
endfunction(qt5a_end_libs_xml)

function (qt5a_add_bundled_libs_xml _xml_file _target _deps)
    file(APPEND ${_xml_file} "    <array name=\"bundled_libs\">\n")
    file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};${_target}_${ANDROID_ABI}</item>\n")

    foreach (_dep ${_deps})
        file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};${_dep}</item>\n")
    endforeach()

    file(APPEND ${_xml_file} "    </array>\n\n")
endfunction(qt5a_add_bundled_libs_xml)

function (qt5a_add_qt5_libs_xml _xml_file _qt5_components)
    file(APPEND ${_xml_file} "    <array name=\"qt_libs\">\n")
    file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};c++_shared</item>\n")

    foreach (_qt_comp ${_qt5_components})
        string(SUBSTRING ${_qt_comp} 5 -1 _qt_comp)
        file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};Qt5${_qt_comp}_${ANDROID_ABI}</item>\n")
    endforeach()

    file(APPEND ${_xml_file} "    </array>\n\n")

    file(APPEND ${_xml_file} "    <array name=\"load_local_libs\">\n")

    file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};libplugins_platforms_qtforandroid_${ANDROID_ABI}.so</item>\n")
# #         <item>x86;libplugins_platforms_qtforandroid_x86.so:libplugins_bearer_qandroidbearer_x86.so:libplugins_mediaservice_qtmedia_android_x86.so:libQt5MultimediaQuick_x86.so:libplugins_position_qtposition_android_x86.so:libplugins_sensors_qtsensors_android_x86.so:libplugins_webview_qtwebview_android_x86.so</item>

    file(APPEND ${_xml_file} "    </array>\n")
endfunction(qt5a_add_qt5_libs_xml)

function (qt5a_copy_qt5_libs _qt5_dir _jni_libs_dir _qt5_components)
    get_filename_component(_qt5_libs_dir "${_qt5_dir}/../../../lib" ABSOLUTE)

    # QtQuick dependency
    if ("${_qt5_components}" MATCHES "Qt5::Quick" )
        set(_qt5_components "${_qt5_components};Qt5::QmlWorkerScript")
    endif()

    foreach (_qt_comp ${_qt5_components})
        string(SUBSTRING ${_qt_comp} 5 -1 _qt_comp)
        file(CREATE_LINK
            "${_qt5_libs_dir}/libQt5${_qt_comp}_${ANDROID_ABI}.so"
            "${_jni_libs_dir}/libQt5${_qt_comp}_${ANDROID_ABI}.so"
            SYMBOLIC)
    endforeach()
endfunction(qt5a_copy_qt5_libs)

function (qt5a_copy_qt5_plugins _qt5_dir _jni_libs_dir _qt5_components)
    get_filename_component(_qt5_plugins_dir "${_qt5_dir}/../../../plugins" ABSOLUTE)

    file(CREATE_LINK
        "${_qt5_plugins_dir}/platforms/libplugins_platforms_qtforandroid_${ANDROID_ABI}.so"
        "${_jni_libs_dir}/libplugins_platforms_qtforandroid_${ANDROID_ABI}.so"
        SYMBOLIC)

    # FIXME Must be configurable
    set(_qt5_plugins_paths
        "${_qt5_plugins_dir}/../qml/QtQuick.2/libqml_QtQuick.2_qtquick2plugin_${ANDROID_ABI}.so"
        "${_qt5_plugins_dir}/../qml/QtQuick/Window.2/libqml_QtQuick_Window.2_windowplugin_${ANDROID_ABI}.so")

    foreach (_p ${_qt5_plugins_paths})
        if (NOT EXISTS ${_p})
            _portable_target_fatal("Qt5 plugin not found: ${_p}.")
        endif()

        get_filename_component(_name ${_p} NAME)
        file(CREATE_LINK "${_p}" "${_jni_libs_dir}/${_name}" SYMBOLIC)
    endforeach()

endfunction(qt5a_copy_qt5_plugins)
