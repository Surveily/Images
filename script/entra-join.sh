#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/join-ad.sh | sudo bash -s -- <ad-username>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

DOMAIN=surveily.com

# Install required packages
apt install -y libpam-aad libnss-aad

# Enable home dir creation
pam-auth-update --enable mkhomedir

# Setup AD
wget https://raw.githubusercontent.com/Surveily/Images/master/script/entra/aad.conf
mv aad.conf /etc/

# Add to sudoers
usermod -aG sudo $1@$DOMAIN