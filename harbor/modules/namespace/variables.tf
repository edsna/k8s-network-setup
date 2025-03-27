variable "namespace_name" {
  description = "Name of the namespace"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the namespace"
  type        = map(string)
  default     = {}
}