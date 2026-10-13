output "hub_vnet_id"           { value = module.hub.vnet_id }
output "app_vnet_id"           { value = module.spoke_app.vnet_id }
output "app_subnet_ids"        { value = module.spoke_app.subnet_ids }
output "ops_vnet_id"           { value = module.spoke_ops.vnet_id }
output "ops_subnet_ids"        { value = module.spoke_ops.subnet_ids }
output "firewall_private_ip"   { value = module.firewall.firewall_private_ip }
output "dns_zone_ids"          { value = { for k, z in azurerm_private_dns_zone.this : k => z.id } }
