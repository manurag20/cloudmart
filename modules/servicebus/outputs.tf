output "namespace_id"   { value = azurerm_servicebus_namespace.this.id }
output "namespace_name" { value = azurerm_servicebus_namespace.this.name }
output "namespace_fqdn" { value = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net" }
output "topic_id"       { value = azurerm_servicebus_topic.orders.id }
output "invoice_notifications_queue_id" { value = azurerm_servicebus_queue.invoice_notifications.id }
