resource "azurerm_template_deployment" "fng-collection" {
  name                = "fng-jobs"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/scheduler-collection.template.json")}"

  parameters {
    name        = "fng-jobs"
    service     = "${var.tags["Service"]}"
    environment = "${var.tags["Environment"]}"
  }
}

data "external" "fng-vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault = "${azurerm_key_vault.vault.name}"

    oms_circle_token = "oms-circle-token"
  }
}

resource "azurerm_template_deployment" "fng-oms-computers" {
  name                = "fng-oms-computers"
  resource_group_name = "${azurerm_resource_group.group.name}"
  deployment_mode     = "Incremental"
  template_body       = "${file("../../shared/scheduler-job.template.json")}"

  parameters {
    collection    = "${azurerm_template_deployment.fng-collection.parameters.name}"
    name          = "fng-oms-computers"
    service       = "${var.tags["Service"]}"
    environment   = "${var.tags["Environment"]}"
    uri           = "https://circleci.com/api/v1.1/project/github/ministryofjustice/hmpps-azure-oms/tree/master"
    body          = "build_parameters[CIRCLE_JOB]=report"
    contentType   = "application/x-www-form-urlencoded"
    authorization = "Basic ${base64encode("${data.external.fng-vault.result.oms_circle_token}:")}"
  }
}
