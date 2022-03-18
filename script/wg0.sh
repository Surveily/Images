#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/wg0.sh | sudo sh

# Setup wg0

systemctl enable wg-quick@wg0.service
systemctl daemon-reload
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0
