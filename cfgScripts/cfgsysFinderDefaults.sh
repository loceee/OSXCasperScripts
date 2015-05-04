#!/bin/bash
#
# set finder defaults me likey

template="/System/Library/User Template/English.lproj"

echo "set Finder default .."
defaults write "${template}/Library/Preferences/com.apple.finder" NewWindowTarget -string PfCm

exit 0
