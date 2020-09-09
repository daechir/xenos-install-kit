#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the script that sets up the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/09/20
# Version: v2b


# Variables
# Fetch only the active networking device name (EG: enp$, wlo$ and etc)
active_device=$(ip -o link show | awk '{print $2,$9}' | grep -i "up" | awk '{print $1}' | sed "s/://g")
# Fetch only the active networking tunnel name(s)
active_device_tunnel=$(ip -o link show | awk '{print $2}' | sed "s/://g" | grep -i "tun")
# Fetch only the active devices domain
active_domain=$(resolvectl domain "${active_device}" | awk '{print $4}')


force_settings(){
  local xenos_device=$1
  local xenos_connection=$2

  ip link set dev "${xenos_device}" allmulticast off
  ip link set dev "${xenos_device}" multicast off

  if [[ -n "${xenos_connection}" ]]; then
    if [[ "${xenos_device}" == wlo* ]]; then
      nmcli connection mod "${xenos_connection}" 802-11-wireless.powersave 2
    fi

    nmcli connection mod "${xenos_connection}" connection.llmnr 0
    nmcli connection mod "${xenos_connection}" connection.mdns 0
  fi

  resolvectl llmnr "${xenos_device}" 0
  resolvectl mdns "${xenos_device}" 0
}


remove_domain(){
  local xenos_device=$1

  resolvectl domain "${xenos_device}" ""
}


if [[ -n "${active_domain}" ]]; then
  case "${active_device}" in
    wlo*)
      active_connection_name=$(nmcli connection show --active | grep -i "wifi" | awk '{print $1,$2,$3}')
      ;;
    enp*)
      active_connection_name=$(nmcli connection show --active | grep -i "ethernet" | awk '{print $1,$2,$3}')
      ;;
  esac

  force_settings "$active_device" "$active_connection_name"
  force_settings "$active_device_tunnel"
  remove_domain "$active_device"
  remove_domain "$active_device_tunnel"
  resolvectl domain "${active_device_tunnel}" "~."
fi

