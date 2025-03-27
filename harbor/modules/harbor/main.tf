resource "kubernetes_secret" "harbor_admin_password" {
  metadata {
    name      = "harbor-admin-secret"
    namespace = var.namespace
  }

  data = {
    "password" = var.admin_password
  }

  type = "Opaque"
}

resource "helm_release" "harbor" {
  name       = var.release_name
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  namespace  = var.namespace
  version    = var.chart_version

  # NodePort settings
  set {
    name  = "expose.type"
    value = "nodePort"
  }

  set {
    name  = "expose.tls.enabled"
    value = tostring(var.tls_enabled)
  }

  set {
    name  = "expose.nodePort.ports.http.nodePort"
    value = var.http_nodeport
  }

  set {
    name  = "expose.nodePort.ports.https.nodePort"
    value = var.https_nodeport
  }

  # External URL
  set {
    name  = "externalURL"
    value = var.tls_enabled ? "https://${var.domain}:${var.https_nodeport}" : "http://${var.domain}:${var.http_nodeport}"
  }

  # Admin password
  set {
    name  = "harborAdminPassword"
    value = kubernetes_secret.harbor_admin_password.data["password"]
  }

  # Storage settings
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  dynamic "set" {
    for_each = var.persistence_config
    content {
      name  = "persistence.persistentVolumeClaim.${set.key}.storageClass"
      value = set.value.storage_class
    }
  }

  dynamic "set" {
    for_each = var.persistence_config
    content {
      name  = "persistence.persistentVolumeClaim.${set.key}.size"
      value = set.value.size
    }
  }
}

resource "kubernetes_ingress_v1" "harbor_ingress" {
  count = var.create_ingress ? 1 : 0
  
  metadata {
    name      = "${var.release_name}-ingress"
    namespace = var.namespace
    annotations = merge({
      "kubernetes.io/ingress.class"                 = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
      "nginx.ingress.kubernetes.io/ssl-redirect"    = tostring(var.tls_enabled)
    }, var.ingress_annotations)
  }

  spec {
    rule {
      host = var.domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${var.release_name}-portal"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.tls_enabled && var.tls_secret_name != "" ? [1] : []
      content {
        hosts       = [var.domain]
        secret_name = var.tls_secret_name
      }
    }
  }

  depends_on = [
    helm_release.harbor
  ]
}