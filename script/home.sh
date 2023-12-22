#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/home.sh | sudo bash -s -- $USER <nas-username> <nas-path>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

USER=$1
NASUSER=$2
NASPATH=$3

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

# Test before mounting permanently
mount -o $OPTIONS $NASPATH/.ssh /home/$USER/.ssh
mount -o $OPTIONS $NASPATH/.kube /home/$USER/.kube
#mount -o $OPTIONS $NASPATH/.gitconfig /home/$USER/.gitconfig

# Mount permanently
echo "$NASPATH/.ssh  /home/$USER/.ssh   cifs    $OPTIONS" >> /etc/fstab
echo "$NASPATH/.kube  /home/$USER/.kube   cifs    $OPTIONS" >> /etc/fstab
#echo "$NASPATH/.gitconfig  /home/$USER/.gitconfig   cifs    $OPTIONS" >> /etc/fstab