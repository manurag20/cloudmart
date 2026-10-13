output "firewall_id"         { value = azurerm_firewall.this.id }
output "firewall_private_ip" { value = azurerm_firewall.this.ip_configuration[0].private_ip_address }
