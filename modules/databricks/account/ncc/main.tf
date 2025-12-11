# ============================================================================
# Network Connectivity Config (NCC) Module
# ============================================================================
# Creates Databricks Network Connectivity Config for serverless compute
# Resolves workspace_keys references internally using workspaces_map
# ============================================================================

locals {
  # Check if workspace binding is configured (known at plan time)
  # Use the keys from config, not the resolved values
  has_workspace_binding = (
    try(var.config.workspace_keys, null) != null ||
    try(var.config.workspace_ids, null) != null
  )

  # Get the list of keys to use for for_each (known at plan time)
  # For workspace_keys: use the keys themselves as for_each keys
  # For workspace_ids: use the IDs directly as for_each keys
  workspace_binding_keys = try(var.config.workspace_keys, null) != null ? (
    var.config.workspace_keys
  ) : try(var.config.workspace_ids, null) != null ? (
    [for id in var.config.workspace_ids : tostring(id)]
  ) : []

  # Resolve workspace_ids from workspace_keys if provided (for actual resource values)
  workspace_ids_map = try(var.config.workspace_keys, null) != null ? {
    for ws_key in var.config.workspace_keys :
    ws_key => var.workspaces_map[ws_key].workspace_id
  } : try(var.config.workspace_ids, null) != null ? {
    for ws_id in var.config.workspace_ids :
    tostring(ws_id) => ws_id
  } : {}
}

resource "databricks_mws_network_connectivity_config" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name   = var.config.name
  region = var.config.region

  network_connectivity_config_id = try(var.config.network_connectivity_config_id, null)
}

# NCC Binding - Attach NCC to workspace(s)
# Note: for_each uses workspace_binding_keys (known at plan time)
# The actual workspace_id is resolved from workspace_ids_map
resource "databricks_mws_ncc_binding" "this" {
  for_each = try(var.config.enabled, true) && local.has_workspace_binding ? toset(local.workspace_binding_keys) : toset([])

  network_connectivity_config_id = databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id
  workspace_id                   = local.workspace_ids_map[each.key]

  depends_on = [databricks_mws_network_connectivity_config.this]
}
