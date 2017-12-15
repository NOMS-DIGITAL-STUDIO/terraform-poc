variable "tags" {
    type = "map"
    default {
        Service = "Digital Hub v1"
        Environment = "dev"
    }
}

resource "azurerm_resource_group" "hubv1-dev" {
    name = "hmpps-hubv1-dev"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "hmpps-hubv1-webapp" {
    name = "hmpps-hubv1-dev"
    resource_group_name = "${azurerm_resource_group.hubv1-dev.name}"
    deployment_mode = "Incremental"
    template_body = "${file("./webapp.template.json")}"
    parameters {
        name = "hmpps-hubv1-dev"
        hostingEnvironment = ""
        hostingPlanName = "hmpps-hubv1-dev"
        location = "UK West"
        sku = "Free"
        workerSize = "0"
        serverFarmResourceGroup = "hmpps-hubv1-dev"
        skuCode = "F1"
        subscriptionId = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    }
}
