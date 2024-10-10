#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/full-22.04.sh | bash

FILE=/surveily-init

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-22.04.sh | bash
   #apt install -y openvpn
   #wget -O /etc/openvpn/dc.conf https://raw.githubusercontent.com/Surveily/Images/refs/heads/master/script/ovpn/dc.ovpn
   #echo 'AUTOSTART="dc"' >> /etc/default/openvpn
   #systemctl daemon-reload
   #systemctl restart openvpn
   touch $FILE
   reboot
fi

FILE=/surveily-k3s

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   echo "File $FILE not exists."
   curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/k3s-multi-agent.sh | sh -s -- 10.100.1.10
   touch $FILE
   reboot
fi
