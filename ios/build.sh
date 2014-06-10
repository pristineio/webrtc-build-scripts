# !/bin/bash

PROJECT_DIR="$HOME"
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
        gclient sync
    else
        gclient sync --revision "src@$1"
    fi
 
    sed -i "" '$d' .gclient
    echo "target_os = ['ios', 'mac']" >> .gclient
    
    
    if [ -z $1 ] 
        then
        gclient sync
    else
        gclient sync --revision "src@$1"
    fi

    echo "-- webrtc has been sucessfully fetched"
    gclient runhooks
}


function build_apprtc () {
    cd "$WEBRTC/trunk"

    create_directory_if_not_found "$BUILD"
    create_directory_if_not_found "$BUILD/headers"
    cp -R $WEBRTC/trunk/talk/app/webrtc/objc/public/*.h $BUILD/headers
    
    ninja -C "out_ios/Debug-iphoneos/" AppRTCDemo
    create_directory_if_not_found "$BUILD/Debug-iphoneos"
    cp -R $WEBRTC/trunk/out_ios/Debug-iphoneos/*.a $BUILD/Debug-iphoneos

    ninja -C "out_ios/Profile-iphoneos/" AppRTCDemo
    create_directory_if_not_found "$BUILD/Profile-iphoneos"
    cp -R $WEBRTC/trunk/out_ios/Profile-iphoneos/*.a $BUILD/Profile-iphoneos

    ninja -C "out_ios/Release-iphoneos/" AppRTCDemo
    create_directory_if_not_found "$BUILD/Release-iphoneos"
    cp -R $WEBRTC/trunk/out_ios/Release-iphoneos/*.a $BUILD/Release-iphoneos
    open "$BUILD"
}

function dance() {
    pull_depot_tools
    fetch "$1"
    build_apprtc
}
