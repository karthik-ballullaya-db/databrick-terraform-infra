output "id" {
  description = "The Azure resource ID of the Databricks workspace"
  value       = try(azurerm_databricks_workspace.this[0].id, null)
}

output "workspace_id" {
  description = "The Databricks workspace ID (used for account-level operations)"
  value       = try(azurerm_databricks_workspace.this[0].workspace_id, null)
}

output "workspace_url" {
  description = "The workspace URL"
  value       = try(azurerm_databricks_workspace.this[0].workspace_url, null)
}

output "managed_resource_group_id" {
  description = "The ID of the managed resource group"
  value       = try(azurerm_databricks_workspace.this[0].managed_resource_group_id, null)
}

output "managed_resource_group_name" {
  description = "The name of the managed resource group"
  value       = try(azurerm_databricks_workspace.this[0].managed_resource_group_name, null)
}

output "storage_account_identity" {
  description = "The identity of the Databricks managed storage account"
  value       = try(azurerm_databricks_workspace.this[0].storage_account_identity, null)
}

output "disk_encryption_set_id" {
  description = "The ID of the disk encryption set"
  value       = try(azurerm_databricks_workspace.this[0].disk_encryption_set_id, null)
}

