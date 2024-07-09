variable "resource_group_name" {
  description = "Name of the resource group where the VNets are deployed"
}

variable "location" {
  description = "Location where the VNets are deployed"
}

variable "vnet1_name" {
  description = "Name of the first virtual network"
}

variable "vnet1_address_space" {
  description = "Address space of the first virtual network"
}

variable "vnet2_name" {
  description = "Name of the second virtual network"
}

variable "vnet2_address_space" {
  description = "Address space of the second virtual network"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = var.vnet1_name
  address_space       = var.vnet1_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet2" {
  name                = var.vnet2_name
  address_space       = var.vnet2_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network_peering" "vnet1-to-vnet2" {
  name                      = "vnet1-to-vnet2"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "vnet2-to-vnet1" {
  name                      = "vnet2-to-vnet1"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
