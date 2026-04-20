# ============================================================
# DEV ENVIRONMENT — Main Orchestration
# ============================================================
# This file CALLS all modules in the correct order.
# Terraform figures out the dependency order automatically
# using output references (e.g., module.hub_vnet.vnet_id).
#
# Deployment order (Terraform resolves this automatically):
#   1. hub-vnet       → creates Hub VNet + subnets
#   2. spoke-vnets    → creates 3 spoke VNets (in parallel)
#   3. peering        → connects Hub ↔ each Spoke (after VNets exist)
#   4. firewall       → deploys Azure Firewall in Hub
#   5. udr            → creates route tables → points to Firewall IP
#   6. nsg            → creates NSGs per tier
#   7. windows-vms    → deploys VMs in each spoke
#   8. apim           → deploys APIM, uses App VM's private IP
# ============================================================

# ── Common Tags ───────────────────────────────────────────────
# Applied to ALL resources — makes cost tracking and management easier
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    CreatedDate = "2026"
  }

  # ── Bootstrap Scripts (PowerShell) ──────────────────────────
  # These run once on VM first boot via CustomScriptExtension.
  # Each tier gets a different application to simulate real workloads.

  # WEB TIER: IIS with a simple HTML frontend
  web_bootstrap = <<-PS1
    powershell -Command "
      Install-WindowsFeature -Name Web-Server -IncludeManagementTools;
      $html = '<html><head><title>Hub-Spoke Web Tier</title><style>body{font-family:Arial;background:#1e3a5f;color:white;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;}.box{text-align:center;padding:40px;background:#2563eb;border-radius:12px;}.badge{background:#16a34a;padding:4px 12px;border-radius:20px;font-size:14px;}</style></head><body><div class=\"box\"><h1>Hub-Spoke Architecture</h1><h2>WEB TIER - Spoke 1</h2><p class=\"badge\">RUNNING</p><p>Azure Hub-Spoke | Dev Environment</p><p>Traffic routes through Azure Firewall</p></div></body></html>';
      Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $html;
    "
  PS1

  # APP TIER: IIS with a simple REST API (returns JSON)
  app_bootstrap = <<-PS1
    powershell -Command "
      Install-WindowsFeature -Name Web-Server -IncludeManagementTools;
      Install-WindowsFeature -Name Web-CGI;
      # Create a simple JSON response page
      $apiPage = '<html><head><title>App API</title></head><body><pre id=\"json\"></pre><script>document.getElementById(\"json\").textContent = JSON.stringify({status:\"healthy\",tier:\"app\",message:\"Hub-Spoke App Tier API\",timestamp:new Date().toISOString(),environment:\"dev\"},null,2);</script></body></html>';
      Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $apiPage;
      # Create /api/hello endpoint
      New-Item -ItemType Directory -Path 'C:\\inetpub\\wwwroot\\api' -Force;
      $helloJson = '{\"message\":\"Hello from App Tier!\",\"tier\":\"app\",\"version\":\"1.0\"}';
      Set-Content -Path 'C:\\inetpub\\wwwroot\\api\\hello' -Value $helloJson;
      # Create /api/health endpoint
      $healthJson = '{\"status\":\"healthy\",\"tier\":\"app\",\"uptime\":\"running\"}';
      Set-Content -Path 'C:\\inetpub\\wwwroot\\api\\health' -Value $healthJson;
    "
  PS1

  # DATA TIER: Simple text page (simulates data service — no real DB for lab)
  data_bootstrap = <<-PS1
    powershell -Command "
      Install-WindowsFeature -Name Web-Server -IncludeManagementTools;
      $page = '<html><head><title>Data Tier</title></head><body><h1>Data Tier</h1><p>Hub-Spoke Spoke 3 - Data Layer</p><p>Only accessible from App Tier</p></body></html>';
      Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $page;
    "
  PS1
}

# ══════════════════════════════════════════════════════════════
# 1. HUB VNET — Central network
# ══════════════════════════════════════════════════════════════
module "hub_vnet" {
  source = "../../modules/hub-vnet"

  project     = var.project
  environment = var.environment
  location    = var.location

  address_space          = var.hub_address_space   # 10.0.0.0/16
  firewall_subnet_prefix = "10.0.1.0/26"           # AzureFirewallSubnet (required /26)
  bastion_subnet_prefix  = "10.0.2.0/27"           # AzureBastionSubnet (required /27)
  apim_subnet_prefix     = "10.0.3.0/24"           # APIM subnet
  gateway_subnet_prefix  = "10.0.4.0/27"           # GatewaySubnet

  tags = local.common_tags
}

# ══════════════════════════════════════════════════════════════
# 2. SPOKE VNETS — One per application tier
# ══════════════════════════════════════════════════════════════
# Same module called 3 times with different spoke_name and CIDRs.
# Each creates its own resource group, VNet, and subnet.

module "spoke_web" {
  source = "../../modules/spoke-vnet"

  project       = var.project
  environment   = var.environment
  location      = var.location
  spoke_name    = "web"
  address_space = var.spoke_web_address_space  # 10.1.0.0/16
  subnet_prefix = "10.1.1.0/24"               # Web workload subnet

  tags = local.common_tags
}

module "spoke_app" {
  source = "../../modules/spoke-vnet"

  project       = var.project
  environment   = var.environment
  location      = var.location
  spoke_name    = "app"
  address_space = var.spoke_app_address_space  # 10.2.0.0/16
  subnet_prefix = "10.2.1.0/24"               # App workload subnet

  tags = local.common_tags
}

module "spoke_data" {
  source = "../../modules/spoke-vnet"

  project       = var.project
  environment   = var.environment
  location      = var.location
  spoke_name    = "data"
  address_space = var.spoke_data_address_space # 10.3.0.0/16
  subnet_prefix = "10.3.1.0/24"               # Data workload subnet

  tags = local.common_tags
}

# ══════════════════════════════════════════════════════════════
# 3. VNET PEERING — Hub ↔ Each Spoke (bidirectional)
# ══════════════════════════════════════════════════════════════
# Called 3 times — once per spoke.
# The module creates 2 peerings per call (hub→spoke + spoke→hub).

module "peering_web" {
  source = "../../modules/peering"

  spoke_name                = "web"
  hub_vnet_id               = module.hub_vnet.vnet_id
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_resource_group_name   = module.hub_vnet.resource_group_name
  spoke_vnet_id             = module.spoke_web.vnet_id
  spoke_vnet_name           = module.spoke_web.vnet_name
  spoke_resource_group_name = module.spoke_web.resource_group_name

  depends_on = [module.hub_vnet, module.spoke_web]
}

module "peering_app" {
  source = "../../modules/peering"

  spoke_name                = "app"
  hub_vnet_id               = module.hub_vnet.vnet_id
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_resource_group_name   = module.hub_vnet.resource_group_name
  spoke_vnet_id             = module.spoke_app.vnet_id
  spoke_vnet_name           = module.spoke_app.vnet_name
  spoke_resource_group_name = module.spoke_app.resource_group_name

  depends_on = [module.hub_vnet, module.spoke_app]
}

module "peering_data" {
  source = "../../modules/peering"

  spoke_name                = "data"
  hub_vnet_id               = module.hub_vnet.vnet_id
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_resource_group_name   = module.hub_vnet.resource_group_name
  spoke_vnet_id             = module.spoke_data.vnet_id
  spoke_vnet_name           = module.spoke_data.vnet_name
  spoke_resource_group_name = module.spoke_data.resource_group_name

  depends_on = [module.hub_vnet, module.spoke_data]
}

# ══════════════════════════════════════════════════════════════
# 4. AZURE FIREWALL — Security inspection point
# ══════════════════════════════════════════════════════════════
# Deployed in the Hub VNet's AzureFirewallSubnet.
# Firewall rules: allow web→app (80/443), app→data (1433), Windows Update

module "firewall" {
  source = "../../modules/firewall"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = module.hub_vnet.resource_group_name
  firewall_subnet_id  = module.hub_vnet.firewall_subnet_id

  # These CIDRs are used in firewall rules (inter-spoke traffic)
  spoke_web_subnet  = "10.1.1.0/24"
  spoke_app_subnet  = "10.2.1.0/24"
  spoke_data_subnet = "10.3.1.0/24"

  tags       = local.common_tags
  depends_on = [module.hub_vnet]
}

# ══════════════════════════════════════════════════════════════
# 5. USER DEFINED ROUTES — Force all traffic via Firewall
# ══════════════════════════════════════════════════════════════
# One route table per spoke subnet.
# Each adds default route: 0.0.0.0/0 → Firewall private IP

module "udr_web" {
  source = "../../modules/udr"

  project             = var.project
  environment         = var.environment
  location            = var.location
  spoke_name          = "web"
  resource_group_name = module.spoke_web.resource_group_name
  subnet_id           = module.spoke_web.workload_subnet_id
  firewall_private_ip = module.firewall.firewall_private_ip  # Output from firewall module

  tags       = local.common_tags
  depends_on = [module.firewall, module.spoke_web]
}

module "udr_app" {
  source = "../../modules/udr"

  project             = var.project
  environment         = var.environment
  location            = var.location
  spoke_name          = "app"
  resource_group_name = module.spoke_app.resource_group_name
  subnet_id           = module.spoke_app.workload_subnet_id
  firewall_private_ip = module.firewall.firewall_private_ip

  tags       = local.common_tags
  depends_on = [module.firewall, module.spoke_app]
}

module "udr_data" {
  source = "../../modules/udr"

  project             = var.project
  environment         = var.environment
  location            = var.location
  spoke_name          = "data"
  resource_group_name = module.spoke_data.resource_group_name
  subnet_id           = module.spoke_data.workload_subnet_id
  firewall_private_ip = module.firewall.firewall_private_ip

  tags       = local.common_tags
  depends_on = [module.firewall, module.spoke_data]
}

# ══════════════════════════════════════════════════════════════
# 6. NETWORK SECURITY GROUPS — Per-tier subnet filtering
# ══════════════════════════════════════════════════════════════

module "nsg_web" {
  source = "../../modules/nsg"

  project               = var.project
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.spoke_web.resource_group_name
  tier                  = "web"
  subnet_id             = module.spoke_web.workload_subnet_id
  bastion_subnet_prefix = "10.0.2.0/27"  # Hub Bastion subnet
  source_address_prefix = "*"            # Web allows traffic from internet

  tags       = local.common_tags
  depends_on = [module.spoke_web]
}

module "nsg_app" {
  source = "../../modules/nsg"

  project               = var.project
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.spoke_app.resource_group_name
  tier                  = "app"
  subnet_id             = module.spoke_app.workload_subnet_id
  bastion_subnet_prefix = "10.0.2.0/27"
  source_address_prefix = "10.1.1.0/24"  # Only from Web subnet

  tags       = local.common_tags
  depends_on = [module.spoke_app]
}

module "nsg_data" {
  source = "../../modules/nsg"

  project               = var.project
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.spoke_data.resource_group_name
  tier                  = "data"
  subnet_id             = module.spoke_data.workload_subnet_id
  bastion_subnet_prefix = "10.0.2.0/27"
  source_address_prefix = "10.2.1.0/24"  # Only from App subnet

  tags       = local.common_tags
  depends_on = [module.spoke_data]
}

# ══════════════════════════════════════════════════════════════
# 7. WINDOWS VIRTUAL MACHINES — One per tier
# ══════════════════════════════════════════════════════════════
# Each VM is placed in its spoke's workload subnet.
# Bootstrap scripts install IIS and deploy tier-specific content.

module "vm_web" {
  source = "../../modules/windows-vm"

  vm_name             = "vm-${var.project}-web-${var.environment}"
  location            = var.location
  resource_group_name = module.spoke_web.resource_group_name
  subnet_id           = module.spoke_web.workload_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  bootstrap_script    = local.web_bootstrap

  tags       = local.common_tags
  depends_on = [module.nsg_web, module.udr_web]
}

module "vm_app" {
  source = "../../modules/windows-vm"

  vm_name             = "vm-${var.project}-app-${var.environment}"
  location            = var.location
  resource_group_name = module.spoke_app.resource_group_name
  subnet_id           = module.spoke_app.workload_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  bootstrap_script    = local.app_bootstrap

  tags       = local.common_tags
  depends_on = [module.nsg_app, module.udr_app]
}

module "vm_data" {
  source = "../../modules/windows-vm"

  vm_name             = "vm-${var.project}-data-${var.environment}"
  location            = var.location
  resource_group_name = module.spoke_data.resource_group_name
  subnet_id           = module.spoke_data.workload_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  bootstrap_script    = local.data_bootstrap

  tags       = local.common_tags
  depends_on = [module.nsg_data, module.udr_data]
}


