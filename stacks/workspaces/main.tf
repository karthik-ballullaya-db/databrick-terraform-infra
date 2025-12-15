# ============================================================================
# Workspaces Stack - Main Entry Point
# ============================================================================
# 
# This stack uses a "one file per workspace" pattern.
# Each workspace has its own .tf file that declares:
#   - Its provider (with host from tfvars)
#   - All module calls using that provider
#
# Structure:
#   workspace_dev.tf       - Dev workspace resources
#   workspace_prod.tf      - Prod workspace resources  
#   workspace_analytics.tf - Analytics workspace resources
#
# To add a new workspace:
#   1. Create: resources/workspaces/<name>/ folder with JSON configs
#   2. Copy workspace_template.tf.example to workspace_<name>.tf
#   3. Find/replace "TEMPLATE" with your workspace name
#   4. Add variable workspace_<name>_host to variables.tf
#   5. Set the host URL in terraform.tfvars
#
# Each workspace file is self-contained with its own provider.
# ============================================================================

# ============================================================================
# Foundation State - Read outputs from foundation stack
# ============================================================================
# This data source reads the foundation stack's state to get:
#   - Access connector IDs (for storage credentials)
#   - Workspace IDs (for workspace bindings)
#   - Storage account details
# ============================================================================

# Option 1: Use terraform_remote_state (when using remote backend)
# Uncomment and configure when using Azure Storage backend
data "terraform_remote_state" "foundation" {
  backend = "azurerm"
  config = {
    resource_group_name  = "sj_terraform_state"
    storage_account_name = "sjtfstate1"
    container_name       = "tfstate"
    key                  = "stack/foundation.tfstate"
  }
}

# Option 2: Use local state (for development)
# This reads the foundation state from the local file
#data "terraform_remote_state" "foundation" {
#  backend = "local"
#  config = {
#    path = "${path.module}/../foundation/terraform.tfstate"
#  }
#}

# ============================================================================
# Common Locals
# ============================================================================

locals {
  # Path to workspace-specific resources
  workspaces_resources_path = "${path.module}/../../resources/databricks/workspaces"

  # ============================================================================
  # Foundation Lookup Maps (from remote state)
  # ============================================================================
  # These are used by modules that need to resolve keys to IDs
  # e.g., access_connector_key -> access_connector_id

  # Access Connectors Map: { key => { id, name, principal_id } }
  access_connectors_map = try(data.terraform_remote_state.foundation.outputs.access_connectors, {})

  # Workspaces Map: { key => { workspace_id, workspace_url, name } }
  # Note: This is used for workspace_keys resolution in workspace bindings
  workspaces_map = try(data.terraform_remote_state.foundation.outputs.workspaces, {})

  # Storage Accounts Map: { key => { id, name, primary_dfs_endpoint } }
  storage_accounts_map = try(data.terraform_remote_state.foundation.outputs.storage_accounts, {})
}
