# ============================================================================
# VNet Module (Enhanced)
# ============================================================================
# Creates Azure Virtual Network with subnets, NSGs, and associations
# Supports Databricks VNet injection with proper delegations
# ============================================================================

resource "azurerm_virtual_network" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location
  address_space       = var.config.address_space

  # Optional DNS servers
  dns_servers = try(var.config.dns_servers, null)

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by = "terraform"
    }
  )
}

# ============================================================================
# Subnets
# ============================================================================
# Supports multiple subnet types:
# - Standard subnets
# - Databricks delegated subnets (public/private)
# - Private endpoint subnets
# ============================================================================

resource "azurerm_subnet" "this" {
  for_each = try(var.config.enabled, true) ? { for subnet in try(var.config.subnets, []) : subnet.name => subnet } : tomap({})

  name                 = each.value.name
  resource_group_name  = var.config.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = each.value.address_prefixes

  # Handle Databricks delegation shorthand or full delegation config
  dynamic "delegation" {
    for_each = try(each.value.delegation, null) == "Microsoft.Databricks/workspaces" ? [1] : []

    content {
      name = "databricks-delegation"

      service_delegation {
        name = "Microsoft.Databricks/workspaces"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
        ]
      }
    }
  }

  # Handle full delegation config (for other services)
  dynamic "delegation" {
    for_each = try(each.value.delegation, null) != "Microsoft.Databricks/workspaces" ? try(each.value.delegations, []) : []

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = try(delegation.value.service_delegation.actions, null)
      }
    }
  }

  service_endpoints                             = try(each.value.service_endpoints, null)
  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, null)
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, null)
}

# ============================================================================
# Network Security Groups
# ============================================================================

resource "azurerm_network_security_group" "this" {
  for_each = try(var.config.enabled, true) ? try(var.config.network_security_groups, {}) : {}

  name                = each.value.name
  location            = var.config.location
  resource_group_name = var.config.resource_group_name

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by = "terraform"
    }
  )

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])

    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = try(security_rule.value.source_port_range, null)
      source_port_ranges           = try(security_rule.value.source_port_ranges, null)
      destination_port_range       = try(security_rule.value.destination_port_range, null)
      destination_port_ranges      = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix        = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes      = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix   = try(security_rule.value.destination_address_prefix, null)
      destination_address_prefixes = try(security_rule.value.destination_address_prefixes, null)
    }
  }
}

# ============================================================================
# NSG Associations
# ============================================================================

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = try(var.config.enabled, true) ? try(var.config.nsg_associations, {}) : {}

  subnet_id                 = azurerm_subnet.this[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_name].id
}

