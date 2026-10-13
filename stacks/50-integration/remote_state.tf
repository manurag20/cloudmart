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
locals {
  governance_resource_group_names = data.terraform_remote_state.governance.outputs.resource_group_names
  identity_principal_ids           = data.terraform_remote_state.security.outputs.identity_principal_ids
  identity_ids                      = data.terraform_remote_state.security.outputs.identity_ids
  storage_account_id                 = data.terraform_remote_state.data_stack.outputs.storage_account_id
  storage_account_name                = data.terraform_remote_state.data_stack.outputs.storage_account_name
  app_insights_connection_string       = data.terraform_remote_state.governance.outputs.app_insights_connection_string
}
