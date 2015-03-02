#!/bin/bash
# locale / region osx
applelocale="${4}"
countycode="${5}"

[ -z "${applelocale}" ] && applelocale="en_AU"
[ -z "${countycode}" ] && countycode="AU"

defaults write /Library/Preferences/.GlobalPreferences AppleLocale ${applelocale}
defaults write /Library/Preferences/.GlobalPreferences Country ${countycode}

exit 0
