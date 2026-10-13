output "github_deploy_client_id" { value = azuread_application.github_deploy.client_id }
output "github_deploy_sp_object_id" { value = azuread_service_principal.github_deploy.object_id }
output "tfstate_storage_account" { value = azurerm_storage_account.tfstate.name }
