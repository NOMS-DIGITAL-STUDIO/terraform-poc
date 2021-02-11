terraform {
  backend "azurerm" {
    resource_group_name  = "iis-preprod"
    storage_account_name = "iispreprodstorage"
    subscription_id      = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    container_name       = "terraform"
    key                  = "iis-preprod.terraform.tfstate"
  }
}
