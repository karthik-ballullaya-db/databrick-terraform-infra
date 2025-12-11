# ============================================================================
# Private Endpoint Module
# ============================================================================
# Creates Azure Private Endpoints for various Azure services
# Supports: Databricks, Storage, Key Vault, SQL, etc.
# ============================================================================

resource "azurerm_private_endpoint" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name
  subnet_id           = var.config.subnet_id

  private_service_connection {
    name                           = try(var.config.private_service_connection_name, "${var.config.name}-psc")
    private_connection_resource_id = var.config.private_connection_resource_id
    subresource_names              = var.config.subresource_names
    is_manual_connection           = try(var.config.is_manual_connection, false)
  }

  # Optional: DNS Zone Group for automatic DNS registration
  dynamic "private_dns_zone_group" {
    for_each = try(var.config.private_dns_zone_ids, null) != null ? [1] : []

    content {
      name                 = try(var.config.dns_zone_group_name, "default")
      private_dns_zone_ids = var.config.private_dns_zone_ids
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

