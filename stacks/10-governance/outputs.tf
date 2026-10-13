output "resource_group_names" { value = { for k, rg in azurerm_resource_group.rg : k => rg.name } }
output "log_analytics_id"          { value = module.monitoring.log_analytics_id }
output "app_insights_id"           { value = module.monitoring.app_insights_id }
output "log_analytics_customer_id" { value = module.monitoring.log_analytics_customer_id }
output "log_analytics_shared_key" {
  value     = module.monitoring.log_analytics_shared_key
  sensitive = true
}
output "app_insights_connection_string" {
  value     = module.monitoring.app_insights_connection_string
  sensitive = true
}
