# ============================================================
# MODULE OUTPUTS: hub-vnet
# ============================================================
# Outputs are how a module exposes values to the caller.
# The environments/dev/main.tf will reference these as:
#   module.hub_vnet.vnet_id
#   module.hub_vnet.firewall_subnet_id
#   etc.
# ============================================================

output "resource_group_name" {
  description = "Name of the Hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "resource_group_location" {
  description = "Location of the Hub resource group"
  value       = azurerm_resource_group.hub.location
}

output "vnet_id" {
  description = "Resource ID of the Hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the Hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "ID of AzureFirewallSubnet — passed to the Firewall module"
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "ID of AzureBastionSubnet — passed to Bastion resource"
  value       = azurerm_subnet.bastion.id
}

output "apim_subnet_id" {
  description = "ID of the APIM subnet"
  value       = azurerm_subnet.apim.id
}

output "gateway_subnet_id" {
  description = "ID of GatewaySubnet — used if deploying VPN Gateway later"
  value       = azurerm_subnet.gateway.id
}
