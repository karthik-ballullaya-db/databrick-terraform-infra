# ============================================================================
# Metastore Assignment Module
# ============================================================================
# Assigns Unity Catalog metastore to Databricks workspace
# Resolves key references internally using lookup maps
# ============================================================================

locals {
  # Resolve workspace_id from workspace_key if provided
  workspace_id = try(var.config.workspace_key, null) != null ? (
    var.workspaces_map[var.config.workspace_key].workspace_id
  ) : try(var.config.workspace_id, null)

  # Resolve metastore_id from metastore_key if provided
  metastore_id = try(var.config.metastore_key, null) != null ? (
    var.metastores_map[var.config.metastore_key].metastore_id
  ) : try(var.config.metastore_id, null)
}

resource "databricks_metastore_assignment" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  metastore_id = local.metastore_id
  workspace_id = local.workspace_id
}

# Set default catalog using the new recommended resource
resource "databricks_default_namespace_setting" "this" {
  count = try(var.config.enabled, true) && try(var.config.default_catalog_name, null) != null ? 1 : 0

  namespace {
    value = try(var.config.default_catalog_name, "main")
  }

  depends_on = [databricks_metastore_assignment.this]
}
