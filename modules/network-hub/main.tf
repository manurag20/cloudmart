# LLD 3.1 — vnet-cm-dev-hub-cin-01, 10.10.0.0/22
resource "azurerm_virtual_network" "hub" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

# Fixed Azure name — do not rename (LLD 3.1)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.0.0/26"]
}

# Required only for Firewall Basic SKU (LLD 3.1)
resource "azurerm_subnet" "firewall_mgmt" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.10.0.64/26"]
}

# 10.10.0.128/26 is deliberately left unallocated — freed up by using
# Bastion Developer SKU, which needs no dedicated subnet (LLD 3.1/3.7).
