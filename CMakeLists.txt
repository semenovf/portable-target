cmake_minimum_required (VERSION 3.5)
project(portable-target-ALL)

add_subdirectory(demo/android-qt)
add_subdirectory(demo/v2/executable)
#add_subdirectory(demo/v2/translation)

if (NOT ANDROID)
#    add_subdirectory(demo/aggressive_check)
endif()
