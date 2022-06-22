#!/bin/bash
# ______________________________________________________________________________
#
#  Set up raylib project for Android
#  Note: this script is sourced by setup.sh when TARGET=Android is specified
# ______________________________________________________________________________
#
# Set up android directory structure
mkdir --parents $SDK $NDK $BUILD
cd $BUILD
mkdir --parents obj dex res/values src/com/$DEV_NAME/$PKG_NAME assets
mkdir --parents res/drawable-ldpi res/drawable-mdpi res/drawable-hdpi res/drawable-xhdpi

# ______________________________________________________________________________
#
#  Download and set up SDK/NDK
# ______________________________________________________________________________
#
case $(uname) in
	"Windows_NT") 
		SDK_OS="win"
		NDK_OS="windows"
		;;
	"Linux")
		SDK_OS="linux"
		NDK_OS="linux"
		;;
esac

# Download SDK
cd $SDK
[[ -e android-sdk.zip ]] || wget https://dl.google.com/android/repository/commandlinetools-$SDK_OS-8092744_latest.zip -O android-sdk.zip
unzip android-sdk

# Set up SDK
cd $SDK/cmdline-tools/bin
./sdkmanager --update --sdk_root=$SDK
./sdkmanager --install "build-tools;$BUILD_TOOLS_VERSION" --sdk_root=$SDK
./sdkmanager --install "platform-tools" --sdk_root=$SDK
./sdkmanager --install "platforms;android-$API_VERSION" --sdk_root=$SDK

# Download NDK
cd $NDK/..
[[ -e android-ndk.zip ]] || wget https://dl.google.com/android/repository/android-ndk-r23b-$NDK_OS.zip -O android-ndk.zip
unzip android-ndk

# ______________________________________________________________________________
#
#  Build raylib
# ______________________________________________________________________________
#
cd ../../../raylib/src
for ABI in $ABIS; do
	case "$ABI" in
		"armeabi-v7a") ARCH="arm";;
		"arm64-v8a") ARCH="arm64";;
		*) ARCH=$ABI;;
	esac

	mkdir -p ../../lib/$TARGET/$ABI $BUILD/lib/$ABI
	rm -f ../../lib/$TARGET/$ABI/libraylib.a

	make ANDROID_NDK=$NDK ANDROID_ARCH=$ARCH ANDROID_API_VERSION=$API_VERSION PLATFORM=PLATFORM_ANDROID || \
	make ANDROID_NDK=$NDK ANDROID_ARCH=$ARCH ANDROID_API_VERSION=$API_VERSION PLATFORM=PLATFORM_ANDROID -e

	mv libraylib.a ../../lib/$TARGET/$ABI/libraylib.a
	cp raylib.h ../../include
	make clean || make clean -e || rm -fv *.o
done
cd ../..

# ______________________________________________________________________________
#
#  Copy/generate files
# ______________________________________________________________________________
#
# Use raylib logo if icons not available
[[ -e assets/icon_ldpi.png ]] || cp raylib/logo/raylib_36x36.png assets/icon_ldpi.png
[[ -e assets/icon_mdpi.png ]] || cp raylib/logo/raylib_48x48.png assets/icon_mdpi.png
[[ -e assets/icon_hdpi.png ]] || cp raylib/logo/raylib_72x72.png assets/icon_hdpi.png
[[ -e assets/icon_xhdpi.png ]] || cp raylib/logo/raylib_96x96.png assets/icon_xhdpi.png

# Generate key for signing APKs
cd android
keytool -genkeypair -validity 1000 -dname "CN=$DEV_NAME,O=Android,C=ES" \
	-keystore $PKG_NAME.keystore -storepass 'raylib' -keypass 'raylib' \
	-alias projectKey -keyalg RSA

cd $BUILD/src/com/$DEV_NAME/$PKG_NAME
echo "package com.$DEV_NAME.$PKG_NAME;"                               >  NativeLoader.java
echo "public class NativeLoader extends android.app.NativeActivity {" >> NativeLoader.java
echo "    static {"                                                   >> NativeLoader.java
echo "        System.loadLibrary(\"main\");"                          >> NativeLoader.java 
echo "    }"                                                          >> NativeLoader.java
echo "}"                                                              >> NativeLoader.java

cd $BUILD
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"                                                                  >  AndroidManifest.xml
echo "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\""                                      >> AndroidManifest.xml
echo "        package=\"com.$DEV_NAME.$PKG_NAME\""                                                                 >> AndroidManifest.xml
echo "        android:versionCode=\"$VERSION_CODE\" android:versionName=\"$VERSION_NAME\" >"                       >> AndroidManifest.xml
echo "    <uses-sdk android:minSdkVersion=\"$MIN_API_VERSION\" android:targetSdkVersion=\"$API_VERSION\"/>"        >> AndroidManifest.xml
echo "    <uses-feature android:glEsVersion=\"0x00020000\" android:required=\"true\"/>"                            >> AndroidManifest.xml
echo "    <uses-permission android:name=\"android.permission.WRITE_EXTERNAL_STORAGE\"/>"                           >> AndroidManifest.xml
echo "    <application android:allowBackup=\"false\" android:label=\"$APP_NAME\" android:icon=\"@drawable/icon\">" >> AndroidManifest.xml
echo "        <activity android:name=\"com.$DEV_NAME.$PKG_NAME.NativeLoader\""                                     >> AndroidManifest.xml
echo "            android:theme=\"@android:style/Theme.NoTitleBar.Fullscreen\""                                    >> AndroidManifest.xml
echo "            android:configChanges=\"orientation|keyboardHidden|screenSize\""                                 >> AndroidManifest.xml
echo "            android:screenOrientation=\"$SCREEN_ORIENTATION\" android:launchMode=\"singleTask\""             >> AndroidManifest.xml
echo "            android:clearTaskOnLaunch=\"true\">"                                                             >> AndroidManifest.xml
echo "            <meta-data android:name=\"android.app.lib_name\" android:value=\"main\"/>"                       >> AndroidManifest.xml
echo "            <intent-filter>"                                                                                 >> AndroidManifest.xml
echo "                <action android:name=\"android.intent.action.MAIN\"/>"                                       >> AndroidManifest.xml
echo "                <category android:name=\"android.intent.category.LAUNCHER\"/>"                               >> AndroidManifest.xml
echo "            </intent-filter>"                                                                                >> AndroidManifest.xml
echo "        </activity>"                                                                                         >> AndroidManifest.xml
echo "    </application>"                                                                                          >> AndroidManifest.xml
echo "</manifest>"                                                                                                 >> AndroidManifest.xml
cd ../..