# ============================================================================
# Storage Credential Module
# ============================================================================
# Creates Unity Catalog Storage Credential
# Resolves key references internally using lookup maps
# ============================================================================

locals {
  # Check if access connector is configured (known at plan time)
  has_access_connector = try(var.config.azure_managed_identity.access_connector_key, null) != null

  # Resolve access_connector_id in azure_managed_identity from access_connector_key if provided
  azure_managed_identity = try(var.config.azure_managed_identity, null) != null ? merge(var.config.azure_managed_identity, {
    access_connector_id = try(var.config.azure_managed_identity.access_connector_key, null) != null ? (
      var.access_connectors_map[var.config.azure_managed_identity.access_connector_key].id
    ) : try(var.config.azure_managed_identity.access_connector_id, null)
  }) : null

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

resource "databricks_storage_credential" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name            = var.config.name
  metastore_id    = try(var.config.metastore_id, null)
  owner           = try(var.config.owner, null)
  comment         = try(var.config.comment, null)
  read_only       = try(var.config.read_only, false)
  force_destroy   = try(var.config.force_destroy, false)
  force_update    = try(var.config.force_update, false)
  skip_validation = try(var.config.skip_validation, false)

  dynamic "azure_managed_identity" {
    for_each = local.azure_managed_identity != null ? [local.azure_managed_identity] : []

    content {
      access_connector_id = azure_managed_identity.value.access_connector_id
    }
  }

  dynamic "azure_service_principal" {
    for_each = try(var.config.azure_service_principal, null) != null ? [var.config.azure_service_principal] : []

    content {
      directory_id   = azure_service_principal.value.directory_id
      application_id = azure_service_principal.value.application_id
      client_secret  = azure_service_principal.value.client_secret
    }
  }

  dynamic "databricks_gcp_service_account" {
    for_each = try(var.config.databricks_gcp_service_account, null) != null ? [var.config.databricks_gcp_service_account] : []

    content {
      email = try(databricks_gcp_service_account.value.email, null)
    }
  }

  dynamic "aws_iam_role" {
    for_each = try(var.config.aws_iam_role, null) != null ? [var.config.aws_iam_role] : []

    content {
      role_arn = aws_iam_role.value.role_arn
    }
  }

  isolation_mode = try(var.config.isolation_mode, null)
}

# Workspace Bindings - Bind storage credential to specific workspace(s)
# Note: for_each uses workspace_binding_keys (known at plan time)
resource "databricks_workspace_binding" "this" {
  for_each = try(var.config.enabled, true) && local.has_workspace_binding ? toset(local.workspace_binding_keys) : toset([])

  securable_name = databricks_storage_credential.this[0].name
  securable_type = "storage_credential"
  workspace_id   = local.workspace_ids_map[each.key]
  binding_type   = try(var.config.binding_type, "BINDING_TYPE_READ_WRITE")

  depends_on = [databricks_storage_credential.this]
}

# Grants - Assign permissions to principals
resource "databricks_grants" "this" {
  count = try(var.config.enabled, true) && try(var.config.permissions, null) != null ? 1 : 0

  storage_credential = databricks_storage_credential.this[0].id

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

  depends_on = [databricks_storage_credential.this, databricks_workspace_binding.this]
}
