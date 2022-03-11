#!/bin/sh

# Run: curl https://raw.githubusercontent.com/Surveily/Images/master/script/rpi.sh | sudo sh

set -e

git clone https://github.com/waveshare/LCD-show.git
cd LCD-show/

chmod +x LCD4-show
 ./LCD4-show 
