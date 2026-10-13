# LLD 6.2 — BlobCreated under invoices/ delivers into the Service Bus queue
resource "azurerm_eventgrid_system_topic" "storage" {
  name                   = var.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = var.storage_account_id
  topic_type              = "Microsoft.Storage.StorageAccounts"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "invoice_created" {
  name                = "evgs-invoice-created"
  system_topic         = azurerm_eventgrid_system_topic.storage.name
  resource_group_name  = var.resource_group_name

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/invoices/"
  }

  service_bus_queue_endpoint_id = var.destination_queue_id

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440 # 24h, in minutes
  }
}
