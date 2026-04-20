# ============================================================
# MODULE: udr (User Defined Routes)
# ============================================================
# UDR overrides Azure's default system routes.
# We add a route: 0.0.0.0/0 → Next hop = Azure Firewall Private IP
#
# This FORCES all outbound traffic from spoke VMs through the Firewall.
# Without this, traffic would bypass the Firewall entirely!
#
# This module is called once per spoke subnet.
# ============================================================

# ── Route Table ───────────────────────────────────────────────
# A route table is a container for custom routes.
# disable_bgp_route_propagation = true → Prevents on-prem VPN routes
# from being propagated into this table (keeps routing predictable).

resource "azurerm_route_table" "spoke" {
  name                       = "rt-${var.project}-${var.spoke_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  bgp_route_propagation_enabled = false # Don't accept dynamic routes from VPN gateway

  tags = var.tags
}

# ── Default Route → Firewall ──────────────────────────────────
# 0.0.0.0/0 = "everything else" (default route)
# 'VirtualAppliance' = next hop is a specific IP (the Firewall)
# All traffic from spoke VMs goes to Firewall first.

resource "azurerm_route" "to_firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.spoke.name
  address_prefix         = "0.0.0.0/0"              # Match ALL destinations
  next_hop_type          = "VirtualAppliance"        # Custom IP as next hop
  next_hop_in_ip_address = var.firewall_private_ip   # Azure Firewall's private IP
}

# ── Associate Route Table with Subnet ─────────────────────────
# The route table only takes effect when ASSOCIATED with a subnet.
# We associate it with the spoke's workload subnet.

resource "azurerm_subnet_route_table_association" "spoke" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.spoke.id
}
