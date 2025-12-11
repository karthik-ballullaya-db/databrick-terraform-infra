# ============================================================================
# Databricks Workspace Module (Simplified)
# ============================================================================
# Creates Azure Databricks Workspace
# Supports both public workspaces and VNet-injected workspaces
# VNet, DNS Zones, and Private Endpoints are managed separately
# Resolves vnet_key references internally using vnets_map
# ============================================================================

locals {
  # Determine network type (default to public)
  network_type = try(var.config.network_type, "public")

  # Resolve VNet references from vnet_key if provided
  vnet_id = try(var.config.vnet_key, null) != null ? (
    var.vnets_map[var.config.vnet_key].id
  ) : try(var.config.vnet_id, null)

  # Resolve subnet IDs from vnet_key and subnet names
  public_subnet_id = try(var.config.vnet_key, null) != null && try(var.config.public_subnet_name, null) != null ? (
    var.vnets_map[var.config.vnet_key].subnet_ids[var.config.public_subnet_name]
  ) : try(var.config.public_subnet_id, null)

  private_subnet_id = try(var.config.vnet_key, null) != null && try(var.config.private_subnet_name, null) != null ? (
    var.vnets_map[var.config.vnet_key].subnet_ids[var.config.private_subnet_name]
  ) : try(var.config.private_subnet_id, null)

  # Resolve NSG association IDs for VNet injection
  public_nsg_association_id = try(var.config.vnet_key, null) != null && try(var.config.nsg_association_public, null) != null ? (
    var.vnets_map[var.config.vnet_key].nsg_association_ids[var.config.nsg_association_public]
  ) : try(var.config.public_nsg_association_id, null)

  private_nsg_association_id = try(var.config.vnet_key, null) != null && try(var.config.nsg_association_private, null) != null ? (
    var.vnets_map[var.config.vnet_key].nsg_association_ids[var.config.nsg_association_private]
  ) : try(var.config.private_nsg_association_id, null)
}

resource "azurerm_databricks_workspace" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                        = var.config.workspace_name
  resource_group_name         = var.config.resource_group_name
  location                    = var.config.location
  sku                         = try(var.config.sku, "premium")
  managed_resource_group_name = try(var.config.managed_resource_group_name, "${var.config.workspace_name}-managed-rg")

  public_network_access_enabled         = try(var.config.public_network_access_enabled, true)
  network_security_group_rules_required = try(var.config.network_security_group_rules_required, "AllRules")

  # Infrastructure encryption (optional)
  infrastructure_encryption_enabled = try(var.config.infrastructure_encryption_enabled, false)

  # Customer managed key (optional)
  customer_managed_key_enabled                        = try(var.config.customer_managed_key_enabled, false)
  managed_services_cmk_key_vault_key_id              = try(var.config.managed_services_cmk_key_vault_key_id, null)
  managed_disk_cmk_key_vault_key_id                  = try(var.config.managed_disk_cmk_key_vault_key_id, null)
  managed_disk_cmk_rotation_to_latest_version_enabled = try(var.config.managed_disk_cmk_rotation_to_latest_version_enabled, null)

  # VNet injection custom parameters - only for vnet_injected network_type
  dynamic "custom_parameters" {
    for_each = local.network_type == "vnet_injected" ? [1] : []

    content {
      no_public_ip                                         = try(var.config.no_public_ip, true)
      virtual_network_id                                   = local.vnet_id
      public_subnet_name                                   = var.config.public_subnet_name
      private_subnet_name                                  = var.config.private_subnet_name
      public_subnet_network_security_group_association_id  = local.public_nsg_association_id
      private_subnet_network_security_group_association_id = local.private_nsg_association_id

      # Optional: storage account for DBFS
      storage_account_name     = try(var.config.storage_account_name, null)
      storage_account_sku_name = try(var.config.storage_account_sku_name, null)
    }
  }

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by   = "terraform"
      network_type = local.network_type
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to managed_resource_group_name after creation
      managed_resource_group_name
    ]
  }
}
