#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the master script which triggers one of two systemd services,
# one which sets up the networking or another which terminates the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/04/20
# Version: v2


# Variables
# Check if firewall is inactive
inactive_firewall=$(systemctl status iptables | grep -i "inactive")


if [[ $1 == wlo* || $1 == enp* || $1 == tun* ]]; then
  case $2 in
    connectivity-change)
      if [[ -n "${inactive_firewall}" ]]; then
        systemctl start xenos-control-dns-2.service
      fi
      ;;
    down)
      systemctl start xenos-control-dns-2.service
      ;;
  esac
fi


if [[ $1 == tun* ]]; then
  case $2 in
    up)
      systemctl start xenos-control-dns-1.service
      ;;
  esac
fi

