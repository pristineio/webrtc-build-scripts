Pod::Spec.new do |s|
  s.name         = "libjingle_peerconnection"
  s.version      = "{WEBRTC_REVISION}.{BUILD_TYPE}.{VERSION_BUILD}"
  s.summary      = "WebRTC Video Streaming Peer Connection API's. An iOS WebRTC demo application hosted on App Engine. Builds by Pristine.io"
  s.description      = <<-DESC
                       The WebRTC native APIs are implemented based on the following [WebRTC spec.](http://dev.w3.org/2011/webrtc/editor/webrtc.html) 

                       The code that implements WebRTC native APIs (including the Stream and the PeerConnection APIs) are available in [libjingle](https://code.google.com/p/libjingle/source/browse/#svn%2Ftrunk%2Ftalk%2Fapp%2Fwebrtc). A [sample client application](https://code.google.com/p/libjingle/source/browse/#svn%2Ftrunk%2Ftalk%2Fexamples%2Fpeerconnection%2Fclient) is also provided there. 

                       The target audience of this document are those who want to use WebRTC Native APIs to develop native RTC applications.
                       DESC
  s.homepage     = "https://github.com/pristineio/webrtc-build-scripts"
  s.ios.platform = :ios, '7.0'
  s.osx.platform = :osx, '10.8'
  s.author       = { "Rahul Behera" => "rahul@pristine.io" }
  s.social_media_url = 'https://twitter.com/bot_the_builder'
  s.source       = { :http => "{POD_URL}/{WEBRTC_REVISION}/{BUILD_TYPE_STRING}/{VERSION_BUILD}/libWebRTC.tar.bz2" }
  s.ios.source_files =  'libjingle_peerconnection/Headers/*.h'
  s.osx.source_files =  'libjingle_peerconnection/Headers/*.h'
  s.osx.public_header_files = "libjingle_peerconnection/Headers/*.h"
  s.ios.public_header_files = "libjingle_peerconnection/Headers/*.h"
  s.ios.preserve_paths = 'libjingle_peerconnection/libWebRTC.a'
  s.ios.vendored_libraries = 'libjingle_peerconnection/libWebRTC.a'
  s.osx.preserve_paths = 'libjingle_peerconnection/libWebRTC-osx.a'
  s.osx.vendored_libraries = 'libjingle_peerconnection/libWebRTC-osx.a'
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'
  s.source_files =  'libjingle_peerconnection/Headers/*.h'
  s.osx.framework = 'AVFoundation', 'AudioToolbox', 'CoreGraphics', 'CoreMedia', 'GLKit', 'QTKit', 'CoreAudio', 'CoreVideo', 'VideoToolbox'
  s.ios.framework = 'AVFoundation', 'AudioToolbox', 'CoreGraphics', 'CoreMedia', 'GLKit', 'UIKit', 'VideoToolbox'
  s.libraries = 'c', 'sqlite3', 'stdc++'
  s.requires_arc = true
  s.xcconfig  =  { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/libjingle_peerconnection"',
                   'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Headers/libjingle_peerconnection"' }
  s.license      = {
    :type => 'http://www.webrtc.org/license-rights/license',
    :text => <<-LICENSE
      Copyright (c) 2011, The WebRTC project authors. All rights reserved.

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are
      met:

        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in
          the documentation and/or other materials provided with the
          distribution.

        * Neither the name of Google nor the names of its contributors may
          be used to endorse or promote products derived from this software
          without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
      A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
      HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
      LICENSE
  }
end
