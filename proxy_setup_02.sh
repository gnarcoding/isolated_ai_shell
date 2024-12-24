#!/bin/bash

# Proxy VM Setup - Part 2 (Restrict Access to OpenAI API)

# Step 6: Restrict Compromised VM to OpenAI API Only
echo "Configuring iptables to restrict access to OpenAI API..."

# Resolve OpenAI API IP address
API_IP=$(nslookup api.openai.com | grep 'Address:' | tail -n 1 | awk '{print $2}')

# Allow traffic from Compromised VM (10.0.0.1) to OpenAI API
iptables -A FORWARD -s 10.0.0.1 -d $API_IP -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d $API_IP -p tcp --dport 443 -j ACCEPT

# Allow DNS traffic from the Compromised VM to the Proxy VM
iptables -A FORWARD -s 10.0.0.1 -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Block all other forwarded traffic from Compromised VM
iptables -A FORWARD -s 10.0.0.1 -j DROP

# Save iptables rules
echo "Saving iptables rules for OpenAI API restrictions..."
netfilter-persistent save
netfilter-persistent reload

echo "Proxy VM setup complete. Access to only OpenAI API is now restricted."
