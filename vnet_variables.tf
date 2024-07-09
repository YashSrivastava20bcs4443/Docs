variable "resource_group_name" {
  description = "Name of the resource group where the VNets are deployed"
  type        = string
}

variable "location" {
  description = "Location where the VNets are deployed"
  type        = string
}

variable "vnet1_name" {
  description = "Name of the first virtual network"
  type        = string
}

variable "vnet1_address_space" {
  description = "Address space of the first virtual network"
  type        = list(string)
}

variable "vnet2_name" {
  description = "Name of the second virtual network"
  type        = string
}

variable "vnet2_address_space" {
  description = "Address space of the second virtual network"
  type        = list(string)
}
