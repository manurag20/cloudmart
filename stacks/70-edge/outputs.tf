output "frontdoor_endpoint" { value = module.frontdoor.endpoint_hostname }
output "appgw_public_ip"    { value = module.appgw.public_ip }
output "appgw_id"           { value = module.appgw.id }
