#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-server-22.04.sh | bash

FILE=/surveily-init

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-22.04.sh | bash
   touch $FILE
   reboot
fi

FILE=/surveily-k3s

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-wg-join-server.sh | sh -s -- $(hostname -I) cluster.surveily.com
   touch $FILE
   reboot
fi
