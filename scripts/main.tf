terraform {
  required_version = ">= 1.0.0"
  backend "local" {
    path = "terraform.tfstate"
  }
}

variable "control_plane_ip" {
  type = string
}

variable "worker_node_ip" {
  type = string
}

variable "ssh_private_key" {
  type = string
}

provider "null" {}

resource "null_resource" "control_plane_setup" {
  connection {
    type        = "ssh"
    host        = var.control_plane_ip
    user        = "root"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      # Set DEBIAN_FRONTEND
      "export DEBIAN_FRONTEND=noninteractive",
      
      # Cleanup old installations
      "kubeadm reset -f || true",
      "systemctl stop kubelet || true",
      "systemctl stop containerd || true",
      "apt-get remove -y docker docker-engine docker.io containerd runc kubelet kubeadm kubectl || true",
      "apt-get autoremove -y",
      "rm -rf /etc/kubernetes/ /var/lib/kubelet/ /var/lib/etcd/ /root/.kube/ /etc/cni/net.d/",
      "rm -f /etc/apt/sources.list.d/kubernetes.list /etc/apt/sources.list.d/docker.list",
      "rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      
      # Clean iptables
      "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X",
      
      # Install dependencies
      "apt-get update",
      "apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg",
      
      # Install containerd
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list",
      "apt-get update",
      "apt-get install -y containerd.io",
      
      # Configure containerd with SystemdCgroup
      "mkdir -p /etc/containerd",
      "containerd config default > /etc/containerd/config.toml",
      "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml",
      "systemctl restart containerd",
      
      # Install K8s
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list",
      "apt-get update",
      "apt-get install -y kubelet=1.29.1-1.1 kubeadm=1.29.1-1.1 kubectl=1.29.1-1.1",
      "apt-mark hold kubelet kubeadm kubectl",
      
      # Initialize control plane
      "kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${var.control_plane_ip} --ignore-preflight-errors=NumCPU || true",
      
      # Set up kubectl
      "mkdir -p /root/.kube",
      "cp -i /etc/kubernetes/admin.conf /root/.kube/config",
      "chmod 600 /root/.kube/config",
      
      # Install Calico CNI
      "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml",
      
      # Save join command
      "kubeadm token create --print-join-command > /root/cluster_join_command.txt",
      "chmod 600 /root/cluster_join_command.txt"
    ]
  }
}

resource "null_resource" "worker_setup" {
  depends_on = [null_resource.control_plane_setup]
  
  connection {
    type        = "ssh"
    host        = var.worker_node_ip
    user        = "root"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      # Set DEBIAN_FRONTEND
      "export DEBIAN_FRONTEND=noninteractive",
      
      # Cleanup old installations
      "kubeadm reset -f || true",
      "systemctl stop kubelet || true",
      "systemctl stop containerd || true",
      "apt-get remove -y docker docker-engine docker.io containerd runc kubelet kubeadm kubectl || true",
      "apt-get autoremove -y",
      "rm -rf /etc/kubernetes/ /var/lib/kubelet/ /var/lib/etcd/ /root/.kube/ /etc/cni/net.d/",
      "rm -f /etc/apt/sources.list.d/kubernetes.list /etc/apt/sources.list.d/docker.list",
      "rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      
      # Clean iptables
      "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X",
      
      # Install dependencies
      "apt-get update",
      "apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg",
      
      # Install containerd
      "install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list",
      "apt-get update",
      "apt-get install -y containerd.io",
      
      # Configure containerd
      "mkdir -p /etc/containerd",
      "containerd config default > /etc/containerd/config.toml",
      "sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml",
      "systemctl restart containerd",
      
      # Install K8s
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list",
      "apt-get update",
      "apt-get install -y kubelet=1.29.1-1.1 kubeadm=1.29.1-1.1",
      "apt-mark hold kubelet kubeadm",
      
      # Join cluster (will be executed after getting the join command)
      "$(ssh -o StrictHostKeyChecking=no root@${var.control_plane_ip} 'cat /root/cluster_join_command.txt')"
    ]
  }
}

output "join_command_location" {
  value = "Join command is saved in /root/cluster_join_command.txt on the control plane node"
}