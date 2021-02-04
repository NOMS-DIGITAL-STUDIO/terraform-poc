terraform {
  required_version = "~> 0.12.28"
  backend "azurerm" {
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "digitalstudioinfradev"
    subscription_id      = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    container_name       = "webops-dev"
    key                  = "webops-dev-terraform.tfstate"
  }
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
  version         = "2.0.0"
  features {}
}
