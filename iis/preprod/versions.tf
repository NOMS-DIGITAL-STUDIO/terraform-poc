terraform {
  required_providers {
    azurerm = {
      version = "2.48.0"
      source  = "hashicorp/azurerm"
    }
    github = {
      source = "integrations/github"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.14"
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  features {}
}
