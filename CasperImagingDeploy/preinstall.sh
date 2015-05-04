#!/bin/bash
#
# start casperimaging

jssurl="https://jss.youthplus.edu.au:8443"
#invalidcert=false
invalidcert=true

userloggedin="$(who | grep console | awk '{print $1}')"

sudo -u ${userloggedin} defaults write com.jamfsoftware.jss allowInvalidCertificate -bool $invalidcert
sudo -u ${userloggedin} defaults write com.jamfsoftware.jss url -string "$jssurl"

exit 0
