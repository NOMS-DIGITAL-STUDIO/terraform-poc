locals {
  env-name = "prod"
}

variable "tags" {
  type = map(any)
  default = {
    "application"      = "Management"
    "environment_name" = "prod"
    "service"          = "FixNGo"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "webops-prod"
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_storage_container" "terraform" {
  name                  = "webops-prod"
  storage_account_name  = "digitalstudioinfraprod"
  container_access_type = "private"
}
