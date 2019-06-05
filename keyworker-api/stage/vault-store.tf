data "aws_ssm_parameter" "jwt-public-key" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/jwt_public_key"
}

data "aws_ssm_parameter" "omic-admin-secret" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/omic_admin_secret"
}

data "aws_ssm_parameter" "appinsights_instrumentationkey" {
  name = "/${lower(var.tags["Environment"])}/appinsights_instrumentationkey"
}
