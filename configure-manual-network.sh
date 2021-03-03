#!/bin/bash

# Read the name of device from deviceFile
# This value is provided by the user in the custom network post installation sript
File='/tmp/deviceFile'

    while IFS= read -r line 
    do
    if [[ "$line" == *"Device"* ]]; then
       device=$(echo "$line" | cut -d= -f 2)
    fi
    if [[ "$line" == *"StaticNetwork"* ]]; then
       customNetwork=$(echo "$line" | cut -d= -f 2)

    fi
    
    done < "$File"
echo $device
echo -n "." >> /dev/tty1
if [ $customNetwork = "y" ]; then

    echo "Setting of static IPv4 as defined by the user."
    #Set BOOTPROTO to static in the network device file
    sed -i -e 's#^\(BOOTPROTO=\).*$#\1'"\"static\""'#' /etc/sysconfig/network-scripts/ifcfg-$device
    echo -n "." >> /dev/tty1
    # Append custom netowrk conf into the network device file
    cat /tmp/static-network >> /etc/sysconfig/network-scripts/ifcfg-$device
	systemctl restart network
    echo -n "." >> /dev/tty1
else
    echo "Using Auto DHCP setup"
fi