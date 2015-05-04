#!/bin/bash
#
# NO .ds-store files on Network Shares

defaults write /Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores -bool true

exit
