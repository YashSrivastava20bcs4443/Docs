terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.106.1"
    }
  }

  backend "azurerm" {
    resource_group_name   = "tfstate-resources"
    storage_account_name  = "mytfstatesstacc"
    container_name        = "tfstate"
    key                   = "PR_TST/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "demo-resource-YS"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "pr-tst-net"
  address_space       = ["10.20.30.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "app_subnet" {
  name                 = "pr-app-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.30.0/26"]
}

resource "azurerm_subnet" "srv_subnet" {
  name                 = "pr-srv-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.30.64/27"]
}

resource "azurerm_subnet" "dbs_subnet" {
  name                 = "pr-dbs-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.30.128/27"]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "pr-gateway-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.30.192/28"]
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAll"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSQL"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.20.30.0/26"
    destination_address_prefix = "10.20.30.128/27"
  }
}

resource "azurerm_network_security_group" "nsg_srv" {
  name                = "nsg-srv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAll"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_dbs" {
  name                = "nsg-dbs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSQLInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"  # or '10.20.30.0/26'
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzurePlatform"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "app_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "srv_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.srv_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_srv.id
}

resource "azurerm_subnet_network_security_group_association" "dbs_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.dbs_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_dbs.id
}

# Public IP Address for Application Gateway
resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "app-gateway-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = "pr-app-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendPublicIpConfig"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }

  frontend_ip_configuration {
    name                          = "appGatewayFrontendPrivateIpConfig"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.30.196" # Specify the private IP address here
  }

  backend_address_pool {
    name = "appGatewayBackendPool"
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appGatewayHttpListener"
    frontend_ip_configuration_name = "appGatewayFrontendPublicIpConfig"
    frontend_port_name             = "frontendPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGatewaySslCert"
  }

  http_listener {
    name                           = "appGatewayPrivateHttpListener"
    frontend_ip_configuration_name = "appGatewayFrontendPrivateIpConfig"
    frontend_port_name             = "frontendPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGatewaySslCert"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "appGatewayHttpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
    priority                   = 1
  }

  request_routing_rule {
    name                       = "rule2"
    rule_type                  = "Basic"
    http_listener_name         = "appGatewayPrivateHttpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
    priority                   = 2
  }

  ssl_certificate {
    name     = "appGatewaySslCert"
    data     = filebase64("D:\\PR-TST\\certificate.pfx")
    password = "Zxcv@1234"
  }

  probe {
    name                = "httpProbe"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  tags = {
    environment = "dev_PR_TST"
  }
}

# Windows NIC 1
resource "azurerm_network_interface" "windows_nic_1" {
  name                = "windows-nic-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }
}

# Windows NIC 2
resource "azurerm_network_interface" "windows_nic_2" {
  name                = "windows-nic-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }
}

# Windows VM 1
resource "azurerm_windows_virtual_machine" "windows_vm_1" {
  name                  = "windows-vm-1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.windows_nic_1.id]
  size                  = "Standard_D2s_v3"
  admin_username        = "adminuser_ys"
  admin_password        = "Password1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Windows VM 2
resource "azurerm_windows_virtual_machine" "windows_vm_2" {
  name                  = "windows-vm-2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.windows_nic_2.id]
  size                  = "Standard_D2s_v3"
  admin_username        = "adminuser_sy"
  admin_password        = "Password1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}


# Association of NIC with Application Gateway Backend Pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "windows_backend_pool_1" {
  network_interface_id    = azurerm_network_interface.windows_nic_1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = one([for pool in azurerm_application_gateway.app_gateway.backend_address_pool : pool.id if pool.name == "appGatewayBackendPool"])
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "windows_backend_pool_2" {
  network_interface_id    = azurerm_network_interface.windows_nic_2.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = one([for pool in azurerm_application_gateway.app_gateway.backend_address_pool : pool.id if pool.name == "appGatewayBackendPool"])
}


# # SQL Managed Instance
# resource "azurerm_mssql_managed_instance" "mi" {
#   name                         = "sql-mi-instance"
#   resource_group_name          = azurerm_resource_group.rg.name
#   location                     = azurerm_resource_group.rg.location
#   subnet_id                    = azurerm_subnet.dbs_subnet.id
#   administrator_login          = "sqladminuser"
#   administrator_login_password = "SecurePassword123!"
#   sku_name                     = "GP_Gen5"
#   vcores                       = 4
#   storage_size_in_gb           = 32
#   license_type                 = "LicenseIncluded"

#   depends_on = [azurerm_virtual_network.vnet, azurerm_subnet.dbs_subnet]
# }

# Outputs
output "windows_vm_1_ip" {
  value = azurerm_network_interface.windows_nic_1.ip_configuration[0].private_ip_address
}

output "windows_vm_2_ip" {
  value = azurerm_network_interface.windows_nic_2.ip_configuration[0].private_ip_address
}

output "app_gateway_public_ip" {
  value = azurerm_public_ip.app_gateway_public_ip.ip_address
}

output "app_gateway_private_ip" {
  value = azurerm_application_gateway.app_gateway.frontend_ip_configuration[1].private_ip_address
}
