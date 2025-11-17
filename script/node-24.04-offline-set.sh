#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/node-24.04-offline-set.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Set
sudo apt-offline install offline-install.zip
