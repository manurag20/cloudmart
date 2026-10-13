output "keyvault_id"   { value = module.keyvault.id }
output "keyvault_name" { value = module.keyvault.name }
output "identity_ids"       { value = { for k, m in module.identities : k => m.id } }
output "identity_principal_ids" { value = { for k, m in module.identities : k => m.principal_id } }
output "identity_client_ids"    { value = { for k, m in module.identities : k => m.client_id } }
output "entra_client_id" { value = azuread_application.customers.client_id }
