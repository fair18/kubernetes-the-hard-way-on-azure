provider "azurerm" {
  version = "=1.28.0"
}

data "azurerm_client_config" "current" {}
# ---------------------------------------------------------------------------------------------------------------------
# Configure RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "default" {
  name = var.resource_group
  location = var.location
  tags = {
    source = "kubernetes-the-hard-way"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# Configure NETWORK
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "default" {
  name = var.vnet_name
  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
  address_space = [
    var.vnet_addr_space]
}

resource "azurerm_subnet" "default" {
  name = var.subnet_name
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name = azurerm_resource_group.default.name
  address_prefix = cidrsubnet(var.vnet_addr_space, 8, 240)
}
# ---------------------------------------------------------------------------------------------------------------------
# Configure NETWORK SECURITY GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "default" {
  name = var.nsg_name
  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  security_rule {
    name = "allow-ssh"
    access = "allow"
    direction = "inbound"
    priority = 1000
    protocol = var.nsg_protocol
    destination_address_prefix = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    source_port_range = "*"
  }

  security_rule {
    name = "allow-api-server"
    access = "allow"
    direction = "inbound"
    priority = 1001
    protocol = var.nsg_protocol
    destination_address_prefix = "*"
    destination_port_range = var.nsg_api_server_port_range
    source_address_prefix = "*"
    source_port_range = "*"
  }

  lifecycle {

    ignore_changes = [ "security_rule" ]
  }
}

resource "azurerm_subnet_network_security_group_association" "default" {
  network_security_group_id = azurerm_network_security_group.default.id
  subnet_id = azurerm_subnet.default.id
}

resource "azurerm_public_ip" "default" {
  name = var.pip_name
  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location
  allocation_method = "Static"
}
# ---------------------------------------------------------------------------------------------------------------------
# Configure NETWORK SECURITY GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_route_table" "default" {
  name = var.routes_table_name
  location = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  route {
    name = "kubernetes-route-10-200-0-0-24"
    address_prefix = cidrsubnet(var.route_address_prefix, 8, 0)
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.default.address_prefix, 20)
  }

  route {
    name = "kubernetes-route-10-200-1-0-24"
    address_prefix = cidrsubnet(var.route_address_prefix, 8, 1)
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.default.address_prefix, 21)
  }

  route {
    name = "kubernetes-route-10-200-2-0-24"
    address_prefix = cidrsubnet(var.route_address_prefix, 8, 2)
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost(azurerm_subnet.default.address_prefix, 22)

  }
}

resource "azurerm_subnet_route_table_association" "default" {
  route_table_id = azurerm_route_table.default.id
  subnet_id = azurerm_subnet.default.id
}

resource "azurerm_lb" "default" {
  name = var.lb_name
  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name = var.lb_frontend_ip_cfg_name
    public_ip_address_id = azurerm_public_ip.default.id
  }
}

resource "azurerm_lb_probe" "default" {
  name = var.lb_probe_name
  resource_group_name = azurerm_resource_group.default.name
  loadbalancer_id = azurerm_lb.default.id
  port = var.nsg_api_server_port_range
  protocol = var.nsg_protocol
}

resource "azurerm_lb_rule" "default" {
  name = var.lb_rule_name
  resource_group_name = azurerm_resource_group.default.name
  protocol = var.nsg_protocol
  loadbalancer_id = azurerm_lb.default.id
  frontend_ip_configuration_name = var.lb_frontend_ip_cfg_name
  frontend_port = var.nsg_api_server_port_range
  backend_address_pool_id = azurerm_lb_backend_address_pool.default.id
  backend_port = var.nsg_api_server_port_range
  probe_id = azurerm_lb_probe.default.id
}

resource "azurerm_lb_backend_address_pool" "default" {
  name = var.lb_backend_address_pool_name
  loadbalancer_id = azurerm_lb.default.id
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_network_interface_backend_address_pool_association" "default" {
  count = var.node_instances
  backend_address_pool_id = azurerm_lb_backend_address_pool.default.id
  ip_configuration_name = "ipconfig-${count.index}"
  network_interface_id = module.controllers.network_interface_ids[count.index]
}
# ---------------------------------------------------------------------------------------------------------------------
# Configure CONTROLLER-VMs
# ---------------------------------------------------------------------------------------------------------------------
module "controllers" {
  source = "./compute"

  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  vm_hostname = "controller"
  node_instances = var.node_instances

  vm_size = var.vm_size
  vm_os_sku = var.vm_os_sku
  vm_os_simple = var.vm_os_simple
  vm_os_publisher = var.vm_os_publisher

  subnet_id = azurerm_subnet.default.id
  subnet_address_prefix = azurerm_subnet.default.address_prefix

  admin_username = var.admin_username
  ssh_key = trimspace(tls_private_key.default.public_key_openssh)
}
# ---------------------------------------------------------------------------------------------------------------------
# Configure WORKER-VMs
# ---------------------------------------------------------------------------------------------------------------------
module "workers" {
  source = "./compute"

  resource_group_name = azurerm_resource_group.default.name
  location = azurerm_resource_group.default.location

  vm_hostname = "worker"
  node_instances = var.node_instances

  vm_size = var.vm_size
  vm_os_sku = var.vm_os_sku
  vm_os_simple = var.vm_os_simple
  vm_os_publisher = var.vm_os_publisher

  subnet_id = azurerm_subnet.default.id
  subnet_address_prefix = azurerm_subnet.default.address_prefix

  admin_username = var.admin_username
  ssh_key = trimspace(tls_private_key.default.public_key_openssh)
}

resource "null_resource" "certs" {
  depends_on = [
    "module.workers",
    "module.controllers"]
  count = var.node_instances

  provisioner "local-exec" {
    command = <<EOF

      scp -o StrictHostKeyChecking=no -i ${local_file.private_key_pem.filename} \
        ${local_file.ca.filename} \
        ${format("%v/certs/worker-%v.pem", path.cwd, count.index)} \
        ${format("%v/certs/worker-%v-key.pem", path.cwd, count.index)} \
      ${format("%v@%v:~/", var.admin_username, module.workers.public_ips[count.index])}
EOF
  }

  provisioner "local-exec" {
    command = <<EOF

      scp -o StrictHostKeyChecking=no -i ${local_file.private_key_pem.filename} \
        ${local_file.ca.filename} \
        ${local_file.ca-key.filename} \
        ${format("%v/certs/kubernetes.pem", path.cwd)} \
        ${format("%v/certs/kubernetes-key.pem", path.cwd)} \
        ${format("%v/certs/service-account-key.pem", path.cwd)} \
        ${format("%v/certs/service-account.pem", path.cwd)} \
      ${format("%v@%v:~/", var.admin_username, module.controllers.public_ips[count.index])}
EOF
  }
}

resource "null_resource" "configs" {
  depends_on = [
    "module.workers",
    "module.controllers"]
  count = var.node_instances

  provisioner "local-exec" {
    command = <<EOF

      scp -o StrictHostKeyChecking=no -i ${local_file.private_key_pem.filename} \
        ${format("%v/config/worker-%v.kubeconfig", path.cwd, count.index)} \
        ${format("%v/config/kube-proxy.kubeconfig", path.cwd)} \
      ${format("%v@%v:~/", var.admin_username, module.workers.public_ips[count.index])}
EOF
  }

  provisioner "local-exec" {
    command = <<EOF

     scp -o StrictHostKeyChecking=no -i ${local_file.private_key_pem.filename} \
      ${format("%v/config/admin.kubeconfig", path.cwd)} \
      ${format("%v/config/kube-controller-manager.kubeconfig", path.cwd)} \
      ${format("%v/config/kube-scheduler.kubeconfig", path.cwd)} \
      ${format("%v/config/encryption-config.yaml", path.cwd)} \
    ${format("%v@%v:~/", var.admin_username, module.controllers.public_ips[count.index])}
EOF
  }
}
