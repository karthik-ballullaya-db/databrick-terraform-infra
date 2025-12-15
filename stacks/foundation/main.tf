# ============================================================================
# Foundation Stack - Azure Resources + Databricks Account Resources
# ============================================================================
# This stack manages:
# - Azure Foundation (Resource Groups, VNets, DNS Zones, etc.)
# - Azure Databricks Workspaces (infrastructure only)
# - Databricks Account-level resources (Metastores, NCCs, Service Principals)
#
# Run this stack FIRST before the workspaces stack.
# ============================================================================

# ============================================================================
# Phase 1: Azure Foundation Resources
# ============================================================================

# Resource Groups
module "resource_groups" {
  source   = "../../modules/azure/resource_group"
  for_each = local.enabled_resource_groups

  config = each.value
}

# Access Connectors (Required for Unity Catalog)
module "access_connectors" {
  source   = "../../modules/azure/access_connector"
  for_each = local.enabled_access_connectors

  config     = each.value
  depends_on = [module.resource_groups]
}

# ============================================================================
# Phase 2: Networking (VNets, Subnets, NSGs)
# ============================================================================

# VNets (Standalone - used by workspaces, storage accounts, etc.)
module "vnets" {
  source   = "../../modules/azure/vnet"
  for_each = local.enabled_vnets

  config     = each.value
  depends_on = [module.resource_groups]
}

# ============================================================================
# Phase 3: Private DNS Zones
# ============================================================================

# Private DNS Zones (for Private Link connectivity)
module "private_dns_zones" {
  source   = "../../modules/azure/private_dns_zone"
  for_each = local.enabled_private_dns_zones

  config     = each.value
  depends_on = [module.vnets]
}

# ============================================================================
# Phase 4: Databricks Workspaces (Azure Infrastructure)
# ============================================================================

# Databricks Workspaces (supports both public and VNet-injected)
module "workspaces" {
  source   = "../../modules/azure/databricks_workspace"
  for_each = local.enabled_workspaces

  config     = each.value
  depends_on = [module.resource_groups, module.vnets]
}

# ============================================================================
# Phase 5: Storage Accounts
# ============================================================================

# Storage Accounts (before private endpoints since PEs reference them)
module "storage_accounts" {
  source   = "../../modules/azure/storage_account"
  for_each = local.enabled_storage_accounts

  config = each.value

  # Pass lookup maps for key resolution
  access_connectors_map = module.access_connectors

  depends_on = [module.access_connectors, module.resource_groups, module.vnets]
}

# ============================================================================
# Phase 6: Private Endpoints (for Databricks, Storage, and other services)
# ============================================================================

# Private Endpoints - Primary (no PE dependencies)
module "private_endpoints" {
  source   = "../../modules/azure/private_endpoint"
  for_each = local.enabled_private_endpoints_primary

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map       = module.workspaces
  storage_accounts_map = module.storage_accounts

  depends_on = [
    module.vnets,
    module.private_dns_zones,
    module.workspaces,
    module.storage_accounts
  ]
}

# Private Endpoints - Dependent (must wait for primary PEs)
module "private_endpoints_dependent" {
  source   = "../../modules/azure/private_endpoint"
  for_each = local.enabled_private_endpoints_dependent

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map       = module.workspaces
  storage_accounts_map = module.storage_accounts

  depends_on = [
    module.private_endpoints
  ]
}

# ============================================================================
# Phase 7: Other Azure Resources
# ============================================================================

# Key Vaults
module "key_vaults" {
  source   = "../../modules/azure/key_vault"
  for_each = local.enabled_key_vaults

  config     = each.value
  depends_on = [module.resource_groups]
}

# Data Factories
module "data_factories" {
  source   = "../../modules/azure/data_factory"
  for_each = local.enabled_data_factories

  config     = each.value
  depends_on = [module.resource_groups, module.vnets]
}

# Virtual Machines
module "vms" {
  source   = "../../modules/azure/vm"
  for_each = local.enabled_vms

  config     = each.value
  depends_on = [module.resource_groups, module.vnets]
}

# ============================================================================
# Phase 8: Databricks Account-Level Resources
# ============================================================================

# Metastores (Unity Catalog)
module "metastores" {
  source   = "../../modules/databricks/account/metastore"
  for_each = local.enabled_metastores

  config = each.value
  depends_on = [
    module.storage_accounts,
    module.access_connectors
  ]

  providers = {
    databricks = databricks.account
  }
}

# Metastore Assignments
module "metastore_assignments" {
  source   = "../../modules/databricks/account/metastore_assignment"
  for_each = local.enabled_metastore_assignments

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map = module.workspaces
  metastores_map = module.metastores

  depends_on = [
    module.metastores,
    module.workspaces
  ]

  providers = {
    databricks = databricks.account
  }
}

# Network Connectivity Configs
module "ncc_configs" {
  source   = "../../modules/databricks/account/ncc"
  for_each = local.enabled_ncc_configs

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map = module.workspaces

  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.account
  }
}

# NCC Private Endpoints
module "ncc_private_endpoints" {
  source   = "../../modules/databricks/account/ncc_private_endpoint"
  for_each = local.enabled_ncc_private_endpoints

  config     = each.value
  depends_on = [module.ncc_configs, module.storage_accounts]

  providers = {
    databricks = databricks.account
  }
}

# Budget Policies
module "budget_policies" {
  source   = "../../modules/databricks/account/budget_policy"
  for_each = local.enabled_budget_policies

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map = module.workspaces

  providers = {
    databricks = databricks.account
  }
}

# Service Principals
module "service_principals" {
  source   = "../../modules/databricks/account/service_principal"
  for_each = local.enabled_service_principals

  config     = each.value
  depends_on = [module.workspaces]

  providers = {
    databricks = databricks.account
  }
}

# Workspace Admin Assignments
module "workspace_admin_assignments" {
  source   = "../../modules/databricks/account/workspace_admin_assignment"
  for_each = local.enabled_workspace_admin_assignments

  config = each.value

  # Pass lookup maps for key resolution
  workspaces_map = module.workspaces

  depends_on = [
    module.workspaces,
    module.service_principals
  ]

  providers = {
    databricks = databricks.account
  }
}
