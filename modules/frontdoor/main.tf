resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "afd-endpoint-cloudmart"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "og-cloudmart"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {}
  health_probe {
    path                = "/health/live"
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 30
  }
}

resource "azurerm_cdn_frontdoor_origin" "appgw" {
  name                          = "origin-appgw"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                      = var.origin_host
  origin_host_header              = var.origin_host
  certificate_name_check_enabled  = true
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = "wafpolicy-afd-dev"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  mode                = var.waf_mode # Phase 1 = Detection, Phase 2 = Prevention

  managed_rule {
    type    = "DefaultRuleSet"
    version = "preview-0.1"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "secpolicy-afd-dev"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "route-cloudmart"
  cdn_frontdoor_endpoint_id      = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids       = [azurerm_cdn_frontdoor_origin.appgw.id]
  supported_protocols            = ["Https"]
  patterns_to_match               = ["/*"]
  forwarding_protocol              = "HttpsOnly"
  https_redirect_enabled            = true
}
