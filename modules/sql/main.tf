# LLD 5.2 — Entra-only auth, serverless, 60-minute auto-pause
resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  public_network_access_enabled = false
  tags                          = var.tags

  azuread_administrator {
    login_username = var.aad_admin_login
    object_id       = var.aad_admin_object_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "inventory" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.this.id
  sku_name       = "GP_S_Gen5_${var.max_vcore}"
  min_capacity   = var.min_vcore
  auto_pause_delay_in_minutes = var.auto_pause_delay_minutes
  zone_redundant = false
  tags           = var.tags
}

module "private_endpoint" {
  source               = "../private-endpoint"
  name                 = "pe-${var.server_name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_mssql_server.this.id
  subresource_names    = ["sqlServer"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}
