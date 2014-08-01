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


WEBRTC="$PROJECT_DIR/webrtc"
DEPOT_TOOLS="$PROJECT_DIR/depot_tools"
BUILD="$WEBRTC/libjingle_peerconnection_builds"
function create_directory_if_not_found() {
    if [ ! -d "$1" ];
    then
        mkdir "$1"
    fi
}

create_directory_if_not_found "$PROJECT_DIR"
create_directory_if_not_found "$WEBRTC"
create_directory_if_not_found "$WEBRTC/WebRTC"


# Update/Get/Ensure the Gclient Depot Tools
function pull_depot_tools() {

    echo Get the current working directory so we can change directories back when done
    WORKING_DIR=`pwd`
    
    echo If no directory where depot tools should be...
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
    echo Go back to working directory
    cd $WORKING_DIR
}

function wrbase() {
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1"
    export GYP_GENERATORS="ninja,xcode"
}

function wrios() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=armv7"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_ios"
    export GYP_CROSSCOMPILE=1
}

function wrsim() {
    wrbase
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=ia32"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_sim"
    export GYP_CROSSCOMPILE=1
}

function get_revision_number() {
    svn info $WEBRTC/trunk | awk '{ if ($1 ~ /Revision/) { print $2 } }'
}

function fetch() {
    
    DIR=`pwd`

    rm -rf $WEBRTC
    mkdir $WEBRTC
    cd $WEBRTC
    gclient config http://webrtc.googlecode.com/svn/trunk
    wrios
    if [ -z $1 ] 
        then
        gclient sync -n
    else
        gclient sync -n --revision "src@$1"
    fi
    sed -i "" '/\-framework IOKit/d' "$WEBRTC/trunk/talk/libjingle.gyp"
    cd "$WEBRTC"
    
    if [ -z $1 ] 
        then
        sync
    else
        sync "$1"
    fi
 
    sed -i "" '$d' .gclient
    echo "target_os = ['ios', 'mac']" >> .gclient
    
    
    if [ -z $1 ]
    then
        sync
    else
        sync "$1"
    fi

    echo "-- webrtc has been sucessfully fetched"

}

function sync() {
    pull_depot_tools
    cd $WEBRTC
    if [ -z $1 ]
    then
        gclient sync
    else
        gclient sync --revision "src@$1"
    fi
}

function copy_headers() {
    create_directory_if_not_found "$BUILD"
    create_directory_if_not_found "$WEBRTC/headers"
    ln -s $WEBRTC/trunk/talk/app/webrtc/objc/public/ $WEBRTC/headers
}

function build_apprtc_sim() {
    cd "$WEBRTC/trunk"
    wrsim
    gclient runhooks

    copy_headers


    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        ninja -C "out_sim/Debug-iphonesimulator/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-sim-Debug.a" $WEBRTC/trunk/out_sim/Debug-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        ninja -C "out_sim/Profile-iphonesimulator/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-sim-Profile.a" $WEBRTC/trunk/out_sim/Profile-iphonesimulator/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        ninja -C "out_sim/Release-iphonesimulator/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-sim-Release.a" $WEBRTC/trunk/out_sim/Release-iphonesimulator/*.a
    fi
}


function build_apprtc() {
    cd "$WEBRTC/trunk"
    wrios
    gclient runhooks

    copy_headers

    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        ninja -C "out_ios/Debug-iphoneos/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-Debug.a" $WEBRTC/trunk/out_ios/Debug-iphoneos/*.a
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        ninja -C "out_ios/Profile-iphoneos/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-Profile.a" $WEBRTC/trunk/out_ios/Profile-iphoneos/*.a
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        ninja -C "out_ios/Release-iphoneos/" AppRTCDemo
        libtool -static -o "$BUILD/libWebRTC-$WEBRTC_REVISION-ios-Release.a" $WEBRTC/trunk/out_ios/Release-iphoneos/*.a
    fi
}

function lipo_ia32_and_armv7() {
    WEBRTC_REVISION=`get_revision_number`
    if [ "$WEBRTC_DEBUG" = true ] ; then
        lipo -create $BUILD/libWebRTC-$WEBRTC_REVISION-sim-Debug.a $BUILD/libWebRTC-$WEBRTC_REVISION-ios-Debug.a -output $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Debug.a
        rm $WEBRTC/libWebRTC-LATEST-Universal-Debug.a
        ln -s $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Debug.a $WEBRTC/libWebRTC-LATEST-Universal-Debug.a
        echo "The libWebRTC-LATEST-Universal-Debug.a in this same directory, is revision " > $WEBRTC/libWebRTC-LATEST-Universal-Debug.a.version.txt
        echo $WEBRTC_REVISION >> $WEBRTC/libWebRTC-LATEST-Universal-Debug.a.version.txt
    fi

    if [ "$WEBRTC_PROFILE" = true ] ; then
        lipo -create $BUILD/libWebRTC-$WEBRTC_REVISION-sim-Profile.a $BUILD/libWebRTC-$WEBRTC_REVISION-ios-Profile.a -output $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Profile.a
        rm $WEBRTC/libWebRTC-LATEST-Universal-Profile.a
        ln -s $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Profile.a $WEBRTC/libWebRTC-LATEST-Universal-Profile.a
        echo "The libWebRTC-LATEST-Universal-Profile.a in this same directory, is revision " > $WEBRTC/libWebRTC-LATEST-Universal-Profile.a.version.txt
        echo $WEBRTC_REVISION >> $WEBRTC/libWebRTC-LATEST-Universal-Profile.a.version.txt
    fi

    if [ "$WEBRTC_RELEASE" = true ] ; then
        lipo -create $BUILD/libWebRTC-$WEBRTC_REVISION-sim-Release.a $BUILD/libWebRTC-$WEBRTC_REVISION-ios-Release.a -output $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Release.a
        rm $WEBRTC/libWebRTC-LATEST-Universal-Release.a
        ln -s $BUILD/libWebRTC-$WEBRTC_REVISION-armv7-ia32-Release.a $WEBRTC/libWebRTC-LATEST-Universal-Release.a
        echo "The libWebRTC-LATEST-Universal-Release.a in this same directory, is revision " > $WEBRTC/libWebRTC-LATEST-Universal-Release.a.version.txt
        echo $WEBRTC_REVISION >> $WEBRTC/libWebRTC-LATEST-Universal-Release.a.version.txt
    fi

}

function get_webrtc() {
    pull_depot_tools
    fetch "$1"
}

function build_webrtc() {
    pull_depot_tools
    build_apprtc
    build_apprtc_sim
    lipo_ia32_and_armv7
}


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


    get_webrtc
    build_webrtc
    echo "Finished Dancing!"
}
