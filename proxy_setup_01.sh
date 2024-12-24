#!/bin/bash

# Proxy VM Setup - Part 1

# Step 1: Ensure systemd-networkd is enabled and running
echo "Ensuring systemd-networkd is enabled and running..."
systemctl enable systemd-networkd
systemctl start systemd-networkd

# Step 2: Bring down the interfaces to reset network configurations
echo "Bringing down the network interfaces..."
nmcli device disconnect enp0s8
ip link set enp0s8 down

# Step 3: Configure Static IP for Internal Network and DHCP for External Network
echo "Configuring static IP for Proxy VM on internal network..."

# Create a netplan configuration for both interfaces
cat <<EOF > /etc/netplan/99_config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:  # Internal interface
      dhcp4: no
      addresses:
        - 10.0.0.2/24
    enp0s3:  # External interface (should use DHCP)
      dhcp4: yes
EOF

# Apply changes
echo "Applying netplan configuration..."
netplan apply

# Step 4: Bring the interfaces back up
echo "Bringing up the network interfaces..."
ip link set enp0s8 up
sleep 10  # Wait for the network to stabilize

# Step 5: Enable IP Forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Step 6: Configure NAT (Masquerading) for Internal Network
echo "Configuring NAT for internal network..."

# Add NAT rule for internal network
EXTERNAL_INTERFACE="enp0s3"  # Ensure the correct external interface is specified
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $EXTERNAL_INTERFACE -j MASQUERADE

# Save iptables rules to persist across reboots
echo "Saving iptables rules..."
apt install -y iptables-persistent netfilter-persistent
netfilter-persistent save
netfilter-persistent reload

# Step 7: Install and Configure dnsmasq
echo "Installing and configuring dnsmasq..."

# Install dnsmasq
apt install -y dnsmasq

# Configure dnsmasq to forward queries to the NAT gateway (e.g., 10.0.2.3)
echo "server=10.0.2.3" >> /etc/dnsmasq.conf
echo "interface=enp0s8" >> /etc/dnsmasq.conf

# Stop and disable systemd-resolved to avoid conflicts with dnsmasq
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm /etc/resolv.conf
echo "nameserver 127.0.0.1" | tee /etc/resolv.conf

# Restart dnsmasq service
systemctl restart dnsmasq

echo "Basic Proxy VM setup complete. You can now run the compromised_setup.sh script before the second part of the script to apply internet access restrictions."
