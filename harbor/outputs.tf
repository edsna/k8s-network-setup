output "harbor_url" {
  description = "URL to access Harbor"
  value       = module.harbor.access_url
}

output "harbor_admin_username" {
  description = "Harbor admin username"
  value       = "admin"
}

output "harbor_namespace" {
  description = "Namespace where Harbor is deployed"
  value       = module.harbor_namespace.name
}