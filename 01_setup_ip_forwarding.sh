#!/bin/bash
# ==============================================================================
# Script: 01_setup_ip_forwarding.sh
# Purpose: Enable IPv4 packet forwarding on the attacker host
# Lab: NTI Cybersecurity Training Lab - MITM via ARP Spoofing
# Researcher: Solo Security Researcher
# ==============================================================================
#
# WHY IP FORWARDING IS REQUIRED FOR MITM:
# By default, the Linux kernel acts as an endpoint, not a router. Any packet 
# received by the network interface whose destination IP does not match the 
# host's own IP address is automatically dropped.
#
# During an ARP spoofing attack, both the target client and the gateway are 
# tricked into sending their traffic through the attacker's MAC address. 
# If IP forwarding is DISABLED (0):
#   -> The attacker drops all packets.
#   -> The victim loses internet / gateway connectivity.
#   -> The attack degenerates into a Denial of Service (DoS), exposing the attacker.
#
# If IP forwarding is ENABLED (1):
#   -> The Linux kernel transparently routes packets between victim and gateway.
#   -> The victim maintains uninterrupted connectivity.
#   -> Full transparent interception, packet sniffing, and modification become possible.
# ==============================================================================

set -euo pipefail

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Please execute this script as root (sudo ./01_setup_ip_forwarding.sh)"
  exit 1
fi

echo "[*] Checking current IPv4 forwarding status..."
CURRENT_STATUS=$(cat /proc/sys/net/ipv4/ip_forward)
echo "    Current net.ipv4.ip_forward = $CURRENT_STATUS"

if [ "$CURRENT_STATUS" -eq 1 ]; then
  echo "[+] IPv4 forwarding is already active."
else
  echo "[*] Enabling IPv4 packet forwarding in kernel memory..."
  
  # Method 1: Using procfs directly
  echo 1 > /proc/sys/net/ipv4/ip_forward

  # Method 2: Using sysctl
  sysctl -w net.ipv4.ip_forward=1 > /dev/null

  # Verify activation
  NEW_STATUS=$(cat /proc/sys/net/ipv4/ip_forward)
  if [ "$NEW_STATUS" -eq 1 ]; then
    echo "[+] SUCCESS: IPv4 packet forwarding is now ENABLED ($NEW_STATUS)."
    echo "[+] Traffic routed to this machine will now be forwarded transparently."
  else
    echo "[-] FAILED: Could not enable IPv4 packet forwarding."
    exit 1
  fi
fi
