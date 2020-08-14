#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the script that sets up the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 07/11/20
# Version: v1


# Variables
# Fetch only the active networking device name (EG: enp$, wl$ and etc)
active_device=$(ip -o link show | awk '{print $2,$9}' | grep "UP" | awk '{print $1}' | sed "s/://g")
# Fetch only the active networking tunnel name(s)
active_device_tunnel=$(ip -o link show | awk '{print $2}' | sed "s/://g" | grep "tun")


force_settings(){
	local xenos_device=$1

	ip link set dev "${xenos_device}" allmulticast off
	ip link set dev "${xenos_device}" multicast off
	resolvectl llmnr "${xenos_device}" 0
	resolvectl mdns "${xenos_device}" 0
}


remove_domain(){
	local xenos_device=$1

	resolvectl domain "${xenos_device}" ""
}


force_settings "$active_device"
force_settings "$active_device_tunnel"
remove_domain "$active_device"
remove_domain "$active_device_tunnel"
resolvectl domain "${active_device_tunnel}" "~."

