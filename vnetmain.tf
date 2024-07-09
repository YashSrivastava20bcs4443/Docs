# vnet_peering/main.tf

resource "azurerm_virtual_network_peering" "source_to_destination" {
  name                          = "${var.peering_name}-source-to-destination"
  resource_group_name           = var.source_resource_group_name
  virtual_network_name          = var.source_vnet_name
  remote_virtual_network_id     = var.destination_vnet_id
  allow_forwarded_traffic       = true
  allow_gateway_transit         = false
  use_remote_gateways           = false
  allow_virtual_network_access  = true
}

resource "azurerm_virtual_network_peering" "destination_to_source" {
  name                          = "${var.peering_name}-destination-to-source"
  resource_group_name           = var.destination_resource_group_name
  virtual_network_name          = var.destination_vnet_name
  remote_virtual_network_id     = var.source_vnet_id
  allow_forwarded_traffic       = true
  allow_gateway_transit         = false
  use_remote_gateways           = false
  allow_virtual_network_access  = true
}
