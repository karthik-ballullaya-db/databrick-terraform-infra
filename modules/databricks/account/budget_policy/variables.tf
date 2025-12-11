variable "config" {
  type        = any
  description = "Configuration object for the budget policy"
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_keys references in filter"
  default     = {}
}
