locals {
  log_analytics_id = data.terraform_remote_state.governance.outputs.log_analytics_id
  app_insights_id   = data.terraform_remote_state.governance.outputs.app_insights_id
  governance_rgs     = data.terraform_remote_state.governance.outputs.resource_group_names
}

# LLD 13.1 — diagnostic settings sending every category to Log Analytics,
# for the resources created in stacks 20, 40, 50, 60, 70. Container Apps'
# own console/system-log diagnostic setting is created directly inside
# 60-platform instead (it needs the environment's own ID, which that stack
# already has in scope) — see Implementation Guide Step 9 for the full list.

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-agw-${var.environment}"
  target_resource_id          = data.terraform_remote_state.edge.outputs.appgw_id
  log_analytics_workspace_id   = local.log_analytics_id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayPerformanceLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }
  metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "diag-cosmos-${var.environment}"
  target_resource_id          = data.terraform_remote_state.data_stack.outputs.cosmos_id
  log_analytics_workspace_id   = local.log_analytics_id

  enabled_log { category = "DataPlaneRequests" }
  enabled_log { category = "QueryRuntimeStatistics" }
  metric { category = "Requests" }
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "diag-sb-${var.environment}"
  target_resource_id          = data.terraform_remote_state.integration.outputs.servicebus_namespace_id
  log_analytics_workspace_id   = local.log_analytics_id

  enabled_log { category = "OperationalLogs" }
  metric { category = "AllMetrics" }
}

# LLD 13.1 — Activity Log for the whole subscription
data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-${var.environment}"
  target_resource_id          = data.azurerm_subscription.current.id
  log_analytics_workspace_id   = local.log_analytics_id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Policy" }
  enabled_log { category = "Security" }
}

# HLD M9 / LLD 13.5 — one availability test hitting the Front Door endpoint
resource "azurerm_application_insights_web_test" "availability" {
  name                    = "webtest-cloudmart-products"
  location                 = var.location
  resource_group_name        = local.governance_rgs["governance"]
  application_insights_id      = local.app_insights_id
  kind                            = "ping"
  geo_locations                     = ["emea-in-ch-azr"] # Central India probe location
  enabled                             = true

  configuration = <<XML
<WebTest Name="webtest-cloudmart-products" Enabled="True" Timeout="30" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010">
  <Items>
    <Request Method="GET" Url="https://${data.terraform_remote_state.edge.outputs.frontdoor_endpoint}/products" />
  </Items>
</WebTest>
XML
}
