data "aws_ssm_parameter" "api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_client_secret"
}

data "aws_ssm_parameter" "admin-api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/admin_api_client_secret"
}

data "aws_ssm_parameter" "tag-manager-api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/tag_manager_client_secret"
}

data "aws_ssm_parameter" "developer-list" {
  name = "developers"
}
