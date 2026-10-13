# Implementation Guide Section 2 — run this stack once, with local state,
# before any other stack exists.
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-cm-tfstate"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "stcmtfstate01"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version           = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                      = var.tags

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 14
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "me_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = data.azurerm_client_config.current.object_id
}

# Implementation Guide Section 1.6 — GitHub OIDC federation
resource "azuread_application" "github_deploy" {
  display_name = "sp-github-cloudmart-deploy"
}

resource "azuread_service_principal" "github_deploy" {
  client_id = azuread_application.github_deploy.client_id
}

resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_deploy.id
  display_name   = "cloudmart-main-branch"
  issuer          = "https://token.actions.githubusercontent.com"
  subject          = "repo:<your-github-org>/cloudmart:ref:refs/heads/main"
  audiences         = ["api://AzureADTokenExchange"]
}

resource "azuread_application_federated_identity_credential" "pull_request" {
  application_id = azuread_application.github_deploy.id
  display_name   = "cloudmart-pull-request"
  issuer          = "https://token.actions.githubusercontent.com"
  subject          = "repo:<your-github-org>/cloudmart:pull_request"
  audiences         = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "github_reader_sub" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Reader"
  principal_id          = azuread_service_principal.github_deploy.object_id
}

resource "azurerm_role_assignment" "github_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = azuread_service_principal.github_deploy.object_id
}
