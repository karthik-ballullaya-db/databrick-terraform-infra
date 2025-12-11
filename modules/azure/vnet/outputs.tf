output "id" {
  description = "The ID of the virtual network"
  value       = try(azurerm_virtual_network.this[0].id, null)
}

output "name" {
  description = "The name of the virtual network"
  value       = try(azurerm_virtual_network.this[0].name, null)
}

output "resource_group_name" {
  description = "The resource group name of the virtual network"
  value       = try(azurerm_virtual_network.this[0].resource_group_name, null)
}

output "location" {
  description = "The location of the virtual network"
  value       = try(azurerm_virtual_network.this[0].location, null)
}

output "address_space" {
  description = "The address space of the virtual network"
  value       = try(azurerm_virtual_network.this[0].address_space, null)
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, subnet in azurerm_subnet.this : k => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet names to their names"
  value = {
    for k, subnet in azurerm_subnet.this : k => subnet.name
  }
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for k, nsg in azurerm_network_security_group.this : k => nsg.id
  }
}

output "nsg_association_ids" {
  description = "Map of NSG association keys to their IDs (required for Databricks VNet injection)"
  value = {
    for k, assoc in azurerm_subnet_network_security_group_association.this : k => assoc.id
  }
}

