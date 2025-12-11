provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = var.databricks_account_host
  account_id = var.databricks_account_id
}

# Workspace provider - dynamically resolves from module output
# Uses the first enabled workspace as the primary workspace provider
# For multi-workspace scenarios, add additional aliased providers as needed
provider "databricks" {
  alias = "workspace"
  host = try(
    module.workspaces[local.primary_workspace_key].workspace_url,
    var.databricks_workspace_host != "" ? var.databricks_workspace_host : null
  )
}
