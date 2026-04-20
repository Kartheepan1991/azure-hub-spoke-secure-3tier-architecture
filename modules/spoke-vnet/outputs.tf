output "resource_group_name" {
  value = azurerm_resource_group.spoke.name
}

output "vnet_id" {
  description = "Spoke VNet resource ID — used in peering module"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet name — used in peering module"
  value       = azurerm_virtual_network.spoke.name
}

output "workload_subnet_id" {
  description = "ID of the workload subnet — used for VM NICs, NSG, UDR"
  value       = azurerm_subnet.workload.id
}

output "workload_subnet_name" {
  description = "Name of the workload subnet"
  value       = azurerm_subnet.workload.name
}
