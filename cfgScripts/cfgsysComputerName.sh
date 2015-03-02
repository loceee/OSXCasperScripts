#!/bin/bash
# sets the computer/host names to prefix-$serial, triming to last places of serial

prefix="${4}"
length=15

serial=$(ioreg -c "IOPlatformExpertDevice" | awk -F '"' '/IOPlatformSerialNumber/ {print $4}')

lenprefix=${#prefix}
trimserial=$(( length - lenprefix + 1))
serialtrim=$(echo ${serial} | tail -c ${trimserial})

computername=$(echo "${prefix}${serialtrim}")

echo "setting computername to ${computername} ..."
scutil --set ComputerName "${computername}"
scutil --set HostName "${computername}"
scutil --set LocalHostName "${computername}"

exit
