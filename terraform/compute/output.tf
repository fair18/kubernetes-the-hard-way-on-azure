output "network_interface_ids" {
  value = azurerm_network_interface.default.*.id
}

output "public_ips" {
  value = azurerm_public_ip.default.*.ip_address
}

output "private_ips" {
  value = azurerm_network_interface.default.*.private_ip_address
}

output "vm_hostname" {
  value = azurerm_virtual_machine.default.*.name
}
