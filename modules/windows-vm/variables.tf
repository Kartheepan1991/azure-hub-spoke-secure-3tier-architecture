variable "vm_name" {
  description = "Name of the VM — e.g. vm-hubspoke-web-dev"
  type        = string
}

variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "subnet_id" {
  description = "Subnet ID where the VM's NIC will be placed"
  type        = string
}

variable "vm_size" {
  description = "VM SKU — Standard_B2s is cheapest Windows-compatible size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Windows local admin username"
  type        = string
}

variable "admin_password" {
  description = "Windows local admin password (min 12 chars, complexity required)"
  type        = string
  sensitive   = true
}

variable "bootstrap_script" {
  description = "PowerShell command to run on first boot (installs IIS + deploys app)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
