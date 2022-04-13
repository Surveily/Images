#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/user.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Add User
useradd -s /bin/bash -d /home/shared/ -m shared
passwd shared
mkdir /home/shared/.ssh
cp /home/surveily/.ssh/authorized_keys /home/shared/.ssh

# Set Up Kube
mkdir /home/shared/.kube
echo "export KUBECONFIG=.kube/config" >> /home/shared/.profile

# Reset Ownership
chown shared:shared -R /home/shared
