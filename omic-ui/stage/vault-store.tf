data "aws_ssm_parameter" "api-client-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/api_client_secret"
}

data "aws_ssm_parameter" "session-cookie-secret" {
  name = "/new-nomis/${lower(var.tags["Environment"])}/session_cookie_secret"
}
