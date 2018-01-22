variable "app_name" {
    type = "string"
    description = "name of the app service application"
}

variable "channels" {
    type = "list"
    description = "the slack channel(s) to notify"
    default = ["shef_webops"]
}

variable "azure_subscription" {
    type = "string"
    description = "either 'development' or 'production'"
    default = "development"
}

variable "azure_tenant_id" {
    type = "string"
    default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

resource "null_resource" "intermediates" {
    triggers = {
        azure_subscription_id = "${var.azure_subscription == "production"
            ? "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
            : "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
        }"
        vault = "${var.azure_subscription == "production"
            ? "webops-prod"
            : "webops-dev"
        }",
        hook_host = "${var.azure_subscription == "production"
            ? "studio-slack-hook-prod.azurewebsites.net"
            : "studio-slack-hook.azurewebsites.net"
        }"
    }
}

resource "random_id" "hook-password" {
    byte_length = 20
}
resource "null_resource" "create-hook-user" {
    triggers = {
        app = "${var.app_name}"
        password = "${random_id.hook-password.hex}"
        channels = "${jsonencode(var.channels)}"
    }
    provisioner "local-exec" {
        command = <<CMD
set -e

az keyvault secret set --vault-name '${null_resource.intermediates.triggers.vault}' \
    --name 'slackhook-user-${var.app_name}' \
    --value '${random_id.hook-password.hex}' \

${path.module}/kudu-webhook.py \
    --appName '${var.app_name}' \
    --urls '${base64encode(jsonencode(formatlist(
        "https://${var.app_name}:${random_id.hook-password.hex}@${null_resource.intermediates.triggers.hook_host}/kudu?channel=%s",
        var.channels
    )))}' \
CMD
    }
}
