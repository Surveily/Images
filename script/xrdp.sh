#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/xrdp.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

apt update
apt install -y xrdp ubuntu-desktop

adduser xrdp ssl-cert

echo "gnome-session" | tee ~/.xsession
echo "export GNOME_SHELL_SESSION_MODE=ubuntu" | tee -a ~/.xsessionrc

systemctl restart xrdp