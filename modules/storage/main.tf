# LLD 5.3 — LRS, shared-key auth disabled, invoices container, no public access
resource "azurerm_storage_account" "this" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  tags                             = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "invoices" {
  name                  = "invoices"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

module "private_endpoint" {
  source               = "../private-endpoint"
  name                 = "pe-${var.name}-blob"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_storage_account.this.id
  subresource_names    = ["blob"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}
