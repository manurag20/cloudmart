resource "azurerm_public_ip" "fw" {
  name                = "pip-afw-dev-cin-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "fw_mgmt" {
  name                = "pip-afw-mgmt-dev-cin-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# LLD 3.5 — Basic SKU, single zone Phase 1
resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.fw.id
  }

  management_ip_configuration {
    name                 = "fw-mgmt-ipconfig"
    subnet_id            = var.mgmt_subnet_id
    public_ip_address_id = azurerm_public_ip.fw_mgmt.id
  }
}

resource "azurerm_firewall_policy" "this" {
  name                = "afwp-cm-dev-cin-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  tags                = var.tags
}

# LLD 3.5 — net-rc-core, priority 100
resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "net-rc-core"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority            = 100

  network_rule_collection {
    name     = "net-rc-core"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      protocols             = ["UDP"]
      source_addresses      = ["10.10.0.0/16"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = ["10.10.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

# LLD 3.5 — app-rc-core, priority 100 (every FQDN rule from the table)
resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "app-rc-core"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority            = 100
  depends_on          = [azurerm_firewall_policy_rule_collection_group.network]

  application_rule_collection {
    name     = "app-rc-core"
    priority = 100
    action   = "Allow"

    rule {
      name              = "allow-azure-mgmt"
      source_addresses  = ["10.10.0.0/16"]
      destination_fqdns = ["management.azure.com", "login.microsoftonline.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "allow-acr"
      source_addresses  = ["10.10.5.0/24"]
      destination_fqdns = ["*.azurecr.io", "*.blob.core.windows.net", "mcr.microsoft.com", "*.data.mcr.microsoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "allow-monitor"
      source_addresses  = ["10.10.0.0/16"]
      destination_fqdns = ["*.ods.opinsights.azure.com", "*.oms.opinsights.azure.com", "*.monitoring.azure.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "allow-github"
      source_addresses  = ["10.10.8.0/27"]
      destination_fqdns = ["github.com", "api.github.com", "*.actions.githubusercontent.com", "*.pkg.github.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "allow-ubuntu-updates"
      source_addresses  = ["10.10.8.0/27"]
      destination_fqdns = ["archive.ubuntu.com", "security.ubuntu.com"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "allow-pypi-npm"
      source_addresses  = ["10.10.8.0/27"]
      destination_fqdns = ["pypi.org", "files.pythonhosted.org", "registry.npmjs.org"]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

# LLD 3.5 — log every rule hit, network and application
resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                       = "diag-afw-dev"
  target_resource_id         = azurerm_firewall.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }
  metric { category = "AllMetrics" }
}
