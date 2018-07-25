resource "azurerm_network_security_group" "o11y-app-gw" {
  name                = "o11y-app-gw"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.o11y-app-gw.name}"

  tags {
    Service = "observability"
  }

  security_rule {
    name                       = "o11ytools"
    description                = "Access o11y tools from the office/vpn and AWS health-kick app"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_address_prefixes      = ["${local.studio_ip}", "${local.moj_vpn_ip}", "${local.health_kick_ip}"]
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["443"]
  }

  security_rule {
    name                       = "o11yhealthapi"
    description                = "Access to azure app gateway health api"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_address_prefix    = "*"
    source_port_range          = "*"
    destination_address_prefix = "10.0.3.0/29"
    destination_port_ranges    = ["65503-65534"]
  }

  security_rule {
    name                       = "DENY_OTHER_VirtualNetwork_Traffic"
    description                = ""
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Deny_InternetOutbound"
    description                = ""
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "*"
  }
}
