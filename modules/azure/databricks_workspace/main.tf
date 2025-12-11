# ============================================================================
# Databricks Workspace Module (Simplified)
# ============================================================================
# Creates Azure Databricks Workspace
# Supports both public workspaces and VNet-injected workspaces
# VNet, DNS Zones, and Private Endpoints are managed separately
# ============================================================================

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
    for_each = try(var.config.network_type, "public") == "vnet_injected" ? [1] : []

    content {
      no_public_ip                                         = try(var.config.no_public_ip, true)
      virtual_network_id                                   = var.config.vnet_id
      public_subnet_name                                   = var.config.public_subnet_name
      private_subnet_name                                  = var.config.private_subnet_name
      public_subnet_network_security_group_association_id  = var.config.public_nsg_association_id
      private_subnet_network_security_group_association_id = var.config.private_nsg_association_id

      # Optional: storage account for DBFS
      storage_account_name     = try(var.config.storage_account_name, null)
      storage_account_sku_name = try(var.config.storage_account_sku_name, null)
    }
  }

  tags = merge(
    try(var.config.tags, {}),
    {
      managed_by   = "terraform"
      network_type = try(var.config.network_type, "public")
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to managed_resource_group_name after creation
      managed_resource_group_name
    ]
  }
}

