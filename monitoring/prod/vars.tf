variable "environment-name" {
  type    = string
  default = "prod"
}

variable "application-name" {
  default = "monitoring"
}

variable "key-pair-name" {
  default = "cw_prod"
}

variable "dns-zone-name" {
  default = "service.hmpps.dsd.io"
}

variable "dns-zone-rg" {
  default = "webops-prod"
}
