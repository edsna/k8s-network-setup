terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "harbor_namespace" {
  source = "./modules/namespace"

  namespace_name = var.namespace_name
  labels = {
    environment = var.environment
    app         = "harbor"
  }
}

module "harbor" {
  source = "./modules/harbor"

  namespace        = module.harbor_namespace.name
  admin_password   = var.harbor_admin_password
  domain           = var.harbor_domain
  http_nodeport    = var.harbor_http_nodeport
  https_nodeport   = var.harbor_https_nodeport
  tls_enabled      = var.harbor_tls_enabled
  create_ingress   = var.create_ingress
  
  persistence_config = {
    registry = {
      storage_class = var.storage_class
      size          = "10Gi"
    }
    chartmuseum = {
      storage_class = var.storage_class
      size          = "5Gi"
    }
    jobservice = {
      storage_class = var.storage_class
      size          = "1Gi"
    }
    database = {
      storage_class = var.storage_class
      size          = "1Gi"
    }
    redis = {
      storage_class = var.storage_class
      size          = "1Gi"
    }
    trivy = {
      storage_class = var.storage_class
      size          = "5Gi"
    }
  }
  
  depends_on = [
    module.harbor_namespace
  ]
}