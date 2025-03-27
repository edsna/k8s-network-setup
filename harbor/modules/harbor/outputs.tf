output "admin_secret_name" {
  description = "Name of the secret containing the admin password"
  value       = kubernetes_secret.harbor_admin_password.metadata[0].name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.harbor.name
}

output "ingress_host" {
  description = "Hostname used for the ingress"
  value       = var.domain
}

output "access_url" {
  description = "URL to access Harbor"
  value       = var.tls_enabled ? "https://${var.domain}:${var.https_nodeport}" : "http://${var.domain}:${var.http_nodeport}"
}