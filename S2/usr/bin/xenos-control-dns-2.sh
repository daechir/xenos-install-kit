#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the script that terminates the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 07/30/20
# Version: v1


# Variables
# Fetch only the active networking device name (EG: enp$, wl$ and etc)
active_device=$(ip -o link show | awk '{print $2,$9}' | grep "UP" | awk '{print $1}' | sed "s/://g")


pkill openvpn

if [[ -n "${active_device}" ]]; then
  nmcli device disconnect "${active_device}"
fi

resolvectl reset-server-features
resolvectl flush-caches

