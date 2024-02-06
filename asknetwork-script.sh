
%post --nochroot --erroronfail --log=/tmp/network-setup.log

scrFile="/tmp/static-network"

curTTY=`tty`
exec < $curTTY > $curTTY 2> $curTTY

clear

ip_validation () {

  ip_check="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"  # Regex Pattern for IPV4
 
  local temp=$1 # Assigning arguement value to $temp
 
  while ! [[ $temp =~ $ip_check ]]; do  # Validating the user input with IPV4 pattern
    read -p "$(tput setaf 1)Please enter a Valid Format ( e.g : $2 ): $(tput sgr 0)" temp
  done
   
  echo $temp 
  
} 


echo -e "\n----------------------------------------------------------------------"
ip link show
echo -e "\n----------------------------------------------------------------------"

# List available network interfaces
for i in `find /sys/class/net/ -type l` ;
  do 
    name=$(echo  ${i} | awk -F/ '{print $NF}'  )
    if [ $name != "lo" ];then
      state=$(cat $i/operstate)
      echo -e "${counter}\t\t\t"${name}"\t\t"${state}
    fi
done
clear
#Ask if the user wants to do manual or auto network config
echo -e "\n\n-------------------Network Configuration--------------------------\n\n"

ManualNetworkConfiguration=""

read -e -p "For Manual network configuration enter 'y', if you want to setup the network using auto DHCP, enter 'n':" ManualNetworkConfiguration

while ! [[ $ManualNetworkConfiguration =~ ^[yYnN]+$ ]]; do  # Validating user input for Yy/Nn
  
  read -p "$(tput setaf 1)Please enter a Valid Input ( e.g : y/n )$(tput sgr 0)" ManualNetworkConfiguration

done

if [ $ManualNetworkConfiguration = "y" ]; then



# List attached network interfaces

echo -e "\n\n$(tput setaf 1)****************************************************************************************"
echo -e "***WARNING: Interface name MUST belong to the list of the interfaces we have presented above. In case the interface name doesn’t belong to the list installation will Fail"
echo "****************************************************************************************$(tput sgr 0)" 
echo -e "\t\t     Detected network interfaces\n"
echo -e "\t\t#\tDEVICE\t\tSTATUS"
echo -e "\t\t-\t------\t\t------"
declare -A choice
counter=0
for i in `find /sys/class/net/ -type l` ;
  do 
    name=$(echo  ${i} | awk -F/ '{print $NF}'  )
    if [ $name != "lo" ];then
      state=$(cat $i/operstate)
      ((counter++))
      choice[$counter]=${name}
      echo -e "\t\t${counter}\t"${name}"\t\t"${state}
      
    fi
done
DeviceName="a"
echo -e "\n"
	
    while [ "$answer" != "y" ] && [ "$answer" != "Y" ] ; do

        while :; do
          read -p "Please enter network device number from the above shown list : " DeviceName 
          [[ $DeviceName =~ ^[0-9]+$ ]] || { echo "$(tput setaf 1)Enter a valid number$(tput sgr 0)"; continue; }
          if ((DeviceName >= 0 && DeviceName <= counter)); then
          DeviceName=${choice[$DeviceName]}
          break
          else
              echo "$(tput setaf 1)Number out of range, try again$(tput sgr 0)"
          fi
	      done
      
        read -p "Please enter IPv4 Address ( e.g : 192.168.33.33 ): " Ip
        Ip=$( ip_validation "$Ip" "192.168.33.33" )
        
        read -e -p "Please enter Gateway: ( e.g : 192.168.1.1 ) " Gateway
        Gateway=$( ip_validation "$Gateway" "192.168.1.1" )

        read -e -p "Please enter Netmask: ( e.g : 255.255.255.0 ) " netmask
        netmask=$( ip_validation "$netmask" "255.255.255.0" )

        read -p "Please enter DNS 1 ( e.g : 8.8.8.8 )  " dns1
        dns1=$( ip_validation "$dns1" "8.8.8.8" )

        read -p "Please enter DNS 2 ( e.g : 8.8.8.4 ) " dns2
        dns2=$( ip_validation "$dns2" "8.8.8.4" )
       

        echo
            echo You entered:
            echo -e "\tDevice Name: $DeviceName"
            echo -e "\tIPv4: $Ip"
            echo -e "\tNetmask: $netmask"
            echo -e "\tdefault Gateway: $Gateway"
            echo -e "\tdefault DNS1: $dns1"
            echo -e "\tdefault DNS2: $dns2"
            echo -n "Is this correct? [y/n] "; read answer
            #Check if the IP is available
      ping -c 3 $Ip &> /dev/null
      rc=$?
      echo "Ping result for entered IP: "$rc >> /tmp/network-setup.log
      if [[ $rc -eq 0 ]]; then
        echo "IP address: $Ip is Not available"
        answer=n
      else
            echo "IP address: $Ip is available"
      fi
    done
    echo StaticNetwork=$ManualNetworkConfiguration > /tmp/deviceFile
    echo Device=$DeviceName >> /tmp/deviceFile
    echo IPADDR=\"$Ip\" > $scrFile
    echo NETMASK=\"$netmask\" >> $scrFile
    echo GATEWAY=\"$Gateway\" >> $scrFile
    echo DNS1=\"$dns1\" >> $scrFile
    echo DNS2=\"$dns2\" >> $scrFile
    echo DEFROUTE=\"yes\" >> $scrFile
else
 	echo "Network will be setup using auto DHCP"
	echo StaticNetwork=$ManualNetworkConfiguration > /tmp/deviceFile
fi
echo -e "\n\n\t$(tput setaf 1)***** WARNING: Please remove/eject the Installation media. This is to ensure that it doesn't start the installation again. *****$(tput sgr 0)"
sleep 10
%end

%post --log=/mnt/sysimage/root/kickstart_post_3.log --nochroot

echo "Copying custom network configuration file"
/bin/cp /tmp/static-network /mnt/sysimage/tmp/static-network
/bin/cp /tmp/deviceFile /mnt/sysimage/tmp/deviceFile
/bin/cp /tmp/network-setup.log /mnt/sysimage/root/network-setup.log

%end
