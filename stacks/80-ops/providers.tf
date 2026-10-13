# Copy this into every stack (10-governance through 90-observability) as providers.tf.
# Each stack's `key=` in the backend-config flag at init time is the only thing that differs.
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    local   = { source = "hashicorp/local", version = "~> 2.5" }
  }
  backend "azurerm" {}   # values supplied via: terraform init -backend-config=../backend.hcl -backend-config="key=<stack>.tfstate"
}
provider "azurerm" {
  features {}
}
