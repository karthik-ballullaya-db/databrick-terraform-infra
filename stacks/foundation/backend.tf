# ============================================================================
# Foundation Stack - Backend Configuration
# ============================================================================
# Configure your backend here for remote state storage
# The workspaces stack will reference this state via terraform_remote_state
# ============================================================================

# Example: Azure Storage Backend
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "tfstateaccount"
#     container_name       = "tfstate"
#     key                  = "foundation.tfstate"
#   }
# }

# For local development, you can use local backend (default)
# The state file will be stored in: stacks/foundation/terraform.tfstate

