
data "aws_ssm_parameter" "api-gateway-token" {
    name  = "/omic-ui/dev/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
    name  = "/omic-ui/dev/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
    name  = "/omic-ui/dev/api_gateway_private_key"
}

data "aws_ssm_parameter" "appinsights-instrumentationkey" {
    name  = "/omic-ui/dev/appinsights_instrumentationkey"
}
