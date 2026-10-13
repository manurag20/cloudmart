terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
  }
  # Deliberately NO backend block — this is the one stack that CREATES the
  # remote backend, so it has to run with local state first (LLD 9.3).
}
provider "azurerm" { features {} }
provider "azuread" {}
