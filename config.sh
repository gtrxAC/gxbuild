#!/bin/bash
# ______________________________________________________________________________
#
#  Build options
#  This script is sourced by build.sh and setup.sh, no need to run it yourself
# ______________________________________________________________________________
#
# Executable name, extension is added depending on target platform.
NAME=game

# Files to compile. You can add multiple files by separating by spaces.
SRC="src/*.c"

# Platform, one of Windows_NT, Linux, Web, Android. Defaults to your OS.
# This can be set from the command line: TARGET=Android ./build.sh
[[ -z "$TARGET" ]] && TARGET=$(uname)

# Compiler flags.
# This can be set from the command line: FLAGS="-Ofast" ./build.sh
[[ -z "$FLAGS" ]] && FLAGS=""

# Compiler flags for release and debug mode
# To set debug mode, run: DEBUG=1 ./build.sh
RELEASE_FLAGS="-Os -flto -s"
DEBUG_FLAGS="-DDEBUG -O0 -g -Wall -Wextra -Wpedantic"

# ______________________________________________________________________________
#
#  Build options for Android
# ______________________________________________________________________________
#
# Path to the Java JDK. This folder should contain a bin folder which has javac
# and some other tools. On Linux, if Java was installed from a package manager,
# the Java path should be somewhere in /usr/lib/jvm.
JAVA=/usr/lib/jvm/java-18-openjdk-amd64

# The developer and package name for the app: com.$DEV_NAME.$PKG_NAME
DEV_NAME=raylib
PKG_NAME=$NAME

# The name of the app shown in the launcher.
APP_NAME=Game

# App version, version code should be incremented by 1 and version name is the
# human readable version.
VERSION_CODE=1
VERSION_NAME=1.0

# What Android API version to target. API_VERSION 29 (Android 10) or above is
# recommended. With an API_VERSION of 23 (Android 6) and up, versions below 23
# are not supported, so the MIN_API_VERSION should be set to 23. To support
# versions 19 (4.4) to 22 (5.1), both the API_VERSION and MIN_API_VERSION should
# be set to 19.
API_VERSION=31
MIN_API_VERSION=23

# The app's screen orientation, portrait or landscape.
SCREEN_ORIENTATION=landscape

# Architectures to build for. armeabi-v7a works for most devices.
ABIS="armeabi-v7a x86"

# Paths for Android SDK/NDK. Don't change unless you already have an SDK
# installation and you know what you're doing.
SDK=$(pwd)/android/sdk/$(uname)
NDK=$(pwd)/android/ndk/$(uname)/android-ndk-r23b
BUILD=$(pwd)/android/build

case $(uname) in
	"Windows_NT") TOOLCHAIN_OS="windows-x86_64";;
	"Linux") TOOLCHAIN_OS="linux-x86_64";;
esac

BUILD_TOOLS_VERSION=29.0.3
BUILD_TOOLS=$SDK/build-tools/$BUILD_TOOLS_VERSION
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$TOOLCHAIN_OS
NATIVE_APP_GLUE=$NDK/sources/android/native_app_glue
AR=$TOOLCHAIN/bin/llvm-ar