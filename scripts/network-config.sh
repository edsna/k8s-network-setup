#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get MAC address and network info
get_network_info() {
    print_status $YELLOW "Getting Network Information..."
    echo "===================="
    
    # Get primary network interface
    PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    print_status $GREEN "Primary Interface: $PRIMARY_INTERFACE"
    
    # Get MAC address
    MAC_ADDRESS=$(ip link show $PRIMARY_INTERFACE | grep ether | awk '{print $2}')
    print_status $GREEN "MAC Address: $MAC_ADDRESS"
    
    # Get current IP address
    IP_ADDRESS=$(ip addr show $PRIMARY_INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    print_status $GREEN "Current IP Address: $IP_ADDRESS"
    
    # DNS servers
    print_status $YELLOW "DNS Servers:"
    cat /etc/resolv.conf | grep nameserver
    
    # Save to file for reference
    echo "Network Configuration $(date)" > network_config.txt
    echo "Interface: $PRIMARY_INTERFACE" >> network_config.txt
    echo "MAC Address: $MAC_ADDRESS" >> network_config.txt
    echo "IP Address: $IP_ADDRESS" >> network_config.txt
}

# Function to verify k8s required ports
check_k8s_ports() {
    print_status $YELLOW "Checking Required K8s Ports..."
    echo "===================="
    
    # Required K8s ports
    PORTS=(
        "6443"  # Kubernetes API server
        "2379"  # etcd server client API
        "2380"  # etcd server client API
        "10250" # Kubelet API
        "10251" # kube-scheduler
        "10252" # kube-controller-manager
        "30000-32767" # NodePort Services
    )
    
    for PORT in "${PORTS[@]}"; do
        if [[ $PORT == *-* ]]; then
            # Port range
            START_PORT=$(echo $PORT | cut -d'-' -f1)
            END_PORT=$(echo $PORT | cut -d'-' -f2)
            print_status $GREEN "Checking port range $START_PORT-$END_PORT"
            # Add your port range check logic here
        else
            # Single port
            nc -zv localhost $PORT &>/dev/null
            if [ $? -eq 0 ]; then
                print_status $GREEN "Port $PORT is open"
            else
                print_status $RED "Port $PORT is closed"
            fi
        fi
    done
}

# Function to test network connectivity
test_connectivity() {
    print_status $YELLOW "Testing Network Connectivity..."
    echo "===================="
    
    # Test internet connectivity
    if ping -c 3 8.8.8.8 &>/dev/null; then
        print_status $GREEN "Internet connectivity: OK"
    else
        print_status $RED "Internet connectivity: FAILED"
    fi
    
    # Test DNS resolution
    if nslookup kubernetes.io &>/dev/null; then
        print_status $GREEN "DNS resolution: OK"
    else
        print_status $RED "DNS resolution: FAILED"
    fi
}

# Main execution
main() {
    print_status $YELLOW "Starting Network Configuration Check"
    echo "===================="
    
    # Create network configuration directory
    mkdir -p ~/k8s-network-config
    cd ~/k8s-network-config
    
    # Run all checks
    get_network_info
    check_k8s_ports
    test_connectivity
    
    print_status $GREEN "Configuration check complete. Results saved in network_config.txt"
}

# Run main function
main
