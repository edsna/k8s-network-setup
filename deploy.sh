#!/bin/bash

# Script to deploy Kubernetes network setup using Terraform

# Function to initialize and apply Terraform in a given directory
deploy_module() {
  local module_dir=$1
  echo "Deploying module in directory: $module_dir"
  cd "$module_dir" || exit
  terraform init
  terraform apply -auto-approve
  cd - || exit
}

# Function to check cluster components
check_cluster_components() {
  echo "===== Checking All Namespaces ====="
  kubectl get ns

  echo -e "\n===== Storage Components ====="
  kubectl get sc
  kubectl get pv,pvc -A

  echo -e "\n===== Monitoring Components ====="
  kubectl get pods -n monitoring
  kubectl get svc -n monitoring

  echo -e "\n===== Ingress Components ====="
  kubectl get pods -n ingress-nginx
  kubectl get svc -n ingress-nginx

  echo -e "\n===== DNS Components ====="
  kubectl get pods -n dns
  kubectl get svc -n dns
}

# Delete existing Helm releases
echo "Deleting existing Helm releases..."
helm uninstall ingress-nginx --namespace ingress-nginx || true
helm uninstall kube-prometheus-stack --namespace monitoring || true
helm uninstall openebs --namespace openebs || true

# Deploy modules in the specified order
echo "Deploying Storage Layer..."
deploy_module "storage"

echo "Deploying Monitoring Stack..."
deploy_module "monitoring"

echo "Deploying Ingress Controller..."
deploy_module "ingress"

echo "Deploying DNS Setup..."
deploy_module "dns"

# Check cluster components after deployment
echo -e "\n===== Checking Deployed Components ====="
check_cluster_components

echo "Deployment complete."

# chmod +x deploy.sh
# bash deploy.sh