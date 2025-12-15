terraform {
  backend "azurerm" {
    resource_group_name  = "sj_terraform_state"
    storage_account_name = "sjtfstate1"
    container_name       = "tfstate"
    key                  = "stack/workspaces.tfstate"
  }
}

