#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/ofv.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

apt install openfortivpn

wget https://raw.githubusercontent.com/Surveily/Images/master/script/ofv/openfortivpn@.service
mv openfortivpn@.service /usr/lib/systemd/system/
systemctl daemon-reload
chmod 600 /etc/openfortivpn/*.conf

echo 'sudo systemctl enable openfortivpn@example'
echo 'sudo systemctl start openfortivpn@example'