#!/bin/bash

# Open required ports
sudo ufw allow 6443/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10251/tcp
sudo ufw allow 10252/tcp
sudo ufw allow 30000:32767/tcp

# Reload UFW
sudo ufw reload

# Enable port forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Save join command to file (for control plane only)
if [ -f "/tmp/join_command.sh" ]; then
    cp /tmp/join_command.sh ./cluster_join_command.txt
    chmod 600 ./cluster_join_command.txt
fi