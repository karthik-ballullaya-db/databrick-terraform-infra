variable "config" {
  type        = any
  description = "Configuration object for the metastore assignment"
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_key references"
  default     = {}
}

variable "metastores_map" {
  type        = any
  description = "Map of metastore modules for resolving metastore_key references"
  default     = {}
}
