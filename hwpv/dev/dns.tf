resource "azurerm_resource_group" "group" {
  name     = local.name
  location = "ukwest"
  tags     = local.tags
}

resource "azurerm_dns_zone" "hwpv" {
  name                = local.dnszone
  resource_group_name = azurerm_resource_group.group.name
  tags                = local.tags
}


variable "cnames" {
  type = list
  default = [
    { "dev-ci" = "ba34e1da-e6d6-4104-bf7b-e04b2f359042.cloudapp.net." },
    { "dev-external-web" = "7cf9cadd-ce00-4f7d-b619-c0fae0fcd77c.cloudapp.net." },
    { "dev-internal-web" = "7cf9cadd-ce00-4f7d-b619-c0fae0fcd77c.cloudapp.net." },
    { "test-external-web" = "8390868f-f629-4c84-b997-47bdf6f0e463.cloudapp.net." },
    { "test-internal-web" = "8390868f-f629-4c84-b997-47bdf6f0e463.cloudapp.net." },
    { "stg-external-web" = "a3ae59d8-509d-4e85-a802-63130d254488.cloudapp.net." },
    { "stg-internal-web" = "a3ae59d8-509d-4e85-a802-63130d254488.cloudapp.net." },
    { "ci" = "00b0444e-6f89-4290-8aa7-c8a48a799827.cloudapp.net." },
  ]
}

resource "azurerm_dns_cname_record" "cname" {
  count    = length(var.cnames)
  name                = element(keys(var.cnames[count.index]), 0)
  zone_name           = local.dnszone
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = element(values(var.cnames[count.index]), 0)
  tags                = local.tags
}
