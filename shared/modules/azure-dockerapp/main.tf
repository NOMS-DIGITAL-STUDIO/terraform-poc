variable "resource_group" {
  type = string
}

variable "location" {
  type = string
  default = "ukwest"
}

variable "app_name" {
  type    = string
}

variable "binding_hostname" {
  type    = string
}

variable "docker_image" {
  type    = string
}

variable "app_settings" {
  type = map
}

variable "ssl_cert_keyvault" {
  type = string
}

variable "tags" {
  type = map
}

resource "azurerm_app_service_plan" "service_plan" {
  name                = var.app_name
  kind                =  "linux"
  location            = var.location
  resource_group_name = var.resource_group
  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
  properties {
    reserved = true
  }
}

resource "azurerm_app_service" "docker_app" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group
  app_service_plan_id = azurerm_app_service_plan.service_plan.id

  app_settings = var.app_settings
}

resource "azurerm_template_deployment" "docker_app" {
  name                = var.app_name
  resource_group_name = var.resource_group
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/webapp-docker-image.template.json")

  parameters {
    app_name = azurerm_app_service.docker_app.name
    docker_image = var.docker_image
    app_serviceplan = azurerm_app_service_plan.service_plan.name
    hostname         = var.binding_hostname
    keyVaultId       = var.ssl_cert_keyvault
    keyVaultCertName = replace(var.binding_hostname, ".", "DOT")
    service          = var.tags["Service"]
    environment      = var.tags["Environment"]
  }
}
