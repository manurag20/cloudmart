resource "azurerm_public_ip" "agw" {
  name                = "pip-agw-dev-cin-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "agw" {
  name                = "wafpolicy-agw-dev"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = var.waf_mode # Phase 1 = Detection, Phase 2 = Prevention (LLD/Guide Step 13)
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

# LLD 7 / HLD 9 — WAF_v2, autoscale, backend pointed at the Container
# Apps Environment's internal load balancer FQDN
resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                 = var.tags
  firewall_policy_id   = azurerm_web_application_firewall_policy.agw.id

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "gw-ipconfig"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  backend_address_pool {
    name  = "aca-backend-pool"
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                  = "aca-http-settings"
    cookie_based_affinity = "Disabled"
    port                   = 443
    protocol                = "Https"
    request_timeout          = 30
    probe_name               = "aca-health-probe"
  }

  probe {
    name                = "aca-health-probe"
    protocol            = "Https"
    path                = "/health/live"
    host                = var.backend_fqdn
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ipconfig"
    frontend_port_name             = "https-port"
    protocol                        = "Https"
    # certificate wired up separately once a domain + cert is chosen
  }

  request_routing_rule {
    name                        = "main-routing-rule"
    rule_type                   = "Basic"
    http_listener_name          = "https-listener"
    backend_address_pool_name   = "aca-backend-pool"
    backend_http_settings_name  = "aca-http-settings"
    priority                     = 100
  }
}
