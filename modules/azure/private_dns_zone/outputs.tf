output "id" {
  description = "The ID of the private DNS zone"
  value       = try(azurerm_private_dns_zone.this[0].id, null)
}

output "name" {
  description = "The name of the private DNS zone"
  value       = try(azurerm_private_dns_zone.this[0].name, null)
}

output "resource_group_name" {
  description = "The resource group name of the private DNS zone"
  value       = try(azurerm_private_dns_zone.this[0].resource_group_name, null)
}

output "vnet_link_ids" {
  description = "Map of VNet link names to their IDs"
  value = {
    for k, link in azurerm_private_dns_zone_virtual_network_link.this : k => link.id
  }
}

