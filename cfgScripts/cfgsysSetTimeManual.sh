#!/bin/bash
# set timezone manually
tzone="${4}"
tserv="${5}"

[ -z "${tzone}" ] && tzone="Australia/Brisbane"
[ -z "${tserv}" ] && tserv="time.asia.apple.com"

defaults write /Library/Preferences/com.apple.timezone.auto Active -bool False

systemsetup -setusingnetworktime on
systemsetup -settimezone ${tzone} -setnetworktimeserver ${tserv}

ntpdate -bvs ${tserv}

exit 0
