<style type="text/css" rel="stylesheet">
.warning { color: black; background-color: #FFE0B2; padding: 0.5em; border-left: solid 0.5em #FF6F00; font-family: monospace;}

.info { color: black; background-color: #C8E6C9; padding: 0.5em; border-left: solid 0.5em #388E3C; font-family: monospace;}

.error { color: black; background-color: #FFCDD2; padding: 0.5em; border-left: solid 0.5em #D32F2F; font-family: monospace;}
</style>

# portable-target
CMake-based scripts for build portable applications.
Tested on Linux, Windows, Android

## Android
### Warnings and errors while build and package

1.
```sh
Warning: QML import could not be resolved in any of the import paths: Material
```

<p class="warning">
No ideas for reslolve it yet.
</p>
<p class="info">
No critical influence on the result was found.
</p>

2.
```sh
...
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
.../Android/Sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip: error: unknown argument '-strip-all'
...
```

<p class="error">
This is error in sources of `androiddeployqt` prior to version `Qt 5.12.9`
</p>
<p class="info">
No critical influence on the result was found.
</p>

3.
```sh
NDK is missing a "platforms" directory.
If you are using NDK, verify the ndk.dir is set to a valid NDK directory. It is currently set to .../Android/Sdk/ndk-bundle.
If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning.
```
<p class="warning">
No ideas for reslolve it yet.
</p>
<p class="info">
No critical influence on the result was found.
</p>
