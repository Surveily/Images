#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/join-ad.sh | sudo sh -s -- <ad-username>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

DOMAIN=ad.surveily.com
UPPER=${DOMAIN^^}

# Install required packages
apt install -y sssd-ad sssd-tools realmd adcli

# Check domain existing
realm -v discover $DOMAIN
clear

# Join the domain
realm -v join $DOMAIN -U $1@$UPPER

# Enable home dir creation
pam-auth-update --enable mkhomedir

# Enable kerberos client
apt install -y krb5-user