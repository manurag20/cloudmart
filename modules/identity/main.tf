# LLD 4.3 — one user-assigned managed identity. Reused for all 5 app
# identities by passing a different `name` from each calling stack.
resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
