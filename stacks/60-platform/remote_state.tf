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
locals {
  governance_resource_group_names = data.terraform_remote_state.governance.outputs.resource_group_names
  app_subnet_ids                   = data.terraform_remote_state.network.outputs.app_subnet_ids
  log_analytics_id                  = data.terraform_remote_state.governance.outputs.log_analytics_id
  identity_ids                       = data.terraform_remote_state.security.outputs.identity_ids
  identity_principal_ids              = data.terraform_remote_state.security.outputs.identity_principal_ids
  identity_client_ids                  = data.terraform_remote_state.security.outputs.identity_client_ids
  entra_client_id                       = data.terraform_remote_state.security.outputs.entra_client_id
  cosmos_endpoint                        = data.terraform_remote_state.data_stack.outputs.cosmos_endpoint
  sql_server_fqdn                         = data.terraform_remote_state.data_stack.outputs.sql_server_fqdn
  servicebus_namespace_fqdn                = data.terraform_remote_state.integration.outputs.servicebus_namespace_fqdn
  servicebus_namespace_id                   = data.terraform_remote_state.integration.outputs.servicebus_namespace_id
  app_insights_connection_string             = data.terraform_remote_state.governance.outputs.app_insights_connection_string
}
