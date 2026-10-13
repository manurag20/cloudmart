output "acr_login_server"    { value = module.acr.login_server }
output "aca_env_id"          { value = module.aca_env.id }
output "aca_env_default_domain" { value = module.aca_env.default_domain }
output "web_frontend_fqdn_hint" { value = "ca-web-frontend-${var.environment}.internal.${module.aca_env.default_domain}" }
