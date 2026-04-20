variable "project" {
  description = "Project prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "spoke_name" {
  description = "Spoke identifier — e.g. 'web', 'app', 'data'"
  type        = string
}

variable "address_space" {
  description = "VNet CIDR for this spoke — e.g. 10.1.0.0/16"
  type        = string
}

variable "subnet_prefix" {
  description = "Workload subnet CIDR — e.g. 10.1.1.0/24"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
