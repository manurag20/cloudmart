# LLD 6.1 — Standard tier (Premium needed for private endpoints is skipped
# for cost — HLD risk R-05; reached via Entra RBAC on the public endpoint)
resource "azurerm_servicebus_namespace" "this" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_servicebus_topic" "orders" {
  name                  = "orders"
  namespace_id          = azurerm_servicebus_namespace.this.id
  default_message_ttl   = "P1D"
}

resource "azurerm_servicebus_subscription" "payment" {
  name                               = "payment"
  topic_id                           = azurerm_servicebus_topic.orders.id
  max_delivery_count                 = 5
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_subscription" "invoice" {
  name                                  = "invoice"
  topic_id                              = azurerm_servicebus_topic.orders.id
  max_delivery_count                    = 5
  dead_lettering_on_message_expiration  = true
}

# LLD 6.1 SQL filter — invoice subscription only receives PaymentCompleted
resource "azurerm_servicebus_subscription_rule" "invoice_filter" {
  name            = "payment-completed-only"
  subscription_id = azurerm_servicebus_subscription.invoice.id
  filter_type     = "SqlFilter"
  sql_filter      = "EventType = 'PaymentCompleted'"
}

# Added when writing the application code (LLD 6.2 note in Implementation
# Guide Step 5/8.5) — lets Event Grid deliver into a queue instead of a raw
# HTTPS webhook, so notification-worker can stay ingress-free like payment-svc.
resource "azurerm_servicebus_queue" "invoice_notifications" {
  name          = "sbq-invoice-notifications"
  namespace_id  = azurerm_servicebus_namespace.this.id
  max_delivery_count = 5
}
