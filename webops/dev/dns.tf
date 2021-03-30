resource "azurerm_dns_zone" "noms" {
  name                = "noms.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_zone" "hmpps" {
  name                = "hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_zone" "hwpv" {
  name                = "hwpv.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags = {
    application      = "HWPV"
    service          = "HWPV"
    environment_name = "devtest"
  }
}

#hwpv
variable "hwpv-cnames" {
  type = list(any)
  default = [
    { "ci" = "00b0444e-6f89-4290-8aa7-c8a48a799827.cloudapp.net." },
    { "dev-ci" = "ba34e1da-e6d6-4104-bf7b-e04b2f359042.cloudapp.net." },
    { "dev-external-web" = "7cf9cadd-ce00-4f7d-b619-c0fae0fcd77c.cloudapp.net." },
    { "dev-internal-web" = "7cf9cadd-ce00-4f7d-b619-c0fae0fcd77c.cloudapp.net." },
    { "stg-external-web" = "a3ae59d8-509d-4e85-a802-63130d254488.cloudapp.net." },
    { "stg-internal-web" = "a3ae59d8-509d-4e85-a802-63130d254488.cloudapp.net." },
    { "test-external-web" = "8390868f-f629-4c84-b997-47bdf6f0e463.cloudapp.net." },
    { "test-internal-web" = "8390868f-f629-4c84-b997-47bdf6f0e463.cloudapp.net." }
  ]
}

resource "azurerm_dns_cname_record" "cname" {
  count               = length(var.hwpv-cnames)
  name                = element(keys(var.hwpv-cnames[count.index]), 0)
  zone_name           = azurerm_dns_zone.hwpv.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = element(values(var.hwpv-cnames[count.index]), 0)
  tags = {
    application      = "HWPV"
    service          = "HWPV"
    environment_name = "devtest"
  }
}

#note - need to remove the record from https://github.com/ministryofjustice/dps-infra-assessment-api/blob/master/aks_infra/dns.tf
resource "azurerm_dns_ns_record" "protoassessment-api" {
  name                = "proto.assessment-api"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-04.azure-dns.com.", "ns3-04.azure-dns.org.", "ns2-04.azure-dns.net.", "ns4-04.azure-dns.info."]
  tags = {
    "business_unit" = "dps"
    "environment"   = "t0"
    "service"       = "assessment-api-gw-t0"
  }
}

resource "azurerm_dns_ns_record" "check-my-diary-dev" {
  name                = "check-my-diary-dev"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-03.azure-dns.com.", "ns2-03.azure-dns.net.", "ns3-03.azure-dns.org.", "ns4-03.azure-dns.info."]
}

resource "azurerm_dns_ns_record" "check-my-diary-preprod" {
  name                = "check-my-diary-preprod"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-07.azure-dns.com.", "ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns4-07.azure-dns.info."]
}

resource "azurerm_dns_ns_record" "check-my-diary-prod" {
  name                = "check-my-diary-prod"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-04.azure-dns.com.", "ns2-04.azure-dns.net.", "ns3-04.azure-dns.org.", "ns4-04.azure-dns.info."]
}


resource "azurerm_dns_ns_record" "digital-prisons" {
  name                = "dp"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-08.azure-dns.com.", "ns2-08.azure-dns.net.", "ns3-08.azure-dns.org.", "ns4-08.azure-dns.info."]
}

#hpa-stage in iis project that needs moving to here
resource "azurerm_dns_cname_record" "hpa-stage" {
  name                = "hpa-stage"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = "iis-stage.azurewebsites.net"
  tags = {
    "Environment" = "Stage"
    "Service"     = "IIS"
  }
}

resource "azurerm_dns_ns_record" "hwpv" {
  name                = "hwpv"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-04.azure-dns.com.", "ns2-04.azure-dns.net.", "ns3-04.azure-dns.org.", "ns4-04.azure-dns.info."]
}

resource "azurerm_dns_cname_record" "ndelius-interface" {
  name                = "ndelius-interface"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = "ndelius-dev.ukwest.cloudapp.azure.com"
}


resource "azurerm_dns_cname_record" "offloc-stage" {
  name                = "offloc-stage"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = "offloc-stage.azurewebsites.net"
}

resource "azurerm_dns_ns_record" "offloc-stage-zone" {
  name                = "offloc-stage-zone"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  records             = ["ns1-03.azure-dns.com.", "ns2-03.azure-dns.net.", "ns3-03.azure-dns.org.", "ns4-03.azure-dns.info."]
}

resource "azurerm_dns_ns_record" "service-hmpps" {
  name                = "service"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-06.azure-dns.com.", "ns2-06.azure-dns.net.", "ns3-06.azure-dns.org.", "ns4-06.azure-dns.info."]

}

resource "azurerm_dns_ns_record" "wmt" {
  name                = "wmt"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-01.azure-dns.com.", "ns2-01.azure-dns.net.", "ns3-01.azure-dns.org.", "ns4-01.azure-dns.info."]

}

resource "azurerm_dns_ns_record" "probation" {
  name                = "probation"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns-1247.awsdns-27.org.", "ns-1910.awsdns-46.co.uk.", "ns-244.awsdns-30.com.", "ns-972.awsdns-57.net."]

}

resource "azurerm_dns_ns_record" "mgmt-devtest" {
  name                = "mgmt-devtest"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-08.azure-dns.com.", "ns2-08.azure-dns.net.", "ns3-08.azure-dns.org.", "ns4-08.azure-dns.info."]

  tags = {
    application      = "Management"
    component        = "web"
    environment_name = "devtest"
    service          = "FixNGo"
  }

}

resource "azurerm_dns_ns_record" "mgmt-prod" {
  name                = "mgmt-prod"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-03.azure-dns.com.", "ns2-03.azure-dns.net.", "ns3-03.azure-dns.org.", "ns4-03.azure-dns.info."]

  tags = {
    application      = "Management"
    component        = "web"
    environment_name = "devtest"
    service          = "FixNGo"
  }

}

resource "azurerm_dns_cname_record" "test-ndelius-interface" {
  name                = "test-ndelius-interface"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "ndelius-dev.ukwest.cloudapp.azure.com"
  ttl                 = "3600"
}

resource "azurerm_dns_cname_record" "rsr-dev" {
  name                = "rsr-dev"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "rsr-dev.azurewebsites.net"
  ttl                 = "300"
}

resource "azurerm_dns_cname_record" "search" {
  name                = "search"
  zone_name           = azurerm_dns_zone.noms.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "search-noms-api.dsd.io"
  ttl                 = "300"
}
