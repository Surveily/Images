#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/lxd.sh | sudo bash -s -- <interface>

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo $1
iptables -I DOCKER-USER -i lxdbr0 -j ACCEPT
iptables -I DOCKER-USER -o lxdbr0 -j ACCEPT
iptables -I DOCKER-USER -i lxdbr0 -o $1 -j ACCEPT
