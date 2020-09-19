#!/bin/bash
# This script serves to control DNS while using openvpn.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/19/20
# Version: v1a


## Variables (1/2)
# Handlers
activated_time=$(date +"%I:%M")
adjusted_time=$(date --date="-59 minutes ago" +"%I:%M")


echo "Notice: The current lease of the openvpn connection begins at ${activated_time} and expires at ${adjusted_time}."


while :
do
  ## Variables (2/2)
  # Hamdlers
  active_device=$(ip -o link show | awk '{print $2,$9}' | grep -i "up" | awk '{print $1}' | sed "s/://g")

  if [[ -n "${active_device}" ]]; then
    active_device_domain=$(resolvectl domain "${active_device}" | awk '{print $4}')

    case "${active_device}" in
      wlo*)
        active_device_connection=$(nmcli connection show --active | grep -i "wifi" | awk '{print $1,$2,$3}')
        ;;
      enp*)
        active_device_connection=$(nmcli connection show --active | grep -i "ethernet" | awk '{print $1,$2,$3}')
        ;;
    esac
  fi

  active_tunnel=$(ip -o link show | awk '{print $2}' | sed "s/://g" | grep -i "tun")
  connection_state="reset"
  current_time=$(date +"%I:%M")
  # Security cases
  inactive_firewall=$(systemctl status iptables | grep -i "inactive")
  ap_failure_1=$(journalctl | grep -i "failed to initiate ap scan" | grep -i -v "execve")
  ap_failure_2=$(journalctl | grep -i "no beacon heard and the time event is over already" | grep -i -v "execve")
  ap_failure_3=$(journalctl | grep -i "ctrl-event-beacon-loss" | grep -i -v "execve")

  ## Functions
  kill_connectivity(){
    local xenos_device=$1

    if [[ -n "${xenos_device}" ]]; then
      nmcli device disconnect "${xenos_device}" &> /dev/null
    fi

    pkill -SIGTERM -f "openvpn"

    resolvectl reset-server-features
    resolvectl flush-caches
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
  }

  ## Prepare connection_message and connection_state
  # If the current session, regardless of the current networking state, fails any or all of the security cases then set connection_state=0
  if [[ -n "${inactive_firewall}" || -n "${ap_failure_1}" || -n "${ap_failure_2}" || -n "${ap_failure_3}" ]]; then
    connection_message="A security case has failed."
    connection_state=0
  fi

  # If the ethernet or wifi is inactive but the tun is active (i.e. device connection closed itself or was killed) then set connection_state=1
  if [[ -z "${active_device}" && -n "${active_tunnel}" ]]; then
    connection_message="The device connection closed itself or was killed."
    connection_state=1
  fi

  # If the ethernet or wifi is active, its domain is empty and the tun is inactive (i.e. tunnel closed itself or was killed) then set connection_state=1
  if [[ -n "${active_device}" && -z "${active_device_domain}" && -z "${active_tunnel}" ]]; then
    connection_message="The tunnel closed itself or was killed."
    connection_state=1
  fi

  # If the current lease of the openvpn connection is about to expire then set connection_state=1
  if [[ "${current_time}" == "${adjusted_time}" ]]; then
    connection_message="The current lease of the openvpn connection is about to expire."
    connection_state=1
  fi

  # If the ethernet or wifi is active, its domain isn't empty and the tun is active then set connection_state=2
  if [[ -n "${active_device}" && -n "${active_device_domain}" && -n "${active_tunnel}" ]]; then
    connection_message="The current networking state has been setup successfully."
    connection_state=2
  fi

  # If the ethernet or wifi is inactive, its domain is empty and the tun is inactive then set connection_state=3
  if [[ -z "${active_device}" && -z "${active_device_domain}" && -z "${active_tunnel}" ]]; then
    connection_message="The current networking state is now resetting."
    connection_state=3
  fi

  ## Now handle connection states
  case $connection_state in
    0 | 1)
      echo "Warning: ${connection_message} Now terminating the current networking state."
      kill_connectivity "${active_device}"
      ;;
    2)
      echo "Success: ${connection_message}"
      setup_connectivity "${active_device}" "${active_device_connection}"
      setup_connectivity "${active_tunnel}"
      resolvectl domain "${active_tunnel}" "~."
      ;;
    3)
      echo "Reset: ${connection_message}"
      break
      ;;
  esac

  # Pause for a second before restarting
  sleep 1
done

