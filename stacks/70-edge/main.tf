locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_edge = local.governance_resource_group_names["edge"]
  rg_app  = local.governance_resource_group_names["net-app"]
}

# LLD 7/9 — Application Gateway WAF_v2, backend = Container Apps internal LB via web-frontend
module "appgw" {
  source               = "../../modules/appgw"
  name                  = "agw-cm-${var.environment}-cin-01"
  location                = var.location
  resource_group_name      = local.rg_app
  subnet_id                  = local.app_subnet_ids["snet-appgw"]
  backend_fqdn                 = local.web_frontend_fqdn
  waf_mode                       = var.waf_mode
  tags                             = local.tags
}

# LLD 9 — Front Door Standard, origin = Application Gateway public IP
module "frontdoor" {
  source                = "../../modules/frontdoor"
  profile_name            = "afd-cm-${var.environment}-01"
  resource_group_name       = local.rg_edge
  origin_host                 = module.appgw.public_ip
  waf_mode                      = var.waf_mode
  tags                             = local.tags
}

# Note: nsg-appgw (stack 20-network) already restricts inbound 443 to the
# AzureFrontDoor.Backend service tag only (its Allow-FrontDoor-HTTPS rule,
# priority 120) — that's what makes a direct hit to the Gateway's public IP
# fail (acceptance test AT-06). Nothing further to add here; this stack
# only needs to deploy the Gateway and Front Door themselves.
