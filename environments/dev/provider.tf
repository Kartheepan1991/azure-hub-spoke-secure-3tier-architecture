# ============================================================
# PROVIDER CONFIGURATION
# ============================================================
# This block tells Terraform:
#   1. Which providers (cloud SDKs) to download
#   2. The minimum version required (>= 3.0 means 3.x or higher)
#   3. Which version of Terraform CLI is needed
# ============================================================

terraform {
  required_version = ">= 1.5.0" # Minimum Terraform CLI version

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # Official Azure provider from HashiCorp registry
      version = "~> 3.100"         # Use 3.100.x — '~>' means allow patch updates only
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5" # Used to generate unique suffixes for globally unique names
    }
  }
}

# ============================================================
# AZURE PROVIDER SETTINGS
# ============================================================
# 'features {}' is required — it enables/configures Azure-specific
# behaviours. We leave it empty to use all defaults.
# ============================================================

provider "azurerm" {
  features {
    # Key Vault: Do not purge on destroy (safe for dev)
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    # Virtual Machines: Delete OS disk when VM is destroyed
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = var.subscription_id # Passed in via variables
}
