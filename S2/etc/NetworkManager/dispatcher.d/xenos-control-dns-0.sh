#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the master script which triggers one of two systemd services,
# one which sets up the networking or another which terminates the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 07/30/20
# Version: v1


# Variables
# Check if firewall is active
active_firewall=$(systemctl status iptables | grep "active")


if [[ $1 == tun* ]]; then
  case $2 in
    up)
      systemctl start xenos-control-dns-1.service
    ;;
    down)
      systemctl start xenos-control-dns-2.service
    ;;
  esac
fi


if [[ $1 == wlo* || $1 == enp* ]]; then
  case $2 in
    up)
      if [[ -z "${active_firewall}" ]]; then
        systemctl start xenos-control-dns-2.service
      fi
      ;;
    down)
      systemctl start xenos-control-dns-2.service
      ;;
  esac
fi

