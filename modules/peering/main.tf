# ============================================================
# MODULE: peering
# ============================================================
# Creates BIDIRECTIONAL VNet peering between Hub and one Spoke.
# This module is called once per spoke (3 times total).
#
# Peering rules:
#   allow_virtual_network_access = true  → VMs can talk to each other
#   allow_forwarded_traffic      = true  → Spoke accepts traffic from Firewall
#   allow_gateway_transit        = true  → Hub shares its VPN Gateway with spokes
#   use_remote_gateways          = true  → Spoke uses Hub's VPN Gateway
#
# NOTE: use_remote_gateways on spoke requires allow_gateway_transit on hub.
# ============================================================

# ── Hub → Spoke Peering ───────────────────────────────────────
# Created in the Hub VNet's resource group
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name = "peer-hub-to-${var.spoke_name}"

  # This peering lives in the HUB VNet
  resource_group_name  = var.hub_resource_group_name
  virtual_network_name = var.hub_vnet_name

  # It points TO the Spoke VNet
  remote_virtual_network_id = var.spoke_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true  # Hub shares gateway (if it has one)
  use_remote_gateways          = false # Hub doesn't use spoke's gateway
}

# ── Spoke → Hub Peering ───────────────────────────────────────
# Created in the Spoke VNet's resource group
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name = "peer-${var.spoke_name}-to-hub"

  # This peering lives in the SPOKE VNet
  resource_group_name  = var.spoke_resource_group_name
  virtual_network_name = var.spoke_vnet_name

  # It points TO the Hub VNet
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true  # Accept forwarded traffic (from Firewall)
  allow_gateway_transit        = false # Spoke doesn't share its own gateway
  use_remote_gateways          = false # Set true only if Hub has a VPN Gateway deployed
}
