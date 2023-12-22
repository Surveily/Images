#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/home.sh | sudo bash -s -- $USER <nas-username>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

USER=$1
NASUSER=$2
NASPATH=//192.168.100.100/home

echo "Mapping $NASPATH for user $NASUSER in directory /home/$USER"
read -sp "NAS Password: " NASPASS

# Install packages
apt install cifs-utils psmisc

# Delete existing credentials
USERID=$(id -u $USER)
FILE=/home/$USER/.nas-credentials

if test -f "$FILE"; then
    rm $FILE
fi

# Set credentials
echo "username=$NASUSER" >> $FILE
echo "password=$NASPASS" >> $FILE

chown $USER:$USER /home/$USER/.nas-credentials
chmod 600 /home/$USER/.nas-credentials

# Mount shares
OPTIONS="credentials=$FILE,uid=$USERID,gid=$USERID,file_mode=0600,_netdev"

# Prepare Home
mkdir -p /home/$USER/.tmp-home
mount -o $OPTIONS $NASPATH /home/$USER/.tmp-home

if ! [ -d "/home/$USER/.tmp-home/.ssh" ]; then
    mkdir -p /home/$USER/.tmp-home/.ssh
fi
if ! [ -d "/home/$USER/.tmp-home/.kube" ]; then
    mkdir -p /home/$USER/.tmp-home/.kube
fi
if ! [ -d "/home/$USER/.tmp-home/Documents" ]; then
    mkdir -p /home/$USER/.tmp-home/Documents
fi

umount /home/$USER/.tmp-home
rm -rf /home/$USER/.tmp-home

# Test before mounting permanently
mount -o $OPTIONS $NASPATH/.ssh /home/$USER/.ssh
mount -o $OPTIONS $NASPATH/.kube /home/$USER/.kube
mount -o $OPTIONS $NASPATH/Documents /home/$USER/Documents
#mount -o $OPTIONS $NASPATH/.gitconfig /home/$USER/.gitconfig

# Mount permanently
echo "$NASPATH/.ssh  /home/$USER/.ssh   cifs    $OPTIONS" >> /etc/fstab
echo "$NASPATH/.kube  /home/$USER/.kube   cifs    $OPTIONS" >> /etc/fstab
echo "$NASPATH/Documents  /home/$USER/Documents   cifs    $OPTIONS" >> /etc/fstab
#echo "$NASPATH/.gitconfig  /home/$USER/.gitconfig   cifs    $OPTIONS" >> /etc/fstab