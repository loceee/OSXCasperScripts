#!/bin/bash
# Use 'openssl' to create an encrypted string for script parameters
# obscure creds from jamf console when passing account credentials from the JSS to a client
#
# based on jamfIT's script - https://github.com/jamfit/Encrypted-Script-Parameters
# but easier and more reusable
# lach
clear

read -p "username: " username
read -s -p "password: " password
echo
read -p "salt (or blank to gen): " SALT
read -p "key (or blank to gen): " KEY

# Usage ~$ GenerateEncryptedString "String"
[ -z ${SALT} ] && SALT=$(openssl rand -hex 8)
[ -z ${KEY} ] && KEY=$(openssl rand -hex 12)
username_enc=$(echo "${username}" | openssl enc -aes256 -a -A -S "${SALT}" -k "${KEY}")
password_enc=$(echo "${password}" | openssl enc -aes256 -a -A -S "${SALT}" -k "${KEY}")

clear
echo '
--- pass these encrypted creds to your script from the jamf policy ---

username_enc: '${username_enc}'
password_enc: '${password_enc}'

-----------------8<----- add this to your jamf script -----8<-------------------

################################################################################
#
# decrypt credentials - jamfCredEncrypter.sh
#
################################################################################

username_enc="${4}"
password_enc="${5}"
salt="'${SALT}'"
key="'${KEY}'"

username=$(echo "${username_enc}" | openssl enc -aes256 -d -a -A -S "${salt}" -k "${key}")
password=$(echo "${password_enc}" | openssl enc -aes256 -d -a -A -S "${salt}" -k "${key}")

################################################################################

-----------------8<----- add this to your jamf script -----8<-------------------

'
exit
