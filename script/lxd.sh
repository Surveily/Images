#!/bin/bash

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/lxd.sh | sudo bash

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

iptables -I DOCKER-USER -i lxdbr0 -j ACCEPT
iptables -I DOCKER-USER -o lxdbr0 -j ACCEPT
iptables -I DOCKER-USER -i lxdbr0 -o wlp3s0 -j ACCEPT
