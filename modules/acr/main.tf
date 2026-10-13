# LLD 6 catalogue — Basic SKU, pull granted per-identity by the calling stack
resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  admin_enabled        = false
  tags                 = var.tags
}
