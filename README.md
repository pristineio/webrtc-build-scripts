##WebRTC Build Scripts
A set of build scripts useful for building WebRTC libraries for Android and iOS.

###Android
The following instructions are for building the native WebRTC libraries for Android.


####Getting Started
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

Then you can build the Android example
```shell

# Build apprtc
build_apprtc

# Build in debug mode
build_debug_apprtc

```

When the scripts are done you can find the .jar and .so file in $WEBRTC_HOME under "libjingle\_peerconnection\_builds".

###iOS
Coming soon...
