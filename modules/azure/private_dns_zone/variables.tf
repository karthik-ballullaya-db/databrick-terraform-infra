variable "config" {
  type        = any
  description = "Configuration object for the private DNS zone"
}

variable "vnets_map" {
  type        = any
  description = "Map of VNet modules for resolving vnet_key references to vnet_id"
  default     = {}
}
