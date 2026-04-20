output "vm_id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "private_ip_address" {
  description = "Private IP of the VM — used in APIM backend configuration"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "nic_id" {
  value = azurerm_network_interface.vm.id
}
