data "aws_ssm_parameter" "jwt-public-key" {
  name = "/${lower(var.tags["Service"])}/${lower(var.tags["Environment"])}/jwt_public_key"
}

