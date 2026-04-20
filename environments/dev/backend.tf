# ============================================================
# BACKEND CONFIGURATION — Where Terraform stores state
# ============================================================
# Terraform STATE tracks what has been deployed in Azure.
# Without state, Terraform can't know what exists and what to change.
#
# LOCAL backend (used here):
#   - State saved in terraform.tfstate file on your machine
#   - Good for learning/solo dev
#
# REMOTE backend (production best practice):
#   - Store state in Azure Storage Account (blob)
#   - Enables team collaboration and state locking
#   - See commented block below for future use
# ============================================================

terraform {
  backend "local" {
    path = "terraform.tfstate" # Saved in environments/dev/ folder
  }
}

# ============================================================
# FUTURE USE: Remote State in Azure Storage
# ============================================================
# Uncomment this block and remove the 'local' block above
# when you want to store state remotely (team/production use).
#
# Before using this, create:
#   az group create -n rg-tfstate -l eastus
#   az storage account create -n stterraformstate123 -g rg-tfstate --sku Standard_LRS
#   az storage container create -n tfstate --account-name stterraformstate123
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-tfstate"
#     storage_account_name = "stterraformstate123"
#     container_name       = "tfstate"
#     key                  = "dev/terraform.tfstate"
#   }
# }
