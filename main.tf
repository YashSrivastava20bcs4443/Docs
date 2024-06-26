terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.106.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "demo-resources"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "external_lb_subnet" {
  name                 = "ExternalLBSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "waf_subnet" {
  name                 = "WAFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "internal_lb_subnet" {
  name                 = "InternalLBSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "VMSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.6.0/24"]
}

# Network Security Group for VMs
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.6.0/24" # Allow SSH from Bastion subnet
    destination_address_prefix = "*"
  }
}

# Network Security Group for External Load Balancer Subnet
resource "azurerm_network_security_group" "external_lb_nsg" {
  name                = "external-lb-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowPort501"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "501"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPort502"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "502"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnets
resource "azurerm_subnet_network_security_group_association" "external_lb_subnet_nsg" {
  subnet_id                 = azurerm_subnet.external_lb_subnet.id
  network_security_group_id = azurerm_network_security_group.external_lb_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# External Load Balancer
resource "azurerm_public_ip" "external_lb_public_ip" {
  name                = "demo-external-lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "external_lb" {
  name                = "demo-external-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.external_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "external_backend_pool" {
  name            = "ExternalBackEndAddressPool"
  loadbalancer_id = azurerm_lb.external_lb.id
}

resource "azurerm_lb_rule" "external_lb_rule_501" {
  name                           = "Port501Rule"
  loadbalancer_id                = azurerm_lb.external_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 501
  backend_port                   = 501
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_backend_pool.id]
}

resource "azurerm_lb_rule" "external_lb_rule_502" {
  name                           = "Port502Rule"
  loadbalancer_id                = azurerm_lb.external_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 502
  backend_port                   = 502
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.external_backend_pool.id]
}

# Web Application Firewall Public IP
resource "azurerm_public_ip" "waf_public_ip" {
  name                = "demo-waf-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "waf" {
  name                = "demo-waf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgwIpConfig"
    subnet_id = azurerm_subnet.waf_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGwFrontendPublicIP"
    public_ip_address_id = azurerm_public_ip.waf_public_ip.id
  }

  backend_address_pool {
    name = "appGwBackendPool"
  }

  backend_http_settings {
    name                  = "appGwHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appGwHttpListener"
    frontend_ip_configuration_name = "appGwFrontendPublicIP"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "appGwHttpListener"
    backend_address_pool_name  = "appGwBackendPool"
    backend_http_settings_name = "appGwHttpSettings"
    priority                   = 100
  }

  url_path_map {
    name                               = "urlPathMap"
    default_backend_address_pool_name  = "appGwBackendPool"
    default_backend_http_settings_name = "appGwHttpSettings"

    path_rule {
      name                       = "pathRule1"
      paths                      = ["/path1/*"]
      backend_address_pool_name  = "appGwBackendPool"
      backend_http_settings_name = "appGwHttpSettings"
    }
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  tags = {
    environment = "Production"
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "demo-waf-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  custom_rules {
    name      = "blockXSSRule"  
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "User-Agent"
      }

      operator          = "Contains"
      negation_condition = false
      match_values      = ["<script>"]
    }

    action = "Block"
  }

  tags = {
    environment = "Production"
  }
}

# Internal Load Balancer
resource "azurerm_lb" "internal_lb" {
  name                = "demo-internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                         = "LoadBalancerFrontEnd"
    subnet_id                    = azurerm_subnet.internal_lb_subnet.id
    private_ip_address           = "10.0.4.4"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "internal_backend_pool" {
  name            = "InternalBackEndAddressPool"
  loadbalancer_id = azurerm_lb.internal_lb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm1_backend_pool" {
  network_interface_id    = azurerm_network_interface.vm_nic1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.internal_backend_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2_backend_pool" {
  network_interface_id    = azurerm_network_interface.vm_nic2.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.internal_backend_pool.id
}

resource "azurerm_lb_rule" "internal_lb_rule_443" {
  name                           = "Port443Rule"
  loadbalancer_id                = azurerm_lb.internal_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.internal_backend_pool.id]
}

# Virtual Machines
resource "azurerm_network_interface" "vm_nic1" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "vm_nic2" {
  name                = "vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic1.id]
  size                = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "vm1"
  admin_username = "adminuser"
  admin_password = "Password1234!"
  disable_password_authentication = false
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic2.id]
  size                = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "vm2"
  admin_username = "adminuser"
  admin_password = "Password1234!"
  disable_password_authentication = false
}

# Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "demo-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku = "Basic"  

  ip_configuration {
    name                 = "bastionIPConfig"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }

  depends_on = [azurerm_subnet.bastion_subnet]
}


resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "demo-bastion-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
