locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_platform = local.governance_resource_group_names["platform"]
}

# LLD 6 catalogue
module "acr" {
  source               = "../../modules/acr"
  name                  = "crcm${var.environment}cin01"
  location               = var.location
  resource_group_name     = local.rg_platform
  tags                      = local.tags
}

# LLD 4.4 — AcrPull for all 6 app identities (the 5 backend services plus web-frontend)
resource "azurerm_role_assignment" "acr_pull" {
  for_each              = local.identity_principal_ids
  scope                 = module.acr.id
  role_definition_name  = "AcrPull"
  principal_id           = each.value
}

# LLD 7.1
module "aca_env" {
  source                          = "../../modules/aca-env"
  name                              = "cae-cm-${var.environment}-cin-01"
  location                           = var.location
  resource_group_name                = local.rg_platform
  subnet_id                           = local.app_subnet_ids["snet-aca"]
  log_analytics_workspace_id           = local.log_analytics_id
  log_analytics_customer_id             = ""
  log_analytics_shared_key               = ""
  tags                                    = local.tags
}

# LLD 13.1 — Container Apps console + system logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "aca_env" {
  name                       = "diag-cae-${var.environment}"
  target_resource_id          = module.aca_env.id
  log_analytics_workspace_id   = local.log_analytics_id

  enabled_log { category = "ContainerAppConsoleLogs" }
  enabled_log { category = "ContainerAppSystemLogs" }
  metric { category = "AllMetrics" }
}

# LLD 7.2 — web-frontend
module "web_frontend" {
  source                   = "../../modules/aca-app"
  name                       = "ca-web-frontend-${var.environment}"
  environment_id               = module.aca_env.id
  resource_group_name            = local.rg_platform
  image                            = "${module.acr.login_server}/web-frontend:${var.image_tag}"
  cpu                                = 0.25
  memory                              = "0.5Gi"
  identity_id                          = local.identity_ids["web-frontend"]
  acr_login_server                       = module.acr.login_server
  min_replicas                             = 1
  max_replicas                              = 5
  target_port                                = 8080
  scale_rule_type                             = "http"
  http_concurrent_requests                     = 50
  env_vars = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.app_insights_connection_string
  }
  tags = local.tags
}

# LLD 7.2 — order-api
module "order_api" {
  source                = "../../modules/aca-app"
  name                    = "ca-order-api-${var.environment}"
  environment_id            = module.aca_env.id
  resource_group_name        = local.rg_platform
  image                        = "${module.acr.login_server}/order-api:${var.image_tag}"
  cpu                            = 0.5
  memory                          = "1Gi"
  identity_id                      = local.identity_ids["order-api"]
  acr_login_server                   = module.acr.login_server
  min_replicas                         = 1
  max_replicas                          = 10
  target_port                            = 8080
  scale_rule_type                         = "http"
  http_concurrent_requests                 = 30
  env_vars = {
    COSMOS_ENDPOINT              = local.cosmos_endpoint
    SERVICEBUS_NAMESPACE          = local.servicebus_namespace_fqdn
    AZURE_CLIENT_ID                = local.identity_client_ids["order-api"]
    ENTRA_CLIENT_ID                 = local.entra_client_id
    INVENTORY_URL                     = "http://ca-inventory-svc-${var.environment}.internal.${module.aca_env.default_domain}"
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.app_insights_connection_string
  }
  tags = local.tags
}

# LLD 7.2 — inventory-svc
module "inventory_svc" {
  source                = "../../modules/aca-app"
  name                    = "ca-inventory-svc-${var.environment}"
  environment_id            = module.aca_env.id
  resource_group_name        = local.rg_platform
  image                        = "${module.acr.login_server}/inventory-svc:${var.image_tag}"
  cpu                            = 0.25
  memory                          = "0.5Gi"
  identity_id                      = local.identity_ids["inventory-svc"]
  acr_login_server                   = module.acr.login_server
  min_replicas                         = 1
  max_replicas                          = 5
  target_port                            = 8080
  scale_rule_type                         = "http"
  http_concurrent_requests                 = 30
  env_vars = {
    SQL_SERVER_FQDN               = local.sql_server_fqdn
    AZURE_CLIENT_ID                 = local.identity_client_ids["inventory-svc"]
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.app_insights_connection_string
  }
  tags = local.tags
}

# LLD 7.2 — payment-svc (worker, no ingress, KEDA Service Bus scale rule)
module "payment_svc" {
  source                           = "../../modules/aca-app"
  name                               = "ca-payment-svc-${var.environment}"
  environment_id                       = module.aca_env.id
  resource_group_name                    = local.rg_platform
  image                                    = "${module.acr.login_server}/payment-svc:${var.image_tag}"
  cpu                                        = 0.25
  memory                                      = "0.5Gi"
  identity_id                                  = local.identity_ids["payment-svc"]
  acr_login_server                               = module.acr.login_server
  min_replicas                                     = 0
  max_replicas                                      = 5
  scale_rule_type                                    = "servicebus"
  servicebus_queue_or_topic_name                       = "orders/subscriptions/payment"
  servicebus_namespace                                   = local.servicebus_namespace_fqdn
  env_vars = {
    SERVICEBUS_NAMESPACE = local.servicebus_namespace_fqdn
    AZURE_CLIENT_ID        = local.identity_client_ids["payment-svc"]
  }
  tags = local.tags
}

# LLD 7.2 — notification-worker (worker, no ingress, KEDA Service Bus scale rule)
module "notification_worker" {
  source                           = "../../modules/aca-app"
  name                               = "ca-notification-worker-${var.environment}"
  environment_id                       = module.aca_env.id
  resource_group_name                    = local.rg_platform
  image                                    = "${module.acr.login_server}/notification-worker:${var.image_tag}"
  cpu                                        = 0.25
  memory                                      = "0.5Gi"
  identity_id                                  = local.identity_ids["notification-worker"]
  acr_login_server                               = module.acr.login_server
  min_replicas                                     = 0
  max_replicas                                      = 3
  scale_rule_type                                    = "servicebus"
  servicebus_queue_or_topic_name                       = "sbq-invoice-notifications"
  servicebus_namespace                                   = local.servicebus_namespace_fqdn
  env_vars = {
    SERVICEBUS_NAMESPACE = local.servicebus_namespace_fqdn
    COSMOS_ENDPOINT        = local.cosmos_endpoint
    AZURE_CLIENT_ID          = local.identity_client_ids["notification-worker"]
  }
  tags = local.tags
}
