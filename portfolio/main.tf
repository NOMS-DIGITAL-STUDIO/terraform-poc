terraform {
    required_version = ">= 0.9.2"
    backend "azure" {
        resource_group_name = "webops"
        storage_account_name = "nomsstudiowebops"
        container_name = "terraform"
        key = "portfolio.terraform.tfstate"
        arm_subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        arm_tenant_id = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
    }
}

variable "app-name" {
    type = "string"
    default = "hmpps-portfolio"
}
variable "tags" {
    type = "map"
    default {
        Service = "Studio"
        Environment = "Dev"
    }
}

resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "app" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../shared/appservice.template.json")}"
    parameters {
        name = "${var.app-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        workers = "1"
    }
}

resource "azurerm_template_deployment" "app-whitelist" {
    name = "app-whitelist"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../shared/appservice-whitelist.template.json")}"

    parameters {
        name = "${var.app-name}"
        # ip1 = "${var.ips["office"]}"
        # subnet1 = "255.255.255.255"
        ip1 = "0.0.0.0"
        subnet1 = "0.0.0.0"
    }

    depends_on = ["azurerm_template_deployment.app"]
}

resource "azurerm_dns_cname_record" "app" {
    name = "portfolio"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "300"
    record = "${var.app-name}.azurewebsites.net"
    tags = "${var.tags}"
}

resource "azurerm_template_deployment" "app-hostname" {
    name = "app-hostname"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../shared/appservice-hostname.template.json")}"

    parameters {
        name = "${var.app-name}"
        hostname = "${azurerm_dns_cname_record.app.name}.${azurerm_dns_cname_record.app.zone_name}"
    }

    depends_on = ["azurerm_template_deployment.app"]
}

resource "azurerm_template_deployment" "app-github" {
    name = "app-github"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../shared/appservice-scm.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.app.parameters.name}"
        repoURL = "https://github.com/noms-digital-studio/hmpps-portfolio.git"
        branch = "master"
    }

    depends_on = ["azurerm_template_deployment.app"]
}

resource "github_repository_webhook" "app" {
  repository = "hmpps-portfolio"

  name = "web"
  configuration {
    url = "${azurerm_template_deployment.app-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}
