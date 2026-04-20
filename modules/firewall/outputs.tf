output "firewall_id" {
  value = azurerm_firewall.main.id
}

output "firewall_name" {
  value = azurerm_firewall.main.name
}

output "firewall_private_ip" {
  description = "Private IP of Firewall — used as 'next hop' in UDR route tables"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP assigned to the Firewall for outbound internet"
  value       = azurerm_public_ip.firewall.ip_address
}
