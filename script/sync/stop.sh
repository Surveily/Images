#!/bin/bash

set -e

USER=$1
FOLDER=$2
FILE=/home/$USER/.nas-credentials

if test -f "$FILE"; then
    rsync -avPH /home/$USER/$FOLDER /home/$USER/.surveily/sync/
fi
