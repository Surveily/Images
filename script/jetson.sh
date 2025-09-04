#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/jetson.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Disable swap
systemctl disable nvzramconfig

# Disable serial camera
systemctl disable nvargus-daemon.service

# Switch to console
systemctl set-default multi-user.target

# # Switch to desktop
# systemctl set-default graphical.target