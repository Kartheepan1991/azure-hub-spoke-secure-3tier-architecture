# ============================================================
# MODULE: firewall
# ============================================================
# Deploys Azure Firewall Standard in the Hub VNet.
#
# Azure Firewall is a managed, stateful L4/L7 firewall.
# It inspects ALL traffic routed to it via UDR route tables.
#
# Components:
#   azurerm_public_ip            → Outbound internet IP for the Firewall
#   azurerm_firewall             → The firewall itself
#   azurerm_firewall_policy      → Container for all rule collections
#   azurerm_firewall_policy_rule_collection_group → Rules inside the policy
#
# Traffic flow (with UDR on spokes):
#   Spoke VM → Route Table (0.0.0.0/0 → Firewall IP) → Firewall → Internet/Other Spoke
# ============================================================

# ── Public IP for Firewall ────────────────────────────────────
# Firewall needs a dedicated Public IP for outbound internet traffic.
# 'Standard' SKU is required for Azure Firewall (not Basic).
# 'Static' allocation = IP never changes (needed for allowlisting).

resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.project}-fw-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"  # IP is fixed — doesn't change on restart
  sku                 = "Standard" # Must be Standard for Azure Firewall

  tags = var.tags
}

# ── Azure Firewall Policy ─────────────────────────────────────
# Policy is the modern way to manage Firewall rules.
# It's separate from the Firewall itself — you can reuse
# the same policy across multiple firewalls (useful for prod).

resource "azurerm_firewall_policy" "main" {
  name                = "afwp-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  # DNS proxy: Firewall acts as DNS resolver for VMs
  # This is required for FQDN-based application rules to work
  dns {
    proxy_enabled = true
  }

  tags = var.tags
}

# ── Azure Firewall ────────────────────────────────────────────
resource "azurerm_firewall" "main" {
  name                = "afw-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet" # Virtual Network firewall (not Azure VWan)
  sku_tier            = "Standard"  # Standard is sufficient; Premium adds IDPS

  # Link to the policy we created above
  firewall_policy_id = azurerm_firewall_policy.main.id

  # IP configuration — connects Firewall to the AzureFirewallSubnet
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id       # Must be AzureFirewallSubnet
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = var.tags
}

# ── Firewall Rule Collection Group ────────────────────────────
# Rules are organized in groups with priorities.
# Lower priority number = evaluated FIRST.
# Rule types:
#   network_rule_collection  → L4 rules (IP/Port/Protocol)
#   application_rule_collection → L7 rules (FQDNs/URLs)
#   nat_rule_collection      → DNAT (port forwarding from internet to VMs)

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "rcg-${var.project}-${var.environment}"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100 # Evaluated first among all rule groups

  # ── Network Rules ─────────────────────────────────────────
  # Allow inter-spoke communication (Web → App, App → Data)
  network_rule_collection {
    name     = "nrc-allow-spoke-to-spoke"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-web-to-app"
      protocols             = ["TCP"]
      source_addresses      = [var.spoke_web_subnet]   # Web tier IPs
      destination_addresses = [var.spoke_app_subnet]   # App tier IPs
      destination_ports     = ["80", "443", "8080"]    # HTTP/HTTPS/Alt-HTTP
    }

    rule {
      name                  = "allow-app-to-data"
      protocols             = ["TCP"]
      source_addresses      = [var.spoke_app_subnet]
      destination_addresses = [var.spoke_data_subnet]
      destination_ports     = ["1433", "3306", "5432"] # SQL Server, MySQL, PostgreSQL
    }
  }

  # ── Application Rules ─────────────────────────────────────
  # Allow VMs to reach specific internet destinations by FQDN.
  # This is L7 filtering — Firewall resolves hostnames.
  application_rule_collection {
    name     = "arc-allow-windows-update"
    priority = 200
    action   = "Allow"

    rule {
      name             = "allow-windows-update"
      source_addresses = ["10.0.0.0/8"] # All our VNets (hub + all spokes)
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      # Microsoft Update URLs
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.microsoft.com",
        "*.azure.com",
        "*.azureedge.net",
        "*.windows.com"
      ]
    }
  }
}
