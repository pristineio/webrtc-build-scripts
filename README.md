##WebRTC Build Scripts
A set of build scripts useful for building WebRTC libraries for Android and iOS.

Bugs: Please submit the [revision](https://code.google.com/p/webrtc/source/list) number that you are using. There are frequent updates to this project so please watch the changelist for bug fixes.

###Android-- [Guide here](http://tech.pristine.io/build-android-apprtc/)
The following instructions are for building the native WebRTC libraries for Android.


#### Getting Started
##### On Linux
You should only need Ubuntu 12.04 on a 64 bit machine to get going.

This is only required once.
```shell

# Source all the routines
source android/build.sh

# Install any dependencies needed
install_dependencies

# Setup jdk
install_jdk1_6

```

##### On Mac or Windows
If you don't have a Ubuntu machine available, or you are too lazy to setup a virtual machine manually, you can build WebRTC for Android on your Mac or Windows PC through our Vagrant script.

First of all, you need to [download and install](http://www.vagrantup.com/downloads.html) Vagrant. After that, from the `/android` directory, you need to execute the following in you shell:

```shell

# Boot up and provision the Vagrant box
vagrant up

# SSH into the Vagrant box
vagrant ssh

```

#### Building the libraries

Then you can build the Android example
```shell
# Build apprtc
build_apprtc

# Build in debug mode
build_debug_apprtc
```

You can build a particular [revision](https://code.google.com/p/webrtc/source/list)
```shell

# Build apprtc
build_apprtc 6783

# Build in debug mode
build_debug_apprtc 6783

```

When the scripts are done you can find the .jar and .so file in $WEBRTC_HOME under "libjingle\_peerconnection\_builds".



###iOS -- [Guide here](http://tech.pristine.io/build-ios-apprtc/)
These steps must be run on Mac OSX

Source the [ios build scripts](https://github.com/pristineio/webrtc-build-scripts/blob/master/ios/build.sh) or  [open the Xcode project](https://github.com/pristineio/webrtc-build-scripts/tree/master/ios/WebRTC.xcodeproj)

```shell
source ios/build.sh
```

Specify if you want to build for Debug/Profile/Release by setting either WEBRTC_DEBUG, WEBRTC_PROFILE, WEBRTC_RELEASE as an environment variable in your bash or xcode scheme run settings.
```shell
WEBRTC_DEBUG=true
WEBRTC_PROFILE=true 
#or
WEBRTC_RELEASE=true
```


#### Building the libraries

Then you can build the Android example
```shell
# We use the term webrtc dance a lot to build 
dance
```
Check which [revision](https://code.google.com/p/webrtc/source/list) you are using at ./webrtc-build-scripts/ios/webrtc/libWebRTC-LATEST-Universal-Debug.a.version.txt


Open the [xcode project](https://github.com/pristineio/webrtc-build-scripts/tree/master/ios/WebRTC.xcodeproj), and execute the [AppRTC Demo](https://code.google.com/p/webrtc/source/browse/#svn%2Ftrunk%2Ftalk%2Fexamples%2Fobjc%2FAppRTCDemo) on any iOS 7 device or simulator
```shell
open ./webrtc-build-scripts/ios/WebRTC.xcodeproj
```

You can also build a particular [revision](https://code.google.com/p/webrtc/source/list)

    #Pull WebRTC
    update2Revision 6783

Make changes then,

    #Build WebRTC
    build_webrtc

Make sure you label your new binaries that are generated in 
```shell
./webrtc-build-scripts/ios/webrtc/libjingle_peerconnection_builds 
```

##### Cocoapods!! Starting from [revision](https://code.google.com/p/webrtc/source/list) 6798 -- Known bug with Git Repo - In the process of moving to HTTP source for binaries
[![Version](https://img.shields.io/cocoapods/v/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![License](https://img.shields.io/cocoapods/l/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![Platform](https://img.shields.io/cocoapods/p/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)

###### Usage

To run the example AppRTC Demo project, clone the repo, and run `pod install` from the Example directory first.

###### Requirements
A fast internet connection.... for your own sanity

###### Installation
--IMPORTANT NOTE-- The Coccoapods bitbucket repo hit the hard filesize limit, I am working with the cocoapods team to move to an HTTP source. Unfortunately the transistion between git and http wasn't smooth but I will update soon.

libjingle_peerconnection is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "libjingle_peerconnection"
    

    # Add this to the bottom so it won't have issues with active architecture
    post_install do |installer_representation|
        installer_representation.project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
                config.build_settings['VALID_ARCHS'] = ['armv7', 'i386']
            end
        end
    end

You might see some versions like 6798.2 .. Yes that is [revision](https://code.google.com/p/webrtc/source/list) number 6798 from the [webrtc changelist](https://code.google.com/p/webrtc/source/list) and the minor (the .2 part) reflects any change I'd make on the cocoapods project configuration side.


