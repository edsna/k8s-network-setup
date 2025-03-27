#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Checking Kubernetes Services Auto-restart Configuration ==="

# Function to check and enable service
check_service() {
    local service=$1
    echo -e "\nChecking $service:"
    
    # Check if service exists
    if systemctl list-unit-files | grep -q $service; then
        echo "Service exists: ✓"
        
        # Check if service is active
        if systemctl is-active --quiet $service; then
            echo -e "Service is active: ${GREEN}✓${NC}"
        else
            echo -e "Service is not active: ${RED}×${NC}"
            echo "Starting service..."
            sudo systemctl start $service
        fi
        
        # Check if service is enabled
        if systemctl is-enabled --quiet $service; then
            echo -e "Service is enabled at boot: ${GREEN}✓${NC}"
        else
            echo -e "Service is not enabled at boot: ${RED}×${NC}"
            echo "Enabling service..."
            sudo systemctl enable $service
        fi
        
        # Show service status
        echo "Current status:"
        systemctl status $service | grep "Active:"
    else
        echo -e "Service not found: ${RED}×${NC}"
    fi
}

# Check critical services
services=("kubelet" "containerd" "docker.socket" "docker" "etcd" "k8s-init")
for service in "${services[@]}"; do
    check_service $service
done

# Check system settings
echo -e "\n=== Checking System Settings ==="

# Check if swap is disabled
if [[ $(swapon --show) ]]; then
    echo -e "Swap is enabled: ${RED}×${NC}"
    echo "Consider disabling swap permanently in /etc/fstab"
else
    echo -e "Swap is disabled: ${GREEN}✓${NC}"
fi

# Check kubelet configuration
echo -e "\n=== Checking Kubelet Configuration ==="
if [ -f "/var/lib/kubelet/config.yaml" ]; then
    echo -e "Kubelet config exists: ${GREEN}✓${NC}"
else
    echo -e "Kubelet config not found: ${RED}×${NC}"
fi

# Check systemd configurations
echo -e "\n=== Checking Systemd Configurations ==="
if [ -d "/etc/systemd/system/kubelet.service.d" ]; then
    echo -e "Kubelet systemd config exists: ${GREEN}✓${NC}"
else
    echo -e "Kubelet systemd config not found: ${RED}×${NC}"
fi

echo -e "\n=== Recommendations ==="
echo "1. Ensure all services show as active and enabled"
echo "2. Keep swap disabled"
echo "3. Verify network connectivity between nodes after restart"
echo "4. Consider setting up monitoring for service status"