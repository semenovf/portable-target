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
   and NDK version 22.1.xxx (22.1.7171670 e.g.) or NDK (Obsolete) that  
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

### Windows

See 
* [Command-line tools](https://developer.android.com/tools) 
* [sdkmanager](https://developer.android.com/tools/sdkmanager)
* [Jetifier](https://developer.android.com/tools/jetifier)

1. Download JDK (e.g. from https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-17).
   Other OpenJDK resources: https://www.openlogic.com/openjdk-downloads, https://jdk.java.net.
2. Download `Command line tools only` from site https://developer.android.com/studio.
3. Download `Jetifier` (https://developer.android.com/tools/jetifier). Optional.
4. Create `android-sdk` directory and unzip archive into it.
5. Cd into `android-sdk\cmdline-tools`, create `latest` subdirectory and move all files and 
   subdirectories into it.
6. Create `env.bat` file to run command line interpreter with environment required for Android 
   development.

```cmd
@echo off
set ANDROID_HOME=c:\android-sdk
set JAVA_HOME=C:\android-sdk\jdk-17.0.11+9
set PATH=C:\Windows\System32;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\tools;%ANDROID_HOME%\tools\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\jetifier-standalone\bin
cmd /Q
```

7. Run `env.bat`
8. Install build tools: `sdkmanager "build-tools;33.0.3"`. Will be downloaded into`%ANDROID_HOME%/build-tools/33.0.3`.
9. Install platform tools: `sdkmanager "platform-tools"`. Will be downloaded into `%ANDROID_HOME%/platform-tools`.
10. Install SDK tools for API level e.g. 33: `sdkmanager "platforms;android-33"`. Will be downloaded into `%ANDROID_HOME%/platforms/android-33`
11. Install NDK: `sdkmanager "ndk;26.3.11579264"`. Will be downloaded into `%ANDROID_HOME%/ndk/26.3.11579264`.
12. Install `cmake`: `sdkmanager "cmake;3.22.1"`. Will be downloaded into `%ANDROID_HOME%/cmake/3.22.1`. 

#### Other useful sdkmanager commands
* List all installed and available packages
```cmd
sdkmanager --list  
```

* List all installed packages
```cmd
sdkmanager --list_installed  

Installed packages:
  Path                 | Version       | Description                      | Location
  -------              | -------       | -------                          | -------
  build-tools;33.0.3   | 33.0.3        | Android SDK Build-Tools 33.0.3   | build-tools\33.0.3
  cmake;3.22.1         | 3.22.1        | CMake 3.22.1                     | cmake\3.22.1
  ndk;26.3.11579264    | 26.3.11579264 | NDK (Side by side) 26.3.11579264 | ndk\26.3.11579264
  platform-tools       | 35.0.1        | Android SDK Platform-Tools       | platform-tools
  platforms;android-33 | 3             | Android SDK Platform 33          | platforms\android-33
```

## Building package

### Ubuntu/Debian

```
$ mkdir build
$ cd build
$ ANDROID=ON \
    QT5_PLATFORM=android_x86 \
    QT5_ROOT=/opt/Qt5.13.2/5.13.2 \
    ANDROID_ABI=x86 \
    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=../cmake/v2/android/AndroidToolchain.cmake ..
$ cmake --build .

# Run emulator and then execute the below command to install package
$ adb install -t -r demo/android-qt/android-build/build/outputs/apk/debug/android-build-debug.apk
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

3. #### Failure [INSTALL_FAILED_TEST_ONLY] while `adb install`
Use `-t` option after `adb install`: `adb install -t -r path-to-package.apk`.  
See [ADB Install Fails With INSTALL_FAILED_TEST_ONLY](https://stackoverflow.com/questions/25274296/adb-install-fails-with-install-failed-test-only)
