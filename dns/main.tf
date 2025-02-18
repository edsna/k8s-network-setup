# dns/main.tf

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

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create DNS namespace
resource "kubernetes_namespace" "dns" {
  metadata {
    name = "dns"
    labels = {
      "app" = "coredns-external"
    }
  }
}

# Create ConfigMap for CoreDNS configuration
resource "kubernetes_config_map" "coredns_custom" {
  metadata {
    name      = "coredns-custom"
    namespace = kubernetes_namespace.dns.metadata[0].name
  }

  data = {
    "Corefile" = <<-EOT
      .:53 {
        errors
        health
        ready
        hosts {
          192.168.197.150 grafana.homelab.local prometheus.homelab.local
          fallthrough
        }
        forward . 8.8.8.8 8.8.4.4
        cache 30
        loop
        reload
        loadbalance
      }
    EOT
  }
}

# Deploy CoreDNS
resource "helm_release" "coredns" {
  name       = "coredns"
  repository = "https://coredns.github.io/helm"
  chart      = "coredns"
  namespace  = kubernetes_namespace.dns.metadata[0].name
  version    = "1.28.0"

  values = [<<-EOT
    service:
      type: NodePort
      nodePort: 32053
    servers:
    - zones:
      - zone: .
      port: 53
      plugins:
      - name: errors
      - name: health
        configBlock: |-
          lameduck 5s
      - name: ready
      - name: hosts
        configBlock: |-
          192.168.197.150 grafana.homelab.local prometheus.homelab.local
          fallthrough
      - name: forward
        parameters: . 8.8.8.8 8.8.4.4
      - name: cache
        parameters: 30
      - name: loop
      - name: reload
      - name: loadbalance
    EOT
  ]
}