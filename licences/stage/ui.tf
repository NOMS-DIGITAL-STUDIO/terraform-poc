variable "ui-name" {
  type    = "string"
  default = "licences-stage"
}

resource "azurerm_app_service_plan" "ui" {
  name                = "${var.ui-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
}

resource "azurerm_app_service" "ui" {
  name                = "${var.ui-name}"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.ui.id}"

  app_settings {
    WEBSITE_NODE_DEFAULT_VERSION = "8.4.0"

    NODE_ENV          = "production"
    SESSION_SECRET    = "${random_id.session-secret.b64}"
    DB_USER           = "ui"
    DB_PASS           = "${random_id.sql-ui-password.b64}"
    DB_SERVER         = "${module.sql.db_server}"
    DB_NAME           = "${module.sql.db_name}"
    NOMIS_API_URL     = "https://noms-api-dev.dsd.io/elite2api-stage"
    ENABLE_TEST_UTILS = true

    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.insights.instrumentation_key}"

    NOMIS_GW_TOKEN = "${data.external.vault.result.elite_api_gateway_token}"
    NOMIS_GW_KEY   = "${data.external.vault.result.elite_api_gateway_private_key}"
  }
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault = "${azurerm_key_vault.vault.name}"

    elite_api_gateway_token       = "elite-api-gateway-token"
    elite_api_gateway_private_key = "elite-api-gateway-private-key"
  }
}

resource "azurerm_template_deployment" "ui-ssl" {
  name                = "ui-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-ssl.template.json")}"

  parameters {
    name             = "${azurerm_app_service.ui.name}"
    hostname         = "${azurerm_dns_cname_record.ui.name}.${azurerm_dns_cname_record.ui.zone_name}"
    keyVaultId       = "${azurerm_key_vault.vault.id}"
    keyVaultCertName = "${replace("${azurerm_dns_cname_record.ui.name}.${azurerm_dns_cname_record.ui.zone_name}", ".", "DOT")}"
    service          = "${var.tags["Service"]}"
    environment      = "${var.tags["Environment"]}"
  }
}

resource "azurerm_template_deployment" "ui-github" {
  name                = "ui-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name    = "${azurerm_app_service.ui.name}"
    repoURL = "https://github.com/noms-digital-studio/licences"
    branch  = "deploy-to-stage"
  }
}

resource "github_repository_webhook" "ui-deploy" {
  repository = "licences"

  name = "web"

  configuration {
    url          = "${azurerm_template_deployment.ui-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

resource "azurerm_template_deployment" "ui-weblogs" {
  name                = "ui-weblogs"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-weblogs.template.json")}"

  parameters {
    name       = "${azurerm_app_service.ui.name}"
    storageSAS = "${data.external.sas-url.result["url"]}"
  }
}

module "slackhook-ui" {
  source   = "../../shared/modules/slackhook"
  app_name = "${azurerm_app_service.ui.name}"
  channels = ["licences-dev"]
}

resource "azurerm_dns_cname_record" "ui" {
  name                = "licences-stage"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "${var.ui-name}.azurewebsites.net"
  tags                = "${var.tags}"
}
