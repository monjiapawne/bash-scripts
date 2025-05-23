#!/bin/bash
############################################################
# purpose: toggle permissions to a path and all sub-folders
# usage: ./bash-toggle-perms.sh
# adjust variables as required in 'config'
############################################################


# === CONFIG === #
user1='misp'
user2='www-data'
filePath='/var/www/MISP'

# === COLORS === #
BLUE="\e[34m"
GREEN="\e[32m"
RESET="\e[0m"

# === Functions === #
function displayOwner ()
{
    ownerVar=$(stat $filePath -c %U)
    echo "--------------------------------"
    echo -e "Owner: ${1}$ownerVar${RESET}"
    echo "Path : $filePath"
}

function checkOwnerLogic ()
{
    if [[ "$ownerVar" != "$user2" ]]; then
        newOwner="$user2"
    else
        newOwner="$user1"
    fi
    sudo chown -R "$newOwner:$newOwner" "$filePath"

}

# === Main === #
displayOwner $BLUE
checkOwnerLogic
echo -e "\nUpdated ownership!"
displayOwner $GREEN
