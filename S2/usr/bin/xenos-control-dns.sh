#!/bin/bash
# This script serves to control DNS while using openvpn.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 10/23/20
# Version: v1c


## Functions
# Functions are listed by call order
initial_vars(){
  activated_time=$(date +"%I:%M")
  adjusted_time=$(date --date="-59 minutes ago" +"%I:%M")
  echo "Notice: The current lease of the openvpn connection begins at ${activated_time} and expires at ${adjusted_time}."

  active_device_domain="init"

  connection_state="reset"

  return 0
}

continuous_vars(){
  security_failure=$(journalctl | grep -i "failed ap scan\|beacon\|heard\|loss\|degraded feature set" | grep -i -v "execve")
  inactive_firewall=$(systemctl status iptables | grep -i "inactive")

  active_device=$(ip -o link show | awk '{print $2,$9}' | grep -i "up" | awk '{print $1}' | sed "s/://g")
  active_tunnel=$(ip -o link show | awk '{print $2}' | sed "s/://g" | grep -i "tun")

  # active_device_connection only needs to be set once per session
  if [[ -n "${active_device}" && -z "${active_device_connection}" ]]; then
    case "${active_device}" in
      wlo*)
        active_device_connection=$(nmcli connection show --active | grep -i "wifi" | awk '{print $1,$2,$3}')
        ;;
      enp*)
        active_device_connection=$(nmcli connection show --active | grep -i "ethernet" | awk '{print $1,$2,$3}')
        ;;
    esac
  fi

  # active_device_domain needs to be set twice per session to ensure firstly that connectivity_state() -> setup_connectivity() fires correctly and
  # that secondly its value is set empty so that connectivity_state() -> kill_connectivity() fires correctly
  if [[ -n "${active_device}" && "${active_device_domain}" == "init" || -n "${active_device}" && "${active_device_domain}" == "~." ]]; then
    active_device_domain=$(resolvectl domain "${active_device}" | awk '{print $4}')
  fi

  current_time=$(date +"%I:%M")

  return 0
}

connectivity_state(){
  ## Prepare connection_message and connection_state
  # If the current session, regardless of the current networking state, fails any or all of the security cases then set connection_state=0
  if [[ -n "${security_failure}" || -n "${inactive_firewall}" ]]; then
    connection_message="A security case has failed."
    connection_state=0
    return 0
  fi

  # If the ethernet or wifi is inactive but the tun is active (i.e. device connection closed itself or was killed) then set connection_state=1
  if [[ -z "${active_device}" && -n "${active_tunnel}" ]]; then
    connection_message="The device connection closed itself or was killed."
    connection_state=1
    return 0
  fi

  # If the ethernet or wifi is active, its domain is empty and the tun is inactive (i.e. tunnel closed itself or was killed) then set connection_state=1
  if [[ -n "${active_device}" && -z "${active_device_domain}" && -z "${active_tunnel}" ]]; then
    connection_message="The tunnel closed itself or was killed."
    connection_state=1
    return 0
  fi

  # If the current lease of the openvpn connection is about to expire then set connection_state=1
  if [[ "${adjusted_time}" == "${current_time}" ]]; then
    connection_message="The current lease of the openvpn connection is about to expire."
    connection_state=1
    return 0
  fi

  # If the ethernet or wifi is active, its domain isn't empty and the tun is active then set connection_state=2
  if [[ -n "${active_device}" && -n "${active_device_domain}" && -n "${active_tunnel}" ]]; then
    connection_message="The current networking state has been setup successfully."
    connection_state=2
    return 0
  fi

  return 0
}

kill_connectivity(){
  local xenos_device=$1

  if [[ -n "${xenos_device}" ]]; then
    nmcli device disconnect "${xenos_device}" &> /dev/null
  fi

  pkill -SIGTERM -f "openvpn"

  resolvectl reset-server-features
  resolvectl flush-caches

  return 0
}

setup_connectivity(){
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

  resolvectl domain "${xenos_device}" ""

  return 0
}


## Initialize script
initial_vars

while :
do
  continuous_vars
  connectivity_state

  if [[ "${connection_state}" != "reset" ]]; then
    case $connection_state in
      0 | 1)
        echo "Warning: ${connection_message} Now terminating the current networking state."
        kill_connectivity "${active_device}"
        break
        ;;
      2)
        echo "Success: ${connection_message}"
        setup_connectivity "${active_device}" "${active_device_connection}"
        setup_connectivity "${active_tunnel}"
        resolvectl domain "${active_tunnel}" "~."
        connection_state="reset"
        ;;
    esac
  fi

  sleep 3
done

exit 0

