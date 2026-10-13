locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_security = local.governance_resource_group_names["security"]
}

data "azurerm_client_config" "current" {}

# LLD 4.5 — Key Vault, RBAC mode, private endpoint only
module "keyvault" {
  source                     = "../../modules/keyvault"
  name                        = "kv-cmdevcin01"
  location                     = var.location
  resource_group_name          = local.rg_security
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  subnet_id                      = local.app_subnet_ids["snet-pe"]
  private_dns_zone_id             = local.dns_zone_ids["privatelink.vaultcore.azure.net"]
  purge_protection_enabled         = var.kv_purge_protection
  tags                              = local.tags
}

# LLD 4.3 — 5 user-assigned managed identities, one per backend service,
# plus a 6th for web-frontend (ACR pull only — it touches no data plane,
# so it gets no RBAC grants in 40-data/50-integration, unlike the other 5).
module "identities" {
  source               = "../../modules/identity"
  for_each              = toset(["order-api", "inventory-svc", "payment-svc", "invoice-fn", "notification-worker", "web-frontend"])
  name                  = "id-${each.key}-${var.environment}"
  location               = var.location
  resource_group_name     = local.rg_security
  tags                     = local.tags
}

# LLD 4.4 — Key Vault Secrets User for every app identity
resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = module.identities
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id          = each.value.principal_id
}

# LLD 4.1 — Entra app registration for customer sign-in, with the
# orders.readwrite scope that order-api checks in the JWT (Section 8.2)
resource "azuread_application" "customers" {
  display_name     = "cloudmart-customers"
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      id                         = "4a6c8f6e-0000-4000-8000-000000000001" # fixed GUID so re-applies don't drift
      value                       = "orders.readwrite"
      type                         = "User"
      admin_consent_description    = "Allows the app to read and write the signed-in user's orders"
      admin_consent_display_name   = "Read and write orders"
      user_consent_description      = "Allows the app to read and write your orders"
      user_consent_display_name     = "Read and write your orders"
      enabled                        = true
    }
  }
}

resource "azurerm_key_vault_secret" "entra_client_id" {
  name         = "entra-app-client-id"
  value        = azuread_application.customers.client_id
  key_vault_id = module.keyvault.id
}
