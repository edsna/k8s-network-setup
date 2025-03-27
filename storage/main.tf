# storage/main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
  }
}


provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
  }
}

# Deploy OpenEBS for storage
resource "helm_release" "openebs" {
  name             = "openebs"
  repository       = "https://openebs.github.io/charts"
  chart            = "openebs"
  namespace        = "openebs"
  create_namespace = true
  version          = "3.9.0"

  set {
    name  = "ndm.enabled"
    value = "true"
  }

  set {
    name  = "ndmOperator.enabled"
    value = "true"
  }
}

# Create default StorageClass
resource "kubernetes_storage_class" "local_hostpath" {
  metadata {
    name = "local-hostpath"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "openebs.io/local"
  reclaim_policy     = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}
