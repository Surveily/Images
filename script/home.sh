#!/bin/bash

# Run: wget https://raw.githubusercontent.com/Surveily/Images/master/script/home.sh && chmod +x home.sh && sudo ./home.sh $USER <nas-username>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

USER=$1
NASUSER=$2
NASPATH=//nas.surveily.com/home

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
declare -a FOLDERS=(".ssh" "Documents") #.gitconfig
OPTIONS="credentials=$FILE,uid=$USERID,gid=$USERID,file_mode=0600,_netdev"

# Test before mounting permanently
for dir in ${FOLDERS[@]}; do
    mount -o $OPTIONS $NASPATH/$dir /home/$USER/$dir
done

# Mount permanently
for dir in ${FOLDERS[@]}; do
    echo "$NASPATH/$dir  /home/$USER/$dir   cifs    $OPTIONS" >> /etc/fstab
done
