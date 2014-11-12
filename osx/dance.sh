#!/bin/sh

#  dance.sh
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

# I am unable to update past 6938. I will update a fix soon.
update2Revision 6937

build_webrtc
echo "Finished Dancing!"

