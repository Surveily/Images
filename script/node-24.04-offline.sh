#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-24.04-offline.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Get
apt update
apt-offline set offline.sig --install-packages apt-offline build-essential software-properties-common \
                                               ethtool iperf iputils-ping inetutils-traceroute net-tools \
                                               lsof iotop lm-sensors nvme-cli smartmontools \
                                               wireguard resolvconf \
                                               nfs-common cifs-utils \
                                               vim rsync htop jq unzip
