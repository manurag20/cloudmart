# LLD 4.5 — RBAC permission model, private endpoint only, soft delete on,
# purge protection OFF in Phase 1 so the vault can be freely recreated
# while learning (flips to true in Phase 2 Step 13 / LLD 4.5).
resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
  tags                          = var.tags
}

module "private_endpoint" {
  source               = "../private-endpoint"
  name                 = "pe-${var.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_key_vault.this.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}
