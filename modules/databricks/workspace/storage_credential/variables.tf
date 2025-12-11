variable "config" {
  type        = any
  description = "Configuration object for the storage credential"
}

variable "access_connectors_map" {
  type        = any
  description = "Map of access connector modules for resolving access_connector_key references"
  default     = {}
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_keys references"
  default     = {}
}
