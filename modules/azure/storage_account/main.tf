# ============================================================================
# Storage Account Module (Simplified)
# ============================================================================
# Creates Azure Storage Account with containers and RBAC
# Private endpoints and DNS zones are managed separately for better modularity
# ============================================================================

resource "azurerm_storage_account" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                            = var.config.name
  resource_group_name             = var.config.resource_group_name
  location                        = var.config.location
  account_tier                    = try(var.config.account_tier, "Standard")
  account_replication_type        = try(var.config.account_replication_type, "LRS")
  is_hns_enabled                  = try(var.config.is_hns_enabled, false)
  public_network_access_enabled   = try(var.config.public_network_access_enabled, false)
  allow_nested_items_to_be_public = try(var.config.allow_nested_items_to_be_public, false)
  min_tls_version                 = try(var.config.min_tls_version, "TLS1_2")
  shared_access_key_enabled       = try(var.config.shared_access_key_enabled, true)

  dynamic "network_rules" {
    for_each = try(var.config.network_rules, null) != null ? [var.config.network_rules] : []

    content {
      default_action             = network_rules.value.default_action
      bypass                     = try(network_rules.value.bypass, ["None"])
      ip_rules                   = try(network_rules.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_rules.value.virtual_network_subnet_ids, [])

      # Private link access for Access Connector (Unity Catalog)
      dynamic "private_link_access" {
        for_each = try(var.config.access_connector_id, null) != null ? [var.config.access_connector_id] : []

        content {
          endpoint_resource_id = private_link_access.value
        }
      }
    }
  }

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by = "terraform"
    }
  )
}

# ============================================================================
# Storage Containers
# ============================================================================

resource "azurerm_storage_container" "this" {
  for_each = try(var.config.enabled, true) ? { for container in try(var.config.containers, []) : container.name => container } : {}

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = try(each.value.container_access_type, "private")
}

# ============================================================================
# Role Assignments for Access Connector (Unity Catalog)
# ============================================================================

resource "azurerm_role_assignment" "blob_data_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.config.access_connector_principal_id
}

resource "azurerm_role_assignment" "queue_data_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = var.config.access_connector_principal_id
}

resource "azurerm_role_assignment" "eventgrid_contributor" {
  count = try(var.config.enabled, true) && try(var.config.access_connector_principal_id, null) != null ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = var.config.access_connector_principal_id
}
