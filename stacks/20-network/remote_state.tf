# Cross-stack data (LLD 9.1) — read 10-governance's state instead of
# requiring these values to be typed in by hand.
data "terraform_remote_state" "governance" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-cm-tfstate"
    storage_account_name = "stcmtfstate01"
    container_name        = "tfstate"
    key                    = "10-governance.tfstate"
    use_azuread_auth        = true
  }
}

locals {
  governance_resource_group_names = data.terraform_remote_state.governance.outputs.resource_group_names
  log_analytics_id                 = data.terraform_remote_state.governance.outputs.log_analytics_id
}
