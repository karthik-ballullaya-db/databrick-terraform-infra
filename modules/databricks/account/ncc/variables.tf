variable "config" {
  type        = any
  description = "Configuration object for the network connectivity config"
}

variable "workspaces_map" {
  type        = any
  description = "Map of workspace modules for resolving workspace_keys references"
  default     = {}
}
