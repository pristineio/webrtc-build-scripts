# !/bin/bash
# Copyright Pristine Inc
# Author: Rahul Behera <rahul@pristine.io>
# Author: Aaron Alaniz <aaron@pristine.io>
# Author: Arik Yaacob   <arik@pristine.io>
#
# Builds the android peer connection library

# Get location of the script itself .. thanks SO ! http://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

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

DEFAULT_WEBRTC_URL="https://chromium.googlesource.com/external/webrtc.git"
DEPOT_TOOLS="$PROJECT_ROOT/depot_tools"
LINARO_TOOLCHAIN="gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
LINARO_TOOLCHAIN_URL="https://releases.linaro.org/archive/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.bz2"
LINARO_TOOLCHAIN_PATH="$PROJECT_ROOT/toolchains"
WEBRTC_ROOT="$PROJECT_ROOT/webrtc"
create_directory_if_not_found "$WEBRTC_ROOT"
BUILD="$WEBRTC_ROOT/libjingle_peerconnection_builds"
WEBRTC_TARGET="AppRTCLinux"

ANDROID_TOOLCHAINS="$WEBRTC_ROOT/src/third_party/android_tools/ndk/toolchains"
PATH="$PATH:$DEPOT_TOOLS"

exec_ninja() {
  echo "Running ninja"
  ninja -C $1 # $WEBRTC_TARGET
}

# Installs the required dependencies on the machine
install_dependencies() {
    sudo apt-get -y install wget git gnupg flex bison gperf build-essential zip curl subversion pkg-config libglib2.0-dev libgtk2.0-dev libxtst-dev libxss-dev libpci-dev libdbus-1-dev libgconf2-dev libgnome-keyring-dev libnss3-dev
    #Download the latest script to install the linux dependencies for ubuntu
    curl https://chromium.googlesource.com/chromium/src/+/master/build/install-build-deps.sh?format=TEXT | base64 -d > install-build-deps.sh
    #use bash (not dash which is default) to run the script
    sudo /bin/bash ./install-build-deps.sh
    #delete the file we just downloaded... not needed anymore
    #rm install-build-deps.sh
}

# Update/Get/Ensure the Gclient Depot Tools
# Also will add to your environment
pull_depot_tools() {
	WORKING_DIR=`pwd`

    # Either clone or get latest depot tools
	if [ ! -d "$DEPOT_TOOLS" ]
	then
	    echo Make directory for gclient called Depot Tools
	    mkdir -p "$DEPOT_TOOLS"

	    echo Pull the depo tools project from chromium source into the depot tools directory
	    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS

	else
		echo Change directory into the depot tools
		cd "$DEPOT_TOOLS"

		echo Pull the depot tools down to the latest
		git pull
	fi

    # Navigate back
	cd "$WORKING_DIR"
}

pull_linaro_toolchain() {
	if [ ! -d ${LINARO_TOOLCHAIN_PATH} ];
	then
		mkdir -p ${LINARO_TOOLCHAIN_PATH}
	fi
	
	cd ${LINARO_TOOLCHAIN_PATH}

	if [ ! -d "${LINARO_TOOLCHAIN_PATH}/${LINARO_TOOLCHAIN}" ];
	then
		#curl -s ${LINARO_TOOLCHAIN_URL} -o ${LINARO_TOOLCHAIN}/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.bz2
		wget ${LINARO_TOOLCHAIN_URL}
		tar xvfpj gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.bz2
	fi
}

# Update/Get the webrtc code base
pull_webrtc() {
    WORKING_DIR=`pwd`

    # If no directory where webrtc root should be...
    create_directory_if_not_found "$WEBRTC_ROOT"
    cd "$WEBRTC_ROOT"

    # Setup gclient config
    echo Configuring gclient for Linux build
    if [ -z $USER_WEBRTC_URL ]
    then
        echo "User has not specified a different webrtc url. Using default"
        gclient config --name=src "$DEFAULT_WEBRTC_URL"
    else
        echo "User has specified their own webrtc url $USER_WEBRTC_URL"
        gclient config --name=src "$USER_WEBRTC_URL"
    fi

    # Ensure our target os is correct building linux
	echo 'target_os = ["linux", "unix"]' >> .gclient

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
	cd "$WORKING_DIR"
}

# Prepare our build
function wrbase() {
    export GYP_DEFINES="host_os=linux libjingle_java=1 build_with_libjingle=1 build_with_chromium=0 enable_tracing=1 enable_android_opensl=0 use_sysroot=0 include_tests=0"
    if [ "$WEBRTC_DEBUG" != "true" ] ;
    then
    	export GYP_DEFINES="$GYP_DEFINES fastbuild=2"
    fi
    export GYP_GENERATORS="ninja"
}

# add shared library option 
# reference from https://www.chromium.org/developers/gyp-environment-variables
function shared_library_option() {
	export GYP_DEFINES="$GYP_DEFINES component=shared_library"
}

# Arm V7 with Neon
function wrarmv7() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=linux"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_linux_armeabi-v7a"
    export GYP_CROSSCOMPILE=1

	export CC=""
	export CXX=""
	export AR=""
	export STRIP=""
	export CC_host=""
	export CXX_host=""

    echo "ARMv7 with Neon Build"
}

# Arm 64
function wrarmv8() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=linux target_arch=arm64 target_subarch=arm64"
    export GYP_GENERATOR_FLAGS="output_dir=out_linux_arm64-v8a"
    export GYP_CROSSCOMPILE=1

	export CC=""
	export CXX=""
	export AR=""
	export STRIP=""
	export CC_host=""
	export CXX_host=""

    echo "ARMv8 with Neon Build"
}

# x86
function wrX86() {
    wrbase
    #export GYP_DEFINES="$GYP_DEFINES OS=linux target_arch=ia32"
	export GYP_DEFINES="$GYP_DEFINES OS=linux target_arch=x86"
    export GYP_GENERATOR_FLAGS="output_dir=out-linux-${WEBRTC_ARCH}"

	export CC=""
	export CXX=""
	export AR=""
	export STRIP=""
	export CC_host=""
	export CXX_host=""

    echo "x86 Build"
}

# x86_64
function wrX86_64() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=linux target_arch=x64"
    export GYP_GENERATOR_FLAGS="output_dir=out-linux-${WEBRTC_ARCH}"

	export CC=""
	export CXX=""
	export AR=""
	export STRIP=""
	export CC_host=""
	export CXX_host=""

    echo "x86_64 Build"
}

function wrarm_linaro-gnueabihf() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=linux"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out-linux-${WEBRTC_ARCH}"
    export GYP_CROSSCOMPILE=1

	export CC="${LINARO_TOOLCHAIN_PATH}/${LINARO_TOOLCHAIN}/bin/arm-linux-gnueabihf-gcc"
	export CXX="${LINARO_TOOLCHAIN_PATH}/${LINARO_TOOLCHAIN}/bin/arm-linux-gnueabihf-g++"
	export AR="${LINARO_TOOLCHAIN_PATH}/${LINARO_TOOLCHAIN}/bin/arm-linux-gnueabihf-ar"
	export STRIP="${LINARO_TOOLCHAIN_PATH}/${LINARO_TOOLCHAIN}/bin/arm-linux-gnueabihf-strip"
	export CC_host="gcc"
	export CXX_host="g++"

    echo "ARM with Linaro Build"
}

# Setup our defines for the build
prepare_gyp_defines() {
    # Configure environment for Linux
    echo Setting up build environment for Linux
#    source "$WEBRTC_ROOT/src/build/android/envsetup.sh"

    # Check to see if the user wants to set their own gyp defines
    echo Export the base settings of GYP_DEFINES so we can define how we want to build
    if [ -z $USER_GYP_DEFINES ]
    then
        echo "User has not specified any gyp defines so we proceed with default"
        if [ "$WEBRTC_ARCH" = "x86" ] ;
        then
            wrX86
        elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
        then
            wrX86_64
#        elif [ "$WEBRTC_ARCH" = "armv7" ] ;
#        then
#           wrarmv7
#        elif [ "$WEBRTC_ARCH" = "armv8" ] ;
#        then
#            wrarmv8
        elif [ "$WEBRTC_ARCH" = "arm-linaro-gnueabihf" ] ;
        then
            wrarm_linaro-gnueabihf
        fi
    else
        echo "User has specified their own gyp defines"
        export GYP_DEFINES="$USER_GYP_DEFINES"
    fi
	
	if [ -z $1 ]
    then
        echo "Disabled shared library option"
    else
        echo "Enabled shared library option"
        shared_library_option
    fi

    echo "GYP_DEFINES=$GYP_DEFINES"
}

# Builds the apprtc demo
execute_build() {
    WORKING_DIR=`pwd`
    cd "$WEBRTC_ROOT/src"

    if [ "$WEBRTC_ARCH" = "x86" ] ;
    then
        ARCH="x86"
#        STRIP="$ANDROID_TOOLCHAINS/x86-4.9/prebuilt/linux-x86_64/bin/i686-linux-strip"
    elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
    then
        ARCH="x64"
#        STRIP="$ANDROID_TOOLCHAINS/x86_64-4.9/prebuilt/linux-x86_64/bin/x86_64-linux-strip"
#    elif [ "$WEBRTC_ARCH" = "armv7" ] ;
#    then
#        ARCH="arm"
#        STRIP="$ANDROID_TOOLCHAINS/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-eabi-strip"
#    elif [ "$WEBRTC_ARCH" = "armv8" ] ;
#    then
#        ARCH="arm64"
#        STRIP="$ANDROID_TOOLCHAINS/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-strip"
    elif [ "$WEBRTC_ARCH" = "linaro-gnueabihf" ] ;
    then
        ARCH="arm"
    fi

    if [ "$WEBRTC_DEBUG" = "true" ] ;
    then
        BUILD_TYPE="Debug"
        DEBUG_ARG='is_debug=true'
    else
        BUILD_TYPE="Release"
        DEBUG_ARG='is_debug=false dcheck_always_on=true'
    fi

    ARCH_OUT="out-linux-${WEBRTC_ARCH}"

#	${WEBRTC_ROOT}/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm
	
    echo Generate projects using GN
    gn gen "$ARCH_OUT/$BUILD_TYPE" --args="$DEBUG_ARG symbol_level=1 target_os=\"linux\" target_cpu=\"${ARCH}\""
    #gclient runhooks

    REVISION_NUM=`get_webrtc_revision`
    echo "Build ${WEBRTC_TARGET} in $BUILD_TYPE (arch: ${WEBRTC_ARCH})"
    exec_ninja "$ARCH_OUT/$BUILD_TYPE"

    # Verify the build actually worked
    if [ $? -eq 0 ]; then
        SOURCE_DIR="$WEBRTC_ROOT/src/$WEBRTC_ARCH/$BUILD_TYPE"
        TARGET_DIR="$BUILD/$BUILD_TYPE"
        create_directory_if_not_found "$TARGET_DIR"

        echo "Copy JAR File"
        create_directory_if_not_found "$TARGET_DIR/libs/"
        create_directory_if_not_found "$TARGET_DIR/jni/"

        if [ "$WEBRTC_ARCH" = "x86" ] ;
        then
        	ARCH_JNI="$TARGET_DIR/jni/x86"
        elif [ "$WEBRTC_ARCH" = "x86_64" ] ;
        then
        	ARCH_JNI="$TARGET_DIR/jni/x86_64"
#        elif [ "$WEBRTC_ARCH" = "armv7" ] ;
#        then
#        	ARCH_JNI="$TARGET_DIR/jni/armeabi-v7a"
#        elif [ "$WEBRTC_ARCH" = "armv8" ] ;
#        then
#        	ARCH_JNI="$TARGET_DIR/jni/arm64-v8a"
        elif [ "$WEBRTC_ARCH" = "linaro" ] ;
        then
        	ARCH_JNI="$TARGET_DIR/jni/linaro"
        fi
        create_directory_if_not_found "$ARCH_JNI"

        # Copy the jars
#        cp -p "$SOURCE_DIR/lib.java/webrtc/sdk/android/libjingle_peerconnection_java.jar" "$TARGET_DIR/libs/libjingle_peerconnection.jar"
#        cp -p "$SOURCE_DIR/lib.java/webrtc/base/base_java.jar" "$TARGET_DIR/libs/base_java.jar"

        # Strip the build only if its release
        if [ "$WEBRTC_DEBUG" = "true" ] ;
        then
            cp -p "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libjingle_peerconnection_so.so" "$ARCH_JNI/libjingle_peerconnection_so.so"
        else
            "$STRIP" -o "$ARCH_JNI/libjingle_peerconnection_so.so" "$WEBRTC_ROOT/src/$ARCH_OUT/$BUILD_TYPE/libjingle_peerconnection_so.so" -s
        fi

        cd "$TARGET_DIR"
        mkdir -p aidl
        mkdir -p assets
        mkdir -p res

        cd "$WORKING_DIR"
        echo "$BUILD_TYPE build for apprtc complete for revision $REVISION_NUM"
    else

        echo "$BUILD_TYPE build for apprtc failed for revision $REVISION_NUM"
        #exit 1
    fi
}

# Gets the webrtc revision
get_webrtc_revision() {
    DIR=`pwd`
    cd "$WEBRTC_ROOT/src"
    REVISION_NUMBER=`git log -1 | grep 'Cr-Commit-Position: refs/heads/master@{#' | egrep -o "[0-9]+}" | tr -d '}'`

    if [ -z "$REVISION_NUMBER" ]
    then
      REVISION_NUMBER=`git describe --tags  | sed 's/\([0-9]*\)-.*/\1/'`
    fi

    if [ -z "$REVISION_NUMBER" ]
    then
      echo "Error grabbing revision number"
      exit 1
    fi

    echo $REVISION_NUMBER
    cd "$DIR"
}

get_webrtc() {
    pull_depot_tools &&
	pull_linaro_toolchain &&
    pull_webrtc $1
}

# Updates webrtc and builds apprtc
build_apprtc() {
#    export WEBRTC_ARCH=armv7
#    prepare_gyp_defines $1 &&
#    execute_build

#    export WEBRTC_ARCH=armv8
#    prepare_gyp_defines $1 &&
#    execute_build

	export WEBRTC_DEBUG=true
    export WEBRTC_ARCH=x86
    prepare_gyp_defines $1 &&
    execute_build

	export WEBRTC_DEBUG=false
    export WEBRTC_ARCH=x86
    prepare_gyp_defines $1 &&
    execute_build	

	export WEBRTC_DEBUG=true
    export WEBRTC_ARCH=x86_64
    prepare_gyp_defines $1 &&
    execute_build

	export WEBRTC_DEBUG=false
    export WEBRTC_ARCH=x86_64
    prepare_gyp_defines $1 &&
    execute_build

	export WEBRTC_DEBUG=true
    export WEBRTC_ARCH=arm-linaro-gnueabihf
    prepare_gyp_defines $1 &&
    execute_build

	export WEBRTC_DEBUG=false
    export WEBRTC_ARCH=arm-linaro-gnueabihf
    prepare_gyp_defines $1 &&
    execute_build		
}