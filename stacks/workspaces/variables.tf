# ============================================================================
# Workspaces Stack - Variables
# ============================================================================
# Each workspace requires a workspace_<name>_host variable.
# Add a new variable when adding a new workspace file.
# ============================================================================

# ============================================================================
# Workspace Host Variables
# ============================================================================

variable "workspace_dev_host" {
  type        = string
  description = "Databricks Workspace URL for dev workspace"
  default     = ""
}

# Add more workspace variables as needed:
# variable "workspace_prod_host" {
#   type        = string
#   description = "Databricks Workspace URL for prod workspace"
#   default     = ""
# }

# ============================================================================
# Environment Configuration
# ============================================================================

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}
