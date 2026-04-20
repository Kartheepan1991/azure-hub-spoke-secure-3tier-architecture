# ============================================================
# VARIABLE DECLARATIONS — Dev Environment
# ============================================================
# Variables make your code reusable across environments.
# You declare them here, then set their values in terraform.tfvars
# ============================================================

# ── Azure Identity ────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region where all resources will be deployed"
  type        = string
  default     = "eastus"
}

# ── Naming & Tagging ──────────────────────────────────────────
variable "environment" {
  description = "Environment name (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name — used as a prefix in all resource names"
  type        = string
  default     = "hubspoke"
}

# ── Network Address Spaces ────────────────────────────────────
# Each VNet gets its own non-overlapping CIDR block.
# Hub is the central network; spokes are the workload networks.

variable "hub_address_space" {
  description = "CIDR block for the Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_web_address_space" {
  description = "CIDR block for Spoke 1 — Web Tier VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "spoke_app_address_space" {
  description = "CIDR block for Spoke 2 — App Tier VNet"
  type        = string
  default     = "10.2.0.0/16"
}

variable "spoke_data_address_space" {
  description = "CIDR block for Spoke 3 — Data Tier VNet"
  type        = string
  default     = "10.3.0.0/16"
}

# ── Windows VM Credentials ────────────────────────────────────
# These are used to log into all Windows VMs via RDP / Bastion.
# In production, use Azure Key Vault — NEVER hardcode passwords.

variable "admin_username" {
  description = "Local administrator username for all Windows VMs"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local administrator password for all Windows VMs"
  type        = string
  sensitive   = true # Terraform will NEVER print this in logs
}

# ── VM Size ───────────────────────────────────────────────────
variable "vm_size" {
  description = "Azure VM SKU — Standard_B2s is cheap for dev/testing"
  type        = string
  default     = "Standard_B2s"
}


