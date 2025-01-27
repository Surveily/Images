#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/entra-join.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Add Tmp Repository
add-apt-repository ppa:ubuntu-enterprise-desktop/authd
apt update

# Install Packages
apt install authd gnome-shell yaru-theme-gnome-shell
snap install authd-msentraid

# Configure Entra ID
mkdir -p /etc/authd/brokers.d/
cp /snap/authd-msentraid/current/conf/authd/msentraid.conf /etc/authd/brokers.d/

# Configure Entra ID Provider
rm /var/snap/authd-msentraid/current/broker.conf
wget -O /var/snap/authd-msentraid/current/broker.conf https://raw.githubusercontent.com/Surveily/Images/master/script/entra/aad.conf

# Restart Services
systemctl restart authd
snap restart authd-msentraid
