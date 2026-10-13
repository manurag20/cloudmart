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
locals {
  governance_resource_group_names = data.terraform_remote_state.governance.outputs.resource_group_names
  app_subnet_ids                   = data.terraform_remote_state.network.outputs.app_subnet_ids
  web_frontend_fqdn                 = data.terraform_remote_state.platform.outputs.web_frontend_fqdn_hint
}
