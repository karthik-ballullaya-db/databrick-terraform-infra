# ============================================================================
# Catalog Module
# ============================================================================
# Creates Unity Catalog Catalog
# Resolves workspace_keys references internally using workspaces_map
# ============================================================================

locals {
  # Check if workspace binding is configured (known at plan time)
  has_workspace_binding = (
    try(var.config.workspace_keys, null) != null ||
    try(var.config.workspace_ids, null) != null
  )

  # Get the list of keys to use for for_each (known at plan time)
  workspace_binding_keys = try(var.config.workspace_keys, null) != null ? (
    var.config.workspace_keys
  ) : try(var.config.workspace_ids, null) != null ? (
    [for id in var.config.workspace_ids : tostring(id)]
  ) : []

  # Resolve workspace_ids from workspace_keys (for actual resource values)
  workspace_ids_map = try(var.config.workspace_keys, null) != null ? {
    for ws_key in var.config.workspace_keys :
    ws_key => var.workspaces_map[ws_key].workspace_id
  } : try(var.config.workspace_ids, null) != null ? {
    for ws_id in var.config.workspace_ids :
    tostring(ws_id) => ws_id
  } : {}
}

resource "databricks_catalog" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name           = var.config.name
  storage_root   = try(var.config.storage_root, null)
  comment        = try(var.config.comment, null)
  properties     = try(var.config.properties, null)
  provider_name  = try(var.config.provider_name, null)
  share_name     = try(var.config.share_name, null)
  isolation_mode = try(var.config.isolation_mode, "OPEN")
  owner          = try(var.config.owner, null)
  force_destroy  = try(var.config.force_destroy, false)
}

# Workspace Bindings - Bind catalog to specific workspace(s)
# Note: for_each uses workspace_binding_keys (known at plan time)
resource "databricks_workspace_binding" "this" {
  for_each = try(var.config.enabled, true) && local.has_workspace_binding ? toset(local.workspace_binding_keys) : toset([])

  securable_name = databricks_catalog.this[0].name
  securable_type = "catalog"
  workspace_id   = local.workspace_ids_map[each.key]
  binding_type   = try(var.config.binding_type, "BINDING_TYPE_READ_WRITE")

  depends_on = [databricks_catalog.this]
}

# Grants - Assign permissions to principals
resource "databricks_grants" "this" {
  count = try(var.config.enabled, true) && try(var.config.permissions, null) != null ? 1 : 0

  catalog = databricks_catalog.this[0].name

  dynamic "grant" {
    for_each = try(var.config.permissions, [])
    content {
      principal = try(
        grant.value.principal,
        try(grant.value.service_principal_name, try(grant.value.group_name, try(grant.value.user_name, null)))
      )
      privileges = try(
        grant.value.privileges,
        try([grant.value.permission_level], null)
      )
    }
  }

  depends_on = [databricks_catalog.this, databricks_workspace_binding.this]
}
