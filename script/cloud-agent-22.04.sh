#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-agent-22.04.sh | bash

FILE=/surveily-init

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-22.04.sh | bash
   touch $FILE
   reboot
fi

FILE=/surveily-k3s

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-wg-join-agent.sh | sh -s -- $(hostname -i | awk '{print $1}') cluster.surveily.com
   touch $FILE
   reboot
fi
