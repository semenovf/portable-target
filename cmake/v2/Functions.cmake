################################################################################
# Copyright (c) 2019-2023 Vladislav Trifochkin
#
# This file is part of `portable-target`.
#
# Changelog:
#      2020.09.03 Initial version (moved from PortableTarget.cmake)
################################################################################
cmake_minimum_required(VERSION 3.5)

################################################################################
# _portable_target_error
################################################################################
function (_portable_target_error TITLE)
    message(WARN "`_portable_target_error` is DEPRECATED, use `_portable_target_fatal`")

    if (${ARGC} GREATER 1)
        message(FATAL_ERROR "*** ERROR: portable_target [${TITLE}]: ${ARGV1}")
    else()
        message(FATAL_ERROR "*** ERROR: portable_target: ${TITLE}")
    endif()
endfunction(_portable_target_error)

################################################################################
# _portable_target_error
################################################################################
function (_portable_target_fatal TITLE)
    if (${ARGC} GREATER 1)
        message(FATAL_ERROR "*** FATAL: portable_target [${TITLE}]: ${ARGV1}")
    else()
        message(FATAL_ERROR "*** FATAL: portable_target: ${TITLE}")
    endif()
endfunction(_portable_target_fatal)

################################################################################
# _portable_target_warn
################################################################################
function (_portable_target_warn TITLE)
    if (${ARGC} GREATER 1)
        message(WARNING "*** WARN: portable_target [${TITLE}]: ${ARGV1}")
    else()
        message(WARNING "*** WARN: portable_target: ${TITLE}")
    endif()
endfunction(_portable_target_warn)

################################################################################
# _portable_target_status
################################################################################
function (_portable_target_status TITLE)
    if (${ARGC} GREATER 1)
        message(STATUS "portable_target [${TITLE}]: ${ARGV1}")
    else()
        message(STATUS "portable_target: ${TITLE}")
    endif()
endfunction(_portable_target_status)

################################################################################
# _portable_target_trace
#
# To enable/disable trace output use portable_target(SET ENABLE_TRACE ON|OFF)
################################################################################
function (_portable_target_trace TITLE)
    get_property(_enable_trace GLOBAL PROPERTY PORTABLE_TARGET_PROP_ENABLE_TRACE)

    if (_enable_trace)
        if (${ARGC} GREATER 1)
            message(STATUS "portable_target [${TITLE}]: ${ARGV1}")
        else()
            message(STATUS "portable_target: ${TITLE}")
        endif()
    endif()
endfunction(_portable_target_trace)

################################################################################
# _portable_apk_error
################################################################################
# DEPRECATED use _portable_target_error
function (_portable_apk_error TITLE)
    message(WARN "`_portable_apk_error` is DEPRECATED, use `_portable_target_fatal`")

    if (${ARGC} GREATER 1)
        message(FATAL_ERROR "*** ERROR: portable_apk [${TITLE}]: ${ARGV1}")
    else()
        message(FATAL_ERROR "*** ERROR: portable_apk: ${TITLE}")
    endif()
endfunction()

################################################################################
# _portable_apk_warn
################################################################################
# DEPRECATED use _portable_target_warn
function (_portable_apk_warn TITLE)
    message(WARN "`_portable_apk_warn` is DEPRECATED, use `_portable_target_warn`")

    if (${ARGC} GREATER 1)
        message(WARNING "*** WARN: : portable_apk [${TITLE}]: ${ARGV1}")
    else()
        message(WARNING "*** WARN: : portable_apk: ${TITLE}")
    endif()

endfunction()

################################################################################
# _portable_apk_status
################################################################################
# DEPRECATED use _portable_target_status
function (_portable_apk_status TARGET TEXT)
    message(WARN "`_portable_apk_status` is DEPRECATED, use `_portable_target_status`")

    if (${ARGC} GREATER 1)
        message(STATUS "portable_apk [${TARGET}]: ${TEXT}")
    else()
        message(STATUS "portable_apk: ${TARGET}")
    endif()
endfunction()

################################################################################
# _mandatory_var_env
#
# Checks variable <VAR> is set. And if not will be attempt to set value from
#      * <VAR_BASE_NAME>
#      * PORTABLE_TARGET_<VAR_BASE_NAME>
#      * ENV{<VAR_BASE_NAME>}
#      * ENV{PORTABLE_TARGET_<VAR_BASE_NAME>}
#
# Usage:
#   _mandatory_var_env(VAR VAR_BASE_NAME "Var description" [DEFAULT_VALUE])
################################################################################
function (_mandatory_var_env _var _var_base_name _var_desc)
    if (NOT DEFINED ${_var})
        if (DEFINED ${_var_base_name})
            set(_local_var ${${_var_base_name}})
        elseif (DEFINED PORTABLE_TARGET_${_var_base_name})
            set(_local_var ${PORTABLE_TARGET_${_var_base_name}})
        elseif (DEFINED ENV{PORTABLE_TARGET_${_var_base_name}})
            set(_local_var $ENV{PORTABLE_TARGET_${_var_base_name}})
        elseif (DEFINED ENV{${_var_base_name}})
            set(_local_var $ENV{${_var_base_name}})
        elseif (${ARGC} GREATER 3)
            set(_local_var ${ARGV3})
        endif()

        if (NOT DEFINED _local_var)
            message(FATAL_ERROR
                "*** ERROR: portable_target: ${_var_desc} must be specified!\n"
                "    It can be set in one of the ways:\n"
                "        * pass `${_var_base_name}` as parameter for function\n"
                "        * `${_var_base_name}` or `PORTABLE_TARGET_${_var_base_name}` parent level variable\n"
                "        * `${_var_base_name}` or `PORTABLE_TARGET_${_var_base_name}` environment variable")
        endif()

        set(${_var} ${_local_var} PARENT_SCOPE)
        set(PORTABLE_TARGET_${_var_base_name} ${_local_var} CACHE STRING "PORTABLE_TARGET_${_var_base_name}")
   endif()
endfunction()

################################################################################
# _optional_var_env
#
# Usage:
#   _optional_var_env(VAR VAR_BASE_NAME)
################################################################################
function (_optional_var_env _var _var_base_name)
    if (NOT DEFINED ${_var})
        if (DEFINED ${_var_base_name})
            set(_local_var ${${_var_base_name}})
        elseif (DEFINED PORTABLE_TARGET_${_var_base_name})
            set(_local_var ${PORTABLE_TARGET_${_var_base_name}})
        elseif (DEFINED ENV{PORTABLE_TARGET_${_var_base_name}})
            set(_local_var $ENV{PORTABLE_TARGET_${_var_base_name}})
        elseif (DEFINED ENV{${_var_base_name}})
            set(_local_var $ENV{${_var_base_name}})
        endif()

        if (_local_var)
            set(${_var} ${_local_var} PARENT_SCOPE)
            set(PORTABLE_TARGET_${_var_base_name} ${_local_var} CACHE STRING "PORTABLE_TARGET_${_var_base_name}")
        endif()
   endif()
endfunction()
