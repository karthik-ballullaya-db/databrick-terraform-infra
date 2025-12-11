variable "config" {
  type        = any
  description = "Configuration object for workspace admin assignment"
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_key references"
  default     = {}
}
