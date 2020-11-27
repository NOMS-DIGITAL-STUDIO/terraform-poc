variable "app-name" {
  type    = string
  default = "rsr-prod"
}

variable "tags" {
  type = map

  default = {
    Service     = "RSR"
    Environment = "Prod"
  }
}

resource "azurerm_resource_group" "group" {
  name     = var.app-name
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_storage_account" "storage" {
  name                      = "${replace(var.app-name, "-", "")}storage"
  resource_group_name       = azurerm_resource_group.group.name
  location                  = azurerm_resource_group.group.location
  account_tier              = "Standard"
  account_kind              = "Storage"
  account_replication_type  = "RAGRS"
  enable_https_traffic_only = false

  tags = var.tags
}

resource "azurerm_key_vault" "vault" {
  name                = var.app-name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  sku_name = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    certificate_permissions = var.azure_certificate_permissions_all
    key_permissions         = []
    secret_permissions      = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}

resource "azurerm_app_service_plan" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }

  tags = var.tags
}

resource "azurerm_app_service" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.app.id

  tags = var.tags

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION   = "6.9.1"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
  }
}

resource "azurerm_application_insights" "insights" {
  name                = var.app-name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 0
}

resource "azurerm_dns_cname_record" "rsr" {
  name                = "rsr"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = var.tags
}

resource "azurerm_template_deployment" "rsr-ssl" {
  name                = "rsr-ssl"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-ssl.template.json")

  parameters = {
    name             = azurerm_app_service.app.name
    hostname         = "${azurerm_dns_cname_record.rsr.name}.${azurerm_dns_cname_record.rsr.zone_name}"
    keyVaultId       = azurerm_key_vault.vault.id
    keyVaultCertName = replace("${azurerm_dns_cname_record.rsr.name}.${azurerm_dns_cname_record.rsr.zone_name}", ".", "DOT")
    service          = var.tags["Service"]
    environment      = var.tags["Environment"]
  }

  depends_on = [azurerm_app_service.app]
}

module "slackhook-rsr" {
  source             = "../../shared/modules/slackhook"
  app_name           = azurerm_app_service.app.name
  channels           = ["api-accelerator", "shef_changes"]
  azure_subscription = "production"
}
