# LLD 5.1 — NoSQL API, Serverless, Session consistency, local auth disabled
resource "azurerm_cosmosdb_account" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  local_authentication_disabled = true
  public_network_access_enabled = false
  tags                          = var.tags

  capabilities { name = "EnableServerless" }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "cloudmart" {
  name                = "cloudmart"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

# LLD 5.1 — partition key /customerId, indexing policy excludes everything
# except customerId, status, createdAt (cheaper writes, same query coverage)
resource "azurerm_cosmosdb_sql_container" "orders" {
  name                = "orders"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.cloudmart.name
  partition_key_paths = ["/customerId"]

  indexing_policy {
    indexing_mode = "consistent"
    included_path { path = "/customerId/?" }
    included_path { path = "/status/?" }
    included_path { path = "/createdAt/?" }
    excluded_path  { path = "/*" }
  }
}

module "private_endpoint" {
  source               = "../private-endpoint"
  name                 = "pe-${var.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_cosmosdb_account.this.id
  subresource_names    = ["Sql"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}
