#!/bin/bash

set -euo pipefail

# Source the network check script
source network_check.sh

# Variables
CONTROL_PLANE_IP="192.168.197.150"
WORKER_NODE_IP="192.168.197.177"
IS_CONTROL_PLANE=true

setup_prerequisites() {
    # Disable swap
    swapoff -a
    sed -i '/swap/d' /etc/fstab
    
    # Load kernel modules
    cat << EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    
    modprobe overlay
    modprobe br_netfilter
    
    # Set kernel parameters
    cat << EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    sysctl --system
    
    # Open required ports using ufw
    ufw allow 6443/tcp  # Kubernetes API server
    ufw allow 2379:2380/tcp  # etcd server client API
    ufw allow 10250/tcp  # Kubelet API
    ufw allow 10251/tcp  # kube-scheduler
    ufw allow 10252/tcp  # kube-controller-manager
    ufw allow 30000:32767/tcp  # NodePort Services range
}

install_terraform() {
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update && apt-get install -y terraform
}

create_terraform_workspace() {
    mkdir -p ~/homelab-k8s
    cd ~/homelab-k8s
    
    # Create terraform.tfvars
    cat << EOF > terraform.tfvars
control_plane_ip = "${CONTROL_PLANE_IP}"
worker_node_ip = "${WORKER_NODE_IP}"
ssh_private_key = "~/.ssh/id_rsa"
EOF

    # Copy main.tf from previous artifact
    cat << 'EOF' > main.tf
# Content from previous k8s-terraform artifact
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --control-plane)
                IS_CONTROL_PLANE=true
                CONTROL_PLANE_IP=$(ip -4 addr show $(ip route | grep default | awk '{print $5}') | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
                shift
                ;;
            --worker)
                IS_CONTROL_PLANE=false
                WORKER_NODE_IP=$(ip -4 addr show $(ip route | grep default | awk '{print $5}') | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
                shift
                ;;
            *)
                echo "Usage: $0 [--control-plane|--worker]"
                exit 1
                ;;
        esac
    done

    # Run network checks
    main_network_check
    
    # Setup prerequisites
    setup_prerequisites
    
    if [ "$IS_CONTROL_PLANE" = true ]; then
        install_terraform
        create_terraform_workspace
        
        echo "Control plane node prepared. Ready to run Terraform."
        echo "Run: cd ~/homelab-k8s && terraform init && terraform apply"
    else
        echo "Worker node prepared. Ready for Terraform configuration from control plane."
    fi
}

main "$@"