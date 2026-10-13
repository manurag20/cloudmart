resource "azurerm_virtual_network" "spoke" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes

  private_endpoint_network_policies = each.value.private_endpoint_policies ? "Enabled" : "Disabled"

  dynamic "delegation" {
    for_each = each.value.delegation_service != null ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name = each.value.delegation_service
      }
    }
  }
}

# LLD 3.2 — peering, both directions, allow_forwarded_traffic = true
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${azurerm_virtual_network.spoke.name}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${azurerm_virtual_network.spoke.name}"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}
