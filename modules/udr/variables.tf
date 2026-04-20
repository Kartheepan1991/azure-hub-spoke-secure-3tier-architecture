variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "spoke_name" {
  description = "Spoke name for route table naming — e.g. 'web', 'app', 'data'"
  type        = string
}
variable "resource_group_name" {
  description = "Resource group to create the route table in"
  type        = string
}
variable "subnet_id" {
  description = "Subnet ID to associate the route table with"
  type        = string
}
variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall — used as next hop"
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
