output "id"       { value = azurerm_cosmosdb_account.this.id } # resource ID, for RBAC scope and diagnostic settings
output "endpoint" { value = azurerm_cosmosdb_account.this.endpoint }
output "name"     { value = azurerm_cosmosdb_account.this.name }
