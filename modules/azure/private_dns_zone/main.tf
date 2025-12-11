# ============================================================================
# Private DNS Zone Module
# ============================================================================
# Creates Azure Private DNS Zones with VNet links
# Supports multiple VNet links (e.g., hub VNet, workspace VNets)
# ============================================================================

resource "azurerm_private_dns_zone" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by = "terraform"
    }
  )
}

# VNet Links - supports both key references (resolved in locals) and direct IDs
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = try(var.config.enabled, true) ? {
    for link in try(var.config.vnet_links, []) : link.name => link
  } : {}

  name                  = each.value.name
  resource_group_name   = var.config.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = try(each.value.registration_enabled, false)

  tags = try(var.config.tags, {})
}
