variable "slackhook_app_id" {
  type    = string
  default = "cd8e65cd-0b83-4aa1-953e-966a1491b2b4"
}

variable "slackhook_app_oid" {
  type    = string
  default = "dc341896-ab17-48ac-83b9-b17416655c0b"
}

resource "azurerm_template_deployment" "slackhook" {
  name                = "slackhook"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice.template.json")

  parameters = {
    name        = "studio-slack-hook-prod"
    service     = var.tags["Service"]
    environment = var.tags["Environment"]
    workers     = "1"
    sku_name    = "S1"
    sku_tier    = "Standard"
  }
}

resource "azurerm_template_deployment" "insights" {
  name                = azurerm_template_deployment.slackhook.parameters.name
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/insights.template.json")

  parameters = {
    name         = azurerm_template_deployment.slackhook.parameters.name
    location     = "northeurope" // Not in UK yet
    service      = var.tags["Service"]
    environment  = var.tags["Environment"]
    appServiceId = azurerm_template_deployment.slackhook.outputs["resourceId"]
  }
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query = {
    vault = azurerm_key_vault.vault.name

    slack_webhook = "slack-webhook"
    client_secret = "slackhook-client-secret"
  }
}

resource "azurerm_template_deployment" "slackhook-config" {
  name                = "slackhook-config"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../slackhook-config.template.json")

  parameters = {
    name                           = azurerm_template_deployment.slackhook.parameters.name
    SLACK_WEBHOOK                  = data.external.vault.result["slack_webhook"]
    KEYVAULT_URI                   = azurerm_key_vault.vault.vault_uri
    KEYVAULT_USER_PREFIX           = "slackhook-user-"
    KEYVAULT_CLIENT_ID             = var.slackhook_app_id
    KEYVAULT_CLIENT_SECRET         = data.external.vault.result["client_secret"]
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_template_deployment.insights.outputs["instrumentationKey"]
  }
}

module "slackhook" {
  source             = "../../shared/modules/slackhook"
  app_name           = azurerm_template_deployment.slackhook.parameters.name
  azure_subscription = "production"
}

resource "azurerm_template_deployment" "slackhook-github" {
  name                = "slackhook-github"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-scm.template.json")

  parameters = {
    name    = azurerm_template_deployment.slackhook.parameters.name
    repoURL = "https://github.com/ministryofjustice/slackhook.git"
    branch  = "deploy"
  }
}

resource "github_repository_webhook" "slackhook-deploy" {
  repository = "slackhook"

  configuration {
    url          = "${azurerm_template_deployment.slackhook-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
