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

# We use the term webrtc dance a lot
dance

```
