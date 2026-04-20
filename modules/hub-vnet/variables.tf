# ============================================================
# MODULE INPUTS: hub-vnet
# ============================================================
# All values the calling environment must provide to this module.
# ============================================================

variable "project" {
  description = "Project prefix used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "Hub VNet CIDR block"
  type        = string
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet (min /26)"
  type        = string
}

variable "bastion_subnet_prefix" {
  description = "CIDR for AzureBastionSubnet (min /27)"
  type        = string
}

variable "apim_subnet_prefix" {
  description = "CIDR for APIM subnet"
  type        = string
}

variable "gateway_subnet_prefix" {
  description = "CIDR for GatewaySubnet (min /27)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
