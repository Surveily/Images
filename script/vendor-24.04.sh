#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/vendor-24.04.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Upgrade dependencies
apt-get update && apt-get upgrade -y
