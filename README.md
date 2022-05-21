# gxbuild
gxbuild is a build system for applications using C and raylib.

## Features
* Supports building for Windows, Linux, Web and Android
* Uses shell scripts, making it easy to run on all platforms with minimal prior setup
* Automates most of the setup process: installing dependencies, downloading and compiling raylib

## Setting up
1. Change the options in `config.sh` to your liking (app name, compiler flags).
2. If you're on Windows, download [w64devkit](https://github.com/skeeto/w64devkit/releases). Make sure you get a release zip, not the source code. Extract the archive somewhere and run `w64devkit.exe`. On Linux, just open a terminal.
2. Follow the below instructions for the platform you want to build for.

### Desktop
1. Run `./setup.sh` to set up the project.
2. Run `./build.sh` to compile the project.

### Web
1. Run `TARGET=Web ./setup.sh` to set up the project. You will need about 1 GB of free space.
2. Run `TARGET=Web ./build.sh` to compile the project.

### Android
1. Download [Java](https://openjdk.java.net/) and extract it somewhere. On Linux, you can also install Java using a package manager (make sure you get the JDK, not just the JRE).
2. Change the Java path in `config.sh`.
2. Run `TARGET=Android ./setup.sh` to set up the project. You will need about 5 GB of free space.
3. Run `TARGET=Android ./build.sh` to compile the project.

### Compiling for Windows from Linux
1. Install `mingw-w64` using your package manager.
2. Run `TARGET=Windows_NT ./setup.sh` to set up the project.
3. Run `TARGET=Windows_NT ./build.sh` to compile the project.

## Notes
raylib currently has some issues on Web and Android platforms, here I've documented some of the issues I've found when creating the [CaveScroller](https://github.com/gtrxAC/cavescroller) game for the [raylib 5K gamejam](https://itch.io/jam/raylib-5k-gamejam). If you have any other issues, you can also check the raylib issue tracker for [Web](https://github.com/raysan5/raylib/issues?q=is%3Aissue+label%3Ahtml5) and [Android](https://github.com/raysan5/raylib/issues?q=is%3Aissue+label%3Aandroid).

### Web

#### Save/LoadStorageValue
`SaveStorageValue` and `LoadStorageValue` save their values in a `storage.data` file internally managed by raylib. raylib on Web (emscripten) does not have a persistent file system, any files created during the runtime of the application are not saved when the user reloads the page.

However, web browsers have a feature called [local storage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage) which allows saving values persistently. You can add this to your code to allow saving and loading values on Web, just use the `save` and `load` functions like you would use `SaveStorageValue` and `LoadStorageValue`:
```c
#ifdef PLATFORM_WEB
	#include <emscripten/emscripten.h>
	#define save(i, v) emscripten_run_script(TextFormat("localStorage.setItem(\"%d\", %d);", i, v))
	#define load(i) emscripten_run_script_int(TextFormat("localStorage.getItem(\"%d\");", i))
#else
	#define save SaveStorageValue
	#define load LoadStorageValue
#endif
```

### Android

#### File system
Currently the file system is not accessible on Android. Trying to load any file outside the assets folder results in `Failed to open file`. This means that any user created files cannot be loaded, and `SaveStorageValue`/`LoadStorageValue` don't work.

Assets such as images and sounds that are bundled into the APK file can still be loaded. gxbuild automatically bundles everything in the `assets` folder into the APK. Note that the `assets` folder is only created after running the `setup.sh` script.

#### Assets folder
On Android, the default working directory for loading assets is the `assets` folder. On other platforms, it is usually the directory containing the executable. To make sure your assets are loaded from the same directory on all platforms, you can do this:

```c
#ifndef PLATFORM_ANDROID
	ChangeDirectory("assets");
#endif

myTexture = LoadTexture("texture.png");
mySound = LoadSound("sound.wav");
myFont = LoadFont("font.ttf");

#ifndef PLATFORM_ANDROID
	ChangeDirectory("..");
#endif
```