#!/usr/bin/python

import sys

FILE = sys.argv[1]

FIND = "{ 'target_name': 'apprtc_signaling'"
PREPEND = """        { 'target_name': 'libWebRTC_objc', # Injected target using github.com/pristineio/webrtc-build-scripts
          'type': 'shared_library', # We are creating a dummy shared_library so all the dependencies are built as static libraries. i think this is a bug
          'dependencies': [
            'libjingle.gyp:libjingle_peerconnection_objc',
          ],
          'sources': [
          ],
          'export_dependent_settings': [
            'libjingle.gyp:libjingle_peerconnection_objc',
          ],
        },
"""

def findSubstringInLines(lines, find):
    for i, line in enumerate(lines):
        if find in line:
            return i
    return -1

def isStringAlreadyPrepended(f, s):
    with open(f) as content:
        data = content.read()
        return s in data

if isStringAlreadyPrepended(FILE, PREPEND):
    exit(0)

with open(FILE, 'r+') as content:
    lines = content.readlines()
    index = findSubstringInLines(lines, FIND)

if index < 0:
    exit(-1)

lines.insert(index, PREPEND)

with open(FILE, 'r+') as content:
    content.write("".join(lines))
    content.truncate()
