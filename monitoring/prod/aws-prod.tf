variable "aws_account_id" {
  type    = string
  default = "589133037702"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_az_a" {
  type    = string
  default = "eu-west-2a"
}

variable "aws_az_b" {
  type    = string
  default = "eu-west-2b"
}

provider "aws" {
  allowed_account_ids = [var.aws_account_id]
  region              = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform"
  }
}

provider "azurerm" {
  version = "=2.38.0"
  features {}
}

locals {
  elb_ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

locals {
  azure_dns_zone_name = "service.hmpps.dsd.io"
  azure_dns_zone_rg   = "webops-prod"
}
