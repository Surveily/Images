#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/join-ad.sh | sudo sh -s -- <ad-username>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

DOMAIN=ad.surveily.com

# Remove from sudoers
gpasswd -d $1@$DOMAIN sudo

# Leave existing domain
realm -v leave $DOMAIN

# Remove home directory
rm -rf /home/$1@$DOMAIN

# Remove required packages
apt purge -y sssd-ad sssd-tools realmd adcli krb5-user
apt autoremove -y