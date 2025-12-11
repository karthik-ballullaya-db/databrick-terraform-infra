output "id" {
  description = "The ID of the private endpoint"
  value       = try(azurerm_private_endpoint.this[0].id, null)
}

output "name" {
  description = "The name of the private endpoint"
  value       = try(azurerm_private_endpoint.this[0].name, null)
}

output "private_ip_address" {
  description = "The private IP address of the private endpoint"
  value       = try(azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address, null)
}

output "private_ip_addresses" {
  description = "List of all private IP addresses associated with the private endpoint"
  value       = try(azurerm_private_endpoint.this[0].custom_dns_configs[*].ip_addresses, [])
}

output "fqdn" {
  description = "The FQDN of the private endpoint (if DNS zone group is configured)"
  value       = try(azurerm_private_endpoint.this[0].custom_dns_configs[0].fqdn, null)
}

output "network_interface_id" {
  description = "The network interface ID of the private endpoint"
  value       = try(azurerm_private_endpoint.this[0].network_interface[0].id, null)
}

