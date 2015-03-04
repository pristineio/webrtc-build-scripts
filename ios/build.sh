#!/bin/sh

#  build.sh
#  WebRTC
#
#  Created by Rahul Behera on 6/18/14.
#  Copyright (c) 2014 Pristine, Inc. All rights reserved.

# Get location of the script itself .. thanks SO ! http://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

DEFAULT_WEBRTC_URL="http://webrtc.googlecode.com/svn/trunk"
DEFAULT_POD_URL="https://s3.amazonaws.com/libjingle"
WEBRTC="$PROJECT_DIR/webrtc"
DEPOT_TOOLS="$PROJECT_DIR/depot_tools"
BUILD="$WEBRTC/libjingle_peerconnection_builds"
WEBRTC_TARGET="libWebRTC_objc"

function create_directory_if_not_found() {
    if [ ! -d "$1" ];
    then
        mkdir -v "$1"
    fi
}

function exec_libtool() {
  echo "Running libtool"
  libtool -static -v -o $@
}

function exec_strip() {
  echo "Running strip"
  strip -S -X $@
}

function exec_ninja() {
  echo "Running ninja"
  ninja -C $1 $WEBRTC_TARGET
}

create_directory_if_not_found "$PROJECT_DIR"
create_directory_if_not_found "$WEBRTC"

# Update/Get/Ensure the Gclient Depot Tools
function pull_depot_tools() {

    echo Get the current working directory so we can change directories back when done
    WORKING_DIR=`pwd`

    echo If no directory where depot tools should be...
    if [ ! -d "$DEPOT_TOOLS" ]
    then
        echo Make directory for gclient called Depot Tools
        mkdir -p $DEPOT_TOOLS

        echo Pull the depot tools project from chromium source into the depot tools directory
        git clone "https://chromium.googlesource.com/chromium/tools/depot_tools.git" "$DEPOT_TOOLS"

    else

        echo Change directory into the depot tools
        cd $DEPOT_TOOLS

        echo Pull the depot tools down to the latest
        git pull
    fi
    PATH="$PATH:$DEPOT_TOOLS"
    echo Go back to working directory
    cd $WORKING_DIR
}

function choose_code_signing() {
    if [ "$WEBRTC_TARGET" == "AppRTCDemo" ]; then
        echo "AppRTCDemo target requires code signing since we are building an *.ipa"
        if [[ -z $IDENTITY ]]
        then
            COUNT=$(security find-identity -v | grep -c "iPhone Developer")
            if [[ $COUNT -gt 1 ]]
            then
              security find-identity -v
              echo "Please select your code signing identity index from the above list:"
              read INDEX
              IDENTITY=$(security find-identity -v | awk -v i=$INDEX -F "\\\) |\"" '{if (i==$1) {print $3}}')
            else
              IDENTITY=$(security find-identity -v | grep "iPhone Developer" | awk -F "\) |\"" '{print $3}')
            fi
            echo Using code signing identity $IDENTITY
        fi
        sed -i -e "s/\'CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\': \'iPhone Developer\',/\'CODE_SIGN_IDENTITY[sdk=iphoneos*]\': \'$IDENTITY\',/" $WEBRTC/src/build/common.gypi
    fi
}

# Set the base of the GYP defines, instructing gclient runhooks what to generate
function wrbase() {
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1"
    if [ "$WEBRTC_TARGET" != "AppRTCDemo" ]; then
        GYP_DEFINES="$GYP_DEFINES chromium_ios_signing=0"
    fi
    export GYP_GENERATORS="ninja,xcode-ninja"
}

# Add the iOS Device specific defines on top of the base
function wrios_armv7() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=armv7 arm_neon=1"
    export GYP_GENERATOR_FLAGS="output_dir=out_ios_armeabi_v7a"
    export GYP_CROSSCOMPILE=1
}

# Add the iOS ARM 64 Device specific defines on top of the base
function wrios_armv8() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=arm64 target_subarch=arm64"
    export GYP_GENERATOR_FLAGS="output_dir=out_ios_arm64_v8a"
    export GYP_CROSSCOMPILE=1
}

# Add the iOS Simulator X86 specific defines on top of the base
function wrX86() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=ia32"
    export GYP_GENERATOR_FLAGS="output_dir=out_ios_x86"
}

# Add the iOS Simulator X64 specific defines on top of the base
function wrX86_64() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=x64 target_subarch=arm64"
    export GYP_GENERATOR_FLAGS="output_dir=out_ios_x86_64"
}

# Add the Mac 64 bit intel defines
function wrMac64() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=mac target_arch=x64 use_system_ssl=1 use_openssl=0 use_nss=0 mac_sdk=10.9"
    export GYP_GENERATOR_FLAGS="output_dir=out_mac_x86_64"
}

# Gets the revision number of the current WebRTC svn repo on the filesystem
function get_revision_number() {
    # Try for svn by default
    REVISION_NUMBER=`svn info "$WEBRTC/src" | awk '{ if ($1 ~ /Revision/) { print $2 } }'`

    # If not set then user is probably using git
    if [ -z "$REVISION_NUMBER" ]
    then
        cd "$WEBRTC/src"
        REVISION_NUMBER=`git describe --tags  | sed 's/\([0-9]*\)-.*/\1/'`
        cd - > /dev/null
    fi

    echo $REVISION_NUMBER
}

# This function allows you to pull the latest changes from WebRTC without doing an entire clone, much faster to build and try changes
# Pass in a revision number as an argument to pull that specific revision ex: update2Revision 6798
function update2Revision() {
    # Ensure that we have gclient added to our environment, so this function can run standalone
    pull_depot_tools
    cd $WEBRTC

    # Setup gclient config
    echo Configuring gclient for iOS build
    if [ -z $USER_WEBRTC_URL ]
    then
        echo "User has not specified a different webrtc url. Using default"
        gclient config --name=src "$DEFAULT_WEBRTC_URL"
    else
        echo "User has specified their own webrtc url $USER_WEBRTC_URL"
        gclient config --name=src "$USER_WEBRTC_URL"
    fi

    # # Make sure that the target os is set to JUST MAC at first by adding that to the .gclient file that gclient config command created
    # # Note this is a workaround until one of the depot_tools/ios bugs has been fixed
    # echo "target_os = ['mac']" >> .gclient
    # if [ -z $1 ]
    # then
    #     sync
    # else
    #     sync "$1"
    # fi

    # # Delete the last line saying we will only build for mac
    # sed -i "" '$d' .gclient

    # Write mac and ios to the target os in the gclient file generated by gclient config
    echo "target_os = ['ios', 'mac']" >> .gclient

    if [ -z $1 ]
    then
        sync
    else
        sync "$1"
    fi

    # Inject the new libWebRTC_objc target so that we can build the files that we need and exclude socket rocket and such
    if [ "$WEBRTC_TARGET" == "libWebRTC_objc" ] ; then
        echo "Adding a new libWebRTC_objc target"
        echo "$PROJECT_DIR/insert_before_text.py" 
        python "$PROJECT_DIR/insert_before_text.py"  "$WEBRTC/src/talk/libjingle_examples.gyp"
        # rm "$WEBRTC/src/talk/libjingle_examples.gyp"
        # mv "webrtc/src/talk/libjingle_examples.gyp1" "$WEBRTC/src/talk/libjingle_examples.gyp"
    fi
    echo "-- webrtc has been successfully updated"
}

# This function cleans out your webrtc directory and does a fresh clone -- slower than a pull
# Pass in a revision number as an argument to clone that specific revision ex: clone 6798
function clone() {
    DIR=`pwd`

    rm -rf $WEBRTC
    mkdir -v $WEBRTC

    update2Revision "$1"
}

# Fire the sync command. Accepts an argument as the revision number that you want to sync to
function sync() {
    pull_depot_tools
    cd $WEBRTC
    choose_code_signing
    if [ -z $1 ]
    then
        gclient sync || true
    else
        gclient sync -r "$1" || true
    fi
}

# Convenience function to copy the headers by creating a symbolic link to the headers directory deep within webrtc src
function copy_headers() {
    if [ ! -h "$WEBRTC/headers" ]; then
        create_directory_if_not_found "$BUILD"
        ln -s "$WEBRTC/src/talk/app/webrtc/objc/public/" "$WEBRTC/headers" || true
    fi
}

function build_webrtc_mac() {
    cd "$WEBRTC/src"

    wrMac64
    choose_code_signing
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        exec_ninja "out_mac_x86_64/Debug/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-mac-x86_64-Debug.a" $WEBRTC/src/out_mac_x86_64/Debug/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        exec_ninja "out_mac_x86_64/Release/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-mac-x86_64-Release.a" $WEBRTC/src/out_mac_x86_64/Release/*.a
        exec_strip "$BUILD/libWebRTC-$WEBRTC_REVISION-mac-x86_64-Release.a"
    fi
}

# Build AppRTC Demo for the simulator (ia32 architecture)
function build_apprtc_sim() {
    cd "$WEBRTC/src"

    wrX86
    choose_code_signing
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        exec_ninja "out_ios_x86/Debug-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86-Debug.a" $WEBRTC/src/out_ios_x86/Debug-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        exec_ninja "out_ios_x86/Profile-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86-Profile.a" $WEBRTC/src/out_ios_x86/Profile-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        exec_ninja "out_ios_x86/Release-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86-Release.a" $WEBRTC/src/out_ios_x86/Release-iphonesimulator/*.a
        exec_strip "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86-Release.a"
    fi
}

# Build AppRTC Demo for the 64 bit simulator (x86_64 architecture)
function build_apprtc_sim64() {
    cd "$WEBRTC/src"

    wrX86_64
    choose_code_signing
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        exec_ninja "out_ios_x86_64/Debug-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86_64-Debug.a" $WEBRTC/src/out_ios_x86_64/Debug-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        exec_ninja "out_ios_x86_64/Profile-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86_64-Profile.a" $WEBRTC/src/out_ios_x86_64/Profile-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        exec_ninja "out_ios_x86_64/Release-iphonesimulator/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86_64-Release.a" $WEBRTC/src/out_ios_x86_64/Release-iphonesimulator/*.a
        exec_strip "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86_64-Release.a"
    fi
}

# Build AppRTC Demo for a real device
function build_apprtc() {
    cd "$WEBRTC/src"

    wrios_armv7
    choose_code_signing
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        exec_ninja "out_ios_armeabi_v7a/Debug-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-armeabi_v7a-Debug.a" $WEBRTC/src/out_ios_armeabi_v7a/Debug-iphoneos/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        exec_ninja "out_ios_armeabi_v7a/Profile-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-armeabi_v7a-Profile.a" $WEBRTC/src/out_ios_armeabi_v7a/Profile-iphoneos/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        exec_ninja "out_ios_armeabi_v7a/Release-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-armeabi_v7a-Release.a" $WEBRTC/src/out_ios_armeabi_v7a/Release-iphoneos/*.a
        exec_strip "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-armeabi_v7a-Release.a"
    fi
}


# Build AppRTC Demo for an armv7 real device
function build_apprtc_arm64() {
    cd "$WEBRTC/src"

    wrios_armv8
    choose_code_signing
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        exec_ninja "out_ios_arm64_v8a/Debug-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-arm64_v8a-Debug.a" $WEBRTC/src/out_ios_arm64_v8a/Debug-iphoneos/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        exec_ninja "out_ios_arm64_v8a/Profile-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-arm64_v8a-Profile.a" $WEBRTC/src/out_ios_arm64_v8a/Profile-iphoneos/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        exec_ninja "out_ios_arm64_v8a/Release-iphoneos/"
        exec_libtool "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-arm64_v8a-Release.a" $WEBRTC/src/out_ios_arm64_v8a/Release-iphoneos/*.a
        exec_strip "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-arm64_v8a-Release.a"
    fi
}

# This function is used to put together the intel (simulator), armv7 and arm64 builds (device) into one static library so its easy to deal with in Xcode
# Outputs the file into the build directory with the revision number
function lipo_intel_and_arm() {
    if [ "$WEBRTC_DEBUG" = true ] ; then
        lipo_for_configuration "Debug"
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        lipo_for_configuration "Profile"
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        lipo_for_configuration "Release"
    fi
}

function lipo_for_configuration() {
    CONFIGURATION=$1
    WEBRTC_REVISION=`get_revision_number`

    # Directories to use for lipo, armv7 and ia32 as default
    LIPO_DIRS="$BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86-$CONFIGURATION.a $BUILD/libWebRTC-$WEBRTC_REVISION-ios-armeabi_v7a-$CONFIGURATION.a"
    # Add ARM64
    LIPO_DIRS="$LIPO_DIRS $BUILD/libWebRTC-$WEBRTC_REVISION-ios-arm64_v8a-$CONFIGURATION.a"
    # and add x86_64
    LIPO_DIRS="$LIPO_DIRS $BUILD/libWebRTC-$WEBRTC_REVISION-ios-x86_64-$CONFIGURATION.a"

    # Lipo the simulator build with the ios build into a universal library
    lipo -create $LIPO_DIRS -output $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a

    # Delete the latest symbolic link just in case :)
    if [ -a $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a ]
    then
        rm $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a
    fi

    # Create a symbolic link pointing to the exact revision that is the latest. This way I don't have to change the xcode project file every time we update the revision number, while still keeping it easy to track which revision you are on
    ln -sf $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a

    # Make it clear which revision you are using .... You don't want to get in the state where you don't know which revision you were using... trust me
    echo "The libWebRTC-LATEST-Universal-$CONFIGURATION.a in this same directory, is revision " > $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a.version.txt

    # Also write to a file for funzies
    echo $WEBRTC_REVISION >> $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a.version.txt

    # Write the version down to a file
    echo "Architectures Built" >> $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a.version.txt
    echo "ia32 - Intel x86" >> $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a.version.txt
    echo "ia64 - Intel x86_64" >> $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a.version.txt
    echo "armv7 - Arm x86" >> $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a.version.txt
    echo "arm64_v8a - Arm 64 (armv8)" >> $BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-$CONFIGURATION.a.version.txt
}

# Convenience method to just "get webrtc" -- a clone
# Pass in an argument if you want to get a specific webrtc revision
function get_webrtc() {
    pull_depot_tools
    update2Revision "$1"
}

# Build webrtc for an ios device and simulator, then create a universal library
function build_webrtc() {
    pull_depot_tools
    build_apprtc
    build_apprtc_arm64
    build_apprtc_sim
    build_apprtc_sim64
    lipo_intel_and_arm
}

# Create the static library, requires an argument specifiying Debug or Release
function create_archive_of_static_libraries() {
    echo Get the current working directory so we can change directories back when done
    WORKING_DIR=`pwd`
    VERSION_BUILD=0
    WEBRTC_REVISION=`get_revision_number`

    echo "Creating Static Library"
    create_directory_if_not_found "$BUILD/archives"
    rm -rf "$BUILD/archives/$WEBRTC_REVISION/$1"
    create_directory_if_not_found "$BUILD/archives/$WEBRTC_REVISION"
    create_directory_if_not_found "$BUILD/archives/$WEBRTC_REVISION/$1"
    
    create_directory_if_not_found "$BUILD/archives/LATEST/"
	ln -sfv "$BUILD/archives/$WEBRTC_REVISION/$1" "$BUILD/archives/LATEST/"

    cd "$BUILD/archives/$WEBRTC_REVISION/$1"

    create_directory_if_not_found libjingle_peerconnection/
    
    # Copy podspec with ios and mac
    cp -v "$PROJECT_DIR/libjingle_peerconnection.podspec" "libjingle_peerconnection.podspec"

    # inject pod url
    if [ -z $USER_POD_URL ]
    then
        echo "User has not specified a different pod url. Using default"
        sed -ic "s|{POD_URL}|"$DEFAULT_POD_URL"|g" libjingle_peerconnection.podspec
    else
        echo "User has specified their own pod url $USER_POD_URL"
        sed -ic "s|{POD_URL}|"$USER_POD_URL"|g" libjingle_peerconnection.podspec
    fi
    
    # inject revision number
    sed -ic "s/{WEBRTC_REVISION}/$WEBRTC_REVISION/g" libjingle_peerconnection.podspec
    # inject build type string
    sed -ic "s/{BUILD_TYPE_STRING}/$1/g" libjingle_peerconnection.podspec
    
    if [ $1 = "Debug" ] 
    then
        VERSION_BUILD=`get_version_build "$WEBRTC_REVISION" 0`
        cp -fv "$BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-Debug.a" "libjingle_peerconnection/libWebRTC.a"
        cp -fv "$BUILD/libWebRTC-$WEBRTC_REVISION-mac-x86_64-Debug.a" "libjingle_peerconnection/libWebRTC-osx.a"
        sed -ic "s/{BUILD_TYPE}/0/g" libjingle_peerconnection.podspec
        sed -ic "s/{VERSION_BUILD}/$VERSION_BUILD/g" libjingle_peerconnection.podspec
    fi
    if [ $1 = "Release" ] 
    then
        VERSION_BUILD=`get_version_build "$WEBRTC_REVISION" 2`
        cp -fv "$BUILD/libWebRTC-$WEBRTC_REVISION-arm-intel-Release.a" "libjingle_peerconnection/libWebRTC.a"
        cp -fv "$BUILD/libWebRTC-$WEBRTC_REVISION-mac-x86_64-Release.a" "libjingle_peerconnection/libWebRTC-osx.a"
        sed -ic "s/{BUILD_TYPE}/2/g" libjingle_peerconnection.podspec
        sed -ic "s/{VERSION_BUILD}/$VERSION_BUILD/g" libjingle_peerconnection.podspec
    fi

    # write the revision and build type into a file
    echo "revision $WEBRTC_REVISION $1 build" > "libjingle_peerconnection/libjingle_peerconnection_revision_build.txt"
    
    # add headers
    cp -fvR "$WEBRTC/src/talk/app/webrtc/objc/public/" "libjingle_peerconnection/Headers"

    # Compress artifact
    tar --use-compress-prog=pbzip2 -cvLf "libWebRTC.tar.bz2" *

    echo Go back to working directory
    cd $WORKING_DIR
}

# Grabs the current version build based on what is
function get_version_build() {
    # Set version build
    VERSION_BUILD=0

    # Create temp output file to parse
    pod search libjingle_peerconnection > /tmp/libjingle_search.log

    if [ -z $USER_POD_URL ]
    then
        VERSION_BUILD=`egrep -o 'Versions: .*\[master repo\]' /tmp/libjingle_search.log | egrep -o '\d+\.\d\.\d+' | awk -v REVISION_NUM="$1" -v BUILD_TYPE="$2" -F '.' 'BEGIN{ VERSION_COUNT = 0 }; { if ($1 == REVISION_NUM && $2 == BUILD_TYPE) VERSION_COUNT += 1 }; END{ print VERSION_COUNT };'`
    else
        VERSION_BUILD=`egrep -o '\[master repo\].*' /tmp/libjingle_search.log | egrep -o '\d+\.\d\.\d+' | awk -v REVISION_NUM="$1" -v BUILD_TYPE="$2" -F '.' 'BEGIN{ VERSION_COUNT = 0 }; { if ($1 == REVISION_NUM && $2 == BUILD_TYPE) VERSION_COUNT += 1 }; END{ print VERSION_COUNT };'`
    fi

    echo "$VERSION_BUILD"
}

# Create an iOS "framework" for distribution sans CocoaPods
function create_ios_framework() {
    if [ "$WEBRTC_DEBUG" = true ] ; then
        create_ios_framework_for_configuration "Debug"
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        create_ios_framework_for_configuration "Profile"
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        create_ios_framework_for_configuration "Release"
    fi
}

function create_ios_framework_for_configuration () {
    CONFIGURATION=$1

    rm -rf $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework
    mkdir -p $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework/Versions/A/Headers
    cp $WEBRTC/src/talk/app/webrtc/objc/public/*.h $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework/Versions/A/Headers
    cp $WEBRTC/libWebRTC-LATEST-Universal-$CONFIGURATION.a $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework/Versions/A/WebRTC

    pushd $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework/Versions
    ln -sfh A Current
    popd
    pushd $WEBRTC/Framework/$CONFIGURATION/WebRTC.framework
    ln -sfh Versions/Current/Headers Headers
    ln -sfh Versions/Current/WebRTC WebRTC
    popd
}

# Get webrtc then build webrtc
function dance() {
    # These next if statement trickery is so that if you run from the command line and don't set anything to build, it will default to the debug profile.
    BUILD_DEBUG=true

    if [ "$WEBRTC_RELEASE" = true ] ; then
        BUILD_DEBUG=false
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        BUILD_DEBUG=false
    fi

    if [ "$BUILD_DEBUG" = true ] ; then
        WEBRTC_DEBUG=true
    fi

    get_webrtc $@
    build_webrtc
    echo "Finished Dancing!"
}
