terraform {
  required_version = "~> 0.12.28"
  backend "azurerm" {
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "digitalstudioinfraprod"
    subscription_id      = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    container_name       = "webops-prod"
    key                  = "webops-prod-terraform.tfstate"
  }
}
provider "azurerm" {
  tenant_id       = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
  subscription_id = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
  version         = "2.0.0"
  features {}
}
