################################################################################
# Copyright (c) 2021 Vladislav Trifochkin
#
# Changelog:
#      2021.11.17 Initial version.
#      2021.11.29 Renamed variables.
################################################################################
cmake_minimum_required (VERSION 3.5)

if (NOT TARGET rocksdb)
    find_library(PFS_ROCKSDB__LIBRARY rocksdb)

    if (NOT PFS_ROCKSDB__LIBRARY AND EXISTS ${PFS_ROCKSDB__ROOT}/CMakeLists.txt)

        #
        # https://github.com/facebook/rocksdb/blob/main/INSTALL.md
        #
        set(ROCKSDB_BUILD_SHARED ON CACHE BOOL "Build RocksDB as shared")
        set(WITH_GFLAGS OFF CACHE BOOL "Disable 'gflags' dependency for RocksDB")
        set(WITH_TESTS OFF CACHE BOOL "Disable build tests for RocksDB")
        set(WITH_BENCHMARK_TOOLS OFF CACHE BOOL "Disable build benchmarks for RocksDB")
        set(WITH_CORE_TOOLS OFF CACHE BOOL "Disable build core tools for RocksDB")
        set(WITH_TOOLS OFF CACHE BOOL "Disable build tools for RocksDB")
        #set(FAIL_ON_WARNINGS OFF CACHE BOOL "Disable process warnings as errors for RocksDB")

        # Disable error for g++ 11.2.0 (RocksDB v6.25.3)
        # error: ‘hostname_buf’ may be used uninitialized [-Werror=maybe-uninitialized]
        if (CMAKE_COMPILER_IS_GNUCXX)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-maybe-uninitialized")
        endif()

        add_subdirectory(${PFS_ROCKSDB__ROOT} rocksdb)
        set(PFS_ROCKSDB__LIBRARY rocksdb)
        set(PFS_ROCKSDB__INCLUDE ${PFS_ROCKSDB__ROOT}/include)
    endif()
else()
    set(PFS_ROCKSDB__LIBRARY rocksdb)
endif()
