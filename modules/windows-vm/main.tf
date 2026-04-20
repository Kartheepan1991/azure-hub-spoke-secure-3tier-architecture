# ============================================================
# MODULE: windows-vm
# ============================================================
# Deploys a Windows Server 2022 VM with IIS web server.
# The VM is placed in a spoke subnet with NO public IP.
# Access is via Azure Bastion (RDP over HTTPS from portal).
#
# For testing, the VM runs a PowerShell bootstrap script
# that installs IIS and deploys a small web application.
#
# Components:
#   azurerm_network_interface  → VM's virtual network card
#   azurerm_windows_virtual_machine → The VM itself
#   azurerm_virtual_machine_extension → PowerShell bootstrap (IIS + app)
# ============================================================

# ── Network Interface Card (NIC) ──────────────────────────────
# The NIC is the VM's connection to the VNet subnet.
# We use DYNAMIC private IP (Azure picks one from subnet range).
# No public IP — access is via Bastion only.

resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic" # Azure auto-assigns from subnet range
    # No public_ip_address_id = no internet-facing IP on this VM
  }

  tags = var.tags
}

# ── Windows Virtual Machine ───────────────────────────────────
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size            # e.g. Standard_B2s
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  # Connect this VM to the NIC we created above
  network_interface_ids = [azurerm_network_interface.vm.id]

  # ── OS Disk ───────────────────────────────────────────────
  # Premium_LRS = faster SSD-backed storage
  # caching = ReadWrite is optimal for OS disks
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Cheaper for dev; use Premium_LRS in prod
  }

  # ── Source Image ──────────────────────────────────────────
  # Windows Server 2022 Datacenter — latest/stable for IIS
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  # ── Timezone ──────────────────────────────────────────────
  timezone = "UTC"

  # ── Boot Diagnostics ──────────────────────────────────────
  # Saves boot screenshots to a storage account.
  # Helpful for diagnosing stuck VMs during first boot.
  boot_diagnostics {}  # Empty block = use managed storage (no cost)

  tags = var.tags
}

# ── Custom Script Extension — IIS + Sample Application ────────
# This PowerShell script runs ONCE during first boot.
# It installs IIS, and deploys a different page per tier:
#   web tier  → HTML welcome page (simulates frontend)
#   app tier  → JSON REST API response (simulates backend API)
#   data tier → Plain text response (simulates data service)
#
# The script is passed as base64-encoded inline command.

resource "azurerm_virtual_machine_extension" "iis_bootstrap" {
  name                 = "iis-bootstrap"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # The 'commandToExecute' runs the PowerShell inline.
  # We use var.bootstrap_script to pass tier-specific content.
  settings = jsonencode({
    commandToExecute = var.bootstrap_script
  })

  tags = var.tags
}
