terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm",
      version = "= 2.48.0",
    }
    github = {
      source  = "integrations/github",
      version = "= 4.5.0"
    }
    random = {
      source  = "hashicorp/random",
      version = "= 3.0.1"
    }
  }
  required_version = "= 0.14.11"
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  features {}
}
