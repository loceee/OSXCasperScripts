#!/bin/bash

template="/System/Library/User Template/English.lproj"

# Set Apple Mouse button 1 to Primary click and button 2 to Secondary click.
defaults write "${template}/Library/Preferences/com.apple.driver.AppleHIDMouse" Button1 -integer 1
defaults write "${template}/Library/Preferences/com.apple.driver.AppleHIDMouse" Button2 -integer 2

# Set Apple Magic Mouse button 1 to Primary click and button 2 to Secondary click.
defaults write "${template}/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.mouse" MouseButtonMode -string TwoButton

exit
