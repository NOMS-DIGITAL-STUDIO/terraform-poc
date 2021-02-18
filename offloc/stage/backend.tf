terraform {
  backend "azurerm" {
    resource_group_name  = "offloc-stage"
    storage_account_name = "offlocstagestorage"
    subscription_id      = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    container_name       = "terraform"
    key                  = "offloc-stage.terraform.tfstate"
  }
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  features {}
}
