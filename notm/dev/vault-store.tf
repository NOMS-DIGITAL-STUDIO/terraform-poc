data "aws_ssm_parameter" "api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_client_secret"
}

data "aws_ssm_parameter" "session-cookie-secret" {
  name = "/new-nomis/${lower(var.tags["Environment"])}/session_cookie_secret"
}

data "aws_ssm_parameter" "google-tag-manager-id" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/google_tag_manager_id"
}

data "aws_ssm_parameter" "appinsights_instrumentationkey" {
  name = "/${lower(var.tags["Environment"])}/appinsights_instrumentationkey"
}
