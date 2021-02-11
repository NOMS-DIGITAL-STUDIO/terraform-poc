terraform {
  required_providers {
    azurerm = {
      version = ">= 2.46.1"
      source  = "hashicorp/azurerm"
    }
  }
  required_version = ">= 0.13"
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  features {}
}
