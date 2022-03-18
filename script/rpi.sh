#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/rpi.sh | sudo sh

set -e

# Enable SSH
systemctl enable ssh
systemctl start ssh

# Install Updates
apt-get update
apt-get upgrade -y
apt-get install -y vim wireguard wireguard-tools #resolvconf

# Install LCD
git clone https://github.com/waveshare/LCD-show.git
cd LCD-show/

chmod +x LCD32-show
./LCD32-show
