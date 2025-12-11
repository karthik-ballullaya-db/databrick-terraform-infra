# ============================================================================
# NCC Private Endpoint Rule Module
# ============================================================================
# Creates Databricks NCC Private Endpoint Rule for serverless connectivity
# Resolves key references internally using lookup maps
# ============================================================================

locals {
  # Resolve network_connectivity_config_id from ncc_key if provided
  network_connectivity_config_id = try(var.config.ncc_key, null) != null ? (
    var.ncc_configs_map[var.config.ncc_key].network_connectivity_config_id
  ) : try(var.config.network_connectivity_config_id, null)

  # Resolve resource_id from storage_account_key if provided
  resource_id = try(var.config.storage_account_key, null) != null ? (
    var.storage_accounts_map[var.config.storage_account_key].id
  ) : try(var.config.resource_id, null)
}

resource "databricks_mws_ncc_private_endpoint_rule" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  network_connectivity_config_id = local.network_connectivity_config_id

  resource_id = local.resource_id
  group_id    = try(var.config.group_id, null)


  # Common parameters
  domain_names = try(var.config.domain_names, null)
  enabled      = try(var.config.enabled_rule, null)
}
