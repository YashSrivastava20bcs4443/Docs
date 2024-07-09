variable "resource_group_name" {
  description = "Name of the resource group where the VNets are deployed"
  type        = string
}

variable "vnet1_name" {
  description = "Name of the first virtual network"
  type        = string
}

variable "vnet2_name" {
  description = "Name of the second virtual network"
  type        = string
}

resource "azurerm_virtual_network_peering" "vnet1-to-vnet2" {
  name                      = "${var.vnet1_name}-to-${var.vnet2_name}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.vnet1_name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet2.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "vnet2-to-vnet1" {
  name                      = "${var.vnet2_name}-to-${var.vnet1_name}"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.vnet2_name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet1.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

data "azurerm_virtual_network" "vnet1" {
  name                = var.vnet1_name
  resource_group_name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet2" {
  name                = var.vnet2_name
  resource_group_name = var.resource_group_name
}
