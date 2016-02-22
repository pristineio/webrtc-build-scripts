#!/usr/bin/python

import sys, ast, json

FILE = sys.argv[1]

FIND = """    ['OS=="ios" or (OS=="mac" and target_arch!="ia32")', {"""
APPEND = """        { 'target_name': 'libWebRTC_objc', # Injected target using github.com/pristineio/webrtc-build-scripts
          'type': 'shared_library', # We are creating a dummy shared_library so all the dependencies are built as static libraries. i think this is a bug
          'dependencies': [
            '<(webrtc_root)/system_wrappers/system_wrappers.gyp:field_trial_default',
            '../talk/app/webrtc/legacy_objc_api.gyp:libjingle_peerconnection_objc',
          ],
          'sources': [
          ],
          'export_dependent_settings': [
            '../talk/app/webrtc/legacy_objc_api.gyp:libjingle_peerconnection_objc',
          ],
        },
"""

def findSubstringInLines(lines, find):
    for i, line in enumerate(lines):
        if find in line:
            return i
    return -1

def isStringAlreadyAppended(f, s):
    with open(f) as content:
        data = content.read()
        return s in data

if isStringAlreadyAppended(FILE, APPEND):
    exit(0)

with open(FILE, 'r+') as content:
    lines = content.readlines()
    index = findSubstringInLines(lines, FIND)

if index < 0:
    exit(-1)

lines.insert(index + 2, APPEND)

with open(FILE, 'r+') as content:
    content.write("".join(lines))
    content.truncate()
