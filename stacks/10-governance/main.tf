locals {
  tags = {
    project     = var.project
    env         = var.environment
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    phase       = "phase1"
  }
}

# LLD 14.1 — all 10 resource groups
resource "azurerm_resource_group" "rg" {
  for_each = toset([
    "governance", "net-hub", "net-app", "net-ops", "security",
    "data", "integration", "platform", "edge", "ops",
  ])
  name     = "rg-cm-${var.environment}-${each.key}"
  location = var.location
  tags     = local.tags
}

module "monitoring" {
  source              = "../../modules/monitoring"
  log_analytics_name  = "log-cm-${var.environment}-cin-01"
  app_insights_name   = "appi-cm-${var.environment}-01"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg["governance"].name
  tags                  = local.tags
}

# LLD 12.1/12.4 — mandatory tags + allowed locations, Audit in Phase 1
resource "azurerm_policy_definition" "mandatory_tags" {
  name         = "require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require project and env tags"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['project']", exists = "false" },
        { field = "tags['env']", exists = "false" },
      ]
    }
    then = { effect = "[parameters('effect')]" }
  })

  parameters = jsonencode({
    effect = {
      type         = "String"
      defaultValue = "Audit"
      allowedValues = ["Audit", "Deny", "Disabled"]
    }
  })
}

resource "azurerm_subscription_policy_assignment" "mandatory_tags" {
  name                 = "assign-mandatory-tags"
  policy_definition_id = azurerm_policy_definition.mandatory_tags.id
  subscription_id       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  parameters             = jsonencode({ effect = { value = "Audit" } }) # -> "Deny" in Phase 2 Step 13
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "assign-allowed-locations"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  subscription_id       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  parameters             = jsonencode({
    listOfAllowedLocations = { value = ["centralindia", "southindia"] }
  })
}

data "azurerm_client_config" "current" {}
