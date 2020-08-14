#!/bin/bash
# Print commands before executing and exit when any command fails
set -xe


configure_firewall() {
	# Configure the firewall
	iptables -N TCP
	iptables -N UDP
	iptables -P FORWARD DROP
	iptables -P OUTPUT ACCEPT
	iptables -P INPUT DROP
	iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
	iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
	iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
	iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
	iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
	iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
	iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable

	# Save our firewall rules
	iptables-save > /etc/iptables/iptables.rules

	# Enable and start the firewall
	systemctl enable iptables.service
	systemctl start iptables.service

	# Harden file permissions
	chmod -R 700 /etc/iptables/
}


configure_firewall

