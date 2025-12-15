# ============================================================================
# Workspace: dev
# ============================================================================
# Self-contained workspace configuration with its own provider.
# Resources are loaded from: resources/workspaces/dev/
# ============================================================================

# ----------------------------------------------------------------------------
# Provider for this workspace
# ----------------------------------------------------------------------------
provider "databricks" {
  alias = "dev"
  host  = var.workspace_dev_host
}

# ----------------------------------------------------------------------------
# Locals - Parse JSON configs for this workspace
# ----------------------------------------------------------------------------
locals {
  # Workspace: dev - Resource parsing
  ws_dev_storage_credentials = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/storage_credentials", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/storage_credentials/${f}"))
  }
  ws_dev_enabled_storage_credentials = {
    for k, v in local.ws_dev_storage_credentials : k => v if try(v.enabled, true)
  }

  ws_dev_external_locations = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/external_locations", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/external_locations/${f}"))
  }
  ws_dev_enabled_external_locations = {
    for k, v in local.ws_dev_external_locations : k => v if try(v.enabled, true)
  }

  ws_dev_catalogs = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/catalogs", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/catalogs/${f}"))
  }
  ws_dev_enabled_catalogs = {
    for k, v in local.ws_dev_catalogs : k => v if try(v.enabled, true)
  }

  ws_dev_schemas = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/schemas", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/schemas/${f}"))
  }
  ws_dev_enabled_schemas = {
    for k, v in local.ws_dev_schemas : k => v if try(v.enabled, true)
  }

  ws_dev_cluster_policies = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/cluster_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/cluster_policies/${f}"))
  }
  ws_dev_enabled_cluster_policies = {
    for k, v in local.ws_dev_cluster_policies : k => v if try(v.enabled, true)
  }

  ws_dev_clusters = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/clusters", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/clusters/${f}"))
  }
  ws_dev_enabled_clusters = {
    for k, v in local.ws_dev_clusters : k => v if try(v.enabled, true)
  }

  ws_dev_sql_warehouses = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/sql_warehouses", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/sql_warehouses/${f}"))
  }
  ws_dev_enabled_sql_warehouses = {
    for k, v in local.ws_dev_sql_warehouses : k => v if try(v.enabled, true)
  }

  ws_dev_workspace_folders = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/workspace_folders", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/workspace_folders/${f}"))
  }
  ws_dev_enabled_workspace_folders = {
    for k, v in local.ws_dev_workspace_folders : k => v if try(v.enabled, true)
  }

  ws_dev_queries = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/queries", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/queries/${f}"))
  }
  ws_dev_enabled_queries = {
    for k, v in local.ws_dev_queries : k => v if try(v.enabled, true)
  }

  ws_dev_alerts = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/alerts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/alerts/${f}"))
  }
  ws_dev_enabled_alerts = {
    for k, v in local.ws_dev_alerts : k => v if try(v.enabled, true)
  }

  ws_dev_workspace_permissions = {
    for f in try(fileset("${local.workspaces_resources_path}/dev/workspace_permissions", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.workspaces_resources_path}/dev/workspace_permissions/${f}"))
  }
  ws_dev_enabled_workspace_permissions = {
    for k, v in local.ws_dev_workspace_permissions : k => v if try(v.enabled, true)
  }
}

# ----------------------------------------------------------------------------
# Modules - All use databricks.dev provider
# ----------------------------------------------------------------------------

module "ws_dev_storage_credentials" {
  source   = "../../modules/databricks/workspace/storage_credential"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_storage_credentials : {}

  config = each.value

  # Pass lookup maps from foundation state for key resolution
  access_connectors_map = local.access_connectors_map
  workspaces_map        = local.workspaces_map

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_external_locations" {
  source   = "../../modules/databricks/workspace/external_location"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_external_locations : {}

  config     = each.value
  depends_on = [module.ws_dev_storage_credentials]

  # Pass lookup maps from foundation state for key resolution
  workspaces_map = local.workspaces_map

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_catalogs" {
  source   = "../../modules/databricks/workspace/catalog"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_catalogs : {}

  config     = each.value
  depends_on = [module.ws_dev_external_locations]

  # Pass lookup maps from foundation state for key resolution
  workspaces_map = local.workspaces_map

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_schemas" {
  source   = "../../modules/databricks/workspace/schema"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_schemas : {}

  config     = each.value
  depends_on = [module.ws_dev_catalogs]

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_cluster_policies" {
  source   = "../../modules/databricks/workspace/cluster_policy"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_cluster_policies : {}

  config = each.value

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_clusters" {
  source   = "../../modules/databricks/workspace/cluster"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_clusters : {}

  config     = each.value
  depends_on = [module.ws_dev_cluster_policies]

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_sql_warehouses" {
  source   = "../../modules/databricks/workspace/sql_warehouse"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_sql_warehouses : {}

  config = each.value

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_workspace_folders" {
  source   = "../../modules/databricks/workspace/workspace_folder"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_workspace_folders : {}

  config = each.value

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_queries" {
  source   = "../../modules/databricks/workspace/query"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_queries : {}

  config     = each.value
  depends_on = [module.ws_dev_sql_warehouses]

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_alerts" {
  source   = "../../modules/databricks/workspace/alert"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_alerts : {}

  config     = each.value
  depends_on = [module.ws_dev_queries]

  providers = {
    databricks = databricks.dev
  }
}

module "ws_dev_workspace_permissions" {
  source   = "../../modules/databricks/workspace/workspace_permissions"
  for_each = var.workspace_dev_host != "" ? local.ws_dev_enabled_workspace_permissions : {}

  config = each.value

  providers = {
    databricks = databricks.dev
  }
}
