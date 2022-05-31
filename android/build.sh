#!/bin/sh
# ______________________________________________________________________________
#
#  Compile raylib project for Android
#  Note: this script is sourced by build.sh when TARGET=Android is specified
# ______________________________________________________________________________
#
FLAGS="-ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wall \
	-Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes \
	-DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=$API_VERSION"

INCLUDES="-I. -Iinclude -I../include -I$NATIVE_APP_GLUE -I$TOOLCHAIN/sysroot/usr/include"

# Copy icons
cp assets/icon_ldpi.png $BUILD/res/drawable-ldpi/icon.png
cp assets/icon_mdpi.png $BUILD/res/drawable-mdpi/icon.png
cp assets/icon_hdpi.png $BUILD/res/drawable-hdpi/icon.png
cp assets/icon_xhdpi.png $BUILD/res/drawable-xhdpi/icon.png

# Copy other assets
cp assets/* android/build/assets

# ______________________________________________________________________________
#
#  Compile
# ______________________________________________________________________________
#
for ABI in $ABIS; do
	case "$ABI" in
		"armeabi-v7a")
			CCTYPE="armv7a-linux-androideabi"
			ABI_FLAGS="-std=c99 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
			;;

		"arm64-v8a")
			CCTYPE="aarch64-linux-android"
			ABI_FLAGS="-std=c99 -target aarch64 -mfix-cortex-a53-835769"
			;;

		"x86")
			CCTYPE="i686-linux-android"
			ABI_FLAGS=""
			;;

		"x86_64")
			CCTYPE="x86_64-linux-android"
			ABI_FLAGS=""
			;;
	esac
	CC="$TOOLCHAIN/bin/$CCTYPE$API_VERSION-clang"

	# Compile native app glue
	# .c -> .o
	$CC -c $NATIVE_APP_GLUE/android_native_app_glue.c -o $NATIVE_APP_GLUE/native_app_glue.o \
		$INCLUDES -I$TOOLCHAIN/sysroot/usr/include/$CCTYPE $FLAGS $ABI_FLAGS

	# .o -> .a
	$AR rcs lib/$TARGET/$ABI/libnative_app_glue.a $NATIVE_APP_GLUE/native_app_glue.o

	# Compile project
	# FLAGS and TYPEFLAGS are from the main build script which sources this one
	$CC $SRC -o $BUILD/lib/$ABI/libmain.so -shared \
		$INCLUDES -I$TOOLCHAIN/sysroot/usr/include/$CCTYPE $FLAGS $TYPEFLAGS $FLAGS $ABI_FLAGS \
		-Wl,-soname,libmain.so -Wl,--exclude-libs,libatomic.a -Wl,--build-id \
		-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now \
		-Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate \
		-L. -L$BUILD/obj -Llib/$TARGET/$ABI \
		-lraylib -lnative_app_glue -llog -landroid -lEGL -lGLESv2 -lOpenSLES -latomic -lc -lm -ldl
done

# ______________________________________________________________________________
#
#  Build APK
# ______________________________________________________________________________
#
$BUILD_TOOLS/aapt package -f -m \
	-S $BUILD/res -J $BUILD/src -M $BUILD/AndroidManifest.xml \
	-I $SDK/platforms/android-$API_VERSION/android.jar

# Compile NativeLoader.java
$JAVA/bin/javac -verbose -source 1.7 -target 1.7 -d $BUILD/obj \
	-bootclasspath $JAVA/jre/lib/rt.jar \
	-classpath $SDK/platforms/android-$API_VERSION/android.jar:$BUILD/obj \
	-sourcepath src $BUILD/src/com/$DEV_NAME/$NAME/R.java \
	$BUILD/src/com/$DEV_NAME/$NAME/NativeLoader.java

$BUILD_TOOLS/dx --verbose --dex --output=$BUILD/dex/classes.dex $BUILD/obj

# Add resources and assets to APK
$BUILD_TOOLS/aapt package -f \
	-M $BUILD/AndroidManifest.xml -S $BUILD/res -A assets \
	-I $SDK/platforms/android-$API_VERSION/android.jar -F $NAME.apk $BUILD/dex

# Add libraries to APK
cd $BUILD
for ABI in $ABIS; do
	$BUILD_TOOLS/aapt add ../../$NAME.apk lib/$ABI/libmain.so
done
cd ../..

# Sign and zipalign APK
$JAVA/bin/jarsigner -keystore android/$NAME.keystore -storepass raylib -keypass raylib \
	-signedjar $NAME.apk $NAME.apk projectKey

$BUILD_TOOLS/zipalign -f 4 $NAME.apk $NAME.final.apk
mv -f $NAME.final.apk $NAME.apk

# Install to device or emulator if -r was specified
[[ "$1" = "-r" ]] && $SDK/platform-tools/adb install -r $NAME.apk