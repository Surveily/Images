#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/xrdp.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

apt update
apt install -y xrdp ubuntu-desktop-minimal

adduser xrdp ssl-cert

echo "gnome-session" | tee /etc/skel/.xsession

echo "export GNOME_SHELL_SESSION_MODE=ubuntu" | tee -a /etc/skel/.xsessionrc
echo "export XDG_CURRENT_DESKTOP=ubuntu:GNOME" | tee -a /etc/skel/.xsessionrc

# Disable Wallpaper Picture
echo "gsettings set org.gnome.desktop.background picture-uri ''" | tee -a /etc/skel/.profile
echo "gsettings set org.gnome.desktop.background picture-uri-dark ''" | tee -a /etc/skel/.profile

systemctl restart xrdp
systemctl set-default multi-user.target
