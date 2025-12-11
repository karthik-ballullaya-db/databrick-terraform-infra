locals {
  # ============================================================================
  # Phase 1: Azure Foundation Resources (No Dependencies)
  # ============================================================================

  # Resource Groups
  resource_groups = {
    for f in try(fileset("${path.module}/resources/azure/resource_groups", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/resource_groups/${f}"))
  }
  all_resource_groups = merge(local.resource_groups, var.resource_groups)
  enabled_resource_groups = {
    for k, v in local.all_resource_groups :
    k => v if try(v.enabled, true)
  }

  # Access Connectors
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

  vnets_raw = {
    for f in try(fileset("${path.module}/resources/azure/vnets", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/vnets/${f}"))
  }
  all_vnets = merge(local.vnets_raw, var.vnets)
  enabled_vnets = {
    for k, v in local.all_vnets :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 3: Private DNS Zones (Depends on VNets)
  # ============================================================================

  private_dns_zones_raw = {
    for f in try(fileset("${path.module}/resources/azure/private_dns_zones", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/private_dns_zones/${f}"))
  }

  # Resolve VNet key references in DNS zone configurations
  private_dns_zones = {
    for k, v in local.private_dns_zones_raw : k => merge(v, {
      vnet_links = [
        for link in try(v.vnet_links, []) : merge(link, {
          # Resolve vnet_key to actual vnet_id
          vnet_id = try(link.vnet_key, null) != null ? module.vnets[link.vnet_key].id : try(link.vnet_id, null)
        })
      ]
    })
  }
  all_private_dns_zones = merge(local.private_dns_zones, var.private_dns_zones)
  enabled_private_dns_zones = {
    for k, v in local.all_private_dns_zones :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 4: Databricks Workspaces (Depends on VNets)
  # ============================================================================

  workspaces_raw = {
    for f in try(fileset("${path.module}/resources/azure/workspaces", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/workspaces/${f}"))
  }

  # Resolve VNet key references for workspaces
  workspaces = {
    for k, v in local.workspaces_raw : k => merge(v, {
      # Determine network type (default to public)
      network_type = try(v.network_type, "public")

      # VNet references - only resolve if vnet_injected
      vnet_id = try(v.vnet_key, null) != null ? module.vnets[v.vnet_key].id : null

      public_subnet_id = try(v.vnet_key, null) != null && try(v.public_subnet_name, null) != null ? (
        module.vnets[v.vnet_key].subnet_ids[v.public_subnet_name]
      ) : null

      private_subnet_id = try(v.vnet_key, null) != null && try(v.private_subnet_name, null) != null ? (
        module.vnets[v.vnet_key].subnet_ids[v.private_subnet_name]
      ) : null

      # NSG association IDs for VNet injection
      public_nsg_association_id = try(v.vnet_key, null) != null && try(v.nsg_association_public, null) != null ? (
        module.vnets[v.vnet_key].nsg_association_ids[v.nsg_association_public]
      ) : null

      private_nsg_association_id = try(v.vnet_key, null) != null && try(v.nsg_association_private, null) != null ? (
        module.vnets[v.vnet_key].nsg_association_ids[v.nsg_association_private]
      ) : null
    })
  }
  all_workspaces = merge(local.workspaces, var.workspaces)
  enabled_workspaces = {
    for k, v in local.all_workspaces :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Phase 5: Private Endpoints (Depends on VNets, Workspaces, DNS Zones)
  # ============================================================================

  private_endpoints_raw = {
    for f in try(fileset("${path.module}/resources/azure/private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/private_endpoints/${f}"))
  }

  # Resolve all key references for private endpoints
  private_endpoints = {
    for k, v in local.private_endpoints_raw : k => merge(v, {
      # Resolve subnet_id from vnet_key and subnet_name
      subnet_id = try(v.vnet_key, null) != null && try(v.subnet_name, null) != null ? (
        module.vnets[v.vnet_key].subnet_ids[v.subnet_name]
      ) : try(v.subnet_id, null)

      # Resolve private_connection_resource_id based on resource type
      private_connection_resource_id = coalesce(
        # Workspace reference
        try(v.workspace_key, null) != null ? module.workspaces[v.workspace_key].id : null,
        # Storage account reference
        try(v.storage_account_key, null) != null ? module.storage_accounts[v.storage_account_key].id : null,
        # Direct ID
        try(v.private_connection_resource_id, null)
      )

      # Resolve DNS zone IDs
      private_dns_zone_ids = try(v.dns_zone_key, null) != null ? [
        module.private_dns_zones[v.dns_zone_key].id
      ] : try(v.private_dns_zone_ids, null)
    })
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
  # Note: Private endpoints and DNS zones are managed separately for modularity

  storage_accounts_raw = {
    for f in try(fileset("${path.module}/resources/azure/storage_accounts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/azure/storage_accounts/${f}"))
  }

  # Resolve key references for storage accounts
  storage_accounts = {
    for k, v in local.storage_accounts_raw : k => merge(v, {
      # Resolve access_connector_id from key
      access_connector_id = try(v.access_connector_key, null) != null ? (
        module.access_connectors[v.access_connector_key].id
      ) : try(v.access_connector_id, null)

      # Resolve access_connector_principal_id from key
      access_connector_principal_id = try(v.access_connector_key, null) != null ? (
        module.access_connectors[v.access_connector_key].principal_id
      ) : try(v.access_connector_principal_id, null)

      # Resolve network_rules.virtual_network_subnet_ids from keys
      network_rules = try(v.network_rules, null) != null ? merge(v.network_rules, {
        virtual_network_subnet_ids = try(v.network_rules.vnet_key, null) != null && try(v.network_rules.subnet_names, null) != null ? [
          for subnet_name in v.network_rules.subnet_names :
          module.vnets[v.network_rules.vnet_key].subnet_ids[subnet_name]
        ] : try(v.network_rules.virtual_network_subnet_ids, [])
      }) : null
    })
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

  # Metastores
  metastores = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastores", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastores/${f}"))
  }
  all_metastores = merge(local.metastores, var.metastores)
  enabled_metastores = {
    for k, v in local.all_metastores :
    k => v if try(v.enabled, true)
  }

  # Metastore Assignments - Key-based resolution
  metastore_assignments_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/metastore_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/metastore_assignments/${f}"))
  }

  metastore_assignments = {
    for k, v in local.metastore_assignments_raw : k => merge(v, {
      # Resolve workspace_id from workspace_key
      workspace_id = try(v.workspace_key, null) != null ? (
        module.workspaces[v.workspace_key].workspace_id
      ) : try(v.workspace_id, null)

      # Resolve metastore_id from metastore_key
      metastore_id = try(v.metastore_key, null) != null ? (
        module.metastores[v.metastore_key].metastore_id
      ) : try(v.metastore_id, null)
    })
  }

  all_metastore_assignments = merge(local.metastore_assignments, var.metastore_assignments)
  enabled_metastore_assignments = {
    for k, v in local.all_metastore_assignments :
    k => v if try(v.enabled, true)
  }

  # Budget Policies - Key-based resolution
  budget_policies_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/budget_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/budget_policies/${f}"))
  }

  budget_policies = {
    for k, v in local.budget_policies_raw : k => merge(v, {
      # Resolve workspace_ids in filter from workspace_keys
      filter = try(v.filter, null) != null ? merge(v.filter, {
        workspace_id = try(v.filter.workspace_id, null) != null ? merge(v.filter.workspace_id, {
          values = try(v.filter.workspace_id.workspace_keys, null) != null ? [
            for ws_key in v.filter.workspace_id.workspace_keys :
            module.workspaces[ws_key].workspace_id
          ] : try(v.filter.workspace_id.values, [])
        }) : null
      }) : null
    })
  }

  all_budget_policies = merge(local.budget_policies, var.budget_policies)
  enabled_budget_policies = {
    for k, v in local.all_budget_policies :
    k => v if try(v.enabled, true)
  }

  # NCC (Network Connectivity Configs) - Key-based resolution
  ncc_configs_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc/${f}"))
  }

  ncc_configs = {
    for k, v in local.ncc_configs_raw : k => merge(v, {
      # Resolve workspace_ids from workspace_keys
      workspace_ids = try(v.workspace_keys, null) != null ? [
        for ws_key in v.workspace_keys :
        module.workspaces[ws_key].workspace_id
      ] : try(v.workspace_ids, null)
    })
  }

  all_ncc_configs = merge(local.ncc_configs, var.ncc_configs)
  enabled_ncc_configs = {
    for k, v in local.all_ncc_configs :
    k => v if try(v.enabled, true)
  }

  # NCC Private Endpoints - Key-based resolution
  ncc_private_endpoints_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/ncc_private_endpoints", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/ncc_private_endpoints/${f}"))
  }

  ncc_private_endpoints = {
    for k, v in local.ncc_private_endpoints_raw : k => merge(v, {
      # Resolve network_connectivity_config_id from ncc_key
      network_connectivity_config_id = try(v.ncc_key, null) != null ? (
        module.ncc_configs[v.ncc_key].network_connectivity_config_id
      ) : try(v.network_connectivity_config_id, null)

      # Resolve resource_id from storage_account_key
      resource_id = try(v.storage_account_key, null) != null ? (
        module.storage_accounts[v.storage_account_key].id
      ) : try(v.resource_id, null)
    })
  }

  all_ncc_private_endpoints = merge(local.ncc_private_endpoints, var.ncc_private_endpoints)
  enabled_ncc_private_endpoints = {
    for k, v in local.all_ncc_private_endpoints :
    k => v if try(v.enabled, true)
  }

  # Service Principals
  service_principals = {
    for f in try(fileset("${path.module}/resources/databricks/account/service_principals", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/service_principals/${f}"))
  }
  all_service_principals = merge(local.service_principals, var.service_principals)
  enabled_service_principals = {
    for k, v in local.all_service_principals :
    k => v if try(v.enabled, true)
  }

  # Workspace Admin Assignments - Key-based resolution
  workspace_admin_assignments_raw = {
    for f in try(fileset("${path.module}/resources/databricks/account/workspace_admin_assignments", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/account/workspace_admin_assignments/${f}"))
  }

  workspace_admin_assignments = {
    for k, v in local.workspace_admin_assignments_raw : k => merge(v, {
      # Resolve workspace_id from workspace_key
      workspace_id = try(v.workspace_key, null) != null ? (
        module.workspaces[v.workspace_key].workspace_id
      ) : try(v.workspace_id, null)
    })
  }

  all_workspace_admin_assignments = merge(local.workspace_admin_assignments, var.workspace_admin_assignments)
  enabled_workspace_admin_assignments = {
    for k, v in local.all_workspace_admin_assignments :
    k => v if try(v.enabled, true)
  }

  # ============================================================================
  # Databricks Workspace Resources
  # ============================================================================

  # Storage Credentials - Key-based resolution
  storage_credentials_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/storage_credentials", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/storage_credentials/${f}"))
  }

  storage_credentials = {
    for k, v in local.storage_credentials_raw : k => merge(v, {
      # Resolve access_connector_id in azure_managed_identity from key
      azure_managed_identity = try(v.azure_managed_identity, null) != null ? merge(v.azure_managed_identity, {
        access_connector_id = try(v.azure_managed_identity.access_connector_key, null) != null ? (
          module.access_connectors[v.azure_managed_identity.access_connector_key].id
        ) : try(v.azure_managed_identity.access_connector_id, null)
      }) : null

      # Resolve workspace_ids from workspace_keys
      workspace_ids = try(v.workspace_keys, null) != null ? [
        for ws_key in v.workspace_keys :
        module.workspaces[ws_key].workspace_id
      ] : try(v.workspace_ids, null)
    })
  }

  all_storage_credentials = merge(local.storage_credentials, var.storage_credentials)
  enabled_storage_credentials = {
    for k, v in local.all_storage_credentials :
    k => v if try(v.enabled, true)
  }

  # External Locations - Key-based resolution
  external_locations_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/external_locations", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/external_locations/${f}"))
  }

  external_locations = {
    for k, v in local.external_locations_raw : k => merge(v, {
      # Resolve workspace_ids from workspace_keys
      workspace_ids = try(v.workspace_keys, null) != null ? [
        for ws_key in v.workspace_keys :
        module.workspaces[ws_key].workspace_id
      ] : try(v.workspace_ids, null)
    })
  }

  all_external_locations = merge(local.external_locations, var.external_locations)
  enabled_external_locations = {
    for k, v in local.all_external_locations :
    k => v if try(v.enabled, true)
  }

  # Catalogs - Key-based resolution
  catalogs_raw = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/catalogs", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/catalogs/${f}"))
  }

  catalogs = {
    for k, v in local.catalogs_raw : k => merge(v, {
      # Resolve workspace_ids from workspace_keys
      workspace_ids = try(v.workspace_keys, null) != null ? [
        for ws_key in v.workspace_keys :
        module.workspaces[ws_key].workspace_id
      ] : try(v.workspace_ids, null)
    })
  }

  all_catalogs = merge(local.catalogs, var.catalogs)
  enabled_catalogs = {
    for k, v in local.all_catalogs :
    k => v if try(v.enabled, true)
  }

  # Schemas
  schemas = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/schemas", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/schemas/${f}"))
  }
  all_schemas = merge(local.schemas, var.schemas)
  enabled_schemas = {
    for k, v in local.all_schemas :
    k => v if try(v.enabled, true)
  }

  # Clusters
  clusters = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/clusters", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/clusters/${f}"))
  }
  all_clusters = merge(local.clusters, var.clusters)
  enabled_clusters = {
    for k, v in local.all_clusters :
    k => v if try(v.enabled, true)
  }

  # Cluster Policies
  cluster_policies = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/cluster_policies", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/cluster_policies/${f}"))
  }
  all_cluster_policies = merge(local.cluster_policies, var.cluster_policies)
  enabled_cluster_policies = {
    for k, v in local.all_cluster_policies :
    k => v if try(v.enabled, true)
  }

  # SQL Warehouses
  sql_warehouses = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/sql_warehouses", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/sql_warehouses/${f}"))
  }
  all_sql_warehouses = merge(local.sql_warehouses, var.sql_warehouses)
  enabled_sql_warehouses = {
    for k, v in local.all_sql_warehouses :
    k => v if try(v.enabled, true)
  }

  # Workspace Folders
  workspace_folders = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/workspace_folders", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/workspace_folders/${f}"))
  }
  all_workspace_folders = merge(local.workspace_folders, var.workspace_folders)
  enabled_workspace_folders = {
    for k, v in local.all_workspace_folders :
    k => v if try(v.enabled, true)
  }

  # Queries
  queries = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/queries", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/queries/${f}"))
  }
  all_queries = merge(local.queries, var.queries)
  enabled_queries = {
    for k, v in local.all_queries :
    k => v if try(v.enabled, true)
  }

  # Alerts
  alerts = {
    for f in try(fileset("${path.module}/resources/databricks/workspace/alerts", "*.json"), []) :
    trimsuffix(f, ".json") => jsondecode(file("${path.module}/resources/databricks/workspace/alerts/${f}"))
  }
  all_alerts = merge(local.alerts, var.alerts)
  enabled_alerts = {
    for k, v in local.all_alerts :
    k => v if try(v.enabled, true)
  }

  # Workspace Permissions
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
