locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_data = local.governance_resource_group_names["data"]
}

data "azurerm_client_config" "current" {}

# LLD 5.1
module "cosmos" {
  source               = "../../modules/cosmos"
  name                  = "cosmos-cm-${var.environment}-cin-01"
  location               = var.location
  resource_group_name     = local.rg_data
  subnet_id                = local.app_subnet_ids["snet-pe"]
  private_dns_zone_id       = local.dns_zone_ids["privatelink.documents.azure.com"]
  tags                       = local.tags
}

resource "azurerm_role_assignment" "cosmos_order_api" {
  scope                = module.cosmos.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id          = local.identity_principal_ids["order-api"]
}

resource "azurerm_role_assignment" "cosmos_notification" {
  scope                = module.cosmos.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id          = local.identity_principal_ids["notification-worker"]
}

# LLD 5.2
module "sql" {
  source                        = "../../modules/sql"
  server_name                    = "sql-cm-${var.environment}-cin-01"
  database_name                   = "sqldb-inventory-${var.environment}"
  location                         = var.location
  resource_group_name              = local.rg_data
  subnet_id                         = local.app_subnet_ids["snet-pe"]
  private_dns_zone_id                = local.dns_zone_ids["privatelink.database.windows.net"]
  aad_admin_object_id                 = data.azurerm_client_config.current.object_id
  aad_admin_login                      = var.owner
  min_vcore                             = var.sql_min_vcore
  max_vcore                              = var.sql_max_vcore
  auto_pause_delay_minutes                = var.sql_auto_pause_delay_minutes
  tags                                      = local.tags
}

# LLD 5.3
module "storage" {
  source               = "../../modules/storage"
  name                  = "stcm${var.environment}cin01"
  location               = var.location
  resource_group_name     = local.rg_data
  subnet_id                = local.app_subnet_ids["snet-pe"]
  private_dns_zone_id       = local.dns_zone_ids["privatelink.blob.core.windows.net"]
  tags                       = local.tags
}

resource "azurerm_role_assignment" "storage_invoice_fn" {
  scope                = module.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id          = local.identity_principal_ids["invoice-fn"]
}

resource "azurerm_role_assignment" "storage_notification" {
  scope                = module.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id          = local.identity_principal_ids["notification-worker"]
}
