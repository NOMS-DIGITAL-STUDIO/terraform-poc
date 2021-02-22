terraform {
  backend "azurerm" {
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "digitalstudioinfraprod"
    subscription_id      = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    container_name       = "webops-prod"
    key                  = "webops-prod-terraform.tfstate"
  }
}
