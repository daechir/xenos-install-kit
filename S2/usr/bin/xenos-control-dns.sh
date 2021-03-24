#!/bin/bash


#################################################
#
#           _______  _        _______  _______
# |\     /|(  ____ \( (    /|(  ___  )(  ____ \
# ( \   / )| (    \/|  \  ( || (   ) || (    \/
#  \ (_) / | (__    |   \ | || |   | || (_____
#   ) _ (  |  __)   | (\ \) || |   | |(_____  )
#  / ( ) \ | (      | | \   || |   | |      ) |
# ( /   \ )| (____/\| )  \  || (___) |/\____) |
# |/     \|(_______/|/    )_)(_______)\_______)
#
#
# This file is a part of the Xenos Install Kit.
# It adheres to the GNU GPL license.
#
# https://github.com/daechir/xenos-install-kit
#
# © 2020-2021
#
#
#################################################


initialize(){
  #
  ## Device variable prep
  #
  # active_device_string: a string of device data used for manipulation
  #                       by default greps all connected devices then filters out special cases
  #                       eg "disconnected" often refers to wireless p2p devices
  #                          "connected (externally)" often refers to tap/tun devices
  # active_device_name: eg en* (ethernet) or wl* (wifi)
  # active_device_connection_name: eg the name of the connection ("Wired connection 1" "Wifi actually sucks")
  # active_device_domain: either init, ~. or empty
  #
  active_device_string=$(nmcli device | grep -i "connected" | grep -v -i "disconnected\|connected (externally)")
  active_device_name=$(echo "${active_device_string}" | awk '{print $1}' | sed "s/^[ \t]*//;s/[ \t]*$//" | sed "/^$/d")
  active_device_connection_name=$(echo "${active_device_string}" | awk '{$1=$2=$3=""; print $0}' | sed "s/^[ \t]*//;s/[ \t]*$//" | sed "/^$/d")
  active_device_domain="init"

  #
  # Setup the active_device_name domain
  #
  resolvectl domain "${active_device_name}" "~."

  #
  ## Time variable prep
  #
  # activated_time: self explainatory
  # adjusted_time: the activated_time +59 minutes forward (1 minute before Openvpn attempts to renew its lease automatically)
  #
  activated_time=$(date +"%I:%M")
  adjusted_time=$(date --date="-59 minutes ago" +"%I:%M")

  echo "Notice: The current lease of the openvpn connection begins at ${activated_time} and expires at ${adjusted_time}."

  #
  ## Loop variable prep
  #
  # connection_state: either init, 0, 1 or 2
  #                   init is a control state
  #                   0,1 are termination states
  #                   2 is a successful state
  #
  connection_state="init"

  return 0
}

update_vars(){
  #
  ## Connection_state=0 variables
  #
  # security_failure: various bugs that can result in data compromises
  # inactive_firewall: self explainatory
  #
  security_failure=$(journalctl | grep -i "failed ap scan\|beacon\|heard\|loss\|degraded feature set" | grep -i -v "execve\|scorecardresearch_beacon.js")
  inactive_firewall=$(systemctl status iptables | grep -i "inactive")

  #
  ## Connection_state=1 variables
  #
  # active_device_connection_state: either disconnected or connected
  # active_device_domain: either init, ~. or empty
  # active_tunnel_name: eg tun*
  # current_time: self explainatory
  #
  active_device_connection_state=$(nmcli device | grep -i "${active_device_name}" | grep -v -i "p2p" | awk '{print $3}' | sed "s/^[ \t]*//;s/[ \t]*$//" | sed "/^$/d")

  if [[ "${active_device_domain}" == "init" || "${active_device_domain}" == "~." ]]; then
    active_device_domain=$(resolvectl domain "${active_device_name}" | awk '{print $4}')
  fi

  active_tunnel_name=$(nmcli device | grep -i "tun" | awk '{print $1}' | sed "s/^[ \t]*//;s/[ \t]*$//" | sed "/^$/d")

  current_time=$(date +"%I:%M")

  return 0
}

check_connectivity_state(){
  # If the current session fails any of the security cases or the firewall is inactive then set connection_state=0
  if [[ -n "${security_failure}" || -n "${inactive_firewall}" ]]; then
    connection_message="A security case has failed."
    connection_state=0
    return 0
  fi

  # If the ethernet or wifi connection is inactive but the tun is active (i.e. device connection closed itself or was killed) then set connection_state=1
  if [[ "${active_device_connection_state}" == "disconnected" && -n "${active_tunnel_name}" ]]; then
    connection_message="The device connection closed itself or was killed."
    connection_state=1
    return 0
  fi

  # If the ethernet or wifi connection is active, its domain is empty and the tun is inactive (i.e. tunnel closed itself or was killed) then set connection_state=1
  if [[ "${active_device_connection_state}" == "connected"  && -z "${active_device_domain}" && -z "${active_tunnel_name}" ]]; then
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

  # If the ethernet or wifi connection is active, its domain isn't empty and the tun is active then set connection_state=2
  if [[ "${active_device_connection_state}" == "connected"  && -n "${active_device_domain}" && -n "${active_tunnel_name}" ]]; then
    connection_message="The current networking state has been setup successfully."
    connection_state=2
    return 0
  fi

  return 0
}

terminate_connectivity(){
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
    if [[ "${xenos_device}" == wl* ]]; then
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
initialize

while :
do
  update_vars
  check_connectivity_state

  if [[ "${connection_state}" != "init" ]]; then
    case $connection_state in
      0 | 1)
        echo "Warning: ${connection_message} Now terminating the current networking state."
        terminate_connectivity "${active_device_name}"
        break
        ;;
      2)
        echo "Success: ${connection_message}"
        setup_connectivity "${active_device_name}" "${active_device_connection_name}"
        setup_connectivity "${active_tunnel_name}"
        resolvectl domain "${active_tunnel_name}" "~."
        connection_state="init"
        ;;
    esac
  fi

  sleep 3
done

exit 0

