variable "app-name" {
    type = "string"
    default = "csra-prod"
}
variable "tags" {
    type = "map"
    default {
        Service = "CSRA"
        Environment = "Prod"
    }
}

resource "random_id" "sql-app-password" {
    byte_length = 32
}
resource "random_id" "sql-reader-password" {
    byte_length = 32
}

resource "azurerm_resource_group" "group" {
    name = "${var.app-name}"
    location = "ukwest"
    tags = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
    name = "${replace(var.app-name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_tier = "Standard"
    account_replication_type = "RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

variable "log-containers" {
    type = "list"
    default = ["web-logs"]
}
resource "azurerm_storage_container" "logs" {
    count = "${length(var.log-containers)}"
    name = "${var.log-containers[count.index]}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    storage_account_name = "${azurerm_storage_account.storage.name}"
    container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    sku {
        name = "standard"
    }
    tenant_id = "${var.azure_tenant_id}"

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_webops_group_oid}"
        key_permissions = []
        secret_permissions = "${var.azure_secret_permissions_all}"
    }

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_app_service_oid}"
        key_permissions = []
        secret_permissions = ["get"]
    }

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_jenkins_sp_oid}"
        key_permissions = []
        secret_permissions = ["set"]
    }

    enabled_for_deployment = false
    enabled_for_disk_encryption = false
    enabled_for_template_deployment = true

    tags = "${var.tags}"
}

module "sql" {
    source = "../../shared/modules/azure-sql"
    name = "${var.app-name}"
    resource_group = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    administrator_login = "csra"
    firewall_rules = [
        {
            label = "Sheffield Digital Studio"
            start = "${var.ips["office"]}"
            end = "${var.ips["office"]}"
        },
    ]
    audit_storage_account = "${azurerm_storage_account.storage.name}"
    edition = "Basic"
    collation = "SQL_Latin1_General_CP1_CI_AS"
    tags = "${var.tags}"

    db_users = {
        app = "${random_id.sql-app-password.b64}"
        reader = "${random_id.sql-reader-password.b64}"
    }

    setup_queries = [
        "GRANT SELECT TO reader"
    ]
}

resource "azurerm_sql_firewall_rule" "app-access" {
    count = "${length(split(",", azurerm_template_deployment.webapp.outputs["ips"]))}"
    name = "Application IP ${count.index}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    server_name = "${module.sql.server_name}"
    start_ip_address = "${element(split(",", azurerm_template_deployment.webapp.outputs["ips"]), count.index)}"
    end_ip_address = "${element(split(",", azurerm_template_deployment.webapp.outputs["ips"]), count.index)}"
}

resource "azurerm_template_deployment" "webapp" {
    name = "webapp"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice.template.json")}"
    parameters {
        name = "${var.app-name}"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        workers = "2"
        sku_name = "S2"
        sku_tier = "Standard"
    }
}

data "external" "sas-url" {
    program = ["node", "../../tools/container-sas-url-cli-auth.js"]
    query {
        subscription_id = "${var.azure_subscription_id}"
        tenant_id = "${var.azure_tenant_id}"
        resource_group = "${azurerm_resource_group.group.name}"
        storage_account = "${azurerm_storage_account.storage.name}"
        container = "web-logs"
        permissions = "rwdl"
        start_date = "2017-05-15T00:00:00Z"
        end_date = "2217-05-15T00:00:00Z"
    }
}

resource "azurerm_template_deployment" "webapp-weblogs" {
    name = "webapp-weblogs"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-weblogs.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        storageSAS = "${data.external.sas-url.result["url"]}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "insights" {
    name = "${var.app-name}"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/insights.template.json")}"
    parameters {
        name = "${var.app-name}"
        location = "northeurope" // Not in UK yet
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
        appServiceId = "${azurerm_template_deployment.webapp.outputs["resourceId"]}"
    }
}

data "external" "vault" {
    program = ["node", "../../tools/keyvault-data-cli-auth.js"]
    query {
        vault = "${azurerm_key_vault.vault.name}"

        viper_service_api_key = "viper-service-api-key"
        elite_api_gateway_token = "elite-api-gateway-token"
        elite_api_gateway_private_key = "elite-api-gateway-private-key"
    }
}

resource "azurerm_template_deployment" "webapp-config" {
    name = "webapp-config"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../webapp-config.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        NODE_ENV = "production"
        APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
        DB_URI = "mssql://app:${random_id.sql-app-password.b64}@${module.sql.db_server}:1433/${module.sql.db_name}?encrypt=true"
        VIPER_SERVICE_URL = "https://aap.service.hmpps.dsd.io/"
        VIPER_SERVICE_API_KEY = "${data.external.vault.result["viper_service_api_key"]}"
        ELITE2_URL = "https://noms-api-preprod.dsd.io/elite2api-prod/"
        ELITE2_API_GATEWAY_TOKEN = "${data.external.vault.result.elite_api_gateway_token}"
        ELITE2_API_GATEWAY_PRIVATE_KEY = "${data.external.vault.result.elite_api_gateway_private_key}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "webapp-whitelist" {
    name = "webapp-whitelist"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-whitelist.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        ip1 = "${var.ips["office"]}"
        # ip2 = "${var.ips["quantum"]}"
        ip3 = "${var.ips["health-kick"]}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

resource "azurerm_template_deployment" "webapp-ssl" {
    name = "webapp-ssl"
    resource_group_name = "${azurerm_resource_group.group.name}"
    deployment_mode = "Incremental"
    template_body = "${file("../../shared/appservice-ssl.template.json")}"

    parameters {
        name = "${azurerm_template_deployment.webapp.parameters.name}"
        hostname = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
        keyVaultId = "${azurerm_key_vault.vault.id}"
        keyVaultCertName = "csraDOTserviceDOThmppsDOTdsdDOTio"
        service = "${var.tags["Service"]}"
        environment = "${var.tags["Environment"]}"
    }

    depends_on = ["azurerm_template_deployment.webapp"]
}

module "slackhook" {
    source = "../../shared/modules/slackhook"
    app_name = "${azurerm_template_deployment.webapp.parameters.name}"
    azure_subscription = "production"
    channels = ["shef_changes", "csra"]
}

resource "azurerm_dns_cname_record" "cname" {
    name = "csra"
    zone_name = "service.hmpps.dsd.io"
    resource_group_name = "webops-prod"
    ttl = "300"
    record = "csra-prod.azurewebsites.net"
    tags {
      Service = "CSRA"
      Environment = "Prod"
    }
}
