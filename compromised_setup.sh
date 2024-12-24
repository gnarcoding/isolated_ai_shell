#!/bin/bash

# Compromised VM Setup

# Step 1: Ensure systemd-networkd is enabled and running
echo "Ensuring systemd-networkd is enabled and running..."
systemctl enable systemd-networkd
systemctl start systemd-networkd

# Step 2: Configure Static IP for Internal Network
echo "Configuring static IP for Compromised VM on internal network..."

# Specify the interface manually if needed (e.g., enp0s3 or enp0s8)
INTERFACE="enp0s3"  # Change this to match the actual internal network interface

echo "Bringing down the network interfaces..."
nmcli device disconnect $INTERFACE
ip link set $INTERFACE down

# Create a netplan configuration for the static IP
cat <<EOF > /etc/netplan/99_config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - 10.0.0.1/24
      routes:
        - to: default
          via: 10.0.0.2
      nameservers:
        addresses: [10.0.0.2]
EOF

# Apply changes
echo "Applying netplan configuration..."
netplan apply
echo "Bringing up the network interfaces..."
ip link set $INTERFACE up
sleep 10  # Wait for the network to stabilize

# Step 3: Update /etc/resolv.conf for DNS resolution
echo "nameserver 10.0.0.2" | tee /etc/resolv.conf

# Step 4: Test DNS Resolution and Connectivity (important before installing packages)
echo "Testing network and DNS resolution..."
ping -c 4 10.0.0.2   # Test DNS resolution (ping Proxy VM)

# Check if DNS is working (google.com or other websites)
ping -c 4 google.com   # This should succeed if DNS is working

# Step 5: Install Python dependencies for OpenAI API (Before internet blocking)
echo "Installing Python dependencies for OpenAI API..."
sudo apt update && sudo apt install -y python3-venv python3-pip 
# install curl for testing
sudo apt install -y curl

# Step 6: Setup non-root user account for accessing the OpenAI API
echo "Setting up non-root user for API access..."
sudo adduser ai_user
su - ai_user -c "echo 'User setup complete'"

# Step 7: Activate virtual environment and install OpenAI package
echo "Setting up Python virtual environment and installing OpenAI package..."
su - ai_user <<'EOF'
python3 -m venv venv
source venv/bin/activate
pip install openai
EOF

# Step 8: Test OpenAI API access
echo "Testing OpenAI API access..."
curl https://api.openai.com

echo "Compromised VM setup complete. You can now run the second part of the Proxy VM setup to apply internet access restrictions."
