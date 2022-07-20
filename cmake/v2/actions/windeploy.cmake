################################################################################
# Copyright (c) 2021,2022 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.04.30 Initial version.
#      2022.07.20 Initial version (v2).
################################################################################
cmake_minimum_required(VERSION 3.11)
include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

# Helper sources:
# [Qt for Windows - Deployment](https://doc.qt.io/qt-5/windows-deployment.html)
# [Deploying Qt WebEngine Applications](https://doc.qt.io/qt-5/qtwebengine-deploying.html)
# [WinDeployQt.cmake](https://github.com/equalsraf/neovim-qt/blob/master/cmake/WinDeployQt.cmake)
# [Using windeployqt with CPack](https://blog.nathanosman.com/2017/11/24/using-windeployqt-with-cpack.html)

function (portable_target_windeploy PRE_BUILD_TARGET)
    set(LOG_PREFIX ${PRE_BUILD_TARGET})

    set(boolparm
        WINDEPLOYQT
        VERBOSE                # Affects windeployqt --verbose option
        NO_COMPILER_RUNTIME    # Affects windeployqt --compiler-runtime option
        INSTALL_SYSTEM_RUNTIME # Distribute the run time libraries from Microsoft
    )

    set(singleparm
        INSTALL_DESTINATION
        INSTALL_COMPONENT
        WINDEPLOYQT_EXECUTABLE
        WINDEPLOYQT_OUTPUT_DIR  # Affects windeployqt --dir option
        #WINDEPLOYQT_QML_DIR    # Affects windeployqt --qmldir option
    )

    set(multiparm
        TARGETS
        WINDEPLOYQT_EXTRA_LIBS
        WINDEPLOYQT_QML_MODULES)

    if (_arg_INSTALL_SYSTEM_RUNTIME)
        # set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
        include(InstallRequiredSystemLibraries)
    endif()

    # Parse the macro arguments
    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_TARGETS)
        _portable_target_error(${LOG_PREFIX} "no TARGETS specified")
    endif()

    if (NOT _arg_INSTALL_DESTINATION)
        _portable_target_error(${LOG_PREFIX} "no INSTALL_DESTINATION specified")
    endif()

    ############################################################################
    # Configure windeployqt
    ############################################################################
    # windeployqt options:
    #  --dir <directory>         Use directory instead of binary directory.
    #  --libdir <path>           Copy libraries to path.
    #  --plugindir <path>        Copy plugins to path.
    #  --debug                   Assume debug binaries.
    #  --release                 Assume release binaries.
    #  --pdb                     Deploy .pdb files (MSVC).
    #  --force                   Force updating files.
    #  --dry-run                 Simulation mode. Behave normally, but do not
    #                            copy/update any files.
    #  --no-patchqt              Do not patch the Qt5Core library.
    #  --no-plugins              Skip plugin deployment.
    #  --no-libraries            Skip library deployment.
    #  --qmldir <directory>      Scan for QML-imports starting from directory.
    #  --qmlimport <directory>   Add the given path to the QML module search
    #                            locations.
    #  --no-quick-import         Skip deployment of Qt Quick imports.
    #  --no-translations         Skip deployment of translations.
    #  --no-system-d3d-compiler  Skip deployment of the system D3D compiler.
    #  --compiler-runtime        Deploy compiler runtime (Desktop only).
    #  --no-virtualkeyboard      Disable deployment of the Virtual Keyboard.
    #  --no-compiler-runtime     Do not deploy compiler runtime (Desktop only).
    #  --webkit2                 Deployment of WebKit2 (web process).
    #  --no-webkit2              Skip deployment of WebKit2.
    #  --json                    Print to stdout in JSON format.
    #  --angle                   Force deployment of ANGLE.
    #  --no-angle                Disable deployment of ANGLE.
    #  --no-opengl-sw            Do not deploy the software rasterizer library.
    #  --list <option>           Print only the names of the files copied.
    #                            Available options:
    #                             source:   absolute path of the source files
    #                             target:   absolute path of the target files
    #                             relative: paths of the target files, relative
    #                                       to the target directory
    #                             mapping:  outputs the source and the relative
    #                                       target, suitable for use within an
    #                                       Appx mapping file
    #  --verbose <level>         Verbose level (0-2).
    #
    # Qt5 modules (valid names to use with windeployqt)
    # bluetooth concurrent core declarative designer designercomponents enginio
    # gamepad gui qthelp multimedia multimediawidgets multimediaquick network nfc
    # opengl positioning printsupport qml qmltooling quick quickparticles quickwidgets
    # script scripttools sensors serialport sql svg test webkit webkitwidgets
    # websockets widgets winextras xml xmlpatterns webenginecore webengine
    # webenginewidgets 3dcore 3drenderer 3dquick 3dquickrenderer 3dinput 3danimation
    # 3dextras geoservices webchannel texttospeech serialbus webview
    #
    # windeployqt --qmldir . --release --force --gui --network --qml --quick --webchannel
    #   --webengine --webenginewidgets --widgets --positioning --sql --serialport
    #   --multimedia TacticalPad2Bin.exe
    #

    if (_arg_WINDEPLOYQT_EXECUTABLE
            OR _arg_WINDEPLOYQT
            OR _arg_WINDEPLOYQT_OUTPUT_DIR
            OR _arg_WINDEPLOYQT_EXTRA_LIBS
            OR _arg_WINDEPLOYQT_QML_MODULES)
        set(_arg_WINDEPLOYQT TRUE)
    endif()

    if (_arg_WINDEPLOYQT)
        if (NOT _arg_WINDEPLOYQT_EXECUTABLE)
            _mandatory_var_env(Qt5_ROOT
                Qt5_ROOT
                "Qt5 Root directory")

            _mandatory_var_env(Qt5_PLATFORM
                Qt5_PLATFORM
                "Qt5 Platform directory")

            set(_arg_WINDEPLOYQT_EXECUTABLE "${Qt5_ROOT}/${Qt5_PLATFORM}/bin/windeployqt.exe")
            set(Qt5_BIN_DIR "${Qt5_ROOT}/${Qt5_PLATFORM}/bin")
        else()
            get_filename_component(Qt5_BIN_DIR ${_arg_WINDEPLOYQT_EXECUTABLE} DIRECTORY)
        endif()

        if (NOT EXISTS ${_arg_WINDEPLOYQT_EXECUTABLE})
            _portable_target_error(${LOG_PREFIX} "'windeployqt' not found at: ${_arg_WINDEPLOYQT_EXECUTABLE}")
        else()
            _portable_target_status(${LOG_PREFIX} "'windeployqt' found at: ${_arg_WINDEPLOYQT_EXECUTABLE}")
        endif()

        if (CMAKE_BUILD_TYPE STREQUAL "Release")
            list(APPEND _windeployqt_args --release)
        else ()
            # NOTE --release-with-debug-info is OBSOLETE in latest Qt5 distributions
		    list(APPEND _windeployqt_args --debug)
	    endif()

        if (_arg_VERBOSE)
            list(APPEND _windeployqt_args --verbose 2)
        endif()

        if (NOT _arg_NO_COMPILER_RUNTIME)
            # vc_redist[.x64].exe will be deployed
            list(APPEND _windeployqt_args "--compiler-runtime")
        endif()

        # WINDEPLOYQT_EXTRA_LIBS used especially as workaround when windeployqt
        # do not properly obtains MultimediaQuick
        if (_arg_WINDEPLOYQT_EXTRA_LIBS)
            if (CMAKE_BUILD_TYPE STREQUAL "Release")
                set(_qt_extra_lib_suffix "")
            else()
                set(_qt_extra_lib_suffix "d")
            endif()

            foreach (_qt_extra_lib ${_arg_WINDEPLOYQT_EXTRA_LIBS})
                set(_qt_extra_lib_path "${Qt5_BIN_DIR}/Qt5${_qt_extra_lib}${_qt_extra_lib_suffix}.dll")

                if (NOT EXISTS ${_qt_extra_lib_path})
                    set(_qt_extra_lib_path "${Qt5_BIN_DIR}/Qt5${_qt_extra_lib}${_qt_extra_lib_suffix}_p.dll")

                    if (NOT EXISTS ${_qt_extra_lib_path})
                        _portable_target_error(${LOG_PREFIX} "${_qt_extra_lib}: no corresponding library found at: ${Qt5_BIN_DIR}")
                    endif()
                endif()

                add_custom_command(TARGET ${PRE_BUILD_TARGET}
                    PRE_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory "${_arg_WINDEPLOYQT_OUTPUT_DIR}"
                    COMMAND ${CMAKE_COMMAND} -E copy "${_qt_extra_lib_path}" "${_arg_WINDEPLOYQT_OUTPUT_DIR}")
            endforeach()
        endif()

        # Do not work properly (workaround see below)
        #if (_arg_WINDEPLOYQT_QML_DIR)
        #    list(APPEND _windeployqt_args --qmldir "${_arg_WINDEPLOYQT_QML_DIR}")
        #endif()

        if (_arg_WINDEPLOYQT_QML_MODULES)
            set(_qml_dir "${Qt5_BIN_DIR}/../qml")

            if (NOT EXISTS ${_qml_dir})
                _portable_target_error(${LOG_PREFIX} "QML directory not found at: ${_qml_dir}")
            endif()

            foreach (_qml_module ${_arg_WINDEPLOYQT_QML_MODULES})
                #set(_qml_dll_excludes "")

                # Collect unnecessary DLLs for later removing
                file(GLOB_RECURSE _qml_dlls LIST_DIRECTORIES false
                    RELATIVE ${_qml_dir}/${_qml_module}
                    "${_qml_dir}/${_qml_module}/*.dll")

                foreach (_qml_dll ${_qml_dlls})
                    get_filename_component(_qml_dll_filename ${_qml_dll} NAME_WLE)
                    get_filename_component(_qml_dll_subdir ${_qml_dll} DIRECTORY)

                    if (EXISTS "${_qml_dir}/${_qml_module}/${_qml_dll_subdir}/${_qml_dll_filename}d.dll")
                        if (CMAKE_BUILD_TYPE STREQUAL "Release")
                            set(_qml_dll_excludes "${_qml_dll_excludes} \"${_arg_WINDEPLOYQT_OUTPUT_DIR}/qml/${_qml_module}/${_qml_dll_subdir}/${_qml_dll_filename}d.dll\"")
                        else()
                            set(_qml_dll_excludes "${_qml_dll_excludes} \"${_arg_WINDEPLOYQT_OUTPUT_DIR}/qml/${_qml_module}/${_qml_dll_subdir}/${_qml_dll_filename}.dll\"")
                        endif()
                    endif()
                endforeach()

                add_custom_command(TARGET ${PRE_BUILD_TARGET}
                    PRE_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory "${_arg_WINDEPLOYQT_OUTPUT_DIR}"
                    COMMAND ${CMAKE_COMMAND} -E copy_directory "${_qml_dir}/${_qml_module}"
                        "${_arg_WINDEPLOYQT_OUTPUT_DIR}/qml/${_qml_module}")

                if (_qml_dll_excludes)
                    add_custom_command(TARGET ${PRE_BUILD_TARGET}
                        PRE_BUILD
                        COMMAND ${CMAKE_COMMAND} -E remove ${_qml_dll_excludes})
                endif()
            endforeach()
        endif()

        foreach (_target ${_arg_TARGETS})
            LIST(APPEND _windeployqt_files "$<TARGET_FILE:${_target}>")
        endforeach()

        if (NOT _arg_WINDEPLOYQT_OUTPUT_DIR)
            set(_arg_WINDEPLOYQT_OUTPUT_DIR "${CMAKE_BINARY_DIR}/WINDEPLOYQT")
        endif()

        add_custom_command(TARGET ${PRE_BUILD_TARGET}
            PRE_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_arg_WINDEPLOYQT_OUTPUT_DIR}"
            COMMAND ${_arg_WINDEPLOYQT_EXECUTABLE}
                ${_windeployqt_args}
                --dir "${_arg_WINDEPLOYQT_OUTPUT_DIR}"
                ${_windeployqt_files})

    endif(_arg_WINDEPLOYQT)

    # Copy deployment directory during installation
   install(DIRECTORY
       "${_arg_WINDEPLOYQT_OUTPUT_DIR}/"   # Trailing slash spicifies copying only content of directory
       DESTINATION ${_arg_INSTALL_DESTINATION}
       COMPONENT ${_arg_INSTALL_COMPONENT}
   )

endfunction()
