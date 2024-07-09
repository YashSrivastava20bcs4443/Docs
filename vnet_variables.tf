# vnet_peering/variables.tf

variable "source_vnet_id" {
  description = "ID of the source VNet"
  type        = string
}

variable "source_vnet_name" {
  description = "Name of the source VNet"
  type        = string
}

variable "source_resource_group_name" {
  description = "Resource Group name of the source VNet"
  type        = string
}

variable "destination_vnet_id" {
  description = "ID of the destination VNet"
  type        = string
}

variable "destination_vnet_name" {
  description = "Name of the destination VNet"
  type        = string
}

variable "destination_resource_group_name" {
  description = "Resource Group name of the destination VNet"
  type        = string
}

variable "peering_name" {
  description = "Name of the VNet peering"
  type        = string
}
