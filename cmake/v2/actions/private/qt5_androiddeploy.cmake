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
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidBearer.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "Multimedia")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtMultimedia.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "WebView")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidWebView.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "Positioning")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtPositioning.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "Nfc")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtNfc.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "Gamepad")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidGamepad.jar')\n")
    endif()

    if (${_qt5_components_str} MATCHES "Gamepad")
        list(APPEND _deps "    implementation files('${_qt5_jar_dir}/QtAndroidGamepad.jar')\n")
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

    # foreach (_dep ${_deps})
    #     file(APPEND ${_xml_file} "        <item>${ANDROID_ABI};${_dep}</item>\n")
    # endforeach()

    file(APPEND ${_xml_file} "    </array>\n\n")
endfunction(qt5a_add_bundled_libs_xml)

function (qt5a_add_qt5_libs_xml _xml_file _qt5_components)
    if ("${_qt5_components}" MATCHES "Quick")
        if (NOT "${_qt5_components}" MATCHES "QmlWorkerScript")
            set(_qt5_components "${_qt5_components};Qt5::QmlWorkerScript")
        endif()
    endif()

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
    if ("${_qt5_components}" MATCHES "Quick")
        if (NOT "${_qt5_components}" MATCHES "QmlWorkerScript")
            set(_qt5_components "${_qt5_components};Qt5::QmlWorkerScript")
        endif()
    endif()

    foreach (_qt_comp ${_qt5_components})
        string(SUBSTRING ${_qt_comp} 5 -1 _qt_comp)
        file(CREATE_LINK
            "${_qt5_libs_dir}/libQt5${_qt_comp}_${ANDROID_ABI}.so"
            "${_jni_libs_dir}/libQt5${_qt_comp}_${ANDROID_ABI}.so"
            SYMBOLIC)
    endforeach()
endfunction(qt5a_copy_qt5_libs)

function (qt5a_copy_qt5_plugins _qt5_dir _jni_libs_dir _qt5_components _is_debuggable)
    get_filename_component(_qt5_android_dir "${_qt5_dir}/../../.." ABSOLUTE)
    list(JOIN _qt5_components " " _qt5_components_str)

    if ("${_qt5_components_str}" MATCHES "Qml" )
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/qml/QtQml/libqml_QtQml_qmlplugin_${ANDROID_ABI}.so")
    endif()

    if ("${_qt5_components_str}" MATCHES "Quick" )
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/qml/QtQml/WorkerScript.2/libqml_QtQml_WorkerScript.2_workerscriptplugin_${ANDROID_ABI}.so")
    endif()

    list(APPEND _qt5_plugins_paths
        "${_qt5_android_dir}/plugins/platforms/libplugins_platforms_qtforandroid_${ANDROID_ABI}.so"

        "${_qt5_android_dir}/qml/QtGraphicalEffects/libqml_QtGraphicalEffects_qtgraphicaleffectsplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtGraphicalEffects/private/libqml_QtGraphicalEffects_private_qtgraphicaleffectsprivate_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick.2/libqml_QtQuick.2_qtquick2plugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Controls.2/libqml_QtQuick_Controls.2_qtquickcontrols2plugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Controls.2/Material/libqml_QtQuick_Controls.2_Material_qtquickcontrols2materialstyleplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Dialogs/libqml_QtQuick_Dialogs_dialogplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Dialogs/Private/libqml_QtQuick_Dialogs_Private_dialogsprivateplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Layouts/libqml_QtQuick_Layouts_qquicklayoutsplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Templates.2/libqml_QtQuick_Templates.2_qtquicktemplates2plugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/QtQuick/Window.2/libqml_QtQuick_Window.2_windowplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/Qt/labs/platform/libqml_Qt_labs_platform_qtlabsplatformplugin_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/qml/Qt/labs/folderlistmodel/libqml_Qt_labs_folderlistmodel_qmlfolderlistmodelplugin_${ANDROID_ABI}.so"

        # Image format support plugins
        "${_qt5_android_dir}/plugins/iconengines/libplugins_iconengines_qsvgicon_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qgif_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qicns_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qico_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qjpeg_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qsvg_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qwbmp_${ANDROID_ABI}.so"
        "${_qt5_android_dir}/plugins/imageformats/libplugins_imageformats_qwebp_${ANDROID_ABI}.so")

    if (${_qt5_components_str} MATCHES "Models" )
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/qml/QtQml/Models.2/libqml_QtQml_Models.2_modelsplugin_${ANDROID_ABI}.so")
    endif()

    if (${_qt5_components_str} MATCHES "Multimedia" )
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/qml/QtMultimedia/libqml_QtMultimedia_declarative_multimedia_${ANDROID_ABI}.so")
    endif()

    if (${_qt5_components_str} MATCHES "Network")
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/plugins/bearer/libplugins_bearer_qandroidbearer_${ANDROID_ABI}.so")
    endif()

    # WebView support plugins
    if (${_qt5_components_str} MATCHES "WebView")
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/plugins/webview/libplugins_webview_qtwebview_android_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/qml/QtWebChannel/libqml_QtWebChannel_declarative_webchannel_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/qml/QtWebSockets/libqml_QtWebSockets_declarative_qmlwebsockets_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/qml/QtWebView/libqml_QtWebView_declarative_webview_${ANDROID_ABI}.so")
    endif()

    if (${_qt5_components_str} MATCHES "Positioning")
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/qml/QtPositioning/libqml_QtPositioning_declarative_positioning_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/position/libplugins_position_qtposition_android_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/position/libplugins_position_qtposition_positionpoll_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/position/libplugins_position_qtposition_serialnmea_${ANDROID_ABI}.so")
    endif()


    if (${_is_debuggable})
        list(APPEND _qt5_plugins_paths
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_debugger_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_inspector_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_local_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_messages_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_native_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_nativedebugger_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_preview_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_profiler_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_quickprofiler_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_server_${ANDROID_ABI}.so"
            "${_qt5_android_dir}/plugins/qmltooling/libplugins_qmltooling_qmldbg_tcp_${ANDROID_ABI}.so")
    endif()

    foreach (_p ${_qt5_plugins_paths})
        if (NOT EXISTS ${_p})
            _portable_target_fatal("Qt5 plugin not found: ${_p}.")
        endif()

        get_filename_component(_name ${_p} NAME)
        file(CREATE_LINK "${_p}" "${_jni_libs_dir}/${_name}" SYMBOLIC)
    endforeach()

endfunction(qt5a_copy_qt5_plugins)
