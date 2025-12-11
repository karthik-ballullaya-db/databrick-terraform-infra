output "id" {
  description = "The ID of the storage account"
  value       = try(azurerm_storage_account.this[0].id, null)
}

output "name" {
  description = "The name of the storage account"
  value       = try(azurerm_storage_account.this[0].name, null)
}

output "resource_group_name" {
  description = "The resource group name of the storage account"
  value       = try(azurerm_storage_account.this[0].resource_group_name, null)
}

output "location" {
  description = "The location of the storage account"
  value       = try(azurerm_storage_account.this[0].location, null)
}

output "primary_dfs_endpoint" {
  description = "The primary DFS endpoint URL"
  value       = try(azurerm_storage_account.this[0].primary_dfs_endpoint, null)
}

output "primary_blob_endpoint" {
  description = "The primary Blob endpoint URL"
  value       = try(azurerm_storage_account.this[0].primary_blob_endpoint, null)
}

output "primary_dfs_host" {
  description = "The hostname with port if applicable for DFS storage"
  value       = try(azurerm_storage_account.this[0].primary_dfs_host, null)
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for Blob storage"
  value       = try(azurerm_storage_account.this[0].primary_blob_host, null)
}

output "container_ids" {
  description = "Map of container names to their resource IDs"
  value = {
    for k, container in azurerm_storage_container.this : k => container.id
  }
}
