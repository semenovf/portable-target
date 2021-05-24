# portable-target
CMake-based scripts for build portable applications.
Tested on Linux, Windows, Android

## Android
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
