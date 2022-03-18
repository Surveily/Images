#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/nfs.sh | sudo sh

set -e

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Install NFS Server
apt-get update
apt-get install -y nfs-kernel-server nfs-common

# Configure NFS Server
mkdir /var/nfs/general -p
chown nobody:nogroup /var/nfs/general
echo "/var/nfs/general    127.0.0.1(rw,sync,no_subtree_check)" | tee -a /etc/exports

# Restart NFS Server
systemctl restart nfs-kernel-server
