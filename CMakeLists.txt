cmake_minimum_required (VERSION 3.5)
add_subdirectory(demo/android-qt)

if (NOT ANDROID)
    add_subdirectory(demo/aggressive_check)
endif()
