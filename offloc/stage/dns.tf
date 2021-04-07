resource "azurerm_dns_zone" "offloc_stage_zone" {
  name                = "offloc-stage-zone.hmpps.dsd.io"
  resource_group_name = local.name

  soa_record {
    email         = "azuredns-hostmaster.microsoft.com"
    expire_time   = "2419200"
    host_name     = "ns1-03.azure-dns.com."
    minimum_ttl   = "300"
    refresh_time  = "3600"
    retry_time    = "300"
    serial_number = "1"
    ttl           = "3600"
  }

  tags = {
    Environment      = "stage"
    application      = "NonCore"
    environment_name = "devtest"
    service          = "NonCore"
  }
}

resource "azurerm_dns_ns_record" "zone_nameserver_record" {
  name                = "@"
  records             = ["ns1-03.azure-dns.com.", "ns2-03.azure-dns.net.", "ns3-03.azure-dns.org.", "ns4-03.azure-dns.info."]
  resource_group_name = local.name
  ttl                 = "172800"
  zone_name           = azurerm_dns_zone.offloc_stage_zone.name
}

resource "azurerm_dns_cname_record" "offloc_stage_www" {
  name                = "www"
  record              = "offloc-stage.azurewebsites.net"
  resource_group_name = local.name

  tags = {
    Environment = "stage"
    Service     = "offloc"
  }

  ttl       = "300"
  zone_name = azurerm_dns_zone.offloc_stage_zone.name
}
