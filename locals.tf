locals {
  # ============================================================================
  # Primary Workspace Key (for provider configuration)
  # ============================================================================
  # The first enabled workspace is used as the primary workspace for the
  # databricks.workspace provider. For multi-workspace scenarios, add
  # additional providers with explicit aliases.

  primary_workspace_key = try(keys(local.enabled_workspaces)[0], null)

  # ============================================================================
  # Phase 1: Azure Foundation Resources (No Dependencies)
  # ============================================================================

  # Resource Groups - Raw JSON parsing only
  resource_groups = {
    for f in try(fileset("${path.module}/resources/azure/resource_groups", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/resource_groups/${f}"))
  }
  all_resource_groups = merge(local.resource_groups, var.resource_groups)
  enabled_resource_groups = {
    for k, v in local.all_resource_groups :
    k => v if try(v.enabled, true)
  }

  # Access Connectors - Raw JSON parsing only
  access_connectors = {
    for f in try(fileset("${path.module}/resources/azure/access_connectors", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/access_connectors/${f}"))
  }
  all_access_connectors = merge(local.access_connectors, var.access_connectors)
  enabled_access_connectors = {
    for k, v in local.all_access_connectors :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 2: VNets (Depends on Resource Groups)
  # ============================================================================

  # VNets - Raw JSON parsing only (NO module references)
  vnets = {
    for f in try(fileset("${path.module}/resources/azure/vnets", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/vnets/${f}"))
  }
  all_vnets = merge(local.vnets, var.vnets)
  enabled_vnets = {
    for k, v in local.all_vnets :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 3: Private DNS Zones (Depends on VNets)
  # ============================================================================

  # Private DNS Zones - Raw JSON parsing only (NO module references)
  # vnet_key resolution happens inside the module
  private_dns_zones = {
    for f in try(fileset("${path.module}/resources/azure/private_dns_zones", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/private_dns_zones/${f}"))
  }
  all_private_dns_zones = merge(local.private_dns_zones, var.private_dns_zones)
  enabled_private_dns_zones = {
    for k, v in local.all_private_dns_zones :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 4: Databricks Workspaces (Depends on VNets)
  # ============================================================================

  # Workspaces - Raw JSON parsing only (NO module references)
  # vnet_key resolution happens inside the module
  workspaces = {
    for f in try(fileset("${path.module}/resources/azure/workspaces", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/workspaces/${f}"))
  }
  all_workspaces = merge(local.workspaces, var.workspaces)
  enabled_workspaces = {
    for k, v in local.all_workspaces :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 5: Private Endpoints (Depends on VNets, Workspaces, DNS Zones)
  # ============================================================================

  # Private Endpoints - Raw JSON parsing only (NO module references)
  # All key resolution happens inside the module
  private_endpoints = {
    for f in try(fileset("${path.module}/resources/azure/private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/private_endpoints/${f}"))
  }
  all_private_endpoints = merge(local.private_endpoints, var.private_endpoints)
  enabled_private_endpoints = {
    for k, v in local.all_private_endpoints :
    k => v if try(v.enabled, true)
  }

  # Split private endpoints into primary (no dependencies) and dependent groups
  # This prevents Azure ConcurrentUpdateError when multiple PEs target the same resource
  enabled_private_endpoints_primary = {
    for k, v in local.enabled_private_endpoints :
    k => v if try(v.depends_on_pe_key, null) == null
  }
  enabled_private_endpoints_dependent = {
    for k, v in local.enabled_private_endpoints :
    k => v if try(v.depends_on_pe_key, null) != null
  }

  # ============================================================================
  # Phase 6: Storage Accounts (Depends on Access Connectors, VNets)
  # ============================================================================

  # Storage Accounts - Raw JSON parsing only (NO module references)
  # access_connector_key and vnet_key resolution happens inside the module
  storage_accounts = {
    for f in try(fileset("${path.module}/resources/azure/storage_accounts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/storage_accounts/${f}"))
  }
  all_storage_accounts = merge(local.storage_accounts, var.storage_accounts)
  enabled_storage_accounts = {
    for k, v in local.all_storage_accounts :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Key Vaults
  # ============================================================================

  key_vaults = {
    for f in try(fileset("${path.module}/resources/azure/key_vaults", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/key_vaults/${f}"))
  }
  all_key_vaults = merge(local.key_vaults, var.key_vaults)
  enabled_key_vaults = {
    for k, v in local.all_key_vaults :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Data Factories
  # ============================================================================

  data_factories = {
    for f in try(fileset("${path.module}/resources/azure/data_factories", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/data_factories/${f}"))
  }
  all_data_factories = merge(local.data_factories, var.data_factories)
  enabled_data_factories = {
    for k, v in local.all_data_factories :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Virtual Machines
  # ============================================================================

  vms = {
    for f in try(fileset("${path.module}/resources/azure/vms", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/vms/${f}"))
  }
  all_vms = merge(local.vms, var.vms)
  enabled_vms = {
    for k, v in local.all_vms :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Databricks Account Resources
  # ============================================================================

  # Metastores - Raw JSON parsing only
  metastores = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastores", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastores/${f}"))
  }
  all_metastores = merge(local.metastores, var.metastores)
  enabled_metastores = {
    for k, v in local.all_metastores :
    k => v if try(v.enabled, true)
  }

  # Metastore Assignments - Raw JSON parsing only (NO module references)
  # workspace_key and metastore_key resolution happens inside the module
  metastore_assignments = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastore_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastore_assignments/${f}"))
  }
  all_metastore_assignments = merge(local.metastore_assignments, var.metastore_assignments)
  enabled_metastore_assignments = {
    for k, v in local.all_metastore_assignments :
    k => v if try(v.enabled, true)
  }

  # Budget Policies - Raw JSON parsing only (NO module references)
  # workspace_keys resolution happens inside the module
  budget_policies = {
    for f in try(fileset("${path.module}/resources/databricks/account/budget_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/budget_policies/${f}"))
  }
  all_budget_policies = merge(local.budget_policies, var.budget_policies)
  enabled_budget_policies = {
    for k, v in local.all_budget_policies :
    k => v if try(v.enabled, true)
  }

  # NCC (Network Connectivity Configs) - Raw JSON parsing only (NO module references)
  # workspace_keys resolution happens inside the module
  ncc_configs = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc/${f}"))
  }
  all_ncc_configs = merge(local.ncc_configs, var.ncc_configs)
  enabled_ncc_configs = {
    for k, v in local.all_ncc_configs :
    k => v if try(v.enabled, true)
  }

  # NCC Private Endpoints - Raw JSON parsing only (NO module references)
  # ncc_key and storage_account_key resolution happens inside the module
  ncc_private_endpoints = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc_private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc_private_endpoints/${f}"))
  }
  all_ncc_private_endpoints = merge(local.ncc_private_endpoints, var.ncc_private_endpoints)
  enabled_ncc_private_endpoints = {
    for k, v in local.all_ncc_private_endpoints :
    k => v if try(v.enabled, true)
  }

  # Service Principals - Raw JSON parsing only
  service_principals = {
    for f in try(fileset("${path.module}/resources/databricks/account/service_principals", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/service_principals/${f}"))
  }
  all_service_principals = merge(local.service_principals, var.service_principals)
  enabled_service_principals = {
    for k, v in local.all_service_principals :
    k => v if try(v.enabled, true)
  }

  # Workspace Admin Assignments - Raw JSON parsing only (NO module references)
  # workspace_key resolution happens inside the module
  workspace_admin_assignments = {
    for f in try(fileset("${path.module}/resources/databricks/account/workspace_admin_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/workspace_admin_assignments/${f}"))
  }
  all_workspace_admin_assignments = merge(local.workspace_admin_assignments, var.workspace_admin_assignments)
  enabled_workspace_admin_assignments = {
    for k, v in local.all_workspace_admin_assignments :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Databricks Workspace Resources
  # ============================================================================

  # Storage Credentials - Raw JSON parsing only (NO module references)
  # access_connector_key and workspace_keys resolution happens inside the module
  storage_credentials = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/storage_credentials", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/storage_credentials/${f}"))
  }
  all_storage_credentials = merge(local.storage_credentials, var.storage_credentials)
  enabled_storage_credentials = {
    for k, v in local.all_storage_credentials :
    k => v if try(v.enabled, true)
  }

  # External Locations - Raw JSON parsing only (NO module references)
  # workspace_keys resolution happens inside the module
  external_locations = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/external_locations", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/external_locations/${f}"))
  }
  all_external_locations = merge(local.external_locations, var.external_locations)
  enabled_external_locations = {
    for k, v in local.all_external_locations :
    k => v if try(v.enabled, true)
  }

  # Catalogs - Raw JSON parsing only (NO module references)
  # workspace_keys resolution happens inside the module
  catalogs = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/catalogs", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/catalogs/${f}"))
  }
  all_catalogs = merge(local.catalogs, var.catalogs)
  enabled_catalogs = {
    for k, v in local.all_catalogs :
    k => v if try(v.enabled, true)
  }

  # Schemas - Raw JSON parsing only
  schemas = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/schemas", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/schemas/${f}"))
  }
  all_schemas = merge(local.schemas, var.schemas)
  enabled_schemas = {
    for k, v in local.all_schemas :
    k => v if try(v.enabled, true)
  }

  # Clusters - Raw JSON parsing only
  clusters = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/clusters", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/clusters/${f}"))
  }
  all_clusters = merge(local.clusters, var.clusters)
  enabled_clusters = {
    for k, v in local.all_clusters :
    k => v if try(v.enabled, true)
  }

  # Cluster Policies - Raw JSON parsing only
  cluster_policies = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/cluster_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/cluster_policies/${f}"))
  }
  all_cluster_policies = merge(local.cluster_policies, var.cluster_policies)
  enabled_cluster_policies = {
    for k, v in local.all_cluster_policies :
    k => v if try(v.enabled, true)
  }

  # SQL Warehouses - Raw JSON parsing only
  sql_warehouses = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/sql_warehouses", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/sql_warehouses/${f}"))
  }
  all_sql_warehouses = merge(local.sql_warehouses, var.sql_warehouses)
  enabled_sql_warehouses = {
    for k, v in local.all_sql_warehouses :
    k => v if try(v.enabled, true)
  }

  # Workspace Folders - Raw JSON parsing only
  workspace_folders = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/workspace_folders", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/workspace_folders/${f}"))
  }
  all_workspace_folders = merge(local.workspace_folders, var.workspace_folders)
  enabled_workspace_folders = {
    for k, v in local.all_workspace_folders :
    k => v if try(v.enabled, true)
  }

  # Queries - Raw JSON parsing only
  queries = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/queries", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/queries/${f}"))
  }
  all_queries = merge(local.queries, var.queries)
  enabled_queries = {
    for k, v in local.all_queries :
    k => v if try(v.enabled, true)
  }

  # Alerts - Raw JSON parsing only
  alerts = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/alerts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/alerts/${f}"))
  }
  all_alerts = merge(local.alerts, var.alerts)
  enabled_alerts = {
    for k, v in local.all_alerts :
    k => v if try(v.enabled, true)
  }

  # Workspace Permissions - Raw JSON parsing only
  workspace_permissions = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/workspace_permissions", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/workspace_permissions/${f}"))
  }
  all_workspace_permissions = merge(local.workspace_permissions, var.workspace_permissions)
  enabled_workspace_permissions = {
    for k, v in local.all_workspace_permissions :
    k => v if try(v.enabled, true)
  }
}
