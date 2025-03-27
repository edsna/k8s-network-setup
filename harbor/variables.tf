variable "namespace_name" {
  description = "Name of the namespace"
  type        = string
  default     = "harbor"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "harbor_admin_password" {
  description = "Admin password for Harbor"
  type        = string
  sensitive   = true
  default     = "dumbpw"  # Change this in production
}

variable "harbor_domain" {
  description = "Domain name for Harbor"
  type        = string
  default     = "harbor.homelab.local"
}

variable "harbor_http_nodeport" {
  description = "NodePort for HTTP traffic"
  type        = string
  default     = "30002"
}

variable "harbor_https_nodeport" {
  description = "NodePort for HTTPS traffic"
  type        = string
  default     = "30003"
}

variable "harbor_tls_enabled" {
  description = "Whether TLS is enabled"
  type        = bool
  default     = false
}

variable "create_ingress" {
  description = "Whether to create an ingress"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "local-hostpath"
}