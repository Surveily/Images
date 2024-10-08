#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/full-22.04.sh | bash

FILE=/surveily-init

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-22.04.sh | bash
   apt install -y openvpn
   touch $FILE
   reboot
fi
