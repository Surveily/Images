#!/bin/bash

# Run: wget https://raw.githubusercontent.com/Surveily/Images/master/script/sync.sh && chmod +x sync.sh && sudo ./sync.sh $USER <nas-username>

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

# Test before mounting
mkdir -p /home/$USER/.surveily/sync

for dir in ${FOLDERS[@]}; do
    mkdir -p /home/$USER/.surveily/sync/$dir
    mount -o $OPTIONS $NASPATH/$dir /home/$USER/.surveily/sync/$dir
done

# Mount permanently
for dir in ${FOLDERS[@]}; do
    echo "$NASPATH/$dir  /home/$USER/.surveily/sync/$dir   cifs    $OPTIONS" >> /etc/fstab
done

# Create services
rm -rf /home/$USER/.surveily/sync/*.sh
wget -O /home/$USER/.surveily/sync/stop.sh https://raw.githubusercontent.com/Surveily/Images/master/script/sync/stop.sh
wget -O /home/$USER/.surveily/sync/start.sh https://raw.githubusercontent.com/Surveily/Images/master/script/sync/start.sh
chmod 700 -R /home/$USER/.surveily
chown $USER:$USER -R /home/$USER/.surveily

for dir in ${FOLDERS[@]}; do
    rm -rf /etc/systemd/system/surveily-sync-$dir.service
    wget -O /etc/systemd/system/surveily-sync-$dir.service https://raw.githubusercontent.com/Surveily/Images/master/script/sync/sync.service
    sed -i -e "s/##user##/$USER/g" /etc/systemd/system/surveily-sync-$dir.service
    sed -i -e "s/##folder##/$dir/g" /etc/systemd/system/surveily-sync-$dir.service
done

systemctl daemon-reload

# Set wait for mounts
mounts=$(systemctl list-units --type=mount | grep .surveily | sed 's/|/ /' | awk '{print $1, $8}'  | { tr -d '\n'; echo; })
for dir in ${FOLDERS[@]}; do
    sed -i -e "s/##mounts##/$mounts/g" /etc/systemd/system/surveily-sync-$dir.service
done

systemctl daemon-reload

# Start services
for dir in ${FOLDERS[@]}; do
    systemctl start surveily-sync-$dir.service    
    systemctl enable surveily-sync-$dir.service
done