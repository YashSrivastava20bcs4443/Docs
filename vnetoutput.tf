output "vnet1_to_vnet2_peering_id" {
  value = azurerm_virtual_network_peering.vnet1-to-vnet2.id
}

output "vnet2_to_vnet1_peering_id" {
  value = azurerm_virtual_network_peering.vnet2-to-vnet1.id
}
