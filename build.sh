#!/bin/bash
# ______________________________________________________________________________
#
#  Compile raylib project
#  Configure the config.sh for your project before building
#
#  - Linux                   ./build.sh
#  - Windows (w64devkit)     ./build.sh
#  - Windows (cross compile) TARGET=Windows_NT ./build.sh
#  - Web                     TARGET=Web ./build.sh
#  - Android                 TARGET=Android ./build.sh
#
#  - Debug                   DEBUG=1 ./build.sh
#  - Build and run           ./build.sh -r
# ______________________________________________________________________________
#
source config.sh

# Add release or debug flags
if [[ -z "$DEBUG" ]]; then
	FLAGS="$FLAGS $RELEASE_FLAGS"
else
	FLAGS="$FLAGS $DEBUG_FLAGS"
fi

# Run the setup if the project hasn't been set up yet
[[ -e lib/$TARGET ]] || ./setup.sh

# Build options for each target
case "$TARGET" in
	"Windows_NT")
		# To build for 32-bit, set ARCH to i686 in both build and setup.sh, then
		# run setup again
		ARCH="x86_64"
		CC="$ARCH-w64-mingw32-gcc"
		EXT=".exe"
		PLATFORM="PLATFORM_DESKTOP"
		TARGET_FLAGS="-lopengl32 -lgdi32 -lwinmm -static -Wl,--subsystem,windows"
		;;

	"Linux")
		CC="gcc"
		PLATFORM="PLATFORM_DESKTOP"
		TARGET_FLAGS="-lGL -lm -lpthread -ldl -lrt -lX11"
		;;

	"Web")
		CC="emcc"
		EXT=".html"
		PLATFORM="PLATFORM_WEB"
		TARGET_FLAGS="-s ASYNCIFY -s USE_GLFW=3 -s TOTAL_MEMORY=67108864 \
		-s FORCE_FILESYSTEM=1 --shell-file src/shell.html --preload-file assets"
		source emsdk/emsdk_env.sh
		;;

	"Android")
		source android/build.sh
		exit
		;;

	*)
		echo "Unsupported platform $TARGET"
		exit 1
		;;
esac

# Don't run the project if build fails
set -e

$CC $SRC -Iinclude -Llib/$TARGET -o $NAME$EXT \
	-lraylib -D$PLATFORM $FLAGS $TARGET_FLAGS

# itch.io expects html5 games to be named index.html, js/data/wasm filenames can
# stay the same
[[ "$TARGET" = "Web" ]] && mv $NAME.html index.html

# ______________________________________________________________________________
#
#  Run if -r was specified
# ______________________________________________________________________________
#
if [[ "$1" = "-r" ]]; then
	case "$TARGET" in
		"Windows_NT") ([[ $(uname) = "Linux" ]] && wine $NAME$EXT) || $NAME$EXT;;
		"Linux") ./$NAME;;
		"Web") emrun index.html;;
	esac
fi
