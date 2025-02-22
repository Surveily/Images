#!/bin/bash

set -e

USER=$1
FOLDER=$2
NASPATH=//nas.surveily.com/home

# Delete existing credentials
USERID=$(id -u $USER)
FILE=/home/$USER/.nas-credentials

if test -f "$FILE"; then
    # Mount shares
    OPTIONS="credentials=$FILE,uid=$USERID,gid=$USERID,file_mode=0600,_netdev"

    # Test before syncing
    mkdir -p /home/$USER/.surveily/sync/$FOLDER
    mount -o $OPTIONS $NASPATH/$FOLDER /home/$USER/.surveily/sync/$FOLDER

    cp -r /home/$USER/$FOLDER /home/$USER/.surveily/sync/$FOLDER
fi
