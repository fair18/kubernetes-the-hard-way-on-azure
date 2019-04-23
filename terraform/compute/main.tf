resource "azurerm_resource_group" "default" {
  name = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_availability_set" "default" {
  name = "${var.vm_hostname}-as"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location = "${azurerm_resource_group.default.location}"
  platform_fault_domain_count = 2
  platform_update_domain_count = 2
  managed = true
}

resource "azurerm_network_interface" "default" {
  count = "${var.node_instances}"
  name = "${var.vm_hostname}-nic-${count.index}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location = "${azurerm_resource_group.default.location}"
  enable_ip_forwarding = true

  "ip_configuration" {
    name = "ipconfig-${count.index}"
    subnet_id = "${var.subnet_id}"
    private_ip_address_allocation = "Static"
    private_ip_address = "${cidrhost(var.subnet_address_prefix, (var.vm_hostname == "controller" ? 10 : 20) + count.index)}"
    public_ip_address_id = "${element(azurerm_public_ip.default.*.id, count.index)}"
  }
}

resource "azurerm_public_ip" "default" {
  count = "${var.node_instances}"
  name = "${var.vm_hostname}-${count.index}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location = "${azurerm_resource_group.default.location}"
  public_ip_address_allocation = "Static"
}

resource "azurerm_virtual_machine" "default" {
  count = "${var.node_instances}"
  name = "${var.vm_hostname}-${count.index}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location = "${azurerm_resource_group.default.location}"
  availability_set_id = "${azurerm_availability_set.default.id}"
  network_interface_ids = [
    "${element(azurerm_network_interface.default.*.id, count.index)}"]
  vm_size = "${var.vm_size}"
  delete_os_disk_on_termination = true

  "storage_os_disk" {
    name = "${var.vm_hostname}-osdisk-${count.index}"
    create_option = "FromImage"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer = "${var.vm_os_simple}"
    sku = "${var.vm_os_sku}"
    version = "latest"
  }

  os_profile {
    computer_name = "${var.vm_hostname}-${count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.ssh_key}"
    }
  }

  boot_diagnostics {
    enabled = false
    storage_uri = ""
  }


}
