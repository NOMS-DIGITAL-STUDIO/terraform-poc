resource "azurerm_dns_zone" "noms" {
  name                = "noms.dsd.io"
  resource_group_name = azurerm_resource_group.group.name

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_zone" "hmpps" {
  name                = "hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "service-hmpps" {
  name                = "service"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-06.azure-dns.com.", "ns2-06.azure-dns.net.", "ns3-06.azure-dns.org.", "ns4-06.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "digital-prisons" {
  name                = "dp"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-08.azure-dns.com.", "ns2-08.azure-dns.net.", "ns3-08.azure-dns.org.", "ns4-08.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "wmt" {
  name                = "wmt"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-01.azure-dns.com.", "ns2-01.azure-dns.net.", "ns3-01.azure-dns.org.", "ns4-01.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "nomis-api" {
  name                = "nomis-api"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-07.azure-dns.com.", "ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns4-07.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "offloc" {
  name                = "offloc-stage-zone"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-03.azure-dns.com.", "ns2-03.azure-dns.net.", "ns3-03.azure-dns.org.", "ns4-03.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "probation" {
  name                = "probation"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns-1247.awsdns-27.org.", "ns-1910.awsdns-46.co.uk.", "ns-244.awsdns-30.com.", "ns-972.awsdns-57.net."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "hwpv" {
  name                = "hwpv"
  zone_name           = azurerm_dns_zone.hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-04.azure-dns.com.", "ns2-04.azure-dns.net.", "ns3-04.azure-dns.org.", "ns4-04.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_cname_record" "search" {
  name                = "search"
  zone_name           = azurerm_dns_zone.noms.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = "search-noms-api.dsd.io"
}
