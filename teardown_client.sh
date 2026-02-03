#!/bin/bash

SLEEPT=3

echo "Listing RED client packages: before uninstall `date`"
sudo apt list --installed | egrep 'redsetup|redcli|red-client'

echo "Unmounting REDFS `date`"
sudo umount -f /mnt/redfs
mount | grep redfs
sleep $SLEEPT

echo "Unload redfs `date`"
sudo modprobe -r redfs
sudo lsmod | grep redfs
sleep $SLEEPT

echo "Removing Client Config `date`"
sudo rm -rf /home/nodeadmin/.config/red
sudo rm -rf /root/.config/red

echo "Listing RED client packages: before uninstall `date`"
dpkg -l | egrep -i 'redcli|red-client'

echo "Tearing down the RED Client setup: `date`"
sudo apt-get purge -y red-client-fs-dkms
sudo apt-get purge -y red-client-common red-client-fs red-client-tools redcli
sleep $SLEEPT

echo "Listing RED client packages: after uninstall `date`"
dpkg -l | egrep -i 'redcli|red-client'
