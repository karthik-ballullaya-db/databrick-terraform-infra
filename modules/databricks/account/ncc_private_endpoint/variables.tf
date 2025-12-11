variable "config" {
  description = "Configuration for NCC Private Endpoint Rule"
  type        = any
}

variable "ncc_configs_map" {
  type        = any
  description = "Map of NCC modules for resolving ncc_key references"
  default     = {}
}

variable "storage_accounts_map" {
  type        = any
  description = "Map of storage account modules for resolving storage_account_key references"
  default     = {}
}
