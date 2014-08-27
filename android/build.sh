# !/bin/bash

# Set your environment how you want
PROJECT_ROOT="$HOME"
DEPOT_TOOLS="$PROJECT_ROOT/depot_tools"
WEBRTC_ROOT="$PROJECT_ROOT/webrtc"

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

# Installs all android related dependencies
install_dependencies() {
	sudo apt-get -y install wget git gnupg flex bison gperf build-essential zip curl subversion
}

# Installs jdk 1.6
install_jdk1_6() {
	WORKING_DIR=`pwd`

    # Download the jdk 1.6
    wget http://ghaffarian.net/downloads/Java/JDK/jdk-6u45-linux-x64.bin

    # Install the jdk
    sudo mkdir /usr/lib/jvm
    cd /usr/lib/jvm && sudo sh $WORKING_DIR/jdk-6u45-linux-x64.bin -noregister
    sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.6.0_45/bin/javac 50000
    sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.6.0_45/bin/java 50000
    sudo update-alternatives --config javac
    sudo update-alternatives --config java

    # Set your JAVA_HOME
    JAVA_HOME=`readlink -f $(which java)`
    JAVA_HOME=`echo ${JAVA_HOME%/bin/java}`
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
    source ~/.bashrc

    # Navigate back and remove jdk bin
    cd $WORKING_DIR
    rm $WORKING_DIR/jdk-6u45-linux-x64.bin
}

# Update/Get/Ensure the Gclient Depot Tools
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
	gclient config http://webrtc.googlecode.com/svn/trunk
	echo "target_os = ['unix', 'android']" >> .gclient

    # Get latest webrtc source
	echo Pull down the latest from the webrtc repo
	echo this can take a while
	if [ -z $1 ]
    then
        echo "gclient sync with newest"
        gclient sync 
    else
    	trunkA="trunk@"
        echo "gclient sync with r$1"
        gclient sync -r $trunkA$1 
    fi

    # Navigate back
	cd $WORKING_DIR
}

# Setup our defines for the build
prepare_gyp_defines() {
    # Setup deps for android and configure environment
    echo Setting up build environment for Android
	$WEBRTC_ROOT/trunk/build/install-build-deps-android.sh
	source $WEBRTC_ROOT/trunk/build/android/envsetup.sh

	echo Export the base settings of GYP_DEFINES so we can define how we want to build
	export GYP_DEFINES="OS=android host_os=linux target_arch=arm libjingle_java=1 build_with_libjingle=1 build_with_chromium=0 enable_tracing=1 arm_neon=1 armv7=1 enable_android_opensl=1"
	echo "GYP_DEFINES=$GYP_DEFINES"
	export DEFINES=$GYP_DEFINES
	echo "DEFINES=$DEFINES"
}

# Clean up and generate the build scripts
prepare_build() {
	WORKING_DIR=`pwd`

    echo Change directory into webrtc trunk
    cd "$WEBRTC_ROOT/trunk"

    echo cleaning old build
    rm -rf out
    mkdir out
    mkdir out/Release
    mkdir out/Debug

    echo gclient runhooks
    gclient runhooks

    cd $WORKING_DIR
}

# Builds the apprtc demo
execute_build() {
	WORKING_DIR=`pwd`
	cd "$WEBRTC_ROOT/trunk"

	PEERCONNECTION_BUILD="$WEBRTC_ROOT/libjingle_peerconnection_builds"
	create_directory_if_not_found "$PEERCONNECTION_BUILD"
	DEBUG_DIR="$PEERCONNECTION_BUILD/Debug"
	create_directory_if_not_found "$DEBUG_DIR"
	ARCHITECTURE="armeabi-v7a"

	DIRECTORY="$WEBRTC_ROOT/trunk/talk/examples/android/libs/$ARCHITECTURE"

	echo Build AppRTCDemo in Release mode
	ninja -C out/Release/ AppRTCDemo
	
	RELEASE_DIR="$PEERCONNECTION_BUILD/Release"
	create_directory_if_not_found "$RELEASE_DIR"
	create_directory_if_not_found "$RELEASE_DIR/$ARCHITECTURE"
	echo "Copy $DIRECTORY/libjingle_peerconnection_so.so to $RELEASE_DIR/$ARCHITECTURE/libjingle_peerconnection_so.so"
	cp -p "$DIRECTORY/libjingle_peerconnection_so.so" "$RELEASE_DIR/$ARCHITECTURE/libjingle_peerconnection_so.so"

	echo "Copy $WEBRTC_ROOT/trunk/talk/examples/android/libs/libjingle_peerconnection.jar to $RELEASE_DIR/libjingle_peerconnection.jar"
	cp -p "$WEBRTC_ROOT/trunk/talk/examples/android/libs/libjingle_peerconnection.jar" "$RELEASE_DIR/libjingle_peerconnection.jar"

	cd $WORKING_DIR

    REVISION_NUM=`get_webrtc_revision`
    echo "Release build for apprtc complete for revision $REVISION_NUM"
}

# Builds the apprtc demo in debug
execute_debug_build() {
	WORKING_DIR=`pwd`

	echo Change directory into webrtc trunk
	cd "$WEBRTC_ROOT/trunk"

	echo Build AppRTCDemo in Debug mode
	ninja -C out/Debug/ AppRTCDemo

	PEERCONNECTION_BUILD="$WEBRTC_ROOT/libjingle_peerconnection_builds"
	create_directory_if_not_found "$PEERCONNECTION_BUILD"
	DEBUG_DIR="$PEERCONNECTION_BUILD/Debug"
	create_directory_if_not_found "$DEBUG_DIR"
	ARCHITECTURE="armeabi-v7a"

	DIRECTORY="$WEBRTC_ROOT/trunk/talk/examples/android/libs/$ARCHITECTURE"

	create_directory_if_not_found "$DEBUG_DIR/$ARCHITECTURE"
	echo "Copy $DIRECTORY/libjingle_peerconnection_so.so to $DEBUG_DIR/$ARCHITECTURE/libjingle_peerconnection_so.so"
	cp -p "$DIRECTORY/libjingle_peerconnection_so.so" "$DEBUG_DIR/$ARCHITECTURE/libjingle_peerconnection_so.so"

	echo "Copy $WEBRTC_ROOT/trunk/talk/examples/android/libs/libjingle_peerconnection.jar to $DEBUG_DIR/libjingle_peerconnection.jar"
	cp -p "$WEBRTC_ROOT/trunk/talk/examples/android/libs/libjingle_peerconnection.jar" "$DEBUG_DIR/libjingle_peerconnection.jar"

	cd $WORKING_DIR
    echo "Debug build for apprtc complete for revision $REVISION_NUM"
}

# Gets the webrtc revision
get_webrtc_revision() {
    svn info "$WEBRTC_ROOT/trunk" | awk '{ if ($1 ~ /Revision/) { print $2 } }'
}

# Updates webrtc and builds apprtc
build_apprtc() {
    pull_depot_tools &&
    pull_webrtc $1 && 
    prepare_gyp_defines &&
    prepare_build && 
    execute_build
}

# Updates webrtc and builds apprtc in debug
build_debug_apprtc() {
    pull_depot_tools &&
    pull_webrtc $1 && 
    prepare_gyp_defines &&
    prepare_build && 
    execute_debug_build
}
