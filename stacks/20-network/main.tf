locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_hub = local.governance_resource_group_names["net-hub"]
  rg_app = local.governance_resource_group_names["net-app"]
  rg_ops = local.governance_resource_group_names["net-ops"]
}

module "hub" {
  source              = "../../modules/network-hub"
  name                 = "vnet-cm-${var.environment}-hub-cin-01"
  location              = var.location
  resource_group_name   = local.rg_hub
  address_space          = var.hub_address_space
  tags                    = local.tags
}

module "spoke_app" {
  source              = "../../modules/network-spoke"
  name                 = "vnet-cm-${var.environment}-app-cin-01"
  location              = var.location
  resource_group_name   = local.rg_app
  address_space          = var.app_address_space
  hub_vnet_id             = module.hub.vnet_id
  hub_vnet_name            = module.hub.vnet_name
  hub_resource_group_name  = local.rg_hub
  tags                      = local.tags
  subnets = {
    "snet-appgw" = { address_prefixes = ["10.10.4.0/24"] }
    "snet-aca"   = { address_prefixes = ["10.10.5.0/24"], delegation_service = "Microsoft.App/environments" }
    "snet-pe"    = { address_prefixes = ["10.10.6.0/24"], private_endpoint_policies = true }
  }
}

module "spoke_ops" {
  source              = "../../modules/network-spoke"
  name                 = "vnet-cm-${var.environment}-ops-cin-01"
  location              = var.location
  resource_group_name   = local.rg_ops
  address_space          = var.ops_address_space
  hub_vnet_id             = module.hub.vnet_id
  hub_vnet_name            = module.hub.vnet_name
  hub_resource_group_name  = local.rg_hub
  tags                      = local.tags
  subnets = {
    "snet-runner" = { address_prefixes = ["10.10.8.0/27"] }
  }
}

module "firewall" {
  source                       = "../../modules/firewall"
  name                          = "afw-cm-${var.environment}-cin-01"
  location                       = var.location
  resource_group_name            = local.rg_hub
  subnet_id                       = module.hub.firewall_subnet_id
  mgmt_subnet_id                   = module.hub.firewall_mgmt_subnet_id
  log_analytics_workspace_id        = local.log_analytics_id
  tags                               = local.tags
}

# LLD 3.3 — UDR: force all egress from the app/ops spokes through the Firewall
resource "azurerm_route_table" "egress_app" {
  name                = "rt-egress-${var.environment}-cin"
  location            = var.location
  resource_group_name = local.rg_app
  tags                 = local.tags

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address   = module.firewall.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "aca" {
  subnet_id      = module.spoke_app.subnet_ids["snet-aca"]
  route_table_id = azurerm_route_table.egress_app.id
}

resource "azurerm_route_table" "egress_ops" {
  name                = "rt-egress-runner-${var.environment}-cin"
  location            = var.location
  resource_group_name = local.rg_ops
  tags                 = local.tags

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address   = module.firewall.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "runner" {
  subnet_id      = module.spoke_ops.subnet_ids["snet-runner"]
  route_table_id = azurerm_route_table.egress_ops.id
}

# LLD 3.4 — NSGs
resource "azurerm_network_security_group" "appgw" {
  name = "nsg-appgw"
  location = var.location
  resource_group_name = local.rg_app
  tags = local.tags
  security_rule {
    name = "Allow-GatewayManager"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "65200-65535"
    source_address_prefix = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name = "Allow-AzureLoadBalancer"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name = "Allow-FrontDoor-HTTPS"
    priority = 120
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = module.spoke_app.subnet_ids["snet-appgw"]
  network_security_group_id = azurerm_network_security_group.appgw.id
}

resource "azurerm_network_security_group" "aca" {
  name = "nsg-aca"
  location = var.location
  resource_group_name = local.rg_app
  tags = local.tags
  security_rule {
    name = "Allow-From-AppGw"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["80", "443"]
    source_address_prefix = "10.10.4.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aca" {
  subnet_id                 = module.spoke_app.subnet_ids["snet-aca"]
  network_security_group_id = azurerm_network_security_group.aca.id
}

resource "azurerm_network_security_group" "pe" {
  name = "nsg-pe"
  location = var.location
  resource_group_name = local.rg_app
  tags = local.tags
  security_rule {
    name = "Allow-From-ACA-and-Runner"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["443", "1433", "5671", "5672"]
    source_address_prefixes = ["10.10.5.0/24", "10.10.8.0/27"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = module.spoke_app.subnet_ids["snet-pe"]
  network_security_group_id = azurerm_network_security_group.pe.id
}

resource "azurerm_network_security_group" "runner" {
  name = "nsg-runner"
  location = var.location
  resource_group_name = local.rg_ops
  tags = local.tags
  security_rule {
    # LLD 3.4 — confirm current Bastion Developer SKU control-plane source range before applying
    name = "Allow-SSH-From-Bastion"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "runner" {
  subnet_id                 = module.spoke_ops.subnet_ids["snet-runner"]
  network_security_group_id = azurerm_network_security_group.runner.id
}

# LLD 3.6 — private DNS zones, linked to all 3 VNets
locals {
  dns_zones = [
    "privatelink.vaultcore.azure.net",
    "privatelink.documents.azure.com",
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
  ]
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = toset(local.dns_zones)
  name                = each.value
  resource_group_name = local.rg_hub
  tags                 = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each              = azurerm_private_dns_zone.this
  name                   = "link-hub-${replace(each.key, ".", "-")}"
  resource_group_name    = local.rg_hub
  private_dns_zone_name  = each.value.name
  virtual_network_id      = module.hub.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "app" {
  for_each              = azurerm_private_dns_zone.this
  name                   = "link-app-${replace(each.key, ".", "-")}"
  resource_group_name    = local.rg_hub
  private_dns_zone_name  = each.value.name
  virtual_network_id      = module.spoke_app.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ops" {
  for_each              = azurerm_private_dns_zone.this
  name                   = "link-ops-${replace(each.key, ".", "-")}"
  resource_group_name    = local.rg_hub
  private_dns_zone_name  = each.value.name
  virtual_network_id      = module.spoke_ops.vnet_id
}

# LLD 3.7 — Bastion Developer SKU, attaches directly, no dedicated subnet
resource "azurerm_bastion_host" "this" {
  name                = "bas-cm-${var.environment}-cin-01"
  location            = var.location
  resource_group_name = local.rg_ops
  sku                  = "Developer"
  virtual_network_id    = module.spoke_ops.vnet_id
  tags                   = local.tags
}
