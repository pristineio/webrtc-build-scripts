# !/bin/bash
# Copyright Pristine Inc 
# Author: Rahul Behera <rahul@pristine.io>
# Author: Aaron Alaniz <aaron@pristine.io>
# Author: Arik Yaacob   <arik@pristine.io>
#
# Builds the android peer connection library

# Set your environment how you want
if [ -n  "$VAGRANT_MACHINE" ];
    then
    PROJECT_ROOT="/vagrant"
else
    # Get location of the script itself .. thanks SO ! http://stackoverflow.com/a/246128
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    PROJECT_ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
fi

DEPOT_TOOLS="$PROJECT_ROOT/depot_tools"
WEBRTC_ROOT="$PROJECT_ROOT/webrtc"
BUILD="$WEBRTC_ROOT/libjingle_peerconnection_builds"
WEBRTC_TARGET="AppRTCDemo"

ANDROID_TOOLCHAINS="$WEBRTC_ROOT/src/third_party/android_tools/ndk/toolchains"

# Utility method for creating a directory
create_directory_if_not_found() {
	# if we cannot find the directory
	if [ ! -d "$1" ];
		then
		echo "$1 directory not found, creating..."
	    mkdir -p "$1"
	    echo "directory created at $1"
	fi
}

exec_ninja() {
  echo "Running ninja"
  ninja -C $1 $WEBRTC_TARGET
}

# Installs the required dependencies on the machine
install_dependencies() {
    sudo apt-get -y install wget git gnupg flex bison gperf build-essential zip curl subversion pkg-config
    #Download the latest script to install the android dependencies for ubuntu
    curl -o install-build-deps-android.sh https://src.chromium.org/svn/trunk/src/build/install-build-deps-android.sh
    #use bash (not dash which is default) to run the script
    sudo /bin/bash ./install-build-deps-android.sh
    #delete the file we just downloaded... not needed anymore
    rm install-build-deps-android.sh
}

# Update/Get/Ensure the Gclient Depot Tools
# Also will add to your environment
pull_depot_tools() {
	WORKING_DIR=`pwd`

    # Either clone or get latest depot tools
	if [ ! -d "$DEPOT_TOOLS" ]
	then
	    echo Make directory for gclient called Depot Tools
	    mkdir -p $DEPOT_TOOLS

	    echo Pull the depo tools project from chromium source into the depot tools directory
	    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS

	else
		echo Change directory into the depot tools
		cd $DEPOT_TOOLS

		echo Pull the depot tools down to the latest
		git pull
	fi
	PATH="$PATH:$DEPOT_TOOLS"

    # Navigate back
	cd $WORKING_DIR
}

# Update/Get the webrtc code base
pull_webrtc() {
    WORKING_DIR=`pwd`

    # If no directory where webrtc root should be...
    create_directory_if_not_found $WEBRTC_ROOT
    cd $WEBRTC_ROOT

    # Ensure our target os is correct building android
    echo Configuring gclient for Android build
	gclient config --name=src http://webrtc.googlecode.com/svn/trunk
	echo "target_os = ['unix', 'android']" >> .gclient

    # Get latest webrtc source
	echo Pull down the latest from the webrtc repo
	echo this can take a while
	if [ -z $1 ]
    then
        echo "gclient sync with newest"
        gclient sync
    else
        echo "gclient sync with $1"
        gclient sync -r $1
    fi

    # Navigate back
	cd $WORKING_DIR
}

# Prepare our build
function wrbase() {
    export GYP_DEFINES="OS=android host_os=linux libjingle_java=1 build_with_libjingle=1 build_with_chromium=0 enable_tracing=1 enable_android_opensl=1"
    export GYP_GENERATORS="ninja"
}

# Arm V7 with Neon
function wrarmv7() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=android"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_android_armeabi_v7a"
    export GYP_CROSSCOMPILE=1
    echo "ARMv7 with Neon Build"
}

# Arm 64
function wrarmv8() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=arm64 target_subarch=arm64"
    export GYP_GENERATOR_FLAGS="$output_dir=out_android_arm64_v8a"
    export GYP_CROSSCOMPILE=1
    echo "ARMv8 with Neon Build"
}

# x86
function wrX86() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=ia32"
    export GYP_GENERATOR_FLAGS="output_dir=out_android_x86"
    echo "x86 Build"
}

# x86_64
function wrX86_64() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=x64"
    export GYP_GENERATOR_FLAGS="output_dir=out_android_x86_64"
    echo "x86_64 Build"
}


# Setup our defines for the build
prepare_gyp_defines() {
    # Configure environment for Android
    echo Setting up build environment for Android
    source $WEBRTC_ROOT/src/build/android/envsetup.sh

    # Check to see if the user wants to set their own gyp defines
    echo Export the base settings of GYP_DEFINES so we can define how we want to build
    if [ -n $USER_GYP_DEFINES ]
    then
        echo "User has not specified any gyp defines so we proceed with default"
        if [ "$WEBRTC_ARCH" = "x86" ] ;
        then
            wrX86
        elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
        then
            wrX86_64
        elif [ "$WEBRTC_ARCH" = "armv7" ] ;
        then
            wrarmv7
        elif [ "$WEBRTC_ARCH" = "armv8" ] ;
        then
            wrarmv8
        fi
    else
        echo "User has specified their own gyp defines"
        export GYP_DEFINES="$USER_GYP_DEFINES"
    fi

    echo "GYP_DEFINES=$GYP_DEFINES"
}

# Builds the apprtc demo
execute_build() {
    WORKING_DIR=`pwd`
    cd "$WEBRTC_ROOT/src"

    echo Run gclient hooks
    gclient runhooks

    if [ "$WEBRTC_ARCH" = "x86" ] ;
    then
        ARCH="x86"
        STRIP=$ANDROID_TOOLCHAINS/x86-4.9/prebuilt/linux-x86_64/bin/i686-linux-android-strip
    elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
    then
        ARCH="x86_64"
        STRIP=$ANDROID_TOOLCHAINS/x86_64-4.9/prebuilt/linux-x86_64/bin/x86_64-linux-android-strip
    elif [ "$WEBRTC_ARCH" = "armv7" ] ;
    then
        ARCH="armeabi_v7a"
        STRIP=$ANDROID_TOOLCHAINS/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip
    elif [ "$WEBRTC_ARCH" = "armv8" ] ;
    then
        ARCH="arm64_v8a"
        STRIP=$ANDROID_TOOLCHAINS/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip
    fi

    if [ "$WEBRTC_DEBUG" = "true" ] ;
    then
        BUILD_TYPE="Debug"
    else
        BUILD_TYPE="Release"
    fi

    ARCH_OUT="out_android_${ARCH}"
    echo "Build ${WEBRTC_TARGET} in $BUILD_TYPE (arch: ${WEBRTC_ARCH:-arm})"
    exec_ninja "$ARCH_OUT/$BUILD_TYPE"
    
    REVISION_NUM=`get_webrtc_revision`
    # Verify the build actually worked
    if [ $? -eq 0 ]; then
        SOURCE_DIR="$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE"
        TARGET_DIR="$BUILD/$BUILD_TYPE"
        create_directory_if_not_found "$TARGET_DIR"
        
        rm "$TARGET_DIR/$REVISION_NUM.zip" || true

        echo "Copy JAR File"
        create_directory_if_not_found "$TARGET_DIR/libs/"
        create_directory_if_not_found "$TARGET_DIR/jniLibs/"

        ARCH_JNI="$TARGET_DIR/jniLibs/${ARCH}"
        create_directory_if_not_found $ARCH_JNI

        cp -p "$SOURCE_DIR/libjingle_peerconnection.jar" "$TARGET_DIR/libs/" 

        $STRIP -o $ARCH_JNI/libjingle_peerconnection_so.so $WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/lib/libjingle_peerconnection_so.so -s

        #cp -pr "$SOURCE_DIR"/* "$TARGET_DIR"
        cd $TARGET_DIR
        mkdir -p res # make resources directory

        zip -r "$TARGET_DIR/$REVISION_NUM.zip" .
        cd $WORKING_DIR

        
        echo "$BUILD_TYPE build for apprtc complete for revision $REVISION_NUM"
    else
        
        echo "$BUILD_TYPE build for apprtc failed for revision $REVISION_NUM"
    fi
}

# Gets the webrtc revision
get_webrtc_revision() {
 #   git describe --tags  | sed 's/r\([0-9]*\)-.*/\1/' #Here's a nice little git version if you are using a git source
    svn info "$WEBRTC_ROOT/src" | awk '{ if ($1 ~ /Revision/) { print $2 } }'
}

get_webrtc() {
    pull_depot_tools &&
    pull_webrtc $1
}

# Updates webrtc and builds apprtc
build_apprtc() {
    export WEBRTC_ARCH=armv7
    prepare_gyp_defines &&
    execute_build

    # Uncomment once the application can successfully build for arm64
    #export WEBRTC_ARCH=armv8
    #prepare_gyp_defines &&
    #execute_build

    export WEBRTC_ARCH=x86
    prepare_gyp_defines &&
    execute_build

    export WEBRTC_ARCH=x86_64
    prepare_gyp_defines &&
    execute_build
}
