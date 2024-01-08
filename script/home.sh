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
declare -a FOLDERS=(".ssh" ".kube" "Documents") #.gitconfig
OPTIONS="credentials=$FILE,uid=$USERID,gid=$USERID,file_mode=0600,_netdev"

# Prepare Home
mkdir -p /home/$USER/.tmp-home
mount -o $OPTIONS $NASPATH /home/$USER/.tmp-home

for dir in ${FOLDERS[@]}; do
    if ! [ -d "/home/$USER/.tmp-home/$dir" ]; then
        mkdir -p /home/$USER/.tmp-home/$dir
    fi
done

umount /home/$USER/.tmp-home
rm -rf /home/$USER/.tmp-home

# Test before mounting permanently
for dir in ${FOLDERS[@]}; do
    mount -o $OPTIONS $NASPATH/$dir /home/$USER/$dir
done

# Mount permanently
for dir in ${FOLDERS[@]}; do
    echo "$NASPATH/$dir  /home/$USER/$dir   cifs    $OPTIONS" >> /etc/fstab
done