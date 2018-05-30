
data "aws_ssm_parameter" "api-gateway-token" {
    name  = "/prisonstaffhub/dev/api_gateway_token"
}

data "aws_ssm_parameter" "api-client-secret" {
    name  = "/prisonstaffhub/dev/api_client_secret"
}

data "aws_ssm_parameter" "api-gateway-private-key" {
    name  = "/prisonstaffhub/dev/api_gateway_private_key"
}