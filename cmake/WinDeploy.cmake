################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of [portable-target](https://github.com/semenovf/portable-target).
#
# Changelog:
#      2021.04.30 Initial version
################################################################################
cmake_minimum_required(VERSION 3.5)
include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/Functions.cmake)

# Helper sources:
# [Qt for Windows - Deployment](https://doc.qt.io/qt-5/windows-deployment.html)
# [Deploying Qt WebEngine Applications](https://doc.qt.io/qt-5/qtwebengine-deploying.html)
# [WinDeployQt.cmake](https://github.com/equalsraf/neovim-qt/blob/master/cmake/WinDeployQt.cmake)
# [Using windeployqt with CPack](https://blog.nathanosman.com/2017/11/24/using-windeployqt-with-cpack.html)

function (portable_windeploy PRE_BUILD_TARGET)
    set(LOG_PREFIX "portable_windeploy")

    set(boolparm
        WINDEPLOYQT
        VERBOSE             # Affects windeployqt --verbose option
        NO_COMPILER_RUNTIME # Affects windeployqt --compiler-runtime option
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
        WINDEPLOYQT_QML_MODULES)

    # TODO Implement later
#    set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
#    include(InstallRequiredSystemLibraries)

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

#        if (_arg_WINDEPLOYQT_QML_DIR)
#            list(APPEND _windeployqt_args --qmldir "${_arg_WINDEPLOYQT_QML_DIR}")
#        endif()

        if (_arg_WINDEPLOYQT_QML_MODULES)
            get_filename_component(_qml_dir ${_arg_WINDEPLOYQT_EXECUTABLE} DIRECTORY)
            set(_qml_dir "${_qml_dir}/../qml")

            if (NOT EXISTS ${_qml_dir})
                _portable_target_error(${LOG_PREFIX} "QML directory not found at: ${_qml_dir}")
            endif()

            foreach (_qml_module ${_arg_WINDEPLOYQT_QML_MODULES})
                add_custom_command(TARGET ${PRE_BUILD_TARGET}
                    PRE_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory "${_arg_WINDEPLOYQT_OUTPUT_DIR}"
                    COMMAND ${CMAKE_COMMAND} -E copy_directory "${_qml_dir}/${_qml_module}" 
                        "${_arg_WINDEPLOYQT_OUTPUT_DIR}/qml/${_qml_module}"
                )
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