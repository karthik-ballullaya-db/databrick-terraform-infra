# ============================================================================
# Private DNS Zone Module
# ============================================================================
# Creates Azure Private DNS Zones with VNet links
# Supports multiple VNet links (e.g., hub VNet, workspace VNets)
# Resolves vnet_key references internally using vnets_map
# ============================================================================

locals {
  # Resolve vnet_links - convert vnet_key to vnet_id using vnets_map
  vnet_links = [
    for link in try(var.config.vnet_links, []) : {
      name                 = link.name
      registration_enabled = try(link.registration_enabled, false)
      # Resolve vnet_id from vnet_key if provided, otherwise use direct vnet_id
      vnet_id = try(link.vnet_key, null) != null ? (
        var.vnets_map[link.vnet_key].id
      ) : link.vnet_id
    }
  ]
}

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

# VNet Links - uses resolved vnet_links from locals
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = try(var.config.enabled, true) ? {
    for link in local.vnet_links : link.name => link
  } : {}

  name                  = each.value.name
  resource_group_name   = var.config.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = each.value.registration_enabled

  tags = try(var.config.tags, {})
}
