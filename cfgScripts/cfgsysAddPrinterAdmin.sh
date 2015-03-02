#!/bin/bash
# pass it a domain group, or default to everyone (all user accounts on computers)
# everyone is good for staff / student macs
#
group="${4}"

[ -z "${group}" ] && countycode="everyone"

dseditgroup -o edit -n /Local/Default -a ${group} -t group lpadmin

exit 0
