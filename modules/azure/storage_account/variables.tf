variable "config" {
  type        = any
  description = "Configuration object for the storage account"
}

variable "access_connectors_map" {
  type        = any
  description = "Map of access connector modules for resolving access_connector_key references"
  default     = {}
}

variable "vnets_map" {
  type        = any
  description = "Map of VNet modules for resolving vnet_key references in network_rules"
  default     = {}
}
