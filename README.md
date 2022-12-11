# portable-target
CMake-based scripts for build portable applications.
Tested on Linux, Windows, Android

# Common requirements

## Linux

Below steps demonstrates working configuration

```sh
$ sudo apt install cmake

# Used by Ninja build system generator.
$ sudo apt install ninja-build
```

# Android development

## Requirements

### Ubuntu/Debian

1. Install Android SDKs (using Android Studio installer as an option)  
   and NDK version 22.1.xxx (22.1.7171670 e.g.) or NDK (Obsolete) that__ 
   listed in `SDK Tools` (need to off flag `Hide Obsolete Packages` to  
   view all available tools).
2. Install Qt framework 5.13.2 by installer.
3. Install Open JDK: `$ sudo apt-get install openjdk-8-jdk`
4. Set development environment:

```sh
# 1. Set JAVA_HOME environment variable.
# NOTE. Need log out and log in to come into force.
$ echo export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 >> ~/.profile

# 2. Set ANDROID_SDK environment variable
# NOTE. Need log out and log in to come into force.
$ echo export ANDROID_SDK=$HOME/Android/Sdk >> ~/.profile

# 3. Set ANDROID_NDK environment variable (this step can be omitted if
# obsolete NDK was installed and ${ANDROID_SDK} contains not empty
# `ndk-bundle` subdirectory).
# NOTE. Need log out and log in to come into force.
$ echo export ANDROID_NDK=${ANDROID_SDK}/ndk/22.1.xxx >> ~/.profile
```

5. Modify `PATH` in `~/.profile`:
`PATH="$ANDROID_SDK/tools:$ANDROID_SDK/tools/bin:$ANDROID_SDK/platform-tools:$PATH"`

## Building package

### Ubuntu/Debian

```
$ mkdir build
$ cd build
$ ANDROID=ON \
    Qt5_PLATFORM=android_x86_64 \
    Qt5_ROOT=/opt/Qt5.13.2/5.13.2 \
    ANDROID_ABI=x86_64 \
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=../cmake/v2/android/AndroidToolchain.cmake ..
$ cmake --build .
```

## Troubleshooting
### Warnings and errors while building and packaging

1. #### QML import could not be resolved in ...
```sh
Warning: QML import could not be resolved in any of the import paths: Material
```

`No ideas for reslolve it yet.`<br/>
`No critical influence on the result was found.`

2. #### llvm-strip: error: unknown argument '-strip-all'
```sh
...
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
...
```

`This is error in sources of 'androiddeployqt' prior to version Qt 5.12.9`<br/>
`No critical influence on the result was found.`

3. #### NDK is missing a "platforms" directory.
```sh
NDK is missing a "platforms" directory.
If you are using NDK, verify the ndk.dir is set to a valid NDK directory. It is currently set to .../Android/Sdk/ndk-bundle.
If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning.
```
`No ideas for reslolve it yet.`<br/>
`No critical influence on the result was found.`
