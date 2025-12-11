variable "config" {
  type        = any
  description = "Configuration object for the private endpoint"
}

variable "vnets_map" {
  type        = any
  description = "Map of VNet modules for resolving vnet_key references to subnet_id"
  default     = {}
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_key references"
  default     = {}
}

variable "storage_accounts_map" {
  type        = any
  description = "Map of storage account modules for resolving storage_account_key references"
  default     = {}
}

variable "private_dns_zones_map" {
  type        = any
  description = "Map of private DNS zone modules for resolving dns_zone_key references"
  default     = {}
}
