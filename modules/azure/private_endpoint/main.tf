# ============================================================================
# Private Endpoint Module
# ============================================================================
# Creates Azure Private Endpoints for various Azure services
# Supports: Databricks, Storage, Key Vault, SQL, etc.
# Resolves key references internally using lookup maps
# ============================================================================

locals {
  # Resolve subnet_id from vnet_key and subnet_name if provided
  subnet_id = try(var.config.vnet_key, null) != null && try(var.config.subnet_name, null) != null ? (
    var.vnets_map[var.config.vnet_key].subnet_ids[var.config.subnet_name]
  ) : try(var.config.subnet_id, null)

  # Resolve private_connection_resource_id based on resource type
  private_connection_resource_id = coalesce(
    # Workspace reference
    try(var.config.workspace_key, null) != null ? var.workspaces_map[var.config.workspace_key].id : null,
    # Storage account reference
    try(var.config.storage_account_key, null) != null ? var.storage_accounts_map[var.config.storage_account_key].id : null,
    # Direct ID
    try(var.config.private_connection_resource_id, null)
  )

  # Resolve DNS zone IDs from dns_zone_key if provided
  private_dns_zone_ids = try(var.config.dns_zone_key, null) != null ? [
    var.private_dns_zones_map[var.config.dns_zone_key].id
  ] : try(var.config.private_dns_zone_ids, null)
}

resource "azurerm_private_endpoint" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  subnet_id           = local.subnet_id

  private_service_connection {
    name                           = try(var.config.private_service_connection_name, "${var.config.name}-psc")
    private_connection_resource_id = local.private_connection_resource_id
    subresource_names              = var.config.subresource_names
    is_manual_connection           = try(var.config.is_manual_connection, false)
  }

  # Optional: DNS Zone Group for automatic DNS registration
  dynamic "private_dns_zone_group" {
    for_each = local.private_dns_zone_ids != null ? [1] : []

    content {
      name                 = try(var.config.dns_zone_group_name, "default")
      private_dns_zone_ids = local.private_dns_zone_ids
    }
  }

  # Optional: IP Configuration for static IP assignment
  dynamic "ip_configuration" {
    for_each = try(var.config.ip_configurations, [])

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = try(ip_configuration.value.subresource_name, null)
      member_name        = try(ip_configuration.value.member_name, null)
    }
  }

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by = "terraform"
    }
  )
}
