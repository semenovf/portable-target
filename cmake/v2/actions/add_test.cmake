################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2021.12.10 Initial version.
###############################################################################
cmake_minimum_required(VERSION 3.11)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions.cmake)

#
# Usage:
#
# portable_target_add_test(TARGET
#       SOURCES sources...
#       [LINK libs...]
#       [ENV env]
#       [ENABLE_COVERAGE ON | OFF])
#
# ENV env
#       Set environment variables (see `set_tests_properties`).
#
function (portable_target_add_test TARGET)
    _portable_target_set_properties_defaults()

    set(boolparm)
    set(singleparm ENABLE_COVERAGE ENV)
    set(multiparm SOURCES LINK)

    cmake_parse_arguments(_arg "${boolparm}" "${singleparm}" "${multiparm}" ${ARGN})

    if (NOT _arg_SOURCES)
        _portable_target_error(${TARGET} "No sources specified for tests")
    endif()

    add_executable(${TARGET})

    if (_arg_ENABLE_COVERAGE)
        include(${CMAKE_CURRENT_LIST_DIR}/../Coverage.cmake)

        # https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#Instrumentation-Options
        #
        # --coverage
        #       This option is used to compile and link code instrumented for
        #       coverage analysis. The option is a synonym for -fprofile-arcs
        #       -ftest-coverage (when compiling) and -lgcov (when linking).
        target_compile_options(${TARGET} PRIVATE -g -O0 --coverage)
        target_link_libraries(${TARGET} PRIVATE -g -O0 --coverage)

        coverage_target("'/usr/*';'*/doctest.h'")
    endif()

    target_sources(${TARGET} PRIVATE ${_arg_SOURCES})

    if (_arg_LINK)
        target_link_libraries(${TARGET} PRIVATE ${_arg_LINK})
    endif()

    add_test(NAME ${TARGET} COMMAND ${TARGET})

    if (MSVC)
        if (_arg_LINK)
            foreach(_lib ${_arg_LINK})
                if (TARGET ${_lib})
                    get_target_property(_lib_type ${_lib} TYPE)

                    if (_lib_type STREQUAL "SHARED_LIBRARY")
                        if (NOT _path_env)
                            set(_path_env "$<TARGET_FILE_DIR:${_lib}>")
                        else()
                            set(_path_env "${_path_env};$<TARGET_FILE_DIR:${_lib}>")
                        endif()
                    endif()
                endif()
            endforeach()

            if (_path_env)
                set(_path_env "PATH=${_path_env}\\;%PATH%")
                set_tests_properties(${TARGET} PROPERTIES ENVIRONMENT "${_path_env}")
            endif()
        endif()
    endif()

#    if (_arg_ENV)
#        set_tests_properties(${TARGET} PROPERTIES ENVIRONMENT ${_arg_ENV})
#    endif()
endfunction(portable_target_add_test)
