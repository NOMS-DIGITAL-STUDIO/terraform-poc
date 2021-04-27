terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.48.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "1.4.0"
    }

  }
  required_version = ">= 0.14"
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383" # NOMS Digital Studio Production 1
  features {}
}

provider "azurerm" {
  alias           = "apvs"
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "19c0e044-6167-4048-a817-7ac7b4323f06" # APVS Production
  features {}
}
