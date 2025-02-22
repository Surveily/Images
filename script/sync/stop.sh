#!/bin/bash

set -e

USER=$1
FOLDER=$2
NASPATH=//nas.surveily.com/home

# Delete existing credentials
USERID=$(id -u $USER)
FILE=/home/$USER/.nas-credentials

if test -f "$FILE"; then
    cp -r /home/$USER/$FOLDER /home/$USER/.surveily/sync/$FOLDER
fi
