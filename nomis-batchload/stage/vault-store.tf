data "aws_ssm_parameter" "api-client-secret" {
  name = "/${lower(replace(var.tags["Service"], " ", "-"))}/${lower(var.tags["Environment"])}/api_client_secret"
}

data "aws_ssm_parameter" "admin-api-client-secret" {
  name = "/${lower(replace(var.tags["Service"], " ", "-"))}/${lower(var.tags["Environment"])}/admin_api_client_secret"
}
