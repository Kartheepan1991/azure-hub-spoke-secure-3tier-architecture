# ============================================================
# MODULE: spoke-vnet
# ============================================================
# Creates a single Spoke VNet with one workload subnet.
# This module is REUSED for all 3 spokes (web, app, data)
# by calling it 3 times with different variables.
#
# Hub-Spoke topology:
#   - All spoke VNets peer with the Hub (handled by peering module)
#   - All outbound traffic routes through Azure Firewall in Hub
#   - Spokes cannot talk to each other directly — must go via Hub
# ============================================================

# ── Spoke Resource Group ──────────────────────────────────────
resource "azurerm_resource_group" "spoke" {
  name     = "rg-${var.project}-${var.spoke_name}-${var.environment}"
  location = var.location

  tags = var.tags
}

# ── Spoke Virtual Network ─────────────────────────────────────
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.project}-${var.spoke_name}-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = [var.address_space]

  tags = var.tags
}

# ── Workload Subnet ───────────────────────────────────────────
# Each spoke has ONE workload subnet where VMs are deployed.
# UDR (route table) is attached here to force traffic via Firewall.

resource "azurerm_subnet" "workload" {
  name                 = "snet-${var.spoke_name}"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_prefix]

  # We attach NSG and UDR separately (from their own modules)
  # This separation = cleaner code + easier management
}
