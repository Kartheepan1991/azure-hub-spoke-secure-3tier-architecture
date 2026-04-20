# ============================================================
# MODULE: nsg (Network Security Group)
# ============================================================
# NSG = a stateful packet filter applied at the subnet level.
# Rules have priority (lower = evaluated first).
# Default implicit rule: DENY ALL inbound not matching any rule.
#
# We create tier-specific rules based on var.tier:
#   "web"  — allows HTTP/HTTPS from internet, RDP from Bastion
#   "app"  — allows only traffic from web tier
#   "data" — allows only traffic from app tier
# ============================================================

# ── Network Security Group ────────────────────────────────────
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.project}-${var.tier}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # ── Rules for WEB tier ──────────────────────────────────────
  dynamic "security_rule" {
    for_each = var.tier == "web" ? [1] : []
    content {
      name                       = "allow-http-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"       # From anywhere (internet-facing)
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.tier == "web" ? [1] : []
    content {
      name                       = "allow-https-inbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  # ── Rules for APP tier ──────────────────────────────────────
  dynamic "security_rule" {
    for_each = var.tier == "app" ? [1] : []
    content {
      name                       = "allow-from-web-tier"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443", "8080"]
      source_address_prefix      = var.source_address_prefix  # Web subnet CIDR
      destination_address_prefix = "*"
    }
  }

  # ── Rules for DATA tier ─────────────────────────────────────
  dynamic "security_rule" {
    for_each = var.tier == "data" ? [1] : []
    content {
      name                       = "allow-from-app-tier"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["1433", "3306", "5432"]  # SQL ports
      source_address_prefix      = var.source_address_prefix  # App subnet CIDR
      destination_address_prefix = "*"
    }
  }

  # ── RDP via Bastion (all tiers) ──────────────────────────────
  # Azure Bastion connects on port 443, but internally RDP is 3389.
  # Bastion uses the AzureBastionSubnet range as source.
  dynamic "security_rule" {
    for_each = [1] # Applied to ALL tiers
    content {
      name                       = "allow-rdp-from-bastion"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = var.bastion_subnet_prefix  # Only from Bastion subnet
      destination_address_prefix = "*"
    }
  }

  # ── Deny all other inbound ───────────────────────────────────
  # Explicit deny rule (same as implicit default, but visible in portal)
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ── Associate NSG with Subnet ─────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
