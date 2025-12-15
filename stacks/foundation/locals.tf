# ============================================================================
# Foundation Stack - Locals
# ============================================================================
# Parses JSON resource configurations from the shared resources/ directory
# ============================================================================

locals {
  # Path to shared resources directory
  resources_path = "${path.module}/../../resources"

  # ============================================================================
  # Azure Foundation Resources
  # ============================================================================

  # Resource Groups
  resource_groups = {
    for f in try(fileset("${local.resources_path}/azure/resource_groups", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/resource_groups/${f}"))
  }
  all_resource_groups = merge(local.resource_groups, var.resource_groups)
  enabled_resource_groups = {
    for k, v in local.all_resource_groups :
    k => v if try(v.enabled, true)
  }

  # Access Connectors
  access_connectors = {
    for f in try(fileset("${local.resources_path}/azure/access_connectors", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/access_connectors/${f}"))
  }
  all_access_connectors = merge(local.access_connectors, var.access_connectors)
  enabled_access_connectors = {
    for k, v in local.all_access_connectors :
    k => v if try(v.enabled, true)
  }

  # VNets
  vnets = {
    for f in try(fileset("${local.resources_path}/azure/vnets", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/vnets/${f}"))
  }
  all_vnets = merge(local.vnets, var.vnets)
  enabled_vnets = {
    for k, v in local.all_vnets :
    k => v if try(v.enabled, true)
  }

  # Private DNS Zones
  private_dns_zones = {
    for f in try(fileset("${local.resources_path}/azure/private_dns_zones", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/private_dns_zones/${f}"))
  }
  all_private_dns_zones = merge(local.private_dns_zones, var.private_dns_zones)
  enabled_private_dns_zones = {
    for k, v in local.all_private_dns_zones :
    k => v if try(v.enabled, true)
  }

  # Workspaces (Azure infrastructure only - workspace resources are in workspaces stack)
  workspaces = {
    for f in try(fileset("${local.resources_path}/azure/workspaces", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/workspaces/${f}"))
  }
  all_workspaces = merge(local.workspaces, var.workspaces)
  enabled_workspaces = {
    for k, v in local.all_workspaces :
    k => v if try(v.enabled, true)
  }

  # Private Endpoints
  private_endpoints = {
    for f in try(fileset("${local.resources_path}/azure/private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/private_endpoints/${f}"))
  }
  all_private_endpoints = merge(local.private_endpoints, var.private_endpoints)
  enabled_private_endpoints = {
    for k, v in local.all_private_endpoints :
    k => v if try(v.enabled, true)
  }
  enabled_private_endpoints_primary = {
    for k, v in local.enabled_private_endpoints :
    k => v if try(v.depends_on_pe_key, null) == null
  }
  enabled_private_endpoints_dependent = {
    for k, v in local.enabled_private_endpoints :
    k => v if try(v.depends_on_pe_key, null) != null
  }

  # Storage Accounts
  storage_accounts = {
    for f in try(fileset("${local.resources_path}/azure/storage_accounts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/storage_accounts/${f}"))
  }
  all_storage_accounts = merge(local.storage_accounts, var.storage_accounts)
  enabled_storage_accounts = {
    for k, v in local.all_storage_accounts :
    k => v if try(v.enabled, true)
  }

  # Key Vaults
  key_vaults = {
    for f in try(fileset("${local.resources_path}/azure/key_vaults", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/key_vaults/${f}"))
  }
  all_key_vaults = merge(local.key_vaults, var.key_vaults)
  enabled_key_vaults = {
    for k, v in local.all_key_vaults :
    k => v if try(v.enabled, true)
  }

  # Data Factories
  data_factories = {
    for f in try(fileset("${local.resources_path}/azure/data_factories", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/data_factories/${f}"))
  }
  all_data_factories = merge(local.data_factories, var.data_factories)
  enabled_data_factories = {
    for k, v in local.all_data_factories :
    k => v if try(v.enabled, true)
  }

  # VMs
  vms = {
    for f in try(fileset("${local.resources_path}/azure/vms", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/azure/vms/${f}"))
  }
  all_vms = merge(local.vms, var.vms)
  enabled_vms = {
    for k, v in local.all_vms :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Databricks Account Resources
  # ============================================================================

  # Metastores
  metastores = {
    for f in try(fileset("${local.resources_path}/databricks/account/metastores", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/metastores/${f}"))
  }
  all_metastores = merge(local.metastores, var.metastores)
  enabled_metastores = {
    for k, v in local.all_metastores :
    k => v if try(v.enabled, true)
  }

  # Metastore Assignments
  metastore_assignments = {
    for f in try(fileset("${local.resources_path}/databricks/account/metastore_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/metastore_assignments/${f}"))
  }
  all_metastore_assignments = merge(local.metastore_assignments, var.metastore_assignments)
  enabled_metastore_assignments = {
    for k, v in local.all_metastore_assignments :
    k => v if try(v.enabled, true)
  }

  # Budget Policies
  budget_policies = {
    for f in try(fileset("${local.resources_path}/databricks/account/budget_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/budget_policies/${f}"))
  }
  all_budget_policies = merge(local.budget_policies, var.budget_policies)
  enabled_budget_policies = {
    for k, v in local.all_budget_policies :
    k => v if try(v.enabled, true)
  }

  # NCC Configs
  ncc_configs = {
    for f in try(fileset("${local.resources_path}/databricks/account/ncc", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/ncc/${f}"))
  }
  all_ncc_configs = merge(local.ncc_configs, var.ncc_configs)
  enabled_ncc_configs = {
    for k, v in local.all_ncc_configs :
    k => v if try(v.enabled, true)
  }

  # NCC Private Endpoints
  ncc_private_endpoints = {
    for f in try(fileset("${local.resources_path}/databricks/account/ncc_private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/ncc_private_endpoints/${f}"))
  }
  all_ncc_private_endpoints = merge(local.ncc_private_endpoints, var.ncc_private_endpoints)
  enabled_ncc_private_endpoints = {
    for k, v in local.all_ncc_private_endpoints :
    k => v if try(v.enabled, true)
  }

  # Service Principals
  service_principals = {
    for f in try(fileset("${local.resources_path}/databricks/account/service_principals", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/service_principals/${f}"))
  }
  all_service_principals = merge(local.service_principals, var.service_principals)
  enabled_service_principals = {
    for k, v in local.all_service_principals :
    k => v if try(v.enabled, true)
  }

  # Workspace Admin Assignments
  workspace_admin_assignments = {
    for f in try(fileset("${local.resources_path}/databricks/account/workspace_admin_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${local.resources_path}/databricks/account/workspace_admin_assignments/${f}"))
  }
  all_workspace_admin_assignments = merge(local.workspace_admin_assignments, var.workspace_admin_assignments)
  enabled_workspace_admin_assignments = {
    for k, v in local.all_workspace_admin_assignments :
    k => v if try(v.enabled, true)
  }
}

