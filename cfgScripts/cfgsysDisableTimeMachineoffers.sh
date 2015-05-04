#!/bin/bash
#
# disable time machine offers

echo "Disabling Time Machine new disk offers..."
defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

exit 0
