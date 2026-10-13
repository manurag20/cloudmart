locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_integration = local.governance_resource_group_names["integration"]
}

# LLD 6.1
module "servicebus" {
  source               = "../../modules/servicebus"
  namespace_name         = "sb-cm-${var.environment}-cin-01"
  location                = var.location
  resource_group_name      = local.rg_integration
  tags                       = local.tags
}

resource "azurerm_role_assignment" "sb_order_api_sender" {
  scope                = module.servicebus.topic_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id          = local.identity_principal_ids["order-api"]
}

resource "azurerm_role_assignment" "sb_payment_sender" {
  scope                = module.servicebus.topic_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id          = local.identity_principal_ids["payment-svc"]
}

resource "azurerm_role_assignment" "sb_namespace_payment_receiver" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id          = local.identity_principal_ids["payment-svc"]
}

resource "azurerm_role_assignment" "sb_namespace_invoice_fn_receiver" {
  scope                = module.servicebus.namespace_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id          = local.identity_principal_ids["invoice-fn"]
}

resource "azurerm_role_assignment" "sb_notification_receiver" {
  scope                = module.servicebus.invoice_notifications_queue_id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id          = local.identity_principal_ids["notification-worker"]
}

# LLD 6.2 — Event Grid delivering BlobCreated into the Service Bus queue
module "eventgrid" {
  source                 = "../../modules/eventgrid"
  name                     = "evgt-invoices-${var.environment}"
  storage_account_id        = local.storage_account_id
  resource_group_name        = local.rg_integration
  location                    = var.location
  destination_queue_id         = module.servicebus.invoice_notifications_queue_id
}

# LLD 6.3 — Function App, Service Bus trigger, writes to Blob
resource "azurerm_storage_account" "fn_storage" {
  # Functions need their own small storage account for AzureWebJobsStorage
  name                     = "stcmfn${var.environment}01"
  resource_group_name      = local.rg_integration
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                      = local.tags
}

module "invoice_fn" {
  source                          = "../../modules/function-app"
  name                              = "func-invoice-gen-${var.environment}"
  location                           = var.location
  resource_group_name                = local.rg_integration
  storage_account_name                 = azurerm_storage_account.fn_storage.name
  storage_account_access_key            = azurerm_storage_account.fn_storage.primary_access_key
  servicebus_namespace                   = module.servicebus.namespace_fqdn
  identity_id                             = local.identity_ids["invoice-fn"]
  app_insights_connection_string           = local.app_insights_connection_string
  tags                                      = local.tags
}
