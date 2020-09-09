#!/bin/bash

set -e

if [ ! -f "/etc/varunit/system-init" ]; then
    ./config.sh --unattended --url $URL --auth pat --token $TOKEN --pool "$POOL" --agent $AGENT --replace --acceptTeeEula
    touch /etc/varunit/system-init
fi

docker login $DOCKER_LOGIN.azurecr.io -u $DOCKER_LOGIN -p $DOCKER_PASSWORD

./run.sh
