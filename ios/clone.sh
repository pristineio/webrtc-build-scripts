#!/bin/sh

#  clone.sh
#  WebRTC
#
#  Created by Rahul Behera on 6/18/14.
#  Copyright (c) 2014 Pristine, Inc. All rights reserved.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SOURCE="$(readlink "$SOURCE")"
[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

source "$PROJECT_DIR/build.sh"
pull_depot_tools
rm -rf "$PROJECT_DIR/webrtc/src"
get_webrtc
