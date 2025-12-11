# ============================================================================
# Budget Policy Module
# ============================================================================
# Creates Databricks Budget Policy for cost management
# Resolves workspace_keys references internally using workspaces_map
# ============================================================================

locals {
  # Resolve workspace_ids from workspace_keys in filter if provided
  filter = try(var.config.filter, null) != null ? merge(var.config.filter, {
    workspace_id = try(var.config.filter.workspace_id, null) != null ? merge(var.config.filter.workspace_id, {
      values = try(var.config.filter.workspace_id.workspace_keys, null) != null ? [
        for ws_key in var.config.filter.workspace_id.workspace_keys :
        var.workspaces_map[ws_key].workspace_id
      ] : try(var.config.filter.workspace_id.values, [])
    }) : null
  }) : null
}

resource "databricks_budget" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  budget_configuration_id = try(var.config.budget_configuration_id, null)
  display_name            = var.config.display_name

  dynamic "filter" {
    for_each = local.filter != null ? [local.filter] : []

    content {
      dynamic "tags" {
        for_each = try(filter.value.tags, [])

        content {
          key = try(tags.value.key, null)

          value {
            operator = try(tags.value.value.operator, null)
            values   = try(tags.value.value.values, null)
          }
        }
      }

      dynamic "workspace_id" {
        for_each = try(filter.value.workspace_id, null) != null ? [filter.value.workspace_id] : []

        content {
          operator = try(workspace_id.value.operator, null)
          values   = try(workspace_id.value.values, null)
        }
      }
    }
  }

  dynamic "alert_configurations" {
    for_each = try(var.config.alert_configurations, [])

    content {
      time_period        = try(alert_configurations.value.time_period, null)
      trigger_type       = try(alert_configurations.value.trigger_type, null)
      quantity_type      = try(alert_configurations.value.quantity_type, null)
      quantity_threshold = try(alert_configurations.value.quantity_threshold, null)
      action_configurations {
        action_type = try(alert_configurations.value.action_configurations.action_type, null)
        target      = try(alert_configurations.value.action_configurations.target, null)
      }
    }
  }
}
