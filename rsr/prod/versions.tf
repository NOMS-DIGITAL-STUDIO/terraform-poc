terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.55.0"
    }
    github = {
      source = "integrations/github"
    }
  }
  required_version = "= 0.15.5"
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  features {}
}
