variable "namespace" {
  description = "Namespace where Harbor will be deployed"
  type        = string
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "harbor"
}

variable "chart_version" {
  description = "Version of the Harbor Helm chart"
  type        = string
  default     = "1.13.0"
}

variable "admin_password" {
  description = "Admin password for Harbor"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name for Harbor"
  type        = string
}

variable "http_nodeport" {
  description = "NodePort for HTTP traffic"
  type        = string
  default     = "30002"
}

variable "https_nodeport" {
  description = "NodePort for HTTPS traffic"
  type        = string
  default     = "30003"
}

variable "tls_enabled" {
  description = "Whether TLS is enabled"
  type        = bool
  default     = false
}

variable "create_ingress" {
  description = "Whether to create an ingress"
  type        = bool
  default     = true
}

variable "ingress_annotations" {
  description = "Additional annotations for the ingress"
  type        = map(string)
  default     = {}
}

variable "tls_secret_name" {
  description = "Name of the TLS secret"
  type        = string
  default     = ""
}

variable "persistence_config" {
  description = "Configuration for persistent volumes"
  type = map(object({
    storage_class = string
    size          = string
  }))
  default = {
    registry = {
      storage_class = "local-hostpath"
      size          = "10Gi"
    }
    chartmuseum = {
      storage_class = "local-hostpath"
      size          = "5Gi"
    }
    jobservice = {
      storage_class = "local-hostpath"
      size          = "1Gi"
    }
    database = {
      storage_class = "local-hostpath"
      size          = "1Gi"
    }
    redis = {
      storage_class = "local-hostpath"
      size          = "1Gi"
    }
    trivy = {
      storage_class = "local-hostpath"
      size          = "5Gi"
    }
  }
}