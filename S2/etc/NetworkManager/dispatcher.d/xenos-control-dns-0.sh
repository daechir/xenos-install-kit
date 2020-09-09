#!/bin/bash
# This script serves to control DNS while using openvpn.
# This is the master script which triggers one of two systemd services,
# one which sets up the networking or another which terminates the networking.
#
# Author: Daechir
# Author URL: https://github.com/daechir
# Modified Date: 09/08/20
# Version: v2a


# Variables
inactive_firewall=$(systemctl status iptables | grep -i "inactive")
ap_failure_1=$(journalctl | grep -i "failed to initiate ap scan" | grep -i -v "execve")
ap_failure_2=$(journalctl | grep -i "no beacon heard and the time event is over already" | grep -i -v "execve")
ap_failure_3=$(journalctl | grep -i "ctrl-event-beacon-loss" | grep -i -v "execve")


if [[ $1 == wlo* || $1 == enp* || $1 == tun* ]]; then
  case $2 in
    connectivity-change)
      if [[ -n "${inactive_firewall}" || -n "${ap_failure_1}" || -n "${ap_failure_2}" || -n "${ap_failure_3}" ]]; then
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

