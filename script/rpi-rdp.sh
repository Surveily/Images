#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/rpi-rdp.sh | sudo sh

set -e

if [ `whoami` != root ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

apt-get install realvnc-vnc-server realvnc-vnc-viewer
vncpasswd -service
echo 'Authentication=VncAuth' >> /root/.vnc/config.d/vncserver-x11
systemctl restart vncserver-x11-serviced
dpkg -i libfuse2_2.9.9-5_armhf.deb
dpkg -i xrdp_0.9.12-1.1_armhf.deb