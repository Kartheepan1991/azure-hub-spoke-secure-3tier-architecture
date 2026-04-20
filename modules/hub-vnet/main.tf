# ============================================================
# MODULE: hub-vnet
# ============================================================
# Creates the Hub Virtual Network with all required subnets.
#
# Hub VNet is the CENTRAL network in a Hub-Spoke topology.
# All spoke traffic is routed THROUGH the hub (via Firewall).
#
# Subnets created:
#   AzureFirewallSubnet  — Required name for Azure Firewall (/26 min)
#   AzureBastionSubnet   — Required name for Azure Bastion (/27 min)
#   snet-apim            — Azure API Management subnet
#   GatewaySubnet        — Reserved for VPN/ExpressRoute gateway
# ============================================================

# ── Resource Group ────────────────────────────────────────────
# A resource group is a logical container for Azure resources.
# All hub resources go in this one group.

resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.project}-hub-${var.environment}"
  location = var.location

  tags = var.tags
}

# ── Hub Virtual Network ───────────────────────────────────────
# The VNet is an isolated private network in Azure.
# address_space defines the overall IP range (10.0.0.0/16 = 65,536 IPs)

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.project}-hub-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.address_space]

  tags = var.tags
}

# ── Azure Firewall Subnet ─────────────────────────────────────
# IMPORTANT: This subnet MUST be named "AzureFirewallSubnet"
# Azure enforces this naming — Firewall deployment will fail otherwise.
# Minimum size: /26 (64 IPs). We use /26.

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # DO NOT rename
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix] # e.g. 10.0.1.0/26
}

# ── Azure Bastion Subnet ──────────────────────────────────────
# IMPORTANT: Must be named "AzureBastionSubnet"
# Bastion lets you RDP/SSH into VMs directly from Azure Portal
# WITHOUT exposing public IPs on VMs — much more secure!
# Minimum size: /27 (32 IPs)

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # DO NOT rename
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix] # e.g. 10.0.2.0/27
}

# ── APIM Subnet ───────────────────────────────────────────────
# API Management will sit in this subnet in the Hub.
# APIM in internal mode is accessible only within the VNet.
# For Consumption tier (our choice), APIM is serverless — no subnet needed.
# We still create this for learning purposes / future use.

resource "azurerm_subnet" "apim" {
  name                 = "snet-apim"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.apim_subnet_prefix] # e.g. 10.0.3.0/24
}

# ── Gateway Subnet ────────────────────────────────────────────
# Reserved for VPN Gateway or ExpressRoute — connects on-prem to Azure.
# MUST be named "GatewaySubnet" (Azure enforced).
# We create it now, deploy gateway later if needed.

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # DO NOT rename
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix] # e.g. 10.0.4.0/27
}
