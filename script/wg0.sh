#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/wg0.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Setup wg0

chmod 600 /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0.service
systemctl daemon-reload
systemctl start wg-quick@wg0
#systemctl status wg-quick@wg0

# Setup DNS reresolver

wget https://raw.githubusercontent.com/Surveily/Images/master/script/wg0/wireguard_reresolve-dns.service
wget https://raw.githubusercontent.com/Surveily/Images/master/script/wg0/wireguard_reresolve-dns.timer

mv wireguard_reresolve-dns.service /etc/systemd/system/wireguard_reresolve-dns.service
mv wireguard_reresolve-dns.timer /etc/systemd/system/wireguard_reresolve-dns.timer

systemctl enable wireguard_reresolve-dns.timer
systemctl start wireguard_reresolve-dns.timer
