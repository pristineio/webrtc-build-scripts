##PSA - WebRTC builds have moved to using GN instead of GYP. Android build script is adapted, but iOS script is still break. Feel free to fork and update them.

##WebRTC Build Scripts

[![Join the chat at https://gitter.im/pristineio/webrtc-build-scripts](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/pristineio/webrtc-build-scripts?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)</br>
A set of build scripts useful for building WebRTC libraries for Android and iOS.

Bugs: Please submit the [revision](https://code.google.com/p/webrtc/source/list) number that you are using. There are frequent updates to this project so please watch the changelist for bug fixes.

###Android ARMv7, ARMv8, x86, x86_64 Builds -- [Guide here](http://tech.pristine.io/build-android-apprtc/)

The following instructions are for building the native WebRTC libraries for Android.


#### Getting Started
##### On Linux
The scripts can probably work on most distros, although we only have experience with Ubuntu 12.04 and 14.04 on 64 bit machines.

This is only required once.
```shell

# Source all the routines
source android/build.sh

# Install any dependencies needed
install_dependencies

# Pull WebRTC
get_webrtc
```

##### On Mac or Windows
If you don't have a Ubuntu machine available, or you are too lazy to setup a virtual machine manually, you can build WebRTC for Android on your Mac or Windows PC through our Vagrant script.

First of all, you need to [download and install](http://www.vagrantup.com/downloads.html) Vagrant. After that, from the `/android` directory, you need to execute the following in you shell:

```shell

# If you need to use private SSH keys from your host computer 
# Execute this line of code to ensure your private key is added to your identity
ssh-add -L

# If there are no identities, add them by:
ssh-add ~/.ssh/id_rsa

# Boot up and provision the Vagrant box
vagrant up

# SSH into the Vagrant box
vagrant ssh

# Installs the required dependencies on the machine
install_dependencies

```
On Windows machines you may face issues with long path names on the VM that aren't handled correctly. A work around is to copy the script to another directory (not the one shared between the VM and Windows host), and build there:

```shell

mkdir mybuild
cd mybuild
cp /vagrant/build.sh .
source ./build.sh
get_webrtc
build_apprtc

```

#### Building the libraries

Then you can build the Android example

```shell
# Pull WebRTC
get_webrtc

# Build apprtc
build_apprtc

# Build in debug mode
export WEBRTC_DEBUG=true
build_apprtc
```

You can build for armv7, armv8, x86, x86_64 platform

```shell
export WEBRTC_ARCH=armv7 #or armv8, x86, or x86_64
prepare_gyp_defines &&
execute_build
```

You can build a particular [revision](https://code.google.com/p/webrtc/source/list)

```shell
# Pull WebRTC
get_webrtc 6783

# Build apprtc
build_apprtc
```

When the scripts are done you can find the .jar and .so file in $WEBRTC_ROOT under "libjingle\_peerconnection\_builds".



###iOS (armv7, arm64, i386) and Mac (X86_64) -- [Guide here](http://tech.pristine.io/build-ios-apprtc/)
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

Then you can build the iOS example
```shell
# We use the term webrtc dance a lot to build 
dance

# Or in two steps
get_webrtc
# Make changes then build WebRTC
build_webrtc
```
Mac example
```shell
# Get WebRTC
get_webrtc
# Make changes then build WebRTC
build_webrtc_mac
```


Check which [revision](https://code.google.com/p/webrtc/source/list) you are using at ./webrtc-build-scripts/ios/webrtc/libWebRTC-LATEST-Universal-Debug.a.version.txt


Open the [xcode project](https://github.com/pristineio/webrtc-build-scripts/tree/master/ios/WebRTC.xcodeproj), and execute the [AppRTC Demo](https://code.google.com/p/webrtc/source/browse/#svn%2Ftrunk%2Ftalk%2Fexamples%2Fobjc%2FAppRTCDemo) on any iOS 7 device or simulator
```shell
open ./webrtc-build-scripts/ios/WebRTC.xcodeproj
```

You can also build a particular [revision](https://code.google.com/p/webrtc/source/list)
```shell
    #Pull WebRTC
    update2Revision 6783
```
Make changes then,
```shell
    #Build WebRTC
    build_webrtc
```
Make sure you label your new binaries that are generated in 
```shell
./webrtc-build-scripts/ios/webrtc/libjingle_peerconnection_builds 
```

##### Cocoapods!!
[![Version](https://img.shields.io/cocoapods/v/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![License](https://img.shields.io/cocoapods/l/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![Platform](https://img.shields.io/cocoapods/p/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)

###### Usage

To run the example AppRTC Demo project, clone the repo, and run `pod install` from the Example directory first.

###### Requirements
A fast internet connection.... for your own sanity

###### Installation

libjingle_peerconnection starting from revision 6931 is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "libjingle_peerconnection"

iOS  ARM64 builds are available as of 7810.0.0

mac x86_64 builds are available as of 7759.0.0

###Linux x86, x86_64 Builds

The following instructions are for building the native WebRTC libraries for Linux.


#### Getting Started
##### On Linux
The scripts can probably work on most distros, although we only have experience with Ubuntu 12.04, 14.04, 16.04 and 16.10 on 64 bit machines.

This is only required once.
```shell

# Source all the routines
source linux/build.sh

# Install any dependencies needed
install_dependencies

# Pull WebRTC
get_webrtc

# Build apprtc
build_apprtc
```

You can build for arm-linaro-gnueabihf, x86, x86_64 platform

```shell
export WEBRTC_ARCH=x86 #, arm-linaro-gnueabihf or x86_64
prepare_gyp_defines &&
execute_build
```

You can build a particular revision

```shell
# Pull WebRTC
get_webrtc 6783

# Build apprtc
build_apprtc
```

###### Versioning

The versioning can be explained as follows:

 
[6931](https://code.google.com/p/webrtc/source/detail?r=6931).2.0 

6931 reflects the SVN revision from the WebRTC root Google Code Project

2 reflects a Release Build (0 for Debug, 1 for Profile)

Profile builds are no longer built by default

The minor 0 reflects any changes I might need to make to the sample xcode project itself to work (incremented normally)


