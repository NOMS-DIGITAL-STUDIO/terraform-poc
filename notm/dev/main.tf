variable "app-name" {
  type    = "string"
  default = "notm-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "NOTM"
    Environment = "Dev"
  }
}

resource "random_id" "session-secret" {
  byte_length = 40
}

resource "azurerm_resource_group" "group" {
  name     = "${var.app-name}"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
  name                     = "${replace(var.app-name, "-", "")}storage"
  resource_group_name      = "${azurerm_resource_group.group.name}"
  location                 = "${azurerm_resource_group.group.location}"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  enable_blob_encryption   = true

  tags = "${var.tags}"
}

variable "log-containers" {
  type    = "list"
  default = ["web-logs"]
}

resource "azurerm_storage_container" "logs" {
  count                 = "${length(var.log-containers)}"
  name                  = "${var.log-containers[count.index]}"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  storage_account_name  = "${azurerm_storage_account.storage.name}"
  container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.app-name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  location            = "${azurerm_resource_group.group.location}"

  sku {
    name = "standard"
  }

  tenant_id = "${var.azure_tenant_id}"

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_webops_group_oid}"
    key_permissions    = []
    secret_permissions = "${var.azure_secret_permissions_all}"
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_app_service_oid}"
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_jenkins_sp_oid}"
    key_permissions    = []
    secret_permissions = ["set"]
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_notm_group_oid}"
    key_permissions    = []
    secret_permissions = "${var.azure_secret_permissions_all}"
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = "${var.tags}"
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault                   = "${azurerm_key_vault.vault.name}"
    google_analytics_id     = "google-analytics-id"
    api_client_secret       = "api-client-secret"
  }
}

resource "azurerm_app_service_plan" "app" {
  name                = "${var.app-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }

  tags = "${var.tags}"
}

resource "azurerm_app_service" "app" {
  name                = "${var.app-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.app.id}"

  app_settings {
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
    NODE_ENV                       = "production"
    API_ENDPOINT_URL               = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/"
    KEYWORKER_API_URL              = "https://keyworker-api-dev.hmpps.dsd.io/"
    OMIC_UI_URL                    = "https://omic-dev.hmpps.dsd.io/"
    USE_API_GATEWAY_AUTH           = "no"
    API_CLIENT_ID                  = "elite2apiclient"
    API_CLIENT_SECRET              = "${data.external.vault.result.api_client_secret}"
    GOOGLE_ANALYTICS_ID            = "${data.external.vault.result.google_analytics_id}"
    HMPPS_COOKIE_NAME              = "hmpps-session-dev"
    HMPPS_COOKIE_DOMAIN            = "hmpps.dsd.io"
    SESSION_COOKIE_SECRET          = "${random_id.session-secret.b64}"
    WEBSITE_NODE_DEFAULT_VERSION   = "8.10.0"
  }

  tags = "${var.tags}"
}

data "external" "sas-url" {
  program = ["python3", "../../tools/container-sas-url-cli-auth.py"]

  query {
    subscription_id = "${var.azure_subscription_id}"
    tenant_id       = "${var.azure_tenant_id}"
    resource_group  = "${azurerm_resource_group.group.name}"
    storage_account = "${azurerm_storage_account.storage.name}"
    container       = "web-logs"
    permissions     = "rwdl"
    start_date      = "2017-05-15T00:00:00Z"
    end_date        = "2217-05-15T00:00:00Z"
  }
}

resource "azurerm_template_deployment" "webapp-weblogs" {
  name                = "webapp-weblogs"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-weblogs.template.json")}"

  parameters {
    name       = "${azurerm_app_service.app.name}"
    storageSAS = "${data.external.sas-url.result["url"]}"
  }
}

resource "azurerm_template_deployment" "insights" {
  name                = "${var.app-name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/insights.template.json")}"

  parameters {
    name        = "${var.app-name}"
    location    = "northeurope"                // Not in UK yet
    service     = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }
}

resource "azurerm_template_deployment" "webapp-ssl" {
  name                = "webapp-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name             = "${azurerm_app_service.app.name}"
    hostname         = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
    keyVaultId       = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}", ".", "DOT")}"
    service          = "${var.tags["Service"]}"
    environment      = "${var.tags["Environment"]}"
  }
}

module "slackhook" {
  source   = "../../shared/modules/slackhook"
  app_name = "${azurerm_app_service.app.name}"
  channels = ["nomisonthemove"]
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "notm-dev"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = "${var.tags}"
}