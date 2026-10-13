data "terraform_remote_state" "governance" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "10-governance.tfstate"
    use_azuread_auth = true
  }
}
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "20-network.tfstate"
    use_azuread_auth = true
  }
}
data "terraform_remote_state" "data_stack" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "40-data.tfstate"
    use_azuread_auth = true
  }
}
data "terraform_remote_state" "integration" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "50-integration.tfstate"
    use_azuread_auth = true
  }
}
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "60-platform.tfstate"
    use_azuread_auth = true
  }
}
data "terraform_remote_state" "edge" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "70-edge.tfstate"
    use_azuread_auth = true
  }
}
locals {
  log_analytics_id = data.terraform_remote_state.governance.outputs.log_analytics_id
}
