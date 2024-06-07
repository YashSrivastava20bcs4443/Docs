provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  count                = 4
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "external_lb" {
  name                = "externalLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  count                = 2
  name                 = "backendPool-${count.index + 1}"
  loadbalancer_id      = azurerm_lb.external_lb.id
}

resource "azurerm_lb_probe" "lb_probe" {
  count                = 2
  name                 = "lbProbe-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  loadbalancer_id      = azurerm_lb.external_lb.id
  protocol             = "Tcp"
  port                 = 80
}

resource "azurerm_lb_rule" "lb_rule" {
  count                = 2
  name                 = "lbRule-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  loadbalancer_id      = azurerm_lb.external_lb.id
  frontend_ip_configuration_name = "publicIPAddress"
  protocol             = "Tcp"
  frontend_port        = 500 + count.index + 1
  backend_port         = 80
  backend_address_pool_id = element(azurerm_lb_backend_address_pool.backend_pool.*.id, count.index)
  probe_id = element(azurerm_lb_probe.lb_probe.*.id, count.index)
}

resource "azurerm_network_interface" "nic" {
  count               = 8
  name                = "nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, floor(count.index / 2))
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pools_ids = [element(azurerm_lb_backend_address_pool.backend_pool.*.id, floor(count.index / 4))]
  }
}

resource "azurerm_virtual_machine" "vm" {
  count                = 8
  name                 = "vm-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size              = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osdisk-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_lb" "internal_lb" {
  count                = 2
  name                 = "internalLB-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  sku                  = "Standard"

  frontend_ip_configuration {
    name                 = "privateIPAddress"
    subnet_id            = element(azurerm_subnet.subnet.*.id, count.index + 2)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "internal_backend_pool" {
  count                = 2
  name                 = "internalBackendPool-${count.index + 1}"
  loadbalancer_id      = element(azurerm_lb.internal_lb.*.id, count.index)
}

resource "azurerm_lb_probe" "internal_lb_probe" {
  count                = 2
  name                 = "internalLbProbe-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  loadbalancer_id      = element(azurerm_lb.internal_lb.*.id, count.index)
  protocol             = "Tcp"
  port                 = 443
}

resource "azurerm_lb_rule" "internal_lb_rule" {
  count                = 2
  name                 = "internalLbRule-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  loadbalancer_id      = element(azurerm_lb.internal_lb.*.id, count.index)
  frontend_ip_configuration_name = "privateIPAddress"
  protocol             = "Tcp"
  frontend_port        = 443
  backend_port         = 443
  backend_address_pool_id = element(azurerm_lb_backend_address_pool.internal_backend_pool.*.id, count.index)
  probe_id = element(azurerm_lb_probe.internal_lb_probe.*.id, count.index)
}

resource "azurerm_network_security_group" "nsg" {
  count                = 4
  name                 = "nsg-${count.index + 1}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                = 4
  subnet_id            = element(azurerm_subnet.subnet.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.nsg.*.id, count.index)
}
