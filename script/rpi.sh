#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/rpi.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Enable SSH
systemctl enable ssh
systemctl start ssh

# Install Keys
mkdir -p ~/.ssh
wget -qO ~/.ssh/authorized_keys https://github.com/turowicz.keys

# Install Updates
apt-get update
apt-get upgrade -y
apt-get install -y vim wireguard wireguard-tools #resolvconf

# Install LCD
git clone https://github.com/waveshare/LCD-show.git
cd LCD-show/

chmod +x LCD32-show
./LCD32-show
