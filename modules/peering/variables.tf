variable "spoke_name" {
  description = "Spoke name for peering resource naming — e.g. 'web', 'app', 'data'"
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the Hub VNet"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the Hub VNet"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group containing the Hub VNet"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the Spoke VNet"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Name of the Spoke VNet"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Resource group containing the Spoke VNet"
  type        = string
}
