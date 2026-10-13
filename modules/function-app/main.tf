# LLD 6.3 — Consumption plan, Python v2 model, Service Bus trigger
resource "azurerm_service_plan" "fn" {
  name                = "asp-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  service_plan_id             = azurerm_service_plan.fn.id
  storage_account_name        = var.storage_account_name
  storage_account_access_key  = var.storage_account_access_key
  tags                        = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  site_config {
    application_stack {
      python_version = "3.12"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME               = "python"
    AzureWebJobsStorage__accountName        = var.storage_account_name
    AzureWebJobsStorage__credential         = "managedidentity"
    AzureWebJobsStorage__clientId           = var.identity_id
    ServiceBusConnection__fullyQualifiedNamespace = var.servicebus_namespace
    ServiceBusConnection__credential        = "managedidentity"
    ServiceBusConnection__clientId          = var.identity_id
    APPLICATIONINSIGHTS_CONNECTION_STRING   = var.app_insights_connection_string
  }
}
