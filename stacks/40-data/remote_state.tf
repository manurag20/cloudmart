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
data "terraform_remote_state" "security" {
  backend = "azurerm"
  config = {
    resource_group_name = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name = "tfstate"
    key = "30-security.tfstate"
    use_azuread_auth = true
  }
}
locals {
  governance_resource_group_names = data.terraform_remote_state.governance.outputs.resource_group_names
  app_subnet_ids                   = data.terraform_remote_state.network.outputs.app_subnet_ids
  dns_zone_ids                      = data.terraform_remote_state.network.outputs.dns_zone_ids
  identity_principal_ids             = data.terraform_remote_state.security.outputs.identity_principal_ids
}
