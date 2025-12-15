# ============================================================================
# Workspaces Stack - Outputs
# ============================================================================
# Each workspace file can add its own outputs here or in the workspace file.
# ============================================================================

# Workspace: dev outputs
output "ws_dev_clusters" {
  description = "Clusters created in dev workspace"
  value = {
    for k, v in module.ws_dev_clusters : k => {
      id   = try(v.id, null)
      name = try(v.name, k)
    }
  }
}

output "ws_dev_catalogs" {
  description = "Catalogs created in dev workspace"
  value = {
    for k, v in module.ws_dev_catalogs : k => {
      id   = try(v.id, null)
      name = try(v.name, k)
    }
  }
}

output "ws_dev_sql_warehouses" {
  description = "SQL Warehouses created in dev workspace"
  value = {
    for k, v in module.ws_dev_sql_warehouses : k => {
      id   = try(v.id, null)
      name = try(v.name, k)
    }
  }
}

# Add outputs for additional workspaces as needed
