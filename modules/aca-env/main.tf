# LLD 7.1 — workload profiles environment (NOT plain Consumption-only),
# internal only, VNet-integrated — required for the UDR-via-Firewall egress
resource "azurerm_container_app_environment" "this" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id        = var.subnet_id
  internal_load_balancer_enabled  = true
  tags                             = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  log_analytics_workspace_id = var.log_analytics_workspace_id
}
