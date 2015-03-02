#!/bin/bash
# set default desktop (mav / yoyo)
desktopimg="${4}"

echo "setting default desktop to ${desktopimg}"
rm /System/Library/CoreServices/DefaultDesktop.jpg
ln -s "${desktopimg}" /System/Library/CoreServices/DefaultDesktop.jpg

exit 0
