#!/bin/bash
# kill entries in dockfixup, prevents osx yoyo from "fixing" our dock (eg. adding maps / ibooks)

/usr/libexec/PlistBuddy -c "delete:add-app" /System/Library/CoreServices/Dock.app/Contents/Resources/com.apple.dockfixup.plist
/usr/libexec/PlistBuddy -c "delete:add-doc" /System/Library/CoreServices/Dock.app/Contents/Resources/com.apple.dockfixup.plist

exit
