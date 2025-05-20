#!/bin/bash

# === CONFIG === #
userAccount='misp'
apacheAccount='www-data'
filePath='/var/www/MISP'

# === COLORS === #
BLUE="\e[34m"
GREEN="\e[32m"
RESET="\e[0m"

# === Functions === #
function displayOwner ()
{
    ownerVar=$(stat /var/www/MISP/ -c %U)
    echo "--------------------------------"
    echo -e "Owner: ${1}$ownerVar${RESET}"
    echo "Path : $filePath"
}

function checkOwnerLogic ()
{
    if [[ "$ownerVar" != "$apacheAccount" ]]; then
        newOwner="$apacheAccount"
    else
        newOwner="$userAccount"
    fi
    sudo chown -R "$newOwner:$newOwner" "$filePath"

}

# === Main === #
displayOwner $BLUE
checkOwnerLogic
echo -e "\nUpdated ownership!"
displayOwner $GREEN
