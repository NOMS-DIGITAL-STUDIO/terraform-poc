resource "azurerm_resource_group" "hub-bounce-prod" {
  name     = "hub-bounce-prod"
  location = "uksouth"
}

resource "azurerm_public_ip" "hub-bounce-prod-ip" {
  name                         = "hub-bounce-prod-ip"
  location                     = "uksouth"
  resource_group_name          = "${azurerm_resource_group.hub-bounce-prod.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "hub-bounce-prod-nsg" {
  name                = "hub-bounce-prod-nsg"
  location            = "uksouth"
  resource_group_name = "${azurerm_resource_group.hub-bounce-prod.name}"

  security_rule {
    name                       = "default-allow-ssh-office"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.ips["office"]}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "default-allow-ssh-mojvpn"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.ips["mojvpn"]}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "default-allow-ssh-dxc"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.ips["dxc"]}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "default-allow-ssh-dxc2"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "109.151.4.165"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "default-allow-http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${var.ips["health-kick"]}"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.hub-bounce-prod.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-bounce-prod-vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_virtual_network" "hub-bounce-prod-vnet" {
  name                = "hub-bounce-prod-vnet"
  resource_group_name = "${azurerm_resource_group.hub-bounce-prod.name}"
  address_space       = ["10.0.1.0/24"]
  location            = "uksouth"
}

resource "azurerm_network_interface" "hub-bounce-prod-ni" {
  name                      = "hub-bounce-prod-ni"
  location                  = "uksouth"
  resource_group_name       = "${azurerm_resource_group.hub-bounce-prod.name}"
  network_security_group_id = "${azurerm_network_security_group.hub-bounce-prod-nsg.id}"

  ip_configuration {
    name                          = "hub-bounce-prod-ni-ip"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.hub-bounce-prod-ip.id}"
  }
}

resource "azurerm_virtual_machine" "hub-bounce-prod-vm" {
  name                  = "hub-bounce-prod-vm"
  location              = "uksouth"
  resource_group_name   = "${azurerm_resource_group.hub-bounce-prod.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-bounce-prod-ni.id}"]
  vm_size               = "Basic_A0"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "hub-bounce-prod-vm-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "30"
  }

  storage_data_disk {
    name              = "hub-bounce-storage"
    caching           = "None"
    create_option     = "Attach"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = "200"
  }

  os_profile {
    computer_name  = "hub-bounce-prod"
    admin_username = "lazzurs"
    admin_password = "ThisIsDisabled111!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/provisioning/.ssh/authorized_keys"
      key_data = "${file("${path.module}/sshkey.pub")}"
    }
  }
}
