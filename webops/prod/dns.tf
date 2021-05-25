resource "azurerm_dns_zone" "service-hmpps" {
  name                = "service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_ns_record" "nomis-api" {
  name                = "nomis-api"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300
  records             = ["ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns1-07.azure-dns.com.", "ns4-07.azure-dns.info."]
}

output "service_hmpps_dsd_io_namesevers" {
  value = [azurerm_dns_zone.service-hmpps.name_servers]
}

resource "azurerm_dns_zone" "az_justice_gov_uk" {
  name                = "az.justice.gov.uk"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_zone" "studio_hosting" {
  name                = "studio-hosting.service.justice.gov.uk"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags

  soa_record {
    email         = "azuredns-hostmaster.microsoft.com"
    expire_time   = "2419200"
    host_name     = "ns1-07.azure-dns.com."
    minimum_ttl   = "300"
    refresh_time  = "3600"
    retry_time    = "300"
    serial_number = "1"
    ttl           = "3600"
  }

}

resource "azurerm_dns_ns_record" "studio_hosting_ns_record" {
  name                = "@"
  records             = ["ns1-07.azure-dns.com.", "ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns4-07.azure-dns.info."]
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "172800"
  zone_name           = azurerm_dns_zone.studio_hosting.name
}

resource "azurerm_dns_cname_record" "user_guide" {
  name                = "user-guide"
  record              = "ministryofjustice.github.io"
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "3600"
  zone_name           = azurerm_dns_zone.studio_hosting.name
}

resource "azurerm_dns_ns_record" "nomis_ns_record" {
  name                = "nomis"
  records             = ["ns1-08.azure-dns.com.", "ns2-08.azure-dns.net.", "ns3-08.azure-dns.org.", "ns4-08.azure-dns.info."]
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "3600"
}
resource "azurerm_dns_ns_record" "oasys_ns_record" {
  name                = "oasys"
  records             = ["ns1-07.azure-dns.com.", "ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns4-07.azure-dns.info."]
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "3600"
}
resource "azurerm_dns_ns_record" "csr_ns_record" {
  name                = "csr"
  records             = ["ns1-06.azure-dns.com.", "ns2-06.azure-dns.net.", "ns3-06.azure-dns.org.", "ns4-06.azure-dns.info."]
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "3600"
}
resource "azurerm_dns_ns_record" "cafm_ns_record" {
  name                = "cafm"
  records             = ["ns1-05.azure-dns.com.", "ns2-05.azure-dns.net.", "ns3-05.azure-dns.org.", "ns4-05.azure-dns.info."]
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "3600"
}

resource "azurerm_dns_cname_record" "bridge_oasys" {
  name                = "bridge-oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_onr" {
  name                = "bridge-onr"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "onr-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_practice_oasys" {
  name                = "bridge-practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "bridge_training_oasys" {
  name                = "bridge-training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "practice_oasys" {
  name                = "practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "training_oasys" {
  name                = "training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_a_record" "aap" {
  name                = "aap"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.143"]
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafm" {
  name                = "cafm"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "hmpps-prod-ukwest-appgw2-moj.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafm_preprod" {
  name                = "cafm-preprod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "hmpps-preprod-ukwest-appgw2-moj.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafmpmg" {
  name                = "cafmpmg"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "hmpps-prod-ukwest-appgw2-moj.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "cafmpmg_preprod" {
  name                = "cafmpmg-preprod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "hmpps-preprod-ukwest-appgw2-moj.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "dso_monitoring_prod" {
  name                = "dso-monitoring-prod"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "ec2-35-176-103-8.eu-west-2.compute.amazonaws.com"
  ttl                 = 300
}

resource "azurerm_dns_a_record" "dev_admin_hub" {
  name                = "dev.admin.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.186"]
  ttl                 = 300
}

resource "azurerm_dns_a_record" "dev_hub" {
  name                = "dev.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.40.45"]
  ttl                 = 500
}

resource "azurerm_dns_a_record" "dev_jenkins_hub" {
  name                = "dev.jenkins.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.28.61"]
  ttl                 = 300
}

resource "azurerm_dns_a_record" "testing_hub" {
  name                = "testing.hub"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["51.141.47.59"]
  ttl                 = 500
}

resource "azurerm_dns_ns_record" "licences" {
  name                = "licences"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["ns-1037.awsdns-01.org", "ns-2027.awsdns-61.co.uk", "ns-362.awsdns-45.com", "ns-673.awsdns-20.net"]
  ttl                 = 60
}

resource "azurerm_dns_cname_record" "mgmt" {
  name                = "mgmt"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "mgmt-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "ndelius_interface" {
  name                = "ndelius-interface"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "ndelius-prod.ukwest.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "offloc" {
  name                = "offloc"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "offloc-prod.azurewebsites.net"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "rsr" {
  name                = "rsr"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "rsr-prod.azurewebsites.net"
  ttl                 = 300
}
