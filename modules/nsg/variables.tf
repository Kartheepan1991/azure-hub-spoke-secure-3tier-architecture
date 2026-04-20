variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "tier" {
  description = "Which tier this NSG is for: 'web', 'app', or 'data'"
  type        = string
  validation {
    condition     = contains(["web", "app", "data"], var.tier)
    error_message = "tier must be 'web', 'app', or 'data'."
  }
}

variable "subnet_id" {
  description = "Subnet to associate this NSG with"
  type        = string
}

variable "source_address_prefix" {
  description = "Source CIDR for inbound rules (e.g. web subnet for app tier)"
  type        = string
  default     = "*"
}

variable "bastion_subnet_prefix" {
  description = "Bastion subnet CIDR — only Bastion can RDP into VMs"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
