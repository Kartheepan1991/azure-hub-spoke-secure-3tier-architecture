variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  description = "Hub resource group where Firewall is deployed"
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of AzureFirewallSubnet in Hub VNet"
  type        = string
}

variable "spoke_web_subnet" {
  description = "CIDR of web spoke workload subnet — used in firewall rules"
  type        = string
}

variable "spoke_app_subnet" {
  description = "CIDR of app spoke workload subnet — used in firewall rules"
  type        = string
}

variable "spoke_data_subnet" {
  description = "CIDR of data spoke workload subnet — used in firewall rules"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
