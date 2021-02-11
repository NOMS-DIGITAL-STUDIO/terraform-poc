terraform {
  required_version = "~> 0.12.28"
  backend "azurerm" {
    resource_group_name  = "iis-preprod"
    storage_account_name = "iispreprodstorage"
    subscription_id      = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    container_name       = "terraform"
    key                  = "iis-preprod.terraform.tfstate"
  }
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  version         = "2.45.1"
  features {}
}
