#!/bin/sh

# Run: curl -s https://raw.githubusercontent.com/Surveily/Images/master/script/cloud-disk-22.04.sh | bash -s -- <disk> <path>

FILE=/surveily-disk

if [ -f $FILE ]; then
   echo "File $FILE exists."
else
   parted /dev/$1 mklabel gpt
   parted -a opt /dev/$1 mkpart primary ext4 0% 100%
   mkfs.ext4 -L datapartition /dev/$1
   mkdir -p $2
   echo "/dev/$1 $2 ext4 defaults 0 2" >> /etc/fstab
   mount -a
   touch $FILE
fi
