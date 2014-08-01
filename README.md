##WebRTC Build Scripts
A set of build scripts useful for building WebRTC libraries for Android and iOS.

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

When the scripts are done you can find the .jar and .so file in $WEBRTC_HOME under "libjingle\_peerconnection\_builds".

###iOS -- [Guide here](http://tech.pristine.io/build-ios-apprtc/)
These steps must be run on Mac OSX

```shell

# Source the ios routines
source ios/build.sh

# EDIT 7/29/14: Forgot to mention that you should specify if you want a debug/profile/release build by executing WEBRTC_DEBUG=true WEBRTC_PROFILE=true or WEBRTC_RELEASE=true ... WHOOPS MY B
# Now it will autoselect debug if you do not specify anything (to help find bugs)

# We use the term webrtc dance a lot
dance

# Open the xcode project, and execute the AppRTC Demo on any iOS 7 device or simulator
open ../../../ios/WebRTC.xcodeproj

```

##### Cocoapods!! Starting from revision 6798
[![Version](https://img.shields.io/cocoapods/v/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![License](https://img.shields.io/cocoapods/l/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)
[![Platform](https://img.shields.io/cocoapods/p/libjingle_peerconnection.svg?style=flat)](http://cocoadocs.org/docsets/libjingle_peerconnection)

###### Usage

To run the example AppRTC Demo project, clone the repo, and run `pod install` from the Example directory first.

###### Requirements
A fast internet connection.... for your own sanity

###### Installation

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

You might see some versions like 6798.2 .. Yes that is revision number 6798 from the [webrtc revision changelist](https://code.google.com/p/webrtc/source/list) and the minor (the .2 part) reflects any change I'd make on the cocoapods project configuration side.


