#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the script that terminates the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/04/20
# Version: v2


# Variables
# Fetch only the active networking device name (EG: enp$, wl$ and etc)
active_device=$(ip -o link show | awk '{print $2,$9}' | grep -i "up" | awk '{print $1}' | sed "s/://g")


if [[ -n "${active_device}" ]]; then
  nmcli device disconnect "${active_device}"
fi

pkill openvpn

resolvectl reset-server-features
resolvectl flush-caches

