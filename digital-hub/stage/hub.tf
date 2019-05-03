resource "azurerm_public_ip" "hub" {
  name                         = "${local.name}-ip"
  location                     = "uksouth"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  public_ip_address_allocation = "static"

  tags = "${local.tags}"
}

resource "azurerm_dns_a_record" "hub" {
  name                = "${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  records             = ["${azurerm_public_ip.hub.ip_address}"]

  tags = "${local.tags}"
}

resource "azurerm_dns_cname_record" "drupal" {
  name                = "drupal.${local.name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "${azurerm_dns_a_record.hub.name}.${azurerm_dns_a_record.hub.zone_name}"

  tags = "${local.tags}"
}

locals {
  hub_bounce_prod_ip = "51.140.76.188"
}

resource "azurerm_network_security_group" "hub" {
  name                = "${local.name}-hub-nsg"
  location            = "uksouth"
  resource_group_name = "${azurerm_resource_group.group.name}"

  security_rule {
    name                       = "ssh-from-bounce"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${local.hub_bounce_prod_ip}"
    destination_address_prefix = "*"
  }

  security_rule {
    name      = "allow-http-https"
    priority  = 1100
    direction = "Inbound"
    access    = "Allow"
    protocol  = "TCP"

    destination_port_ranges    = ["80", "443"]
    destination_address_prefix = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
  }

  security_rule {
    name                       = "deny-everything-else"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = "${local.tags}"
}

resource "azurerm_virtual_network" "hub" {
  name                = "${local.name}-vnet"
  resource_group_name = "${azurerm_resource_group.group.name}"
  address_space       = ["10.0.1.0/28"]
  location            = "uksouth"

  tags = "${local.tags}"
}

resource "azurerm_subnet" "default" {
  name                      = "default"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub.name}"
  address_prefix            = "10.0.1.0/28"
  network_security_group_id = "${azurerm_network_security_group.hub.id}"
}

resource "azurerm_network_interface" "hub" {
  name                = "${local.name}-nic"
  location            = "uksouth"
  resource_group_name = "${azurerm_resource_group.group.name}"

  ip_configuration {
    name                          = "default"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub.id}"
  }

  tags = "${local.tags}"
}

resource "azurerm_managed_disk" "hub-data" {
  name                 = "${local.name}-data"
  location             = "${azurerm_resource_group.group.location}"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "256"
}

resource "azurerm_managed_disk" "hub-content" {
  name                 = "${local.name}-content"
  location             = "${azurerm_resource_group.group.location}"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "256"
}

resource "azurerm_virtual_machine" "hub" {
  name                  = "${local.name}-vm"
  location              = "uksouth"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${azurerm_network_interface.hub.id}"]
  vm_size               = "Standard_DS2_v2"

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = false

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "128"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.hub-data.name}"
    managed_disk_id = "${azurerm_managed_disk.hub-data.id}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.hub-data.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.hub-content.name}"
    managed_disk_id = "${azurerm_managed_disk.hub-content.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.hub-content.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${local.name}"
    admin_username = "provisioning"
  }

  
  os_profile_linux_config {
    disable_password_authentication = true

    /* COMMENTED OUT AS DEPLOYMENT FAILS WITH HARD CODED SSH KEY FROM FILE
    ssh_keys {
      path     = "/home/provisioning/.ssh/authorized_keys"
      key_data = "${file("${path.module}/sshkey.pub")}"
    }
    */
  }

  tags = "${local.tags}"
}
