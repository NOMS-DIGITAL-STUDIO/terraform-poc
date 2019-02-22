variable "slackhook_app_id" {
  type    = "string"
  default = "592a1f64-d98e-46a1-8f1b-41e7a674249e"
}

variable "slackhook_app_oid" {
  type    = "string"
  default = "745faff5-eaed-448c-83ba-d659baa902f7"
}

resource "azurerm_template_deployment" "slackhook" {
  name                = "slackhook"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice.template.json")}"

  parameters {
    name        = "studio-slack-hook"
    service     = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
    workers     = "1"
    sku_name    = "S1"
    sku_tier    = "Standard"
  }
}

resource "azurerm_template_deployment" "insights" {
  name                = "${azurerm_template_deployment.slackhook.parameters.name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/insights.template.json")}"

  parameters {
    name         = "${azurerm_template_deployment.slackhook.parameters.name}"
    location     = "northeurope"                                                    // Not in UK yet
    service      = "${var.tags["Service"]}"
    environment  = "${var.tags["Environment"]}"
    appServiceId = "${azurerm_template_deployment.slackhook.outputs["resourceId"]}"
  }
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault = "${azurerm_key_vault.vault.name}"

    slack_webhook = "slack-webhook"
    client_secret = "slackhook-client-secret"
  }
}

resource "azurerm_template_deployment" "slackhook-config" {
  name                = "slackhook-config"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../slackhook-config.template.json")}"

  parameters {
    name                           = "${azurerm_template_deployment.slackhook.parameters.name}"
    SLACK_WEBHOOK                  = "${data.external.vault.result["slack_webhook"]}"
    KEYVAULT_URI                   = "${azurerm_key_vault.vault.vault_uri}"
    KEYVAULT_USER_PREFIX           = "slackhook-user-"
    KEYVAULT_CLIENT_ID             = "${var.slackhook_app_id}"
    KEYVAULT_CLIENT_SECRET         = "${data.external.vault.result["client_secret"]}"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
  }
}

module "slackhook" {
  source   = "../../shared/modules/slackhook"
  app_name = "${azurerm_template_deployment.slackhook.parameters.name}"
}

resource "azurerm_template_deployment" "slackhook-ssl" {
  name                = "slackhook-ssl"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-sslonly.template.json")}"

  parameters {
    name = "${azurerm_template_deployment.slackhook.parameters.name}"
  }
}

resource "azurerm_template_deployment" "slackhook-github" {
  name                = "slackhook-github"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/appservice-scm.template.json")}"

  parameters {
    name    = "${azurerm_template_deployment.slackhook.parameters.name}"
    repoURL = "https://github.com/ministryofjustice/slackhook.git"
    branch  = "master"
  }
}

resource "github_repository_webhook" "slackhook-deploy" {
  repository = "slackhook"

  name = "web"

  configuration {
    url          = "${azurerm_template_deployment.slackhook-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
