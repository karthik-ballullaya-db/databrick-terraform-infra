variable "config" {
  type        = any
  description = "Configuration object for the Databricks workspace"
}

variable "vnets_map" {
  type        = any
  description = "Map of VNet modules for resolving vnet_key references"
  default     = {}
}
