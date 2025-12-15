# ============================================================================
# Foundation Stack - Outputs
# ============================================================================
# These outputs are consumed by the workspaces stack via terraform_remote_state
# ============================================================================

# ============================================================================
# Workspace Outputs (Critical for workspaces stack)
# ============================================================================

output "workspaces" {
  description = "Map of workspace details (key => {workspace_id, workspace_url, name})"
  value = {
    for k, v in module.workspaces : k => {
      workspace_id  = v.workspace_id
      workspace_url = v.workspace_url
      name          = v.name
    }
  }
}

output "workspace_urls" {
  description = "Map of workspace keys to workspace URLs for provider configuration"
  value = {
    for k, v in module.workspaces : k => v.workspace_url
  }
}

output "workspace_ids" {
  description = "Map of workspace keys to workspace IDs"
  value = {
    for k, v in module.workspaces : k => v.workspace_id
  }
}

# ============================================================================
# Azure Resource Outputs
# ============================================================================

output "resource_groups" {
  description = "Map of resource group details"
  value = {
    for k, v in module.resource_groups : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "storage_accounts" {
  description = "Map of storage account details"
  value = {
    for k, v in module.storage_accounts : k => {
      id                  = v.id
      name                = v.name
      primary_dfs_endpoint = try(v.primary_dfs_endpoint, null)
    }
  }
}

output "access_connectors" {
  description = "Map of access connector details"
  value = {
    for k, v in module.access_connectors : k => {
      id           = v.id
      name         = v.name
      principal_id = try(v.principal_id, null)
    }
  }
}

output "vnets" {
  description = "Map of VNet details"
  value = {
    for k, v in module.vnets : k => {
      id   = v.id
      name = v.name
    }
  }
}

# ============================================================================
# Databricks Account Resource Outputs
# ============================================================================

output "metastores" {
  description = "Map of metastore details"
  value = {
    for k, v in module.metastores : k => {
      id   = v.id
      name = try(v.name, k)
    }
  }
}

output "ncc_configs" {
  description = "Map of NCC configuration details"
  value = {
    for k, v in module.ncc_configs : k => {
      id   = v.id
      name = try(v.name, k)
    }
  }
}

output "service_principals" {
  description = "Map of service principal details"
  value = {
    for k, v in module.service_principals : k => {
      id             = v.id
      application_id = try(v.application_id, null)
    }
  }
}

