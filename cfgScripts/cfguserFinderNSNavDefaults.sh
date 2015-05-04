#!/bin/bash
#
# settng new Finder to open PFCm (computer, will show mounted shares)
# setting NSNav to open 'target' so save dialogs land at target (~/Documents/Servers)

user="${3}"
target="${4}"

echo "set Finder NewWindowTarget to PfDo .."
sudo -u ${user} defaults write com.apple.finder NewWindowTarget -string PfDo

# ms office doesnt' seem to respect this
echo "set NSNavpanel to ${target} and expanded .."
sudo -u ${user} defaults write NSGlobalDomain NSNavLastRootDirectory -string "${target}"
sudo -u ${user} defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

exit 0
