locals {
  env-name = "devtest"
}

variable "o11y-tags" {
    type = "map"
    default {
      Service = "observability"
      Environment = "devtest"
    }
}

# Resource group
resource "azurerm_resource_group" "o11y-app-gw" {
  name     = "o11y-app-gw-${local.env-name}"
  location = "ukwest"
  tags = "${var.o11y-tags}"
}

# Public IP for app gateway
resource "azurerm_public_ip" "o11y-app-gw-pip" {
  name                         = "o11y-app-gw-pip-${local.env-name}"
  domain_name_label            = "o11y-${local.env-name}"
  location                     = "ukwest"
  resource_group_name          = "${azurerm_resource_group.o11y-app-gw.name}"
  public_ip_address_allocation = "dynamic"
  tags = "${var.o11y-tags}"
}

# Nice DNS name for easy access
resource "azurerm_dns_cname_record" "o11y" {
  name                = "o11y-${local.env-name}"
  zone_name           = "${azurerm_dns_zone.hmpps.name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  ttl                 = "300"
  record              = "o11y-${local.env-name}.${azurerm_public_ip.o11y-app-gw-pip.location}.cloudapp.azure.com"
}

# vnet for gateway to live in
resource "azurerm_virtual_network" "o11y-app-gw-net" {
  name                = "o11y-app-gw-${local.env-name}-net"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.o11y-app-gw.name}"
  tags = "${var.o11y-tags}"
  address_space = ["10.0.3.0/24"]
}

resource "azurerm_virtual_network_peering" "o11y-app-gw-to-noms-mgnt" {
  name                        = "o11y-app-gw-to-noms-mgnt"
  resource_group_name         = "${azurerm_resource_group.o11y-app-gw.name}"
  virtual_network_name        = "${azurerm_virtual_network.o11y-app-gw-net.name}"
  remote_virtual_network_id   = "/subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb/resourceGroups/Network-NOMS-Mgmt/providers/Microsoft.Network/virtualNetworks/NOMS-Mgmt"
  allow_virtual_network_access = true
}

# Subnet for gateway, with NSG attached
resource "azurerm_subnet" "o11y-app-gw-subnet" {
  name                      = "o11y-app-gw-subnet"
  resource_group_name       = "${azurerm_resource_group.o11y-app-gw.name}"
  virtual_network_name      = "${azurerm_virtual_network.o11y-app-gw-net.name}"
  address_prefix            = "10.0.3.0/29"
  network_security_group_id = "${azurerm_network_security_group.o11y-app-gw.id}"
  route_table_id            = ""
  service_endpoints         = []
}

# Application Gateway
resource "azurerm_application_gateway" "o11y-app-gw" {
  name                = "o11y-app-gw-${local.env-name}"
  resource_group_name = "${azurerm_resource_group.o11y-app-gw.name}"
  location            = "ukwest"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "o11y-gateway-ip-configuration"
    subnet_id = "${azurerm_virtual_network.o11y-app-gw-net.id}/subnets/${azurerm_subnet.o11y-app-gw-subnet.name}"
  }

  frontend_port {
    name = "o11y-app-gw-feport-${local.env-name}"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "o11y-app-gw-feip-${local.env-name}"
    public_ip_address_id = "${azurerm_public_ip.o11y-app-gw-pip.id}"
  }

  # This should be dymanically generated list of backend servers
  backend_address_pool {
    name            = "o11y-be-pool"
    ip_address_list = ["10.102.0.4"]
  }

  backend_http_settings {
    name                  = "grafana"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "prometheus"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "prometheus-probe"
  }

  backend_http_settings {
    name                  = "alertmanager"
    cookie_based_affinity = "Disabled"
    port                  = 9093
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "alertmanager-probe"
  }

  probe {
    name                = "alertmanager-probe"
    protocol            = "Http"
    path                = "/alertmanager/"
    host                = "127.0.0.1"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "5"
  }

  probe {
    name                = "prometheus-probe"
    protocol            = "Http"
    path                = "/prometheus/"
    host                = "127.0.0.1"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "5"
  }

  http_listener {
    name                           = "o11y-app-gw-httplstn-${local.env-name}"
    frontend_ip_configuration_name = "o11y-app-gw-feip-${local.env-name}"
    frontend_port_name             = "o11y-app-gw-feport-${local.env-name}"
    protocol                       = "Https"
    ssl_certificate_name           = "o11y-app-gw-devtestSslCert"
  }

  ssl_certificate {
    name     = "o11y-app-gw-devtestSslCert"
    data     = "${local.bootstrap_selfsigned_cert}"
    #data     = "${base64encode(file("o11y-app-gw-bootstrapcert.pfx"))}"
    password = "bootstrapcert"
  }

  request_routing_rule {
    name                       = "o11y-app-gw-routing-rules"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "o11y-app-gw-httplstn-${local.env-name}"
    url_path_map_name          = "o11y-path-map"
  }

  url_path_map {
    name                               = "o11y-path-map"
    default_backend_address_pool_name  = "o11y-be-pool"
    default_backend_http_settings_name = "grafana"

    path_rule {
      name                       = "prometheus"
      paths                      = ["/prometheus*"]
      backend_address_pool_name  = "o11y-be-pool"
      backend_http_settings_name = "prometheus"
    }

    path_rule {
      name                       = "alertmanager"
      paths                      = ["/alertmanager*"]
      backend_address_pool_name  = "o11y-be-pool"
      backend_http_settings_name = "alertmanager"
    }
  }
}

# Setup keyvault for storing SSL certificate in, this is used by jenkins for the lets-encrypt autorenewals
resource "azurerm_key_vault" "o11y-app-gw" {
  name                = "o11y-app-gw-${local.env-name}"
  location            = "ukwest"
  resource_group_name = "${azurerm_resource_group.o11y-app-gw.name}"

  sku {
    name = "standard"
  }
    
    tenant_id = "${var.azure_tenant_id}"

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_webops_group_oid}"
        key_permissions = []
        secret_permissions = "${var.azure_secret_permissions_all}"
    }

    access_policy {
        tenant_id = "${var.azure_tenant_id}"
        object_id = "${var.azure_jenkins_sp_oid}"
        key_permissions = []
        secret_permissions = ["set", "get"]
    }

  enabled_for_deployment = false
  enabled_for_disk_encryption = false
  enabled_for_template_deployment = true
  tags = "${var.o11y-tags}"
}


# Below code doesn't work because of bug, https://github.com/terraform-providers/terraform-provider-azurerm/issues/656
# It's due to be fixed in version 0.10.0 of the azurerm provider.
# The below would have bootstrapped the secrets which jenkins then uses to store the lets encrypt cert.
#resource "azurerm_key_vault_secret" "ssl-cert" {
#  name      = "appgw-ssl-certificate"
#  value     = "${local.bootstrap_selfsigned_cert}"
#  vault_uri = "${azurerm_key_vault.o11y-app-gw.vault_uri}"
#}
#
## This vault secret is to allow the test functionality of the jenkins job to work.
#resource "azurerm_key_vault_secret" "test-ssl-cert" {
#  name      = "test-appgw-ssl-certificate"
#  value     = "${local.bootstrap_selfsigned_cert}"
#  vault_uri = "${azurerm_key_vault.o11y-app-gw.vault_uri}"
#}

locals {
  bootstrap_selfsigned_cert = "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"
}
